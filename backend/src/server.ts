import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import { createServer } from "node:http";
import { Server } from "socket.io";
import { Message } from "./models/convo.model";
import apiRouter from "./routes/api";

const PORT = Number.parseInt(process.env.PORT ?? "3000", 10);

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// API routes
app.use(apiRouter);

// Global error handling middleware
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error("Unhandled Global Error:", err);

  const errorResponse = {
    success: false,
    message: err.message || "Internal Server Error",
    ...(process.env.NODE_ENV !== "production" && { stack: err.stack }),
  };

  res.status(err.status || 500).json(errorResponse);
});
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

// interface ChatMessage {
//   id: string;
//   sender: string;
//   text: string;
//   timestamp: string;
// }

function createMessage(
  sender: string,
  text: string,
  conversationId?: number,
): Message {
  return {
    sender,
    text,
    createdAt: new Date(),
    conversationId, // No conversation ID for system messages
  };
}

io.on("connection", (socket) => {
  console.log(
    JSON.stringify({
      level: "info",
      message: "Client connected",
      socketId: socket.id,
      timestamp: new Date().toISOString(),
    }),
  );

  // Send welcome message to the connected client
  socket.emit(
    "message",
    createMessage("system", "Connected to Psycho Chat backend."),
  );

  // Listen for incoming messages
  socket.on("message", (text: string) => {
    const trimmedText = text?.trim();

    if (!trimmedText) {
      socket.emit(
        "message",
        createMessage("system", "Message cannot be empty."),
      );
      return;
    }

    // Broadcast message to all connected clients
    const message = createMessage("user", trimmedText);
    io.emit("message", message);

    console.log(
      JSON.stringify({
        level: "info",
        message: "Message broadcasted",
        socketId: socket.id,
        text: trimmedText,
        timestamp: new Date().toISOString(),
      }),
    );
  });

  // Handle disconnection
  socket.on("disconnect", (reason) => {
    console.log(
      JSON.stringify({
        level: "info",
        message: "Client disconnected",
        socketId: socket.id,
        reason,
        timestamp: new Date().toISOString(),
      }),
    );
  });

  // Handle errors
  socket.on("error", (error: Error) => {
    console.error(
      JSON.stringify({
        level: "error",
        message: "Socket error",
        socketId: socket.id,
        error: error.message,
        timestamp: new Date().toISOString(),
      }),
    );
  });
});

server.listen(PORT, () => {
  console.log(
    JSON.stringify({
      level: "info",
      message: `Socket.IO server listening on http://localhost:${PORT}`,
      timestamp: new Date().toISOString(),
    }),
  );
});

// Handle server errors
server.on("error", (error: Error) => {
  console.error(
    JSON.stringify({
      level: "error",
      message: "HTTP server error",
      error: error.message,
      timestamp: new Date().toISOString(),
    }),
  );
  process.exitCode = 1;
});

