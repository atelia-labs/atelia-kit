import Foundation
import Testing
@testable import AteliaKit

private enum ProjectLifecycleFixtureError: Error {
    case unconfiguredResponse
}

private actor ProjectLifecycleClientFixture: AteliaClient {
    private var repositoriesResponse: [AteliaRepository]
    private var registerRepositoryResponse: Result<AteliaRegisterRepositoryResponse, any Error>?
    private var submitJobResponse: Result<AteliaSubmitJobResponse, any Error>?
    private var jobResponse: Result<AteliaGetJobResponse, any Error>?
    private var cancelJobResponse: Result<AteliaCancelJobResponse, any Error>?
    private var listEventsResponse: Result<AteliaListEventsResponse, any Error>?
    private var replayEventsResponse: Result<AteliaReplayEventsResponse, any Error>?

    private(set) var registerRequests: [AteliaRegisterRepositoryRequest] = []
    private(set) var submitRequests: [AteliaSubmitJobRequest] = []
    private(set) var requestedJobIDs: [String] = []
    private(set) var cancellationRequests: [(jobId: String, request: AteliaCancelJobRequest)] = []
    private(set) var listEventRequests: [AteliaListEventsRequest] = []
    private(set) var replayEventRequests: [AteliaReplayEventsRequest] = []

    init(
        repositoriesResponse: [AteliaRepository] = [],
        registerRepositoryResponse: Result<AteliaRegisterRepositoryResponse, any Error>? = nil,
        submitJobResponse: Result<AteliaSubmitJobResponse, any Error>? = nil,
        jobResponse: Result<AteliaGetJobResponse, any Error>? = nil,
        cancelJobResponse: Result<AteliaCancelJobResponse, any Error>? = nil,
        listEventsResponse: Result<AteliaListEventsResponse, any Error>? = nil,
        replayEventsResponse: Result<AteliaReplayEventsResponse, any Error>? = nil
    ) {
        self.repositoriesResponse = repositoriesResponse
        self.registerRepositoryResponse = registerRepositoryResponse
        self.submitJobResponse = submitJobResponse
        self.jobResponse = jobResponse
        self.cancelJobResponse = cancelJobResponse
        self.listEventsResponse = listEventsResponse
        self.replayEventsResponse = replayEventsResponse
    }

    func repositories(for session: AteliaSession) async throws -> [AteliaRepository] {
        _ = session
        return repositoriesResponse
    }

    func registerRepositoryResponse(
        for session: AteliaSession,
        request: AteliaRegisterRepositoryRequest
    ) async throws -> AteliaRegisterRepositoryResponse {
        _ = session
        registerRequests.append(request)
        guard let registerRepositoryResponse else {
            throw ProjectLifecycleFixtureError.unconfiguredResponse
        }
        return try registerRepositoryResponse.get()
    }

    func submitJobResponse(
        for session: AteliaSession,
        request: AteliaSubmitJobRequest
    ) async throws -> AteliaSubmitJobResponse {
        _ = session
        submitRequests.append(request)
        guard let submitJobResponse else {
            throw ProjectLifecycleFixtureError.unconfiguredResponse
        }
        return try submitJobResponse.get()
    }

    func jobResponse(
        for session: AteliaSession,
        jobId: String
    ) async throws -> AteliaGetJobResponse {
        _ = session
        requestedJobIDs.append(jobId)
        guard let jobResponse else {
            throw ProjectLifecycleFixtureError.unconfiguredResponse
        }
        return try jobResponse.get()
    }

    func cancelJobResponse(
        for session: AteliaSession,
        jobId: String,
        request: AteliaCancelJobRequest
    ) async throws -> AteliaCancelJobResponse {
        _ = session
        cancellationRequests.append((jobId: jobId, request: request))
        guard let cancelJobResponse else {
            throw ProjectLifecycleFixtureError.unconfiguredResponse
        }
        return try cancelJobResponse.get()
    }

    func listEventsResponse(
        for session: AteliaSession,
        request: AteliaListEventsRequest
    ) async throws -> AteliaListEventsResponse {
        _ = session
        listEventRequests.append(request)
        guard let listEventsResponse else {
            throw ProjectLifecycleFixtureError.unconfiguredResponse
        }
        return try listEventsResponse.get()
    }

    func replayEventsResponse(
        for session: AteliaSession,
        request: AteliaReplayEventsRequest
    ) async throws -> AteliaReplayEventsResponse {
        _ = session
        replayEventRequests.append(request)
        guard let replayEventsResponse else {
            throw ProjectLifecycleFixtureError.unconfiguredResponse
        }
        return try replayEventsResponse.get()
    }

    func registerRequestsValue() -> [AteliaRegisterRepositoryRequest] {
        registerRequests
    }

    func submitRequestsValue() -> [AteliaSubmitJobRequest] {
        submitRequests
    }

    func requestedJobIDsValue() -> [String] {
        requestedJobIDs
    }

    func cancellationRequestsValue() -> [(jobId: String, request: AteliaCancelJobRequest)] {
        cancellationRequests
    }

    func listEventRequestsValue() -> [AteliaListEventsRequest] {
        listEventRequests
    }

    func replayEventRequestsValue() -> [AteliaReplayEventsRequest] {
        replayEventRequests
    }
}

