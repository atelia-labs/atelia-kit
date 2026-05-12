import Foundation
import Testing
@testable import AteliaKit

private actor PackageAuthoringStoreClientFixture: AteliaClient {
    /// Queued authoring-flow responses returned by the fixture.
    private var authoringFlowResponses: [Result<AteliaPackageAuthoringFlowResponse, any Error>]
    /// Queued remix responses returned by the fixture.
    private var remixResponses: [Result<AteliaPackageRemixResponse, any Error>]
    /// Queued publication responses returned by the fixture.
    private var publicationResponses: [Result<AteliaPackagePublicationResponse, any Error>]
    /// Queued registry-submission responses returned by the fixture.
    private var registrySubmissionResponses: [Result<AteliaPackageRegistrySubmissionResponse, any Error>]
    /// Session observed for the latest authoring-flow request.
    private(set) var authoringFlowSession: AteliaSession?
    /// Session observed for the latest remix request.
    private(set) var remixSession: AteliaSession?
    /// Session observed for the latest publication request.
    private(set) var publicationSession: AteliaSession?
    /// Session observed for the latest registry-submission request.
    private(set) var registrySubmissionSession: AteliaSession?
    /// Latest authoring-flow request observed by the fixture.
    private(set) var lastAuthoringFlowRequest: AteliaPackageAuthoringFlowRequest?
    /// Latest remix request observed by the fixture.
    private(set) var lastRemixRequest: AteliaPackageRemixRequest?
    /// Latest publication request observed by the fixture.
    private(set) var lastPublicationRequest: AteliaPackagePublicationRequest?
    /// Latest registry-submission request observed by the fixture.
    private(set) var lastRegistrySubmissionRequest: AteliaPackageRegistrySubmissionRequest?

    /// Creates a fixture with per-operation response queues.
    init(
        authoringFlowResponses: [Result<AteliaPackageAuthoringFlowResponse, any Error>] = [],
        remixResponses: [Result<AteliaPackageRemixResponse, any Error>] = [],
        publicationResponses: [Result<AteliaPackagePublicationResponse, any Error>] = [],
        registrySubmissionResponses: [Result<AteliaPackageRegistrySubmissionResponse, any Error>] = []
    ) {
        self.authoringFlowResponses = authoringFlowResponses
        self.remixResponses = remixResponses
        self.publicationResponses = publicationResponses
        self.registrySubmissionResponses = registrySubmissionResponses
    }

    /// Records and returns the next authoring-flow response.
    func packageAuthoringFlowResponse(
        for session: AteliaSession,
        request: AteliaPackageAuthoringFlowRequest
    ) async throws -> AteliaPackageAuthoringFlowResponse {
        authoringFlowSession = session
        lastAuthoringFlowRequest = request
        return try nextAuthoringFlowResponse()
    }

    /// Records and returns the next remix response.
    func packageRemixResponse(
        for session: AteliaSession,
        request: AteliaPackageRemixRequest
    ) async throws -> AteliaPackageRemixResponse {
        remixSession = session
        lastRemixRequest = request
        return try nextRemixResponse()
    }

    /// Records and returns the next publication response.
    func packagePublicationResponse(
        for session: AteliaSession,
        request: AteliaPackagePublicationRequest
    ) async throws -> AteliaPackagePublicationResponse {
        publicationSession = session
        lastPublicationRequest = request
        return try nextPublicationResponse()
    }

    /// Records and returns the next registry-submission response.
    func packageRegistrySubmissionResponse(
        for session: AteliaSession,
        request: AteliaPackageRegistrySubmissionRequest
    ) async throws -> AteliaPackageRegistrySubmissionResponse {
        registrySubmissionSession = session
        lastRegistrySubmissionRequest = request
        return try nextRegistrySubmissionResponse()
    }

    /// Dequeues the next authoring-flow response.
    private func nextAuthoringFlowResponse() throws -> AteliaPackageAuthoringFlowResponse {
        guard !authoringFlowResponses.isEmpty else {
            throw PackageAuthoringStoreFixtureError.unconfiguredResponse
        }
        return try authoringFlowResponses.removeFirst().get()
    }

    /// Dequeues the next remix response.
    private func nextRemixResponse() throws -> AteliaPackageRemixResponse {
        guard !remixResponses.isEmpty else {
            throw PackageAuthoringStoreFixtureError.unconfiguredResponse
        }
        return try remixResponses.removeFirst().get()
    }

    /// Dequeues the next publication response.
    private func nextPublicationResponse() throws -> AteliaPackagePublicationResponse {
        guard !publicationResponses.isEmpty else {
            throw PackageAuthoringStoreFixtureError.unconfiguredResponse
        }
        return try publicationResponses.removeFirst().get()
    }

    /// Dequeues the next registry-submission response.
    private func nextRegistrySubmissionResponse() throws -> AteliaPackageRegistrySubmissionResponse {
        guard !registrySubmissionResponses.isEmpty else {
            throw PackageAuthoringStoreFixtureError.unconfiguredResponse
        }
        return try registrySubmissionResponses.removeFirst().get()
    }
}

