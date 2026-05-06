# Sunrise

A WeatherKit-powered iOS weather app with an animated character companion.
Hand-drawn 80s-anime aesthetic, designed for iOS first with macOS as a
second-stage target.

## Tech stack

- **UI**: UIKit + Auto Layout, with SwiftUI islands for Swift Charts and the widget
- **State**: [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.x with Observation
- **Data**: Apple WeatherKit, CoreLocation, MapKit (city search)
- **Persistence**: `UserDefaults` (MVP) → GRDB once we need history
- **Animation**: [airbnb/lottie-spm](https://github.com/airbnb/lottie-spm) (drop-in JSON)
- **Localization**: Xcode String Catalogs (`.xcstrings`), English as the base
- **Project generation**: [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Structure

```
Sunrise/                # iOS app target (UIKit views)
├── App/                # AppDelegate, SceneDelegate, RootTabBarController
├── Features/           # Per-tab UIViewControllers (Today / Forecast / Character / Profile / Cities)
├── Resources/          # Assets, String Catalog, entitlements, LaunchScreen, Lottie/
└── Support/            # Observation glue

SunriseWidget/          # WidgetKit extension (small + medium)

Packages/
├── SunriseCore/        # Models, Clients (Weather/Location/Search/Persistence/Notifications), SharedStorage
├── SunriseFeatures/    # TCA reducers (Today, Forecast, Character, Profile, Root, City)
├── SunriseDesignSystem # Palette, Typography, Spacing tokens + components
└── SunriseAnimation/   # Lottie character view + condition catalog

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

1. **Signing & Capabilities** for both `Sunrise` and `SunriseWidget`:
   - Set your team
   - Enable **WeatherKit** (registered against the App ID in the Apple
     Developer portal)
   - Add the **App Group** `group.app.sunrise` to both targets so the widget
     can read snapshots written by the main app
2. Pick the `Sunrise` scheme and run on iOS 17+ simulator or device.

## Roadmap

| Milestone | Status | Scope |
|-----------|--------|-------|
| M0 | ✅ | Project scaffolding, TCA wiring, design tokens, English base strings |
| M1 | ✅ | Today tab — live WeatherKit + location, formatted readout |
| M2 | ✅ | City management + persistence (multi-city switching) |
| M3 | ✅ | 15-day Forecast tab with Swift Charts |
| M4 | ✅ | Character tab MVP — static art per condition + localized dialogue |
| M5 | ✅ | Profile / Settings — units, notifications, about |
| M6 | ✅ | Lottie animations for the character (drop JSON in `Sunrise/Resources/Lottie/`) |
| M7 | ✅ | Daily local notifications + WidgetKit extension |
| M8 | open | TestFlight polish, screenshots, App Store listing |

## Localization

The base language is English (`en`). Existing locales: `zh-Hans`, `ja`. Add
new strings to `Sunrise/Resources/Localizable.xcstrings` via Xcode; auto-export
keeps the catalog tidy.

## Adding character animations

Drop Lottie JSON files into `Sunrise/Resources/Lottie/` named
`character_<condition>.json` (one of `clear`, `cloudy`, `rain`,
`thunderstorm`, `snow`, `windy`, `fog`). Re-run `xcodegen generate` so the
project picks them up. Missing files fall back to the SF-Symbol portrait.
