# VoxSight Backend API

Backend Node.js + PostgreSQL untuk sistem monitoring kamera IoT VoxSight.

---

## 🚀 Cara Menjalankan

### 1. Install dependencies
```bash
npm install
```

### 2. Setup environment
```bash
cp .env.example .env
# Edit .env sesuai konfigurasi database kamu
```

### 3. Setup database PostgreSQL
```bash
psql -U postgres -c "CREATE DATABASE voxsight_db;"
psql -U postgres -d voxsight_db -f voxsight_schema.sql
```

### 4. Jalankan server
```bash
# Development (auto-reload)
npm run dev

# Production
npm start
```

Server berjalan di `http://localhost:3000`

---

## 📡 API Endpoints

### Auth

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/api/auth/register` | ❌ | Daftar akun baru |
| POST | `/api/auth/login` | ❌ | Login, dapat JWT token |
| POST | `/api/auth/refresh-token` | ❌ | Refresh JWT token |
| POST | `/api/auth/reset-password` | ❌ | Reset password via email |
| PUT | `/api/auth/change-password` | ✅ | Ganti password (perlu login) |
| GET | `/api/auth/profile` | ✅ | Lihat profil |
| PUT | `/api/auth/profile` | ✅ | Edit profil |

### Dashboard

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/dashboard` | ✅ | Ringkasan semua device (baterai, data, status) |
| GET | `/api/dashboard/device/:id_device` | ✅ | Detail satu device + history 24 jam |

### Device

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/devices` | ✅ | Daftar semua device |
| POST | `/api/devices` | ✅ | Daftarkan device baru |
| DELETE | `/api/devices/:id_device` | ✅ | Hapus device |
| PATCH | `/api/devices/:id_device/status` | ✅ | Update status aktif/nonaktif |

### Monitoring (dari IoT device)

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/api/monitoring/:id_device` | ❌ | Kirim data monitoring (baterai, suhu, data) |

> Auto-generate alert jika `battery < 20%` atau `paket_data < 100MB`

### Lokasi

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/location/:id_device` | ✅ | Lokasi terbaru |
| GET | `/api/location/:id_device/history` | ✅ | Riwayat lokasi |
| GET | `/api/location/:id_device/last-seen` | ✅ | Lokasi terakhir saat device mati |
| POST | `/api/location/:id_device` | ❌ | Kirim lokasi dari IoT device |

### Kamera

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/camera/:id_device` | ✅ | Status kamera terbaru (fps, focus, clarity, latency) |
| GET | `/api/camera/:id_device/history` | ✅ | Riwayat performa kamera |
| POST | `/api/camera/:id_device` | ❌ | Kirim data kamera dari IoT device |

### Alert / Notifikasi

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/api/alerts` | ✅ | Semua alert (support filter & pagination) |
| GET | `/api/alerts/unread-count` | ✅ | Jumlah notifikasi belum dibaca |
| GET | `/api/alerts/device/:id_device` | ✅ | Alert per device |
| PATCH | `/api/alerts/:id/read` | ✅ | Tandai satu alert sudah dibaca |
| PATCH | `/api/alerts/read-all` | ✅ | Tandai semua alert sudah dibaca |

---

## 🔔 Alert Types

| alert_type | Severity | Trigger |
|-----------|----------|---------|
| `LOW_BATTERY` | high / critical | Baterai < 20% |
| `LOW_DATA_PACKAGE` | high / critical | Paket data < 100 MB |
| `DEVICE_OFFLINE` | critical | Device mati, berisi lokasi terakhir |
| `DEVICE_OFFLINE_LOCATION` | high | Device offline saat kirim lokasi |

---

## 🔐 Autentikasi

Semua endpoint yang butuh auth, kirim header:
```
Authorization: Bearer <token>
```

Token didapat setelah login, berlaku 7 hari. Gunakan refresh token untuk perbarui.

---

## 📦 Contoh Request

### Register
```json
POST /api/auth/register
{
  "username": "rafi123",
  "email": "rafi@example.com",
  "password": "password123",
  "nama_lengkap": "Rafi Pratama",
  "nomor_handphone": "08123456789"
}
```

### Login
```json
POST /api/auth/login
{
  "identifier": "rafi123",
  "password": "password123"
}
```

### Kirim Monitoring dari IoT
```json
POST /api/monitoring/<id_device>
{
  "battery": 18.5,
  "paket_data": 85,
  "suhu_cpu": 45.2,
  "suhu_camera": 38.1,
  "internet_active": true
}
```

### Filter Alert
```
GET /api/alerts?is_read=false&severity=critical&page=1&limit=10
```
