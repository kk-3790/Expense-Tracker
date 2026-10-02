# 💸 Paisa — AI-Powered Expense Tracker & Bill-Splitting App

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Google Gemini AI](https://img.shields.io/badge/Gemini%20AI-3.5%20Flash-4285F4?logo=google&logoColor=white)](https://ai.google.dev)
[![Platform](https://img.shields.io/badge/Platforms-iOS%20%7C%20Android-green?logo=apple&logoColor=white)](https://flutter.dev)
[![Tests](https://img.shields.io/badge/Tests-47%20Passed-brightgreen?logo=checkmarx&logoColor=white)](#-testing)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Paisa** is a modern, high-performance personal finance and group bill-splitting application built with **Flutter**, **Firebase**, and **Google Gemini AI**. Inspired by modern fintech design systems on Behance, it combines automated expense tracking, bilateral split-bill accounting, BharatQR merchant categorization, and real-time AI financial advice into a dark-mode mobile experience.

</div>

---

## 🌟 Key Features

### 🤝 Bilateral In-App Bill Splitting & Ledger
- **Shared Bilateral Accounting:** Split bills equally or custom among friends. Automatically maintains a shared master ledger across registered accounts.
- **In-App Requests & Real-Time Alerts:** Recipients receive real-time alert banners and red badge counters on their notification bell.
- **1-Tap Settlement:** Friends can **Approve & Pay** (automatically debits recipient balance) or **Decline**. When the organizer opens the app, approved requests automatically settle and credit their balance.
- **Deep-Link UPI Integration:** Generates 1-tap `upi://pay` payment request deep links with pre-filled amounts, payee names, and transaction references.
- **Friend Reminder Engine:** Pre-formats and copies polite repayment reminders directly to the clipboard.

### 🤖 Context-Aware AI Financial Advisor (Gemini 3.5)
- **Live Financial Reasoning:** Integrated with **Google Gemini 3.5 Flash** to answer natural-language questions about your spending, budget health, and affordability.
- **Contextual Awareness:** Reads live user balance, monthly spending, and goal progress to offer customized **50/30/20 budgeting advice**.
- **Resilient Offline Fallback:** If cloud quotas are reached or the device is offline, Paisa seamlessly falls back to a built-in deterministic local financial intelligence engine.

### ⚡ Smart QR & Merchant Auto-Categorization
- **BharatQR / UPI Parsing:** Scan UPI merchant QR codes with instant amount, payee, and transaction reference extraction.
- **MCC Auto-Categorization:** Uses Merchant Category Codes (MCC) to automatically classify transactions into Food, Grocery, Transportation, Fuel, and Shopping without manual input.

### 🎯 Savings Goals & Budget Milestones
- **Interactive Goal Tracking:** Set savings targets with visual milestone progress bars and target completion dates.
- **Category Budget Alerts:** Configurable monthly limits with automated high-spending warnings.
- **Multi-Currency Support:** Switch between Rupee (`₹`), Dollar (`$`), Euro (`€`), Pound (`£`), and Yen (`¥`).

### 📱 Conceptzilla Dark Mode UI / UX
- **Fintech Aesthetics:** Bespoke dark theme (`#121315`) with vibrant neon accents (`#B7F23D`) and fluid glassmorphic cards.
- **Dedicated Transaction Details:** Full breakdown screen displaying itemized shares, settlement progress bar, participants, and status pills.
- **Custom Numeric Keypad:** Ergonomic financial keypad optimized for single-thumb mobile data entry.

### 🔒 Enterprise-Grade Session Isolation
- **Multi-User Architecture:** Complete isolation between user sessions upon sign-in/sign-out—guaranteeing zero data leakage between different Firebase Auth profiles.
- **Firebase Sync:** Secure authentication via Google Sign-In and cloud persistence through Cloud Firestore.

---

## 🛠️ Tech Stack & Architecture

| Layer | Technologies |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (iOS & Android) |
| **Language** | [Dart](https://dart.dev) (Null Safety) |
| **Backend & Cloud** | [Firebase Authentication](https://firebase.google.com/products/auth), [Cloud Firestore](https://firebase.google.com/products/firestore) |
| **Generative AI** | [Google Gemini AI](https://ai.google.dev) (`gemini-3.5-flash-lite`, `gemini-3.5-flash`) |
| **State Management** | Reactive `ValueNotifier` & `ValueListenableBuilder` architecture |
| **Local Storage** | `SharedPreferences` with scoped per-user key isolation |
| **Payments & QR** | UPI Deep Linking (`upi://pay`), Camera & Mobile Scanner |
| **Testing** | 47 Unit & Integration test cases covering backend calculations and cross-user splits |

---

## 📂 Project Structure

```text
lib/
├── main.dart                       # App entry point, Firebase init & theme setup
├── models/
│   └── transaction_model.dart      # Transaction entity with split metadata & helpers
├── screens/
│   ├── home_screen.dart            # Hero balance, goal slider, recent transactions & bell badge
│   ├── add_transaction_screen.dart # Custom dial pad, QR shortcut & split participant selector
│   ├── transaction_detail_screen.dart # Itemized split breakdown, reminder & settlement actions
│   ├── ai_chat_screen.dart         # Gemini 3.5 AI financial chatbot with context injection
│   ├── notifications_screen.dart   # Incoming split approvals, payment debits & status cards
│   ├── qr_scanner_screen.dart      # BharatQR scanner with MCC classification
│   ├── statistics_screen.dart      # Analytics, spending charts & category distribution
│   └── settings_screen.dart        # Currency, theme, budget limits & API key management
├── services/
│   ├── auth_service.dart           # Firebase Google Sign-In & clean user session switching
│   ├── gemini_service.dart         # Multi-model pool, rate-limit retries & local fallback
│   ├── split_service.dart          # Shared bilateral ledger, request lifecycle & UPI links
│   ├── transaction_service.dart    # Isolated ledger, balance calculations & offline cache
│   └── goal_service.dart           # Savings goals persistence & progress tracking
└── theme/
    └── paisa_theme.dart            # Conceptzilla color palette, typography & category icons
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or higher)
- [Xcode](https://developer.apple.com/xcode/) (for iOS deployment, macOS only)
- [Android Studio](https://developer.android.com/studio) (for Android deployment)
- A [Google AI Studio](https://aistudio.google.com/) Gemini API Key (optional, local engine is available out of the box)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/krishpatel-317/Expense-Tracker.git
   cd Expense-Tracker
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase (Optional for full cloud sync):**
   - Place your `GoogleService-Info.plist` in `ios/Runner/`.
   - Place your `google-services.json` in `android/app/`.

4. **Run the application:**
   ```bash
   # Run on connected device or simulator
   flutter run
   ```

---

## 🧪 Testing

The application includes an extensive automated test suite covering ledger accounting, goal percentages, multi-user isolation, split settlement workflows, and offline AI fallbacks.

Run the test suite with:

```bash
flutter test test/paisa_backend_test.dart
```

**Test Results:**
```text
00:03 +47: All tests passed!
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!  
Feel free to check out the [issues page](https://github.com/krishpatel-317/Expense-Tracker/issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

