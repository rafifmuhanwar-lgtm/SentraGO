# 🚀 SentraGO

> Platform Jastip & Suruh Antar On-Demand — 3 Aplikasi, 1 Ekosistem

**SentraGO** adalah platform logistik *on-demand* yang menghubungkan **pelanggan**, **kurir**, dan **admin** dalam satu ekosistem. Pelanggan bisa titip belanja (Jastip) atau menyuruh kurir mengerjakan tugas (Suruh), dilengkapi fitur chat real-time, live tracking, dan pembayaran terintegrasi.

---

## 📱 Aplikasi

| Aplikasi | Platform | Folder | Pengguna |
|---|---|---|---|
| **Customer App** | Flutter (Android/iOS) | `customer_app/` | Pelanggan |
| **Courier App** | Flutter (Android/iOS) | `courier_app/` | Kurir |
| **Admin Dashboard** | HTML/CSS/JS | `Dashboard Sentra/` | Admin CS & Manajemen |

---

## ✨ Fitur Unggulan

### 👤 Customer App
- ✅ Auth (Email/Password & OAuth)
- ✅ Buat pesanan **Jastip** (titip belanja) & **Suruh** (tugas kurir)
- ✅ Peta interaktif (Mapbox) untuk pickup/delivery
- ✅ Hitung ongkos kirim otomatis (berdasarkan jarak)
- ✅ **Live Tracking** kurir real-time
- ✅ **Chat** dengan kurir & **Live CS** dengan admin
- ✅ SentraPay Wallet + Top Up via Pakasir
- ✅ Escrow system (dana diamankan sampai pesanan selesai)
- ✅ Push Notification (FCM)
- ✅ Riwayat pesanan & status real-time

### 🚚 Courier App
- ✅ Auth + KYC Verification + Onboarding
- ✅ Lihat & ambil pesanan yang tersedia
- ✅ 3 tab pesanan: **Tersedia**, **Aktif**, **Riwayat**
- ✅ **Live Tracking** (update lokasi real-time)
- ✅ **Chat** dengan pelanggan
- ✅ **Live CS** dengan admin
- ✅ Ringkasan pendapatan (hari ini, bulan ini, total)
- ✅ **Tarik Saldo** (Withdrawal) ke rekening bank
- ✅ **Riwayat Transaksi** + riwayat penarikan
- ✅ Getar & notifikasi saat ada pesanan baru
- ✅ Online/Offline toggle
- ✅ Pengaturan (notifikasi, privasi, hemat baterai)
- ✅ Push Notification (FCM)

### 🖥️ Admin Dashboard
- ✅ **Dashboard** statistik real-time (total user, driver, pesanan, pendapatan)
- ✅ Grafik pesanan mingguan (Chart.js)
- ✅ Manajemen **Pesanan** (filter, search, status)
- ✅ Manajemen **User** & **Driver**
- ✅ **Withdrawal Management** (setujui/tolak penarikan saldo kurir)
- ✅ **Live CS Chat** — baca & balas chat dari customer/courier
- ✅ Laporan pendapatan + grafik interaktif
- ✅ Auth menggunakan Appwrite (email/password)
- ✅ Auto-refresh data setiap 5 detik

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────┐  ┌─────────────────────┐  ┌──────────────────────┐
│    CUSTOMER APP     │  │     COURIER APP     │  │   ADMIN DASHBOARD    │
│     (Flutter)       │  │      (Flutter)      │  │    (HTML/CSS/JS)     │
├─────────────────────┤  ├─────────────────────┤  ├──────────────────────┤
│ • Jastip & Suruh    │  │ • Ambil Pesanan     │  │ • Statistik Grafis   │
│ • Live Tracking     │  │ • Navigasi & Chat   │  │ • Manajemen Semua    │
│ • Wallet & Top Up   │  │ • Pendapatan        │  │ • Withdrawal Approve │
│ • Live CS           │  │ • Tarik Saldo       │  │ • Live CS Chat       │
└────────┬────────────┘  └────────┬────────────┘  └──────────┬───────────┘
         │                        │                          │
         └────────────────────────┼──────────────────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │     APPWRITE (BaaS)         │
                    │  ┌──────┬──────┬────────┐  │
                    │  │ DB   │ Auth │ Storage│  │
                    │  └──┬───┴──────┴────────┘  │
                    │     │ Cloud Function        │
                    │     │ (send push notif)     │
                    └─────┼──────────────────────┘
                          │
                    ┌─────▼──────┐
                    │  Firebase  │
                    │  FCM Push  │
                    └────────────┘
