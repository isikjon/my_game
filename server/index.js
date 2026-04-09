const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');
const db = require('./db');
const routes = require('./routes');
const { registerSocket, cleanup } = require('./socket');

const PORT = process.env.PORT || 3000;

const app = express();
app.use(cors());
app.use(express.json({ limit: '5mb' }));
app.use('/api', routes);

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
    credentials: true
  },
  pingInterval: 25000,
  pingTimeout: 20000,
  transports: ['polling', 'websocket'],
  allowUpgrades: true,
  upgradeTimeout: 30000,
  maxHttpBufferSize: 1e6,
});

// init db
db.getDb();

// register socket handlers
registerSocket(io);

// cleanup old games every hour
setInterval(() => db.deleteOldGames(24), 3600_000);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Викторина API running on port ${PORT}`);
});

// graceful shutdown
function shutdown() {
  console.log('Shutting down...');
  cleanup();
  db.closeDb();
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 5000);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

module.exports = { app, server, io };
