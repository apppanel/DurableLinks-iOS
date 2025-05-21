import Foundation

@objc
public enum DurableLinksSDKError: Int, Error {
    case notConfigured
    case invalidDurableLink
    case delegateUnavailable
    case unknownDelegateResponse
    case noURLInPasteboard
    case alreadyCheckedPasteboard

    var nsError: NSError {
        switch self {
        case .notConfigured:
            return NSError(domain: "com.DurableLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "DurableLinks not configured"])
        case .invalidDurableLink:
            return NSError(domain: "com.DurableLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "Invalid durable link"])
        case .delegateUnavailable:
            return NSError(domain: "com.DurableLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "Delegate unavailable"])
        case .unknownDelegateResponse:
            return NSError(
                domain: "com.DurableLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "Unknown response from delegate"])
        case .noURLInPasteboard:
            return NSError(
                domain: "com.DurableLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "No valid URL found in pasteboard"])
        case .alreadyCheckedPasteboard:
            return NSError(
                domain: "com.DurableLinks", code: rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Already checked pasteboard for Durable Link once, further checks will fail immediately as handling now goes through handleDurableLink"
                ])
        }
    }
}
