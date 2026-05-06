import Foundation

/// Drives the animated character. v1 ships with static art per condition;
/// later milestones swap in Lottie / Rive state machines.
public protocol CharacterAnimator: AnyObject, Sendable {
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
