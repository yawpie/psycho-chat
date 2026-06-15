import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import { createServer } from "node:http";
import { Server } from "socket.io";
import apiRouter from "./routes/api";
import {
  addMessageToConversation,
} from "./services/convo.service";

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

function createSystemMessage(text: string) {
  return {
    id: -1,
    sender: "system",
    text,
    createdAt: new Date(),
    conversationId: -1,
    status: "sent",
  };
}

interface SendMessagePayload {
  sender?: unknown;
  receiver?: unknown;
  text?: unknown;
  conversationId?: unknown;
}

// online user in memory
const onlineUsers = new Map<string, string>();
io.on("connection", (socket) => {
  let registeredUsername: string | null = null;

  console.log(
    JSON.stringify({
      level: "info",
      message: "Client connected",
      socketId: socket.id,
      timestamp: new Date().toISOString(),
    }),
  );
  socket.on("register", (username: string) => {
    if (!username?.trim()) return;
    if (registeredUsername && onlineUsers.get(registeredUsername)) {
      //   onlineUsers.delete(registeredUsername);
    }
    registeredUsername = username.trim();
    onlineUsers.set(registeredUsername, socket.id);
    console.log(
      `User ${registeredUsername} registered with socket ID ${socket.id}`,
    );
  });

  socket.on("send_message", async (data: SendMessagePayload) => {
    try {
      const sender = typeof data.sender === "string" ? data.sender.trim() : "";
      const text = typeof data.text === "string" ? data.text.trim() : "";
      const conversationId =
        typeof data.conversationId === "number" ? data.conversationId : NaN;
      console.log(`send_message inbound...`);
      
      if (
        !registeredUsername ||
        sender !== registeredUsername ||
        !text ||
        !Number.isInteger(conversationId)
      ) {
        throw new Error("Invalid message payload");
      }
      
      console.log(`adding message to db...`);
      const message = await addMessageToConversation(
        conversationId,
        sender,
        text,
      );
      console.log(`Message added to db: ${message.id}`);
      console.log(`sending message to clients...`);
      const payload = {
        ...message,
        status: "sent",
      };

      // console.log(`Message from ${sender} to ${receiverUsername}: ${text}`);
      socket.emit("receiver_message", payload);

      // const receiverSocketId = onlineUsers.get(receiverUsername);
      // if (receiverSocketId && receiverSocketId !== socket.id) {
      //   io.to(receiverSocketId).emit("receiver_message", payload);
      // } else if (!receiverSocketId) {
      //   console.log(`User ${receiverUsername} is not online`);
      // }
    } catch (error) {
      socket.emit("message_error", {
        message:
          error instanceof Error ? error.message : "Failed to send message",
      });
    }
  });
  // Listen for incoming messages
  // socket.on("message", (text: string) => {
  //   const trimmedText = text?.trim();

  //   if (!trimmedText) {
  //     socket.emit(
  //       "message",
  //       createMessage("system", "Message cannot be empty."),
  //     );
  //     return;
  //   }

  //   // Broadcast message to all connected clients
  //   const message = createMessage("user", trimmedText);
  //   io.emit("message", message);

  //   console.log(
  //     JSON.stringify({
  //       level: "info",
  //       message: "Message broadcasted",
  //       socketId: socket.id,
  //       text: trimmedText,
  //       timestamp: new Date().toISOString(),
  //     }),
  //   );
  // });

  // Handle disconnection
  socket.on("disconnect", (reason) => {
    if (
      registeredUsername &&
      onlineUsers.get(registeredUsername) === socket.id
    ) {
      onlineUsers.delete(registeredUsername);
    }

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

