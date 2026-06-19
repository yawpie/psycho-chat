export interface Conversation {
  id: string;
  user1: string;
  user2: string;
  user1DisplayName?: string | null;
  user2DisplayName?: string | null;
  password?: string | null;
  createdAt: Date;
}

export interface Message {
  id: string;
  sender: string;
  message: string;
  createdAt: Date;
  conversationId: string;
  clientMessageId?: string | null;
  status?: string | null;
}
