const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');
const { randomUUID } = require('crypto');

const DEFAULT_DB_PATH = path.join(__dirname, 'data', 'svoya_igra.db');

let _db = null;

function getDb(dbPath) {
  if (_db) return _db;

  const p = dbPath || process.env.DB_PATH || DEFAULT_DB_PATH;
  const dir = path.dirname(p);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  _db = new Database(p);
  _db.pragma('journal_mode = WAL');
  _db.pragma('foreign_keys = ON');

  _db.exec(`
    CREATE TABLE IF NOT EXISTS games (
      id            TEXT PRIMARY KEY,
      code          TEXT UNIQUE NOT NULL,
      name          TEXT DEFAULT '',
      status        TEXT DEFAULT 'setup',
      current_round INTEGER DEFAULT 0,
      current_qid   INTEGER,
      created_at    TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS rounds (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      game_id       TEXT NOT NULL,
      name          TEXT NOT NULL,
      time_seconds  INTEGER DEFAULT 60,
      sort_order    INTEGER NOT NULL,
      FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS topics (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      round_id      INTEGER NOT NULL,
      name          TEXT NOT NULL,
      sort_order    INTEGER NOT NULL,
      FOREIGN KEY (round_id) REFERENCES rounds(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS questions (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      topic_id      INTEGER NOT NULL,
      score         INTEGER NOT NULL,
      type          TEXT DEFAULT 'normal',
      question_text TEXT NOT NULL,
      answer_text   TEXT NOT NULL,
      is_used       INTEGER DEFAULT 0,
      FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS teams (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      game_id       TEXT NOT NULL,
      name          TEXT NOT NULL,
      score         INTEGER DEFAULT 0,
      FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
    );
  `);

  return _db;
}

function closeDb() {
  if (_db) {
    _db.close();
    _db = null;
  }
}

// ─── Game ────────────────────────────────────────────────────────────────────

function generateCode() {
  const db = getDb();
  const stmt = db.prepare('SELECT 1 FROM games WHERE code = ?');
  let code;
  do {
    code = String(Math.floor(1000 + Math.random() * 9000));
  } while (stmt.get(code));
  return code;
}

function createGame(name = '') {
  const db = getDb();
  const id = randomUUID();
  const code = generateCode();
  db.prepare(
    'INSERT INTO games (id, code, name) VALUES (?, ?, ?)',
  ).run(id, code, name);
  return { id, code, name, status: 'setup' };
}

function deleteGame(gameId) {
  const db = getDb();
  db.prepare('DELETE FROM games WHERE id = ?').run(gameId);
}

function getGameByCode(code) {
  const db = getDb();
  const game = db.prepare('SELECT * FROM games WHERE code = ?').get(code);
  if (!game) return null;

  const rounds = db
    .prepare('SELECT * FROM rounds WHERE game_id = ? ORDER BY sort_order')
    .all(game.id);

  for (const round of rounds) {
    round.topics = db
      .prepare('SELECT * FROM topics WHERE round_id = ? ORDER BY sort_order')
      .all(round.id);
    for (const topic of round.topics) {
      topic.questions = db
        .prepare('SELECT * FROM questions WHERE topic_id = ? ORDER BY score')
        .all(topic.id);
    }
  }

  const teams = db
    .prepare('SELECT * FROM teams WHERE game_id = ? ORDER BY id')
    .all(game.id);

  return { ...game, rounds, teams };
}

function getGameById(id) {
  const db = getDb();
  return db.prepare('SELECT * FROM games WHERE id = ?').get(id);
}

function listGames() {
  const db = getDb();
  // Return games with their teams (simplified)
  const games = db.prepare('SELECT * FROM games ORDER BY created_at DESC').all();
  for (const g of games) {
    g.teams = db.prepare('SELECT name FROM teams WHERE game_id = ?').all(g.id).map(t => t.name);
  }
  return games;
}

function listAllTeams() {
  const db = getDb();
  // Distinct team names to show as "templates" or "previously used"
  return db.prepare('SELECT DISTINCT name FROM teams ORDER BY name').all();
}

// ─── Bulk setup (rounds → topics → questions) ───────────────────────────────

/**
 * Replaces all rounds/topics/questions for a game.
 * `rounds` is an array of:
 *   { name, timeSeconds, topics: [{ name, questions: [{ score, type, question, answer }] }] }
 */
