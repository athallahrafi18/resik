import { Request, Response } from 'express';
import path from 'path';
import xlsx from 'xlsx';

// Fungsi bantu
const extractVolume = (name: string): number | null => {
  const match = name.match(/\d+/);
  return match ? parseInt(match[0]) : null;
};

export const lookupBarcode = (req: Request, res: Response) => {
  const { barcode } = req.body;
  if (!barcode) return res.status(400).json({ message: 'Barcode diperlukan.' });

  try {
    // === Load Excel Files ===
    const barcodePath = path.join(__dirname, '../../data/Barcode_data_terklasifikasi_prediksi.xlsx');
    const beratPath = path.join(__dirname, '../../data/Berat_sampah.xlsx');
    const hargaPath = path.join(__dirname, '../../data/Harga_Sampah.xlsx');

    const barcodeWB = xlsx.readFile(barcodePath);
    const beratWB = xlsx.readFile(beratPath);
    const hargaWB = xlsx.readFile(hargaPath);

    const barcodeData = xlsx.utils.sheet_to_json<any>(barcodeWB.Sheets[barcodeWB.SheetNames[0]]);
    const beratData = xlsx.utils.sheet_to_json<any>(beratWB.Sheets[beratWB.SheetNames[0]]);
    const hargaData = xlsx.utils.sheet_to_json<any>(hargaWB.Sheets[hargaWB.SheetNames[0]]);

    // === Cari produk dari barcode
    const produk = barcodeData.find(item => item.Id?.toString() === barcode);
    if (!produk) return res.status(404).json({ message: 'Produk tidak ditemukan.' });

    const nama = produk.Nama;
    const jenis = produk.Jenis || 'Unknown';
    const hargaPerKg = hargaData.find(h => h.Jenis === jenis)?.Harga || 0;
    const hargaPerGram = hargaPerKg / 1000;
    const ukuran = extractVolume(nama) || 0;

    // === Cari berat berdasarkan jenis dan ukuran terdekat
    const jenisData = beratData.filter(b => b.Jenis === jenis && b.Ukuran != null && b.Berat != null);
    const closest = jenisData.reduce((prev, curr) => {
      const prevDiff = Math.abs(prev.Ukuran - ukuran);
      const currDiff = Math.abs(curr.Ukuran - ukuran);
      return currDiff < prevDiff ? curr : prev;
    }, jenisData[0]);

    const berat = closest?.Berat || 0;
    const jumlahPerKg = berat > 0 ? Math.floor(1000 / berat) : 0;

    return res.json({
      barcode,
      nama_produk: nama,
      jenis,
      ukuran,
      berat: Math.round(berat),
      jumlah_per_kg: jumlahPerKg,
      harga_per_gram: parseFloat(hargaPerGram.toFixed(2)),
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Terjadi kesalahan server.' });
  }
};
