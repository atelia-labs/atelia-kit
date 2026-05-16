import Foundation

/// Atomic snapshot of project and job lifecycle state cached by the store.
public struct AteliaProjectLifecycleStoreSnapshot: Sendable, Equatable {
    /// Latest repository projection returned by open/register.
    public var repository: AteliaRepository?
    /// Latest job projection returned by submit/get/cancel.
    public var job: AteliaJob?
    /// Latest cancellation projection returned by cancel.
    public var cancellation: AteliaJobCancellation?
    /// Latest polling-friendly event list returned by the client.
    public var events: [AteliaEvent]
    /// Latest bounded replay response returned by the client.
    public var replayResponse: AteliaReplayEventsResponse?
    /// Latest protocol metadata from the most recent cached response.
    public var metadata: AteliaProtocolMetadata?
    /// Latest cursor returned by a replay operation.
    public var latestCursor: AteliaEventCursor?

    /// Creates a project lifecycle snapshot.
    public init(
        repository: AteliaRepository?,
        job: AteliaJob?,
        cancellation: AteliaJobCancellation?,
        events: [AteliaEvent],
        replayResponse: AteliaReplayEventsResponse?,
        metadata: AteliaProtocolMetadata?,
        latestCursor: AteliaEventCursor?
    ) {
        self.repository = repository
        self.job = job
        self.cancellation = cancellation
        self.events = events
        self.replayResponse = replayResponse
        self.metadata = metadata
        self.latestCursor = latestCursor
    }
}

