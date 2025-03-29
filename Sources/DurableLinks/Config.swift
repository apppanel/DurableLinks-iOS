import Foundation

public actor DurableLinkConfig {
    public static let shared = DurableLinkConfig()
    private weak var _shortenerDelegate: DurableLinkShortenerDelegate?

    public func setShortenerDelegate(_ delegate: DurableLinkShortenerDelegate?) {
        self._shortenerDelegate = delegate
    }

    public func getShortenerDelegate() -> DurableLinkShortenerDelegate? {
        return _shortenerDelegate
    }
}
