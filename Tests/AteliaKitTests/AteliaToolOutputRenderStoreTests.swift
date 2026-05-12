import Foundation
import Testing
@testable import AteliaKit

/// Errors thrown by tool-output render store test fixtures.
private enum ToolOutputRenderStoreFixtureError: Error {
    case requestFailed
    case timeoutWaitingForRequests(expected: Int, actual: Int)
    case unconfiguredResponse
}

/// Sequential fixture client that records the latest render request.
private actor ToolOutputRenderStoreClientFixture: AteliaClient {
    private var responses: [Result<AteliaToolOutputRenderResponse, any Error>]
    private(set) var lastRequest: AteliaToolOutputRenderRequest?

    /// Creates a fixture with queued render responses.
    init(responses: [Result<AteliaToolOutputRenderResponse, any Error>] = []) {
        self.responses = responses
    }

    /// Records the request and returns the next queued render response.
    func renderToolOutputResponse(
        for session: AteliaSession,
        request: AteliaToolOutputRenderRequest
    ) async throws -> AteliaToolOutputRenderResponse {
        _ = session
        lastRequest = request
        return try nextResponse()
    }

    /// Removes and returns the next queued render response.
    private func nextResponse() throws -> AteliaToolOutputRenderResponse {
        guard !responses.isEmpty else {
            throw ToolOutputRenderStoreFixtureError.unconfiguredResponse
        }
        return try responses.removeFirst().get()
    }
}

/// Controllable fixture client for ordering async render completions.
private actor ControllableToolOutputRenderStoreClientFixture: AteliaClient {
    private var renderContinuations: [CheckedContinuation<AteliaToolOutputRenderResponse, any Error>] = []

    /// Captures a render request until the test resumes it.
    func renderToolOutputResponse(
        for session: AteliaSession,
        request: AteliaToolOutputRenderRequest
    ) async throws -> AteliaToolOutputRenderResponse {
        _ = session
        _ = request
        return try await withCheckedThrowingContinuation { continuation in
            renderContinuations.append(continuation)
        }
    }

    /// Waits until the fixture has captured the expected number of requests.
    func waitForRequests(_ count: Int, timeout: Duration = .seconds(2)) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while renderContinuations.count < count {
            guard clock.now < deadline else {
                throw ToolOutputRenderStoreFixtureError.timeoutWaitingForRequests(
                    expected: count,
                    actual: renderContinuations.count
                )
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    /// Completes one captured request with a render response.
    func respond(to index: Int, with response: AteliaToolOutputRenderResponse) {
        renderContinuations[index].resume(returning: response)
    }

    /// Completes one captured request with an error.
    func fail(to index: Int, with error: any Error) {
        renderContinuations[index].resume(throwing: error)
    }
}

/// Builds protocol metadata for render responses.
private func toolOutputMetadata(capability: String = "tool_output_render.v1") -> AteliaProtocolMetadata {
    AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: [capability]
    )
}

/// Builds a canonical tool-result reference fixture.
private func toolResult(_ id: String) -> AteliaToolResultRef {
    AteliaToolResultRef(
        toolResultId: "tool_result_\(id)",
        toolInvocationId: "tool_invocation_\(id)",
        jobId: "job_\(id)",
        repositoryId: "repo_\(id)",
        contentType: "application/json"
    )
}

/// Builds a render response fixture.
private func toolOutputResponse(
    suffix: String,
    format: AteliaToolOutputRenderFormat = .json,
    renderedOutput: String = "{\"value\":\"ready\"}",
    degraded: Bool = false,
    fallbackReason: String? = nil
) -> AteliaToolOutputRenderResponse {
    AteliaToolOutputRenderResponse(
        metadata: toolOutputMetadata(),
        toolResult: toolResult(suffix),
        format: format,
        renderedOutput: renderedOutput,
        renderedOutputMetadata: AteliaRenderedToolOutputMetadata(
            degraded: degraded,
            fallbackReason: fallbackReason,
            truncation: AteliaRenderedToolOutputTruncation(
                originalBytes: 64,
                retainedBytes: 32,
                reason: "test truncate"
            )
        )
    )
}

/// Builds a render request fixture.
private func toolOutputRequest(format: AteliaToolOutputRenderFormat = .json) -> AteliaToolOutputRenderRequest {
    AteliaToolOutputRenderRequest(
        toolResult: toolResult("common"),
        format: format
    )
}

/// Verifies render caches the latest successful response and derived render fields.
@Test func renderCachesLatestResponseAndDerivedState() async throws {
    let request = toolOutputRequest()
    let response = toolOutputResponse(suffix: "cached", renderedOutput: "Hello")
    let client = ToolOutputRenderStoreClientFixture(responses: [.success(response)])
    let store = AteliaToolOutputRenderStore(client: client, session: AteliaSession())

    let rendered = try await store.render(request: request)

    #expect(rendered == response)
    #expect(await client.lastRequest == request)
    #expect(await store.response == response)
    #expect(await store.metadata == response.metadata)
    #expect(await store.toolResult == response.toolResult)
    #expect(await store.format == response.format)
    #expect(await store.renderedOutput == response.renderedOutput)
    #expect(await store.renderedOutputMetadata == response.renderedOutputMetadata)

    let snapshot = await store.snapshot()
    #expect(snapshot.response == response)
    #expect(snapshot.metadata == response.metadata)
    #expect(snapshot.toolResult == response.toolResult)
    #expect(snapshot.format == response.format)
    #expect(snapshot.renderedOutput == response.renderedOutput)
    #expect(snapshot.renderedOutputMetadata == response.renderedOutputMetadata)
}

/// Verifies a stale in-flight render cannot overwrite a newer completed render.
@Test func staleRenderDoesNotOverwriteNewerRender() async throws {
    let client = ControllableToolOutputRenderStoreClientFixture()
    let store = AteliaToolOutputRenderStore(client: client, session: AteliaSession())
    let olderResponse = toolOutputResponse(suffix: "older", renderedOutput: "older")
    let newerResponse = toolOutputResponse(suffix: "newer", renderedOutput: "newer")
    let request = toolOutputRequest(format: .json)

    let olderRender = Task {
        try await store.render(request: request)
    }
    defer { olderRender.cancel() }
    try await client.waitForRequests(1)

    let newerRender = Task {
        try await store.render(request: request)
    }
    defer { newerRender.cancel() }
    try await client.waitForRequests(2)

    await client.respond(to: 1, with: newerResponse)
    _ = try await newerRender.value
    await client.respond(to: 0, with: olderResponse)
    _ = try await olderRender.value

    #expect(await store.response == newerResponse)
    #expect(await store.toolResult == newerResponse.toolResult)
    #expect(await store.renderedOutput == newerResponse.renderedOutput)
    #expect(await store.format == newerResponse.format)
    #expect(await store.renderedOutputMetadata == newerResponse.renderedOutputMetadata)
}

/// Verifies a failed newer render does not discard an older successful render.
@Test func failedNewerRenderDoesNotDiscardOlderSuccessfulRender() async throws {
    let client = ControllableToolOutputRenderStoreClientFixture()
    let store = AteliaToolOutputRenderStore(client: client, session: AteliaSession())
    let olderResponse = toolOutputResponse(suffix: "older", renderedOutput: "older")
    let request = toolOutputRequest(format: .text)

    let olderRender = Task {
        try await store.render(request: request)
    }
    defer { olderRender.cancel() }
    try await client.waitForRequests(1)

    let newerRender = Task {
        try await store.render(request: request)
    }
    defer { newerRender.cancel() }
    try await client.waitForRequests(2)

    await client.fail(to: 1, with: ToolOutputRenderStoreFixtureError.requestFailed)
    await #expect(throws: ToolOutputRenderStoreFixtureError.self) {
        try await newerRender.value
    }
    await client.respond(to: 0, with: olderResponse)
    _ = try await olderRender.value

    #expect(await store.response == olderResponse)
    #expect(await store.toolResult == olderResponse.toolResult)
    #expect(await store.renderedOutput == olderResponse.renderedOutput)
    #expect(await store.format == olderResponse.format)
}

