# Character Lottie animations

Drop Lottie JSON files in this folder to enable animated character art.

## Naming

Each weather condition expects a file named `character_<condition>.json`:

- `character_clear.json`
- `character_cloudy.json`
- `character_rain.json`
- `character_thunderstorm.json`
- `character_snow.json`
- `character_windy.json`
- `character_fog.json`

Missing files are tolerated — the app falls back to the SF Symbol portrait so
you can ship one condition at a time.

## Bundling

`project.yml` already lists `Sunrise/Resources` in the app target's resources
list, so any `.json` you drop here is copied into the bundle automatically.
After adding files, re-run `xcodegen generate` so the project file picks them
up.

## Tooling

Author the animations in After Effects with the
[Bodymovin / Lottie Files](https://lottiefiles.com/plugins) plugin, or
generate them via Rive (export the timeline to Lottie). Aim for ~512px
square, 24-30fps, looping motion ≤ 6 seconds.
