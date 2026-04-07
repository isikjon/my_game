const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
const ioClient = require('socket.io-client');
const db = require('./db');
const routes = require('./routes');
const { registerSocket, cleanup } = require('./socket');

const TEST_PORT = 3099;
const BASE = `http://localhost:${TEST_PORT}`;

let server, io;

// ─── Helpers ─────────────────────────────────────────────────────────────────

async function api(method, path, body) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json' },
  };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${BASE}/api${path}`, opts);
  const data = await res.json();
  return { status: res.status, data };
}

function connect(code, role = 'player') {
  return new Promise((resolve, reject) => {
    const socket = ioClient(BASE, {
      transports: ['websocket'],
      forceNew: true,
    });
    socket.on('connect', () => {
      const event = role === 'host' ? 'host-game' : 'join-game';
      socket.emit(event, code, (resp) => {
        if (resp.error) {
          socket.disconnect();
          return reject(new Error(resp.error));
        }
        resolve(socket);
      });
    });
    socket.on('connect_error', reject);
    setTimeout(() => reject(new Error('Socket connect timeout')), 5000);
  });
}

function emitAsync(socket, event, data) {
  return new Promise((resolve, reject) => {
    socket.emit(event, data, (resp) => {
      if (resp?.error) return reject(new Error(resp.error));
      resolve(resp);
    });
    setTimeout(() => reject(new Error(`${event} timeout`)), 5000);
  });
}

function waitForEvent(socket, event, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(
      () => reject(new Error(`Timeout waiting for ${event}`)),
      timeoutMs,
    );
    socket.once(event, (data) => {
      clearTimeout(timer);
      resolve(data);
    });
  });
}

// ─── Sample game data ────────────────────────────────────────────────────────

const SAMPLE_ROUNDS = [
  {
    name: 'Раунд 1',
    timeSeconds: 3,
    topics: [
      {
        name: 'Природа',
        questions: [
          { score: 500, type: 'normal', question: 'Самое большое животное?', answer: 'Синий кит' },
          { score: 1000, type: 'normal', question: 'Самая длинная река?', answer: 'Нил' },
          { score: 1500, type: 'bonus', question: 'Самая высокая гора?', answer: 'Эверест' },
          { score: 2000, type: 'normal', question: 'Самое глубокое озеро?', answer: 'Байкал' },
          { score: 2500, type: 'cat', question: 'Самый большой остров?', answer: 'Гренландия' },
        ],
      },
      {
        name: 'Еда',
        questions: [
          { score: 500, type: 'normal', question: 'Итальянское блюдо из теста?', answer: 'Пицца' },
          { score: 1000, type: 'normal', question: 'Японское блюдо из риса и рыбы?', answer: 'Суши' },
          { score: 1500, type: 'normal', question: 'Французский суп из лука?', answer: 'Луковый суп' },
          { score: 2000, type: 'bonus', question: 'Грузинское блюдо из теста и мяса?', answer: 'Хинкали' },
          { score: 2500, type: 'normal', question: 'Мексиканская лепёшка?', answer: 'Тортилья' },
        ],
      },
    ],
  },
  {
    name: 'Раунд 2',
    timeSeconds: 2,
    topics: [
      {
        name: 'История',
        questions: [
          { score: 500, type: 'normal', question: 'Год основания Рима?', answer: '753 до н.э.' },
          { score: 1000, type: 'normal', question: 'Первый президент США?', answer: 'Вашингтон' },
          { score: 1500, type: 'normal', question: 'Год падения Берлинской стены?', answer: '1989' },
          { score: 2000, type: 'normal', question: 'Кто открыл Америку?', answer: 'Колумб' },
          { score: 2500, type: 'cat', question: 'Битва при Ватерлоо?', answer: '1815' },
        ],
      },
    ],
  },
];

const TEAM_NAMES = ['Команда 1', 'Команда 2', 'Команда 3'];

// ─── Setup / Teardown ────────────────────────────────────────────────────────

before(async () => {
  // use in-memory test db
  process.env.DB_PATH = ':memory:';
  // Force reinit
  db.closeDb();
  db.getDb(':memory:');

  const app = express();
  app.use(cors());
  app.use(express.json({ limit: '5mb' }));
  app.use('/api', routes);

  server = http.createServer(app);
  io = new Server(server, { cors: { origin: '*' } });
  registerSocket(io);

  await new Promise((r) => server.listen(TEST_PORT, r));
  console.log(`Test server on port ${TEST_PORT}`);
});

after(async () => {
  cleanup();
  io.close();
  await new Promise((r) => server.close(r));
  db.closeDb();
  console.log('Test server closed');
});

// ─── REST API Tests ──────────────────────────────────────────────────────────

describe('REST API', () => {
  let gameCode;
  let gameId;

  it('POST /api/games — creates a game', async () => {
    const { status, data } = await api('POST', '/games', { name: 'Тестовая игра' });
    assert.equal(status, 201);
    assert.ok(data.id);
    assert.ok(data.code);
    assert.equal(data.code.length, 4);
    assert.equal(data.name, 'Тестовая игра');
    gameCode = data.code;
    gameId = data.id;
  });

  it('GET /api/games/:code — returns empty game', async () => {
    const { status, data } = await api('GET', `/games/${gameCode}`);
    assert.equal(status, 200);
    assert.equal(data.code, gameCode);
    assert.equal(data.status, 'setup');
    assert.deepEqual(data.rounds, []);
    assert.deepEqual(data.teams, []);
  });

  it('GET /api/games/9999 — 404 for invalid code', async () => {
    const { status } = await api('GET', '/games/0000');
    assert.equal(status, 404);
  });

  it('PUT /api/games/:code/setup — sets up rounds/topics/questions', async () => {
    const { status, data } = await api('PUT', `/games/${gameCode}/setup`, {
      rounds: SAMPLE_ROUNDS,
    });
    assert.equal(status, 200);
    assert.equal(data.rounds.length, 2);
    assert.equal(data.rounds[0].topics.length, 2);
    assert.equal(data.rounds[0].topics[0].questions.length, 5);
    assert.equal(data.rounds[0].topics[0].questions[0].question_text, 'Самое большое животное?');
    assert.equal(data.rounds[0].topics[0].questions[0].score, 500);
    assert.equal(data.rounds[0].topics[0].questions[0].type, 'normal');
    assert.equal(data.rounds[1].topics.length, 1);
    assert.equal(data.rounds[1].topics[0].name, 'История');
  });

  it('PUT /api/games/:code/setup — validation: empty rounds', async () => {
    const { status } = await api('PUT', `/games/${gameCode}/setup`, { rounds: [] });
    assert.equal(status, 400);
  });

  it('PUT /api/games/:code/setup — validation: missing question fields', async () => {
    const { status } = await api('PUT', `/games/${gameCode}/setup`, {
      rounds: [{ name: 'R', topics: [{ name: 'T', questions: [{ score: 500 }] }] }],
    });
    assert.equal(status, 400);
  });

  it('POST /api/games/:code/teams — adds a team', async () => {
    const { status, data } = await api('POST', `/games/${gameCode}/teams`, {
      name: 'Команда 1',
    });
    assert.equal(status, 201);
    assert.ok(data.id);
    assert.equal(data.name, 'Команда 1');
    assert.equal(data.score, 0);
  });

  it('POST /api/games/:code/teams/bulk — adds multiple teams', async () => {
    const { status, data } = await api('POST', `/games/${gameCode}/teams/bulk`, {
      names: ['Команда 2', 'Команда 3'],
    });
    assert.equal(status, 201);
    assert.equal(data.length, 2);
  });

  it('GET /api/games/:code/teams — lists teams', async () => {
    const { status, data } = await api('GET', `/games/${gameCode}/teams`);
    assert.equal(status, 200);
    assert.equal(data.length, 3);
  });

  it('DELETE /api/teams/:id — removes a team', async () => {
    const { data: teams } = await api('GET', `/games/${gameCode}/teams`);
    const lastId = teams[teams.length - 1].id;
    const { status } = await api('DELETE', `/teams/${lastId}`);
    assert.equal(status, 200);
    const { data: after } = await api('GET', `/games/${gameCode}/teams`);
    assert.equal(after.length, 2);
  });

  it('POST /api/games/:code/teams — validation: empty name', async () => {
    const { status } = await api('POST', `/games/${gameCode}/teams`, { name: '' });
    assert.equal(status, 400);
  });

  // re-add deleted team for socket tests
  it('restore 3 teams for socket tests', async () => {
    await api('POST', `/games/${gameCode}/teams`, { name: 'Команда 3' });
    const { data } = await api('GET', `/games/${gameCode}/teams`);
    assert.equal(data.length, 3);
  });
});

// ─── Socket.IO Tests ─────────────────────────────────────────────────────────

describe('Socket.IO', () => {
  let gameCode;
  let hostSocket, playerSocket;
  let teamIds;

  before(async () => {
    // create a fresh game for socket tests
    const { data: game } = await api('POST', '/games', { name: 'Socket test' });
    gameCode = game.code;

    await api('PUT', `/games/${gameCode}/setup`, { rounds: SAMPLE_ROUNDS });
    const { data: teams } = await api('POST', `/games/${gameCode}/teams/bulk`, {
      names: TEAM_NAMES,
    });
    teamIds = teams.map((t) => t.id);
  });

  after(() => {
    if (hostSocket) hostSocket.disconnect();
    if (playerSocket) playerSocket.disconnect();
  });

  it('host connects and joins room', async () => {
    hostSocket = await connect(gameCode, 'host');
    assert.ok(hostSocket.connected);
  });

  it('player connects and joins room', async () => {
    const joinedPromise = waitForEvent(hostSocket, 'player-joined');
    playerSocket = await connect(gameCode, 'player');
    assert.ok(playerSocket.connected);
    const joinData = await joinedPromise;
    assert.ok(joinData.socketId);
  });

  it('start-game broadcasts game-started', async () => {
    const startedPromise = waitForEvent(playerSocket, 'game-started');
    await emitAsync(hostSocket, 'start-game', gameCode);
    const gameData = await startedPromise;
    assert.equal(gameData.status, 'playing');
    assert.equal(gameData.rounds.length, 2);
  });

  it('select-question broadcasts question and starts timer', async () => {
    const questionPromise = waitForEvent(playerSocket, 'question-selected');
    await emitAsync(hostSocket, 'select-question', {
      code: gameCode,
      roundIdx: 0,
      topicIdx: 0,
      scoreIdx: 0,
    });
    const qData = await questionPromise;
    assert.equal(qData.questionText, 'Самое большое животное?');
    assert.equal(qData.score, 500);
    assert.equal(qData.type, 'normal');
    assert.equal(qData.timerSeconds, 3);
  });

  it('timer-tick fires and counts down', async () => {
    const tick = await waitForEvent(playerSocket, 'timer-tick', 3000);
    assert.ok(tick.seconds <= 3);
    assert.ok(tick.seconds >= 0);
  });

  it('reveal-answer broadcasts answer', async () => {
    const answerPromise = waitForEvent(playerSocket, 'answer-revealed');
    await emitAsync(hostSocket, 'reveal-answer', gameCode);
    const aData = await answerPromise;
    assert.equal(aData.answerText, 'Синий кит');
  });

  it('assign-score awards points and marks question used', async () => {
    const scorePromise = waitForEvent(playerSocket, 'score-updated');
    const resp = await emitAsync(hostSocket, 'assign-score', {
      code: gameCode,
      teamId: teamIds[0],
    });
    assert.ok(resp.ok);
    const sData = await scorePromise;
    const team1 = sData.teams.find((t) => t.id === teamIds[0]);
    assert.equal(team1.score, 500);
    assert.equal(sData.awardedScore, 500);
  });

  it('used question cannot be selected again', async () => {
    try {
      await emitAsync(hostSocket, 'select-question', {
        code: gameCode,
        roundIdx: 0,
        topicIdx: 0,
        scoreIdx: 0,
      });
      assert.fail('Should have thrown');
    } catch (e) {
      assert.equal(e.message, 'Question already used');
    }
  });

  it('skip-question marks question used without scoring', async () => {
    // select another question first
    await emitAsync(hostSocket, 'select-question', {
      code: gameCode,
      roundIdx: 0,
      topicIdx: 0,
      scoreIdx: 1,
    });
    const skipPromise = waitForEvent(playerSocket, 'question-skipped');
    await emitAsync(hostSocket, 'skip-question', gameCode);
    const sData = await skipPromise;
    assert.ok(sData.questionId);

    // verify team 1 still has only 500
    const { data: teams } = await api('GET', `/games/${gameCode}/teams`);
    const team1 = teams.find((t) => t.id === teamIds[0]);
    assert.equal(team1.score, 500);
  });

  it('next-round changes round', async () => {
    const roundPromise = waitForEvent(playerSocket, 'round-changed');
    await emitAsync(hostSocket, 'next-round', { code: gameCode, roundIdx: 1 });
    const rData = await roundPromise;
    assert.equal(rData.roundIdx, 1);
    assert.equal(rData.game.current_round, 1);
  });

  it('select question from round 2', async () => {
    const questionPromise = waitForEvent(playerSocket, 'question-selected');
    await emitAsync(hostSocket, 'select-question', {
      code: gameCode,
      roundIdx: 1,
      topicIdx: 0,
      scoreIdx: 2,
    });
    const qData = await questionPromise;
    assert.equal(qData.questionText, 'Год падения Берлинской стены?');
    assert.equal(qData.score, 1500);
  });

  it('assign score to team 2', async () => {
    const scorePromise = waitForEvent(playerSocket, 'score-updated');
    await emitAsync(hostSocket, 'assign-score', {
      code: gameCode,
      teamId: teamIds[1],
    });
    const sData = await scorePromise;
    const team2 = sData.teams.find((t) => t.id === teamIds[1]);
    assert.equal(team2.score, 1500);
  });

  it('get-state returns full game', async () => {
    const resp = await emitAsync(playerSocket, 'get-state', gameCode);
    assert.ok(resp.ok);
    assert.equal(resp.game.status, 'playing');
    assert.equal(resp.game.rounds.length, 2);
    assert.equal(resp.game.teams.length, 3);
  });

  it('end-game finishes the game', async () => {
    const endPromise = waitForEvent(playerSocket, 'game-ended');
    const resp = await emitAsync(hostSocket, 'end-game', gameCode);
    assert.ok(resp.ok);
    const eData = await endPromise;
    assert.equal(eData.teams.length, 3);

    // verify final scores
    const team1 = eData.teams.find((t) => t.id === teamIds[0]);
    const team2 = eData.teams.find((t) => t.id === teamIds[1]);
    assert.equal(team1.score, 500);
    assert.equal(team2.score, 1500);

    // verify game status in DB
    const { data: game } = await api('GET', `/games/${gameCode}`);
    assert.equal(game.status, 'finished');
  });
});

// ─── Full flow end-to-end ────────────────────────────────────────────────────

describe('Full game flow (end-to-end)', () => {
  let code;
  let host, player1, player2;
  let tIds;

  before(async () => {
    // 1. Create game
    const { data: game } = await api('POST', '/games', { name: 'E2E Game' });
    code = game.code;

    // 2. Setup
    await api('PUT', `/games/${code}/setup`, {
      rounds: [
        {
          name: 'Финал',
          timeSeconds: 2,
          topics: [
            {
              name: 'Спорт',
              questions: [
                { score: 500, type: 'normal', question: 'Сколько игроков в футбольной команде?', answer: '11' },
                { score: 1000, type: 'normal', question: 'Олимпийские кольца — сколько?', answer: '5' },
                { score: 1500, type: 'bonus', question: 'Родина шахмат?', answer: 'Индия' },
                { score: 2000, type: 'normal', question: 'Вид спорта с ракеткой и воланом?', answer: 'Бадминтон' },
                { score: 2500, type: 'cat', question: 'Самый быстрый человек?', answer: 'Усэйн Болт' },
              ],
            },
          ],
        },
      ],
    });

    // 3. Teams
    const { data: teams } = await api('POST', `/games/${code}/teams/bulk`, {
      names: ['Орлы', 'Тигры'],
    });
    tIds = teams.map((t) => t.id);

    // 4. Connect
    host = await connect(code, 'host');
    player1 = await connect(code, 'player');
    player2 = await connect(code, 'player');
  });

  after(() => {
    host?.disconnect();
    player1?.disconnect();
    player2?.disconnect();
  });

  it('plays a full game', async () => {
    // Start
    await emitAsync(host, 'start-game', code);

    // Q1: 500 → Орлы
    await emitAsync(host, 'select-question', { code, roundIdx: 0, topicIdx: 0, scoreIdx: 0 });
    await emitAsync(host, 'reveal-answer', code);
    await emitAsync(host, 'assign-score', { code, teamId: tIds[0] });

    // Q2: 1000 → Тигры
    await emitAsync(host, 'select-question', { code, roundIdx: 0, topicIdx: 0, scoreIdx: 1 });
    await emitAsync(host, 'assign-score', { code, teamId: tIds[1] });

    // Q3: 1500 → skip
    await emitAsync(host, 'select-question', { code, roundIdx: 0, topicIdx: 0, scoreIdx: 2 });
    await emitAsync(host, 'skip-question', code);

    // Q4: 2000 → Орлы
    await emitAsync(host, 'select-question', { code, roundIdx: 0, topicIdx: 0, scoreIdx: 3 });
    await emitAsync(host, 'assign-score', { code, teamId: tIds[0] });

    // Q5: 2500 → Тигры
    await emitAsync(host, 'select-question', { code, roundIdx: 0, topicIdx: 0, scoreIdx: 4 });
    await emitAsync(host, 'assign-score', { code, teamId: tIds[1] });

    // End
    const endResp = await emitAsync(host, 'end-game', code);
    const eagles = endResp.teams.find((t) => t.name === 'Орлы');
    const tigers = endResp.teams.find((t) => t.name === 'Тигры');

    assert.equal(eagles.score, 2500); // 500 + 2000
    assert.equal(tigers.score, 3500); // 1000 + 2500
    assert.ok(tigers.score > eagles.score, 'Тигры should win');
  });
});
