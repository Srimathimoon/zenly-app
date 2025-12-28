#  Zenly App

Zenly is a Flutter-based **mental health and relaxation application** designed to help users reduce stress, practice mindfulness, and improve emotional well-being through calm interactions and supportive features.

---

## ✨ Features

### 🌊 Zen Garden
- **Water Mode**
    - Tap to create ripple animations
    - Plays a single, non-overlapping calming water droplet sound
- **Sand Mode**
    - Draw patterns in sand using touch gestures
    - Sand lines fade naturally over time for a relaxing effect

### 💬 Mental Health Chatbot
- Friendly, supportive chatbot conversations
- Responds empathetically to user input
- Designed for emotional comfort and motivation

### 😊 Mood Tracking
- Track daily moods and emotions
- Helps users reflect on their mental health patterns

### 🎮 Mini Game Module
- Simple relaxing game interactions
- Designed to reduce stress and improve focus

### 🔐 Authentication
- Firebase **anonymous authentication**
- No personal data required, ensuring user privacy

### 🎧 Audio Experience
- Calming Zen sounds
- Single audio player to prevent sound overlap
- Optimized for Flutter Web, Android, and iOS

---

## 🛠️ Tech Stack

- **Flutter (Dart)**
- **Firebase Authentication**
- **CustomPainter** for Zen Garden animations
- **AudioPlayers** for sound effects
- **Material UI**

---

## 📂 Project Structure

lib/
├── main.dart
├── chat.dart
├── mood_screen.dart
├── game.dart
assets/
├── audio/
│ ├── water.mp3
│ └── sand.mp3
└── images/
└── zenly_logo.png

----

## ▶️ Getting Started

### Prerequisites
- Flutter SDK installed
- Android Studio / VS Code
- Firebase project configured (optional for auth)

### Run the App

```bash
flutter pub get
flutter run
