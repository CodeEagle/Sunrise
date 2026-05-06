# Sunrise

A WeatherKit-powered iOS weather app with an animated character companion.
Hand-drawn 80s-anime aesthetic, designed for iOS first with macOS as a
second-stage target.

## Tech stack

- **UI**: UIKit + Auto Layout
- **State**: [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.x with Observation
- **Data**: Apple WeatherKit, CoreLocation
- **Persistence**: `UserDefaults` (MVP) → GRDB once we need history
- **Localization**: Xcode String Catalogs (`.xcstrings`), English as the base
- **Project generation**: [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Structure

```
Sunrise/                # iOS app target (UIKit views)
├── App/                # AppDelegate, SceneDelegate, RootTabBarController
├── Features/           # Per-tab UIViewControllers that consume TCA stores
├── Resources/          # Assets, String Catalog, entitlements, LaunchScreen
└── Support/            # Observation glue

Packages/
├── SunriseCore/        # Models, WeatherClient, LocationClient, settings
├── SunriseFeatures/    # TCA reducers (Today, Forecast, Character, Profile, Root)
├── SunriseDesignSystem # Palette, Typography, Spacing tokens + components
└── SunriseAnimation/   # Placeholder for Lottie/Rive integration

SunriseTests/           # App-target smoke tests
```

Reducers and core modules are pure Swift and free of UIKit imports, so they
can be reused on macOS / visionOS later without modification.

## Getting started

```bash
brew install xcodegen
xcodegen generate
open Sunrise.xcodeproj
```

Then in Xcode:

1. **Signing & Capabilities** → set your team. The WeatherKit capability is
   already declared in `Sunrise/Resources/Sunrise.entitlements`. Make sure your
   App ID has WeatherKit enabled in the Apple Developer portal.
2. Pick the `Sunrise` scheme and run on iOS 17+ simulator or device.

## Roadmap

| Milestone | Scope |
|-----------|-------|
| M0 | Project scaffolding, TCA wiring, design tokens, English base strings |
| M1 | Today tab — live WeatherKit + location, formatted readout |
| M2 | City management + persistence (multi-city switching) |
| M3 | 15-day Forecast tab with Swift Charts |
| M4 | Character tab MVP — static art per condition + localized dialogue |
| M5 | Profile / Settings — units, notifications, about |
| M6 | Lottie animations for the character |
| M7 | Notifications + Widgets + Lock Screen |
| M8 | TestFlight polish |

## Localization

The base language is English (`en`). Existing locales: `zh-Hans`, `ja`. Add
new strings to `Sunrise/Resources/Localizable.xcstrings` via Xcode; auto-export
keeps the catalog tidy.
