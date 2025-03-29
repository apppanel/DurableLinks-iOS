import Foundation

public struct DurableLinkSocialMetaTagParameters: Sendable, Codable {
    
    public var title: String?

    /// The description to be used when the Durable Link is shared in a social post.
    public var descriptionText: String?

    /// The image URL to be used when the Durable Link is shared in a social post.
    public var imageURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case title = "st"
        case descriptionText = "sd"
        case imageURL = "si"
    }


    public init(title: String? = nil, descriptionText: String? = nil, imageURL: URL? = nil) {
        self.title = title
        self.descriptionText = descriptionText
        self.imageURL = imageURL
    }
}
