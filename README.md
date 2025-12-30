# WeatherFast

[![Flutter CI](https://github.com/ASDev-Official/weatherfast/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/ASDev-Official/weatherfast/actions/workflows/flutter_ci.yml)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2FASDev-Official%2Fweatherfast.svg?type=shield&issueType=license)](https://app.fossa.com/projects/git%2Bgithub.com%2FASDev-Official%2Fweatherfast?ref=badge_shield)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2FASDev-Official%2Fweatherfast.svg?type=shield&issueType=security)](https://app.fossa.com/projects/git%2Bgithub.com%2FASDev-Official%2Fweatherfast?ref=badge_shield)

Fast, focused weather app built with Flutter. Get instant conditions, intelligent insights, and a clean animated experience across Android, iOS, web, and desktop.

## Features

- Real-time conditions with AQI, hourly strip, and 10-day outlook
- AI-driven insights: recommendations, health tips, best times, and week-ahead summary
- Animated weather backdrops with dynamic themes
- Location search with typeahead and current-location shortcut
- In-app web views for helpful links
- Modern settings page with License info and help/feedback entry points

## Getting Started

1. Clone and install

```bash
git clone https://github.com/aadishsamir123/asdev-weatherfast.git
cd asdev-weatherfast
flutter pub get
```

2. Run

```bash
flutter run
```

Platform targets: android, ios, web, macos, windows (enable the desired platforms via `flutter config --enable-<platform>`).

## Development

- Analyze: `flutter analyze`
- Format: `dart format lib/ test/`
- Tests: `flutter test`
- Build (Android): `flutter build apk --release`
- Build (iOS): `flutter build ipa --release`

## Project Structure (high level)

- `lib/main.dart` — app entry, theme, navigation shell
- `lib/weather_home.dart` — home experience, search, current + forecast
- `lib/detail_screen.dart` — insights, AQI, hourly/daily details
- `lib/services/` — data, AI insights, time utilities
- `lib/ui/` — animated weather backdrop and shared UI pieces
- `lib/settings_screen.dart` — settings, license, help
- `assets/` — icons, backgrounds, profile art

## Notes

- Location permissions are required for “Use my location.”
- Internet access is required for weather/insights data.

## Contributing

Issues and PRs are welcome. Please run `flutter analyze` and `flutter test` before submitting.

## License

This project is licensed under the MIT License. See `LICENSE` for details.

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2FASDev-Official%2Fweatherfast.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2FASDev-Official%2Fweatherfast?ref=badge_large)
