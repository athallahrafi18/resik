# Resik (Monorepo)

Project ini berisi dua bagian utama:
- `resik-backend` → Backend menggunakan Express.js + Railway
- `resik-frontend` → Frontend menggunakan Flutter

---

## 📦 Struktur Folder

```
resik/
├── resik-backend/    # Backend Express.js
├── resik-frontend/   # Frontend Flutter
```

---

## ⚙️ Langkah Clone & Setup Project

1. **Clone repository**

```bash
git clone https://github.com/athallahrafi18/resik.git
cd resik
```

---

## 🔧 Setup `resik-backend`

```bash
cd resik-backend
cp .env.example .env    # nanti di kirim file .env nya, skip aja langkah yang ini
npm install
```

> **Catatan:** Isi file `.env` sesuai konfigurasi yang digunakan.

### Run project secara lokal

```bash
npm run dev
```

---

## 💻 Setup `resik-frontend` (Flutter)

```bash
cd ../resik-frontend
flutter pub get
```

> Jika belum install Flutter: [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)

### Run project di Android emulator / device:

```bash
flutter run
```

---

## 🚀 Deployment (Opsional untuk DevOps)

### Backend via Railway:
- Root directory yang digunakan: `resik-backend`
- Jangan deploy seluruh repo root ke Railway, cukup arahkan ke folder `resik-backend`.

### Frontend:
- Belum di-deploy otomatis, gunakan build manual jika perlu (`flutter build apk` atau `flutter build web`)

---

## 👥 Kontribusi

1. Fork → Clone → Buat branch fitur
2. Commit perubahanmu
3. Buat Pull Request (PR)

---

<!-- ## 📄 Lisensi

[MIT License](LICENSE) -->
