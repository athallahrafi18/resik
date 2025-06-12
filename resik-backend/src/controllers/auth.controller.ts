import { Request, Response } from 'express';
import db from '../firebase';
import { User } from '../interfaces/User';
import bcrypt from 'bcrypt';
import admin from 'firebase-admin';

export const register = async (req: Request, res: Response): Promise<void> => {
  const { uid, username, email, phone, password } = req.body;

  if (!uid || !username || !email || !phone || !password) {
    res.status(400).json({ message: 'Semua field wajib diisi.' });
    return;
  }

  try {
    // Cek apakah email sudah digunakan
    const snapshot = await db.collection('users').where('email', '==', email).get();

    if (!snapshot.empty) {
      res.status(409).json({ message: 'Email sudah terdaftar.' });
      return;
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser: User = {
      uid,
      username,
      email,
      phone,
      password: hashedPassword,
      role: 'user', // role default untuk yang register sendiri
      createdAt: new Date(),
    };

    await db.collection('users').add(newUser);

    res.status(201).json({ message: 'Pendaftaran berhasil.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Terjadi kesalahan server.', error });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  const { token } = req.body;

  if (!token) {
    res.status(400).json({ message: 'Token tidak ditemukan.' });
    return;
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    const uid = decoded.uid;

    const snapshot = await db.collection('users').where('uid', '==', uid).get();

    if (snapshot.empty) {
      res.status(404).json({ message: 'User tidak ditemukan di database.' });
      return;
    }

    const userData = snapshot.docs[0].data();

    res.status(200).json({
      uid,
      email: userData.email,
      role: userData.role,
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(401).json({ message: 'Token tidak valid atau expired.' });
  }
};

export const updateFcmToken = async (req: Request, res: Response): Promise<void> => {
  const { uid, fcmToken } = req.body;
  if (!uid || !fcmToken) {
    res.status(400).json({ message: 'uid dan fcmToken wajib diisi.' });
    return;
  }
  try {
    const userRef = db.collection('users').where('uid', '==', uid);
    const snapshot = await userRef.get();
    if (snapshot.empty) {
      res.status(404).json({ message: 'User tidak ditemukan.' });
      return;
    }
    // Update FCM token untuk dokumen user pertama yang ditemukan
    await snapshot.docs[0].ref.update({ fcmToken });
    res.json({ success: true });
  } catch (err) {
    console.error("Gagal update fcmToken:", err);
    res.status(500).json({ message: "Gagal update fcmToken", error: err });
  }
};