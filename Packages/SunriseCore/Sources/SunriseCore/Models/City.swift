import Foundation
import CoreLocation

public struct City: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let region: String?
    public let country: String?
    public let latitude: Double
    public let longitude: Double
    public let timeZoneIdentifier: String?

    public init(
        id: UUID = UUID(),
        name: String,
        region: String? = nil,
        country: String? = nil,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.region = region
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
