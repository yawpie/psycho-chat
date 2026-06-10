import { Router } from "express";
import { login, register } from "../services/auth.service";
import { validateAuthRequest } from "../middlewares/auth.middleware";
import { createConversation, getConversationById } from "../services/convo.service";

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
router.post("/auth/register", validateAuthRequest, async (req, res) => {
  try {
    await register(req.body.username, req.body.password);
    res.json({ message: "Registration successful" });
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

router.get("/conversations/:id", async (req, res) => {
  try {
    const conversation = await getConversationById(parseInt(req.params.id));
    if (!conversation) {
      return res.status(404).json({ message: "Conversation not found" });
    }
    res.json(conversation);
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch conversation" });
  }
});
router.post("/conversations", async (req, res) => {
  // Implement conversation creation logic here
  const { user1, user2 } = req.body;
  try {
    await createConversation(user1, user2);
    res.status(201).json({ message: "Conversation created successfully" });
  } catch (error) {
    res.status(500).json({ message: "Failed to create conversation" });
  }
});
router.post("/messages", async (req, res) => {
  // Implement message sending logic here
  const { sender, text, conversationId } = req.body;
  try {
    
  } catch (error) {
    
  }
    

  res.status(201).json({ message: "Message sent successfully" });
});

export default router;
