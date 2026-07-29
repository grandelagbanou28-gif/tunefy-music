<div align="center">

  <img src="assets/icon/icon.png" alt="Tunefy Logo" width="120" />

  # Tunefy

  **A premium music streaming experience built with Flutter.**

  [![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

</div>

---

## Overview

Tunefy is a beautifully crafted music streaming UI built with **Flutter** and **BLoC** state management. It delivers a fluid, Spotify-inspired experience with smooth animations, intuitive navigation, and a modern design language.

> This project is a UI clone for educational and portfolio purposes. All rights to the original design belong to their respective owners.

---

## Features

- **Home** — Personalized music recommendations and recently played
- **Search** — Browse by genre, mood, and curated playlists
- **Library** — Manage your saved albums, playlists, and liked songs
- **Player** — Full-featured music player with album art, controls, and lyrics
- **Onboarding** — Smooth onboarding flow for new users
- **Profile** — User profile and settings
- **Podcasts** — Browse and discover podcasts
- **Album & Artist Views** — Detailed views for albums and artists
- **Playlist Search** — Search and add songs to playlists
- **Shazam Integration** — Scan Spotify codes

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| State Management | BLoC (Business Logic Component) |
| Dependency Injection | `get_it` |
| Animations | `animations` package |
| UI Components | `auto_size_text`, `flutter_barcode_scanner` |
| Media | `video_player` |

---

## Project Structure

```
lib/
  main.dart
  DI/
    service_locator.dart
  bloc/
    album/
    artist/
    playlist/
    podcast/
  constants/
  data/
    datasource/
    model/
    repository/
  ui/
  widgets/
```

---

## Getting Started

### Prerequisites

- **Flutter SDK** (>=3.2.6)
- **Dart SDK** (>=3.2.6 <4.0.0)
- Android Studio / VS Code with Flutter plugin

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/tunefy.git

# Navigate to the project
cd tunefy

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## Building

```bash
# Android APK
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

---

## Screenshots

| Home | Search | Player | Library |
|:---:|:---:|:---:|:---:|
| ![Home](images/home/...) | ![Search](images/...) | ![Player](images/song_screen.png) | ![Library](images/...) |

---

## License

This project is for educational purposes only. Licensed under the MIT License.

---

<div align="center">

  Made with Flutter

</div>
