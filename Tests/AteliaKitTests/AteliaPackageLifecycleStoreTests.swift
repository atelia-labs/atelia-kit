import Foundation
import Testing
@testable import AteliaKit

private enum PackageLifecycleFixtureError: Error {
    case requestFailed
    case timeoutWaitingForRequests(expected: Int, actual: Int)
    case unconfiguredResponse
}

private actor PackageLifecycleClientFixture: AteliaClient {
    private var lifecycleResponses: [Result<AteliaPackageLifecycleResponse, any Error>]
    private var rollbackResponses: [Result<AteliaPackageRollbackResponse, any Error>]
    private var statusResponses: [Result<AteliaPackageStatusResponse, any Error>]
    private var listResponses: [Result<AteliaPackageListResponse, any Error>]
    private var blocklistApplyResponses: [Result<AteliaPackageBlocklistApplyResponse, any Error>]
    private var blocklistListResponses: [Result<AteliaPackageBlocklistListResponse, any Error>]

    init(
        lifecycleResponses: [Result<AteliaPackageLifecycleResponse, any Error>] = [],
        rollbackResponses: [Result<AteliaPackageRollbackResponse, any Error>] = [],
        statusResponses: [Result<AteliaPackageStatusResponse, any Error>] = [],
        listResponses: [Result<AteliaPackageListResponse, any Error>] = [],
        blocklistApplyResponses: [Result<AteliaPackageBlocklistApplyResponse, any Error>] = [],
        blocklistListResponses: [Result<AteliaPackageBlocklistListResponse, any Error>] = []
    ) {
        self.lifecycleResponses = lifecycleResponses
        self.rollbackResponses = rollbackResponses
        self.statusResponses = statusResponses
        self.listResponses = listResponses
        self.blocklistApplyResponses = blocklistApplyResponses
        self.blocklistListResponses = blocklistListResponses
    }

    func packageInstallResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageInstallResponse {
        _ = session
        _ = request
        return try nextLifecycleResponse()
    }

    func packageUpdateResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageUpdateResponse {
        _ = session
        _ = request
        return try nextLifecycleResponse()
    }

    func packageDisableResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageDisableResponse {
        _ = session
        _ = packageId
        return try nextLifecycleResponse()
    }

    func packageEnableResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageEnableResponse {
        _ = session
        _ = packageId
        return try nextLifecycleResponse()
    }

    func packageRemoveResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRemoveResponse {
        _ = session
        _ = packageId
        return try nextLifecycleResponse()
    }

    func packageRollbackResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRollbackResponse {
        _ = session
        _ = packageId
        guard !rollbackResponses.isEmpty else {
            throw PackageLifecycleFixtureError.unconfiguredResponse
        }
        return try rollbackResponses.removeFirst().get()
    }

    func packageStatusResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageStatusResponse {
        _ = session
        _ = packageId
        guard !statusResponses.isEmpty else {
            throw PackageLifecycleFixtureError.unconfiguredResponse
        }
        return try statusResponses.removeFirst().get()
    }

    func packageListResponse(
        for session: AteliaSession,
        request: AteliaPackageListRequest
    ) async throws -> AteliaPackageListResponse {
        _ = session
        _ = request
        guard !listResponses.isEmpty else {
            throw PackageLifecycleFixtureError.unconfiguredResponse
        }
        return try listResponses.removeFirst().get()
    }

    func packageBlocklistApplyResponse(
        for session: AteliaSession,
        request: AteliaPackageBlocklistRequest
    ) async throws -> AteliaPackageBlocklistApplyResponse {
        _ = session
        _ = request
        guard !blocklistApplyResponses.isEmpty else {
            throw PackageLifecycleFixtureError.unconfiguredResponse
        }
        return try blocklistApplyResponses.removeFirst().get()
    }

    func packageBlocklistListResponse(
        for session: AteliaSession
    ) async throws -> AteliaPackageBlocklistListResponse {
        _ = session
        guard !blocklistListResponses.isEmpty else {
            throw PackageLifecycleFixtureError.unconfiguredResponse
        }
        return try blocklistListResponses.removeFirst().get()
    }

    private func nextLifecycleResponse() throws -> AteliaPackageLifecycleResponse {
        guard !lifecycleResponses.isEmpty else {
            throw PackageLifecycleFixtureError.unconfiguredResponse
        }
        return try lifecycleResponses.removeFirst().get()
    }
}

