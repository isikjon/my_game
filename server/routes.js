const express = require('express');
const db = require('./db');

const router = express.Router();

// ─── POST /api/games — create a new game ─────────────────────────────────────

router.post('/games', (req, res) => {
  try {
    const { name } = req.body || {};
    const game = db.createGame(name || '');
    res.status(201).json(game);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/games — list all games ─────────────────────────────────────────

router.get('/games', (req, res) => {
  try {
    const games = db.listGames();
    res.json(games);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/teams — list all distinct team names ───────────────────────────

router.get('/teams', (req, res) => {
  try {
    const teams = db.listAllTeams();
    res.json(teams);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/games/:code — full game state ──────────────────────────────────

router.get('/games/:code', (req, res) => {
  try {
    const game = db.getGameByCode(req.params.code);
    if (!game) return res.status(404).json({ error: 'Game not found' });
    res.json(game);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── DELETE /api/games/:code — delete a game ──────────────────────────────────

router.delete('/games/:code', (req, res) => {
  try {
    const game = db.getGameByCode(req.params.code);
    if (!game) return res.status(404).json({ error: 'Game not found' });
    db.deleteGame(game.id);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── PUT /api/games/:code/setup — bulk set rounds/topics/questions ───────────

router.put('/games/:code/setup', (req, res) => {
  try {
    const game = db.getGameByCode(req.params.code);
    if (!game) return res.status(404).json({ error: 'Game not found' });
    if (game.status !== 'setup') {
      return res.status(400).json({ error: 'Game already started' });
    }

    const { rounds } = req.body;
    if (!Array.isArray(rounds) || rounds.length === 0) {
      return res.status(400).json({ error: 'rounds must be a non-empty array' });
    }

    for (let ri = 0; ri < rounds.length; ri++) {
      const r = rounds[ri];
      if (!r.name) {
        return res.status(400).json({ error: `rounds[${ri}].name is required` });
      }
      if (!Array.isArray(r.topics) || r.topics.length === 0) {
        return res
          .status(400)
          .json({ error: `rounds[${ri}].topics must be a non-empty array` });
      }
      for (let ti = 0; ti < r.topics.length; ti++) {
        const t = r.topics[ti];
        if (!t.name) {
          return res
            .status(400)
            .json({ error: `rounds[${ri}].topics[${ti}].name is required` });
        }
        if (!Array.isArray(t.questions) || t.questions.length === 0) {
          return res.status(400).json({
            error: `rounds[${ri}].topics[${ti}].questions must be a non-empty array`,
          });
        }
        for (let qi = 0; qi < t.questions.length; qi++) {
          const q = t.questions[qi];
          if (!q || !q.question || !q.answer || !q.score) {
            return res.status(400).json({
              error: `rounds[${ri}].topics[${ti}].questions[${qi}] must have question, answer, score`,
            });
          }
        }
      }
    }

    db.setupGame(game.id, rounds);
    const updated = db.getGameByCode(req.params.code);
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/games/:code/teams — add a team ───────────────────────────────

router.post('/games/:code/teams', (req, res) => {
  try {
    const game = db.getGameByCode(req.params.code);
    if (!game) return res.status(404).json({ error: 'Game not found' });

    const { name } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'Team name is required' });
    }

    const team = db.addTeam(game.id, name.trim());
    res.status(201).json(team);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/games/:code/teams/bulk — add multiple teams at once ───────────

router.post('/games/:code/teams/bulk', (req, res) => {
  try {
    const game = db.getGameByCode(req.params.code);
    if (!game) return res.status(404).json({ error: 'Game not found' });

    const { names } = req.body;
    if (!Array.isArray(names) || names.length === 0) {
      return res
        .status(400)
        .json({ error: 'names must be a non-empty array of strings' });
    }

    const teams = [];
    for (const n of names) {
      if (n && n.trim()) {
        teams.push(db.addTeam(game.id, n.trim()));
      }
    }
    res.status(201).json(teams);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── DELETE /api/teams/:id — remove a team ───────────────────────────────────

router.delete('/teams/:id', (req, res) => {
  try {
    db.removeTeam(Number(req.params.id));
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/games/:code/teams — list teams ────────────────────────────────

router.get('/games/:code/teams', (req, res) => {
  try {
    const game = db.getGameByCode(req.params.code);
    if (!game) return res.status(404).json({ error: 'Game not found' });
    res.json(game.teams);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/templates — list all templates ─────────────────────────────────

router.get('/templates', (req, res) => {
  try {
    const templates = db.listTemplates();
    res.json(templates);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/templates/:id — get template data ─────────────────────────────

router.get('/templates/:id', (req, res) => {
  try {
    const t = db.getTemplate(Number(req.params.id));
    if (!t) return res.status(404).json({ error: 'Template not found' });
    res.json({ ...t, data: JSON.parse(t.data) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/templates — create a template ─────────────────────────────────

router.post('/templates', (req, res) => {
  try {
    const { name, data } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'name is required' });
    }
    if (!data || !data.rounds) {
      return res.status(400).json({ error: 'data.rounds is required' });
    }
    const result = db.createTemplate(name.trim(), JSON.stringify(data));
    res.status(201).json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── DELETE /api/templates/:id — delete a template ───────────────────────────

router.delete('/templates/:id', (req, res) => {
  try {
    db.deleteTemplate(Number(req.params.id));
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
