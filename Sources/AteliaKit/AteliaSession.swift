import Foundation

/// Session state for a connected Atelia endpoint.
public struct AteliaSession: Sendable, Equatable, Identifiable {
    /// Stable session identifier.
    public var id: UUID
    /// Endpoint associated with the session.
    public var endpoint: AteliaEndpoint
    /// Display name shown for the session.
    public var displayName: String

    /// Creates a session with local-friendly defaults.
    public init(
        id: UUID = UUID(),
        endpoint: AteliaEndpoint = AteliaEndpoint(),
        displayName: String = "Local Secretary"
    ) {
        self.id = id
        self.endpoint = endpoint
        self.displayName = displayName
    }
}
