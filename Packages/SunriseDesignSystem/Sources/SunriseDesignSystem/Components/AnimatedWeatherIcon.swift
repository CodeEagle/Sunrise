#if canImport(SwiftUI)
import SwiftUI

/// Lively weather glyph — composes the bundled base icon
/// (`icon_<condition>.png`) with one or more codex-generated transparent
/// overlay PNGs (raindrop, snowflake, lightning, wind streak), each
/// animated via Core Animation transforms.
///
/// Why this shape: gpt-image-2 sequence frames flicker because each call
/// drifts visual style (the gotcha noted in CLAUDE.md). Decomposing the
/// scene into a stable static base + one isolated motion element keeps
/// the look consistent — only the overlay moves, the base never redraws.
public struct AnimatedWeatherIcon: View {
    public let conditionRawValue: String
    public let isAnimating: Bool

    @State private var phase: CGFloat = 0

    public init(conditionRawValue: String, isAnimating: Bool = true) {
        self.conditionRawValue = conditionRawValue
        self.isAnimating = isAnimating
    }

    public var body: some View {
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

    // MARK: - Base

    @ViewBuilder
    private func base(size: CGSize) -> some View {
        let baseImage: Image
        if let watercolor = WeatherIconArt.image(forConditionRawValue: conditionRawValue) {
            baseImage = Image(uiImage: watercolor)
        } else {
            baseImage = Image(systemName: ConditionGlyph.symbolName(forConditionRawValue: conditionRawValue))
        }
        baseImage
            .resizable()
            .scaledToFit()
            .modifier(BaseMotionModifier(condition: conditionRawValue, phase: phase))
            .frame(width: size.width, height: size.height)
    }

    // MARK: - Overlays

    /// Spec for one animated overlay layer. `xFraction`/`yFraction` are
    /// where the layer's centre sits in the canvas (0–1). `size` is the
    /// layer's edge length as a fraction of the canvas. `delay` shifts
    /// the layer's animation phase so multiple layers don't move in lockstep.
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

    // MARK: - Animation driver

    private func startAnimation() {
        guard isAnimating else { return }
        phase = 0
        withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
            phase = 1
        }
    }

    private var animationDuration: Double {
        switch conditionRawValue {
        case "clear": return 12          // slow sun rotation
        case "cloudy", "fog": return 8   // gentle drift
        case "rain": return 1.6          // looping drops
        case "snow": return 2.4          // tumbling flakes
        case "thunderstorm": return 3    // flash cycle
        case "windy": return 2.4         // sway + streaks
        default: return 6
        }
    }
}

/// Motion applied to the base icon. Movements here are kept subtle so the
/// overlay layers carry most of the personality.
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
            // Cloud bobs gently while drops/flakes fall below it.
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

/// Motion applied per overlay layer. Different per condition:
/// - rain: drops translate down + fade in/out for a rainfall illusion.
/// - snow: flakes translate down with rotation.
/// - thunderstorm: bolt flashes by toggling opacity at peak phase.
/// - windy: streaks slide left → right and fade.
private struct OverlayMotionModifier: ViewModifier {
    let condition: String
    let phase: CGFloat
    let delay: CGFloat

    private var local: CGFloat {
        // Loop-shifted phase that keeps each layer at its own offset.
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
            // Sharp flash at the peak of the cycle.
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
