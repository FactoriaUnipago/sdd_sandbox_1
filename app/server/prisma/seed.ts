import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import { faker } from '@faker-js/faker';

const prisma = new PrismaClient();

async function main() {
  const adminUsername = 'admin';
  const adminPassword = 'adminpassword';
  const saltRounds = 12;

  console.log('Resetting database...');
  // Clear existing data (since cascade delete is configured, deleting users deletes tasks)
  await prisma.user.deleteMany({});

  console.log('Seeding database with Faker.js...');

  // 1. Create Admin User
  console.log('Creating admin user...');
  const adminPasswordHash = await bcrypt.hash(adminPassword, saltRounds);
  const adminUser = await prisma.user.create({
    data: {
      username: adminUsername,
      passwordHash: adminPasswordHash,
    },
  });

  // 2. Create tasks for Admin
  console.log('Generating fake tasks for admin...');
  const adminTasksData = Array.from({ length: 8 }).map(() => ({
    title: faker.hacker.verb().charAt(0).toUpperCase() + faker.hacker.verb().slice(1) + ' ' + faker.hacker.noun(),
    description: faker.lorem.paragraph(),
    completed: faker.datatype.boolean(),
    createdAt: faker.date.recent({ days: 15 }),
    userId: adminUser.id,
  }));

  await prisma.task.createMany({
    data: adminTasksData,
  });

  // 3. Create other mock users
  console.log('Generating fake users and tasks...');
  const commonPasswordHash = await bcrypt.hash('password123', saltRounds);

  for (let i = 0; i < 4; i++) {
    // Generate unique username
    const username = faker.internet.username().toLowerCase().slice(0, 15) + faker.number.int({ min: 10, max: 99 });
    const user = await prisma.user.create({
      data: {
        username,
        passwordHash: commonPasswordHash,
      },
    });

    const userTasksCount = faker.number.int({ min: 3, max: 6 });
    const userTasksData = Array.from({ length: userTasksCount }).map(() => ({
      title: faker.hacker.verb().charAt(0).toUpperCase() + faker.hacker.verb().slice(1) + ' ' + faker.hacker.noun(),
      description: faker.lorem.paragraph(),
      completed: faker.datatype.boolean(),
      createdAt: faker.date.recent({ days: 30 }),
      userId: user.id,
    }));

    await prisma.task.createMany({
      data: userTasksData,
    });
  }

  const totalUsers = await prisma.user.count();
  const totalTasks = await prisma.task.count();
  console.log(`Database seeding completed successfully!`);
  console.log(`Created ${totalUsers} users.`);
  console.log(`Created ${totalTasks} tasks.`);
}

main()
  .catch((e) => {
    console.error('Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
