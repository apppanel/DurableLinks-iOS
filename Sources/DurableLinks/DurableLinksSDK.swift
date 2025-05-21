//

import UIKit

@objc
public final class DurableLinksSDK: NSObject, @unchecked Sendable {

    @objc public static let SDKVersion: String = "1.0.0"
    
    nonisolated(unsafe) private static var lock = DispatchQueue(label: "com.DurableLinks.lock")
    nonisolated(unsafe) private static var _shared: DurableLinksSDK?

    @objc public static var shared: DurableLinksSDK {
        return lock.sync {
            guard let instance = _shared else {
                assertionFailure("Must call DurableLinks.configure first")
                return DurableLinksSDK()
            }
            return instance
        }
    }

    @discardableResult
    @objc public static func configure(allowedHosts: [String]) -> DurableLinksSDK {
        return lock.sync {
            precondition(_shared == nil, "configure(...) called multiple times")
            let instance = DurableLinksSDK()
            instance.allowedHosts = allowedHosts
            _shared = instance
            return instance
        }
    }

    @objc public weak var delegate: DurableLinksDelegate?

    private var allowedHosts: [String] = []

    private override init() { super.init() }
}


extension DurableLinksSDK {
    public func handlePasteboardDurableLink() async throws -> DurableLink {
        let hasCheckedPasteboardKey = "hasCheckedPasteboardForDurableLink"

        if UserDefaults.standard.bool(forKey: hasCheckedPasteboardKey) {
            throw DurableLinksSDKError.alreadyCheckedPasteboard
        }

        UserDefaults.standard.set(true, forKey: hasCheckedPasteboardKey)

        let pasteboard = UIPasteboard.general
        if pasteboard.hasURLs {
            if let copiedURLString = pasteboard.string,
                let url = URL(string: copiedURLString)
            {
                let durableLink = try await handleDurableLink(url)
                if pasteboard.string == copiedURLString {
                    pasteboard.string = nil
                }
                return durableLink
            }
        }
        throw DurableLinksSDKError.noURLInPasteboard
    }

    public func handleDurableLink(_ incomingURL: URL) async throws -> DurableLink {
        guard isValidDurableLink(url: incomingURL) else {
            throw DurableLinksSDKError.invalidDurableLink
        }

        guard let delegate else {
            throw DurableLinksSDKError.delegateUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            delegate.exchangeShortCode(requestedLink: incomingURL) { response, error in
                guard
                    let longLink = response?.longLink,
                    let durableLink = DurableLink(longLink: longLink)
                else {
                    continuation.resume(throwing: error ?? DurableLinksSDKError.unknownDelegateResponse)
                    return
                }
                continuation.resume(returning: durableLink)
            }
        }
    }

    @objc
    public func handlePasteboardDurableLink(completion: @Sendable @escaping (DurableLink?, NSError?) -> Void) {
        Task {
            do {
                let durableLink = try await handlePasteboardDurableLink()
                completion(durableLink, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }

    @objc
    public func handleDurableLink(_ incomingURL: URL, completion: @Sendable @escaping (DurableLink?, NSError?) -> Void) {
        Task {
            do {
                let durableLink = try await handleDurableLink(incomingURL)
                completion(durableLink, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }
}

extension DurableLinksSDK {
    public func shorten(
        durableLink: DurableLinkComponents,
        completion: @escaping (DurableLinkShortenResponse?, Error?) -> Void
    ) {
        guard let delegate = DurableLinksSDK.shared.delegate else {
            assertionFailure(
                "No DurableLinkShortenerDelegate configured. "
                    + "You must set DurableLinkConfig.shared.setShortenerDelegate(...) before shortening URLs."
            )
            completion(
                nil,
                DurableLinksSDKError.delegateUnavailable
            )
            return
        }

        guard let longURL = durableLink.url else {
            completion(
                nil,
                DurableLinksSDKError.invalidDurableLink
            )
            return
        }

        delegate.shortenURL(longURL: longURL) { durableLinkShortenResponse, error in
            completion(durableLinkShortenResponse, error)
        }
    }

    public func shorten(
        durableLink: DurableLinkComponents
    ) async throws -> DurableLinkShortenResponse {
        guard let delegate = DurableLinksSDK.shared.delegate else {
            assertionFailure(
                "No DurableLinkShortenerDelegate configured. "
                    + "You must set DurableLinkConfig.shared.setShortenerDelegate(...) before shortening URLs."
            )
            throw DurableLinksSDKError.delegateUnavailable
        }

        guard let longURL = durableLink.url else {
            throw DurableLinksSDKError.invalidDurableLink
        }

        return try await withCheckedThrowingContinuation { continuation in
            delegate.shortenURL(longURL: longURL) { durableLinkShortenResponse, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let durableLinkShortenResponse = durableLinkShortenResponse {
                    continuation.resume(returning: (durableLinkShortenResponse))
                } else {
                    continuation.resume(
                        throwing: DurableLinksSDKError.unknownDelegateResponse
                    )
                }
            }
        }
    }
}

extension DurableLinksSDK {
    public func isValidDurableLink(url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }
        let canParse = canParseDurableLink(url)
        let matchesShortLinkFormat = url.path.range(of: "/[^/]+", options: .regularExpression) != nil
        return canParse && matchesShortLinkFormat
    }

    private func canParseDurableLink(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return isAllowedCustomDomain(url)
    }

    private func isAllowedCustomDomain(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return allowedHosts.contains(host)
    }
}
