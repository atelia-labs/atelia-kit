import Foundation
import Testing
@testable import AteliaKit

private actor ProjectStatusClientFixture: AteliaClient {
    private let response: AteliaProjectStatus
    private var callCount = 0
    private var requestedSessions: [AteliaSession] = []
    private var requestedRepositoryIDs: [String] = []

    /// Creates a fixture client that returns the supplied project-status response.
    init(response: AteliaProjectStatus) {
        self.response = response
    }

    /// Returns the fixture project-status response and records one client call.
    func projectStatus(
        for session: AteliaSession,
        repositoryId: String
    ) async throws -> AteliaProjectStatus {
        callCount += 1
        requestedSessions.append(session)
        requestedRepositoryIDs.append(repositoryId)
        return response
    }

    /// Returns how many project-status calls reached the fixture.
    func calls() -> Int {
        callCount
    }

    /// Returns the sessions passed to the fixture.
    func sessions() -> [AteliaSession] {
        requestedSessions
    }

    /// Returns the repository identifiers passed to the fixture.
    func repositoryIDs() -> [String] {
        requestedRepositoryIDs
    }
}

private enum FixtureError: Error {
    /// The controllable fixture did not observe the expected number of requests before timeout.
    case timeoutWaitingForRequests(expected: Int, actual: Int)
    /// The controllable fixture failed a captured request.
    case requestFailed
}

private actor ControllableProjectStatusClient: AteliaClient {
    private var continuations: [CheckedContinuation<AteliaProjectStatus, any Error>] = []

    /// Suspends until the test explicitly responds to the captured request.
    func projectStatus(
        for session: AteliaSession,
        repositoryId: String
    ) async throws -> AteliaProjectStatus {
        _ = session
        _ = repositoryId
        return try await withCheckedThrowingContinuation { continuation in
            continuations.append(continuation)
        }
    }

    /// Waits until the expected number of requests have reached the fixture.
    func waitForRequests(_ count: Int, timeout: Duration = .seconds(2)) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while continuations.count < count {
            guard clock.now < deadline else {
                throw FixtureError.timeoutWaitingForRequests(
                    expected: count,
                    actual: continuations.count
                )
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    /// Resumes one captured request with the supplied project-status response.
    func respond(to index: Int, with response: AteliaProjectStatus) {
        continuations[index].resume(returning: response)
    }

    /// Resumes one captured request by throwing the supplied error.
    func fail(to index: Int, with error: any Error) {
        continuations[index].resume(throwing: error)
    }
}

/// Shared project-status response used by store behavior tests.
private let projectStatusFixtureResponse = AteliaProjectStatus(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["project_status.v1"]
    ),
    repository: AteliaRepository(
        repositoryId: "repo_123",
        displayName: "Atelia Kit",
        rootPath: "/workspace/atelia-kit",
        allowedScope: AteliaPathScope(
            kind: .repository,
            roots: ["/workspace/atelia-kit"],
            includePatterns: ["Sources/**"],
            excludePatterns: [".build/**"]
        ),
        trustState: .trusted,
        createdAtUnixMilliseconds: 1710000000000,
        updatedAtUnixMilliseconds: 1710000100000
    ),
    recentJobs: [
        AteliaJob(
            jobId: "job_123",
            repositoryId: "repo_123",
            requester: .agent(id: "agent_secretary", displayName: "Secretary"),
            kind: "tool",
            goal: "Read package manifest",
            status: .running,
            policySummary: AteliaPolicySummary(
                decisionId: "pol_123",
                outcome: .audited,
                riskTier: .r1,
                reasonCode: "bounded_read"
            ),
            createdAtUnixMilliseconds: 1710000000000,
            startedAtUnixMilliseconds: 1710000001000,
            latestEventId: "evt_123",
            cancellation: AteliaJobCancellation(state: "none")
        ),
        AteliaJob(
            jobId: "job_456",
            repositoryId: "repo_123",
            requester: .user(id: "user_123", displayName: "Aki"),
            kind: "review",
            goal: "Check protocol shapes",
            status: .queued,
            createdAtUnixMilliseconds: 1710000002000
        )
    ],
    recentPolicyDecisions: [
        AteliaPolicyDecision(
            decisionId: "pol_123",
            outcome: .allowed,
            riskTier: .r1,
            requestedCapability: "filesystem.read",
            reasonCode: "bounded_read",
            reason: "Read-only access is sufficient",
            approvalRequestRef: nil,
            auditRef: "aud_123"
        ),
        AteliaPolicyDecision(
            decisionId: "pol_456",
            outcome: .needsApproval,
            riskTier: .r3,
            requestedCapability: "filesystem.write",
            reasonCode: "approval_required",
            reason: "Writes need explicit approval",
            approvalRequestRef: "approval_456",
            auditRef: nil
        )
    ],
    latestCursor: AteliaEventCursor(sequence: 17, eventId: "evt_123"),
    daemonStatus: .ready,
    storageStatus: .migrating
)

/// Shared project-status response used by race-ordering tests.
private let olderProjectStatusFixtureResponse = AteliaProjectStatus(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["project_status.v1"]
    ),
    repository: AteliaRepository(
        repositoryId: "repo_123",
        displayName: "Atelia Kit",
        rootPath: "/workspace/atelia-kit",
        allowedScope: AteliaPathScope(kind: .repository),
        trustState: .trusted,
        createdAtUnixMilliseconds: 1710000000000,
        updatedAtUnixMilliseconds: 1710000100000
    ),
    recentJobs: [
        AteliaJob(
            jobId: "job_old",
            repositoryId: "repo_123",
            requester: .system(id: "system"),
            kind: "sync",
            goal: "Fetch older snapshot",
            status: .running,
            createdAtUnixMilliseconds: 1710000000000
        )
    ],
    recentPolicyDecisions: [],
    latestCursor: nil,
    daemonStatus: .starting,
    storageStatus: .ready
)

