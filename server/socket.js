const db = require('./db');

// gameCode → { hostId, interval, seconds, questionId, phase, roundIdx, topicIdx, scoreIdx, answerText, catRevealed }
const liveGames = new Map();

function buildLiveStateAck(code) {
  const live = liveGames.get(code);
  if (!live || !live.phase) return null;
  const result = { phase: live.phase };
  if (live.questionId) {
    const q = db.getQuestionById(live.questionId);
    if (q) {
      result.activeQuestion = {
        questionId: q.id,
        questionText: q.question_text,
        score: q.score,
        type: q.type,
        roundIdx: live.roundIdx,
        topicIdx: live.topicIdx,
        scoreIdx: live.scoreIdx,
        timerSeconds: live.seconds || 0,
      };
    }
  }
  if (live.phase === 'result' && live.answerText) {
    result.revealedAnswer = live.answerText;
  }
  if (live.catRevealed) {
    result.catRevealed = true;
  }
  return result;
}

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
        live = { hostId: socket.id, interval: null, seconds: 0, questionId: null, phase: null };
        liveGames.set(code, live);
      }
      live.hostId = socket.id;

      const liveState = buildLiveStateAck(code);
      ack?.({ ok: true, game, liveState });
    });

    // ─── Player joins game room ──────────────────────────────────────────
    socket.on('join-game', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      socket.join(code);
      socket.data.code = code;
      socket.data.role = 'player';

      socket.to(code).emit('player-joined', { socketId: socket.id });
      const liveState = buildLiveStateAck(code);
      ack?.({ ok: true, game, liveState });
    });

    // ─── Start game ─────────────────────────────────────────────────────
    socket.on('start-game', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      db.setGameStatus(game.id, 'playing');
      db.setCurrentRound(game.id, 0);

      const live = liveGames.get(code);
      if (live) {
        live.phase = 'board';
        live.questionId = null;
        live.roundIdx = undefined;
        live.topicIdx = undefined;
        live.scoreIdx = undefined;
        live.answerText = undefined;
      }

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

      live.phase = 'question';
      live.roundIdx = roundIdx;
      live.topicIdx = topicIdx;
      live.scoreIdx = scoreIdx;
      live.answerText = undefined;
      live.catRevealed = false;

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

      // For cat questions, delay timer until host calls reveal-cat-question
      if (question.type === 'cat') {
        live.seconds = totalSeconds;
      } else {
        live.interval = setInterval(() => {
          live.seconds--;
          io.to(code).emit('timer-tick', { seconds: live.seconds });
          if (live.seconds <= 0) {
            clearInterval(live.interval);
            live.interval = null;
            io.to(code).emit('timer-ended');
          }
        }, 1000);
      }

      ack?.({ ok: true, questionId: question.id });
    });

    // ─── Reveal answer ──────────────────────────────────────────────────
    socket.on('reveal-answer', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game || !game.current_qid) return ack?.({ error: 'No active question' });

      const question = db.getQuestionById(game.current_qid);
      if (!question) return ack?.({ error: 'Question not found' });

      const live = liveGames.get(code);
      if (live) {
        live.phase = 'result';
        live.answerText = question.answer_text;
      }

      io.to(code).emit('answer-revealed', {
        answerText: question.answer_text,
        questionId: question.id,
      });
      ack?.({ ok: true });
    });

    // ─── Reveal cat question (start timer after cat splash) ────────────
    socket.on('reveal-cat-question', (code, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      const live = liveGames.get(code);
      if (!live || !live.questionId) return ack?.({ error: 'No active question' });

      if (live.interval) clearInterval(live.interval);

      const totalSeconds = live.seconds || 60;
      live.catRevealed = true;
      io.to(code).emit('cat-question-revealed', { timerSeconds: totalSeconds });

      live.interval = setInterval(() => {
        live.seconds--;
        io.to(code).emit('timer-tick', { seconds: live.seconds });
        if (live.seconds <= 0) {
          clearInterval(live.interval);
          live.interval = null;
          io.to(code).emit('timer-ended');
        }
      }, 1000);

      ack?.({ ok: true });
    });

    // ─── Penalize team (deduct points, keep question open) ───────────
    socket.on('penalize-team', ({ code, teamId }, ack) => {
      const game = db.getGameByCode(code);
      if (!game) return ack?.({ error: 'Game not found' });

      const live = liveGames.get(code);
      const qid = game.current_qid || live?.questionId;
      if (!qid) return ack?.({ error: 'No active question' });

      const question = db.getQuestionById(qid);
      if (!question) return ack?.({ error: 'Question not found' });

      db.updateTeamScore(teamId, -question.score);

      const teams = db.getTeams(game.id);
      io.to(code).emit('team-penalized', {
        teamId,
        penaltyScore: question.score,
        teams,
      });

      ack?.({ ok: true, teams });
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

      const awardedScore = (teamId && question.type === 'bonus')
        ? question.score * 2
        : question.score;

      if (teamId) {
        db.updateTeamScore(teamId, awardedScore);
      }

      db.markQuestionUsed(question.id);
      db.setCurrentQuestion(game.id, null);
      if (live) live.questionId = null;

      if (live) {
        live.phase = 'board';
        live.roundIdx = undefined;
        live.topicIdx = undefined;
        live.scoreIdx = undefined;
        live.answerText = undefined;
      }

      const teams = db.getTeams(game.id);
      io.to(code).emit('score-updated', {
        teams,
        awardedTeamId: teamId || null,
        awardedScore,
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

      if (live) {
        live.phase = 'board';
        live.roundIdx = undefined;
        live.topicIdx = undefined;
        live.scoreIdx = undefined;
        live.answerText = undefined;
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

      const live = liveGames.get(code);
      if (live) {
        live.phase = 'board';
        live.questionId = null;
        live.roundIdx = undefined;
        live.topicIdx = undefined;
        live.scoreIdx = undefined;
        live.answerText = undefined;
      }

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
