const db = require('./db');

// gameCode → { hostId, interval, seconds, questionId }
const liveGames = new Map();

function registerSocket(io) {
  io.on('connection', (socket) => {
    // ─── Host creates / joins game room ──────────────────────────────────
    socket.on('host-game', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      socket.join(code);
      socket.data.code = code;
      socket.data.role = 'host';

      let live = liveGames.get(code);
      if (!live) {
        live = { hostId: socket.id, interval: null, seconds: 0, questionId: null };
        liveGames.set(code, live);
      }
      live.hostId = socket.id;

      ack?.({ ok: true, game });
    });

    // ─── Player joins game room ──────────────────────────────────────────
    socket.on('join-game', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      socket.join(code);
      socket.data.code = code;
      socket.data.role = 'player';

      socket.to(code).emit('player-joined', { socketId: socket.id });
      ack?.({ ok: true, game });
    });

    // ─── Start game ─────────────────────────────────────────────────────
    socket.on('start-game', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      db.setGameStatus(game.id, 'playing');
      db.setCurrentRound(game.id, 0);

      const updated = db.getGameByCode(code);
      io.to(code).emit('game-started', updated);
      ack?.({ ok: true });
    });

    // ─── Select question ────────────────────────────────────────────────
    socket.on('select-question', ({ code, roundIdx, topicIdx, scoreIdx }, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      const question = db.getQuestionByPosition(
        game.id,
        roundIdx,
        topicIdx,
        scoreIdx,
      );
      if (!question) return ack?.({ error: 'Question not found' });
      if (question.is_used) return ack?.({ error: 'Question already used' });

      db.setCurrentQuestion(game.id, question.id);

      const live = liveGames.get(code) || {
        hostId: socket.id,
        interval: null,
        seconds: 0,
        questionId: null,
      };
      if (!liveGames.has(code)) liveGames.set(code, live);

      // clear any previous timer
      if (live.interval) clearInterval(live.interval);

      const round = game.rounds[roundIdx];
      const totalSeconds = round ? round.time_seconds : 60;
      live.seconds = totalSeconds;
      live.questionId = question.id;

      io.to(code).emit('question-selected', {
        questionId: question.id,
        questionText: question.question_text,
        score: question.score,
        type: question.type,
        timerSeconds: totalSeconds,
        roundIdx,
        topicIdx,
        scoreIdx,
      });

      // start countdown
      live.interval = setInterval(() => {
        live.seconds--;
        io.to(code).emit('timer-tick', { seconds: live.seconds });
        if (live.seconds <= 0) {
          clearInterval(live.interval);
          live.interval = null;
          io.to(code).emit('timer-ended');
        }
      }, 1000);

      ack?.({ ok: true, questionId: question.id });
    });

    // ─── Reveal answer ──────────────────────────────────────────────────
    socket.on('reveal-answer', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game || !game.current_qid) return ack?.({ error: 'No active question' });

      const question = db.getQuestionById(game.current_qid);
      if (!question) return ack?.({ error: 'Question not found' });

      io.to(code).emit('answer-revealed', {
        answerText: question.answer_text,
        questionId: question.id,
      });
      ack?.({ ok: true });
    });

    // ─── Assign score to team ───────────────────────────────────────────
    socket.on('assign-score', ({ code, teamId }, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      const live = liveGames.get(code);

      // stop timer if running
      if (live?.interval) {
        clearInterval(live.interval);
        live.interval = null;
      }

      const qid = game.current_qid || live?.questionId;
      if (!qid) return ack?.({ error: 'No active question' });

      const question = db.getQuestionById(qid);
      if (!question) return ack?.({ error: 'Question not found' });

      // award points
      if (teamId) {
        db.updateTeamScore(teamId, question.score);
      }

      db.markQuestionUsed(question.id);
      db.setCurrentQuestion(game.id, null);
      if (live) live.questionId = null;

      const teams = db.getTeams(game.id);
      io.to(code).emit('score-updated', {
        teams,
        awardedTeamId: teamId || null,
        awardedScore: question.score,
        questionId: question.id,
      });

      ack?.({ ok: true, teams });
    });

    // ─── Skip question (no one answered) ────────────────────────────────
    socket.on('skip-question', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      const live = liveGames.get(code);
      if (live?.interval) {
        clearInterval(live.interval);
        live.interval = null;
      }

      const qid = game.current_qid || live?.questionId;
      if (qid) {
        db.markQuestionUsed(qid);
        db.setCurrentQuestion(game.id, null);
        if (live) live.questionId = null;
      }

      io.to(code).emit('question-skipped', { questionId: qid });
      ack?.({ ok: true });
    });

    // ─── Next round ─────────────────────────────────────────────────────
    socket.on('next-round', ({ code, roundIdx }, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      if (roundIdx >= game.rounds.length) {
        return ack?.({ error: 'No more rounds' });
      }

      db.setCurrentRound(game.id, roundIdx);
      const updated = db.getGameByCode(code);
      io.to(code).emit('round-changed', { roundIdx, game: updated });
      ack?.({ ok: true });
    });

    // ─── End game ───────────────────────────────────────────────────────
    socket.on('end-game', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      const live = liveGames.get(code);
      if (live?.interval) {
        clearInterval(live.interval);
        live.interval = null;
      }

      db.setGameStatus(game.id, 'finished');
      const teams = db.getTeams(game.id);
      io.to(code).emit('game-ended', { teams });
      liveGames.delete(code);
      ack?.({ ok: true, teams });
    });

    // ─── Disconnect ─────────────────────────────────────────────────────
    socket.on('disconnect', () => {
      const code = socket.data.code;
      if (!code) return;

      if (socket.data.role === 'host') {
        io.to(code).emit('host-disconnected');
      }
    });

    // ─── Request full state (reconnection) ──────────────────────────────
    socket.on('get-state', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });
      ack?.({ ok: true, game });
    });
  });
}

function cleanup() {
  for (const [, live] of liveGames) {
    if (live.interval) clearInterval(live.interval);
  }
  liveGames.clear();
}

module.exports = { registerSocket, cleanup, liveGames };
