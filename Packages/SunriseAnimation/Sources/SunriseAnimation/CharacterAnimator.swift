import Foundation

/// Drives the animated character. v1 ships with static art per condition;
/// later milestones swap in Lottie / Rive state machines.
///
/// Marked `@MainActor` because every conformer (`LottieCharacterView`) is a
/// UIView, which is itself main-actor isolated under Swift 6. Without this
/// the conformance crosses actor isolation and the compiler refuses with
/// "crosses into main actor-isolated code". `Sendable` is intentionally
/// dropped — main-actor classes don't need it for in-process UI dispatch.
@MainActor
public protocol CharacterAnimator: AnyObject {
    func update(condition: AnimatedCondition, dayPeriod: AnimatedDayPeriod)
}

public enum AnimatedCondition: String, Sendable, CaseIterable {
    case clear, cloudy, rain, thunderstorm, snow, windy, fog
}

public enum AnimatedDayPeriod: String, Sendable {
    case dawn, day, dusk, night
}

/// Convention for finding character animation JSON in a host app's bundle.
/// Drop files at `Resources/Lottie/character_<condition>.json` and the loader
/// will pick them up. Missing files trigger the static fallback.
public enum CharacterAnimationCatalog {
    public static func filename(for condition: AnimatedCondition) -> String {
        "character_\(condition.rawValue)"
    }
}
