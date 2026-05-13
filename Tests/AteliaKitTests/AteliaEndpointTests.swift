import Foundation
import Testing
@testable import AteliaKit

private actor HealthOnlyClient: AteliaClient {
    /// Number of health calls observed by the fixture.
    private var healthCallCount = 0
    /// Number of repertoire calls observed by the fixture.
    private var repertoireCallCount = 0

    /// Returns a degraded health response for default-status tests.
    func health(for session: AteliaSession) async throws -> AteliaHealthResponse {
        _ = session
        healthCallCount += 1
        return AteliaHealthResponse(
            daemonStatus: .degraded,
            daemonVersion: "0.0.0",
            protocolVersion: "0.1.0",
            storageVersion: "0.0.0",
            storageStatus: .unavailable,
            capabilities: [],
            betaState: nil
        )
    }

    /// Returns an empty repertoire and records the call.
    func repertoire(for session: AteliaSession) async throws -> [AteliaRepertoireEntry] {
        _ = session
        repertoireCallCount += 1
        return []
    }

    /// Returns observed protocol method call counts.
    func callCounts() -> (health: Int, repertoire: Int) {
        (healthCallCount, repertoireCallCount)
    }
}

/// Minimal conformer used to verify default protocol fallback behavior.
private actor StatusOnlyClient: AteliaClient {
    /// Number of local status calls observed by the fixture.
    private var statusCallCount = 0

    /// Returns the local status implementation used by fallback tests.
    func status(for session: AteliaSession) async throws -> SecretaryStatus {
        _ = session
        statusCallCount += 1
        return SecretaryStatus(phase: .ready, message: "local placeholder")
    }

    /// Returns the observed local status call count.
    func callCount() -> Int {
        statusCallCount
    }
}

/// Minimal conformer used to verify trust-index request fallback behavior.
private actor UnfilteredPackageTrustIndexClient: AteliaClient {
    /// Number of unfiltered trust-index calls observed by the fixture.
    private var trustIndexCallCount = 0

    /// Returns an empty package trust index for default-request fallback tests.
    func packageTrustIndexResponse(for session: AteliaSession) async throws -> AteliaPackageTrustIndexResponse {
        _ = session
        trustIndexCallCount += 1
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

    /// Returns the observed unfiltered trust-index call count.
    func callCount() -> Int {
        trustIndexCallCount
    }
}

/// Minimal conformer used to verify default request fallback through the entry API.
private actor EntriesOnlyPackageTrustIndexClient: AteliaClient {
    /// Number of entry trust-index calls observed by the fixture.
    private var trustIndexCallCount = 0

    /// Returns one package trust index entry for default-request fallback tests.
    func packageTrustIndex(for session: AteliaSession) async throws -> [AteliaPackageTrustIndexEntry] {
        _ = session
        trustIndexCallCount += 1
        return [
            AteliaPackageTrustIndexEntry(
                packageId: "com.example.entries",
                version: "1.0.0",
                status: .installed,
                boundary: .official
            )
        ]
    }

    /// Returns the observed entry trust-index call count.
    func callCount() -> Int {
        trustIndexCallCount
    }
}

/// Verifies endpoint configuration builds the expected base URL.
@Test func endpointBuildsBaseURL() {
    let endpoint = AteliaEndpoint(host: "127.0.0.1", port: 8787, usesTLS: false)
    #expect(endpoint.baseURL.absoluteString == "http://127.0.0.1:8787")
}

/// Verifies running daemon health maps to the starting Secretary phase.
@Test func healthResponseMapsRunningToStartingSecretaryPhase() {
    let health = AteliaHealthResponse(
        daemonStatus: .running,
        daemonVersion: "0.1.0",
        protocolVersion: "0.1.0",
        storageVersion: "0.1.0",
        storageStatus: .ready,
        capabilities: ["health.v1", "jobs.v1"],
        betaState: .init(
            scope: "workspace",
            durability: "session",
            restartSemantics: "preserved",
            limits: ["beta-slice"]
        )
    )

    #expect(health.secretaryStatus.phase == .starting)
    #expect(health.secretaryStatus.message == nil)
}

/// Verifies ready daemon health maps to the ready Secretary phase.
@Test func healthResponseMapsReadyToReadySecretaryPhase() {
    let health = AteliaHealthResponse(
        daemonStatus: .ready,
        daemonVersion: "0.1.0",
        protocolVersion: "0.1.0",
        storageVersion: "0.1.0",
        storageStatus: .ready,
        capabilities: []
    )

    #expect(health.secretaryStatus.phase == .ready)
    #expect(health.secretaryStatus.message == nil)
}

/// Verifies canonical health JSON decodes from protocol snake_case keys.
@Test func healthResponseDecodesCanonicalSnakeCaseProtocolJSON() throws {
    let data = #"""
    {
      "daemon_status": "degraded",
      "daemon_version": "1.2.3",
      "protocol_version": "2.0.0",
      "storage_version": "4.5.6",
      "storage_status": "read_only",
      "capabilities": ["health.v1", "beta.v1"],
      "beta_state": {
        "scope": "workspace",
        "durability": "session",
        "restart_semantics": "preserved",
        "limits": ["beta-slice"]
      }
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaHealthResponse.self, from: data)

    #expect(decoded == AteliaHealthResponse(
        daemonStatus: .degraded,
        daemonVersion: "1.2.3",
        protocolVersion: "2.0.0",
        storageVersion: "4.5.6",
        storageStatus: .readOnly,
        capabilities: ["health.v1", "beta.v1"],
        betaState: .init(
            scope: "workspace",
            durability: "session",
            restartSemantics: "preserved",
            limits: ["beta-slice"]
        )
    ))
}