private actor DelayedReplayLifecycleClientFixture: AteliaClient {
    private let listJobEventsResponse: AteliaListEventsResponse
    private var replayContinuation: CheckedContinuation<AteliaReplayEventsResponse, any Error>?
    private var replayStarted = false
    private var replayStartedWaiters: [CheckedContinuation<Void, Never>] = []

    init(listJobEventsResponse: AteliaListEventsResponse) {
        self.listJobEventsResponse = listJobEventsResponse
    }

    func listJobEventsResponse(
        for session: AteliaSession,
        jobId: String,
        request: AteliaListEventsRequest
    ) async throws -> AteliaListEventsResponse {
        _ = session
        _ = jobId
        _ = request
        return listJobEventsResponse
    }

    func replayEventsResponse(
        for session: AteliaSession,
        request: AteliaReplayEventsRequest
    ) async throws -> AteliaReplayEventsResponse {
        _ = session
        _ = request
        replayStarted = true
        replayStartedWaiters.forEach { $0.resume() }
        replayStartedWaiters.removeAll()
        return try await withCheckedThrowingContinuation { continuation in
            replayContinuation = continuation
        }
    }

    func waitForReplayRequest() async {
        if replayStarted { return }
        await withCheckedContinuation { continuation in
            replayStartedWaiters.append(continuation)
        }
    }

    func completeReplay(with response: AteliaReplayEventsResponse) {
        replayContinuation?.resume(returning: response)
        replayContinuation = nil
    }
}

private func lifecycleRepository() -> AteliaRepository {
    AteliaRepository(
        repositoryId: "repo_123",
        displayName: "Atelia Kit",
        rootPath: "/workspace/atelia-kit",
        allowedScope: AteliaPathScope(kind: .repository, roots: ["/workspace/atelia-kit"]),
        trustState: .trusted,
        createdAtUnixMilliseconds: 1710000000000,
        updatedAtUnixMilliseconds: 1710000100000
    )
}

private func lifecycleMetadata(capability: String) -> AteliaProtocolMetadata {
    AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.1.0",
        storageVersion: "0.1.0",
        capabilities: [capability]
    )
}

private func lifecycleJob(status: AteliaJob.Status = .running) -> AteliaJob {
    AteliaJob(
        jobId: "job_123",
        repositoryId: "repo_123",
        requester: .agent(id: "agent_secretary", displayName: "Secretary"),
        kind: "documentation_review",
        goal: "Review protocol references",
        status: status,
        createdAtUnixMilliseconds: 1710000000000,
        startedAtUnixMilliseconds: 1710000001000,
        completedAtUnixMilliseconds: status == .canceled ? 1710000003000 : nil,
        latestEventId: status == .canceled ? "evt_124" : "evt_123",
        cancellation: AteliaJobCancellation(
            state: status == .canceled ? "completed" : "not_requested",
            requestedBy: status == .canceled ? .user(id: "user_123", displayName: "Ada") : nil,
            reason: status == .canceled ? "stop" : nil,
            requestedAtUnixMilliseconds: status == .canceled ? 1710000002000 : nil,
            completedAtUnixMilliseconds: status == .canceled ? 1710000003000 : nil
        )
    )
}

