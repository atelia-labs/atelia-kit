import Foundation

/// Atomic snapshot of package authoring store cached state.
public struct AteliaPackageAuthoringStoreSnapshot: Sendable, Equatable {
    /// Latest authoring-flow response envelope, if one has completed.
    public var authoringFlowResponse: AteliaPackageAuthoringFlowResponse?
    /// Latest remix response envelope, if one has completed.
    public var remixResponse: AteliaPackageRemixResponse?
    /// Latest publication response envelope, if one has completed.
    public var publicationResponse: AteliaPackagePublicationResponse?
    /// Latest registry-submission response envelope, if one has completed.
    public var registrySubmissionResponse: AteliaPackageRegistrySubmissionResponse?
    /// Latest protocol metadata from the most recent cached response.
    public var metadata: AteliaProtocolMetadata?
    /// Latest package authoring flow.
    public var flow: AteliaPackageAuthoringFlow?
    /// Latest cached flow steps.
    public var steps: [AteliaPackageAuthoringFlowStep]
    /// Steps that currently require user consent.
    public var stepsRequiringConsent: [AteliaPackageAuthoringFlowStep]
    /// Latest publication plan from the cached flow.
    public var publicationPlan: AteliaPackagePublicationPlan?
    /// Cached source class for the latest flow.
    public var sourceClass: AteliaPackageSourceClass?
    /// Cached source reference for the latest flow.
    public var source: AteliaPackageGitHubSourceReference?
    /// Latest registry-submission state returned by the registry endpoint.
    public var registrySubmissionState: AteliaPackageRegistrySubmissionState?

    /// Creates a package authoring store snapshot.
    public init(
        authoringFlowResponse: AteliaPackageAuthoringFlowResponse?,
        remixResponse: AteliaPackageRemixResponse?,
        publicationResponse: AteliaPackagePublicationResponse?,
        registrySubmissionResponse: AteliaPackageRegistrySubmissionResponse?,
        metadata: AteliaProtocolMetadata?,
        flow: AteliaPackageAuthoringFlow?,
        steps: [AteliaPackageAuthoringFlowStep],
        stepsRequiringConsent: [AteliaPackageAuthoringFlowStep],
        publicationPlan: AteliaPackagePublicationPlan?,
        sourceClass: AteliaPackageSourceClass?,
        source: AteliaPackageGitHubSourceReference?,
        registrySubmissionState: AteliaPackageRegistrySubmissionState?
    ) {
        self.authoringFlowResponse = authoringFlowResponse
        self.remixResponse = remixResponse
        self.publicationResponse = publicationResponse
        self.registrySubmissionResponse = registrySubmissionResponse
        self.metadata = metadata
        self.flow = flow
        self.steps = steps
        self.stepsRequiringConsent = stepsRequiringConsent
        self.publicationPlan = publicationPlan
        self.sourceClass = sourceClass
        self.source = source
        self.registrySubmissionState = registrySubmissionState
    }
}

