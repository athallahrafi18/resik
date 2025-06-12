import { SampahItem } from "./SampahItem";

export interface SetoranInput {
  order_id: string;
  nama: string;
  alamat: string;
  tanggal: string; // atau Date jika sudah di-convert
  catatan?: string;
  total_harga: number;
  status?: string;
  sampah: SampahItem[]; // kamu bisa bikin interface `SampahItem` juga kalau mau lebih spesifik
}
