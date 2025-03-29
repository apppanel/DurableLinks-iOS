import Foundation

public enum DurableLinkPathLength: String, Sendable {
    case short = "SHORT"
    case unguessable = "UNGUESSABLE"
}

public struct DurableLinkComponentsOptions: Sendable {
    public var pathLength: DurableLinkPathLength

    public init(pathLength: DurableLinkPathLength = .unguessable) {
        self.pathLength = pathLength
    }
    
}
