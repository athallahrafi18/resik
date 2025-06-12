import { Request, Response } from "express";
import db from "../firebase";
import { Query } from "firebase-admin/firestore";
import { admin } from "../firebase";
import { SetoranInput } from "../interfaces/SetoranInput";

// Helper untuk generate Order ID seperti SS-001
const generateOrderId = (index: number): string => {
  return `SS-${index.toString().padStart(3, "0")}`;
};

// POST /api/setoran
export const submitSetoran = async (req: Request, res: Response): Promise<void> => {
  const { nama, alamat, tanggal, catatan, total_harga, sampah } = req.body;
  const user_id = (req as any).user?.uid;

  if (!user_id) {
    res.status(401).json({ message: "User belum login. Token tidak valid." });
    return;
  }

  if (!nama || !alamat || !tanggal || !Array.isArray(sampah) || sampah.length === 0) {
    res.status(400).json({ message: "Data tidak lengkap atau tidak valid." });
    return;
  }

  try {
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
      tanggal: new Date(tanggal),
      catatan,
      total_harga,
      sampah,
      status: "Pending",
      createdAt: new Date(),
      updated_at: new Date(),
      claimed_amount: 0, // Default: 0
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
        total_harga: d.total_harga ?? 0,
        claimed_amount: d.claimed_amount ?? 0,
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
      claimed_amount: data?.claimed_amount ?? 0,
    });
  } catch (error: any) {
    console.error("Gagal mengambil detail setoran:", error.message ?? error);
    res.status(500).json({ message: "Terjadi kesalahan saat mengambil detail.", error });
  }
};

// PATCH hanya update status
export const updateSetoranStatus = async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  const { status } = req.body;
  if (!status) {
    res.status(400).json({ message: "Status wajib diisi." });
    return;
  }
  try {
    // Update status setoran
    await db.collection('setoran').doc(id).update({ status, updated_at: new Date() });

    // Ambil data setoran (buat dapat user_id)
    const setoranDoc = await db.collection('setoran').doc(id).get();
    const setoranData = setoranDoc.data();
    const user_id = setoranData?.user_id;

    // Compose notification content
    let notifTitle = "Update Status Setoran";
    let notifBody = `Status setoran kamu sekarang: ${status}`;
    let notifType = "status_update";
    if (status === "Selesai") {
      notifTitle = "Setoran Selesai!";
      notifBody = "Setoran kamu telah berhasil diverifikasi. Terima kasih!";
      notifType = "success";
    } else if (status === "Gagal") {
      notifTitle = "Setoran Gagal";
      notifBody = "Maaf, setoran kamu gagal. Cek detail atau hubungi admin.";
      notifType = "error";
    }

    // SIMPAN ke Firestore: notifications/{user_id}/items
    if (user_id) {
      await db
        .collection("notifications")
        .doc(user_id)
        .collection("items")
        .add({
          title: notifTitle,
          body: notifBody,
          type: notifType,
          status,
          setoran_id: id,
          timestamp: new Date(),
          isRead: false,
        });

      // Ambil FCM token user dari Firestore (collection 'users', field 'fcmToken')
      const userSnap = await db.collection("users").where("uid", "==", user_id).limit(1).get();
      if (!userSnap.empty) {
        const userData = userSnap.docs[0].data();
        const fcmToken = userData?.fcmToken;

        if (fcmToken) {
          // Kirim FCM notification!
          await admin.messaging().send({
            notification: { title: notifTitle, body: notifBody },
            data: { type: "setoran", status, setoran_id: id },
            token: fcmToken,
          });
        }
      }
    }

    res.status(200).json({ message: "Status berhasil diubah & notifikasi dikirim." });
  } catch (error) {
    res.status(500).json({ message: "Gagal update status / kirim notifikasi.", error });
  }
};

// PUT update semua data setoran, termasuk array sampah
export const updateSetoran = async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  const { status, sampah, total_harga, catatan } = req.body;
  try {
    const updateData: any = {};
    if (status) updateData.status = status;
    if (sampah) updateData.sampah = sampah;
    if (total_harga !== undefined) updateData.total_harga = total_harga;
    if (catatan !== undefined) updateData.catatan = catatan;
    updateData.updated_at = new Date();

    await db.collection('setoran').doc(id).update(updateData);
    res.status(200).json({ message: "Setoran berhasil diupdate." });
  } catch (error) {
    res.status(500).json({ message: "Gagal update data.", error });
  }
};
