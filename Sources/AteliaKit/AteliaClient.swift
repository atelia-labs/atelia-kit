import Foundation

public protocol AteliaClient: Sendable {
    func health(for session: AteliaSession) async throws -> AteliaHealthResponse
    func repertoire(for session: AteliaSession) async throws -> [AteliaRepertoireEntry]
    func status(for session: AteliaSession) async throws -> SecretaryStatus
}

public extension AteliaClient {
    func status(for session: AteliaSession) async throws -> SecretaryStatus {
        let health = try await health(for: session)
        return health.secretaryStatus
    }
}

public actor LocalAteliaClient: AteliaClient {
    public init() {}

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

    public func repertoire(for session: AteliaSession) async throws -> [AteliaRepertoireEntry] {
        _ = session
        return []
    }

    public func status(for session: AteliaSession) async throws -> SecretaryStatus {
        _ = session
        return SecretaryStatus(
            phase: .unknown,
            message: "Protocol transport is not implemented yet."
        )
    }
}
