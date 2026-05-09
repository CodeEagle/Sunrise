#if canImport(SwiftUI)
import SwiftUI

/// Lively weather glyph with two render paths:
///
/// 1. **Spritesheet** — when `icon_<condition>_sheet.png` ships in the
///    bundle, slice it into frames and play through a `UIImageView`
///    animation. One codex call per spritesheet keeps every frame in
///    the same gen pass, so character / palette / texture stay locked
///    across the loop (sidesteps the per-call drift gotcha noted in
///    CLAUDE.md).
/// 2. **CA-overlay fallback** — when the spritesheet isn't bundled yet,
///    composite the static base icon with one or more codex-generated
///    overlay PNGs (raindrop, snowflake, lightning, wind streak), each
///    transformed via SwiftUI motion modifiers.
public struct AnimatedWeatherIcon: View {
    public let conditionRawValue: String
    public let isAnimating: Bool

    public init(conditionRawValue: String, isAnimating: Bool = true) {
        self.conditionRawValue = conditionRawValue
        self.isAnimating = isAnimating
    }

    public var body: some View {
        if let frames = spritesheetFrames {
            SpritesheetPlayer(frames: frames, duration: spritesheetDuration, isAnimating: isAnimating)
                .aspectRatio(1, contentMode: .fit)
        } else {
            FallbackOverlayIcon(conditionRawValue: conditionRawValue, isAnimating: isAnimating)
        }
    }

    private var spritesheetFrames: [UIImage]? {
        WeatherIconSpritesheet.loadFrames(
            named: "icon_\(conditionRawValue)_sheet",
            grid: WeatherIconSpritesheet.Grid(columns: 8, rows: 8)
        )
    }

    /// 64-frame loops driven by 8×8 spritesheets. UIImageView splits
    /// `duration / count` per frame, so a 2.5s loop @ 64 frames = 25.6
    /// fps which is comfortably inside the smooth-motion threshold —
    /// individual rotation / drop / drift deltas (5.6° per frame for
    /// the sun) are too small to read as discrete steps.
    private var spritesheetDuration: TimeInterval {
        switch conditionRawValue {
        case "clear": return 4.0           // sun rotation, ~16 fps
        case "cloudy", "fog": return 5.0   // drift cycle, ~13 fps
        case "rain": return 2.0            // drops fall, 32 fps
        case "snow": return 3.0            // tumble, ~21 fps
        case "thunderstorm": return 3.0    // flash cycle, ~21 fps
        case "windy": return 3.0           // streak slide, ~21 fps
        default: return 3.0
        }
    }
}

/// `UIImageView` wrapper that plays a frame array via
/// `animationImages` / `startAnimating`. SwiftUI's `Image` only takes a
/// single frame; UIImageView is the path to native frame animation.
///
/// The wrapped UIImageView's `intrinsicContentSize` is the source PNG's
/// pixel size (512×512 from the sliced spritesheet). Without
/// `sizeThatFits` SwiftUI inherits that as the natural width, so a
/// caller's `.frame(width: 32, height: 32)` only gets honoured if the
/// parent layout pre-clamps the proposal — many SwiftUI hosts don't,
/// which is what lets the icons "blow up" to fill the row. Returning
/// `proposal.replacingUnspecifiedDimensions(by:)` forces the
/// representable to honour whatever the parent proposes (clamped to
/// 32×32 when the parent leaves both axes unspecified).
private struct SpritesheetPlayer: UIViewRepresentable {
    let frames: [UIImage]
    let duration: TimeInterval
    let isAnimating: Bool

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.animationImages = frames
        view.animationDuration = duration
        view.animationRepeatCount = 0
        view.image = frames.first
        // Don't let UIImageView's huge intrinsic size leak into the
        // SwiftUI layout pass — the parent's `.frame` is the source of
        // truth for the displayed size.
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        if isAnimating {
            view.startAnimating()
        }
        return view
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions(by: CGSize(width: 32, height: 32))
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        // Re-bind frames on update so a condition change refreshes the
        // playing loop instead of stranding the previous condition's
        // frames.
        if view.animationImages?.count != frames.count {
            view.animationImages = frames
            view.animationDuration = duration
            view.image = frames.first
        }
        if isAnimating, !view.isAnimating {
            view.startAnimating()
        } else if !isAnimating, view.isAnimating {
            view.stopAnimating()
        }
    }
}

// MARK: - Fallback (Core Animation overlays)

private struct FallbackOverlayIcon: View {
    let conditionRawValue: String
    let isAnimating: Bool

    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                base(size: proxy.size)
                ForEach(overlaySpecs, id: \.id) { spec in
                    overlayView(spec: spec, size: proxy.size)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { startAnimation() }
        .onChange(of: isAnimating) { _, newValue in
            if newValue { startAnimation() } else { phase = 0 }
        }
    }

