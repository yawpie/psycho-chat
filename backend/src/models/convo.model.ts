import { User } from "./user.model";

export interface Conversation {
    id: number;
    user1: string;
    user2: string;
    messages: Message[];
    password?: string;
}

export interface Message {
    id?: number;
    sender: string;
    text: string;
    createdAt: Date;
    conversationId?: number;
}

