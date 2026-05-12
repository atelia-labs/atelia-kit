import Foundation

/// Atomic snapshot of tool-output render store cached state.
public struct AteliaToolOutputRenderStoreSnapshot: Sendable, Equatable {
    /// Latest tool-output render envelope, if one has completed.
    public var response: AteliaToolOutputRenderResponse?
    /// Latest protocol metadata.
    public var metadata: AteliaProtocolMetadata?
    /// Latest tool-result reference.
    public var toolResult: AteliaToolResultRef?
    /// Latest requested and applied output format.
    public var format: AteliaToolOutputRenderFormat?
    /// Latest rendered output body.
    public var renderedOutput: String?
    /// Latest rendered output metadata.
    public var renderedOutputMetadata: AteliaRenderedToolOutputMetadata?

    /// Creates a tool-output render snapshot.
    public init(
        response: AteliaToolOutputRenderResponse?,
        metadata: AteliaProtocolMetadata?,
        toolResult: AteliaToolResultRef?,
        format: AteliaToolOutputRenderFormat?,
        renderedOutput: String?,
        renderedOutputMetadata: AteliaRenderedToolOutputMetadata?
    ) {
        self.response = response
        self.metadata = metadata
        self.toolResult = toolResult
        self.format = format
        self.renderedOutput = renderedOutput
        self.renderedOutputMetadata = renderedOutputMetadata
    }
}

/// Actor-backed cache for the latest tool-output render response.
public actor AteliaToolOutputRenderStore {
    private let client: any AteliaClient
    private let session: AteliaSession
    private var latestResponse: AteliaToolOutputRenderResponse?
    private var latestMetadata: AteliaProtocolMetadata?
    private var latestToolResult: AteliaToolResultRef?
    private var latestFormat: AteliaToolOutputRenderFormat?
    private var latestRenderedOutput: String?
    private var latestRenderedOutputMetadata: AteliaRenderedToolOutputMetadata?
    private var nextRenderGeneration = 0
    private var latestAppliedGeneration = 0
    private var clearGeneration = 0

    /// Creates a render-store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.client = client
        self.session = session
    }

    /// Renders a tool-output payload and caches the latest successful response.
    @discardableResult
    public func render(
        request: AteliaToolOutputRenderRequest
    ) async throws -> AteliaToolOutputRenderResponse {
        let operationGeneration = beginRender()
        let response = try await client.renderToolOutputResponse(for: session, request: request)
        apply(response, generation: operationGeneration)
        return response
    }

    /// Clears any cached tool-output render state.
    public func clear() {
        clearGeneration = nextRenderGeneration
        latestResponse = nil
        latestMetadata = nil
        latestToolResult = nil
        latestFormat = nil
        latestRenderedOutput = nil
        latestRenderedOutputMetadata = nil
    }

    /// Returns the latest cached render response.
    public var response: AteliaToolOutputRenderResponse? {
        latestResponse
    }

    /// Returns the latest protocol metadata.
    public var metadata: AteliaProtocolMetadata? {
        latestMetadata
    }

    /// Returns the latest tool-result reference.
    public var toolResult: AteliaToolResultRef? {
        latestToolResult
    }

    /// Returns the latest render output format.
    public var format: AteliaToolOutputRenderFormat? {
        latestFormat
    }

    /// Returns the latest rendered output body.
    public var renderedOutput: String? {
        latestRenderedOutput
    }

    /// Returns the latest rendered output metadata.
    public var renderedOutputMetadata: AteliaRenderedToolOutputMetadata? {
        latestRenderedOutputMetadata
    }

    /// Returns an atomic snapshot of cached tool-output render state.
    public func snapshot() -> AteliaToolOutputRenderStoreSnapshot {
        AteliaToolOutputRenderStoreSnapshot(
            response: latestResponse,
            metadata: latestMetadata,
            toolResult: latestToolResult,
            format: latestFormat,
            renderedOutput: latestRenderedOutput,
            renderedOutputMetadata: latestRenderedOutputMetadata
        )
    }

    /// Increments and returns the next render-generation token.
    private func beginRender() -> Int {
        nextRenderGeneration += 1
        return nextRenderGeneration
    }

    /// Returns whether a render generation is newer than the clear generation.
    private func shouldApply(_ operationGeneration: Int) -> Bool {
        operationGeneration > clearGeneration
    }

    /// Applies render response to cache when it is newer and not stale.
    private func apply(
        _ response: AteliaToolOutputRenderResponse,
        generation: Int
    ) {
        guard shouldApply(generation) && generation > latestAppliedGeneration else { return }
        latestAppliedGeneration = generation
        latestResponse = response
        latestMetadata = response.metadata
        latestToolResult = response.toolResult
        latestFormat = response.format
        latestRenderedOutput = response.renderedOutput
        latestRenderedOutputMetadata = response.renderedOutputMetadata
    }
}
