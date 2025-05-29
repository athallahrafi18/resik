const fs = require("fs");

// Baca file JSON
const serviceAccount = require("./serviceAccountKey.json");

// Escape \n di private key
const privateKey = serviceAccount.private_key.replace(/\n/g, "\\n");

// Susun isi .env
const envData = `
FIREBASE_PROJECT_ID=${serviceAccount.project_id}
FIREBASE_CLIENT_EMAIL=${serviceAccount.client_email}
FIREBASE_PRIVATE_KEY="${privateKey}"
`.trim();

// Tulis ke file .env
fs.writeFileSync(".env", envData);
console.log("✅ Berhasil convert ke .env");
