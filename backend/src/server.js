import { WebSocketServer } from 'ws';
import { randomUUID } from 'node:crypto';

const PORT = Number.parseInt(process.env.PORT ?? '3000', 10);
const wss = new WebSocketServer({ port: PORT });
const clients = new Set();

function createMessage(sender, text) {
  return {
    id: randomUUID(),
    sender,
    text,
    timestamp: new Date().toISOString(),
  };
}

function broadcast(payload) {
  const encoded = JSON.stringify(payload);

  for (const client of clients) {
    if (client.readyState === client.OPEN) {
      client.send(encoded);
    }
  }
}

wss.on('connection', (socket) => {
  clients.add(socket);
  socket.send(JSON.stringify(createMessage('system', 'Connected to Psycho Chat backend.')));

  socket.on('message', (data) => {
    const text = data.toString().trim();

    if (!text) {
      socket.send(JSON.stringify(createMessage('system', 'Message cannot be empty.')));
      return;
    }

    broadcast(createMessage('user', text));
  });

  socket.on('close', () => {
    clients.delete(socket);
  });

  socket.on('error', (error) => {
    console.error(JSON.stringify({
      level: 'error',
      message: 'WebSocket client error',
      error: error.message,
      timestamp: new Date().toISOString(),
    }));
  });
});

wss.on('listening', () => {
  console.log(JSON.stringify({
    level: 'info',
    message: `WebSocket server listening on ws://localhost:${PORT}`,
    timestamp: new Date().toISOString(),
  }));
});

wss.on('error', (error) => {
  console.error(JSON.stringify({
    level: 'error',
    message: 'WebSocket server error',
    error: error.message,
    timestamp: new Date().toISOString(),
  }));
  process.exitCode = 1;
});
