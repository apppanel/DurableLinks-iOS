import Foundation

@objc public final class DurableLinkOptionsParameters: NSObject, Codable, @unchecked Sendable {

    @objc
    public enum DurableLinkPathLength: Int, Codable, @unchecked Sendable {
        case unguessable = 0
        case short = 1
    }

    @objc public var pathLength: DurableLinkPathLength

    @objc
    public init(pathLength: DurableLinkPathLength = .unguessable) {
        self.pathLength = pathLength
    }

}
