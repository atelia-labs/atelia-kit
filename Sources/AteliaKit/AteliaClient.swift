import Foundation

public protocol AteliaClient: Sendable {
    func status(for session: AteliaSession) async throws -> SecretaryStatus
}

public actor LocalAteliaClient: AteliaClient {
    public init() {}

    public func status(for session: AteliaSession) async throws -> SecretaryStatus {
        _ = session
        return SecretaryStatus(
            phase: .unknown,
            message: "Protocol transport is not implemented yet."
        )
    }
}