/// Verifies repertoire availability values round-trip through Codable.
@Test func repertoireEntryRoundTripsAvailability() throws {
    let entry = AteliaRepertoireEntry(
        id: "tool.fs.write",
        label: "Write file",
        declaredEffect: "Writes to the workspace",
        riskTier: .r2,
        scope: .workspace,
        invocationStyle: .sync,
        availability: .unavailable(reason: "missing capability"),
        visibility: .both,
        permission: false,
        runnableNow: false
    )

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try encoder.encode(entry)
    let decoded = try decoder.decode(AteliaRepertoireEntry.self, from: data)

    #expect(decoded == entry)
}

/// Verifies canonical repertoire JSON decodes from protocol snake_case keys.
@Test func repertoireEntryDecodesCanonicalSnakeCaseProtocolJSON() throws {
    let data = #"""
    {
      "id": "tool.fs.write",
      "label": "Write file",
      "declared_effect": "Writes to the workspace",
      "risk_tier": "r2",
      "scope": "workspace",
      "invocation_style": "sync",
      "availability": {
        "state": "unavailable",
        "reason": "missing capability"
      },
      "visibility": "both",
      "permission": false,
      "runnable_now": false
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaRepertoireEntry.self, from: data)

    #expect(decoded == AteliaRepertoireEntry(
        id: "tool.fs.write",
        label: "Write file",
        declaredEffect: "Writes to the workspace",
        riskTier: .r2,
        scope: .workspace,
        invocationStyle: .sync,
        availability: .unavailable(reason: "missing capability"),
        visibility: .both,
        permission: false,
        runnableNow: false
    ))
}

/// Verifies default request fallback does not silently ignore real trust-index filters.
@Test func defaultTrustIndexRequestFallsBackToUnfilteredConformer() async throws {
    let client = UnfilteredPackageTrustIndexClient()
    let session = AteliaSession()

    let response = try await client.packageTrustIndexResponse(
        for: session,
        request: AteliaPackageTrustIndexRequest()
    )

    #expect(response.packages.isEmpty)
    #expect(response.metadata.capabilities == ["package_trust_index.v1"])
    #expect(await client.callCount() == 1)

    await #expect(throws: AteliaClientError.packageTrustIndexUnavailable) {
        _ = try await client.packageTrustIndexResponse(
            for: session,
            request: AteliaPackageTrustIndexRequest(includeBlocked: false, discoveryOnly: true)
        )
    }
}

