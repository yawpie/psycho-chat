import { prisma } from "../config/prisma";
import bcrypt from "bcrypt";
import { User } from "../models/user.model";
import { Conversation } from "../models/convo.model";
import { _getUserDataByUsername } from "../utils/getUserHelper";

export async function register(
  username: string,
  rawPassword?: string,
): Promise<User> {
  // Check if the username already exists
  const existingUser = await prisma.user.findUnique({
    where: { username },
  });

  if (existingUser) {
    throw new Error("Username already exists");
  }

  const hashedPassword = await bcrypt.hash(rawPassword || "password", 10); // Replace with actual hashing logic

  // Create a new user
  const newUser = await prisma.user.create({
    data: {
      username,
      password: hashedPassword,
    },
  });
  return { id: newUser.id, username, description: newUser.description || null };
}

export async function login(
  username: string,
  rawPassword?: string,
): Promise<User> {
  // Find the user by username
  console.log(username, rawPassword);

  const user = await prisma.user.findUnique({
    where: { username },
  });

  if (!user) {
    throw new Error("User not found");
  }
  console.log(user);

  // Compare the provided password with the hashed password
  const isMatch = await bcrypt.compare(
    rawPassword || "defaultpassword",
    user.password,
  );

  if (!isMatch) {
    throw new Error("Invalid password");
  }
  const returnUser: User = {
    id: user.id,
    username: user.username,
    description: user.description || null,
  };
  return returnUser;
}

export async function createEncryptedConversation(
  pasienUsername: string, // Username pasien
  createdBy: string, // Username psikiater
  password: string,
  fullName?: string,
) {
  try {
    // const user1Data = await _getUserDataByUsername(user1);
    // if (!user1Data) {
    //   throw new Error(`User not found: ${user1}`);
    // }
    // const user2Data = await _getUserDataByUsername(user2);
    // if (!user2Data) {
    //   throw new Error(`User not found: ${user2}`);
    // }
    const hashedPassword = await bcrypt.hash(password, 10);
    let pasienUsernameData = await prisma.user.findFirst({
      where: {
        username: pasienUsername,
      },
    });
    if (pasienUsernameData) {
      throw new Error(`Username already exists: ${pasienUsername}`);
    } else {
      pasienUsernameData = await prisma.user.create({
        data: {
          username: pasienUsername,
          password: hashedPassword,
          description: fullName ?? null,
        },
      });
    }
    const psikiaterData = await _getUserDataByUsername(createdBy);
    if (!psikiaterData) {
      throw new Error(`User not found: ${createdBy}`);
    }

    const sorted = [pasienUsernameData.id, psikiaterData.id].sort();
    const user1Id = sorted[0];
    const user2Id = sorted[1];

    const conversation = await prisma.conversation.create({
      data: {
        user1Id: user1Id,
        user2Id: user2Id,
        password: hashedPassword,
      },
    });
    const convoWithUsernames: Conversation = {
      id: conversation.id,
      user1: pasienUsernameData.username,
      user2: psikiaterData.username,
      user1DisplayName: pasienUsernameData.description,
      user2DisplayName: psikiaterData.description,
      createdAt: conversation.createdAt,
      password: conversation.password,
    };
    return convoWithUsernames;
  } catch (error) {
    console.error("Error creating conversation with password:", error);
    throw new Error(
      `Failed to create conversation: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

async function logout(username: string): Promise<void> {
  // For a stateless API, logout can be handled on the client side by simply removing the token or session.
  // If you are using sessions, you would destroy the session here.
  // This function is a placeholder to indicate where logout logic would go if needed.
}