private func lifecycleEvent(eventId: String = "evt_123", sequence: UInt64 = 42) -> AteliaEvent {
    AteliaEvent(
        eventId: eventId,
        sequence: sequence,
        occurredAtUnixMilliseconds: 1710000001000,
        subject: AteliaEventSubject(type: .job, id: "job_123"),
        kind: "job.started",
        severity: .info,
        message: "job started",
        refs: AteliaEventRefs(repositoryId: "repo_123", jobId: "job_123")
    )
}

/// Verifies opening a project reuses an existing repository instead of registering again.
@Test func openReusesExistingRepository() async throws {
    let repository = lifecycleRepository()
    let client = ProjectLifecycleClientFixture(repositoriesResponse: [repository])
    let store = AteliaProjectLifecycleStore(client: client, session: AteliaSession())

    let opened = try await store.open(
        request: AteliaRegisterRepositoryRequest(
            displayName: repository.displayName,
            rootPath: repository.rootPath,
            allowedScope: repository.allowedScope,
            requester: .user(id: "user_123", displayName: "Ada")
        )
    )

    #expect(opened == repository)
    #expect(await client.registerRequestsValue().isEmpty)
    #expect(await store.repository == repository)
}

/// Verifies project lifecycle operations cache repository, job, cancellation, and event state.
@Test func lifecycleStoreCachesRepositoryJobAndEvents() async throws {
    let repository = lifecycleRepository()
    let job = lifecycleJob()
    let canceledJob = lifecycleJob(status: .canceled)
    let event = lifecycleEvent()
    let client = ProjectLifecycleClientFixture(
        repositoriesResponse: [],
        registerRepositoryResponse: .success(AteliaRegisterRepositoryResponse(
            metadata: lifecycleMetadata(capability: "repositories.register.v1"),
            repository: repository,
            policy: AteliaPolicyDecision(
                decisionId: "pol_123",
                outcome: .allowed,
                riskTier: .r1,
                requestedCapability: "filesystem.read",
                reasonCode: "trusted_workspace",
                reason: "Workspace is trusted"
            )
        )),
        submitJobResponse: .success(AteliaSubmitJobResponse(
            metadata: lifecycleMetadata(capability: "jobs.submit.v1"),
            job: job,
            policy: AteliaPolicyDecision(
                decisionId: "pol_123",
                outcome: .audited,
                riskTier: .r1,
                requestedCapability: "filesystem.read",
                reasonCode: "bounded_read",
                reason: "Read-only request is permitted"
            )
        )),
        jobResponse: .success(AteliaGetJobResponse(metadata: lifecycleMetadata(capability: "jobs.get.v1"), job: job)),
        cancelJobResponse: .success(AteliaCancelJobResponse(
            metadata: lifecycleMetadata(capability: "jobs.cancel.v1"),
            job: canceledJob,
            cancellation: canceledJob.cancellation ?? AteliaJobCancellation(state: "completed")
        )),
        listEventsResponse: .success(AteliaListEventsResponse(
            metadata: lifecycleMetadata(capability: "events.list.v1"),
            events: [event],
            nextPageToken: nil
        )),
        replayEventsResponse: .success(AteliaReplayEventsResponse(
            metadata: lifecycleMetadata(capability: "events.replay.v1"),
            events: [event],
            cursor: AteliaEventCursor(sequence: 42, eventId: "evt_123")
        ))
    )
    let store = AteliaProjectLifecycleStore(client: client, session: AteliaSession())

    let opened = try await store.open(
        request: AteliaRegisterRepositoryRequest(
            displayName: repository.displayName,
            rootPath: repository.rootPath,
            allowedScope: repository.allowedScope,
            requester: .user(id: "user_123", displayName: "Ada")
        )
    )
    let submittedJob = try await store.submit(
        request: AteliaSubmitJobRequest(
            repositoryId: repository.repositoryId,
            requester: .agent(id: "agent_secretary", displayName: "Secretary"),
            kind: "documentation_review",
            goal: "Review protocol references"
        )
    )
    let loadedJob = try await store.job(jobId: job.jobId)
    let canceled = try await store.cancel(
        jobId: job.jobId,
        request: AteliaCancelJobRequest(
            requester: .user(id: "user_123", displayName: "Ada"),
            reason: "stop"
        )
    )
    let events = try await store.listJobEvents(
        jobId: job.jobId,
        request: AteliaListEventsRequest(repositoryId: repository.repositoryId)
    )
    let replay = try await store.replayEvents(
        request: AteliaReplayEventsRequest(repositoryId: repository.repositoryId)
    )

    #expect(opened == repository)
    #expect(submittedJob == job)
    #expect(loadedJob == job)
    #expect(canceled == canceledJob)
    #expect(events == [event])
    #expect(replay == [event])
    #expect(await client.registerRequestsValue().count == 1)
    #expect(await client.submitRequestsValue().count == 1)
    #expect(await client.requestedJobIDsValue() == [job.jobId])
    #expect(await client.cancellationRequestsValue().map(\.jobId) == [job.jobId])
    #expect(await client.listEventRequestsValue().compactMap(\.repositoryId) == [repository.repositoryId])
    #expect(await client.replayEventRequestsValue().map(\.repositoryId) == [repository.repositoryId])
    #expect(await store.repository == repository)
    #expect(await store.job == canceledJob)
    #expect(await store.cancellation == canceledJob.cancellation)
    #expect(await store.events == [event])
    #expect((await store.replayResponse)?.cursor == AteliaEventCursor(sequence: 42, eventId: "evt_123"))
    #expect(await store.metadata == lifecycleMetadata(capability: "events.replay.v1"))
    #expect(await store.latestCursor == AteliaEventCursor(sequence: 42, eventId: "evt_123"))
}

