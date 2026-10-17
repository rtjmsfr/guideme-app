# 📱 GuideMe — Flutter Mobile App

A Flutter mobile application that connects tourists in Saudi Arabia with local guides, with recommendations and translation integrated. Part of the **GuideMe** graduation project.

---

## 🚀 Features

* Email authentication (Firebase Auth)
* Browse, search, and filter tourist places and guides
* Book guides and chat with them
* Leave reviews, ratings, and likes
* Personalized recommendations
* Text translation for non-Arabic speakers
* Static content localized in 11 languages
* Available on both Android and iOS

---

## ⚠️ Note on First-Time Use

> **⏳ Firebase configuration is required to run the project.**
> The `google-services.json` file is not included in the repository for security reasons. Add your own from your Firebase project before running.

---

## 📦 Requirements

* Flutter SDK 3.0+
* Dart 3.0+
* A Firebase project (for authentication and database)

---

## 🔧 Installation

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Add Firebase configuration

Place your `google-services.json` in `android/app/`.

---

## 💻 Run the App

```bash
flutter run
```

---

## 🧠 AI Integration

The AI features run in two separate backend services, not inside the Flutter app. The app calls them via HTTP:

* **Recommendations** — LightFM-based service
* **Translation** — M2M-100-based service

---
## 🗂 Directory Structure

```css
guideme-app/
├── lib/
│   ├── auth/                # Login, registration, guide signup, password reset
│   ├── core/                # Recommendation & translation services (Cubits + API service)
│   ├── guide/               # Guide listing, profile, booking, and details
│   ├── place/               # Place listing, favorites, details, and place model
│   ├── profile/             # User profile, profile editing, and settings
│   ├── welcome/             # Welcome and home screens
│   ├── chat.dart            # Chat feature between tourists and guides
│   ├── main.dart            # App entry point
│   └── recommendation.dart  # Recommended places/guides screen
├── assets/
│   ├── data/                # Saudi attractions dataset (CSV)
│   ├── langs/               # Language configuration (langs.json)
│   ├── translations/        # Localization files for 11 languages
│   └── *.jpg, logo.png      # Place images and app logo
├── android/                 # Android platform files
├── ios/                     # iOS platform files
├── pubspec.yaml
└── README.md
```
---