/// Shared project-status response used by clear-in-flight tests.
private func projectStatusResponse(jobId: String) -> AteliaProjectStatus {
    AteliaProjectStatus(
        metadata: AteliaProtocolMetadata(
            protocolVersion: "1.0.0",
            daemonVersion: "0.2.0",
            storageVersion: "0.2.0",
            capabilities: ["project_status.v1"]
        ),
        repository: AteliaRepository(
            repositoryId: "repo_123",
            displayName: "Atelia Kit",
            rootPath: "/workspace/atelia-kit",
            allowedScope: AteliaPathScope(kind: .repository),
            trustState: .trusted,
            createdAtUnixMilliseconds: 1710000000000,
            updatedAtUnixMilliseconds: 1710000100000
        ),
        recentJobs: [
            AteliaJob(
                jobId: jobId,
                repositoryId: "repo_123",
                requester: .system(id: "system"),
                kind: "sync",
                goal: "Pending update",
                status: .running,
                createdAtUnixMilliseconds: 1710000000000
            )
        ],
        recentPolicyDecisions: [],
        latestCursor: nil,
        daemonStatus: .running,
        storageStatus: .ready
    )
}

/// Verifies reload fetches the project status once and keeps the response payload.
@Test func reloadPopulatesStatusAndDerivedProperties() async throws {
    let client = ProjectStatusClientFixture(response: projectStatusFixtureResponse)
    let session = AteliaSession(id: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!)
    let store = AteliaProjectStatusStore(
        client: client,
        session: session,
        repositoryId: "repo_123"
    )

    try await store.reload()

    #expect(await client.calls() == 1)
    #expect(await client.sessions() == [session])
    #expect(await client.repositoryIDs() == ["repo_123"])
    #expect(await store.status == projectStatusFixtureResponse)
    #expect(await store.metadata == projectStatusFixtureResponse.metadata)
    #expect(await store.repository == projectStatusFixtureResponse.repository)
    #expect(await store.recentJobs == projectStatusFixtureResponse.recentJobs)
    #expect(await store.recentPolicyDecisions == projectStatusFixtureResponse.recentPolicyDecisions)
    #expect(await store.latestCursor == projectStatusFixtureResponse.latestCursor)
    #expect(await store.daemonStatus == Optional(projectStatusFixtureResponse.daemonStatus))
    #expect(await store.storageStatus == Optional(projectStatusFixtureResponse.storageStatus))
}