/// Verifies an older replay response cannot overwrite newer listed events.
@Test func lifecycleStoreDoesNotOverwriteNewerListEventsWithStaleReplay() async throws {
    let replayEvent = lifecycleEvent(eventId: "evt_replay_old", sequence: 41)
    let listedEvent = lifecycleEvent(eventId: "evt_list_new", sequence: 42)
    let client = DelayedReplayLifecycleClientFixture(
        listJobEventsResponse: AteliaListEventsResponse(
            metadata: lifecycleMetadata(capability: "events.list.v1"),
            events: [listedEvent],
            nextPageToken: nil
        )
    )
    let store = AteliaProjectLifecycleStore(client: client, session: AteliaSession())

    let replayTask = Task {
        try await store.replayEvents(
            request: AteliaReplayEventsRequest(repositoryId: "repo_123")
        )
    }
    await client.waitForReplayRequest()

    let listedEvents = try await store.listJobEvents(
        jobId: "job_123",
        request: AteliaListEventsRequest(repositoryId: "repo_123")
    )
    await client.completeReplay(
        with: AteliaReplayEventsResponse(
            metadata: lifecycleMetadata(capability: "events.replay.v1"),
            events: [replayEvent],
            cursor: AteliaEventCursor(sequence: replayEvent.sequence, eventId: replayEvent.eventId)
        )
    )
    let replayedEvents = try await replayTask.value

    #expect(listedEvents == [listedEvent])
    #expect(replayedEvents == [replayEvent])
    #expect(await store.events == [listedEvent])
    #expect((await store.replayResponse)?.events == [replayEvent])
    #expect(await store.latestCursor == AteliaEventCursor(sequence: replayEvent.sequence, eventId: replayEvent.eventId))
}
