# KASSMA Miners

A Flutter mobile application for managing artisanal and small-scale mining operations in the Kitanda Artisanal & Small-Scale Miners Association (KASSMA).

## Overview

KASSMA Miners streamlines mining operations management by providing role-based dashboards for different user types (Pit Owners, Site Owners, Pit Managers) to manage ore receipts, incidents, workers, and ID cards.


## Features


- **Authentication** - Secure JWT-based login with role-based access
- **Role-Based Dashboards**
  - Pit Owner Dashboard - Overview of workers, receipts, incidents, and active pits
  - Site Owner Dashboard - Production stats, leaching tanks, and gold records
- **Ore Receipts** - Create and track ore deliveries with transporter and vehicle details
- **Incident Reporting** - Report and track incidents with severity levels
- **Worker Management** - Add, assign, and manage mining workers
- **ID Card Issuance** - Issue and track ID cards for workers
- **Pit Assignment** - Assign workers and managers to specific mining pits


## Tech Stack

- **Framework:** Flutter 3.x
- **State Management:** flutter_bloc (BLoC pattern)
- **HTTP Client:** Dio
- **Storage:** flutter_secure_storage, shared_preferences
- **UI:** Material Design 3, Google Fonts (Inter)


## Project Structure


```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root widget with theme and routing
├── config/
│   ├── constants.dart         # App constants and API config
│   └── theme.dart            # Material theme configuration
├── data/
│   └── models/
│       └── user.dart         # User model with role helpers
├── presentation/
│   ├── bloc/
│   │   └── auth/            # Authentication BLoC
│   ├── screens/
│   │   ├── dashboard/       # Dashboard screens
│   │   ├── login/           # Login screen
│   │   ├── splash/          # Splash screen
│   │   ├── members/         # Worker management
│   │   ├── receipts/        # Ore receipts
│   │   ├── incidents/      # Incident reporting
│   │   ├── id_cards/        # ID card management
│   │   └── workers/         # Worker views
│   └── widgets/              # Reusable UI components
└── services/
    ├── api_service.dart     # API communication
    └── storage_service.dart  # Local storage helpers
```


## Getting Started

### Prerequisites

- Flutter SDK 3.x or higher
- Android Studio / Xcode for mobile development

### Installation

```bash
# Clone the repository
git clone https://github.com/mycosoft/kassma-miners-app.git

# Navigate to project
cd kassma-miners-app

# Install dependencies
flutter pub get

# Run the app
flutter run
```


### Build

```bash
# Android APK
flutter build apk

# iOS
flutter build ios
```

## User Roles

| Role | Description |
|------|-------------|
| Pit Owner | Manages pits, workers, receipts, incidents |
| Site Owner | Oversees multiple pits, production, gold records |
| Pit Manager | Manages assigned pits and workers |


## API Endpoints

The app connects to `https://kassma.net/api/v1` for backend services. Authentication uses Bearer token in request headers.


## Screenshots

The app features a splash screen with brand animation, login with email/password, and role-specific dashboards with bottom navigation.


## Development

Developed by **Mycosoft Technologies** for KASSMA (Kitanda Artisanal & Small-Scale Miners Association).

## License

This project is private and proprietary to KASSMA and Mycosoft Technologies.
