import { prisma } from "../config/prisma";
import { User } from "../models/user.model";

export async function _getUserDataById(userId: string): Promise<User> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });
  if (!user) {
    throw new Error(`User not found: ${userId}`);
  }
  return user;
}

export async function _getUserDataByUsername(username: string): Promise<User> {
  const user = await prisma.user.findUnique({
    where: { username },
  });
  if (!user) {
    throw new Error(`User not found: ${username}`);
  }
  return user;
}