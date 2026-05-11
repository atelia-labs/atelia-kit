import Foundation
import Testing
@testable import AteliaKit

private actor PackageTrustIndexClientFixture: AteliaClient {
    private let response: AteliaPackageTrustIndexResponse
    private var callCount = 0

    init(response: AteliaPackageTrustIndexResponse) {
        self.response = response
    }

    func packageTrustIndexResponse(for session: AteliaSession) async throws -> AteliaPackageTrustIndexResponse {
        _ = session
        callCount += 1
        return response
    }

    func calls() -> Int {
        callCount
    }
}

private actor ControllablePackageTrustIndexClient: AteliaClient {
    private var continuations: [CheckedContinuation<AteliaPackageTrustIndexResponse, Never>] = []

    func packageTrustIndexResponse(for session: AteliaSession) async throws -> AteliaPackageTrustIndexResponse {
        _ = session
        return await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func waitForRequests(_ count: Int) async throws {
        while continuations.count < count {
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    func respond(to index: Int, with response: AteliaPackageTrustIndexResponse) {
        continuations[index].resume(returning: response)
    }
}

private let packageTrustIndexFixtureResponse = AteliaPackageTrustIndexResponse(
    metadata: AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: ["package_trust_index.v1"]
    ),
    packages: [
        AteliaPackageTrustIndexEntry(
            packageId: "com.example.alpha",
            version: "1.2.3",
            status: .installed,
            boundary: .official,
            manifestDigest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            artifactDigest: "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        ),
        AteliaPackageTrustIndexEntry(
            packageId: "com.example.beta",
            version: "2.0.0",
            status: .blocked,
            boundary: .thirdParty,
            manifestDigest: "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
            artifactDigest: "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
            block: AteliaPackageTrustIndexEntry.Block(
                reason: .policyViolation,
                key: .extensionId("com.example.beta")
            )
        )
    ]
)

private func packageTrustIndexResponse(packageId: String) -> AteliaPackageTrustIndexResponse {
    AteliaPackageTrustIndexResponse(
        metadata: AteliaProtocolMetadata(
            protocolVersion: "1.0.0",
            daemonVersion: "0.2.0",
            storageVersion: "0.2.0",
            capabilities: ["package_trust_index.v1"]
        ),
        packages: [
            AteliaPackageTrustIndexEntry(
                packageId: packageId,
                version: "1.0.0",
                status: .installed,
                boundary: .official
            )
        ]
    )
}

/// Verifies reload fetches the trust index once and keeps the response metadata.
@Test func reloadFetchesOnceAndPreservesMetadata() async throws {
    let client = PackageTrustIndexClientFixture(response: packageTrustIndexFixtureResponse)
    let session = AteliaSession()
    let store = AteliaPackageTrustIndexStore(client: client, session: session)

    try await store.reload()

    #expect(await client.calls() == 1)
    #expect(await store.response == packageTrustIndexFixtureResponse)
    #expect(await store.metadata == packageTrustIndexFixtureResponse.metadata)
}

/// Verifies the store exposes packages and supports package-id lookup.
@Test func storeExposesPackagesAndPackageLookup() async throws {
    let client = PackageTrustIndexClientFixture(response: packageTrustIndexFixtureResponse)
    let session = AteliaSession()
    let store = AteliaPackageTrustIndexStore(client: client, session: session)

    try await store.reload()

    #expect(await store.packages == packageTrustIndexFixtureResponse.packages)
    #expect(await store.package(id: "com.example.alpha") == packageTrustIndexFixtureResponse.packages[0])
    #expect(await store.package(id: "com.example.beta") == packageTrustIndexFixtureResponse.packages[1])
    #expect(await store.package(id: "com.example.missing") == nil)
}

/// Verifies an older in-flight reload cannot overwrite a newer completed reload.
@Test func staleReloadDoesNotOverwriteNewerReload() async throws {
    let client = ControllablePackageTrustIndexClient()
    let store = AteliaPackageTrustIndexStore(client: client, session: AteliaSession())
    let olderResponse = packageTrustIndexResponse(packageId: "com.example.older")
    let newerResponse = packageTrustIndexResponse(packageId: "com.example.newer")

    let olderReload = Task {
        try await store.reload()
    }
    try await client.waitForRequests(1)

    let newerReload = Task {
        try await store.reload()
    }
    try await client.waitForRequests(2)

    await client.respond(to: 1, with: newerResponse)
    try await newerReload.value
    await client.respond(to: 0, with: olderResponse)
    try await olderReload.value

    #expect(await store.response == newerResponse)
    #expect(await store.package(id: "com.example.older") == nil)
    #expect(await store.package(id: "com.example.newer") == newerResponse.packages[0])
}

/// Verifies clear prevents an older in-flight reload from repopulating the cache.
@Test func clearInvalidatesInFlightReload() async throws {
    let client = ControllablePackageTrustIndexClient()
    let store = AteliaPackageTrustIndexStore(client: client, session: AteliaSession())
    let response = packageTrustIndexResponse(packageId: "com.example.pending")

    let reload = Task {
        try await store.reload()
    }
    try await client.waitForRequests(1)

    await store.clear()
    await client.respond(to: 0, with: response)
    try await reload.value

    #expect(await store.response == nil)
    #expect(await store.packages.isEmpty)
    #expect(await store.package(id: "com.example.pending") == nil)
}

/// Verifies clear removes the cached response and derived package index.
@Test func clearResetsCachedState() async throws {
    let client = PackageTrustIndexClientFixture(response: packageTrustIndexFixtureResponse)
    let session = AteliaSession()
    let store = AteliaPackageTrustIndexStore(client: client, session: session)

    try await store.reload()
    await store.clear()

    #expect(await store.response == nil)
    #expect(await store.metadata == nil)
    #expect(await store.packages.isEmpty)
    #expect(await store.package(id: "com.example.alpha") == nil)
}
