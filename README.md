# Dictionary App

A 50k-word English-Bangla offline-first dictionary app built with Flutter, using an MVVM-style architecture (data / domain / presentation layers) with Provider for state management.

## Structure
- **core/** -- cross-cutting concerns (constants, theme, utils, errors, services, routes)
- **data/** -- local (sqflite) + remote (Free Dictionary API) data sources, models, repository implementations
- **domain/** -- entities and repository contracts
- **presentation/** -- providers (ViewModels), screens, and reusable widgets

## Getting Started
```
flutter pub get
flutter run
```
