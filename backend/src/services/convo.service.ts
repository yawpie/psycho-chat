import { prisma } from "../config/prisma";
import { Conversation, Message } from "../models/convo.model";
import { User } from "../models/user.model";
import bcrypt from "bcrypt";
import {
  _getUserDataById,
  _getUserDataByUsername,
} from "../utils/getUserHelper";

export async function getConversationPassword(conversationId: string): Promise<string | null> {
  const conversation = await prisma.conversation.findUnique({
    where: { id: conversationId },
  });
  return conversation?.password ?? null;
}

export async function createConversation(
  user1: string,
  user2: string,
  password?: string,
): Promise<Conversation> {
  try {
    const user1Data = await _getUserDataByUsername(user1);
    if (!user1Data) {
      throw new Error(`User not found: ${user1}`);
    }
    const user2Data = await _getUserDataByUsername(user2);
    if (!user2Data) {
      throw new Error(`User not found: ${user2}`);
    }
    const sorted = [user1Data.id, user2Data.id].sort();
    const user1Id = sorted[0]; // Ensure user1Id is the smaller ID for consistent ordering
    const user2Id = sorted[1];
    const conversation = await prisma.conversation.create({
      data: {
        user1Id: user1Id,
        user2Id: user2Id,
        password: password ?? null,
      },
    });
    const convoWithUsernames: Conversation = {
      id: conversation.id,
      user1: user1Data.username,
      user2: user2Data.username,
      user1DisplayName: user1Data.description,
      user2DisplayName: user2Data.description,
      createdAt: conversation.createdAt,
      password: conversation.password,
    };
    return convoWithUsernames;
  } catch (error) {
    console.error(error);

    throw new Error(
      `Failed to create conversation: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

export async function getLastMessageByConversationId(
  convoId: string,
): Promise<Message> {
  const message = await prisma.message.findFirstOrThrow({
    where: {
      conversationId: convoId,
    },
    orderBy: {
      createdAt: "desc",
    },
    select: {
      id: true,
      sender: {
        select: {
          username: true,
        },
      },
      message: true,
      createdAt: true,
      conversationId: true,
    },
  });

  const formattedMessage: Message = {
    id: message.id,
    sender: message.sender.username,
    message: message.message,
    createdAt: message.createdAt,
    conversationId: message.conversationId,
  };

  return formattedMessage;
}

export async function getAllConversationsForUsername(
  username: string,
): Promise<Conversation[]> {
  try {
    const userId = (await _getUserDataByUsername(username)).id;
    if (!userId) {
      throw new Error(`User not found: ${username}`);
    }
    // search for conversations where the user is either user1 or user2
    const conversations = await prisma.conversation.findMany({
      where: {
        OR: [{ user1Id: userId }, { user2Id: userId }],
      },
      include: {
        user1: {
          select: {
            username: true,
            description: true,
          },
        },
        user2: {
          select: {
            username: true,
            description: true,
          },
        },
      },
    });
    // Map conversations to include usernames instead of IDs
    const convoWithUsernames: Conversation[] = conversations.map((convo) => ({
      id: convo.id,
      user1: convo.user1.username,
      user2: convo.user2.username,
      user1DisplayName: convo.user1.description,
      user2DisplayName: convo.user2.description,
      createdAt: convo.createdAt,
      password: convo.password,
    }));
    return convoWithUsernames;
  } catch (error) {
    throw new Error(
      `Failed to get conversations for user: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

export async function getConversationsWithUsernames(
  username1: string,
  username2: string,
): Promise<Conversation> {
  const user1Data = await _getUserDataByUsername(username1);
  if (!user1Data) {
    throw new Error(`User not found: ${username1}`);
  }
  const user2Data = await _getUserDataByUsername(username2);
  if (!user2Data) {
    throw new Error(`User not found: ${username2}`);
  }
  const sorted = [user1Data.id, user2Data.id].sort();
  const user1Id = sorted[0];
  const user2Id = sorted[1];
  const conversation = await prisma.conversation.findFirst({
    where: {
      user1Id: user1Id,
      user2Id: user2Id,
    },
    include: {
      user1: {
        select: {
          username: true,
          description: true,
        },
      },
      user2: {
        select: {
          username: true,
          description: true,
        },
      },
    },
  });
  if (!conversation) {
    throw new Error(
      `Conversation not found for users: ${username1} and ${username2}`,
    );
  }
  const convoWithUsernames: Conversation = {
    id: conversation.id,
    user1: conversation.user1.username,
    user2: conversation.user2.username,
    user1DisplayName: conversation.user1.description,
    user2DisplayName: conversation.user2.description,
    createdAt: conversation.createdAt,
    password: conversation.password,
  };
  return convoWithUsernames;
}

export async function getMessagesByConversationId(
  conversationId: string,
): Promise<Message[]> {
  const messages = await prisma.message.findMany({
    where: {
      conversationId,
    },
  });
  const messagesWithSenderUsernames: Message[] = await Promise.all(
    messages.map(async (msg) => {
      const senderData = await _getUserDataById(msg.senderId);
      return {
        id: msg.id,
        sender: senderData.username,
        message: msg.message,
        createdAt: msg.createdAt,
        conversationId: msg.conversationId,
        clientMessageId: msg.clientMessageId,
        status: msg.status,
      };
    }),
  );
  return messagesWithSenderUsernames;
}

export async function addMessageToConversation(
  conversationId: string,
  sender: string,
  message: string, // text was renamed to message in the database schema
  clientMessageId?: string,
): Promise<Message> {
  const senderData = await _getUserDataByUsername(sender);
  if (!senderData) {
    throw new Error(`User not found: ${sender}`);
  }

  if (clientMessageId) {
    const existingMessage = await prisma.message.findUnique({
      where: { clientMessageId },
    });

    if (existingMessage) {
      return {
        id: existingMessage.id,
        sender: senderData.username,
        message: existingMessage.message,
        createdAt: existingMessage.createdAt,
        conversationId: existingMessage.conversationId,
        clientMessageId: existingMessage.clientMessageId,
        status: existingMessage.status,
      };
    }
  }

  const newMessage = await prisma.message.create({
    data: {
      senderId: senderData.id,
      message: message,
      conversationId,
      clientMessageId: clientMessageId ?? null,
    },
  });

  return {
    id: newMessage.id,
    sender: senderData.username,
    message: newMessage.message,
    createdAt: newMessage.createdAt,
    conversationId: newMessage.conversationId,
    clientMessageId: newMessage.clientMessageId,
    status: newMessage.status,
  };
}
export async function updateMessageStatus(
  clientMessageId: string,
  status: "sent" | "received" | "read" | "error",
): Promise<Message> {
  const updatedMessage = await prisma.message.update({
    where: { clientMessageId },
    data: { status },
  });
  return {
    id: updatedMessage.id,
    sender: updatedMessage.senderId, // You might want to fetch the actual sender username
    message: updatedMessage.message,
    createdAt: updatedMessage.createdAt,
    conversationId: updatedMessage.conversationId,
    clientMessageId: updatedMessage.clientMessageId,
    status: updatedMessage.status,
  };
}