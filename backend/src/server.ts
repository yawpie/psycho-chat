import express from 'express';
import cors from 'cors';
import { createServer } from 'node:http';
import { WebSocketServer, WebSocket } from 'ws';
import { randomUUID } from 'node:crypto';

const PORT = Number.parseInt(process.env.PORT ?? '3000', 10);

const app = express();
app.use(cors());
const server = createServer(app);
const wss = new WebSocketServer({ server });

const clients = new Set<WebSocket>();

interface ChatMessage {
  id: string;
  sender: string;
  text: string;
  timestamp: string;
}

function createMessage(sender: string, text: string): ChatMessage {
  return {
    id: randomUUID(),
    sender,
    text,
    timestamp: new Date().toISOString(),
  };
}

function broadcast(payload: ChatMessage): void {
  const encoded = JSON.stringify(payload);

  for (const client of clients) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(encoded);
    }
  }
}

wss.on('connection', (socket: WebSocket) => {
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

  socket.on('error', (error: Error) => {
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

wss.on('error', (error: Error) => {
  console.error(JSON.stringify({
    level: 'error',
    message: 'WebSocket server error',
    error: error.message,
    timestamp: new Date().toISOString(),
  }));
  process.exitCode = 1;
});

server.listen(PORT, () => {
  console.log(JSON.stringify({
    level: 'info',
    message: `HTTP server listening on http://localhost:${PORT}`,
    timestamp: new Date().toISOString(),
  }));
});
