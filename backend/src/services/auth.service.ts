import { prisma } from "../config/prisma";
import bcrypt from "bcrypt";
import { User } from "../models/user.model";


export async function register(username: string, rawPassword?: string): Promise<void> {
  // Check if the username already exists
  const existingUser = await prisma.user.findUnique({
    where: { username },
  });

  if (existingUser) {
    throw new Error("Username already exists");
  }

  const hashedPassword = await bcrypt.hash(rawPassword || "defaultpassword", 10); // Replace with actual hashing logic

  // Create a new user
  await prisma.user.create({
    data: {
      username,
      password: hashedPassword,
    },
  });
}

export async function login(username: string, rawPassword?: string): Promise<User> {
    // Find the user by username
    const user = await prisma.user.findUnique({
        where: { username },
    });

    if (!user) {
        throw new Error("User not found");
    }

    // Compare the provided password with the hashed password
    const isMatch = await bcrypt.compare(rawPassword || "defaultpassword", user.password);

    if (!isMatch) {
        throw new Error("Invalid password");
    }
    const returnUser : User = {
        id: user.id,
        username: user.username,
        description: user.description || undefined,
        
    }
    return returnUser;

}

async function logout(username: string): Promise<void> {
    // For a stateless API, logout can be handled on the client side by simply removing the token or session.
    // If you are using sessions, you would destroy the session here.
    // This function is a placeholder to indicate where logout logic would go if needed.
}