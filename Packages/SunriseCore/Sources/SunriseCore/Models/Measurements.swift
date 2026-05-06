import Foundation

public struct Temperature: Codable, Hashable, Sendable {
    public let celsius: Double
    public init(celsius: Double) { self.celsius = celsius }
    public var fahrenheit: Double { celsius * 9 / 5 + 32 }
}

public struct Wind: Codable, Hashable, Sendable {
    public let speedKPH: Double
    public let directionDegrees: Double
    public init(speedKPH: Double, directionDegrees: Double) {
        self.speedKPH = speedKPH
        self.directionDegrees = directionDegrees
    }
    public var speedMPS: Double { speedKPH / 3.6 }
    public var speedMPH: Double { speedKPH * 0.621371 }
}

public struct Percent: Codable, Hashable, Sendable {
    public let value: Double // 0...1
    public init(value: Double) { self.value = max(0, min(1, value)) }
}
