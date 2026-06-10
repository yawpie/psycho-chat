import { prisma } from "../config/prisma";
import { Conversation } from "../models/convo.model";

export async function createConversation(
  user1: string,
  user2: string,
): Promise<void> {
  await prisma.conversation.create({
    data: {
      user1,
      user2,
    },
  });
}

export async function getConversationsForUser(
  username: string,
): Promise<any[]> {
  const conversations = await prisma.conversation.findMany({
    where: {
      OR: [{ user1: username }, { user2: username }],
    },
    include: {
      messages: true,
    },
  });
  return conversations;
}

export async function getConversationById(
  conversationId: number,
): Promise<Conversation | null> {
  const conversation = await prisma.conversation.findUniqueOrThrow({
    where: {
      id: conversationId,
    },
    include: {
      messages: true,
    },
  });
  let formattedConversation: Conversation | null = null;
  try {
    formattedConversation = {
      id: conversation.id,
      user1: conversation.user1,
      user2: conversation.user2,
      messages: conversation.messages.map((msg) => ({
        id: msg.id,
        sender: msg.sender,
        text: msg.text,
        createdAt: msg.createdAt,
        conversationId: msg.conversationId,
      })),
    };
  } catch (error) {
    formattedConversation = null;
    throw new Error(
      `Failed to format conversation data: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
  return formattedConversation;
}

export async function addMessageToConversation(
  conversationId: number,
  sender: string,
  text: string,
): Promise<void> {
  await prisma.message.create({
    data: {
      sender,
      text,
      conversationId,
    },
  });
}
