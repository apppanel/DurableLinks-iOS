import Foundation

public struct DurableLinkIOSParameters: Sendable, Codable {

    /// The App Store ID of the iOS app in App Store.
    public var appStoreID: String?

    /// The link to open when the app isn't installed.
    public var fallbackURL: URL?

    /// The link to open on iPads when the app isn't installed.
    public var iPadFallbackURL: URL?

    /// The minimum version of your app that can open the link.
    public var minimumAppVersion: String?
    
    
    enum CodingKeys: String, CodingKey {
        case appStoreID = "isi"
        case fallbackURL = "ifl"
        case iPadFallbackURL = "ipfl"
        case minimumAppVersion = "imv"
    }
    
    public init(appStoreID: String? = nil, fallbackURL: URL? = nil, iPadFallbackURL: URL? = nil, minimumAppVersion: String? = nil) {
        self.appStoreID = appStoreID
        self.fallbackURL = fallbackURL
        self.iPadFallbackURL = iPadFallbackURL
        self.minimumAppVersion = minimumAppVersion
    }

}
