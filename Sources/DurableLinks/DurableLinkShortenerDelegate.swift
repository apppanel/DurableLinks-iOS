import Foundation

@objc public protocol DurableLinkShortenerDelegate: AnyObject {
    /// Called when a shortened URL is requested.
    /// The delegate must perform the network request and call the completion.
    @objc func shortenURL(
        longURL: URL,
        completion: @escaping (URL?, [String]?, Error?) -> Void
    )

    @objc func exchangeShortCode(
        requestedLink: URL,
        completion: @escaping (URL?, Error?) -> Void
    )
}
