import Foundation

public struct DurableLinkItunesConnectAnalyticsParameters: Sendable, Codable {

    /// The iTunes Connect affiliate token.
    public var affiliateToken: String?

    /// The iTunes Connect campaign token.
    public var campaignToken: String?

    /// The iTunes Connect provider token.
    public var providerToken: String?
    
    enum CodingKeys: String, CodingKey {
        case affiliateToken = "at"
        case campaignToken = "ct"
        case providerToken = "pt"
    }
    
    public init(affiliateToken: String? = nil, campaignToken: String? = nil, providerToken: String? = nil) {
        self.affiliateToken = affiliateToken
        self.campaignToken = campaignToken
        self.providerToken = providerToken
    }
    
}
