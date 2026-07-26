# System Architecture — SentraGO

## Diagram Arsitektur

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SENTRAGO PLATFORM                            │
├──────────────────┬──────────────────┬───────────────────────────────┤
│                  │                  │                               │
│  CUSTOMER APP    │   COURIER APP    │       ADMIN DASHBOARD         │
│  (Flutter)       │   (Flutter)      │       (HTML/CSS/JS)           │
│                  │                  │                               │
│  - Pesanan       │  - Terima Order  │  - Dashboard Statistik       │
│  - Tracking      │  - Navigasi      │  - Manajemen Order           │
│  - Chat          │  - Chat          │  - Manajemen User/Driver     │
│  - Wallet/Topup  │  - Pendapatan    │  - Withdrawal Management     │
│  - Live CS       │  - Tarik Saldo   │  - Live CS Chat              │
│  - Notifikasi    │  - Live CS       │  - Laporan & Grafik          │
│                  │  - Notifikasi    │                               │
└────────┬─────────┴────────┬─────────┴───────────────┬───────────────┘
         │                  │                         │
         │          Appwrite Web SDK / REST            │
         ▼                  ▼                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     BACKEND (Appwrite BaaS)                         │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Database │  │   Auth   │  │ Storage  │  │ Cloud Functions  │   │
│  │          │  │          │  │          │  │                  │   │
│  │ • orders │  │ Email/   │  │ • Photo  │  │ send-push-       │   │
│  │ • chats  │  │ Password │  │ • Struk  │  │ notification.js  │   │
│  │ • users  │  │ OAuth    │  │ • Media  │  │                  │   │
│  │ • etc    │  │          │  │          │  └────────┬─────────┘   │
│  └──────────┘  └──────────┘  └──────────┘           │             │
│                                                     ▼             │
│                                          ┌──────────────────┐      │
│                                          │  Firebase FCM    │      │
│                                          │  Push Notif      │      │
│                                          └──────────────────┘      │
└─────────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    THIRD PARTY SERVICES                             │
│                                                                     │
│  Mapbox (Map & Geocoding)    │    Pakasir (Payment Gateway)         │
│  OSRM (Distance Matrix)      │    Firebase (FCM)                    │
└─────────────────────────────────────────────────────────────────────┘
```

## Stack Teknologi

| Layer | Teknologi |
|---|---|
| **Mobile Framework** | Flutter 3.x (Dart) |
| **State Management** | Riverpod |
| **Routing** | GoRouter |
| **Backend** | Appwrite Cloud (BaaS) |
| **Database** | Appwrite Database (NoSQL document-based) |
| **Auth** | Appwrite Auth (Email/Password, OAuth) |
| **Push Notification** | Firebase Cloud Messaging + Appwrite Cloud Function |
| **Maps** | Flutter Map + Mapbox + OSRM |
| **Payment** | Pakasir (Customer App) |
| **Admin Dashboard** | HTML5, CSS3, Vanilla JS |
| **Local Storage** | SharedPreferences, FlutterSecureStorage |

## Alur Data Antar Komponen

### 1. Alur Pembuatan Pesanan (Customer → Courier)
```
Customer App                           Courier App
    │                                      │
    │── 1. Buat pesanan ──► Appwrite DB ──►│
    │                                      │
    │◄── 3. Status update ──Appwrite DB ◄──│── 2. Kurir accept order
    │                                      │
    │◄── 5. Chat realtime ──Appwrite DB ◄──│── 4. Chat selama antar
    │                                      │
    │◄── 7. Notif "Selesai" ────FCM ◄─────│── 6. Complete order
```

### 2. Alur Live CS (Chat dengan Admin)
```
Customer/Courier App               Admin Dashboard (Web)
    │                                      │
    │── 1. Kirim pesan CS ──► Appwrite DB ──►│
    │                                      │
    │◄── 3. Baca balasan ◄──Appwrite DB ◄──│── 2. Admin balas pesan
    │                                      │
    │   Auto-refresh setiap 3-5 detik       │
```

## Pola Arsitektur

### Mobile App: Feature-based Clean Architecture
```
lib/
├── core/               # Shared config, services, constants
│   ├── config/
│   ├── constants/
│   ├── services/
│   └── routes/
├── features/           # Per-fitur
│   ├── auth/
│   │   ├── data/       # Repositories
│   │   ├── domain/     # Models
│   │   └── presentation/  # Providers + Screens
│   ├── order/
│   ├── chat/
│   └── ...
└── main.dart
```

### Admin Dashboard: File-based
```
Dashboard Sentra/
├── js/           # JavaScript modules (ES modules)
│   ├── appwrite-config.js   # Shared Appwrite client
│   ├── auth.js              # Auth helpers
│   ├── dashboard.js
│   ├── order.js
│   ├── user.js
│   ├── driver.js
│   ├── reports.js
│   ├── cs.js
│   └── withdrawal.js
├── *.html         # Per-halaman
└── style.css      # Global stylesheet
```
