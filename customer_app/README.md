# SentraGO — Customer App

Aplikasi **pelanggan** untuk platform layanan on-demand **SentraGO**. Dibangun dengan Flutter + Riverpod + GoRouter.

## ✨ Fitur

| Fitur | Status |
|---|---|
| Auth (Email/Password, Google OAuth) | ✅ |
| Register | ✅ |
| Jastip (Form, Summary, Map, Success) | ✅ |
| Suruh (Form, Summary) | ✅ |
| Order (List, Detail, Tracking) | ✅ |
| Chat dengan Kurir | ✅ |
| Top Up Wallet | ✅ |
| Profile (Edit, Address, Payment, Notif, Help) | ✅ |
| Promo | ✅ |
| Onboarding *(coming soon)* | 🔄 |
| Rating & Review Kurir *(coming soon)* | 🔄 |

## 🛠 Tech Stack

- **Framework:** Flutter (SDK ^3.9.2)
- **State Management:** Riverpod (flutter_riverpod + riverpod_annotation)
- **Routing:** go_router
- **Backend:** Appwrite (Auth, Database, Storage, Realtime)
- **Payment:** Pakasir
- **HTTP Client:** Dio
- **Map:** flutter_map + Mapbox
- **Lokasi:** geolocator + geocoding
- **Storage:** flutter_secure_storage
- **QR:** qr_flutter
- **Caching:** cached_network_image

## 🚀 Setup

### 1. Prasyarat

- Flutter SDK ^3.9.2
- Appwrite server
- Akun Pakasir (payment gateway)

### 2. Clone & Install

```bash
git clone <repo-url>
cd customer_app
flutter pub get
```

### 3. Konfigurasi Environment

Buat file `.env` di root `customer_app/`:

```env
APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your_project_id
APPWRITE_DATABASE_ID=your_database_id
APPWRITE_STORAGE_BUCKET_ID=your_bucket_id
PAKASIR_BASE_URL=https://app.pakasir.com
PAKASIR_PROJECT_SLUG=sentrago
PAKASIR_API_KEY=your_pakasir_api_key
MAPBOX_ACCESS_TOKEN=your_mapbox_token
```

Atau copy dari `.env.example`:

```bash
cp ../.env.example .env
```

### 4. Setup Appwrite

Lihat panduan lengkap di [SETUP_APPWRITE.md](./SETUP_APPWRITE.md).

### 5. Jalankan

```bash
flutter run
```

## 📁 Struktur Project

```
lib/
├── main.dart
├── core/
│   ├── config/          # AppConfig, PricingConfig (.env loader)
│   ├── constants/       # AppColors
│   ├── models/          # Shared models
│   ├── routes/          # GoRouter config
│   ├── services/        # Appwrite, Database, Distance, Escrow, Ongkir, Pakasir, Storage
│   ├── theme/           # AppTheme, Typography
│   └── widgets/         # Shared widgets (PhotoPickerTile)
├── features/
│   ├── auth/            # Login, Register
│   ├── chat/            # Chat List, Chat Room
│   ├── home/            # Home, Main, Promo
│   ├── jastip/          # Jastip Form, Summary, Success, Map
│   ├── location/        # Location Selection
│   ├── order/           # Order List, Detail, Courier Receipt, Tracking
│   ├── profile/         # Edit Profile, Addresses, Payment, Help, About, Notif
│   ├── splash/          # Splash screen
│   ├── suruh/           # Suruh Form, Summary
│   └── wallet/          # Top Up, Wallet
```

## 🔐 Environment Variables

Semua API keys dan konfigurasi rahasia disimpan di `.env` (tidak di-commit). Lihat `.env.example` untuk daftar lengkap variabel yang dibutuhkan.

## 🧪 Testing

```bash
flutter test
```

## 📄 Lisensi

Proyek internal — SentraGO.
