import Foundation

public protocol DurableLinkShortenerDelegate: AnyObject, Sendable {
    /// Called when a shortened URL is requested.
    /// The delegate must perform the network request and call the completion.
    func shortenURL(
        longURL: URL,
        options: DurableLinkComponentsOptions,
        completion: @escaping (URL?, [String]?, Error?) -> Void
    )
}
