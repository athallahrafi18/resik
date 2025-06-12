import { Request, Response } from "express";
import db from "../firebase";
import { admin } from "../firebase";

// Minimal nominal klaim reward
const MIN_CLAIM = 5000;

export const claimReward = async (req: Request, res: Response): Promise<void> => {
  const user_id = (req as any).user?.uid;
  const { nama, phone, metode, rekening, nominal } = req.body;

  if (!user_id || !nama || !phone || !metode || !rekening || !nominal) {
    res.status(400).json({ message: "Data tidak lengkap" });
    return;
  }
  if (typeof nominal !== "number" || nominal < MIN_CLAIM) {
    res.status(400).json({ message: `Minimal klaim reward Rp${MIN_CLAIM}` });
    return;
  }

  try {
    // 1. Hitung saldo tersedia: total setoran Selesai - total nominal reward diklaim
    // Ambil semua setoran Selesai milik user
    const setoranSnap = await db.collection("setoran")
      .where("user_id", "==", user_id)
      .where("status", "==", "Selesai")
      .get();

    let totalSetoran = 0;
    setoranSnap.forEach(doc => {
      totalSetoran += doc.data().total_harga ?? 0;
    });

    // Ambil semua klaim reward
    const rewardSnap = await db.collection("reward")
      .where("user_id", "==", user_id)
      .get();

    let totalKlaim = 0;
    rewardSnap.forEach(doc => {
      totalKlaim += doc.data().nominal ?? 0;
    });

    // Saldo yang benar-benar tersedia
    const saldo = totalSetoran - totalKlaim;

    if (nominal > saldo) {
      res.status(400).json({ message: "Nominal klaim melebihi saldo yang tersedia." });
      return;
    }

    // Generate reward_id
    const lastReward = await db.collection("reward")
      .orderBy("created_at", "desc")
      .limit(1)
      .get();

    let lastNumber = 0;
    if (!lastReward.empty) {
      const lastId = lastReward.docs[0].data().reward_id;
      const match = lastId?.match(/RW-(\d+)/);
      if (match) {
        lastNumber = parseInt(match[1], 10);
      }
    }
    const reward_id = `RW-${(lastNumber + 1).toString().padStart(3, "0")}`;

    // Simpan reward
    const newReward = {
      reward_id,
      user_id,
      nama,
      phone,
      nominal,
      metode,
      rekening,
      status: "Menunggu",
      created_at: new Date(),
      updated_at: new Date(),
    };

    await db.collection("reward").add(newReward);

    res.status(201).json({ message: "Reward berhasil diklaim.", reward_id, nominal });
  } catch (err) {
    res.status(500).json({ message: "Klaim reward gagal", error: err });
  }
};

// Get saldo reward (saldo = total setoran selesai - total klaim reward)
export const getRewardSaldo = async (req: Request, res: Response): Promise<void> => {
  const user_id = (req as any).user?.uid;
  if (!user_id) {
    res.status(401).json({ message: "Unauthorized" });
    return;
  }

  try {
    // Total setoran selesai
    const setoranSnap = await db.collection("setoran")
      .where("user_id", "==", user_id)
      .where("status", "==", "Selesai")
      .get();

    let totalSetoran = 0;
    setoranSnap.forEach(doc => {
      totalSetoran += doc.data().total_harga ?? 0;
    });

    // Total nominal klaim reward (semua status)
    const rewardSnap = await db.collection("reward")
      .where("user_id", "==", user_id)
      .get();

    let totalKlaim = 0;
    let countBerhasil = 0, countProses = 0, countMenunggu = 0;
    rewardSnap.forEach(doc => {
      const status = doc.data().status;
      const nominal = doc.data().nominal ?? 0;
      totalKlaim += nominal;
      if (status === "Berhasil") countBerhasil++;
      else if (status === "Proses") countProses++;
      else if (status === "Menunggu") countMenunggu++;
    });

    // Saldo yang bisa diklaim
    const saldo = totalSetoran - totalKlaim;

    // Data user
    let username = "";
    let phone = "";
    const userSnap = await db.collection("users")
      .where("uid", "==", user_id)
      .limit(1)
      .get();
    if (!userSnap.empty) {
      const userData = userSnap.docs[0].data();
      username = userData.username ?? "";
      phone = userData.phone ?? "";
    }

    res.status(200).json({
      saldo,
      username,
      phone,
      countBerhasil,
      countProses,
      countMenunggu,
    });
  } catch (err) {
    res.status(500).json({ message: "Gagal ambil saldo reward", error: err });
  }
};

