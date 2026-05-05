import Foundation

/// Errors thrown by the default `AteliaClient` compatibility surface.
public enum AteliaClientError: Error, Sendable, Equatable {
    /// The conformer does not provide a health snapshot implementation.
    case healthUnavailable
    /// The conformer does not provide a repertoire implementation.
    case repertoireUnavailable
}

/// Protocol for fetching Atelia health, repertoire, and derived secretary status for a session.
public protocol AteliaClient: Sendable {
    /// Returns the current health snapshot for the given session.
    func health(for session: AteliaSession) async throws -> AteliaHealthResponse
    /// Returns the current repertoire entries for the given session.
    func repertoire(for session: AteliaSession) async throws -> [AteliaRepertoireEntry]
    /// Returns the secretary status derived from the current health snapshot.
    func status(for session: AteliaSession) async throws -> SecretaryStatus
}

public extension AteliaClient {
    /// Returns a compatibility error when the conformer does not provide health.
    func health(for session: AteliaSession) async throws -> AteliaHealthResponse {
        _ = session
        throw AteliaClientError.healthUnavailable
    }

    /// Returns a compatibility error when the conformer does not provide repertoire.
    func repertoire(for session: AteliaSession) async throws -> [AteliaRepertoireEntry] {
        _ = session
        throw AteliaClientError.repertoireUnavailable
    }

    /// Returns the secretary status derived from the current health snapshot.
    func status(for session: AteliaSession) async throws -> SecretaryStatus {
        let health = try await health(for: session)
        return health.secretaryStatus
    }
}

/// In-memory client used by tests and local development.
public actor LocalAteliaClient: AteliaClient {
    /// Creates a local client that returns placeholder data.
    public init() {}

    /// Returns a placeholder health snapshot for the given session.
    public func health(for session: AteliaSession) async throws -> AteliaHealthResponse {
        _ = session
        return AteliaHealthResponse(
            daemonStatus: .starting,
            daemonVersion: "0.0.0",
            protocolVersion: "0.1.0",
            storageVersion: "0.0.0",
            storageStatus: .unavailable,
            capabilities: [],
            betaState: nil
        )
    }

    /// Returns an empty repertoire for the given session.
    public func repertoire(for session: AteliaSession) async throws -> [AteliaRepertoireEntry] {
        _ = session
        return []
    }

}
