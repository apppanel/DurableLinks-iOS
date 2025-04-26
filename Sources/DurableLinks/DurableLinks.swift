//

import UIKit

public class DurableLinks {
    
    @MainActor static public func handlePasteboardDurableLink(completion: @escaping @Sendable (Result<DurableLink, Error>) -> Void) {
        let pasteboard = UIPasteboard.general
        if pasteboard.hasURLs {
            if let copiedURLString = pasteboard.string, let url = URL(string: copiedURLString) {
                handleDurableLink(url, completion: completion)
            }
        }
    }

    static public func handleDurableLink(_ incomingURL: URL, completion: @escaping @Sendable (Result<DurableLink, Error>) -> Void) {
        Task {
            if await isValidDurableLink(incomingURL) {
                    await DurableLinkConfig.shared.getShortenerDelegate()?.exchangeShortCode(requestedLink: incomingURL) { url, error in
                        if let url = url {
                            completion(.success(DurableLink(longLink: url)!))
                        } else {
                            completion(.failure(error ?? NSError(domain: "DurableLink", code: 1, userInfo: [NSLocalizedDescriptionKey: "errorDescription"])))
                        }
                    }
            } else {
                completion(.failure(NSError(domain: "Invalid durable link", code: 0, userInfo: nil)))
            }
        }
    }

    private static func isValidDurableLink(_ url: URL) async -> Bool {
        guard let host = url.host else {
            print("❌ Invalid URL: No host found.")
            return false
        }
        let canParse = await canParseUniversalLink(url)
        let matchesShortLinkFormat = url.path.range(of: "/[^/]+", options: .regularExpression) != nil
        return canParse && matchesShortLinkFormat
    }

    private static func canParseUniversalLink(_ url: URL) async -> Bool {
        guard let host = url.host else { return false }
        return await isAllowedCustomDomain(url)
    }

    private static func isAllowedCustomDomain(_ url: URL) async -> Bool {
        guard let host = url.host else { return false }
        let allowedCustomDomains = await DurableLinkConfig.shared.getShortenerDelegate()?.getAllowedDomains() ?? []
        return allowedCustomDomains.contains(host)
    }
}
