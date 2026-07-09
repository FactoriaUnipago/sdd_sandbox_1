import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import { faker } from '@faker-js/faker';

const prisma = new PrismaClient();

async function main() {
  // Make faker deterministic
  faker.seed(42);

  const adminUsername = 'admin';
  const adminPassword = 'adminpassword';
  const saltRounds = 12;

  console.log('Resetting database...');
  // Clear existing data (cascade delete deletes tasks)
  await prisma.user.deleteMany({});

  console.log('Seeding database with Faker.js (deterministic seed = 42)...');

  // 1. Create Admin User
  console.log('Creating admin user...');
  const adminPasswordHash = await bcrypt.hash(adminPassword, saltRounds);
  const adminUser = await prisma.user.create({
    data: {
      username: adminUsername,
      passwordHash: adminPasswordHash,
    },
  });

  // 2. Create tasks for Admin (25 tasks to meet the min 25 records per table requirement)
  console.log('Generating 25 fake tasks for admin...');
  const adminTasksData = Array.from({ length: 25 }).map(() => ({
    title: faker.hacker.verb().charAt(0).toUpperCase() + faker.hacker.verb().slice(1) + ' ' + faker.hacker.noun(),
    description: faker.lorem.paragraph(),
    completed: faker.datatype.boolean(),
    createdAt: faker.date.recent({ days: 15 }),
    userId: adminUser.id,
  }));

  await prisma.task.createMany({
    data: adminTasksData,
  });

  // 3. Create 24 additional mock users (25 users total including admin)
  console.log('Generating 24 additional fake users and their tasks...');
  const commonPasswordHash = await bcrypt.hash('password123', saltRounds);

  const usersData = Array.from({ length: 24 }).map((_, idx) => {
    // Generate deterministic usernames
    const baseUsername = faker.internet.username().toLowerCase().replace(/[^a-z0-9]/g, '');
    const username = `${baseUsername}${idx + 10}`;
    return {
      username: username.slice(0, 50),
      passwordHash: commonPasswordHash,
    };
  });

  // Create users one by one to ensure unique constraint and retrieve IDs
  const createdUsers = [];
  for (const userData of usersData) {
    try {
      const user = await prisma.user.create({
        data: userData,
      });
      createdUsers.push(user);
    } catch (err) {
      // Fallback if there's any duplicate username collision
      const uniqueUsername = `user${faker.number.int({ min: 100000, max: 999999 })}`;
      const user = await prisma.user.create({
        data: {
          username: uniqueUsername,
          passwordHash: commonPasswordHash,
        },
      });
      createdUsers.push(user);
    }
  }

  // Create tasks for other users (at least 1 task per user, making total tasks > 25)
  console.log('Generating tasks for secondary users...');
  const secondaryTasksData = [];
  for (const user of createdUsers) {
    const tasksCount = faker.number.int({ min: 1, max: 3 });
    for (let i = 0; i < tasksCount; i++) {
      secondaryTasksData.push({
        title: faker.hacker.verb().charAt(0).toUpperCase() + faker.hacker.verb().slice(1) + ' ' + faker.hacker.noun(),
        description: faker.lorem.paragraph(),
        completed: faker.datatype.boolean(),
        createdAt: faker.date.recent({ days: 30 }),
        userId: user.id,
      });
    }
  }

  await prisma.task.createMany({
    data: secondaryTasksData,
  });

  const totalUsers = await prisma.user.count();
  const totalTasks = await prisma.task.count();
  console.log(`Database seeding completed successfully!`);
  console.log(`Created ${totalUsers} users (minimum requirement of 25 met).`);
  console.log(`Created ${totalTasks} tasks (minimum requirement of 25 met).`);
}

main()
  .catch((e) => {
    console.error('Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
