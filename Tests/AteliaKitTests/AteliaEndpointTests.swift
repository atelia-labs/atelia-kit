import Foundation
import Testing
@testable import AteliaKit

@Test func endpointBuildsBaseURL() {
    let endpoint = AteliaEndpoint(host: "127.0.0.1", port: 8787, usesTLS: false)
    #expect(endpoint.baseURL.absoluteString == "http://127.0.0.1:8787")
}

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

@Test func localClientExposesTypedProtocolSurface() async throws {
    let client = LocalAteliaClient()
    let session = AteliaSession()

    let health = try await client.health(for: session)
    #expect(health.daemonStatus == .starting)
    #expect(health.capabilities.isEmpty)

    let repertoire = try await client.repertoire(for: session)
    #expect(repertoire.isEmpty)

    let status = try await client.status(for: session)
    #expect(status.phase == .unknown)
    #expect(status.message == "Protocol transport is not implemented yet.")
}
