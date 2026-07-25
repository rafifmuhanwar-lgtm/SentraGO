# SentraGO — Courier App

Aplikasi **kurir** untuk platform layanan on-demand **SentraGO**. Dibangun dengan Flutter + Riverpod + GoRouter.

## ✨ Fitur

| Fitur | Status |
|---|---|
| Auth (Email/Password, Google OAuth) | ✅ |
| Register | ✅ |
| Onboarding (Pemilihan Kendaraan & Wilayah) | ✅ |
| Verifikasi KYC | ✅ |
| Dashboard Penerimaan Order | ✅ |
| Detail Order & Proof Delivery | ✅ |
| Riwayat Order | ✅ |
| Chat dengan Customer | ✅ |
| Profile & Edit Profile | ✅ |
| Withdrawal / Penarikan Saldo | ✅ |
| Push Notification *(coming soon)* | 🔄 |

## 🛠 Tech Stack

- **Framework:** Flutter (SDK ^3.9.2)
- **State Management:** Riverpod (flutter_riverpod)
- **Routing:** go_router (StatefulShellRoute)
- **Backend:** Appwrite (Auth, Database, Storage, Realtime)
- **HTTP Client:** Dio
- **Map:** flutter_map + Mapbox
- **Lokasi:** geolocator
- **Auth Web:** flutter_web_auth_2

## 🚀 Setup

### 1. Prasyarat

- Flutter SDK ^3.9.2
- Dart SDK ^3.9.2
- Appwrite server (self-hosted atau cloud)

### 2. Clone & Install

```bash
git clone <repo-url>
cd courier_app
flutter pub get
```

### 3. Konfigurasi Environment

Buat file `.env` di root `courier_app/`:

```env
APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your_project_id
APPWRITE_DATABASE_ID=your_database_id
APPWRITE_STORAGE_BUCKET_ID=your_bucket_id
MAPBOX_ACCESS_TOKEN=your_mapbox_token
```

Atau copy dari `.env.example`:

```bash
cp ../.env.example .env
```

### 4. Jalankan

```bash
flutter run
```

## 📁 Struktur Project

```
lib/
├── main.dart
├── core/
│   ├── config/          # AppConfig (.env loader)
│   ├── constants/       # AppColors, AppThemes
│   ├── models/          # Shared models
│   ├── routes/          # GoRouter config
│   └── services/        # Appwrite, Database, Distance
├── features/
│   ├── auth/            # Login, Register, Onboarding, Edit Profile
│   ├── chat/            # Chat List, Chat Room
│   ├── home/            # Home screen
│   ├── kyc/             # KYC verification
│   ├── main/            # Bottom nav shell
│   ├── order/           # Orders, Detail, Receipt, Delivery Proof
│   ├── profile/         # Profile, Help Center, Withdrawal
│   └── splash/          # Splash screen
```

## 🔐 Environment Variables

Semua API keys dan konfigurasi rahasia disimpan di `.env` (tidak di-commit). Lihat `.env.example` untuk daftar lengkap variabel yang dibutuhkan.

## 🧪 Testing

```bash
flutter test
```

## 📄 Lisensi

Proyek internal — SentraGO.
