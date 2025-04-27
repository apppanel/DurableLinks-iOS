//

import UIKit

@objc
public final class DurableLinks: NSObject, @unchecked Sendable {
  
    nonisolated(unsafe) private static var lock = DispatchQueue(label: "com.yourapp.DurableLinks.lock")
    nonisolated(unsafe) private static var _shared: DurableLinks?
  
    @objc public static var shared: DurableLinks {
      return lock.sync {
        guard let instance = _shared else {
          assertionFailure("Must call DurableLinks.configure first")
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
        throw DurableLinksError.noURLInPasteboard
    }
    
    public func handleDurableLink(_ incomingURL: URL) async throws -> DurableLink {
        guard isValidDurableLink(incomingURL) else {
            throw DurableLinksError.invalidDurableLink
        }
        
        guard let delegate else {
            throw DurableLinksError.delegateUnavailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            delegate.exchangeShortCode(requestedLink: incomingURL) { url, error in
                if let url = url {
                    continuation.resume(returning: DurableLink(longLink: url)!)
                } else {
                    continuation.resume(throwing: error ?? DurableLinksError.unknownDelegateResponse)
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
        completion(
          nil,
          nil,
          DurableLinksError.delegateUnavailable
        )
        return
      }
        
        guard let longURL = durableLink.url else {
            completion(
              nil,
              nil,
              DurableLinksError.invalidDurableLink
            )
            return
        }

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
          throw DurableLinksError.delegateUnavailable
      }
        
        guard let longURL = durableLink.url  else {
            throw DurableLinksError.invalidDurableLink
        }

      return try await withCheckedThrowingContinuation { continuation in
        delegate.shortenURL(longURL: longURL) { shortURL, warnings, error in
          if let error = error {
            continuation.resume(throwing: error)
          } else if let shortURL = shortURL {
            continuation.resume(returning: (shortURL, warnings))
          } else {
            continuation.resume(
                throwing: DurableLinksError.unknownDelegateResponse
              )
          }
        }
      }
    }
}

extension DurableLinks {
    private func isValidDurableLink(_ url: URL) -> Bool {
        guard let host = url.host else {
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
