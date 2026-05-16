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
    private(set) var listJobEventRequests: [(jobId: String, request: AteliaListEventsRequest)] = []
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

    func listJobEventsResponse(
        for session: AteliaSession,
        jobId: String,
        request: AteliaListEventsRequest
    ) async throws -> AteliaListEventsResponse {
        _ = session
        listJobEventRequests.append((jobId: jobId, request: request))
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

    func listJobEventRequestsValue() -> [(jobId: String, request: AteliaListEventsRequest)] {
        listJobEventRequests
    }

    func replayEventRequestsValue() -> [AteliaReplayEventsRequest] {
        replayEventRequests
    }

    func setRegisterRepositoryResponse(_ response: Result<AteliaRegisterRepositoryResponse, any Error>) {
        registerRepositoryResponse = response
    }

    func setReplayEventsResponse(_ response: Result<AteliaReplayEventsResponse, any Error>) {
        replayEventsResponse = response
    }
}

private actor DelayedReplayLifecycleClientFixture: AteliaClient {
    private let listJobEventsResponse: AteliaListEventsResponse
    private(set) var listJobEventRequests: [(jobId: String, request: AteliaListEventsRequest)] = []
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
        listJobEventRequests.append((jobId: jobId, request: request))
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

    func listJobEventRequestsValue() -> [(jobId: String, request: AteliaListEventsRequest)] {
        listJobEventRequests
    }
}

private actor DelayedRepositoryOpenLifecycleClientFixture: AteliaClient {
    private let registerRepositoryResponseValue: AteliaRegisterRepositoryResponse
    private let submitJobResponseValue: AteliaSubmitJobResponse
    private let cancelJobResponseValue: AteliaCancelJobResponse
    private let listJobEventsResponseValue: AteliaListEventsResponse
    private let replayEventsResponseValue: AteliaReplayEventsResponse
    private let repositoriesValue: [AteliaRepository]
    private var registerContinuation: CheckedContinuation<AteliaRegisterRepositoryResponse, Never>?
    private var registerStarted = false
    private var registerStartedWaiters: [CheckedContinuation<Void, Never>] = []

    init(
        repositoriesResponse: [AteliaRepository] = [],
        registerRepositoryResponse: AteliaRegisterRepositoryResponse,
        submitJobResponse: AteliaSubmitJobResponse,
        cancelJobResponse: AteliaCancelJobResponse,
        listJobEventsResponse: AteliaListEventsResponse,
        replayEventsResponse: AteliaReplayEventsResponse
    ) {
        repositoriesValue = repositoriesResponse
        registerRepositoryResponseValue = registerRepositoryResponse
        submitJobResponseValue = submitJobResponse
        cancelJobResponseValue = cancelJobResponse
        listJobEventsResponseValue = listJobEventsResponse
        replayEventsResponseValue = replayEventsResponse
    }

    func repositories(for session: AteliaSession) async throws -> [AteliaRepository] {
        _ = session
        return repositoriesValue
    }

    func registerRepositoryResponse(
        for session: AteliaSession,
        request: AteliaRegisterRepositoryRequest
    ) async throws -> AteliaRegisterRepositoryResponse {
        _ = session
        _ = request
        registerStarted = true
        registerStartedWaiters.forEach { $0.resume() }
        registerStartedWaiters.removeAll()
        return await withCheckedContinuation { continuation in
            registerContinuation = continuation
        }
    }

    func submitJobResponse(
        for session: AteliaSession,
        request: AteliaSubmitJobRequest
    ) async throws -> AteliaSubmitJobResponse {
        _ = session
        _ = request
        return submitJobResponseValue
    }

    func cancelJobResponse(
        for session: AteliaSession,
        jobId: String,
        request: AteliaCancelJobRequest
    ) async throws -> AteliaCancelJobResponse {
        _ = session
        _ = jobId
        _ = request
        return cancelJobResponseValue
    }

    func listJobEventsResponse(
        for session: AteliaSession,
        jobId: String,
        request: AteliaListEventsRequest
    ) async throws -> AteliaListEventsResponse {
        _ = session
        _ = jobId
        _ = request
        return listJobEventsResponseValue
    }

    func replayEventsResponse(
        for session: AteliaSession,
        request: AteliaReplayEventsRequest
    ) async throws -> AteliaReplayEventsResponse {
        _ = session
        _ = request
        return replayEventsResponseValue
    }

    func waitForRegisterRequest() async {
        if registerStarted { return }
        await withCheckedContinuation { continuation in
            registerStartedWaiters.append(continuation)
        }
    }

    func completeRegister() {
        registerContinuation?.resume(returning: registerRepositoryResponseValue)
        registerContinuation = nil
    }
}

