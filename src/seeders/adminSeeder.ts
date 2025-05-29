import db from '../firebase';
import bcrypt from 'bcrypt';

async function seedAdmin() {
  const uid = 'oZlc7nrnFBbkNxp1t5vuKAdYuwh2'; // ganti dengan UID dari Firebase Auth admin kamu
  const email = 'admin@gmail.com';
  const username = 'Super Admin';
  const phone = '08123456789';
  const plainPassword = 'admin123';

  try {
    const snapshot = await db.collection('users').where('email', '==', email).get();
    if (!snapshot.empty) {
      console.log('Admin already exists.');
      return;
    }

    const hashedPassword = await bcrypt.hash(plainPassword, 10);

    await db.collection('users').add({
      uid,
      email,
      username,
      phone,
      password: hashedPassword,
      role: 'admin',
      createdAt: new Date(),
    });

    console.log('Admin seeded successfully!');
  } catch (error) {
    console.error('Error seeding admin:', error);
  }
}

seedAdmin();
