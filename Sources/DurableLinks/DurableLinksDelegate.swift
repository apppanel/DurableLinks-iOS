import Foundation

@objc public protocol DurableLinksDelegate: AnyObject {
    @objc func shortenURL(
        longURL: URL,
        completion: @escaping (DurableLinkShortenResponse?, Error?) -> Void
    )

    @objc func exchangeShortCode(
        requestedLink: URL,
        completion: @escaping (ExchangeLinkResponse?, Error?) -> Void
    )
}