/// Actor-backed cache for package authoring-flow, remix, publication, and registry-submission state.
public actor AteliaPackageAuthoringStore {
    /// Client used to perform Secretary package-authoring requests.
    private let client: any AteliaClient
    /// Session attached to all package-authoring requests.
    private let session: AteliaSession
    /// Latest protocol metadata from a successful package-authoring operation.
    private var latestMetadata: AteliaProtocolMetadata?
    /// Latest flow returned by any package-authoring operation.
    private var latestFlow: AteliaPackageAuthoringFlow?
    /// Latest authoring-flow response envelope.
    private var latestAuthoringFlowResponse: AteliaPackageAuthoringFlowResponse?
    /// Latest remix response envelope.
    private var latestRemixResponse: AteliaPackageRemixResponse?
    /// Latest publication response envelope.
    private var latestPublicationResponse: AteliaPackagePublicationResponse?
    /// Latest registry-submission response envelope.
    private var latestRegistrySubmissionResponse: AteliaPackageRegistrySubmissionResponse?
    /// Monotonic token assigned to newly started operations.
    private var nextOperationGeneration = 0
    /// Generation after which results are allowed to update the cache.
    private var clearGeneration = 0
    /// Latest generation that updated metadata.
    private var metadataGeneration = 0
    /// Latest generation that updated the flow.
    private var flowGeneration = 0
    /// Latest generation that updated the authoring-flow envelope.
    private var authoringFlowGeneration = 0
    /// Latest generation that updated the remix envelope.
    private var remixGeneration = 0
    /// Latest generation that updated the publication envelope.
    private var publicationGeneration = 0
    /// Latest generation that updated the registry-submission envelope.
    private var registrySubmissionGeneration = 0

    /// Creates an authoring store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.client = client
        self.session = session
    }

    /// Loads the package authoring-flow envelope and caches latest metadata and flow.
    @discardableResult
    public func load(
        request: AteliaPackageAuthoringFlowRequest
    ) async throws -> AteliaPackageAuthoringFlow {
        let operationGeneration = nextOperation()
        let response = try await client.packageAuthoringFlowResponse(for: session, request: request)
        applyAuthoringFlowResponse(response, generation: operationGeneration)
        return response.flow
    }

    /// Starts a remix request and caches the returned authoring flow and metadata.
    @discardableResult
    public func remix(
        request: AteliaPackageRemixRequest
    ) async throws -> AteliaPackageAuthoringFlow {
        let operationGeneration = nextOperation()
        let response = try await client.packageRemixResponse(for: session, request: request)
        applyRemixResponse(response, generation: operationGeneration)
        return response.flow
    }

    /// Prepares a package publication request and caches resulting flow and metadata.
    @discardableResult
    public func preparePublication(
        request: AteliaPackagePublicationRequest
    ) async throws -> AteliaPackageAuthoringFlow {
        let operationGeneration = nextOperation()
        let response = try await client.packagePublicationResponse(for: session, request: request)
        applyPublicationResponse(response, generation: operationGeneration)
        return response.flow
    }

    /// Submits registry-submission state and caches envelope + latest registry state.
    @discardableResult
    public func submitRegistry(
        request: AteliaPackageRegistrySubmissionRequest
    ) async throws -> AteliaPackageRegistrySubmissionState {
        let operationGeneration = nextOperation()
        let response = try await client.packageRegistrySubmissionResponse(for: session, request: request)
        applyRegistrySubmissionResponse(response, generation: operationGeneration)
        return response.state
    }

    /// Clears all cached authoring-flow, response, and metadata state.
    public func clear() {
        clearGeneration = nextOperationGeneration
        latestMetadata = nil
        latestFlow = nil
        latestAuthoringFlowResponse = nil
        latestRemixResponse = nil
        latestPublicationResponse = nil
        latestRegistrySubmissionResponse = nil
    }

    /// Returns the cached latest authoring-flow response envelope.
    public var authoringFlowResponse: AteliaPackageAuthoringFlowResponse? {
        latestAuthoringFlowResponse
    }

    /// Returns the cached latest remix response envelope.
    public var remixResponse: AteliaPackageRemixResponse? {
        latestRemixResponse
    }

    /// Returns the cached latest publication response envelope.
    public var publicationResponse: AteliaPackagePublicationResponse? {
        latestPublicationResponse
    }

    /// Returns the cached latest registry-submission response envelope.
    public var registrySubmissionResponse: AteliaPackageRegistrySubmissionResponse? {
        latestRegistrySubmissionResponse
    }

    /// Returns the latest protocol metadata from the most recent successful operation.
    public var metadata: AteliaProtocolMetadata? {
        latestMetadata
    }

    /// Returns the latest cached package authoring flow.
    public var flow: AteliaPackageAuthoringFlow? {
        latestFlow
    }

    /// Returns the latest cached flow steps.
    public var steps: [AteliaPackageAuthoringFlowStep] {
        latestFlow?.steps ?? []
    }

    /// Returns the steps that currently require user consent.
    public var stepsRequiringConsent: [AteliaPackageAuthoringFlowStep] {
        latestFlow?.stepsRequiringConsent ?? []
    }

    /// Returns the latest publication plan from the cached flow.
    public var publicationPlan: AteliaPackagePublicationPlan? {
        latestFlow?.publicationPlan
    }

    /// Returns the cached source class for the latest flow.
    public var sourceClass: AteliaPackageSourceClass? {
        latestFlow?.sourceClass
    }

    /// Returns the cached source reference for the latest flow.
    public var source: AteliaPackageGitHubSourceReference? {
        latestFlow?.source
    }

    /// Returns the cached registry-submission state.
    public var registrySubmissionState: AteliaPackageRegistrySubmissionState? {
        latestRegistrySubmissionResponse?.state
    }

    /// Returns an atomic snapshot of the cached authoring-flow, publication, and registry state.
    public func snapshot() -> AteliaPackageAuthoringStoreSnapshot {
        AteliaPackageAuthoringStoreSnapshot(
            authoringFlowResponse: latestAuthoringFlowResponse,
            remixResponse: latestRemixResponse,
            publicationResponse: latestPublicationResponse,
            registrySubmissionResponse: latestRegistrySubmissionResponse,
            metadata: latestMetadata,
            flow: latestFlow,
            steps: steps,
            stepsRequiringConsent: stepsRequiringConsent,
            publicationPlan: latestFlow?.publicationPlan,
            sourceClass: latestFlow?.sourceClass,
            source: latestFlow?.source,
            registrySubmissionState: latestRegistrySubmissionResponse?.state
        )
    }

    /// Increments and returns the next operation generation token.
    private func nextOperation() -> Int {
        nextOperationGeneration += 1
        return nextOperationGeneration
    }

    /// Returns whether an operation generation is newer than the current clear generation.
    private func shouldApply(_ operationGeneration: Int) -> Bool {
        operationGeneration > clearGeneration
    }

    /// Returns whether an operation generation should replace a cached generation.
    private func shouldApply(_ operationGeneration: Int, after appliedGeneration: Int) -> Bool {
        shouldApply(operationGeneration) && operationGeneration > appliedGeneration
    }

    /// Caches response metadata when not stale.
    private func applyMetadata(_ metadata: AteliaProtocolMetadata, generation: Int) {
        guard shouldApply(generation, after: metadataGeneration) else { return }
        metadataGeneration = generation
        latestMetadata = metadata
    }

    /// Caches a complete authoring flow and derived metadata.
    private func applyFlow(_ flow: AteliaPackageAuthoringFlow, generation: Int) {
        guard shouldApply(generation, after: flowGeneration) else { return }
        flowGeneration = generation
        latestFlow = flow
    }

    /// Caches the authoring-flow envelope and derived metadata.
    private func applyAuthoringFlowResponse(
        _ response: AteliaPackageAuthoringFlowResponse,
        generation: Int
    ) {
        if shouldApply(generation, after: authoringFlowGeneration) {
            authoringFlowGeneration = generation
            latestAuthoringFlowResponse = response
            applyMetadata(response.metadata, generation: generation)
            applyFlow(response.flow, generation: generation)
        }
    }

    /// Caches the remix response and derived metadata.
    private func applyRemixResponse(
        _ response: AteliaPackageRemixResponse,
        generation: Int
    ) {
        if shouldApply(generation, after: remixGeneration) {
            remixGeneration = generation
            latestRemixResponse = response
            applyMetadata(response.metadata, generation: generation)
            applyFlow(response.flow, generation: generation)
        }
    }

    /// Caches the publication response and derived metadata.
    private func applyPublicationResponse(
        _ response: AteliaPackagePublicationResponse,
        generation: Int
    ) {
        if shouldApply(generation, after: publicationGeneration) {
            publicationGeneration = generation
            latestPublicationResponse = response
            applyMetadata(response.metadata, generation: generation)
            applyFlow(response.flow, generation: generation)
        }
    }

    /// Caches the registry-submission response and derived metadata/flow.
    private func applyRegistrySubmissionResponse(
        _ response: AteliaPackageRegistrySubmissionResponse,
        generation: Int
    ) {
        if shouldApply(generation, after: registrySubmissionGeneration) {
            registrySubmissionGeneration = generation
            latestRegistrySubmissionResponse = response
            applyMetadata(response.metadata, generation: generation)
            if let flow = response.flow {
                applyFlow(flow, generation: generation)
            }
        }
    }
}