```

### Stack Teknologi

| Layer | Teknologi |
|---|---|
| **Mobile Framework** | Flutter 3.x (Dart) |
| **State Management** | Riverpod 3.x |
| **Routing** | GoRouter 17.x |
| **Backend** | Appwrite Cloud (BaaS) v1.9 |
| **Database** | Appwrite Document DB (NoSQL) |
| **Auth** | Appwrite Auth (Email/Password + OAuth) |
| **Push Notification** | Firebase Cloud Messaging + Appwrite Cloud Function |
| **Maps & Location** | Flutter Map + Mapbox GL + OSRM + Geolocator |
| **Payment Gateway** | Pakasir (customer app) |
| **Admin Dashboard** | HTML5, CSS3, Vanilla JavaScript (ES Modules) |
| **Charts** | Chart.js |
| **Local Storage** | SharedPreferences + FlutterSecureStorage |
| **Images** | CachedNetworkImage + ImagePicker |

### Struktur Folder

```
sentrago/
├── customer_app/           # Flutter app pelanggan
│   └── lib/
│       ├── core/          # Config, constants, services, routes
│       └── features/      # Per-fitur
│           ├── auth/      #   data → domain → presentation
│           ├── chat/
│           ├── jastip/
│           ├── suruh/
│           ├── order/
│           ├── wallet/
│           ├── tracking/
│           └── notification/
├── courier_app/            # Flutter app kurir
│   └── lib/
│       ├── core/
│       └── features/
│           ├── auth/
│           ├── chat/
│           ├── cs_chat/
│           ├── order/
│           ├── profile/
│           ├── notification/
│           └── settings/
├── Dashboard Sentra/       # Admin web dashboard
│   ├── js/                # ES Modules
│   │   ├── appwrite-config.js
│   │   ├── auth.js
│   │   ├── dashboard.js
│   │   ├── order.js
│   │   ├── user.js
│   │   ├── driver.js
│   │   ├── reports.js
│   │   ├── cs.js
│   │   └── withdrawal.js
│   ├── *.html             # Per-halaman
│   └── style.css
├── appwrite-cloud-function-sendpush/  # Appwrite Cloud Function
│   └── send-push-notification.js
└── docs/                  # Dokumentasi
    ├── architecture.md
    └── erd.md
```

---

## 🗄️ Database Schema

9 collections di Appwrite Database:

| Collection | Tujuan | Key Fields |
|---|---|---|
| `users` | Data pelanggan | name, email, phone, fcmToken |
| `couriers` | Data kurir | name, kendaraan, area, isOnline, kycVerified |
| `orders` | **Pesanan inti** | userId, courierId, status, danaBelanja, ongkir, biayaLayanan |
| `chats` | Chat customer ↔ kurir ↔ admin CS | orderId, senderRole, message, timestamp |
| `withdrawals` | Penarikan saldo kurir | courierId, amount, status (pending/approved/rejected) |
| `notifications` | Riwayat notifikasi in-app | userId, title, body, category, isRead |
| `sentrapay_wallets` | Dompet digital customer | userId, balance |
| `escrow_transactions` | Transaksi escrow | orderId, amount, status |
| `topup_transactions` | Riwayat top up | userId, amount, method, status |

📖 **[Lihat ERD Lengkap →](docs/erd.md)**
📖 **[Lihat Detail Arsitektur →](docs/architecture.md)**

---

## 🔧 Cara Menjalankan

### Prasyarat
- Flutter SDK ^3.9.2
- Akun Appwrite (Cloud)
- Mapbox Access Token
- Akun Firebase (FCM) — opsional (push notification)
- Akun Pakasir — opsional (payment gateway)

### 1. Clone & Setup Environment

```bash
git clone https://github.com/rafifmuhanwar-lgtm/SentraGO.git
cd SentraGO
```

Copy `.env.example` ke `.env` di root, lalu isi konfigurasi:
```bash
cp .env.example customer_app/.env
cp .env.example courier_app/.env
```

### 2. Setup Appwrite

Buat project di [Appwrite Console](https://console.cloud.appwrite.io) lalu buat:

| Resource | ID |
|---|---|
| Database | `6a5a2cca002aaa8dd6f8` |
| Collection: `users` | |
| Collection: `couriers` | |
| Collection: `orders` | |
| Collection: `chats` | |
| Collection: `withdrawals` | |
| Collection: `notifications` | |
| Storage Bucket | `6a5d565700192c93077a` |

Detail field tiap collection → lihat **[ERD Documentation](docs/erd.md)**

### 3. Menjalankan Customer App

```bash
cd customer_app
flutter pub get
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=TOKEN_ANDA
```

### 4. Menjalankan Courier App

```bash
cd courier_app
flutter pub get
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=TOKEN_ANDA
```

### 5. Menjalankan Admin Dashboard

```bash
cd "Dashboard Sentra"
python -m http.server 8000
# atau pake Node: npx http-server -p 8000
```

Buka browser → `http://localhost:8000/dashboard.html`

### 6. Setup Firebase (Push Notification)

