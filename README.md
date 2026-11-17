# Flutter Practice App

A Flutter learning project with several mini-apps in one interface.

[Русская версия](README-RU.md)

## Features

- **Counter** — a counter with action history.
- **Unit Converter** — convert values between different units.
- **Todo List** — manage tasks with local persistence.
- **Random Quotes** — display quotes from a local JSON file.
- **Photo Gallery** — add, view, and delete photos with local storage.
- **Weather** — search for cities, view current weather, a seven-day forecast, and temperature charts.

## Technologies

- Flutter and Dart
- Shared Preferences for local data persistence
- Image Picker for selecting photos
- Path Provider and Path for local file storage
- HTTP for weather and city search requests to Open-Meteo
- FL Chart for temperature charts
- Intl for date formatting
- Flutter Dotenv for loading the environment file

## Getting Started

### Prerequisites

- Flutter SDK compatible with Dart `^3.13.3`
- A configured emulator or a connected device
- Internet access for weather data and city search

### Installation

1. Clone this repository and open its directory.
2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Create the environment file:

   ```bash
   cp .env.example .env
   ```

   No API key is required by the current weather service. You can leave `.env` empty. The file must exist because the application loads it at startup.

4. Run the application:

   ```bash
   flutter run
   ```

## Project Structure

```text
lib/
├── main.dart       # Application entry point and navigation
├── models/         # Data models
├── screens/        # Application screens
├── services/       # Weather requests and local storage
└── widgets/        # Reusable UI components

assets/             # City and quote data
```

## Weather Data

The current implementation requests forecasts and city coordinates from Open-Meteo.

## Project Status

This project is intended for learning and practicing Flutter development.
