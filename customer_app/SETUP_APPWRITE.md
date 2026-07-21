# Panduan Setup Appwrite untuk Sentra

## Daftar Isi
1. [Buat Akun Appwrite](#1-buat-akun-appwrite)
2. [Buat Project](#2-buat-project)
3. [Dapatkan Project ID & Endpoint](#3-dapatkan-project-id--endpoint)
4. [Enable Google OAuth](#4-enable-google-oauth)
5. [Buat Database & Collections](#5-buat-database--collections)
6. [Buat Storage Bucket](#6-buat-storage-bucket)
7. [Update Config di Flutter](#7-update-config-di-flutter)
8. [Setup Android (Deep Link)](#8-setup-android-deep-link)
9. [Setup iOS (Deep Link)](#9-setup-ios-deep-link)
10. [Testing](#10-testing)

---

## 1. Buat Akun Appwrite

1. Buka [https://appwrite.io](https://appwrite.io)
2. Klik **"Get Started"** atau **"Sign Up"** di pojok kanan atas
3. Pilih cara daftar:
   - **GitHub** (recommended — paling cepat)
   - **Google**
   - **Email + Password** (biasa)
4. Ikuti petunjuk pendaftaran
5. Setelah berhasil, kamu akan masuk ke **Appwrite Console**

> ✅ **Gratis, tanpa kartu kredit!** Free tier langsung aktif setelah daftar.

---

## 2. Buat Project

1. Di Appwrite Console, klik tombol **"Create Project"** (atau **"Buat Project"**)
2. Isi:
   - **Project Name:** `Sentra`
   - **Project ID:** biarkan auto-generate (contoh: `67890abcdef1234567890`)
3. Klik **"Create"**
4. Tunggu beberapa detik sampai project terbentuk

---

## 3. Dapatkan Project ID & Endpoint

Setelah project terbentuk, kamu akan masuk ke halaman **Overview** project.

### Yang perlu dicatat:
1. **Project ID** — ada di bagian atas halaman (contoh: `67890abcdef1234567890`)
2. **Endpoint** — biasanya: `https://cloud.appwrite.io/v1`

> Simpan nilai-nilai ini, kita akan pakai di langkah 7.

---

## 4. Enable Google OAuth

### 4.1 Di Appwrite Console
1. Di sidebar kiri, klik **"Auth"** → **"Settings"**
2. Scroll ke bagian **"OAuth2 Providers"**
3. Cari **"Google"**, klik toggle untuk enable
4. Akan muncul form: **App ID**, **App Secret**
5. Biarkan dulu, kita akan isi setelah dapat dari Google Console

### 4.2 Bikin Kredensial Google OAuth
1. Buka [Google Cloud Console](https://console.cloud.google.com)
2. Buat project baru (atau pilih project yang sudah ada)
3. Klik **"APIs & Services"** → **"Credentials"**
4. Klik **"+ Create Credentials"** → **"OAuth client ID"**
5. Pilih **"Web application"**
6. Isi:
   - **Name:** `Sentra Appwrite OAuth`
   - **Authorized redirect URIs:** Klik **"+ Add URI"**
   - Tambahkan: `https://cloud.appwrite.io/v1/account/sessions/oauth2/callback/<PROJECT_ID_KAMU>`
     (ganti `<PROJECT_ID_KAMU>` dengan Project ID dari langkah 3)
7. Klik **"Create"**
8. Akan muncul popup dengan **Client ID** dan **Client Secret**
9. Copy kedua nilai tersebut

### 4.3 Isi Kembali ke Appwrite
1. Kembali ke **Appwrite Console** → **Auth** → **Settings** → **Google OAuth**
2. Isi:
   - **App ID** → isi dengan **Client ID** dari Google
   - **App Secret** → isi dengan **Client Secret** dari Google
3. Klik **"Update"**

> ✅ Google OAuth siap digunakan!

---

## 5. Buat Database & Collections

### 5.1 Buat Database
1. Di sidebar kiri, klik **"Databases"**
2. Klik **"Create Database"**
3. Isi:
   - **Database Name:** `sentra_main`
   - **Database ID:** biarkan auto-generate atau isi `sentra_main`
4. Klik **"Create"**

### 5.2 Buat Collection: `users`
1. Di dalam database `sentra_main`, klik **"Create Collection"**
2. Isi:
   - **Collection Name:** `users`
   - **Collection ID:** `users`
3. Klik **"Create"**
4. Buat attributes (klik **"Add Attribute"**):

| Attribute | Type | Required | Default |
|-----------|------|----------|---------|
| `name` | string | ✅ Yes | (kosong) |
| `email` | string | ✅ Yes | (kosong) |
| `phone` | string | ❌ No | (kosong) |
| `photoUrl` | string | ❌ No | (kosong) |
| `selectedArea` | string | ❌ No | (kosong) |
| `createdAt` | string | ❌ No | (kosong) |

5. Buat index (klik **"Indexes"** → **"Add Index"**):
   - Index `by_email`: `email` (ASC), status `Enabled`

### 5.3 Buat Collection: `orders`
1. Klik **"Create Collection"**
2. Isi:
   - **Collection Name:** `orders`
   - **Collection ID:** `orders`
3. Klik **"Create"**
4. Buat attributes:

| Attribute | Type | Required | Default |
|-----------|------|----------|---------|
| `userId` | string | ✅ Yes | (kosong) |
| `type` | string | ✅ Yes | (kosong) |
| `item` | string | ✅ Yes | (kosong) |
| `pickupLocation` | string | ❌ No | (kosong) |
| `dropoffLocation` | string | ❌ No | (kosong) |
| `budget` | double | ❌ No | 0 |
| `notes` | string | ❌ No | (kosong) |
| `status` | string | ✅ Yes | `pending` |
| `courierId` | string | ❌ No | (kosong) |
| `totalPrice` | double | ❌ No | 0 |
| `createdAt` | string | ❌ No | (kosong) |

5. Buat index:
   - Index `by_user`: `userId` (ASC), status `Enabled`
   - Index `by_status`: `status` (ASC), status `Enabled`

### 5.4 Buat Collection: `chats`
1. Klik **"Create Collection"**
2. Isi:
   - **Collection Name:** `chats`
   - **Collection ID:** `chats`
3. Klik **"Create"**
4. Buat attributes:

| Attribute | Type | Required | Default |
|-----------|------|----------|---------|
| `orderId` | string | ✅ Yes | (kosong) |
| `senderId` | string | ✅ Yes | (kosong) |
| `senderName` | string | ✅ Yes | (kosong) |
| `message` | string | ✅ Yes | (kosong) |
| `timestamp` | string | ❌ No | (kosong) |

5. Buat index:
   - Index `by_order`: `orderId` (ASC), status `Enabled`

> ✅ Database dan collections siap!

---

## 6. Buat Storage Bucket

1. Di sidebar kiri, klik **"Storage"**
2. Klik **"Create Bucket"**
3. Isi:
   - **Bucket Name:** `Sentra Uploads`
   - **Bucket ID:** biarkan auto-generate atau isi `sentra_uploads`
   - **Maximum file size:** `10` (MB)
   - **Allowed file extensions:** kosongkan (biarkan semua)
4. **Permissions:** pilih **"Allow read for any"** (biarkan default)
5. Klik **"Create"**

### Catat Bucket ID
Setelah bucket jadi, catat **Bucket ID** (contoh: `67890abcdef1234567890`)

> ✅ Storage siap!

---

## 7. Update Config di Flutter

### Update file `lib/core/config/app_config.dart`

Buka file `lib/core/config/app_config.dart` dan ganti nilai-nilai berikut:

```dart
class AppConfig {
  AppConfig._();

  static const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
  
  // Ganti dengan Project ID kamu (dari langkah 3)
  static const String appwriteProjectId = '67890abcdef1234567890';
  
  // Ganti dengan Database ID (dari langkah 5.1)
  static const String appwriteDatabaseId = 'sentra_main'; // atau ID auto-generate

  static const String usersCollection = 'users';
  static const String ordersCollection = 'orders';
  static const String chatsCollection = 'chats';

  // Ganti dengan Bucket ID (dari langkah 6)
  static const String storageBucketId = '67890abcdef1234567890';

  // Ganti dengan Project ID di URL ini
  static const String oauthSuccessRedirect = 'appwrite-custom-67890abcdef1234567890://success';
  static const String oauthFailureRedirect = 'appwrite-custom-67890abcdef1234567890://failure';
}
```

**Yang perlu diganti:**
- `YOUR_PROJECT_ID` → Project ID asli (contoh: `67890abcdef...`)
- `YOUR_BUCKET_ID` → Bucket ID asli (contoh: `67890abcdef...`)

---

## 8. Setup Android (Deep Link)

Buka file `android/app/src/main/AndroidManifest.xml`

Di dalam tag `<activity>` yang utama, tambahkan intent filter untuk OAuth redirect:

```xml
<!-- Di dalam <activity android:name=".MainActivity" ... > -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="appwrite-custom-YOUR_PROJECT_ID"
        android:host="success" />
</intent-filter>
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="appwrite-custom-YOUR_PROJECT_ID"
        android:host="failure" />
</intent-filter>
```

**Ganti** `YOUR_PROJECT_ID` dengan Project ID asli kamu.

---

## 9. Setup iOS (Deep Link)

Buka file `ios/Runner/Info.plist`

Tambahkan konfigurasi URL scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.sentra.customer_app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>appwrite-custom-YOUR_PROJECT_ID</string>
        </array>
    </dict>
</array>
```

**Ganti** `YOUR_PROJECT_ID` dengan Project ID asli kamu.

---

## 10. Testing

### Jalankan Aplikasi
```bash
cd customer_app
flutter run
```

### Cek Alur Login
1. App muncul → **Splash Screen** (logo Sentra)
2. Setelah 3 detik → **Location Selection** (pilih area)
3. Tap "Lanjutkan" → **Login Screen**
4. Tap **"Lanjutkan dengan Google"**
5. Browser/popup akan muncul → pilih akun Google kamu
6. Setelah login → langsung ke **Home Screen**
7. Nama kamu muncul di "Hallo, [nama] 👋"

### Cek Profile
1. Tap tab **"Akun"** (paling kanan)
2. Nama dan email kamu muncul di header
3. Bisa tap **"Keluar"** untuk logout

### Cek Appwrite Console
1. Buka **Appwrite Console** → **Auth** → **Users**
   - User baru dengan email Google kamu akan muncul
2. Buka **Databases** → `sentra_main` → `users`
   - Dokumen user baru dengan data kamu akan ada

---

## Troubleshooting

### Error: "OAuth redirect tidak bekerja"
- Pastikan **AndroidManifest.xml** atau **Info.plist** sudah diupdate dengan Project ID yang benar
- Di Android emulator, Google OAuth mungkin perlu Google Play Services
- Coba install ulang app setelah update manifest

### Error: "Failed to create document"
- Pastikan **collection ID** di `app_config.dart` sama dengan yang dibuat di console
- Pastikan **attribute names** sama persis (case sensitive)

### Error: "Storage file upload failed"
- Pastikan **Bucket ID** di `app_config.dart` benar
- Cek **bucket permissions** — pastikan ada izin create

### Error: "Appwrite Client initialization failed"
- Cek koneksi internet
- Pastikan **Endpoint** benar (`https://cloud.appwrite.io/v1`)
- Pastikan **Project ID** benar

---

## Referensi

- [Appwrite Flutter SDK Docs](https://appwrite.io/docs/reference/flutter)
- [Appwrite Console](https://cloud.appwrite.io)
- [Google Cloud Console](https://console.cloud.google.com)
