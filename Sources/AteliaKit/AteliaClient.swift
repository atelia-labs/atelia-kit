import Foundation

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

    /// Returns a placeholder secretary status for the given session.
    public func status(for session: AteliaSession) async throws -> SecretaryStatus {
        _ = session
        return SecretaryStatus(
            phase: .unknown,
            message: "Protocol transport is not implemented yet."
        )
    }
}
