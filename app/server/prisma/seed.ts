import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const username = 'admin';
  const plainPassword = 'adminpassword';
  const saltRounds = 12; // cost 12

  console.log('Seeding database...');

  // Check if admin already exists
  const existingAdmin = await prisma.user.findUnique({
    where: { username },
  });

  if (existingAdmin) {
    console.log(`User "${username}" already exists. Skipping creation.`);
  } else {
    console.log(`Hashing password for "${username}"...`);
    const passwordHash = await bcrypt.hash(plainPassword, saltRounds);

    console.log(`Creating user "${username}"...`);
    const adminUser = await prisma.user.create({
      data: {
        username,
        passwordHash,
      },
    });
    console.log(`User "${username}" created with ID: ${adminUser.id}`);
  }

  console.log('Database seeding completed successfully.');
}

main()
  .catch((e) => {
    console.error('Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
