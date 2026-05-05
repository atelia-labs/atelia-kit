import Foundation

/// Derived secretary health state surfaced by the client.
public struct SecretaryStatus: Sendable, Equatable {
    /// Normalized status phase.
    public enum Phase: String, Sendable, Equatable {
        /// Status could not be determined.
        case unknown
        /// The secretary is not available.
        case offline
        /// The secretary is still starting.
        case starting
        /// The secretary is ready.
        case ready
        /// The secretary is available with reduced health.
        case degraded
    }

    /// Normalized phase for the secretary.
    public var phase: Phase
    /// Optional human-readable status message.
    public var message: String?
    /// Time the status was checked.
    public var checkedAt: Date

    /// Creates a secretary status snapshot.
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
