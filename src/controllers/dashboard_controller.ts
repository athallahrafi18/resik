import { Request, Response } from "express";
import db from "../firebase";

export const getDashboardSummary = async (req: Request, res: Response) => {
  try {
    const snapshot = await db.collection("setoran").get();
    const userSnap = await db.collection("users").get();

    let pending = 0;
    let diproses = 0;
    let selesai = 0;

    snapshot.forEach((doc) => {
      const data = doc.data();
      switch (data.status) {
        case "Pending":
          pending++;
          break;
        case "Diproses":
          diproses++;
          break;
        case "Selesai":
          selesai++;
          break;
      }
    });

    res.status(200).json({
      total_transaksi: snapshot.size,
      total_user: userSnap.size,
      pending,
      diproses,
      selesai,
    });
  } catch (error) {
    console.error("Gagal ambil summary dashboard:", error);
    res.status(500).json({ message: "Gagal ambil summary dashboard", error });
  }
};
