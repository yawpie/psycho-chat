import { Router } from "express";
import {
  createEncryptedConversation,
  login,
  pasienLogin,
  register,
} from "../services/auth.service";
import { validateAuthRequest } from "../middlewares/auth.middleware";
import {
  addMessageToConversation,
  createConversation,
  getAllConversationsForUsername,
  getConversationPassword,
  getConversationsWithUsernames,
  getLastMessageByConversationId,
  getMessagesByConversationId,
} from "../services/convo.service";
import { Conversation } from "../models/convo.model";
import { prisma } from "../config/prisma";
import { User } from "../models/user.model";

const router = Router();

router.get("/health", (req, res) => {
  res.json({ message: "Health check passed!" });
});

router.get("/auth", (req, res) => {
  res.json({ message: "Auth route" });
});
router.post("/auth/login", validateAuthRequest, async (req, res) => {
  try {
    const user = await login(req.body.username, req.body.password);
    res.json(user);
  } catch (error) {
    res.status(401).json({ message: "Invalid credentials" });
    console.error(
      JSON.stringify({
        level: "error",
        message: "Login failed",
        username: req.body.username,
        error: error instanceof Error ? error.message : String(error),
        timestamp: new Date().toISOString(),
      }),
    );
  }
});

router.post("/auth/create-new-pasien", async (req, res) => {
  try {
    console.log(`Creating new pasien with username: ${req.body.pasienUsername}, createdBy: ${req.body.createdBy}`);
    const conversation = await createEncryptedConversation(
      req.body.pasienUsername,
      req.body.createdBy,
      req.body.password,
      req.body.fullName,
    );
    res.json({ message: "New pasien created successfully", conversation });
  } catch (error) {
    res.status(400).json({ message: "Failed to create new pasien" });
    console.error(
      JSON.stringify({
        level: "error",
        message: "Failed to create new pasien",
        error: error instanceof Error ? error.message : String(error),
        timestamp: new Date().toISOString(),
      }),
    );
  }
});

router.post("/auth/register", validateAuthRequest, async (req, res) => {
  try {
    const user: User = await register(req.body.username, req.body.password);
    console.log(`User ${req.body.username} registered successfully`);
    res.json({ message: "Registration successful", username: user.username });
  } catch (error) {
    res.status(400).json({ message: "Registration failed" });
    console.error(
      JSON.stringify({
        level: "error",
        message: "Registration failed",
        username: req.body.username,
        error: error instanceof Error ? error.message : String(error),
        timestamp: new Date().toISOString(),
      }),
    );
  }
});

router.post("/auth/pasien-login", async (req, res) => {
  try {
    const { password } = req.body;
    if (typeof password !== "string" || !password.trim()) {
      return res.status(400).json({ message: "Password harus diisi" });
    }
    const result = await pasienLogin(password);
    res.json(result);
  } catch (error) {
    res.status(401).json({ message: "Password tidak valid" });
    console.error(
      JSON.stringify({
        level: "error",
        message: "Pasien login failed",
        error: error instanceof Error ? error.message : String(error),
        timestamp: new Date().toISOString(),
      }),
    );
  }
});
router.get("/convo", async (req, res) => {
  try {
    const username = req.query.username;
    if (!username || typeof username !== "string") {
      return res.status(400).json({ message: "Username is required" });
    }
    const conversation = await getAllConversationsForUsername(username);
    res.json(conversation);
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch conversation" });
  }
});

// router.get("/convo/messages/:id", async (req, res) => {
//   try {
//     const messages = await getMessagesByConversationId(parseInt(req.params.id));
//     if (!messages) {
//       return res.status(404).json({ message: "Messages not found" });
//     }
//     res.json(messages);
//   } catch (error) {
//     res.status(500).json({ message: "Failed to fetch messages" });
//   }
// });
router.get("/convo/:id", async (req, res) => {
  try {
    const conversation = await getMessagesByConversationId(req.params.id);
    if (!conversation) {
      return res.status(404).json({ message: "Conversation not found" });
    }
    res.json(conversation);
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch conversation" });
  }
});

router.get("/convo/:id/last", async (req, res) => {
  try {
    const message = await getLastMessageByConversationId(req.params.id);
    if (!message) {
      return res.status(404).json({ message: "Message not found" });
    }
    res.json(message);
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch message" });
  }
});
router.get("/convo/:id/password", async (req, res) => {
  try {
    const password = await getConversationPassword(req.params.id);
    if (!password) {
      return res.status(404).json({ message: "Conversation not found" });
    }
    console.log(`Fetched password for conversation ${req.params.id}, password: ${password}`);
    res.json({ password });
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch conversation password" });
  }
});

router.post("/convo/create", async (req, res) => {
  // Implement conversation creation logic here

  try {
    const { user1, user2, password } = req.body;
    if (
      typeof user1 !== "string" ||
      typeof user2 !== "string" ||
      typeof password !== "string"
    ) {
      return res.status(400).json({ message: "Invalid user data" });
    }

    const conversation = await createConversation(user1, user2, password);
    console.log(
      `Conversation created between ${user1} and ${user2} with ID: ${conversation.id}`,
    );

    res.status(201).json({
      message: "Conversation synchronized successfully",
      conversation,
    });
  } catch (error) {
    res.status(500).json({ message: "Failed to create conversation" });
  }
});
router.post("/messages", async (req, res) => {
  const { sender, text, conversationId, clientMessageId } = req.body;
  try {
    const message = await addMessageToConversation(
      conversationId,
      sender,
      text, // biarkan as-is, mungkin ciphertext
      clientMessageId
    );
    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ message: "Failed to send message" });
  }
});

router.post("/messages/sync", async (req, res) => {
  const { sender, text, conversationId, clientMessageId } = req.body;

  try {
    if (
      typeof sender !== "string" ||
      typeof text !== "string" ||
      typeof conversationId !== "string" ||
      !sender.trim() ||
      !conversationId.trim() ||
      !text
    ) {
      return res.status(400).json({ message: "Invalid message payload" });
    }

    const message = await addMessageToConversation(
      conversationId,
      sender,
      text,
      typeof clientMessageId === "string" && clientMessageId.trim()
        ? clientMessageId
        : undefined,
    );

    return res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ message: "Failed to sync message" });
  }
});

// for development only
router.delete("/delete-all-convo", async (req, res) => {
  try {
    await prisma.message.deleteMany({});
    await prisma.conversation.deleteMany({});
    res.json({ message: "All data deleted successfully" });
    console.log("All conversations and messages deleted successfully");
  } catch (error) {
    console.error("Failed to delete data:", error);
    res.status(500).json({ message: "Failed to delete data" });
  }
});

export default router;
