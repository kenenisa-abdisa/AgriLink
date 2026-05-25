# AgriDirect 🇪🇹

AgriDirect is a modern, end-to-end mobile marketplace designed to empower Ethiopian farmers and consumers. It bridges the gap between rural producers and urban buyers, providing a seamless platform for direct agricultural trade, real-time communication, and secure order management.

---

## 🚀 Key Features

### 🛒 Dynamic Marketplace
*   **Intelligent Search:** Voice-enabled search and advanced filtering (Price, Category, Organic).
*   **Farmer Profiles:** Dedicated spaces for farmers to showcase their stories, ratings, and full product catalogs.
*   **Rich Product Details:** High-quality imagery, stock status, and direct-to-farmer messaging.

### 💬 Real-Time Communication
*   **Instant Messaging:** Built-in chat system powered by Supabase Realtime for instant buyer-farmer negotiation.
*   **Order Notifications:** Automated alerts for order status updates and new messages.

### 📦 Order & Logistics
*   **Order Tracking:** Live tracking of order status from "Pending" to "Delivered."
*   **Farmer Dashboard:** Self-service management for farmers to add/edit/delete products and track earnings.
*   **Bulk Ordering:** Support for commercial buyers and business portal access.

### 🌍 Localization
*   **Multilingual Support:** Fully localized in **English**, **Amharic (አማርኛ)**, and **Oromo (Afaan Oromoo)**.
*   **Region-Specific Content:** Tailored for the Ethiopian agricultural landscape.

---

## 🛠 Tech Stack

*   **Frontend:** [Flutter](https://flutter.dev) (Dart)
*   **Backend & Database:** [Supabase](https://supabase.com) (PostgreSQL, Auth, Realtime Storage)
*   **State Management:** Provider Pattern
*   **Theming:** Custom Vibrant Design System (Glassmorphism & Material 3)
*   **APIs:** Google Maps (Location Services), Speech-to-Text, Image Picker

---

## 📸 Screenshots

| Marketplace | Product Details | Real-time Chat |
| :---: | :---: | :---: |
| ![Marketplace](https://via.placeholder.com/200x400?text=Marketplace) | ![Details](https://via.placeholder.com/200x400?text=Product+Details) | ![Chat](https://via.placeholder.com/200x400?text=Real-time+Chat) |

---

## 📥 Installation & Setup

### Prerequisites
*   Flutter SDK (v3.19+)
*   Dart SDK
*   A Supabase Project (Tables: `users`, `products`, `messages`, `orders`, `farmers`)

### Run Locally
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/AgriDirect.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure Environment:**
    Update `lib/env_config.dart` with your Supabase URL and Anon Key.
4.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 🤝 Contribution

Contributions are welcome! If you'd like to improve AgriDirect, please fork the repo and create a pull request.

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
**Developed by [Your Name]** - *Connecting Ethiopia's Heartbeat to the World.*