private actor ControllablePackageLifecycleClientFixture: AteliaClient {
    enum RequestKind {
        case list
        case install
        case status
    }

    private var listContinuations: [CheckedContinuation<AteliaPackageListResponse, any Error>] = []
    private var installContinuations: [CheckedContinuation<AteliaPackageLifecycleResponse, any Error>] = []
    private var statusContinuations: [CheckedContinuation<AteliaPackageStatusResponse, any Error>] = []

    func packageListResponse(
        for session: AteliaSession,
        request: AteliaPackageListRequest
    ) async throws -> AteliaPackageListResponse {
        _ = session
        _ = request
        return try await withCheckedThrowingContinuation { continuation in
            listContinuations.append(continuation)
        }
    }

    func packageInstallResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageInstallResponse {
        _ = session
        _ = request
        return try await withCheckedThrowingContinuation { continuation in
            installContinuations.append(continuation)
        }
    }

    func packageStatusResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageStatusResponse {
        _ = session
        _ = packageId
        return try await withCheckedThrowingContinuation { continuation in
            statusContinuations.append(continuation)
        }
    }

    func waitForRequests(_ kind: RequestKind, count: Int, timeout: Duration = .seconds(2)) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while requestCount(kind) < count {
            guard clock.now < deadline else {
                throw PackageLifecycleFixtureError.timeoutWaitingForRequests(
                    expected: count,
                    actual: requestCount(kind)
                )
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    func respondToList(_ index: Int, with response: AteliaPackageListResponse) {
        listContinuations[index].resume(returning: response)
    }

    func failList(_ index: Int, with error: any Error) {
        listContinuations[index].resume(throwing: error)
    }

    func respondToInstall(_ index: Int, with response: AteliaPackageLifecycleResponse) {
        installContinuations[index].resume(returning: response)
    }

    func respondToStatus(_ index: Int, with response: AteliaPackageStatusResponse) {
        statusContinuations[index].resume(returning: response)
    }

    private func requestCount(_ kind: RequestKind) -> Int {
        switch kind {
        case .list:
            return listContinuations.count
        case .install:
            return installContinuations.count
        case .status:
            return statusContinuations.count
        }
    }
}

private func metadata(_ capability: String = "extensions.lifecycle.v1") -> AteliaProtocolMetadata {
    AteliaProtocolMetadata(
        protocolVersion: "1.0.0",
        daemonVersion: "0.2.0",
        storageVersion: "0.2.0",
        capabilities: [capability]
    )
}

private func packageManifest(id: String = "com.example.package") -> AteliaPackageManifest {
    AteliaPackageManifest(fields: [
        "id": .string(id),
        "version": .string("1.0.0")
    ])
}

private func lifecycleRecord(
    packageId: String,
    version: String = "1.0.0",
    status: AteliaPackageTrustIndexEntry.Status = .installed
) -> AteliaPackageLifecycleRecord {
    AteliaPackageLifecycleRecord(
        packageId: packageId,
        version: version,
        manifestDigest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        artifactDigest: "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        source: AteliaPackageTrustIndexEntry.SourceSnapshot(source: "github"),
        boundary: .thirdParty,
        status: status
    )
}

private func lifecycleResponse(packageId: String, version: String = "1.0.0") -> AteliaPackageLifecycleResponse {
    AteliaPackageLifecycleResponse(
        metadata: metadata(),
        record: lifecycleRecord(packageId: packageId, version: version)
    )
}

private func listResponse(packageIds: [String]) -> AteliaPackageListResponse {
    AteliaPackageListResponse(
        metadata: metadata("extensions.list.v1"),
        packages: packageIds.map { packageId in
            AteliaPackageStatus(packageId: packageId, record: lifecycleRecord(packageId: packageId))
        }
    )
}

/// Verifies install stores the latest lifecycle envelope and package lookup entry.
@Test func installStoresLifecycleResponseAndPackageStatus() async throws {
    let response = lifecycleResponse(packageId: "com.example.install")
    let client = PackageLifecycleClientFixture(lifecycleResponses: [.success(response)])
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())

    let record = try await store.install(request: AteliaPackageLifecycleRequest(manifest: packageManifest()))

    #expect(record == response.record)
    #expect(await store.lifecycleResponse == response)
    #expect(await store.latestRecord == response.record)
    #expect(await store.metadata == response.metadata)
    #expect(await store.package(id: "com.example.install")?.record == response.record)
}

/// Verifies list replaces the package index in response order.
@Test func listStoresPackageStatusesAndLookupIndex() async throws {
    let response = listResponse(packageIds: ["com.example.alpha", "com.example.beta"])
    let client = PackageLifecycleClientFixture(listResponses: [.success(response)])
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())

    let packages = try await store.list()

    #expect(packages == response.packages)
    #expect(await store.listResponse == response)
    #expect(await store.packages == response.packages)
    #expect(await store.package(id: "com.example.alpha") == response.packages[0])
    #expect(await store.package(id: "com.example.beta") == response.packages[1])
}

