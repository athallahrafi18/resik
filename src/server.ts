import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import os from "os"; // untuk log IP
import authRoutes from "./routes/auth";
import barcodeRoutes from './routes/barcode_routes';
import setorRoutes from './routes/setor';
import dashboardRoutes from "./routes/dashboard_routes";

dotenv.config();

const app = express();
const PORT = Number(process.env.PORT) || 5001;

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api", barcodeRoutes);
app.use("/api/setoran", setorRoutes);
app.use("/api", dashboardRoutes);

app.get("/", (req, res) => {
  res.send("Hello from backend!");
});

// ✅ Gunakan 0.0.0.0 agar bisa diakses dari emulator dan jaringan lokal
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);

  // ✅ Tambahkan log IP lokal untuk akses dari perangkat lain
  const interfaces = os.networkInterfaces();
  console.log(`🌐 Available at:`);

  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal) {
        console.log(`👉 http://${iface.address}:${PORT}`);
      }
    }
  }

  console.log(`🤖 Emulator can access via: http://10.0.2.2:${PORT}`);
});