private func lifecycleRepository(
    repositoryId: String = "repo_123",
    displayName: String = "Atelia Kit",
    rootPath: String = "/workspace/atelia-kit"
) -> AteliaRepository {
    AteliaRepository(
        repositoryId: repositoryId,
        displayName: displayName,
        rootPath: rootPath,
        allowedScope: AteliaPathScope(kind: .repository, roots: [rootPath]),
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

private func lifecycleJob(
    status: AteliaJob.Status = .running,
    repositoryId: String = "repo_123"
) -> AteliaJob {
    AteliaJob(
        jobId: "job_123",
        repositoryId: repositoryId,
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

private func lifecycleEvent(
    eventId: String = "evt_123",
    sequence: UInt64 = 42,
    repositoryId: String = "repo_123"
) -> AteliaEvent {
    AteliaEvent(
        eventId: eventId,
        sequence: sequence,
        occurredAtUnixMilliseconds: 1710000001000,
        subject: AteliaEventSubject(type: .job, id: "job_123"),
        kind: "job.started",
        severity: .info,
        message: "job started",
        refs: AteliaEventRefs(repositoryId: repositoryId, jobId: "job_123")
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

/// Verifies a delayed first open does not overwrite newer job-scoped state from a different repository.
@Test func lifecycleStoreDoesNotApplyStaleOpenAfterDifferentRepositoryJobActivity() async throws {
    let firstRepository = lifecycleRepository(
        repositoryId: "repo_123",
        displayName: "Atelia Kit",
        rootPath: "/workspace/atelia-kit"
    )
    let delayedRepository = lifecycleRepository(
        repositoryId: "repo_456",
        displayName: "Delayed Repo",
        rootPath: "/workspace/atelia-delayed"
    )
    let job = lifecycleJob(repositoryId: firstRepository.repositoryId)
    let listedEvent = lifecycleEvent(
        eventId: "evt_list",
        sequence: 42,
        repositoryId: firstRepository.repositoryId
    )
    let replayedEvent = lifecycleEvent(
        eventId: "evt_replay",
        sequence: 43,
        repositoryId: firstRepository.repositoryId
    )
    let replayCursor = AteliaEventRouteCursor.afterSequence(replayedEvent.sequence)

    let client = DelayedRepositoryOpenLifecycleClientFixture(
        repositoriesResponse: [],
        registerRepositoryResponse: AteliaRegisterRepositoryResponse(
            metadata: lifecycleMetadata(capability: "repositories.register.v1"),
            repository: delayedRepository,
            policy: AteliaPolicyDecision(
                decisionId: "pol_456",
                outcome: .allowed,
                riskTier: .r1,
                requestedCapability: "filesystem.read",
                reasonCode: "trusted_workspace",
                reason: "Workspace is trusted"
            )
        ),
        submitJobResponse: AteliaSubmitJobResponse(
            metadata: lifecycleMetadata(capability: "jobs.submit.v1"),
            job: job,
            policy: AteliaPolicyDecision(
                decisionId: "pol_124",
                outcome: .audited,
                riskTier: .r1,
                requestedCapability: "filesystem.read",
                reasonCode: "bounded_read",
                reason: "Read-only request is permitted"
            )
        ),
        cancelJobResponse: AteliaCancelJobResponse(
            metadata: lifecycleMetadata(capability: "jobs.cancel.v1"),
            job: lifecycleJob(status: .canceled, repositoryId: firstRepository.repositoryId),
            cancellation: AteliaJobCancellation(state: "completed")
        ),
        listJobEventsResponse: AteliaListEventsResponse(
            metadata: lifecycleMetadata(capability: "events.list.v1"),
            events: [listedEvent],
            nextPageToken: nil
        ),
        replayEventsResponse: AteliaReplayEventsResponse(
            metadata: lifecycleMetadata(capability: "events.replay.v1"),
            events: [replayedEvent],
            cursor: replayCursor
        )
    )
    let store = AteliaProjectLifecycleStore(client: client, session: AteliaSession())

    let openTask = Task {
        try await store.open(request: AteliaRegisterRepositoryRequest(
            displayName: delayedRepository.displayName,
            rootPath: delayedRepository.rootPath,
            allowedScope: delayedRepository.allowedScope,
            requester: .user(id: "user_123", displayName: "Ada")
        ))
    }
    await client.waitForRegisterRequest()

    _ = try await store.submit(
        request: AteliaSubmitJobRequest(
            repositoryId: firstRepository.repositoryId,
            requester: .agent(id: "agent_secretary", displayName: "Secretary"),
            kind: "documentation_review",
            goal: "Review protocol references"
        )
    )
    _ = try await store.cancel(
        jobId: job.jobId,
        request: AteliaCancelJobRequest(
            requester: .user(id: "user_123", displayName: "Ada"),
            reason: "stop"
        )
    )
    _ = try await store.listJobEvents(
        jobId: job.jobId,
        request: AteliaListEventsRequest(repositoryId: firstRepository.repositoryId)
    )
    _ = try await store.replayEvents(
        request: AteliaReplayEventsRequest(repositoryId: firstRepository.repositoryId)
    )

    await client.completeRegister()
    _ = try await openTask.value

    let snapshot = await store.snapshot()
    #expect(snapshot.repository == nil)
    #expect(snapshot.job?.repositoryId == firstRepository.repositoryId)
    #expect(snapshot.events == [replayedEvent])
    #expect(snapshot.replayResponse?.events == [replayedEvent])
    #expect(snapshot.latestCursor == replayCursor)
    #expect(snapshot.metadata == lifecycleMetadata(capability: "events.replay.v1"))
}

/// Verifies submit/load job operations from another repository clear cached repository state.
@Test func lifecycleStoreClearsRepositoryStateWhenJobComesFromDifferentRepository() async throws {
    let cachedRepository = lifecycleRepository(
        repositoryId: "repo_123",
        displayName: "Atelia Kit",
        rootPath: "/workspace/atelia-kit"
    )
    let nextRepositoryId = "repo_456"
    let job = lifecycleJob(repositoryId: nextRepositoryId)
    let replayCursor = AteliaEventRouteCursor.afterSequence(43)
    let event = lifecycleEvent(
        eventId: "evt_123",
        sequence: 43,
        repositoryId: nextRepositoryId
    )

    let client = ProjectLifecycleClientFixture(
        registerRepositoryResponse: .success(AteliaRegisterRepositoryResponse(
            metadata: lifecycleMetadata(capability: "repositories.register.v1"),
            repository: cachedRepository,
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
                decisionId: "pol_124",
                outcome: .audited,
                riskTier: .r1,
                requestedCapability: "filesystem.read",
                reasonCode: "bounded_read",
                reason: "Read-only request is permitted"
            )
        )),
        jobResponse: .success(AteliaGetJobResponse(
            metadata: lifecycleMetadata(capability: "jobs.get.v1"),
            job: job
        )),
        listEventsResponse: .success(AteliaListEventsResponse(
            metadata: lifecycleMetadata(capability: "events.list.v1"),
            events: [event],
            nextPageToken: nil
        )),
        replayEventsResponse: .success(AteliaReplayEventsResponse(
            metadata: lifecycleMetadata(capability: "events.replay.v1"),
            events: [event],
            cursor: .afterSequence(event.sequence)
        ))
    )
    let store = AteliaProjectLifecycleStore(client: client, session: AteliaSession())

    _ = try await store.open(
        request: AteliaRegisterRepositoryRequest(
            displayName: cachedRepository.displayName,
            rootPath: cachedRepository.rootPath,
            allowedScope: cachedRepository.allowedScope,
            requester: .user(id: "user_123", displayName: "Ada")
        )
    )

    _ = try await store.submit(
        request: AteliaSubmitJobRequest(
            repositoryId: job.repositoryId,
            requester: .agent(id: "agent_secretary", displayName: "Secretary"),
            kind: "documentation_review",
            goal: "Review protocol references"
        )
    )
    _ = try await store.job(jobId: job.jobId)

    _ = try await store.listJobEvents(
        jobId: job.jobId,
        request: AteliaListEventsRequest(repositoryId: job.repositoryId)
    )
    _ = try await store.replayEvents(
        request: AteliaReplayEventsRequest(repositoryId: job.repositoryId)
    )

    let snapshot = await store.snapshot()
    #expect(snapshot.repository == nil)
    #expect(snapshot.job?.repositoryId == nextRepositoryId)
    #expect(snapshot.events == [event])
    #expect(snapshot.replayResponse?.events == [event])
    #expect(snapshot.latestCursor == replayCursor)
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
            cursor: .afterSequence(42)
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
    #expect(await client.listEventRequestsValue().isEmpty)
    #expect(await client.listJobEventRequestsValue().map(\.jobId) == [job.jobId])
    #expect(await client.listJobEventRequestsValue().compactMap(\.request.repositoryId) == [repository.repositoryId])
    #expect(await client.replayEventRequestsValue().map(\.repositoryId) == [repository.repositoryId])
    #expect(await store.repository == repository)
    #expect(await store.job == canceledJob)
    #expect(await store.cancellation == canceledJob.cancellation)
    #expect(await store.events == [event])
    #expect((await store.replayResponse)?.cursor == .afterSequence(42))
    #expect(await store.metadata == lifecycleMetadata(capability: "events.replay.v1"))
    #expect(await store.latestCursor == .afterSequence(42))
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
            cursor: .afterEventId(replayEvent.eventId)
        )
    )
    let replayedEvents = try await replayTask.value

    #expect(listedEvents == [listedEvent])
    #expect(replayedEvents == [replayEvent])
    #expect(await store.events == [listedEvent])
    #expect((await store.replayResponse)?.events == [replayEvent])
    #expect(await store.latestCursor == .afterEventId(replayEvent.eventId))
    #expect(await client.listJobEventRequestsValue().map(\.jobId) == ["job_123"])
    #expect(await client.listJobEventRequestsValue().compactMap(\.request.repositoryId) == ["repo_123"])
}

/// Verifies a newer replay response with no cursor clears an older replay cursor.
@Test func lifecycleStoreClearsCursorWhenNewerReplayOmitsCursor() async throws {
    let firstEvent = lifecycleEvent(eventId: "evt_123", sequence: 42)
    let secondEvent = lifecycleEvent(eventId: "evt_124", sequence: 43)
    let client = ProjectLifecycleClientFixture(
        replayEventsResponse: .success(AteliaReplayEventsResponse(
            metadata: lifecycleMetadata(capability: "events.replay.v1"),
            events: [firstEvent],
            cursor: .afterSequence(firstEvent.sequence)
        ))
    )
    let store = AteliaProjectLifecycleStore(client: client, session: AteliaSession())

    _ = try await store.replayEvents(request: AteliaReplayEventsRequest(repositoryId: "repo_123"))
    await client.setReplayEventsResponse(.success(AteliaReplayEventsResponse(
        metadata: lifecycleMetadata(capability: "events.replay.v1"),
        events: [secondEvent],
        cursor: nil
    )))
    _ = try await store.replayEvents(request: AteliaReplayEventsRequest(repositoryId: "repo_123"))

    #expect(await store.events == [secondEvent])
    #expect((await store.replayResponse)?.events == [secondEvent])
    #expect(await store.latestCursor == nil)
}

/// Verifies switching repository identity clears cached job-scoped state.
@Test func lifecycleStoreResetsJobScopedStateWhenRepositoryChanges() async throws {
    let firstRepository = lifecycleRepository()
    let secondRepository = lifecycleRepository(
        repositoryId: "repo_456",
        displayName: "Atelia App",
        rootPath: "/workspace/atelia-app"
    )
    let job = lifecycleJob()
    let event = lifecycleEvent()
    let client = ProjectLifecycleClientFixture(
        registerRepositoryResponse: .success(AteliaRegisterRepositoryResponse(
            metadata: lifecycleMetadata(capability: "repositories.register.v1"),
            repository: firstRepository,
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
                decisionId: "pol_124",
                outcome: .audited,
                riskTier: .r1,
                requestedCapability: "filesystem.read",
                reasonCode: "bounded_read",
                reason: "Read-only request is permitted"
            )
        )),
        cancelJobResponse: .success(AteliaCancelJobResponse(
            metadata: lifecycleMetadata(capability: "jobs.cancel.v1"),
            job: lifecycleJob(status: .canceled),
            cancellation: AteliaJobCancellation(state: "completed")
        )),
        listEventsResponse: .success(AteliaListEventsResponse(
            metadata: lifecycleMetadata(capability: "events.list.v1"),
            events: [event],
            nextPageToken: nil
        )),
        replayEventsResponse: .success(AteliaReplayEventsResponse(
            metadata: lifecycleMetadata(capability: "events.replay.v1"),
            events: [event],
            cursor: .afterSequence(event.sequence)
        ))
    )
    let store = AteliaProjectLifecycleStore(client: client, session: AteliaSession())

    _ = try await store.open(request: AteliaRegisterRepositoryRequest(
        displayName: firstRepository.displayName,
        rootPath: firstRepository.rootPath,
        allowedScope: firstRepository.allowedScope,
        requester: .user(id: "user_123", displayName: "Ada")
    ))
    _ = try await store.submit(request: AteliaSubmitJobRequest(
        repositoryId: firstRepository.repositoryId,
        requester: .agent(id: "agent_secretary", displayName: "Secretary"),
        kind: "documentation_review",
        goal: "Review protocol references"
    ))
    _ = try await store.cancel(
        jobId: job.jobId,
        request: AteliaCancelJobRequest(
            requester: .user(id: "user_123", displayName: "Ada"),
            reason: "stop"
        )
    )
    _ = try await store.listJobEvents(
        jobId: job.jobId,
        request: AteliaListEventsRequest(repositoryId: firstRepository.repositoryId)
    )
    _ = try await store.replayEvents(
        request: AteliaReplayEventsRequest(repositoryId: firstRepository.repositoryId)
    )

    await client.setRegisterRepositoryResponse(.success(AteliaRegisterRepositoryResponse(
        metadata: lifecycleMetadata(capability: "repositories.register.v1"),
        repository: secondRepository,
        policy: AteliaPolicyDecision(
            decisionId: "pol_125",
            outcome: .allowed,
            riskTier: .r1,
            requestedCapability: "filesystem.read",
            reasonCode: "trusted_workspace",
            reason: "Workspace is trusted"
        )
    )))
    _ = try await store.open(request: AteliaRegisterRepositoryRequest(
        displayName: secondRepository.displayName,
        rootPath: secondRepository.rootPath,
        allowedScope: secondRepository.allowedScope,
        requester: .user(id: "user_123", displayName: "Ada")
    ))

    let snapshot = await store.snapshot()
    #expect(snapshot.repository == secondRepository)
    #expect(snapshot.job == nil)
    #expect(snapshot.cancellation == nil)
    #expect(snapshot.events.isEmpty)
    #expect(snapshot.replayResponse == nil)
    #expect(snapshot.latestCursor == nil)
}

/// Verifies an older repository reset cannot clear newer job-scoped cache fields.
@Test func lifecycleStoreDoesNotClearNewerJobScopedStateWhenStaleOpenResumes() async throws {
    let repository = lifecycleRepository()
    let job = lifecycleJob()
    let canceledJob = lifecycleJob(status: .canceled)
    let listedEvent = lifecycleEvent(eventId: "evt_list_new", sequence: 42)
    let replayedEvent = lifecycleEvent(eventId: "evt_replay_new", sequence: 43)
    let replayCursor = AteliaEventRouteCursor.afterSequence(replayedEvent.sequence)
    let client = DelayedRepositoryOpenLifecycleClientFixture(
        registerRepositoryResponse: AteliaRegisterRepositoryResponse(
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
        ),
        submitJobResponse: AteliaSubmitJobResponse(
            metadata: lifecycleMetadata(capability: "jobs.submit.v1"),
            job: job,
            policy: AteliaPolicyDecision(
                decisionId: "pol_124",
                outcome: .audited,
                riskTier: .r1,
                requestedCapability: "filesystem.read",
                reasonCode: "bounded_read",
                reason: "Read-only request is permitted"
            )
        ),
        cancelJobResponse: AteliaCancelJobResponse(
            metadata: lifecycleMetadata(capability: "jobs.cancel.v1"),
            job: canceledJob,
            cancellation: canceledJob.cancellation ?? AteliaJobCancellation(state: "completed")
        ),
        listJobEventsResponse: AteliaListEventsResponse(
            metadata: lifecycleMetadata(capability: "events.list.v1"),
            events: [listedEvent],
            nextPageToken: nil
        ),
        replayEventsResponse: AteliaReplayEventsResponse(
            metadata: lifecycleMetadata(capability: "events.replay.v1"),
            events: [replayedEvent],
            cursor: replayCursor
        )
    )
    let store = AteliaProjectLifecycleStore(client: client, session: AteliaSession())

    let openTask = Task {
        try await store.open(request: AteliaRegisterRepositoryRequest(
            displayName: repository.displayName,
            rootPath: repository.rootPath,
            allowedScope: repository.allowedScope,
            requester: .user(id: "user_123", displayName: "Ada")
        ))
    }
    await client.waitForRegisterRequest()

    _ = try await store.submit(request: AteliaSubmitJobRequest(
        repositoryId: repository.repositoryId,
        requester: .agent(id: "agent_secretary", displayName: "Secretary"),
        kind: "documentation_review",
        goal: "Review protocol references"
    ))
    _ = try await store.cancel(
        jobId: job.jobId,
        request: AteliaCancelJobRequest(
            requester: .user(id: "user_123", displayName: "Ada"),
            reason: "stop"
        )
    )
    _ = try await store.listJobEvents(
        jobId: job.jobId,
        request: AteliaListEventsRequest(repositoryId: repository.repositoryId)
    )
    _ = try await store.replayEvents(
        request: AteliaReplayEventsRequest(repositoryId: repository.repositoryId)
    )

    await client.completeRegister()
    let opened = try await openTask.value

    let snapshot = await store.snapshot()
    #expect(opened == repository)
    #expect(snapshot.repository == repository)
    #expect(snapshot.job == canceledJob)
    #expect(snapshot.cancellation == canceledJob.cancellation)
    #expect(snapshot.events == [replayedEvent])
    #expect(snapshot.replayResponse?.events == [replayedEvent])
    #expect(snapshot.latestCursor == replayCursor)
    #expect(snapshot.metadata == lifecycleMetadata(capability: "events.replay.v1"))
    }

    /// Verifies a delayed open for a different repository cannot overwrite newer same-run state for another repository.
    @Test func lifecycleStoreDoesNotMixRepositoryAndJobStateAcrossDifferentRepositoryOpen() async throws {
        let firstRepository = lifecycleRepository(
            repositoryId: "repo_123",
            displayName: "Atelia Kit",
            rootPath: "/workspace/atelia-kit"
        )
        let secondRepository = lifecycleRepository(
            repositoryId: "repo_456",
            displayName: "Atelia App",
            rootPath: "/workspace/atelia-app"
        )
        let job = lifecycleJob()
        let canceledJob = lifecycleJob(status: .canceled)
        let listedEvent = lifecycleEvent(eventId: "evt_list_new", sequence: 42)
        let replayedEvent = lifecycleEvent(eventId: "evt_replay_new", sequence: 43)
        let replayCursor = AteliaEventRouteCursor.afterSequence(replayedEvent.sequence)

        let client = DelayedRepositoryOpenLifecycleClientFixture(
            repositoriesResponse: [firstRepository],
            registerRepositoryResponse: AteliaRegisterRepositoryResponse(
                metadata: lifecycleMetadata(capability: "repositories.register.v1"),
                repository: secondRepository,
                policy: nil
            ),
            submitJobResponse: AteliaSubmitJobResponse(
                metadata: lifecycleMetadata(capability: "jobs.submit.v1"),
                job: job,
                policy: AteliaPolicyDecision(
                    decisionId: "pol_124",
                    outcome: .audited,
                    riskTier: .r1,
                    requestedCapability: "filesystem.read",
                    reasonCode: "bounded_read",
                    reason: "Read-only request is permitted"
                )
            ),
            cancelJobResponse: AteliaCancelJobResponse(
                metadata: lifecycleMetadata(capability: "jobs.cancel.v1"),
                job: canceledJob,
                cancellation: canceledJob.cancellation ?? AteliaJobCancellation(state: "completed")
            ),
            listJobEventsResponse: AteliaListEventsResponse(
                metadata: lifecycleMetadata(capability: "events.list.v1"),
                events: [listedEvent],
                nextPageToken: nil
            ),
            replayEventsResponse: AteliaReplayEventsResponse(
                metadata: lifecycleMetadata(capability: "events.replay.v1"),
                events: [replayedEvent],
                cursor: replayCursor
            )
        )
        let store = AteliaProjectLifecycleStore(client: client, session: AteliaSession())

        _ = try await store.open(
            request: AteliaRegisterRepositoryRequest(
                displayName: firstRepository.displayName,
                rootPath: firstRepository.rootPath,
                allowedScope: firstRepository.allowedScope,
                requester: .user(id: "user_123", displayName: "Ada")
            )
        )

        let openTask = Task {
            try await store.open(request: AteliaRegisterRepositoryRequest(
                displayName: secondRepository.displayName,
                rootPath: secondRepository.rootPath,
                allowedScope: secondRepository.allowedScope,
                requester: .user(id: "user_123", displayName: "Ada")
            ))
        }
        await client.waitForRegisterRequest()

        _ = try await store.submit(
            request: AteliaSubmitJobRequest(
                repositoryId: firstRepository.repositoryId,
                requester: .agent(id: "agent_secretary", displayName: "Secretary"),
                kind: "documentation_review",
                goal: "Review protocol references"
            )
        )
        _ = try await store.cancel(
            jobId: job.jobId,
            request: AteliaCancelJobRequest(
                requester: .user(id: "user_123", displayName: "Ada"),
                reason: "stop"
            )
        )
        _ = try await store.listJobEvents(
            jobId: job.jobId,
            request: AteliaListEventsRequest(repositoryId: firstRepository.repositoryId)
        )
        _ = try await store.replayEvents(
            request: AteliaReplayEventsRequest(repositoryId: firstRepository.repositoryId)
        )

        await client.completeRegister()
        let opened = try await openTask.value

        let snapshot = await store.snapshot()
        #expect(opened == secondRepository)
        #expect(snapshot.repository == firstRepository)
        #expect(snapshot.job == canceledJob)
        #expect(snapshot.events == [replayedEvent])
        #expect(snapshot.replayResponse?.events == [replayedEvent])
        #expect(snapshot.latestCursor == replayCursor)
        #expect(snapshot.metadata == lifecycleMetadata(capability: "events.replay.v1"))
    }
