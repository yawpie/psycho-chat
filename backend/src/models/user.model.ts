export interface User {
    id: number;
    username: string;
    password?: string;
    description: string | null;
    createdAt?: Date;
}