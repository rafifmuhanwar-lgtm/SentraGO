# Outline Presentasi SentraGO — 10 Menit

## Slide 1 — Pembukaan (30 detik)
- Logo SentraGO
- Nama Tim & Anggota
- Asal Kampus/Sekolah
- **Tagline:** "Titip Belanja & Suruh Antar Jadi Lebih Mudah"

## Slide 2 — Latar Belakang (1 menit)
- Masalah: Pekerja sibuk & anak kos kesulitan belanja/antar barang
- Kurir butuh platform fleksibel untuk mencari order
- Admin butuh dashboard monitoring real-time
- **Solusi:** Platform 3-in-1: Customer + Courier + Admin

## Slide 3 — Tujuan Aplikasi (30 detik)
- Memudahkan pelanggan titip belanja (Jastip) & suruh kurir (Suruh)
- Memberikan penghasilan fleksibel bagi kurir
- Monitoring bisnis real-time bagi admin

## Slide 4 — Teknologi (1 menit)
- **Mobile:** Flutter + Riverpod + GoRouter
- **Backend:** Appwrite (BaaS) — Database, Auth, Storage
- **Push Notif:** Firebase FCM + Appwrite Cloud Function
- **Maps:** Flutter Map + Mapbox + OSRM
- **Payment:** Pakasir Gateway
- **Dashboard:** HTML5 + CSS3 + Chart.js + Appwrite SDK

## Slide 5 — Arsitektur Sistem (1 menit)
- Diagram 3 aplikasi → Appwrite → Firebase
- Alur data: Customer buat order → Appwrite → Courier dapat notif
- Live CS: Chat masuk ke Appwrite → Admin baca & balas dari Dashboard

## Slide 6 — Database (1 menit)
- 9 Collection: users, couriers, orders, chats, withdrawals, notifications, sentrapay_wallets, escrow_transactions, topup_transactions
- Relasi utama: orders → users (customer) & couriers (kurir)
- Field redundancy untuk backward compatibility

## Slide 7 — Demo Fitur Utama (3 menit)
- **Flow 1:** Customer login → buat Jastip → Courier terima → tracking
- **Flow 2:** Live CS dari app → Admin balas dari Dashboard
- **Flow 3:** Courier tarik saldo → Admin approve dari Dashboard
- **Flow 4:** Dashboard admin: statistik real-time, grafik, laporan

## Slide 8 — Fitur Unggulan (1 menit)
- ✅ Chat realtime customer-courier-admin CS
- ✅ Live tracking kurir (Mapbox)
- ✅ Escrow wallet (dana aman sampai selesai)
- ✅ Push notification (FCM)
- ✅ Withdrawal management + approve/reject
- ✅ Riwayat transaksi lengkap
- ✅ Live CS 3 arah (customer-courier-admin)
- ✅ Dashboard statistik real-time + grafik

## Slide 9 — Tantangan & Solusi (30 detik)
- **Tantangan:** Integrasi Appwrite dengan multiple platform
- **Solusi:** Shared Appwrite project, collection yang sama
- **Tantangan:** FCM dari customer ke courier
- **Solusi:** Appwrite Cloud Function + Firebase Admin SDK
- **Tantangan:** Real-time chat 3 arah
- **Solusi:** Appwrite Realtime subscription + polling interval

## Slide 10 — Rencana Pengembangan (30 detik)
- AI recommendation untuk kurir terdekat
- Multi-language support
- Progressive Web App (PWA) dashboard
- Analytics & reporting lanjutan
- Integrasi dengan e-commerce

---

# Persiapan Demo — Checklist

## ✅ H-1

- [ ] `flutter clean && flutter pub get` di customer_app & courier_app
- [ ] `flutter run` di 2 device/emulator — pastikan jalan
- [ ] Cek login Appwrite — session valid
- [ ] Buat **data dummy**: 2-3 pesanan, 1-2 withdrawal pending, 2-3 chat CS
- [ ] Test kirim notif — FCM jalan
- [ ] Dashboard Sentra: `python -m http.server 8000` — akses dari browser

## ✅ Saat Demo

- [ ] Laptop charger siap
- [ ] Internet stable (pribadi)
- [ ] Device 1: Customer App (login customer dummy)
- [ ] Device 2: Courier App (login kurir dummy)
- [ ] Laptop: Dashboard Admin (browser)
- [ ] Timer 10 menit — jangan lebih!

## ⚠️ Antisipasi Error

| Masalah | Solusi |
|---|---|
| FCM offline | Push notification skip, notif lokal tetep jalan |
| Appwrite down | Siapin video recording sebagai backup |
| Laptop lemot | Tutup apps lain, matiin wifi scanning |
| Device error | Siapin emulator Android di laptop |