1. Buka [Firebase Console](https://console.firebase.google.com) → project `sentrago-27157`
2. Download `google-services.json` → letakkan di `customer_app/android/app/` dan `courier_app/android/app/`
3. Aktifkan Authentication → Sign-in method → Email/Password
4. Setup Cloud Messaging → Dapatkan Server Key
5. Set Environment Variable di Appwrite Function:

| Variable | Value |
|---|---|
| `APPWRITE_API_KEY` | (Appwrite API Key dengan akses dokumen) |
| `FCM_PROJECT_ID` | sentrago-27157 |
| `FCM_CLIENT_EMAIL` | (dari Firebase service account) |
| `FCM_PRIVATE_KEY` | (dari Firebase service account) |

---

## 🎯 Fitur Unggulan untuk Penilaian

| No | Kriteria | Keunggulan SentraGO |
|---|---|---|
| 1 | **Problem & Relevance** | Solusi nyata: jastip & suruh antar untuk pekerja sibuk, anak kos, dan UMKM |
| 2 | **System Architecture** | 3 aplikasi terintegrasi via Appwrite, pola Clean Architecture di Flutter |
| 3 | **Backend & API** | Serverless via Appwrite BaaS + Cloud Function untuk push notification |
| 4 | **Database & Data Modeling** | 9 collection dengan relasi, redundancy untuk backward compat |
| 5 | **Code Quality** | Riverpod, GoRouter, feature-based folder, version control (Git) |
| 6 | **Feature Depth** | Chat realtime, live tracking, escrow, FCM push, withdrawal, live CS, wallet |
| 7 | **Demo Stability** | Appwrite handle backend, Flutter hot reload untuk demo cepat |
| 8 | **Documentation** | README lengkap, ERD, arsitektur diagram, setup guide |

---

## 🧪 Alur Demo (10 Menit)

### Flow 1: Pembuatan Pesanan (Customer → Courier) — 4 menit
1. Buka Customer App → Login → Buat pesanan Jastip
2. Buka Courier App → Login → Tab **Tersedia** → Lihat pesanan baru
3. Courier **Accept** → status berubah → customer dapat notif
4. Buka **Dashboard Admin** → Lihat statistik & daftar pesanan

### Flow 2: Live CS Chat — 3 menit
1. Customer App → Profil → Pusat Bantuan → **Live Chat CS**
2. Kirim pesan "Halo CS"
3. Buka **Dashboard Admin** → **Customer Service** → Lihat chat masuk
4. Admin balas pesan

### Flow 3: Withdrawal — 2 menit
1. Courier App → Tarik Saldo → Ajukan penarikan
2. Buka **Dashboard Admin** → **Withdrawal** → Lihat permintaan
3. Klik **Setuju** → status berubah

### Flow 4: Dashboard — 1 menit
1. Lihat grafik pendapatan (biaya layanan)
2. Filter pesanan by status
3. Lihat laporan

---

## 📸 Screenshot

> *(Tambahkan screenshot aplikasi di sini)*

| Customer App | Courier App | Admin Dashboard |
|---|---|---|
| *(placeholder)* | *(placeholder)* | *(placeholder)* |

---

## 🔮 Fitur Selanjutnya (Future Features)

- **Chatbot Customer Service:** Fitur obrolan (chat) terintegrasi dengan bot untuk layanan pelanggan. Jika bot tidak dapat menjawab atau menyelesaikan masalah, pengguna akan diberikan opsi untuk dihubungkan langsung dengan agen layanan pelanggan (*live agent*).
- **Promo & Voucher Management:** Modul khusus bagi admin untuk membuat dan mengatur kode diskon, periode promo, atau limit penggunaan bagi pengguna.
- **Global Live Map:** Peta interaktif raksasa yang menampilkan pergerakan seluruh kurir aktif secara *real-time* di satu layar (sangat berguna untuk tim *operation/dispatch*).
- **Geofencing & Dynamic Pricing:** Admin dapat menggambar batas wilayah (*polygon*) di peta, misalnya menetapkan "Zona A", di mana jika sedang hujan atau *rush hour*, harga dasar pengiriman akan naik secara otomatis (*surge pricing*).
- **Ticketing/Helpdesk System:** Mengintegrasikan keluhan yang masuk dari Chatbot Customer Service ke dalam *dashboard* admin sebagai "tiket", sehingga agen *customer service* bisa merespons keluhan secara berurutan (*queue*).
- **Google Maps Integration:** Bermigrasi dari layanan pemetaan Mapbox ke Google Maps API untuk meningkatkan akurasi peta, rute, dan kapabilitas lokasi.

---

## 📝 Lisensi

Proyek ini bersifat proprietary. Hak cipta dilindungi undang-undang.

---

## 👥 Tim

**Nama Tim:** *[isi nama tim]*
**Asal Kampus/Sekolah:** *[isi asal]*
**GitHub:** [github.com/rafifmuhanwar-lgtm/SentraGO](https://github.com/rafifmuhanwar-lgtm/SentraGO)
