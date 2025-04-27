import Foundation

@objc
public enum DurableLinksError: Int, Error {
    case notConfigured
    case invalidDurableLink
    case delegateUnavailable
    case unknownDelegateResponse
    case noURLInPasteboard

    var nsError: NSError {
        switch self {
        case .notConfigured:
            return NSError(domain: "com.yourapp.DurableLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "DurableLinks not configured"])
        case .invalidDurableLink:
            return NSError(domain: "com.yourapp.DurableLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "Invalid durable link"])
        case .delegateUnavailable:
            return NSError(domain: "com.yourapp.DurableLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "Delegate unavailable"])
        case .unknownDelegateResponse:
            return NSError(domain: "com.yourapp.DurableLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "Unknown response from delegate"])
        case .noURLInPasteboard:
            return NSError(domain: "com.yourapp.DurableLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "No valid URL found in pasteboard"])
        }
    }
}
