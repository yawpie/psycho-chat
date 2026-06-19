import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import { createServer } from "node:http";
import { Server } from "socket.io";
import apiRouter from "./routes/api";
import { addMessageToConversation, updateMessageStatus } from "./services/convo.service";
import { Message } from "./models/convo.model";

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
  clientMessageId?: unknown;
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

  socket.on("message_delivered", async (data: { clientMessageId: string, receiver: string }) => {
    const { clientMessageId, receiver } = data;
    // Handle message delivered event
    console.log(
      JSON.stringify({
        level: "info",
        message: "Message delivered",
        socketId: socket.id,
        clientMessageId,
        timestamp: new Date().toISOString(),
      }),
    );
    try {
      console.log(`Updating message status to 'received' for clientMessageId: ${clientMessageId}`);
      const updatedMessage = await updateMessageStatus(clientMessageId, "received");
      const receiverSocketId = onlineUsers.get(receiver);
      const payload = {
        ...updatedMessage,
        receiver,
      };
      if (receiverSocketId) {
        io.to(receiverSocketId).emit("message_status_update", payload);
      } else {
        console.log(`Receiver ${receiver} is not online`);
      }
    } catch (error) {
      console.error("Error updating message status:", error);
    }
  });

  socket.on("send_message", async (data: SendMessagePayload) => {
    try {
      const sender = typeof data.sender === "string" ? data.sender.trim() : "";
      // Jangan trim text — bisa berisi ciphertext AES-GCM terenkripsi
      const text = typeof data.text === "string" ? data.text : "";
      const conversationId =
        typeof data.conversationId === "string" ? data.conversationId : "";
      const clientMessageId =
        typeof data.clientMessageId === "string" ? data.clientMessageId : "";

      const receiverUsername =
        typeof data.receiver === "string" ? data.receiver.trim() : "";
      const receiverSocketId = onlineUsers.get(receiverUsername);
      const actualReceiverSocketId =
        receiverSocketId !== null ? receiverSocketId! : "";
      const senderSocketId = onlineUsers.get(sender);
      const actualSenderSocketId =
        senderSocketId !== null ? senderSocketId! : "";

      console.log(`send_message inbound...`);
      console.log(`message: ${text}`);
      
      if (
        !registeredUsername ||
        sender !== registeredUsername ||
        !text ||
        !conversationId
      ) {
        throw new Error("Invalid message payload");
      }

      console.log(`adding message to db...`);
      const message:Message = await addMessageToConversation(
        conversationId,
        sender,
        text,
        clientMessageId,
      );
      console.log(`Message added to db: ${message.id}`);
      console.log(`sending message to clients...`);
      const payload = {
        ...message,
        receiver: receiverUsername,
      };

      io.to(actualReceiverSocketId).emit("receiver_message", payload);
      io.to(actualSenderSocketId).emit("receiver_message", payload);

      // console.log(`Message from ${sender} to ${receiverUsername}: ${text}`);
      // socket.emit("receiver_message", payload);

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

