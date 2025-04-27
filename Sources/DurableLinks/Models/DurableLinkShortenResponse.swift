//

import Foundation

@objcMembers
public final class DurableLinkShortenResponse: NSObject, Decodable {
    public let shortLink: String
    public let warnings: [Warning]

    @objcMembers
    public final class Warning: NSObject, Decodable {
        public let warningMessage: String
    }
}