/// Verifies default request fallback reaches conformers that only provide entries.
@Test func defaultTrustIndexEntryRequestFallsBackToUnfilteredConformer() async throws {
    let client = EntriesOnlyPackageTrustIndexClient()
    let session = AteliaSession()

    let entries = try await client.packageTrustIndex(
        for: session,
        request: AteliaPackageTrustIndexRequest()
    )

    #expect(entries.map(\.packageId) == ["com.example.entries"])
    #expect(await client.callCount() == 1)

    await #expect(throws: AteliaClientError.packageTrustIndexUnavailable) {
        _ = try await client.packageTrustIndex(
            for: session,
            request: AteliaPackageTrustIndexRequest(includeBlocked: false, discoveryOnly: true)
        )
    }
}

/// Verifies the local client exposes placeholder typed protocol surfaces.
@Test func localClientExposesTypedProtocolSurface() async throws {
    let client = LocalAteliaClient()
    let session = AteliaSession()
    let renderRequest = AteliaToolOutputRenderRequest(
        toolResult: AteliaToolResultRef(
            toolResultId: "tool_result_123",
            toolInvocationId: "tool_invocation_123",
            jobId: "job_123",
            repositoryId: "repo_123",
            contentType: "application/json"
        ),
        format: .json
    )

    let health = try await client.health(for: session)
    #expect(health.daemonStatus == .starting)
    #expect(health.capabilities.isEmpty)

    let repertoire = try await client.repertoire(for: session)
    #expect(repertoire.isEmpty)

    let trustIndex = try await client.packageTrustIndexResponse(for: session)
    #expect(trustIndex.packages.isEmpty)
    #expect(trustIndex.metadata.protocolVersion == "0.1.0")
    #expect(trustIndex.metadata.capabilities == ["package_trust_index.v1"])

    let trustIndexEntries = try await client.packageTrustIndex(for: session)
    #expect(trustIndexEntries.isEmpty)

    let discoveryTrustIndex = try await client.packageTrustIndexResponse(
        for: session,
        request: AteliaPackageTrustIndexRequest(includeBlocked: false, discoveryOnly: true)
    )
    #expect(discoveryTrustIndex.packages.isEmpty)
    #expect(discoveryTrustIndex.metadata.capabilities == ["package_trust_index.v1"])

    let status = try await client.status(for: session)
    #expect(status.phase == .unknown)
    #expect(status.message == "Protocol transport is not implemented yet.")

    await #expect(throws: AteliaClientError.packageValidationUnavailable) {
        _ = try await client.packageValidationResponse(
            for: session,
            request: AteliaPackageValidationRequest(manifest: AteliaPackageManifest())
        )
    }
    await #expect(throws: AteliaClientError.packageValidationUnavailable) {
        _ = try await client.packageValidation(
            for: session,
            request: AteliaPackageValidationRequest(manifest: AteliaPackageManifest())
        )
    }
    await #expect(throws: AteliaClientError.packageRollbackUnavailable) {
        _ = try await client.packageRollback(for: session, packageId: "com.example.package")
    }

    await #expect(throws: AteliaClientError.packageInstallUnavailable) {
        _ = try await client.packageInstallResponse(
            for: session,
            request: AteliaPackageLifecycleRequest(manifest: AteliaPackageManifest())
        )
    }
    await #expect(throws: AteliaClientError.packageUpdateUnavailable) {
        _ = try await client.packageUpdateResponse(
            for: session,
            request: AteliaPackageLifecycleRequest(manifest: AteliaPackageManifest())
        )
    }
    await #expect(throws: AteliaClientError.packageStatusUnavailable) {
        _ = try await client.packageStatusResponse(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageInspectUnavailable) {
        _ = try await client.packageInspectResponse(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageInspectUnavailable) {
        _ = try await client.packageInspect(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageListUnavailable) {
        _ = try await client.packageListResponse(for: session, request: AteliaPackageListRequest())
    }
    await #expect(throws: AteliaClientError.packageDisableUnavailable) {
        _ = try await client.packageDisableResponse(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageEnableUnavailable) {
        _ = try await client.packageEnableResponse(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageRemoveUnavailable) {
        _ = try await client.packageRemoveResponse(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageBlocklistUnavailable) {
        _ = try await client.packageBlocklistApplyResponse(
            for: session,
            request: AteliaPackageBlocklistRequest(
                entry: AteliaPackageBlocklistEntry(
                    reason: .userBlocked,
                    key: .extensionId("com.example.package")
                )
            )
        )
    }
    await #expect(throws: AteliaClientError.packageBlocklistUnavailable) {
        _ = try await client.packageBlocklistListResponse(for: session)
    }
    await #expect(throws: AteliaClientError.packageAuthoringFlowUnavailable) {
        _ = try await client.packageAuthoringFlowResponse(
            for: session,
            request: AteliaPackageAuthoringFlowRequest(packageId: "com.example.package")
        )
    }
    await #expect(throws: AteliaClientError.packageRemixUnavailable) {
        _ = try await client.packageRemixResponse(
            for: session,
            request: AteliaPackageRemixRequest(
                packageId: "com.example.package",
                sourceClass: .workspaceLocal
            )
        )
    }
    await #expect(throws: AteliaClientError.packagePublicationUnavailable) {
        _ = try await client.packagePublicationResponse(
            for: session,
            request: AteliaPackagePublicationRequest(
                packageId: "com.example.package",
                sourceClass: .workspaceLocal,
                visibility: .privateRemix,
                requiresRegistrySubmission: false,
                productionInstallable: false
            )
        )
    }
    await #expect(throws: AteliaClientError.packageRegistrySubmissionUnavailable) {
        _ = try await client.packageRegistrySubmissionResponse(
            for: session,
            request: AteliaPackageRegistrySubmissionRequest(
                packageId: "com.example.package",
                state: .submitted
            )
        )
    }

    await #expect(throws: AteliaClientError.toolOutputRenderUnavailable) {
        _ = try await client.renderToolOutputResponse(for: session, request: renderRequest)
    }
    await #expect(throws: AteliaClientError.toolOutputRenderUnavailable) {
        _ = try await client.renderToolOutput(for: session, request: renderRequest)
    }
}

