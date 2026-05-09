# Sunrise — operator notes for Claude

## Known gotchas

### WeatherKit JWT auth fails with `WDSJWTAuthenticatorServiceListener.Errors Code=2`

Apple splits WeatherKit config across **two** tabs in the Developer Portal under the App ID, and Xcode only syncs one of them. If only the Capabilities tab is enabled the JWT issuance server rejects the app at runtime — the Capabilities checkbox is for entitlements, not for token signing.

**Fix (one-time, per App ID)**:

1. Apple Developer Portal → Identifiers → edit App ID (here: `fun.selfstudio.sunrise` AND `fun.selfstudio.sunrise.widget`).
2. **Capabilities tab** → confirm WeatherKit is checked. (Xcode usually does this for you when the entitlement is in `Sunrise.entitlements`.)
3. **App Services tab** → also enable WeatherKit here. **This is the step everyone misses.** Save.
4. Wait 30–60 min for the JWT server to propagate the App Services flip.
5. Xcode → Settings → Accounts → Download Manual Profiles. Clean build folder. Reinstall on device.

If you see Code=2 after a bundle id change, App Services almost always needs to be re-enabled on the new App ID — being on the old one doesn't carry over.

Reference: <https://walbum.app/zh/blog/weatherkit-configuration-trap>

## Bundle / group identifiers (canonical, all lowercase)

- App: `fun.selfstudio.sunrise`
- Widget: `fun.selfstudio.sunrise.widget`
- Tests: `fun.selfstudio.sunrise.tests`
- UITests: `fun.selfstudio.sunrise.uitests`
- App Group (shared between app + widget): `group.fun.selfstudio.sunrise`

Apple normalises App IDs to lowercase server-side, but Xcode signing is case-sensitive — keep these strings *exactly* as above wherever they appear (project.yml, both `.entitlements`, `SharedStorage.appGroupIdentifier`).

## Project shape

- **xcodegen** is the source of truth — `project.yml` generates `Sunrise.xcodeproj`. Don't edit the `.xcodeproj` directly; changes won't survive a regen.
- **TCA** (`pointfreeco/swift-composable-architecture`) drives state. Reducers live in `Packages/SunriseFeatures/Sources/<Feature>Feature/`.
- Local Swift packages: `SunriseCore`, `SunriseFeatures`, `SunriseDesignSystem`, `SunriseAnimation`. All on `swiftLanguageModes: [.v6]`.
- `-mockData` launch argument swaps every `*Client` to its `previewValue` so the UI populates without WeatherKit / CoreLocation. CI uses this; local dev can opt in via Edit Scheme → Arguments.

## CI

- `.github/workflows/ios.yml` runs unsigned simulator builds + UI tests on `macos-26`. Screenshots come out as the `screenshots` artifact (zip).
- For visual feedback in chat, fetch run artifacts with the `GH_PAT` env var via `api.github.com` and either `Read` PNGs locally or push to the `_screenshots-*` orphan branch and link via raw.githubusercontent.com.

## Merging to `main`

The local git proxy blocks direct pushes to `main` (HTTP 403 on the receive-pack endpoint), even for fast-forwards. **Always merge via a PR**:

1. Push the work to its `claude/<topic>-XXXX` branch (those pushes are allowed).
2. Open a PR with the GitHub MCP `create_pull_request` tool — `owner: codeeagle`, `repo: sunrise`, base `main`, head `claude/<topic>-XXXX`. The MCP server is already wired to `GH_PAT`.
3. Merge with `merge_pull_request` (default merge method works).

Don't waste cycles retrying `git push origin <branch>:main` — it stays 403 for the entire session.

Reference: PR #1 (`fix(icons): clamp spritesheet player size`) used this path after direct main pushes started failing mid-session.

## WeatherKit doesn't ship historical observations

`WeatherKit` only exposes **current + 10-day forecast**. There is **no** way to fetch a past day's actual weather from `WeatherService.weather(for:including:)`. `WeatherQuery.daily(startDate:endDate:)` only narrows the *future* window — calling it with both dates in the past returns HTTP 400 from the JWT issuer ("`Unable to authenticate`" wrapper around a malformed-request rejection).

Don't waste cycles spelunking for a hidden historical API or tweaking date math — there isn't one. The calendar tab fills in via a local rolling cache (`PersistenceClient.recordHistoricalDay`) that the Today tab writes to on every successful `weatherClient.fetch`. Over time this accumulates one row per day per city; that's the entire data source for the history calendar.

Reference: PR #6 + #8 (local-cache fallback after WeatherKit historical attempts kept 400'ing).

## Image-gen agent (codex CLI)

- Install: `npm i -g @openai/codex` (the operator authorises ChatGPT once the device code is printed).
- `codex login --device-auth` then visit `https://auth.openai.com/codex/device` with the printed code.
- Image generation: `codex exec --skip-git-repo-check --sandbox workspace-write --dangerously-bypass-approvals-and-sandbox -i <reference.png>` with prompt on stdin (the `-i FILE...` form swallows positional args, so always pipe the prompt).
- Generated PNGs land at `~/.codex/generated_images/<session>/ig_*.png`. **Always re-check dimensions** — gpt-image-2 ignores the requested size; resize via Pillow's LANCZOS to the target before shipping (App icons must be exactly 1024×1024, RGB only, no alpha — Xcode rejects otherwise).
- Sequential frames don't work for animation: each generation is independent so character / skyline / texture drift between frames produces visible flicker. For animation use Core Animation transforms (Ken Burns, parallax) on a single static painting instead.

## CoreLocation threading

`CLLocationManager` anchors its delegate-callback queue to the thread that *instantiated* the manager — setting the delegate later doesn't re-anchor it. TCA resolves `liveValue` lazily on a background TaskExecutor without a run loop, so any `CLLocationManager()` constructed there will silently never deliver `didUpdateLocations` / `didFailWithError`. The fix in `LocationClient.swift` hops both the constructor *and* the delegate hookup onto main via `DispatchQueue.main.sync`. Don't refactor that out without preserving the main-thread guarantee.