/// Verifies derived properties preserve response order and surface loaded values.
@Test func lookupDerivedPropertiesPreserveResponseOrder() async throws {
    let client = ProjectStatusClientFixture(response: projectStatusFixtureResponse)
    let store = AteliaProjectStatusStore(
        client: client,
        session: AteliaSession(),
        repositoryId: "repo_123"
    )

    try await store.reload()

    #expect(await store.recentJobs == projectStatusFixtureResponse.recentJobs)
    #expect(await store.recentPolicyDecisions == projectStatusFixtureResponse.recentPolicyDecisions)
    #expect(await store.repository == projectStatusFixtureResponse.repository)
    #expect(await store.metadata == projectStatusFixtureResponse.metadata)
}

/// Verifies clear removes the cached status and derived projections.
@Test func projectStatusClearResetsCachedState() async throws {
    let client = ProjectStatusClientFixture(response: projectStatusFixtureResponse)
    let store = AteliaProjectStatusStore(
        client: client,
        session: AteliaSession(),
        repositoryId: "repo_123"
    )

    try await store.reload()
    await store.clear()

    #expect(await store.status == nil)
    #expect(await store.metadata == nil)
    #expect(await store.repository == nil)
    #expect(await store.recentJobs.isEmpty)
    #expect(await store.recentPolicyDecisions.isEmpty)
    #expect(await store.latestCursor == nil)
    #expect(await store.daemonStatus == nil)
    #expect(await store.storageStatus == nil)
}

/// Verifies an older in-flight reload cannot overwrite a newer completed reload.
@Test func projectStatusStaleReloadDoesNotOverwriteNewerReload() async throws {
    let client = ControllableProjectStatusClient()
    let store = AteliaProjectStatusStore(
        client: client,
        session: AteliaSession(),
        repositoryId: "repo_123"
    )

    let olderReload: Task<Void, Error> = Task {
        try await store.reload()
    }
    try await client.waitForRequests(1)

    let newerReload: Task<Void, Error> = Task {
        try await store.reload()
    }
    try await client.waitForRequests(2)

    let newerResponse = projectStatusResponse(jobId: "job_newer")
    await client.respond(to: 1, with: newerResponse)
    try await newerReload.value
    await client.respond(to: 0, with: olderProjectStatusFixtureResponse)
    try await olderReload.value

    #expect(await store.status == newerResponse)
    #expect(await store.recentJobs == newerResponse.recentJobs)
    #expect(await store.daemonStatus == Optional(AteliaHealthResponse.DaemonStatus.running))
}

/// Verifies a newer failed reload does not invalidate an older successful reload.
@Test func projectStatusFailedNewerReloadDoesNotDiscardOlderSuccessfulReload() async throws {
    let client = ControllableProjectStatusClient()
    let store = AteliaProjectStatusStore(
        client: client,
        session: AteliaSession(),
        repositoryId: "repo_123"
    )
    let olderResponse = projectStatusResponse(jobId: "job_older")

    let olderReload: Task<Void, Error> = Task {
        try await store.reload()
    }
    try await client.waitForRequests(1)

    let newerReload: Task<Void, Error> = Task {
        try await store.reload()
    }
    try await client.waitForRequests(2)

    await client.fail(to: 1, with: FixtureError.requestFailed)
    await #expect(throws: FixtureError.self) {
        try await newerReload.value
    }
    await client.respond(to: 0, with: olderResponse)
    try await olderReload.value

    #expect(await store.status == olderResponse)
    #expect(await store.recentJobs == olderResponse.recentJobs)
    #expect(await store.daemonStatus == Optional(AteliaHealthResponse.DaemonStatus.running))
}

/// Verifies clear prevents an older in-flight reload from repopulating the cache.
@Test func projectStatusClearInvalidatesInFlightReload() async throws {
    let client = ControllableProjectStatusClient()
    let store = AteliaProjectStatusStore(
        client: client,
        session: AteliaSession(),
        repositoryId: "repo_123"
    )
    let response = projectStatusResponse(jobId: "job_pending")

    let reload: Task<Void, Error> = Task {
        try await store.reload()
    }
    try await client.waitForRequests(1)

    await store.clear()
    await client.respond(to: 0, with: response)
    try await reload.value

    #expect(await store.status == nil)
    #expect(await store.metadata == nil)
    #expect(await store.repository == nil)
    #expect(await store.recentJobs.isEmpty)
    #expect(await store.recentPolicyDecisions.isEmpty)
    #expect(await store.latestCursor == nil)
    #expect(await store.daemonStatus == nil)
    #expect(await store.storageStatus == nil)
}