/// Verifies focused package operations update the public current package list.
@Test func lifecycleOperationUpdatesPackageListAfterListLoad() async throws {
    let list = listResponse(packageIds: ["com.example.alpha", "com.example.beta"])
    let install = lifecycleResponse(packageId: "com.example.gamma")
    let client = PackageLifecycleClientFixture(
        lifecycleResponses: [.success(install)],
        listResponses: [.success(list)]
    )
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())

    try await store.list()
    try await store.install(request: AteliaPackageLifecycleRequest(manifest: packageManifest(id: "com.example.gamma")))

    #expect(await store.packages.map(\.packageId) == [
        "com.example.alpha",
        "com.example.beta",
        "com.example.gamma"
    ])
    #expect(await store.package(id: "com.example.gamma")?.record == install.record)
}

/// Verifies latestRecord tracks recency across rollback and lifecycle operations.
@Test func latestRecordTracksMostRecentRecordOperation() async throws {
    let rollbackResponse = AteliaPackageRollbackResponse(
        metadata: metadata("extensions.rollback.v1"),
        record: lifecycleRecord(packageId: "com.example.rollback", status: .installedPreviousVersion)
    )
    let installResponse = lifecycleResponse(packageId: "com.example.install")
    let client = PackageLifecycleClientFixture(
        lifecycleResponses: [.success(installResponse)],
        rollbackResponses: [.success(rollbackResponse)]
    )
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())

    try await store.rollback(packageId: "com.example.rollback")
    #expect(await store.latestRecord == rollbackResponse.record)

    try await store.install(request: AteliaPackageLifecycleRequest(manifest: packageManifest(id: "com.example.install")))
    #expect(await store.latestRecord == installResponse.record)
}

/// Verifies status, rollback, and blocklist operations update their focused response slots.
@Test func focusedOperationsStoreLatestResponses() async throws {
    let statusResponse = AteliaPackageStatusResponse(
        metadata: metadata("extensions.status.v1"),
        package: AteliaPackageStatus(packageId: "com.example.status")
    )
    let rollbackResponse = AteliaPackageRollbackResponse(
        metadata: metadata("extensions.rollback.v1"),
        record: lifecycleRecord(packageId: "com.example.rollback", status: .installedPreviousVersion)
    )
    let blocklistEntry = AteliaPackageBlocklistEntry(
        reason: .userBlocked,
        key: .extensionId("com.example.blocked"),
        note: "user requested"
    )
    let blocklistApplyResponse = AteliaPackageBlocklistApplyResponse(
        metadata: metadata("extensions.blocklist.apply.v1"),
        entry: blocklistEntry
    )
    let blocklistListResponse = AteliaPackageBlocklistListResponse(
        metadata: metadata("extensions.blocklist.list.v1"),
        entries: [blocklistEntry]
    )
    let client = PackageLifecycleClientFixture(
        rollbackResponses: [.success(rollbackResponse)],
        statusResponses: [.success(statusResponse)],
        blocklistApplyResponses: [.success(blocklistApplyResponse)],
        blocklistListResponses: [.success(blocklistListResponse)]
    )
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())

    try await store.status(packageId: "com.example.status")
    try await store.rollback(packageId: "com.example.rollback")
    try await store.applyBlocklist(request: AteliaPackageBlocklistRequest(entry: blocklistEntry))
    try await store.listBlocklist()

    #expect(await store.statusResponse == statusResponse)
    #expect(await store.rollbackResponse == rollbackResponse)
    #expect(await store.blocklistApplyResponse == blocklistApplyResponse)
    #expect(await store.blocklistListResponse == blocklistListResponse)
    #expect(await store.blocklistEntries == [blocklistEntry])
    #expect(await store.metadata == blocklistListResponse.metadata)
}

/// Verifies an older in-flight list cannot overwrite a newer completed list.
@Test func staleListDoesNotOverwriteNewerList() async throws {
    let client = ControllablePackageLifecycleClientFixture()
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())
    let olderResponse = listResponse(packageIds: ["com.example.older"])
    let newerResponse = listResponse(packageIds: ["com.example.newer"])

    let olderList = Task {
        try await store.list()
    }
    try await client.waitForRequests(.list, count: 1)

    let newerList = Task {
        try await store.list()
    }
    try await client.waitForRequests(.list, count: 2)

    await client.respondToList(1, with: newerResponse)
    _ = try await newerList.value
    await client.respondToList(0, with: olderResponse)
    _ = try await olderList.value

    #expect(await store.listResponse == newerResponse)
    #expect(await store.package(id: "com.example.older") == nil)
    #expect(await store.package(id: "com.example.newer") == newerResponse.packages[0])
}

