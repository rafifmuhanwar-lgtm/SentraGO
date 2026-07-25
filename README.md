# SentraGO

SentraGO adalah platform pengiriman dan logistik *on-demand* komprehensif yang terdiri dari tiga komponen utama: **Aplikasi Pelanggan (Customer App)** untuk membuat pesanan, **Aplikasi Kurir (Courier App)** untuk pengemudi mengelola pengiriman, dan **Admin Dashboard** untuk manajemen sistem.

Proyek ini dibangun menggunakan Flutter untuk aplikasi seluler dan HTML/CSS untuk dashboard, serta menggunakan [Appwrite](https://appwrite.io/) sebagai *Backend-as-a-Service* (BaaS) dan Mapbox untuk kapabilitas pemetaan.

---

## 📱 Struktur Proyek

Repositori ini dibagi menjadi direktori utama berikut:

- `/customer_app`: Aplikasi Flutter untuk pelanggan membuat pesanan, melacak pengiriman, melakukan obrolan (chat) dengan kurir, dan mengelola pembayaran.
- `/courier_app`: Aplikasi Flutter untuk kurir/pengemudi menerima pesanan, memperbarui status pengiriman, dan mengelola pendapatan/penarikan saldo.
- `/Dashboard Sentra`: Admin dashboard berbasis HTML/CSS/JS untuk memantau pengguna, kurir, dan seluruh transaksi.

---

## 🔄 Alur Aplikasi (Flow)

### 1. Alur Aplikasi Pelanggan (Customer App)
1. **Registrasi/Login:** Pelanggan masuk ke aplikasi menggunakan autentikasi Appwrite.
2. **Pembuatan Pesanan:** Pelanggan memasukkan lokasi penjemputan (pickup) dan lokasi pengiriman (drop-off) melalui peta interaktif, lalu memilih jenis paket.
3. **Pembayaran:** Pelanggan melakukan pembayaran biaya pengiriman melalui *gateway* pembayaran Pakasir.
4. **Pencarian Kurir:** Sistem mencari kurir terdekat yang tersedia.
5. **Pemantauan & Chat:** Setelah kurir didapatkan, pelanggan dapat memantau lokasi kurir secara *real-time* dan berkomunikasi melalui fitur *chat* bawaan.
6. **Penyelesaian Pesanan:** Saat pesanan tiba, pelanggan akan melihat status pesanan berubah menjadi selesai dan dapat melihat riwayat pesanan.

### 2. Alur Aplikasi Kurir (Courier App)
1. **Login Kurir:** Kurir yang sudah terdaftar dan disetujui masuk ke aplikasi.
2. **Status Online:** Kurir mengaktifkan status agar bisa menerima pesanan masuk.
3. **Menerima Pesanan:** Saat ada pesanan di sekitar, kurir mendapat notifikasi dan dapat "Menerima" pesanan tersebut.
4. **Proses Pengiriman:** Kurir mengikuti navigasi peta menuju lokasi *pickup*, mengambil paket, dan memperbarui status pesanan menjadi "Dalam Perjalanan" (*In Transit*).
5. **Komunikasi:** Kurir dapat melakukan *chat* dengan pelanggan jika membutuhkan panduan jalan atau informasi paket.
6. **Penyelesaian & Pendapatan:** Setelah paket diserahkan, kurir mengubah status menjadi "Terkirim" (*Delivered*). Biaya pengiriman masuk ke saldo akun kurir, yang nantinya bisa ditarik (*withdraw*).

### 3. Alur Admin Dashboard
1. **Pemantauan Global:** Admin masuk ke dashboard web untuk melihat ringkasan pesanan aktif dan memantau keseluruhan sistem.
2. **Manajemen Pengguna & Kurir:** Admin memverifikasi kurir baru yang mendaftar atau mengelola data pengguna.
3. **Pelacakan Transaksi:** Admin memantau seluruh alur pembayaran, penyelesaian pesanan, dan laporan operasional harian.

---

## 🛠️ Teknologi yang Digunakan

### Aplikasi Mobile (Customer & Courier)
- **Framework:** Flutter (Dart)
- **Manajemen State:** Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Routing:** GoRouter (`go_router`)
- **Layanan Backend:** Appwrite SDK (`appwrite`)
- **Networking:** Dio (`dio`)
- **Peta & Lokasi:** Flutter Map (`flutter_map`), Geolocator (`geolocator`), Mapbox
- **Gateway Pembayaran (Customer):** Pakasir
- **Penyimpanan Lokal:** Flutter Secure Storage (`flutter_secure_storage`)
- **UI & Styling:** Google Fonts, Cupertino Icons, Cached Network Image

### Admin Dashboard
- **Frontend:** HTML5, CSS3, Vanilla JavaScript murni.

---

## 🚀 Cara Menjalankan Proyek

Ikuti instruksi berikut untuk menjalankan proyek di perangkat lokal Anda.

### Prasyarat

1. **Flutter SDK:** Pastikan Anda telah menginstal Flutter (SDK `^3.9.2` atau yang kompatibel). [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Dart SDK:** Sudah termasuk di dalam Flutter.
3. **IDE:** VS Code, Android Studio, atau IntelliJ IDEA.
4. **Akun Appwrite:** Proyek aktif di Appwrite Cloud (atau *self-hosted*) dengan Database, Auth, dan Storage yang sudah dikonfigurasi.
5. **Akun Mapbox:** Access Token dari Mapbox untuk merender peta.

---

### Konfigurasi (Environment Variables)

Sebelum menjalankan aplikasi, Anda perlu mengatur *endpoint* Appwrite dan token Mapbox.

#### 1. Konfigurasi Mapbox
Aplikasi membaca Mapbox melalui argumen `--dart-define`. Anda memerlukan Mapbox Access Token (bisa diambil dari file `config.json` di proyek ini).

#### 2. Konfigurasi Appwrite
Pastikan Appwrite Project ID, Database ID, dan Storage Bucket ID sudah disesuaikan pada file konfigurasi masing-masing aplikasi:
- **Customer App:** `customer_app/lib/core/config/app_config.dart`
- **Courier App:** `courier_app/lib/core/config/app_config.dart`

---

### Menjalankan Customer App

1. Masuk ke direktori `customer_app`:
   ```bash
   cd customer_app
   ```
2. Unduh *dependencies* Flutter:
   ```bash
   flutter pub get
   ```
3. Jalankan *code generator* untuk Riverpod dan *annotations* lainnya (jika diperlukan):
   ```bash
   dart run build_runner build -d
   ```
4. Jalankan aplikasi (ganti `YOUR_MAPBOX_TOKEN` dengan token asli Anda):
   ```bash
   flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN
   ```

---

### Menjalankan Courier App

1. Masuk ke direktori `courier_app`:
   ```bash
   cd courier_app
   ```
2. Unduh *dependencies* Flutter:
   ```bash
   flutter pub get
   ```
3. Jalankan *code generator*:
   ```bash
   dart run build_runner build -d
   ```
4. Jalankan aplikasi:
   ```bash
   flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN
   ```

---

### Menjalankan Admin Dashboard

Dashboard hanya menggunakan file HTML statis. Tidak memerlukan proses *build*.
1. Masuk ke direktori `Dashboard Sentra`.
2. Buka file `dashboard.html` di browser web modern apa saja.
   *(Tips: Gunakan ekstensi "Live Server" di VS Code untuk pengalaman pengembangan yang lebih baik).*

---

## 🔒 Referensi Setup Backend (Appwrite)

Untuk men-*deploy* proyek ini ke instans Appwrite Anda sendiri, Anda perlu membuat:
1. **Database** dengan *collection* berikut:
   - `users`
   - `couriers`
   - `orders`
   - `chats`
   - `withdrawals`
2. **Storage Bucket** untuk menyimpan avatar pengguna, foto paket, dan media lainnya.
3. Mengonfigurasi **OAuth providers** (jika menggunakan *social login*) dan memperbarui Redirect URLs pada `app_config.dart`.

---

## 📝 Lisensi

Proyek ini bersifat tertutup (*proprietary*) dan rahasia. Dilarang keras menyalin file-file dalam repositori ini tanpa izin.
