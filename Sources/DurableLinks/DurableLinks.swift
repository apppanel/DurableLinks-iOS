//

import UIKit

@objc
public final class DurableLinks: NSObject, @unchecked Sendable {
  
    nonisolated(unsafe) private static var lock = DispatchQueue(label: "com.yourapp.DurableLinks.lock")
    nonisolated(unsafe) private static var _shared: DurableLinks?
  
    @objc public static var shared: DurableLinks {
      return lock.sync {
        guard let instance = _shared else {
          assertionFailure("Must call configure first")
          return DurableLinks()
        }
        return instance
      }
    }
  
@discardableResult
@objc public static func configure(allowedHosts: [String]) -> DurableLinks {
    return lock.sync {
        precondition(_shared == nil, "configure(...) called multiple times")
        let instance = DurableLinks()
        instance.allowedHosts = allowedHosts
        _shared = instance
        return instance
    }
}

  public weak var delegate: DurableLinkShortenerDelegate?
    
  private var allowedHosts: [String] = []

  private override init() { super.init() }
}

extension DurableLinks {
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
    public func shorten(
      durableLink: DurableLinkComponents,
      completion: @escaping (URL?, [String]?, Error?) -> Void
    ) {
      guard let delegate = DurableLinks.shared.delegate else {
        assertionFailure(
          "No DurableLinkShortenerDelegate configured. " +
          "You must set DurableLinkConfig.shared.setShortenerDelegate(...) before shortening URLs."
        )
        // immediately call back with an error
        completion(
          nil,
          nil,
          NSError(
            domain: "com.yourapp.DurableLinks",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "No delegate configured"]
          )
        )
        return
      }
        
        guard let longURL = durableLink.url else {
            completion(
              nil,
              nil,
              NSError(
                domain: "com.yourapp.DurableLinks",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Durable link is not valid"]
              )
            )
            return
        }

      // just forward the call directly to the delegate
      delegate.shortenURL(longURL: longURL) { shortURL, warnings, error in
        completion(shortURL, warnings, error)
      }
    }

    public func shorten(
        durableLink: DurableLinkComponents
    ) async throws -> (URL, [String]?) {
      guard let delegate = DurableLinks.shared.delegate else {
        assertionFailure(
          "No DurableLinkShortenerDelegate configured. " +
          "You must set DurableLinkConfig.shared.setShortenerDelegate(...) before shortening URLs."
        )
        throw NSError(
          domain: "com.yourapp.DurableLinks",
          code: 0,
          userInfo: [NSLocalizedDescriptionKey: "No delegate configured"]
        )
      }
        
        guard let longURL = durableLink.url  else {
            throw NSError(domain: "com.yourapp.DurableLinks", code: 0, userInfo: [NSLocalizedDescriptionKey: "Durable Link is not valid"])
        }

      return try await withCheckedThrowingContinuation { continuation in
        delegate.shortenURL(longURL: longURL) { shortURL, warnings, error in
          if let error = error {
            continuation.resume(throwing: error)
          } else if let shortURL = shortURL {
            continuation.resume(returning: (shortURL, warnings))
          } else {
            continuation.resume(
              throwing: NSError(
                domain: "com.yourapp.DurableLinks",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Unknown delegate response"]
              )
            )
          }
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
