# AI Music Recommendation App 🎵

![App Screenshot](assets/images/screenshot.png) <!-- Add your screenshot path here -->

A Flutter application that generates personalized music playlists based on mood and genre selections using AI-powered recommendations.

## Features ✨

- **Mood-based recommendations**: Select from various moods (Happy, Sad, Energetic, etc.)
- **Multi-genre selection**: Choose from 20+ music genres
- **Hybrid API integration**: Combines Last.fm and OpenAI for robust recommendations
- **Music service integration**: Open playlists directly in Spotify or Audiomack
- **Beautiful UI**: Custom animations and responsive design
- **Offline caching**: Stores recent recommendations for offline access

## Technologies Used 🛠️

- **Flutter**: Cross-platform framework
- **Dart**: Programming language
- **Hive**: Lightweight database for caching
- **Last.fm API**: For music metadata and recommendations
- **OpenAI API**: For AI-powered playlist generation
- **Google Fonts**: Custom typography

## Installation Guide 📲

### Prerequisites

- Flutter SDK (latest version)
- Android Studio/Xcode (for emulator)
- Physical device (optional but recommended)

### Setup

1. Clone the repository:
   ```bash
   git clone
   ```
2. flutter pub get
3. tokenOpenAi=your_openai_key_here
   tokenLastFm=your_lastfm_key_here
4. flutter run

How It Works 🤖
User selects a mood from animated circles

Chooses one or more music genres

App combines selections to generate recommendations:

First tries Last.fm API

Falls back to OpenAI if needed

Uses mock data if APIs fail

Displays playlist with options to open in music services
