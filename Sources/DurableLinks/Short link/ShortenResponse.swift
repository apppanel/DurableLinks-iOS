import Foundation

public struct DurableLinkShortenResponse: Decodable {
    public let shortLink: String?
    public let warning: [Warning]?

    public struct Warning: Decodable {
        public let warningMessage: String
    }
}


public struct ExchangeLinkResponse: Decodable {
    public let longLink: URL?
}
