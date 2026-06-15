import { prisma } from "../config/prisma";
import { Conversation, Message } from "../models/convo.model";
import { User } from "../models/user.model";

export async function createConversation(
  user1: string,
  user2: string,
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
      },
    });
    const convoWithUsernames: Conversation = {
      id: conversation.id,
      user1: user1Data.username,
      user2: user2Data.username,
      createdAt: conversation.createdAt,
      password: conversation.password,
    };
    return convoWithUsernames;
  } catch (error) {
    throw new Error(
      `Failed to create conversation: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

async function _getUserDataById(userId: number): Promise<User> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });
  if (!user) {
    throw new Error(`User not found: ${userId}`);
  }
  return user;
}

async function _getUserDataByUsername(username: string): Promise<User> {
  const user = await prisma.user.findUnique({
    where: { username },
  });
  if (!user) {
    throw new Error(`User not found: ${username}`);
  }
  return user;
}

export async function getLastMessageByConversationId(
  convoId: number,
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
      text: true,
      createdAt: true,
      conversationId: true,
    },
  });

  const formattedMessage: Message = {
    id: message.id,
    sender: message.sender.username,
    message: message.text,
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
          },
        },
        user2: {
          select: {
            username: true,
          },
        },
      },
    });
    // Map conversations to include usernames instead of IDs
    const convoWithUsernames: Conversation[] = conversations.map((convo) => ({
      id: convo.id,
      user1: convo.user1.username,
      user2: convo.user2.username,
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
        },
      },
      user2: {
        select: {
          username: true,
        },      },
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
    createdAt: conversation.createdAt,
    password: conversation.password,
  };
  return convoWithUsernames;
}

export async function getMessagesByConversationId(
  conversationId: number,
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
      };
    }),
  );
  return messagesWithSenderUsernames;
}

export async function addMessageToConversation(
  conversationId: number,
  sender: string,
  message: string, // text was renamed to message in the database schema
): Promise<Message> {
  const senderData = await _getUserDataByUsername(sender);
  if (!senderData) {
    throw new Error(`User not found: ${sender}`);
  }
  const newMessage = await prisma.message.create({
    data: {
      senderId: senderData.id,
      message: message,
      conversationId,
    },
  });

  return {
    id: newMessage.id,
    sender: senderData.username,
    message: newMessage.message,
    createdAt: newMessage.createdAt,
    conversationId: newMessage.conversationId,
  };
}
