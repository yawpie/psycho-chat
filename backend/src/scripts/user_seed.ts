import { prisma } from "../config/prisma";
import bcrypt from 'bcrypt';
async function main() {
  // Create a new user with a post
  const hashPassword = async (rawPassword: string) => {
   return await bcrypt.hash(rawPassword, 10); // Replace with actual hashing logic, 
  }

  const user1 = await prisma.user.create({
    data: {
      username: "johndoe",
      password: await hashPassword("password"),
      description: "This is a test user.",
    },
  });

  const user2 = await prisma.user.create({
    data: {
      username: "janedoe",
      password: await hashPassword("password"),
      description: "This is a test user.",
    },
  });
  console.log("Created user:", user1, user2);

  // Fetch all users with their posts
  const allUsers = await prisma.user.findMany({
    select: {
      id: true,
      username: true,
    },
  });
  console.log("All users:", JSON.stringify(allUsers, null, 2));
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });