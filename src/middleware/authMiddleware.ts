import { Request, Response, NextFunction } from 'express';
import admin from 'firebase-admin';

export const authenticate = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ message: 'Authorization token tidak ditemukan.' });
    return;
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    (req as any).user = decodedToken;
    next();
  } catch (error) {
    console.error('Token tidak valid:', error);
    res.status(401).json({ message: 'Token tidak valid atau expired.' });
    return;
  }
};
