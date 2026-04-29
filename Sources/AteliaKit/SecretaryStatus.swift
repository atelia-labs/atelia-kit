import Foundation

public struct SecretaryStatus: Sendable, Equatable {
    public enum Phase: String, Sendable, Equatable {
        case unknown
        case offline
        case starting
        case ready
        case degraded
    }

    public var phase: Phase
    public var message: String?
    public var checkedAt: Date

    public init(
        phase: Phase = .unknown,
        message: String? = nil,
        checkedAt: Date = Date()
    ) {
        self.phase = phase
        self.message = message
        self.checkedAt = checkedAt
    }
}
