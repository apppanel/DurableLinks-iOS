//

import UIKit

@MainActor
@objc
public class DurableLinks: NSObject {
  
  private static var _shared: DurableLinks?
  
  @objc public static var shared: DurableLinks {
    guard let instance = _shared else {
      assertionFailure("Must call configure first")
      return DurableLinks()
    }
    return instance
  }
  
  @discardableResult
  @objc public static func configure(allowedHosts: [String]) -> DurableLinks {
    precondition(_shared == nil, "configure(...) called multiple times")
    let instance = DurableLinks()
    instance.allowedHosts = allowedHosts
    _shared = instance
    return instance
  }

  public weak var delegate: DurableLinkShortenerDelegate?
    
  private var allowedHosts: [String] = []

  private override init() { super.init() }
    
    public func handlePasteboardDurableLink() async throws -> DurableLink {
        let pasteboard = UIPasteboard.general
        if pasteboard.hasURLs {
            if let copiedURLString = pasteboard.string,
               let url = URL(string: copiedURLString) {
                return try await handleDurableLink(url)
            }
        }
        throw NSError(domain: "DurableLink", code: 0, userInfo: [NSLocalizedDescriptionKey: "No valid URL found in pasteboard"])
    }
    
    public func handleDurableLink(_ incomingURL: URL) async throws -> DurableLink {
        guard isValidDurableLink(incomingURL) else {
            throw NSError(domain: "DurableLink", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid durable link"])
        }
        
        guard let delegate else {
            throw NSError(domain: "DurableLink", code: 0, userInfo: [NSLocalizedDescriptionKey: "Shortener delegate unavailable"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            delegate.exchangeShortCode(requestedLink: incomingURL) { url, error in
                if let url = url {
                    continuation.resume(returning: DurableLink(longLink: url)!)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "DurableLink", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown error exchanging short code"]))
                }
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

extension DurableLinks {
    private func isValidDurableLink(_ url: URL) -> Bool {
        guard let host = url.host else {
            print("❌ Invalid URL: No host found.")
            return false
        }
        let canParse = canParseUniversalLink(url)
        let matchesShortLinkFormat = url.path.range(of: "/[^/]+", options: .regularExpression) != nil
        return canParse && matchesShortLinkFormat
    }

    private func canParseUniversalLink(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return isAllowedCustomDomain(url)
    }

    private func isAllowedCustomDomain(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return allowedHosts.contains(host)
    }
}