/// Verifies default status derives from health when no explicit status exists.
@Test func defaultStatusDerivesFromHealthSnapshot() async throws {
    let client = HealthOnlyClient()
    let session = AteliaSession()

    let status = try await client.status(for: session)
    let counts = await client.callCounts()

    #expect(counts.health == 1)
    #expect(counts.repertoire == 0)
    #expect(status.phase == .degraded)
    #expect(status.message == nil)
}

/// Verifies local placeholder status-only conformers retain fallback behavior.
@Test func statusOnlyConformerUsesLocalStatusAndUnavailableCapabilityFallbacks() async throws {
    let client = StatusOnlyClient()
    let session = AteliaSession()
    let renderRequest = AteliaToolOutputRenderRequest(
        toolResult: AteliaToolResultRef(
            toolResultId: "tool_result_123",
            toolInvocationId: "tool_invocation_123",
            jobId: "job_123",
            repositoryId: "repo_123",
            contentType: "application/json"
        ),
        format: .text
    )

    let status = try await client.status(for: session)
    let callCountBeforeFallbackChecks = await client.callCount()

    #expect(callCountBeforeFallbackChecks == 1)
    #expect(status.phase == .ready)
    #expect(status.message == "local placeholder")

    await #expect(throws: AteliaClientError.healthUnavailable) {
        _ = try await client.health(for: session)
    }

    await #expect(throws: AteliaClientError.repertoireUnavailable) {
        _ = try await client.repertoire(for: session)
    }

    await #expect(throws: AteliaClientError.packageTrustIndexUnavailable) {
        _ = try await client.packageTrustIndex(for: session)
    }

    await #expect(throws: AteliaClientError.packageRollbackUnavailable) {
        _ = try await client.packageRollbackResponse(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageValidationUnavailable) {
        _ = try await client.packageValidationResponse(
            for: session,
            request: AteliaPackageValidationRequest(manifest: AteliaPackageManifest())
        )
    }
    await #expect(throws: AteliaClientError.packageValidationUnavailable) {
        _ = try await client.packageValidation(
            for: session,
            request: AteliaPackageValidationRequest(manifest: AteliaPackageManifest())
        )
    }
    await #expect(throws: AteliaClientError.packageInstallUnavailable) {
        _ = try await client.packageInstall(
            for: session,
            request: AteliaPackageLifecycleRequest(manifest: AteliaPackageManifest())
        )
    }
    await #expect(throws: AteliaClientError.packageUpdateUnavailable) {
        _ = try await client.packageUpdate(
            for: session,
            request: AteliaPackageLifecycleRequest(manifest: AteliaPackageManifest())
        )
    }
    await #expect(throws: AteliaClientError.packageStatusUnavailable) {
        _ = try await client.packageStatus(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageListUnavailable) {
        _ = try await client.packageList(for: session, request: AteliaPackageListRequest())
    }
    await #expect(throws: AteliaClientError.packageDisableUnavailable) {
        _ = try await client.packageDisable(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageEnableUnavailable) {
        _ = try await client.packageEnable(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageRemoveUnavailable) {
        _ = try await client.packageRemove(for: session, packageId: "com.example.package")
    }
    await #expect(throws: AteliaClientError.packageBlocklistUnavailable) {
        _ = try await client.packageBlocklistApply(
            for: session,
            request: AteliaPackageBlocklistRequest(
                entry: AteliaPackageBlocklistEntry(
                    reason: .userBlocked,
                    key: .extensionId("com.example.package")
                )
            )
        )
    }
    await #expect(throws: AteliaClientError.packageBlocklistUnavailable) {
        _ = try await client.packageBlocklistList(for: session)
    }
    await #expect(throws: AteliaClientError.packageAuthoringFlowUnavailable) {
        _ = try await client.packageAuthoringFlow(
            for: session,
            request: AteliaPackageAuthoringFlowRequest(packageId: "com.example.package")
        )
    }
    await #expect(throws: AteliaClientError.packageRemixUnavailable) {
        _ = try await client.packageRemix(
            for: session,
            request: AteliaPackageRemixRequest(
                packageId: "com.example.package",
                sourceClass: .workspaceLocal
            )
        )
    }
    await #expect(throws: AteliaClientError.packagePublicationUnavailable) {
        _ = try await client.packagePublication(
            for: session,
            request: AteliaPackagePublicationRequest(
                packageId: "com.example.package",
                sourceClass: .workspaceLocal,
                visibility: .privateRemix,
                requiresRegistrySubmission: false,
                productionInstallable: false
            )
        )
    }
    await #expect(throws: AteliaClientError.packageRegistrySubmissionUnavailable) {
        _ = try await client.packageRegistrySubmissionState(
            for: session,
            request: AteliaPackageRegistrySubmissionRequest(
                packageId: "com.example.package",
                state: .submitted
            )
        )
    }
    await #expect(throws: AteliaClientError.toolOutputRenderUnavailable) {
        _ = try await client.renderToolOutputResponse(for: session, request: renderRequest)
    }

    let callCountAfterFallbackChecks = await client.callCount()
    #expect(callCountAfterFallbackChecks == 1)
}