/// Verifies a failed newer operation does not discard an older successful operation.
@Test func failedNewerListDoesNotDiscardOlderSuccessfulList() async throws {
    let client = ControllablePackageLifecycleClientFixture()
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())
    let olderResponse = listResponse(packageIds: ["com.example.older"])

    let olderList = Task {
        try await store.list()
    }
    try await client.waitForRequests(.list, count: 1)

    let newerList = Task {
        try await store.list()
    }
    try await client.waitForRequests(.list, count: 2)

    await client.failList(1, with: PackageLifecycleFixtureError.requestFailed)
    await #expect(throws: PackageLifecycleFixtureError.self) {
        try await newerList.value
    }
    await client.respondToList(0, with: olderResponse)
    _ = try await olderList.value

    #expect(await store.listResponse == olderResponse)
    #expect(await store.package(id: "com.example.older") == olderResponse.packages[0])
}

/// Verifies unrelated newer operations do not suppress older focused cache slots.
@Test func newerStatusDoesNotDiscardOlderInstallResponse() async throws {
    let client = ControllablePackageLifecycleClientFixture()
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())
    let installResponse = lifecycleResponse(packageId: "com.example.install")
    let statusResponse = AteliaPackageStatusResponse(
        metadata: metadata("extensions.status.v1"),
        package: AteliaPackageStatus(packageId: "com.example.status")
    )

    let install = Task {
        try await store.install(request: AteliaPackageLifecycleRequest(manifest: packageManifest()))
    }
    try await client.waitForRequests(.install, count: 1)

    let status = Task {
        try await store.status(packageId: "com.example.status")
    }
    try await client.waitForRequests(.status, count: 1)

    await client.respondToStatus(0, with: statusResponse)
    _ = try await status.value
    await client.respondToInstall(0, with: installResponse)
    _ = try await install.value

    #expect(await store.statusResponse == statusResponse)
    #expect(await store.lifecycleResponse == installResponse)
    #expect(await store.latestRecord == installResponse.record)
    #expect(await store.package(id: "com.example.status") == statusResponse.package)
    #expect(await store.package(id: "com.example.install")?.record == installResponse.record)
}

/// Verifies newer lifecycle responses do not suppress older package index upserts.
@Test func newerInstallDoesNotDiscardOlderDifferentPackageInstallStatus() async throws {
    let client = ControllablePackageLifecycleClientFixture()
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())
    let olderResponse = lifecycleResponse(packageId: "com.example.older")
    let newerResponse = lifecycleResponse(packageId: "com.example.newer")

    let olderInstall = Task {
        try await store.install(request: AteliaPackageLifecycleRequest(manifest: packageManifest(id: "com.example.older")))
    }
    try await client.waitForRequests(.install, count: 1)

    let newerInstall = Task {
        try await store.install(request: AteliaPackageLifecycleRequest(manifest: packageManifest(id: "com.example.newer")))
    }
    try await client.waitForRequests(.install, count: 2)

    await client.respondToInstall(1, with: newerResponse)
    _ = try await newerInstall.value
    await client.respondToInstall(0, with: olderResponse)
    _ = try await olderInstall.value

    #expect(await store.lifecycleResponse == newerResponse)
    #expect(await store.latestRecord == newerResponse.record)
    #expect(await store.package(id: "com.example.newer")?.record == newerResponse.record)
    #expect(await store.package(id: "com.example.older")?.record == olderResponse.record)
}

/// Verifies clear prevents older in-flight operations from repopulating state.
@Test func clearInvalidatesInFlightPackageOperation() async throws {
    let client = ControllablePackageLifecycleClientFixture()
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())
    let response = lifecycleResponse(packageId: "com.example.pending")

    let install = Task {
        try await store.install(request: AteliaPackageLifecycleRequest(manifest: packageManifest()))
    }
    try await client.waitForRequests(.install, count: 1)

    await store.clear()
    await client.respondToInstall(0, with: response)
    _ = try await install.value

    #expect(await store.lifecycleResponse == nil)
    #expect(await store.metadata == nil)
    #expect(await store.packages.isEmpty)
    #expect(await store.package(id: "com.example.pending") == nil)
}

/// Verifies clear removes cached package lifecycle state.
@Test func clearResetsCachedLifecycleState() async throws {
    let response = lifecycleResponse(packageId: "com.example.clear")
    let client = PackageLifecycleClientFixture(lifecycleResponses: [.success(response)])
    let store = AteliaPackageLifecycleStore(client: client, session: AteliaSession())

    try await store.install(request: AteliaPackageLifecycleRequest(manifest: packageManifest()))
    await store.clear()

    #expect(await store.lifecycleResponse == nil)
    #expect(await store.latestRecord == nil)
    #expect(await store.metadata == nil)
    #expect(await store.packages.isEmpty)
    #expect(await store.package(id: "com.example.clear") == nil)
}