/// Actor-backed command/cache surface for repository registration and job lifecycle operations.
public actor AteliaProjectLifecycleStore {
    private let client: any AteliaClient
    private let session: AteliaSession
    private var latestRepository: AteliaRepository?
    private var latestJob: AteliaJob?
    private var latestCancellation: AteliaJobCancellation?
    private var latestEvents: [AteliaEvent] = []
    private var latestReplayResponse: AteliaReplayEventsResponse?
    private var latestMetadata: AteliaProtocolMetadata?
    private var latestCursorValue: AteliaEventCursor?
    private var nextOperationGeneration = 0
    private var clearGeneration = 0
    private var repositoryGeneration = 0
    private var jobGeneration = 0
    private var cancellationGeneration = 0
    private var eventsGeneration = 0
    private var replayGeneration = 0
    private var metadataGeneration = 0
    private var cursorGeneration = 0

    /// Creates a lifecycle store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.client = client
        self.session = session
    }

    /// Opens a project by reusing a registered repository if it already exists or registering one if needed.
    @discardableResult
    public func open(request: AteliaRegisterRepositoryRequest) async throws -> AteliaRepository {
        let operationGeneration = beginOperation()
        if let existingRepository = try await repository(matching: request.rootPath) {
            applyRepository(existingRepository, generation: operationGeneration)
            return existingRepository
        }

        let response = try await client.registerRepositoryResponse(for: session, request: request)
        applyRepositoryResponse(response, generation: operationGeneration)
        return response.repository
    }

    /// Submits a job and caches the persisted job projection.
    @discardableResult
    public func submit(request: AteliaSubmitJobRequest) async throws -> AteliaJob {
        let operationGeneration = beginOperation()
        let response = try await client.submitJobResponse(for: session, request: request)
        applyMetadata(response.metadata, generation: operationGeneration)
        applyJob(response.job, generation: operationGeneration)
        return response.job
    }

    /// Loads one job projection and caches it.
    @discardableResult
    public func job(jobId: String) async throws -> AteliaJob {
        let operationGeneration = beginOperation()
        let response = try await client.jobResponse(for: session, jobId: jobId)
        applyMetadata(response.metadata, generation: operationGeneration)
        applyJob(response.job, generation: operationGeneration)
        return response.job
    }

    /// Cancels one job and caches the returned cancellation state.
    @discardableResult
    public func cancel(jobId: String, request: AteliaCancelJobRequest) async throws -> AteliaJob {
        let operationGeneration = beginOperation()
        let response = try await client.cancelJobResponse(for: session, jobId: jobId, request: request)
        applyMetadata(response.metadata, generation: operationGeneration)
        applyJob(response.job, generation: operationGeneration)
        applyCancellation(response.cancellation, generation: operationGeneration)
        return response.job
    }

    /// Loads polling-friendly events for one repository or cursor scope and caches the latest list.
    @discardableResult
    public func listEvents(request: AteliaListEventsRequest = .init()) async throws -> [AteliaEvent] {
        let operationGeneration = beginOperation()
        let response = try await client.listEventsResponse(for: session, request: request)
        applyEventsResponse(response, generation: operationGeneration)
        return response.events
    }

    /// Loads polling-friendly events for one job and caches the latest list.
    @discardableResult
    public func listJobEvents(
        jobId: String,
        request: AteliaListEventsRequest = .init()
    ) async throws -> [AteliaEvent] {
        let operationGeneration = beginOperation()
        let response = try await client.listJobEventsResponse(
            for: session,
            jobId: jobId,
            request: request
        )
        applyEventsResponse(response, generation: operationGeneration)
        return response.events
    }

    /// Replays a bounded event range and caches the returned replay envelope.
    @discardableResult
    public func replayEvents(request: AteliaReplayEventsRequest) async throws -> [AteliaEvent] {
        let operationGeneration = beginOperation()
        let response = try await client.replayEventsResponse(for: session, request: request)
        applyReplayResponse(response, generation: operationGeneration)
        return response.events
    }

    /// Clears all cached repository, job, event, and metadata state.
    public func clear() {
        clearGeneration = nextOperationGeneration
        latestRepository = nil
        latestJob = nil
        latestCancellation = nil
        latestEvents = []
        latestReplayResponse = nil
        latestMetadata = nil
        latestCursorValue = nil
    }

    /// Returns the latest repository projection, if one has been loaded.
    public var repository: AteliaRepository? {
        latestRepository
    }

    /// Returns the latest job projection, if one has been loaded.
    public var job: AteliaJob? {
        latestJob
    }

    /// Returns the latest cancellation projection, if one has been loaded.
    public var cancellation: AteliaJobCancellation? {
        latestCancellation
    }

    /// Returns the latest polling-friendly events.
    public var events: [AteliaEvent] {
        latestEvents
    }

    /// Returns the latest bounded replay response.
    public var replayResponse: AteliaReplayEventsResponse? {
        latestReplayResponse
    }

    /// Returns the latest protocol metadata from the most recent successful operation.
    public var metadata: AteliaProtocolMetadata? {
        latestMetadata
    }

    /// Returns the latest replay cursor, if one has been loaded.
    public var latestCursor: AteliaEventCursor? {
        latestCursorValue
    }

    /// Returns an atomic snapshot of the cached repository, job, and event state.
    public func snapshot() -> AteliaProjectLifecycleStoreSnapshot {
        AteliaProjectLifecycleStoreSnapshot(
            repository: latestRepository,
            job: latestJob,
            cancellation: latestCancellation,
            events: latestEvents,
            replayResponse: latestReplayResponse,
            metadata: latestMetadata,
            latestCursor: latestCursorValue
        )
    }

    private func beginOperation() -> Int {
        nextOperationGeneration += 1
        return nextOperationGeneration
    }

    private func shouldApply(_ operationGeneration: Int) -> Bool {
        operationGeneration > clearGeneration
    }

    private func shouldApply(_ operationGeneration: Int, after appliedGeneration: Int) -> Bool {
        shouldApply(operationGeneration) && operationGeneration > appliedGeneration
    }

    private func applyMetadata(_ metadata: AteliaProtocolMetadata, generation: Int) {
        guard shouldApply(generation, after: metadataGeneration) else { return }
        metadataGeneration = generation
        latestMetadata = metadata
    }

    private func applyRepository(_ repository: AteliaRepository, generation: Int) {
        guard shouldApply(generation, after: repositoryGeneration) else { return }
        if latestRepository?.repositoryId != repository.repositoryId {
            resetJobScopedState(generation: generation)
        }
        repositoryGeneration = generation
        latestRepository = repository
    }

    private func resetJobScopedState(generation: Int) {
        if shouldApply(generation, after: jobGeneration) {
            jobGeneration = generation
            latestJob = nil
        }
        if shouldApply(generation, after: cancellationGeneration) {
            cancellationGeneration = generation
            latestCancellation = nil
        }
        if shouldApply(generation, after: eventsGeneration) {
            eventsGeneration = generation
            latestEvents = []
        }
        if shouldApply(generation, after: replayGeneration) {
            replayGeneration = generation
            latestReplayResponse = nil
        }
        if shouldApply(generation, after: cursorGeneration) {
            cursorGeneration = generation
            latestCursorValue = nil
        }
    }

    private func applyRepositoryResponse(
        _ response: AteliaRegisterRepositoryResponse,
        generation: Int
    ) {
        applyMetadata(response.metadata, generation: generation)
        applyRepository(response.repository, generation: generation)
    }

    private func applyJob(_ job: AteliaJob, generation: Int) {
        guard shouldApply(generation, after: jobGeneration) else { return }
        jobGeneration = generation
        latestJob = job
    }

    private func applyCancellation(_ cancellation: AteliaJobCancellation, generation: Int) {
        guard shouldApply(generation, after: cancellationGeneration) else { return }
        cancellationGeneration = generation
        latestCancellation = cancellation
    }

    private func applyEventsResponse(_ response: AteliaListEventsResponse, generation: Int) {
        applyMetadata(response.metadata, generation: generation)
        guard shouldApply(generation, after: eventsGeneration) else { return }
        eventsGeneration = generation
        latestEvents = response.events
    }

    private func applyReplayResponse(_ response: AteliaReplayEventsResponse, generation: Int) {
        applyMetadata(response.metadata, generation: generation)
        guard shouldApply(generation, after: replayGeneration) else { return }
        replayGeneration = generation
        latestReplayResponse = response
        if shouldApply(generation, after: eventsGeneration) {
            eventsGeneration = generation
            latestEvents = response.events
        }
        if shouldApply(generation, after: cursorGeneration) {
            cursorGeneration = generation
            latestCursorValue = response.cursor
        }
    }

    private func repository(matching rootPath: String) async throws -> AteliaRepository? {
        let repositories = try await client.repositories(for: session)
        return repositories.first { $0.rootPath == rootPath }
    }
}
