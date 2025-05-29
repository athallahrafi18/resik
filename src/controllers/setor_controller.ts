import { Request, Response } from "express";
import db from "../firebase";
import { Query } from "firebase-admin/firestore";
import { SetoranInput } from "../interfaces/SetoranInput";

// Helper untuk generate Order ID seperti SS-001
const generateOrderId = (index: number): string => {
  return `SS-${index.toString().padStart(3, "0")}`;
};

// POST /api/setoran
export const submitSetoran = async (req: Request, res: Response): Promise<void> => {
  const { nama, user_id, alamat, tanggal, catatan, total_harga, sampah } = req.body;

  // Validasi input
  if (!nama || !alamat || !tanggal || !Array.isArray(sampah) || sampah.length === 0) {
    res.status(400).json({ message: "Data tidak lengkap atau tidak valid." });
    return;
  }

  try {
    // Ambil setoran terakhir berdasarkan createdAt
    const snapshot = await db
      .collection("setoran")
      .orderBy("createdAt", "desc")
      .limit(1)
      .get();

    let lastNumber = 0;
    if (!snapshot.empty) {
      const lastId = snapshot.docs[0].data().order_id;
      const match = lastId?.match(/SS-(\d+)/);
      if (match) {
        lastNumber = parseInt(match[1], 10);
      }
    }

    const order_id = generateOrderId(lastNumber + 1);

    const newSetoran = {
      order_id,
      nama,
      user_id,
      alamat,
      tanggal: new Date(tanggal), // ← penting agar bisa digunakan orderBy di Firestore
      catatan,
      total_harga,
      sampah,
      status: "Pending",
      createdAt: new Date(),
    };

    await db.collection("setoran").add(newSetoran);

    res.status(201).json({ message: "Setoran berhasil disimpan.", order_id });
  } catch (error) {
    console.error("Gagal menyimpan setoran:", error);
    res.status(500).json({ message: "Terjadi kesalahan saat menyimpan data.", error });
  }
};

// GET /api/setoran?status=Pending
export const getSetoranList = async (req: Request, res: Response): Promise<void> => {
  const { status, uid } = req.query;

  try {
    let query: Query = db.collection("setoran");

    if (uid) {
      query = query.where("user_id", "==", uid);
    }

    if (status && status !== "Semua") {
      query = query.where("status", "==", status);
    }

    query = query.orderBy("tanggal", "desc");

    const snapshot = await query.get();

    const data = snapshot.docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        order_id: d.order_id,
        nama: d.nama,
        status: d.status,
        tanggal: d.tanggal?.toDate?.() ?? null,
      };
    });

    res.status(200).json(data);
  } catch (error) {
    console.error("Gagal mengambil data setoran:", error);
    res.status(500).json({ message: "Terjadi kesalahan saat mengambil data.", error });
  }
};


// GET /api/setoran/:id
export const getSetoranById = async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const doc = await db.collection("setoran").doc(id).get();

    if (!doc.exists) {
      res.status(404).json({ message: "Data tidak ditemukan" });
      return;
    }

    const data = doc.data();

    // Ambil email dan telepon berdasarkan user_id
    let email = "";
    let phone = "";

    if (data?.user_id) {
      const userSnap = await db
        .collection("users")
        .where("uid", "==", data.user_id)
        .limit(1)
        .get();

      if (!userSnap.empty) {
        const userData = userSnap.docs[0].data();
        email = userData?.email ?? "";
        phone = userData?.phone ?? "";
      }
    }

    res.status(200).json({
      id: doc.id,
      order_id: data?.order_id ?? '',
      nama: data?.nama ?? '',
      email,
      phone,
      alamat: data?.alamat ?? '',
      tanggal: data?.createdAt?.toDate?.() ?? '',
      catatan: data?.catatan ?? '',
      total_harga: data?.total_harga ?? 0,
      status: data?.status ?? 'Pending',
      sampah: data?.sampah ?? [],
    });
  } catch (error: any) {
    console.error("Gagal mengambil detail setoran:", error.message ?? error);
    res.status(500).json({ message: "Terjadi kesalahan saat mengambil detail.", error });
  }
};