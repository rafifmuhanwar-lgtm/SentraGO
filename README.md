# SentraGO

SentraGO is a comprehensive on-demand delivery and logistics platform consisting of three main components: a **Customer Application** for placing orders, a **Courier Application** for drivers to manage deliveries, and an **Admin Dashboard** for system management.

This project is built using Flutter for the mobile applications and HTML/CSS for the dashboard, utilizing [Appwrite](https://appwrite.io/) as the Backend-as-a-Service (BaaS) and Mapbox for mapping capabilities.

---

## 📱 Project Structure

The repository is divided into the following main directories:

- `/customer_app`: Flutter application for customers to create orders, track deliveries, chat with couriers, and manage payments.
- `/courier_app`: Flutter application for couriers/drivers to accept orders, update delivery statuses, and manage their earnings/withdrawals.
- `/Dashboard Sentra`: HTML/CSS/JS based admin dashboard for monitoring users, couriers, and transactions.

---

## 🛠️ Technology Stack

### Mobile Applications (Customer & Courier Apps)
- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Routing:** GoRouter (`go_router`)
- **Backend Services:** Appwrite SDK (`appwrite`)
- **Networking:** Dio (`dio`)
- **Maps & Location:** Flutter Map (`flutter_map`), Geolocator (`geolocator`), Mapbox
- **Payment Gateway (Customer):** Pakasir
- **Local Storage:** Flutter Secure Storage (`flutter_secure_storage`)
- **UI & Styling:** Google Fonts, Cupertino Icons, Cached Network Image

### Admin Dashboard
- **Frontend:** HTML5, CSS3, Vanilla JavaScript

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

1. **Flutter SDK:** Ensure you have Flutter installed (SDK `^3.9.2` or compatible). [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Dart SDK:** Included with Flutter.
3. **IDE:** VS Code, Android Studio, or IntelliJ IDEA with Flutter plugins installed.
4. **Appwrite Account:** An active project in Appwrite Cloud (or self-hosted) with Database, Auth, and Storage configured.
5. **Mapbox Account:** An access token from Mapbox for rendering maps.

---

### Configuration (Environment Variables)

Before running the apps, you need to configure the Appwrite endpoint and Mapbox token. 

#### 1. Mapbox Configuration
The applications use Mapbox via `--dart-define`. You will need your Mapbox Access Token (found in `config.json` or your Mapbox Dashboard).

#### 2. Appwrite Configuration
Ensure the Appwrite Project ID, Database ID, and Storage Bucket ID are correctly set in both applications:
- **Customer App:** `customer_app/lib/core/config/app_config.dart`
- **Courier App:** `courier_app/lib/core/config/app_config.dart`

---

### Running the Customer App

1. Navigate to the `customer_app` directory:
   ```bash
   cd customer_app
   ```
2. Get the Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the code generator for Riverpod and other annotations (if needed):
   ```bash
   dart run build_runner build -d
   ```
4. Run the application (replace `YOUR_MAPBOX_TOKEN` with the actual token):
   ```bash
   flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN
   ```

---

### Running the Courier App

1. Navigate to the `courier_app` directory:
   ```bash
   cd courier_app
   ```
2. Get the Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the code generator:
   ```bash
   dart run build_runner build -d
   ```
4. Run the application:
   ```bash
   flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN
   ```

---

### Running the Admin Dashboard

The dashboard consists of static HTML files. No build process is required.
1. Navigate to the `Dashboard Sentra` directory.
2. Open `dashboard.html` in any modern web browser to view the interface.
   *(Tip: Use VS Code's "Live Server" extension for a better development experience).*

---

## 📦 Core Features

### Customer App
- **Authentication:** Login/Register via Appwrite Auth.
- **Order Creation:** Input pickup and delivery locations, select package types.
- **Real-time Map:** Interactive map for selecting locations (powered by Mapbox).
- **Payment Integration:** Process payments securely via Pakasir Gateway.
- **Chat:** Real-time chat with the assigned courier.
- **Order History:** View active and past orders.

### Courier App
- **Authentication:** Secure login for approved couriers.
- **Order Management:** View available orders, accept deliveries, and update statuses (Pickup, In Transit, Delivered).
- **Navigation:** View pickup and drop-off coordinates.
- **Chat:** Communicate directly with the customer.
- **Earnings & Withdrawal:** Track delivery earnings and request withdrawals.

### Admin Dashboard
- **User & Courier Management:** Monitor active users and driver partners.
- **Order Tracking:** Oversee all system transactions.
- **Reports:** Generate analytics and business reports.

---

## 🔒 Appwrite Backend Setup (Reference)

To deploy this project to your own Appwrite instance, you will need to create:
1. **Database** with the following collections:
   - `users`
   - `couriers`
   - `orders`
   - `chats`
   - `withdrawals`
2. **Storage Bucket** for user avatars, package photos, etc.
3. Configure **OAuth providers** (if using social login) and update the Redirect URLs in `app_config.dart`.

---

## 📝 License

This project is proprietary and confidential. Unauthorized copying of files within this repository is strictly prohibited.
