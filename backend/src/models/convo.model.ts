export interface Conversation {
  id: number;
  user1: string;
  user2: string;
  password: string | null;
  createdAt: Date;
}

export interface Message {
  id: number;
  sender: string;
  message: string;
  createdAt: Date;
  conversationId: number;
}
