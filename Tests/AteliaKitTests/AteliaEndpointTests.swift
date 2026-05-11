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

/// Minimal conformer used to verify default protocol compatibility behavior.
private actor StatusOnlyClient: AteliaClient {
    /// Number of legacy status calls observed by the fixture.
    private var statusCallCount = 0

    /// Returns the legacy status implementation used by compatibility tests.
    func status(for session: AteliaSession) async throws -> SecretaryStatus {
        _ = session
        statusCallCount += 1
        return SecretaryStatus(phase: .ready, message: "legacy")
    }

    /// Returns the observed legacy status call count.
    func callCount() -> Int {
        statusCallCount
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

/// Verifies the local client exposes placeholder typed protocol surfaces.
@Test func localClientExposesTypedProtocolSurface() async throws {
    let client = LocalAteliaClient()
    let session = AteliaSession()

    let health = try await client.health(for: session)
    #expect(health.daemonStatus == .starting)
    #expect(health.capabilities.isEmpty)

    let repertoire = try await client.repertoire(for: session)
    #expect(repertoire.isEmpty)

    let trustIndex = try await client.packageTrustIndex(for: session)
    #expect(trustIndex.isEmpty)

    let status = try await client.status(for: session)
    #expect(status.phase == .unknown)
    #expect(status.message == "Protocol transport is not implemented yet.")
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

/// Verifies legacy status-only conformers retain compatibility behavior.
@Test func statusOnlyConformerStillCompilesAndUsesLegacyStatusImplementation() async throws {
    let client = StatusOnlyClient()
    let session = AteliaSession()

    let status = try await client.status(for: session)
    let callCountBeforeUnavailableChecks = await client.callCount()

    #expect(callCountBeforeUnavailableChecks == 1)
    #expect(status.phase == .ready)
    #expect(status.message == "legacy")

    await #expect(throws: AteliaClientError.healthUnavailable) {
        _ = try await client.health(for: session)
    }

    await #expect(throws: AteliaClientError.repertoireUnavailable) {
        _ = try await client.repertoire(for: session)
    }

    await #expect(throws: AteliaClientError.packageTrustIndexUnavailable) {
        _ = try await client.packageTrustIndex(for: session)
    }

    let callCountAfterUnavailableChecks = await client.callCount()
    #expect(callCountAfterUnavailableChecks == 1)
}
