import { Request, Response } from "express";
import db from "../firebase";

// GET /api/reward-history/:uid
export const getRewardHistory = async (req: Request, res: Response) => {
  const { uid } = req.params;

  try {
    // 1. Ambil Setoran dengan status 'Selesai'
    const setoranSnap = await db.collection("setoran")
      .where("user_id", "==", uid)
      .where("status", "==", "Selesai")
      .get();

    const setoranRiwayat = setoranSnap.docs.map(doc => {
      const d = doc.data();
      return {
        id: doc.id,
        type: "masuk",
        description: "Reward Diterima",
        amount: d.total_harga ?? 0,
        created_at: d.updated_at?.toDate ? d.updated_at.toDate() : d.updated_at,
      };
    });

    // 2. Ambil Reward dengan status 'Berhasil'
    const rewardSnap = await db.collection("reward")
      .where("user_id", "==", uid)
      .where("status", "==", "Berhasil")
      .get();

    const rewardRiwayat = rewardSnap.docs.map(doc => {
      const d = doc.data();
      return {
        id: doc.id,
        type: "keluar",
        description: "Penarikan Reward Berhasil",
        amount: d.nominal ?? 0,
        created_at: d.updated_at?.toDate ? d.updated_at.toDate() : d.updated_at,
      };
    });

    // Gabungkan dan urutkan berdasarkan tanggal terbaru
    const allRiwayat = [...setoranRiwayat, ...rewardRiwayat].sort(
      (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );

    res.json(allRiwayat);
  } catch (err) {
    res.status(500).json({ message: "Gagal mengambil riwayat reward", error: err });
  }
};
