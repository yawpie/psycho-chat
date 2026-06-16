export interface User {
    id: string;
    username: string;
    password?: string;
    description: string | null;
    createdAt?: Date;
}