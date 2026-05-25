# 🌾 AgriLink — Ethiopia's Direct Farm-to-Table Marketplace

<p align="center">
  <strong>Connecting Ethiopian Farmers Directly with Buyers</strong><br>
  A modern mobile marketplace that bridges rural producers and urban consumers — enabling direct agricultural trade, real-time communication, and secure order management.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.19+-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.11+-0175C2?style=for-the-badge&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/Firebase-Notifications-FFCA28?style=for-the-badge&logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
</p>

---

## 📋 Table of Contents

- [About the Project](#-about-the-project)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Admin Panel](#-admin-panel)
- [Database Schema](#-database-schema)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)

---

## 📖 About the Project

**AgriLink** is a full-stack mobile application built to solve the disconnect between Ethiopian farmers and consumers. Smallholder farmers often lack access to markets, fair pricing, and reliable buyers. AgriLink eliminates middlemen by providing a direct, digital marketplace where:

- **Farmers** can list products, manage orders, track earnings, and communicate with buyers
- **Buyers** can browse, search, filter, and order fresh agricultural products directly from verified farmers
- **Admins** can oversee the platform through a dedicated web-based admin panel

---

## 🚀 Key Features

### 🛒 Dynamic Marketplace
- **Voice-enabled search** with advanced filtering (price, category, organic)
- **Farmer profiles** — dedicated pages showcasing ratings, stories, and full product catalogs
- **Rich product details** — images, stock status, pricing, and direct messaging to farmers

### 💬 Real-Time Communication
- **Instant messaging** — built-in chat powered by Supabase Realtime
- **Push notifications** — order updates and new message alerts via Firebase Cloud Messaging

### 📦 Order & Logistics
- **Order tracking** — live status from "Pending" → "Confirmed" → "Shipped" → "Delivered"
- **Farmer dashboard** — self-service product management, earnings tracking, and order fulfillment
- **Bulk ordering** — support for commercial buyers with a dedicated business portal
- **Multiple payment methods** — Cash on Delivery, Mobile Money (Chapa), Bank Transfer

### 🌍 Localization
- **Trilingual support** — English, Amharic (አማርኛ), and Afaan Oromoo
- **Region-specific content** tailored for the Ethiopian agricultural landscape

### 📊 Admin Panel (Web)
- **User management** — view, filter, and manage all registered users
- **Product moderation** — approve, edit, or remove listings
- **Order oversight** — monitor and manage all platform orders
- **Analytics dashboard** — revenue tracking, user growth, and platform statistics

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter (Dart) |
| **Backend & Database** | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| **Push Notifications** | Firebase Cloud Messaging + Flutter Local Notifications |
| **State Management** | Provider Pattern |
| **Admin Panel** | Flutter Web |
| **Location Services** | Geolocator |
| **Voice Search** | Speech-to-Text |
| **PDF Reports** | pdf + printing packages |
| **Offline Support** | Hive (local storage) |
| **Image Handling** | Image Picker + Cached Network Image |

---

## 📂 Project Structure

```
AgriLink/
├── agridirect_app/           # 📱 Main Flutter mobile application
│   ├── lib/
│   │   ├── models/           # Data models (User, Product, Order, etc.)
│   │   ├── providers/        # State management (Provider pattern)
│   │   ├── screens/          # All app screens (25+ screens)
│   │   ├── services/         # Backend services (Auth, Orders, Messages, etc.)
│   │   ├── widgets/          # Reusable UI components
│   │   ├── setup/            # Database migration SQL scripts
│   │   └── main.dart         # App entry point
│   └── pubspec.yaml
│
├── admin_panel/              # 🖥️ Web-based admin dashboard (Flutter Web)
│   ├── lib/
│   │   ├── screens/          # Admin screens (Users, Products, Orders)
│   │   ├── services/         # Admin API services
│   │   └── main.dart
│   └── pubspec.yaml
│
├── products_migration.sql    # Database migration for products table
└── README.md                 # You are here!
```

---

## 🏁 Getting Started

### Prerequisites

- **Flutter SDK** v3.19 or higher — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** v3.11+
- A **Supabase** project — [Create one free](https://supabase.com)
- (Optional) **Firebase** project for push notifications

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/kenenisa-abdisa/AgriLink.git
   cd AgriLink
   ```

2. **Install dependencies for the mobile app**
   ```bash
   cd agridirect_app
   flutter pub get
   ```

3. **Configure environment**
   
   Update `lib/env_config.dart` with your Supabase credentials:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. **Set up the database**
   
   Run the SQL migration scripts found in `lib/setup/migration.sql` in your Supabase SQL Editor to create the required tables, RLS policies, and functions.

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 🖥 Admin Panel

The admin panel is a separate Flutter Web application for platform management.

```bash
cd admin_panel
flutter pub get
flutter run -d chrome
```

---

## 🗃 Database Schema

The application uses the following core tables in Supabase (PostgreSQL):

| Table | Purpose |
|---|---|
| `users` | User accounts (buyers, farmers, admins) |
| `farmers` | Extended farmer profiles and verification data |
| `products` | Product listings with images, pricing, and stock |
| `orders` | Order records linking buyers and farmers |
| `order_items` | Individual items within each order |
| `messages` | Real-time chat messages between users |
| `reviews` | Product and farmer reviews/ratings |
| `notifications` | In-app notification records |

Full migration scripts are available in [`agridirect_app/lib/setup/migration.sql`](agridirect_app/lib/setup/migration.sql).

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

---

## 👤 Author

**Kenenisa Abdisa**

- GitHub: [@kenenisa-abdisa](https://github.com/kenenisa-abdisa)
- Email: kenenisaabdisa73@gmail.com

---

<p align="center">
  <em>🌱 AgriLink — Connecting Ethiopia's Heartbeat to the World 🌍</em>
</p>