/// Verifies clear prevents older in-flight renders from repopulating cached state.
@Test func clearInvalidatesInFlightRender() async throws {
    let client = ControllableToolOutputRenderStoreClientFixture()
    let store = AteliaToolOutputRenderStore(client: client, session: AteliaSession())
    let response = toolOutputResponse(suffix: "pending", renderedOutput: "pending")

    let render = Task {
        try await store.render(request: toolOutputRequest())
    }
    defer { render.cancel() }
    try await client.waitForRequests(1)

    await store.clear()
    await client.respond(to: 0, with: response)
    _ = try await render.value

    #expect(await store.response == nil)
    #expect(await store.metadata == nil)
    #expect(await store.toolResult == nil)
    #expect(await store.format == nil)
    #expect(await store.renderedOutput == nil)
    #expect(await store.renderedOutputMetadata == nil)

    let snapshot = await store.snapshot()
    #expect(snapshot.response == nil)
    #expect(snapshot.metadata == nil)
    #expect(snapshot.toolResult == nil)
    #expect(snapshot.format == nil)
    #expect(snapshot.renderedOutput == nil)
    #expect(snapshot.renderedOutputMetadata == nil)
}

/// Verifies clear removes cached render response and derived fields.
@Test func clearResetsCachedRenderState() async throws {
    let request = toolOutputRequest(format: .toon)
    let response = toolOutputResponse(suffix: "stored", format: .toon, renderedOutput: "rendered")
    let client = ToolOutputRenderStoreClientFixture(responses: [.success(response)])
    let store = AteliaToolOutputRenderStore(client: client, session: AteliaSession())

    _ = try await store.render(request: request)
    await store.clear()

    #expect(await store.response == nil)
    #expect(await store.metadata == nil)
    #expect(await store.toolResult == nil)
    #expect(await store.format == nil)
    #expect(await store.renderedOutput == nil)
    #expect(await store.renderedOutputMetadata == nil)
}
