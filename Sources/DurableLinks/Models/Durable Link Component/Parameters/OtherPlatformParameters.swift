import Foundation

public struct DurableLinkOtherPlatformParameters: Sendable, Codable {
    
    public var fallbackURL: URL?

    enum CodingKeys: String, CodingKey {
        case fallbackURL = "ofl"
    }

    public init(fallbackURL: URL? = nil) {
        self.fallbackURL = fallbackURL
    }
}
