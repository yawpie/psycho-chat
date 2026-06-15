/*
  Warnings:

  - You are about to drop the column `user1` on the `conversations` table. All the data in the column will be lost.
  - You are about to drop the column `user2` on the `conversations` table. All the data in the column will be lost.
  - You are about to drop the column `sender` on the `messages` table. All the data in the column will be lost.
  - Added the required column `user1Id` to the `conversations` table without a default value. This is not possible if the table is not empty.
  - Added the required column `user2Id` to the `conversations` table without a default value. This is not possible if the table is not empty.
  - Added the required column `senderId` to the `messages` table without a default value. This is not possible if the table is not empty.

*/
-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_conversations" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "user1Id" INTEGER NOT NULL,
    "user2Id" INTEGER NOT NULL,
    "password" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "conversations_user1Id_fkey" FOREIGN KEY ("user1Id") REFERENCES "users" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "conversations_user2Id_fkey" FOREIGN KEY ("user2Id") REFERENCES "users" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_conversations" ("createdAt", "id", "password") SELECT "createdAt", "id", "password" FROM "conversations";
DROP TABLE "conversations";
ALTER TABLE "new_conversations" RENAME TO "conversations";
CREATE UNIQUE INDEX "conversations_user1Id_user2Id_key" ON "conversations"("user1Id", "user2Id");
CREATE TABLE "new_messages" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "senderId" INTEGER NOT NULL,
    "conversationId" INTEGER NOT NULL,
    "text" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "messages_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "users" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "messages_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "conversations" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_messages" ("conversationId", "createdAt", "id", "text") SELECT "conversationId", "createdAt", "id", "text" FROM "messages";
DROP TABLE "messages";
ALTER TABLE "new_messages" RENAME TO "messages";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
