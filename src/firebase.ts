import admin from "firebase-admin";
import * as dotenv from 'dotenv';

dotenv.config();

// Debug
console.log("🔥 ENV DEBUG:");
console.log("FIREBASE_PROJECT_ID:", process.env.FIREBASE_PROJECT_ID);
console.log("FIREBASE_CLIENT_EMAIL:", process.env.FIREBASE_CLIENT_EMAIL);
console.log("FIREBASE_PRIVATE_KEY exists?", !!process.env.FIREBASE_PRIVATE_KEY);

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY
  }),
});

const db = admin.firestore();
export default db;