// Lainnya TIDAK berubah (list reward, detail, update status), tapi update juga updated_at jika status berubah
export const getAllRewardList = async (req: Request, res: Response): Promise<void> => {
  const { status } = req.query;

  try {
    let query: FirebaseFirestore.Query = db.collection("reward");
    if (status && status !== "Semua") {
      query = query.where("status", "==", status);
    }
    query = query.orderBy("created_at", "desc");

    const snapshot = await query.get();
    const data = await Promise.all(snapshot.docs.map(async (doc) => {
      const d = doc.data();
      let nama_user = d.nama || d.nama_user || "-";
      if (!nama_user && d.user_id) {
        const userSnap = await db.collection("users").where("uid", "==", d.user_id).limit(1).get();
        if (!userSnap.empty) {
          nama_user = userSnap.docs[0].data().nama ?? "-";
        }
      }
      return {
        id: doc.id,
        reward_id: d.reward_id,
        nama_user,
        nominal: d.nominal ?? 0,
        tanggal_reward: d.created_at?.toDate?.() ?? null,
        status: d.status ?? "Pending",
      };
    }));

    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan saat mengambil daftar reward.", error });
  }
};

export const getRewardDetail = async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const rewardDoc = await db.collection("reward").doc(id).get();
    if (!rewardDoc.exists) {
      res.status(404).json({ message: "Reward tidak ditemukan" });
      return;
    }
    const rewardData = rewardDoc.data();

    // Format waktu klaim
    let createdAtStr = '-';
    if (rewardData?.created_at) {
      const dt = rewardData.created_at.toDate ? rewardData.created_at.toDate() : new Date(rewardData.created_at);
      createdAtStr = dt.toISOString();
    }

    res.status(200).json({
      id: rewardDoc.id,
      reward_id: rewardData?.reward_id ?? '',
      nama: rewardData?.nama ?? '-',
      phone: rewardData?.phone ?? '-',
      metode: rewardData?.metode ?? '-',
      rekening: rewardData?.rekening ?? '-',
      nominal: rewardData?.nominal ?? 0,
      status: rewardData?.status ?? '-',
      created_at: createdAtStr,
    });
  } catch (err) {
    res.status(500).json({ message: "Gagal mengambil detail reward", error: err });
  }
};

// Update status & updated_at
export const updateRewardStatus = async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  const { status } = req.body;

  if (!["Menunggu", "Proses", "Berhasil"].includes(status)) {
    res.status(400).json({ message: "Status tidak valid" });
    return;
  }

  try {
    const rewardRef = db.collection("reward").doc(id);
    const rewardDoc = await rewardRef.get();

    if (!rewardDoc.exists) {
      res.status(404).json({ message: "Reward tidak ditemukan" });
      return;
    }

    await rewardRef.update({ status, updated_at: new Date() });

    const rewardData = rewardDoc.data();
    const user_id = rewardData?.user_id;

    // Compose notification
    let notifTitle = "Update Status Reward";
    let notifBody = `Status reward kamu sekarang: ${status}`;
    let notifType = "reward";
    if (status === "Proses") {
      notifTitle = "Reward Sedang Diproses";
      notifBody = "Klaim reward kamu sedang diproses oleh admin.";
      notifType = "reward";
    } else if (status === "Berhasil") {
      notifTitle = "Reward Berhasil!";
      notifBody = "Klaim reward kamu sudah berhasil. Cek rekening/metode yang dipilih.";
      notifType = "success";
    }

    // *** Tambah: Simpan notifikasi ke Firestore ***
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
          reward_id: id,
          timestamp: new Date(),
          isRead: false,
        });

      // *** Kirim FCM (tidak diubah) ***
      const userSnap = await db.collection("users").where("uid", "==", user_id).limit(1).get();
      if (!userSnap.empty) {
        const userData = userSnap.docs[0].data();
        const fcmToken = userData?.fcmToken;

        if (fcmToken) {
          await admin.messaging().send({
            notification: { title: notifTitle, body: notifBody },
            data: { type: "reward", status, reward_id: id },
            token: fcmToken,
          });
        }
      }
    }

    res.status(200).json({ message: "Status berhasil diupdate & notifikasi dikirim", status });
  } catch (error) {
    res.status(500).json({ message: "Gagal update status", error });
  }
};
