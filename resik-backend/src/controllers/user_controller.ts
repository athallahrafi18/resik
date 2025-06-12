import { Request, Response } from 'express';
import db from '../firebase';

/**
 * Get all users
 */
export const getAllUsers = async (req: Request, res: Response): Promise<void> => {
  try {
    const snapshot = await db.collection('users').get();
    const users = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        username: data.username ?? '',
        email: data.email ?? '',
        createdAt: data.createdAt ? data.createdAt.toDate() : null,
      };
    });
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: 'Failed to get users', error: err });
  }
};

/**
 * Delete a user by ID
 */
export const deleteUser = async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  try {
    await db.collection('users').doc(id).delete();
    res.status(200).json({ message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete user', error: err });
  }
};

/**
 * Get a user by ID
 */
export const getUserById = async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  try {
    const userSnap = await db.collection('users').where('uid', '==', id).limit(1).get();
    if (userSnap.empty) {
      res.status(404).json({ message: 'User not found' });
      return;
    }
    const userDoc = userSnap.docs[0];
    const data = userDoc.data();
    res.json({
      id: userDoc.id,
      username: data?.username ?? '',
      email: data?.email ?? '',
      phone: data?.phone ?? '',
      createdAt: data?.createdAt ? data.createdAt.toDate() : null,
    });
  } catch (err) {
    res.status(500).json({ message: 'Failed to get user', error: err });
  }
};

/**
 * Put a user by ID
 */
export const updateUser = async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params; // id = uid firebase
  const { username, email, phone } = req.body;

  try {
    // Query dokumen user berdasarkan field 'uid', bukan docId!
    const userSnap = await db.collection('users').where('uid', '==', id).limit(1).get();
    if (userSnap.empty) {
      res.status(404).json({ message: 'User not found' });
      return;
    }
    const userDoc = userSnap.docs[0];
    await userDoc.ref.update({ username, email, phone });
    res.status(200).json({ message: 'Profile updated' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update user', error: err });
  }
};