    private func base(size: CGSize) -> some View {
        baseImage
            .resizable()
            .scaledToFit()
            .modifier(BaseMotionModifier(condition: conditionRawValue, phase: phase))
            .frame(width: size.width, height: size.height)
    }

    private var baseImage: Image {
        if let watercolor = WeatherIconArt.image(forConditionRawValue: conditionRawValue) {
            return Image(uiImage: watercolor)
        }
        return Image(systemName: ConditionGlyph.symbolName(forConditionRawValue: conditionRawValue))
    }

    private struct OverlaySpec {
        let id: String
        let assetName: String
        let xFraction: CGFloat
        let yFraction: CGFloat
        let size: CGFloat
        let delay: CGFloat
    }

    private var overlaySpecs: [OverlaySpec] {
        switch conditionRawValue {
        case "rain":
            return [
                .init(id: "drop-1", assetName: "raindrop_overlay", xFraction: 0.34, yFraction: 0.78, size: 0.18, delay: 0.0),
                .init(id: "drop-2", assetName: "raindrop_overlay", xFraction: 0.62, yFraction: 0.82, size: 0.16, delay: 0.5)
            ]
        case "snow":
            return [
                .init(id: "flake-1", assetName: "snowflake_overlay", xFraction: 0.35, yFraction: 0.78, size: 0.20, delay: 0.0),
                .init(id: "flake-2", assetName: "snowflake_overlay", xFraction: 0.62, yFraction: 0.82, size: 0.18, delay: 0.4)
            ]
        case "thunderstorm":
            return [
                .init(id: "bolt", assetName: "lightning_overlay", xFraction: 0.5, yFraction: 0.72, size: 0.32, delay: 0.0)
            ]
        case "windy":
            return [
                .init(id: "wind-1", assetName: "wind_overlay", xFraction: 0.5, yFraction: 0.45, size: 0.7, delay: 0.0),
                .init(id: "wind-2", assetName: "wind_overlay", xFraction: 0.5, yFraction: 0.65, size: 0.55, delay: 0.5)
            ]
        default:
            return []
        }
    }

    @ViewBuilder
    private func overlayView(spec: OverlaySpec, size: CGSize) -> some View {
        if let image = bundledImage(name: spec.assetName) {
            let edge = size.width * spec.size
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: edge, height: edge)
                .modifier(OverlayMotionModifier(
                    condition: conditionRawValue,
                    phase: phase,
                    delay: spec.delay
                ))
                .position(x: size.width * spec.xFraction, y: size.height * spec.yFraction)
        }
    }

    private func bundledImage(name: String) -> UIImage? {
        if let asset = UIImage(named: name) { return asset }
        if let path = Bundle.main.path(forResource: name, ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }

    private func startAnimation() {
        guard isAnimating else { return }
        phase = 0
        withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
            phase = 1
        }
    }

    private var animationDuration: Double {
        switch conditionRawValue {
        case "clear": return 12
        case "cloudy", "fog": return 8
        case "rain": return 1.6
        case "snow": return 2.4
        case "thunderstorm": return 3
        case "windy": return 2.4
        default: return 6
        }
    }
}

private struct BaseMotionModifier: ViewModifier {
    let condition: String
    let phase: CGFloat

    func body(content: Content) -> some View {
        switch condition {
        case "clear":
            content.rotationEffect(.degrees(Double(phase) * 360))
        case "cloudy", "fog":
            content.offset(x: sin(Double(phase) * 2 * .pi) * 4)
        case "rain", "snow":
            content.offset(y: sin(Double(phase) * 2 * .pi) * 2)
        case "thunderstorm":
            content.opacity(1 - max(0, sin(Double(phase) * 2 * .pi) * 0.25))
        case "windy":
            content.rotationEffect(.degrees(sin(Double(phase) * 2 * .pi) * 4))
        default:
            content
        }
    }
}

private struct OverlayMotionModifier: ViewModifier {
    let condition: String
    let phase: CGFloat
    let delay: CGFloat

    private var local: CGFloat {
        var p = phase + delay
        if p >= 1 { p -= 1 }
        return p
    }

    func body(content: Content) -> some View {
        switch condition {
        case "rain":
            content
                .offset(y: -8 + local * 28)
                .opacity(1 - abs(local - 0.5) * 1.4)
        case "snow":
            content
                .offset(y: -8 + local * 28)
                .rotationEffect(.degrees(Double(local) * 360))
                .opacity(1 - abs(local - 0.5) * 1.2)
        case "thunderstorm":
            let flash = pow(max(0, sin(Double(local) * 2 * .pi)), 8)
            content.opacity(0.2 + flash)
        case "windy":
            content
                .offset(x: -40 + local * 80)
                .opacity(1 - abs(local - 0.5) * 1.6)
        default:
            content
        }
    }
}
#endif
