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
    /// The conformer does not provide the package trust index projection.
    case packageTrustIndexUnavailable
    /// The conformer does not provide the package rollback operation.
    case packageRollbackUnavailable
    /// The conformer does not provide package manifest validation.
    case packageValidationUnavailable
    /// The conformer does not provide package install operations.
    case packageInstallUnavailable
    /// The conformer does not provide package update operations.
    case packageUpdateUnavailable
    /// The conformer does not provide package status operations.
    case packageStatusUnavailable
    /// The conformer does not provide package listing operations.
    case packageListUnavailable
    /// The conformer does not provide package disable operations.
    case packageDisableUnavailable
    /// The conformer does not provide package enable operations.
    case packageEnableUnavailable
    /// The conformer does not provide package remove operations.
    case packageRemoveUnavailable
    /// The conformer does not provide package blocklist operations.
    case packageBlocklistUnavailable
    /// The conformer does not provide tool output render operations.
    case toolOutputRenderUnavailable
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
    /// Returns the package trust index entries visible to the session.
    func packageTrustIndex(for session: AteliaSession) async throws -> [AteliaPackageTrustIndexEntry]
    /// Returns the full package trust index envelope, including protocol metadata.
    func packageTrustIndexResponse(for session: AteliaSession) async throws -> AteliaPackageTrustIndexResponse
    /// Returns the rollback response envelope for a package.
    func packageRollbackResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRollbackResponse
    /// Returns the package validation response for a manifest request.
    func packageValidationResponse(
        for session: AteliaSession,
        request: AteliaPackageValidationRequest
    ) async throws -> AteliaPackageValidationResponse
    /// Returns the package install operation envelope.
    func packageInstallResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageInstallResponse
    /// Returns the package install operation record.
    func packageInstall(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageLifecycleRecord
    /// Returns the package update operation envelope.
    func packageUpdateResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageUpdateResponse
    /// Returns the package update operation record.
    func packageUpdate(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageLifecycleRecord
    /// Returns the package status envelope.
    func packageStatusResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageStatusResponse
    /// Returns the package status payload.
    func packageStatus(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageStatus
    /// Returns the package list envelope.
    func packageListResponse(
        for session: AteliaSession,
        request: AteliaPackageListRequest
    ) async throws -> AteliaPackageListResponse
    /// Returns package lifecycle records from the package list envelope.
    func packageList(
        for session: AteliaSession,
        request: AteliaPackageListRequest
    ) async throws -> [AteliaPackageStatus]
    /// Returns the package disable operation envelope.
    func packageDisableResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageDisableResponse
    /// Returns the package disable operation record.
    func packageDisable(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageLifecycleRecord
    /// Returns the package enable operation envelope.
    func packageEnableResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageEnableResponse
    /// Returns the package enable operation record.
    func packageEnable(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageLifecycleRecord
    /// Returns the package remove operation envelope.
    func packageRemoveResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRemoveResponse
    /// Returns the package remove operation record.
    func packageRemove(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageLifecycleRecord
    /// Returns the package blocklist apply operation envelope.
    func packageBlocklistApplyResponse(
        for session: AteliaSession,
        request: AteliaPackageBlocklistRequest
    ) async throws -> AteliaPackageBlocklistApplyResponse
    /// Returns the package blocklist entry returned by an apply operation.
    func packageBlocklistApply(
        for session: AteliaSession,
        request: AteliaPackageBlocklistRequest
    ) async throws -> AteliaPackageBlocklistEntry
    /// Returns the package blocklist list envelope.
    func packageBlocklistListResponse(
        for session: AteliaSession
    ) async throws -> AteliaPackageBlocklistListResponse
    /// Returns current package blocklist entries.
    func packageBlocklistList(
        for session: AteliaSession
    ) async throws -> [AteliaPackageBlocklistEntry]
    /// Returns the tool output render response for a canonical tool result.
    func renderToolOutputResponse(
        for session: AteliaSession,
        request: AteliaToolOutputRenderRequest
    ) async throws -> AteliaToolOutputRenderResponse
}

/// Default compatibility implementations for optional client capabilities.
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

    /// Returns the package trust index entries from the full envelope.
    func packageTrustIndex(for session: AteliaSession) async throws -> [AteliaPackageTrustIndexEntry] {
        try await packageTrustIndexResponse(for: session).packages
    }

    /// Returns a compatibility error when the conformer does not provide the package trust index.
    func packageTrustIndexResponse(for session: AteliaSession) async throws -> AteliaPackageTrustIndexResponse {
        _ = session
        throw AteliaClientError.packageTrustIndexUnavailable
    }

    /// Returns the rollback record from the full response envelope.
    func packageRollback(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRollbackRecord {
        try await packageRollbackResponse(for: session, packageId: packageId).record
    }

    /// Returns a compatibility error when the conformer does not provide package rollback.
    func packageRollbackResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRollbackResponse {
        _ = session
        _ = packageId
        throw AteliaClientError.packageRollbackUnavailable
    }

    /// Returns the package manifest field validation response from the default client.
    func packageValidationResponse(
        for session: AteliaSession,
        request: AteliaPackageValidationRequest
    ) async throws -> AteliaPackageValidationResponse {
        _ = session
        _ = request
        throw AteliaClientError.packageValidationUnavailable
    }

    /// Returns the validated package manifest from a package validation request.
    func packageValidation(
        for session: AteliaSession,
        request: AteliaPackageValidationRequest
    ) async throws -> AteliaPackageManifest {
        try await packageValidationResponse(for: session, request: request).manifest
    }

    /// Returns the package install record from the install response envelope.
    func packageInstall(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageLifecycleRecord {
        try await packageInstallResponse(for: session, request: request).record
    }

    /// Returns a compatibility error when the conformer does not provide package install.
    func packageInstallResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageInstallResponse {
        _ = session
        _ = request
        throw AteliaClientError.packageInstallUnavailable
    }

    /// Returns the package update record from the update response envelope.
    func packageUpdate(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageLifecycleRecord {
        try await packageUpdateResponse(for: session, request: request).record
    }

    /// Returns a compatibility error when the conformer does not provide package update.
    func packageUpdateResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageUpdateResponse {
        _ = session
        _ = request
        throw AteliaClientError.packageUpdateUnavailable
    }

    /// Returns the package status from the package status envelope.
    func packageStatus(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageStatus {
        try await packageStatusResponse(for: session, packageId: packageId).package
    }

    /// Returns a compatibility error when the conformer does not provide package status.
    func packageStatusResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageStatusResponse {
        _ = session
        _ = packageId
        throw AteliaClientError.packageStatusUnavailable
    }

    /// Returns package list entries from the package list envelope.
    func packageList(
        for session: AteliaSession,
        request: AteliaPackageListRequest = .init()
    ) async throws -> [AteliaPackageStatus] {
        try await packageListResponse(for: session, request: request).packages
    }

    /// Returns a compatibility error when the conformer does not provide package list.
    func packageListResponse(
        for session: AteliaSession,
        request: AteliaPackageListRequest
    ) async throws -> AteliaPackageListResponse {
        _ = session
        _ = request
        throw AteliaClientError.packageListUnavailable
    }

    /// Returns the package disable record from the disable response envelope.
    func packageDisable(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageLifecycleRecord {
        try await packageDisableResponse(for: session, packageId: packageId).record
    }

    /// Returns a compatibility error when the conformer does not provide package disable.
    func packageDisableResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageDisableResponse {
        _ = session
        _ = packageId
        throw AteliaClientError.packageDisableUnavailable
    }

    /// Returns the package enable record from the enable response envelope.
    func packageEnable(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageLifecycleRecord {
        try await packageEnableResponse(for: session, packageId: packageId).record
    }

    /// Returns a compatibility error when the conformer does not provide package enable.
    func packageEnableResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageEnableResponse {
        _ = session
        _ = packageId
        throw AteliaClientError.packageEnableUnavailable
    }

    /// Returns the package remove record from the remove response envelope.
    func packageRemove(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageLifecycleRecord {
        try await packageRemoveResponse(for: session, packageId: packageId).record
    }

    /// Returns a compatibility error when the conformer does not provide package remove.
    func packageRemoveResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRemoveResponse {
        _ = session
        _ = packageId
        throw AteliaClientError.packageRemoveUnavailable
    }

    /// Returns the blocklist entry returned by the blocklist apply operation.
    func packageBlocklistApply(
        for session: AteliaSession,
        request: AteliaPackageBlocklistRequest
    ) async throws -> AteliaPackageBlocklistEntry {
        try await packageBlocklistApplyResponse(for: session, request: request).entry
    }

    /// Returns a compatibility error when the conformer does not provide package blocklist apply.
    func packageBlocklistApplyResponse(
        for session: AteliaSession,
        request: AteliaPackageBlocklistRequest
    ) async throws -> AteliaPackageBlocklistApplyResponse {
        _ = session
        _ = request
        throw AteliaClientError.packageBlocklistUnavailable
    }

    /// Returns package blocklist entries from a package blocklist listing response.
    func packageBlocklistList(
        for session: AteliaSession
    ) async throws -> [AteliaPackageBlocklistEntry] {
        try await packageBlocklistListResponse(for: session).entries
    }

    /// Returns a compatibility error when the conformer does not provide package blocklist listing.
    func packageBlocklistListResponse(
        for session: AteliaSession
    ) async throws -> AteliaPackageBlocklistListResponse {
        _ = session
        throw AteliaClientError.packageBlocklistUnavailable
    }

    /// Returns the default tool output render error when the conformer does not provide render.
    func renderToolOutputResponse(
        for session: AteliaSession,
        request: AteliaToolOutputRenderRequest
    ) async throws -> AteliaToolOutputRenderResponse {
        _ = session
        _ = request
        throw AteliaClientError.toolOutputRenderUnavailable
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

    /// Returns an empty package trust index for the local placeholder client.
    public func packageTrustIndexResponse(for session: AteliaSession) async throws -> AteliaPackageTrustIndexResponse {
        _ = session
        return AteliaPackageTrustIndexResponse(
            metadata: AteliaProtocolMetadata(
                protocolVersion: "0.1.0",
                daemonVersion: "0.0.0",
                storageVersion: "0.0.0",
                capabilities: ["package_trust_index.v1"]
            ),
            packages: []
        )
    }

    /// Returns the legacy local status placeholder for compatibility with older clients.
    public func status(for session: AteliaSession) async throws -> SecretaryStatus {
        _ = session
        return SecretaryStatus(phase: .unknown, message: "Protocol transport is not implemented yet.")
    }

}
