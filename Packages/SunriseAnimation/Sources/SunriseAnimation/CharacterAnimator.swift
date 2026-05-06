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
