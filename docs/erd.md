# Database Schema — SentraGO

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        APPWRITE DATABASE                             │
│                     ID: 6a5a2cca002aaa8dd6f8                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────┐    ┌──────────────────┐                       │
│  │      users       │    │    couriers      │                       │
│  ├──────────────────┤    ├──────────────────┤                       │
│  │ $id (PK)         │    │ $id (PK)         │                       │
│  │ name             │    │ name             │                       │
│  │ email            │    │ email            │                       │
│  │ phone            │    │ phone            │                       │
│  │ photoUrl         │    │ photoUrl         │                       │
│  │ fcmToken         │    │ fcmToken         │                       │
│  │ status           │    │ vehicleType      │                       │
│  │ $createdAt       │    │ vehiclePlate     │                       │
│  └────────┬─────────┘    │ selectedArea     │                       │
│           │              │ isOnline         │                       │
│           │              │ kycVerified      │                       │
│           │              │ role: 'courier'  │                       │
│           │              │ $createdAt       │                       │
│           │              └────────┬─────────┘                       │
│           │                       │                                │
│           │                       │                                │
│  ┌────────▼───────────────────────▼──────────┐                     │
│  │                 orders                    │                     │
│  ├───────────────────────────────────────────┤                     │
│  │ $id (PK)                                  │                     │
│  │ userId (FK → users.$id)                   │                     │
│  │ courierId (FK → couriers.$id)             │                     │
│  │ type/orderType: 'jastip' | 'suruh'       │                     │
│  │ title/item: nama barang/tugas             │                     │
│  │ description/notes                         │                     │
│  │ status: ongoing | completed | cancelled   │                     │
│  │ statusText: deskripsi status              │                     │
│  │ pickupAddress & dropoffAddress            │                     │
│  │ pickupLat/Lng & dropoffLat/Lng            │                     │
│  │ danaBelanja, ongkir, biayaLayanan        │                     │
│  │ totalAmount / totalPrice                  │                     │
│  │ serviceName                               │                     │
│  │ courierName, courierPhone, courierAvatar  │                     │
│  │ escrowId                                  │                     │
│  │ strukImageUrl, totalBelanjaStruk         │                     │
│  │ deliveryProofUrl, refundCustomer          │                     │
│  │ kebijakanLebih: jangan_lebih | boleh_lebih│                     │
│  │ voucherCode, voucherDiscount              │                     │
│  │ jarakKm, estimasiWaktu                   │                     │
│  │ courierLat, courierLng                    │                     │
│  │ $createdAt, $updatedAt                    │                     │
│  └──────────────────┬────────────────────────┘                     │
│                     │                                              │
│                     │                                              │
│  ┌──────────────────▼────────────────────────┐                     │
│  │                 chats                     │                     │
│  ├───────────────────────────────────────────┤                     │
│  │ $id (PK)                                  │                     │
│  │ orderId: order ID atau cs_chat_{userId}   │                     │
│  │ senderId                                  │                     │
│  │ senderName                                │                     │
│  │ senderRole: customer | courier | admin    │                     │
│  │ message                                   │                     │
│  │ messageType: text | image | video         │                     │
│  │ mediaUrl                                  │                     │
│  │ timestamp                                 │                     │
│  │ $createdAt                                │                     │
│  └───────────────────────────────────────────┘                     │
│                                                                     │
│  ┌──────────────────┐    ┌──────────────────┐                       │
│  │   withdrawals    │    │  notifications   │                       │
│  ├──────────────────┤    ├──────────────────┤                       │
│  │ $id (PK)         │    │ $id (PK)         │                       │
│  │ courierId (FK)   │    │ userId           │                       │
│  │ amount           │    │ title            │                       │
│  │ bankName         │    │ body             │                       │
│  │ accountNumber    │    │ category         │                       │
│  │ status:          │    │ isRead           │                       │
│  │   pending|       │    │ routeName        │                       │
│  │   approved|      │    │ createdAt        │                       │
│  │   rejected       │    │ $createdAt       │                       │
│  │ $createdAt       │    └──────────────────┘                       │
│  └──────────────────┘                                              │
│                                                                     │
│  ┌──────────────────────┐  ┌──────────────────┐                    │
│  │  sentrapay_wallets   │  │ escrow_          │                    │
│  ├──────────────────────┤  │ transactions      │                    │
│  │ userId (PK)          │  ├──────────────────┤                     │
│  │ balance              │  │ orderId          │                    │
│  │ totalTopUp           │  │ customerId       │                    │
│  │ totalSpent           │  │ amount           │                    │
│  │ $createdAt           │  │ status: held|    │                    │
│  └──────────────────────┘  │   released|refund│                    │
│                            │ $createdAt       │                    │
│  ┌──────────────────────┐  └──────────────────┘                    │
│  │    topup_transactions │                                        │
│  ├──────────────────────┤                                         │
│  │ userId, amount,      │                                         │
│  │ method, status       │                                         │
│  │ $createdAt           │                                         │
│  └──────────────────────┘                                         │
└─────────────────────────────────────────────────────────────────────┘
```

## Detail Collection

### `orders` — Collection inti
Field utama yang dikirim dari Customer App saat membuat pesanan:

```json
{
  "$id": "auto-generated",
  "userId": "customer_appwrite_id",
  "type": "jastip",
  "orderType": "jastip",
  "title": "Belanja sayur",
  "item": "Belanja sayur",
  "description": "Tolong beli..."
}
```

### `chats` — Multi-purpose
Collection `chats` digunakan untuk **3 jenis chat**:
1. **Chat Customer ↔ Courier** — orderId = order.$id
2. **Live CS Customer → Admin** — orderId = `cs_chat_{customerId}`
3. **Live CS Courier → Admin** — orderId = `cs_chat_{courierId}`

### `withdrawals` — Penarikan saldo kurir
Field `status` digunakan oleh Admin Dashboard untuk approve/reject.

## Index yang Dibutuhkan

Untuk performa query, buat index berikut di Appwrite Console:

| Collection | Field | Type |
|---|---|---|
| `orders` | `status` | Key |
| `orders` | `userId` | Key |
| `orders` | `courierId` | Key |
| `orders` | `$createdAt` | Key |
| `chats` | `orderId` | Key |
| `chats` | `timestamp` | Key |
| `withdrawals` | `courierId` | Key |
| `notifications` | `userId` | Key |
| `notifications` | `isRead` | Key |
