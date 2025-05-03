import Foundation

@objc public protocol DurableLinkShortenerDelegate: AnyObject {
    /// The delegate must perform the network request and call the completion.
    @objc func shortenURL(
        longURL: URL,
        completion: @escaping (DurableLinkShortenResponse?, Error?) -> Void
    )

    /// The delegate must perform the network request and call the completion.
    @objc func exchangeShortCode(
        requestedLink: URL,
        completion: @escaping (ExchangeLinkResponse?, Error?) -> Void
    )
}
