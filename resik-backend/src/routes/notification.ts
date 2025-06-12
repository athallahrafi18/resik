import express from 'express';
import { admin } from '../firebase';

const router = express.Router();

router.post('/notify', async (req, res) => {
  const { token, title, body, data } = req.body;

  try {
    const message = {
      notification: {
        title,
        body,
      },
      data: data || {},
      token,
    };

    const response = await admin.messaging().send(message);
    res.json({ success: true, response });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;