function setupGame(gameId, rounds) {
  const db = getDb();

  const txn = db.transaction(() => {
    // wipe existing structure
    const oldRounds = db
      .prepare('SELECT id FROM rounds WHERE game_id = ?')
      .all(gameId);
    for (const r of oldRounds) {
      const oldTopics = db
        .prepare('SELECT id FROM topics WHERE round_id = ?')
        .all(r.id);
      for (const t of oldTopics) {
        db.prepare('DELETE FROM questions WHERE topic_id = ?').run(t.id);
      }
      db.prepare('DELETE FROM topics WHERE round_id = ?').run(r.id);
    }
    db.prepare('DELETE FROM rounds WHERE game_id = ?').run(gameId);

    // insert new structure
    const insRound = db.prepare(
      'INSERT INTO rounds (game_id, name, time_seconds, sort_order) VALUES (?, ?, ?, ?)',
    );
    const insTopic = db.prepare(
      'INSERT INTO topics (round_id, name, sort_order) VALUES (?, ?, ?)',
    );
    const insQ = db.prepare(
      'INSERT INTO questions (topic_id, score, type, question_text, answer_text) VALUES (?, ?, ?, ?, ?)',
    );

    for (let ri = 0; ri < rounds.length; ri++) {
      const r = rounds[ri];
      const rRes = insRound.run(gameId, r.name, r.timeSeconds || 60, ri);
      const roundId = rRes.lastInsertRowid;

      const topics = r.topics || [];
      for (let ti = 0; ti < topics.length; ti++) {
        const t = topics[ti];
        const tRes = insTopic.run(roundId, t.name, ti);
        const topicId = tRes.lastInsertRowid;

        const questions = t.questions || [];
        for (const q of questions) {
          if (q && q.question && q.answer) {
            insQ.run(
              topicId,
              q.score,
              q.type || 'normal',
              q.question,
              q.answer,
            );
          }
        }
      }
    }
  });

  txn();
}

// ─── Teams ───────────────────────────────────────────────────────────────────

function addTeam(gameId, name) {
  const db = getDb();
  const res = db
    .prepare('INSERT INTO teams (game_id, name) VALUES (?, ?)')
    .run(gameId, name);
  return { id: Number(res.lastInsertRowid), game_id: gameId, name, score: 0 };
}

function removeTeam(teamId) {
  const db = getDb();
  db.prepare('DELETE FROM teams WHERE id = ?').run(teamId);
}

function getTeams(gameId) {
  const db = getDb();
  return db
    .prepare('SELECT * FROM teams WHERE game_id = ? ORDER BY id')
    .all(gameId);
}

function updateTeamScore(teamId, delta) {
  const db = getDb();
  db.prepare('UPDATE teams SET score = score + ? WHERE id = ?').run(
    delta,
    teamId,
  );
  return db.prepare('SELECT * FROM teams WHERE id = ?').get(teamId);
}

// ─── Questions ───────────────────────────────────────────────────────────────

function markQuestionUsed(questionId) {
  const db = getDb();
  db.prepare('UPDATE questions SET is_used = 1 WHERE id = ?').run(questionId);
}

function getQuestionById(questionId) {
  const db = getDb();
  return db.prepare('SELECT * FROM questions WHERE id = ?').get(questionId);
}

function getQuestionByPosition(gameId, roundIdx, topicIdx, scoreIdx) {
  const db = getDb();
  const scores = [500, 1000, 1500, 2000, 2500];
  const scoreVal = scores[scoreIdx];
  if (scoreVal === undefined) return null;

  const round = db
    .prepare(
      'SELECT * FROM rounds WHERE game_id = ? AND sort_order = ?',
    )
    .get(gameId, roundIdx);
  if (!round) return null;

  const topic = db
    .prepare(
      'SELECT * FROM topics WHERE round_id = ? AND sort_order = ?',
    )
    .get(round.id, topicIdx);
  if (!topic) return null;

  return db
    .prepare(
      'SELECT * FROM questions WHERE topic_id = ? AND score = ?',
    )
    .get(topic.id, scoreVal);
}

// ─── Game status ─────────────────────────────────────────────────────────────

function setGameStatus(gameId, status) {
  const db = getDb();
  db.prepare('UPDATE games SET status = ? WHERE id = ?').run(status, gameId);
}

function setCurrentRound(gameId, roundIdx) {
  const db = getDb();
  db.prepare('UPDATE games SET current_round = ? WHERE id = ?').run(
    roundIdx,
    gameId,
  );
}

function setCurrentQuestion(gameId, qid) {
  const db = getDb();
  db.prepare('UPDATE games SET current_qid = ? WHERE id = ?').run(
    qid,
    gameId,
  );
}

// ─── Cleanup ─────────────────────────────────────────────────────────────────

function deleteOldGames(hoursAgo = 24) {
  const db = getDb();
  db.prepare(
    "DELETE FROM games WHERE created_at < datetime('now', ? || ' hours')",
  ).run(-hoursAgo);
}

module.exports = {
  getDb,
  closeDb,
  createGame,
  deleteGame,
  getGameByCode,
  getGameById,
  listGames,
  listAllTeams,
  setupGame,
  addTeam,
  removeTeam,
  getTeams,
  updateTeamScore,
  markQuestionUsed,
  getQuestionById,
  getQuestionByPosition,
  setGameStatus,
  setCurrentRound,
  setCurrentQuestion,
  deleteOldGames,
};