/// Errors thrown by the authoring store test fixture.
private enum PackageAuthoringStoreFixtureError: Error {
    case unconfiguredResponse
}

/// Builds protocol metadata for an authoring capability.
private func packageAuthoringMetadata(_ capability: String) -> AteliaProtocolMetadata {
    AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: [capability]
    )
}

/// Builds a reusable GitHub source reference fixture.
private func sourceReference() -> AteliaPackageGitHubSourceReference {
    AteliaPackageGitHubSourceReference(
        repository: "atelia-labs/atelia",
        ref: "main",
        manifestPath: "packages/review/aep.yaml",
        manifestDigest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        artifactDigests: [
            "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        ]
    )
}

/// Builds a reusable authoring flow fixture.
private func authoringFlow(
    packageId: String = "com.example.review.extension",
    sourceClass: AteliaPackageSourceClass = .workspaceLocal,
    source: AteliaPackageGitHubSourceReference? = sourceReference(),
    steps: [AteliaPackageAuthoringFlowStep] = [
        AteliaPackageAuthoringFlowStep(
            id: .inspect,
            title: "Inspect package",
            state: .complete
        ),
        AteliaPackageAuthoringFlowStep(
            id: .publish,
            title: "Submit registry",
            state: .requiresConsent,
            requiresExplicitConsent: true
        )
    ],
    publicationPlan: AteliaPackagePublicationPlan? = AteliaPackagePublicationPlan(
        visibility: .privateRemix,
        sourceClass: .workspaceLocal,
        source: sourceReference(),
        requiresRegistrySubmission: true,
        productionInstallable: false
    )
) -> AteliaPackageAuthoringFlow {
    AteliaPackageAuthoringFlow(
        packageId: packageId,
        sourceClass: sourceClass,
        source: source,
        steps: steps,
        publicationPlan: publicationPlan
    )
}

/// Verifies load delegates request/session, caches metadata, and exposes derived flow state.
@Test func loadCachesAuthoringFlowAndDerivedState() async throws {
    let flow = authoringFlow(
        packageId: "com.example.review.extension",
        sourceClass: .verifiedRegistry,
        source: sourceReference(),
        steps: [
            AteliaPackageAuthoringFlowStep(
                id: .install,
                title: "Install package",
                state: .complete
            ),
            AteliaPackageAuthoringFlowStep(
                id: .registrySearch,
                title: "Search registry",
                state: .requiresConsent,
                requiresExplicitConsent: true
            )
        ]
    )
    let response = AteliaPackageAuthoringFlowResponse(
        metadata: packageAuthoringMetadata("extensions.authoring-flow.v1"),
        flow: flow
    )
    let request = AteliaPackageAuthoringFlowRequest(
        packageId: "com.example.review.extension",
        includePrivateSteps: false
    )
    let session = AteliaSession()
    let client = PackageAuthoringStoreClientFixture(authoringFlowResponses: [.success(response)])
    let store = AteliaPackageAuthoringStore(client: client, session: session)

    let loadedFlow = try await store.load(request: request)

    #expect(loadedFlow == flow)
    #expect(await client.lastAuthoringFlowRequest == request)
    #expect(await client.authoringFlowSession == session)
    #expect(await store.authoringFlowResponse == response)
    #expect(await store.metadata == response.metadata)
    #expect(await store.flow == response.flow)
    #expect(await store.sourceClass == response.flow.sourceClass)
    #expect(await store.source == response.flow.source)
    #expect(await store.publicationPlan == response.flow.publicationPlan)
    #expect(await store.steps == response.flow.steps)
    #expect(await store.stepsRequiringConsent == [response.flow.steps[1]])
}

/// Verifies remix, publication, and registry submission propagate inputs and cache envelopes.
@Test func flowsAndRegistrySubmissionRefreshLatestMetadataAndState() async throws {
    let remixFlow = authoringFlow(
        packageId: "com.example.review.extension",
        sourceClass: .workspaceLocal,
        steps: [AteliaPackageAuthoringFlowStep(id: .remix, title: "Remix package", state: .inProgress)]
    )
    let preparedPublicationFlow = authoringFlow(
        packageId: "com.example.review.extension",
        sourceClass: .bundledOfficial,
        steps: [AteliaPackageAuthoringFlowStep(id: .publish, title: "Publish package", state: .blocked)]
    )
    let authoringResponse = AteliaPackageAuthoringFlowResponse(
        metadata: packageAuthoringMetadata("extensions.authoring-flow.v1"),
        flow: authoringFlow(
            packageId: "com.example.review.extension",
            sourceClass: .verifiedRegistry,
            steps: [AteliaPackageAuthoringFlowStep(id: .inspect, title: "Inspect package", state: .available)]
        )
    )
    let remixResponse = AteliaPackageRemixResponse(
        metadata: packageAuthoringMetadata("extensions.remix.v1"),
        flow: remixFlow
    )
    let publicationResponse = AteliaPackagePublicationResponse(
        metadata: packageAuthoringMetadata("extensions.publication.v1"),
        flow: preparedPublicationFlow
    )
    let registryResponse = AteliaPackageRegistrySubmissionResponse(
        metadata: packageAuthoringMetadata("extensions.registry-submission.v1"),
        packageId: "com.example.review.extension",
        state: .accepted,
        message: "queued",
        flow: nil
    )

    let loadRequest = AteliaPackageAuthoringFlowRequest(packageId: "com.example.review.extension")
    let remixRequest = AteliaPackageRemixRequest(
        packageId: "com.example.review.extension",
        sourceClass: .workspaceLocal,
        source: sourceReference()
    )
    let publicationRequest = AteliaPackagePublicationRequest(
        packageId: "com.example.review.extension",
        sourceClass: .bundledOfficial,
        source: sourceReference(),
        visibility: .publicSearchable,
        requiresRegistrySubmission: true,
        productionInstallable: false
    )
    let registryRequest = AteliaPackageRegistrySubmissionRequest(
        packageId: "com.example.review.extension",
        state: .accepted,
        note: "approved"
    )

    let session = AteliaSession()
    let client = PackageAuthoringStoreClientFixture(
        authoringFlowResponses: [.success(authoringResponse)],
        remixResponses: [.success(remixResponse)],
        publicationResponses: [.success(publicationResponse)],
        registrySubmissionResponses: [.success(registryResponse)]
    )
    let store = AteliaPackageAuthoringStore(client: client, session: session)

    _ = try await store.load(request: loadRequest)
    let remixed = try await store.remix(request: remixRequest)
    let preparedFlow = try await store.preparePublication(request: publicationRequest)
    let registryState = try await store.submitRegistry(request: registryRequest)

    #expect(remixed == remixResponse.flow)
    #expect(preparedFlow == publicationResponse.flow)
    #expect(registryState == registryResponse.state)
    #expect(await client.lastRemixRequest == remixRequest)
    #expect(await client.lastPublicationRequest == publicationRequest)
    #expect(await client.lastRegistrySubmissionRequest == registryRequest)
    #expect(await client.remixSession == session)
    #expect(await client.publicationSession == session)
    #expect(await client.registrySubmissionSession == session)
    #expect(await store.remixResponse == remixResponse)
    #expect(await store.publicationResponse == publicationResponse)
    #expect(await store.registrySubmissionResponse == registryResponse)
    #expect(await store.sourceClass == preparedFlow.sourceClass)
    #expect(await store.steps == preparedFlow.steps)
    #expect(await store.registrySubmissionState == .accepted)
    #expect(await store.metadata == packageAuthoringMetadata("extensions.registry-submission.v1"))
    #expect(await store.flow == preparedFlow)

    let snapshot = await store.snapshot()
    #expect(snapshot.authoringFlowResponse == authoringResponse)
    #expect(snapshot.remixResponse == remixResponse)
    #expect(snapshot.publicationResponse == publicationResponse)
    #expect(snapshot.registrySubmissionResponse == registryResponse)
    #expect(snapshot.metadata == packageAuthoringMetadata("extensions.registry-submission.v1"))
    #expect(snapshot.flow == preparedFlow)
    #expect(snapshot.steps == preparedFlow.steps)
    #expect(snapshot.stepsRequiringConsent == preparedFlow.stepsRequiringConsent)
    #expect(snapshot.publicationPlan == preparedFlow.publicationPlan)
    #expect(snapshot.sourceClass == preparedFlow.sourceClass)
    #expect(snapshot.source == preparedFlow.source)
    #expect(snapshot.registrySubmissionState == .accepted)
}

/// Verifies optional registry-submission flow data updates only flow when present.
@Test func registrySubmissionOptionalFlowUpdatesFlowWhenPresentAndSkipsWhenAbsent() async throws {
    let initialFlow = authoringFlow(packageId: "com.example.review.extension")
    let loadResponse = AteliaPackageAuthoringFlowResponse(
        metadata: packageAuthoringMetadata("extensions.authoring-flow.v1"),
        flow: initialFlow
    )
    let registryResponseWithoutFlow = AteliaPackageRegistrySubmissionResponse(
        metadata: packageAuthoringMetadata("extensions.registry-submission.v1"),
        packageId: "com.example.review.extension",
        state: .submitted,
        message: nil,
        flow: nil
    )
    let registryResponseWithFlow = AteliaPackageRegistrySubmissionResponse(
        metadata: packageAuthoringMetadata("extensions.registry-submission.v2"),
        packageId: "com.example.review.extension",
        state: .accepted,
        message: "accepted",
        flow: authoringFlow(
            packageId: "com.example.review.extension",
            sourceClass: .verifiedRegistry,
            steps: [AteliaPackageAuthoringFlowStep(id: .registrySearch, title: "Check registry", state: .available)]
        )
    )
    let requestWithoutFlow = AteliaPackageRegistrySubmissionRequest(
        packageId: "com.example.review.extension",
        state: .submitted
    )
    let requestWithFlow = AteliaPackageRegistrySubmissionRequest(
        packageId: "com.example.review.extension",
        state: .accepted
    )
    let client = PackageAuthoringStoreClientFixture(
        authoringFlowResponses: [.success(loadResponse)],
        registrySubmissionResponses: [
            .success(registryResponseWithoutFlow),
            .success(registryResponseWithFlow)
        ]
    )
    let store = AteliaPackageAuthoringStore(
        client: client,
        session: AteliaSession()
    )

    _ = try await store.load(request: AteliaPackageAuthoringFlowRequest(packageId: "com.example.review.extension"))
    _ = try await store.submitRegistry(request: requestWithoutFlow)

    #expect(await store.flow == initialFlow)
    #expect(await store.registrySubmissionResponse == registryResponseWithoutFlow)
    #expect(await store.registrySubmissionState == .submitted)
    #expect(await store.metadata == packageAuthoringMetadata("extensions.registry-submission.v1"))

    let acceptedFlow = try await store.submitRegistry(request: requestWithFlow)

    #expect(acceptedFlow == .accepted)
    #expect(await store.registrySubmissionResponse == registryResponseWithFlow)
    #expect(await store.registrySubmissionState == .accepted)
    #expect(await store.flow?.id == registryResponseWithFlow.flow?.id)
    #expect(await store.sourceClass == .verifiedRegistry)
    #expect(await store.steps == registryResponseWithFlow.flow?.steps ?? [])
    #expect(await client.lastRegistrySubmissionRequest == requestWithFlow)
}

/// Verifies clear empties cached state and derived values.
@Test func clearDiscardsAuthoringStoreCache() async throws {
    let response = AteliaPackageAuthoringFlowResponse(
        metadata: packageAuthoringMetadata("extensions.authoring-flow.v1"),
        flow: authoringFlow()
    )
    let client = PackageAuthoringStoreClientFixture(
        authoringFlowResponses: [.success(response)]
    )
    let store = AteliaPackageAuthoringStore(client: client, session: AteliaSession())

    _ = try await store.load(request: AteliaPackageAuthoringFlowRequest(packageId: "com.example.review.extension"))
    #expect(await store.flow == response.flow)
    #expect(await store.metadata == response.metadata)

    await store.clear()

    #expect(await store.flow == nil)
    #expect(await store.steps.isEmpty)
    #expect(await store.stepsRequiringConsent.isEmpty)
    #expect(await store.publicationPlan == nil)
    #expect(await store.publicationResponse == nil)
    #expect(await store.remixResponse == nil)
    #expect(await store.authoringFlowResponse == nil)
    #expect(await store.registrySubmissionResponse == nil)
    #expect(await store.metadata == nil)
    #expect(await store.sourceClass == nil)
    #expect(await store.source == nil)
    #expect(await store.registrySubmissionState == nil)

    let snapshot = await store.snapshot()
    #expect(snapshot.authoringFlowResponse == nil)
    #expect(snapshot.remixResponse == nil)
    #expect(snapshot.publicationResponse == nil)
    #expect(snapshot.registrySubmissionResponse == nil)
    #expect(snapshot.metadata == nil)
    #expect(snapshot.flow == nil)
    #expect(snapshot.steps.isEmpty)
    #expect(snapshot.stepsRequiringConsent.isEmpty)
    #expect(snapshot.publicationPlan == nil)
    #expect(snapshot.sourceClass == nil)
    #expect(snapshot.source == nil)
    #expect(snapshot.registrySubmissionState == nil)
}
