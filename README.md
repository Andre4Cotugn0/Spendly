<p align="center">
  <img src="assets/icon/icon.png" alt="Moneyra Logo" width="120" />
</p>

<h1 align="center">Moneyra</h1>

<p align="center">
  <strong>Personal finance tracker — expenses, subscriptions & budgets in one place.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.0.0-blue?style=flat-square" alt="version" />
  <img src="https://img.shields.io/badge/Flutter-3.9%2B-02569B?style=flat-square&logo=flutter" alt="flutter" />
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey?style=flat-square" alt="platform" />
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="license" />
</p>

---

## Overview

Moneyra is a cross-platform mobile app built with Flutter that helps you take full control of your personal finances. Track daily expenses, monitor recurring subscriptions, analyse spending trends with interactive charts, and manage debts — all stored locally on your device with no external account required.

---

## Features

| Feature | Description |
|---|---|
| **Expense Tracking** | Log expenses with category, amount, date and notes in seconds |
| **Subscription Manager** | Keep track of all recurring bills (monthly, yearly, custom) |
| **Statistics & Charts** | Visualise spending trends with interactive, filterable charts |
| **Debt Tracker** | Track money you owe or are owed, with partial-payment support |
| **Custom Categories** | Create and personalise expense categories with icons and colours |
| **Home Screen Widgets** | Glanceable expense widget directly on your Android home screen |
| **Local Notifications** | Reminders for upcoming subscription renewals and daily logging |
| **CSV Export** | Export your full expense history or a date range to CSV |
| **Dark / Light Mode** | Full system-level dark mode support |
| **Onboarding Flow** | Friendly guided setup on first launch |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Provider |
| Local Database | SQLite via `sqflite` |
| Charts | `fl_chart` |
| Notifications | `flutter_local_notifications` |
| Home Widget | `home_widget` |
| Sharing & Export | `share_plus`, `csv` |
| UI | Material Design 3, Google Fonts, `flutter_animate` |

---

## Project Structure

```
lib/
├── main.dart               # App entry point
├── core/                   # Theme, shared utilities
├── data/
│   ├── constants/          # App-wide constants
│   ├── database/           # SQLite database layer
│   ├── models/             # Data models
│   └── services/           # Business logic & services
├── features/
│   ├── add_expense/        # Add / edit expense screen
│   ├── categories/         # Category management
│   ├── debts/              # Debt tracking
│   ├── home/               # Dashboard / home screen
│   ├── onboarding/         # First-launch onboarding
│   ├── settings/           # App settings
│   ├── statistics/         # Charts & analytics
│   └── subscriptions/      # Subscription management
├── providers/              # Provider state classes
└── widgets/                # Shared reusable widgets
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>= 3.9.0`
- Dart SDK `>= 3.9.0`
- Android Studio or Xcode (for native builds)

### Installation

```bash
# Clone the repository
git clone https://github.com/<your-username>/moneyra.git
cd moneyra

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

---

## Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## Platforms

| Platform | Status |
|---|---|
| Android | ✅ Supported |
| iOS | ✅ Supported |

---

## License

This project is distributed under the **MIT License with Attribution**.

You are free to use, modify and distribute this software — including for commercial purposes — provided that credit to the original author is retained in the source code and/or documentation of any derived work.

See the [LICENSE](LICENSE) file for full details.
