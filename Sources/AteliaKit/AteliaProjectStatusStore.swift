import Foundation

/// Actor-backed cache for the latest project status response.
public actor AteliaProjectStatusStore {
    private let client: any AteliaClient
    private let session: AteliaSession
    private let repositoryId: String
    private var latestStatus: AteliaProjectStatus?
    private var nextReloadGeneration = 0
    private var latestAppliedGeneration = 0
    private var clearGeneration = 0

    /// Creates a project status store for a client/session/repository triplet.
    public init(client: some AteliaClient, session: AteliaSession, repositoryId: String) {
        self.client = client
        self.session = session
        self.repositoryId = repositoryId
    }

    /// Reloads the latest project status from the client.
    public func reload() async throws {
        nextReloadGeneration += 1
        let reloadGeneration = nextReloadGeneration
        let status = try await client.projectStatus(for: session, repositoryId: repositoryId)
        guard reloadGeneration > latestAppliedGeneration,
              reloadGeneration > clearGeneration else {
            return
        }
        latestAppliedGeneration = reloadGeneration
        latestStatus = status
    }

    /// Clears any cached project status state.
    public func clear() {
        clearGeneration = nextReloadGeneration
        latestStatus = nil
    }

    /// Returns the latest project status, if one has been loaded.
    public var status: AteliaProjectStatus? {
        latestStatus
    }

    /// Returns the latest protocol metadata, if one has been loaded.
    public var metadata: AteliaProtocolMetadata? {
        latestStatus?.metadata
    }

    /// Returns the latest repository snapshot, if one has been loaded.
    public var repository: AteliaRepository? {
        latestStatus?.repository
    }

    /// Returns the latest jobs in response order.
    public var recentJobs: [AteliaJob] {
        latestStatus?.recentJobs ?? []
    }

    /// Returns the latest policy decisions in response order.
    public var recentPolicyDecisions: [AteliaPolicyDecision] {
        latestStatus?.recentPolicyDecisions ?? []
    }

    /// Returns the latest event cursor, if one has been loaded.
    public var latestCursor: AteliaEventCursor? {
        latestStatus?.latestCursor
    }

    /// Returns the latest daemon status, if one has been loaded.
    public var daemonStatus: AteliaHealthResponse.DaemonStatus? {
        latestStatus?.daemonStatus
    }

    /// Returns the latest storage status, if one has been loaded.
    public var storageStatus: AteliaHealthResponse.StorageStatus? {
        latestStatus?.storageStatus
    }
}
