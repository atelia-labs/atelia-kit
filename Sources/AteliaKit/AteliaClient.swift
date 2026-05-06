import Foundation

/// Errors thrown by the default `AteliaClient` compatibility surface.
public enum AteliaClientError: Error, Sendable, Equatable {
    /// The conformer does not provide a health snapshot implementation.
    case healthUnavailable
    /// The conformer does not provide a repertoire implementation.
    case repertoireUnavailable
    /// The conformer does not provide repository listing.
    case repositoriesUnavailable
    /// The conformer does not provide the live tool repertoire projection.
    case toolRepertoireUnavailable
    /// The conformer does not provide project status snapshots.
    case projectStatusUnavailable
}

/// Protocol for fetching Atelia health, repertoire, and derived secretary status for a session.
public protocol AteliaClient: Sendable {
    /// Returns the current health snapshot for the given session.
    func health(for session: AteliaSession) async throws -> AteliaHealthResponse
    /// Returns the current repertoire entries for the given session.
    func repertoire(for session: AteliaSession) async throws -> [AteliaRepertoireEntry]
    /// Returns the secretary status derived from the current health snapshot.
    func status(for session: AteliaSession) async throws -> SecretaryStatus
    /// Returns registered repositories visible to the session.
    func repositories(for session: AteliaSession) async throws -> [AteliaRepository]
    /// Returns the beta tool repertoire projection visible to the session.
    func toolRepertoire(for session: AteliaSession) async throws -> [AteliaToolRepertoireEntry]
    /// Returns a compact project status snapshot for a registered repository.
    func projectStatus(
        for session: AteliaSession,
        repositoryId: String
    ) async throws -> AteliaProjectStatus
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

    /// Returns a compatibility error when the conformer does not provide repositories.
    func repositories(for session: AteliaSession) async throws -> [AteliaRepository] {
        _ = session
        throw AteliaClientError.repositoriesUnavailable
    }

    /// Returns a compatibility error when the conformer does not provide tool repertoire.
    func toolRepertoire(for session: AteliaSession) async throws -> [AteliaToolRepertoireEntry] {
        _ = session
        throw AteliaClientError.toolRepertoireUnavailable
    }

    /// Returns a compatibility error when the conformer does not provide project status.
    func projectStatus(
        for session: AteliaSession,
        repositoryId: String
    ) async throws -> AteliaProjectStatus {
        _ = session
        _ = repositoryId
        throw AteliaClientError.projectStatusUnavailable
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

    /// Returns no repositories for the local placeholder client.
    public func repositories(for session: AteliaSession) async throws -> [AteliaRepository] {
        _ = session
        return []
    }

    /// Returns no tool repertoire entries for the local placeholder client.
    public func toolRepertoire(for session: AteliaSession) async throws -> [AteliaToolRepertoireEntry] {
        _ = session
        return []
    }

    /// Returns a compatibility error until a project status fixture is supplied.
    public func projectStatus(
        for session: AteliaSession,
        repositoryId: String
    ) async throws -> AteliaProjectStatus {
        _ = session
        _ = repositoryId
        throw AteliaClientError.projectStatusUnavailable
    }

    /// Returns the legacy local status placeholder for compatibility with older clients.
    public func status(for session: AteliaSession) async throws -> SecretaryStatus {
        _ = session
        return SecretaryStatus(phase: .unknown, message: "Protocol transport is not implemented yet.")
    }

}
