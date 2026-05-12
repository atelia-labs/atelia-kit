import Foundation

/// Atomic snapshot of package lifecycle store cached state.
public struct AteliaPackageLifecycleStoreSnapshot: Sendable, Equatable {
    /// Latest lifecycle response, when one has completed.
    public var lifecycleResponse: AteliaPackageLifecycleResponse?
    /// Latest rollback response, when one has completed.
    public var rollbackResponse: AteliaPackageRollbackResponse?
    /// Latest package status response, when one has completed.
    public var statusResponse: AteliaPackageStatusResponse?
    /// Latest package list response, when one has completed.
    public var listResponse: AteliaPackageListResponse?
    /// Latest blocklist apply response, when one has completed.
    public var blocklistApplyResponse: AteliaPackageBlocklistApplyResponse?
    /// Latest blocklist list response, when one has completed.
    public var blocklistListResponse: AteliaPackageBlocklistListResponse?
    /// Latest protocol metadata from the most recent cached response.
    public var metadata: AteliaProtocolMetadata?
    /// Latest lifecycle or rollback record.
    public var latestRecord: AteliaPackageLifecycleRecord?
    /// Package statuses currently known to the store.
    public var packages: [AteliaPackageStatus]
    /// Latest known blocklist entries.
    public var blocklistEntries: [AteliaPackageBlocklistEntry]

    /// Creates a package lifecycle store snapshot.
    public init(
        lifecycleResponse: AteliaPackageLifecycleResponse?,
        rollbackResponse: AteliaPackageRollbackResponse?,
        statusResponse: AteliaPackageStatusResponse?,
        listResponse: AteliaPackageListResponse?,
        blocklistApplyResponse: AteliaPackageBlocklistApplyResponse?,
        blocklistListResponse: AteliaPackageBlocklistListResponse?,
        metadata: AteliaProtocolMetadata?,
        latestRecord: AteliaPackageLifecycleRecord?,
        packages: [AteliaPackageStatus],
        blocklistEntries: [AteliaPackageBlocklistEntry]
    ) {
        self.lifecycleResponse = lifecycleResponse
        self.rollbackResponse = rollbackResponse
        self.statusResponse = statusResponse
        self.listResponse = listResponse
        self.blocklistApplyResponse = blocklistApplyResponse
        self.blocklistListResponse = blocklistListResponse
        self.metadata = metadata
        self.latestRecord = latestRecord
        self.packages = packages
        self.blocklistEntries = blocklistEntries
    }
}

/// Actor-backed command/cache surface for package lifecycle operations.
public actor AteliaPackageLifecycleStore {
    private let client: any AteliaClient
    private let session: AteliaSession
    private var latestLifecycleResponse: AteliaPackageLifecycleResponse?
    private var latestRollbackResponse: AteliaPackageRollbackResponse?
    private var latestStatusResponse: AteliaPackageStatusResponse?
    private var latestListResponse: AteliaPackageListResponse?
    private var latestBlocklistApplyResponse: AteliaPackageBlocklistApplyResponse?
    private var latestBlocklistListResponse: AteliaPackageBlocklistListResponse?
    private var latestMetadata: AteliaProtocolMetadata?
    private var latestRecordValue: AteliaPackageLifecycleRecord?
    private var packageOrder: [String] = []
    private var packagesByID: [String: AteliaPackageStatus] = [:]
    private var blocklistEntriesValue: [AteliaPackageBlocklistEntry] = []
    private var blocklistEntryGenerations: [AteliaPackageTrustIndexEntry.Block.Key: Int] = [:]
    private var nextOperationGeneration = 0
    private var latestLifecycleGeneration = 0
    private var latestRollbackGeneration = 0
    private var latestStatusGeneration = 0
    private var latestListGeneration = 0
    private var latestBlocklistApplyGeneration = 0
    private var latestBlocklistListGeneration = 0
    private var latestMetadataGeneration = 0
    private var latestRecordGeneration = 0
    private var latestPackageListGeneration = 0
    private var packageGenerations: [String: Int] = [:]
    private var clearGeneration = 0

    /// Creates a package lifecycle store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.client = client
        self.session = session
    }

    /// Installs a package and records the latest lifecycle response.
    @discardableResult
    public func install(request: AteliaPackageLifecycleRequest) async throws -> AteliaPackageLifecycleRecord {
        let operationGeneration = beginOperation()
        let response = try await client.packageInstallResponse(for: session, request: request)
        applyLifecycleResponse(response, generation: operationGeneration)
        return response.record
    }

    /// Updates a package and records the latest lifecycle response.
    @discardableResult
    public func update(request: AteliaPackageLifecycleRequest) async throws -> AteliaPackageLifecycleRecord {
        let operationGeneration = beginOperation()
        let response = try await client.packageUpdateResponse(for: session, request: request)
        applyLifecycleResponse(response, generation: operationGeneration)
        return response.record
    }

    /// Rolls back a package and records the latest rollback response.
    @discardableResult
    public func rollback(packageId: String) async throws -> AteliaPackageRollbackRecord {
        let operationGeneration = beginOperation()
        let response = try await client.packageRollbackResponse(for: session, packageId: packageId)
        if shouldApply(operationGeneration, after: latestRollbackGeneration) {
            latestRollbackGeneration = operationGeneration
            latestRollbackResponse = response
            applyMetadata(response.metadata, generation: operationGeneration)
            applyRecord(response.record, generation: operationGeneration)
        }
        upsertPackageStatus(Self.status(from: response.record), generation: operationGeneration)
        return response.record
    }

    /// Disables a package and records the latest lifecycle response.
    @discardableResult
    public func disable(packageId: String) async throws -> AteliaPackageLifecycleRecord {
        let operationGeneration = beginOperation()
        let response = try await client.packageDisableResponse(for: session, packageId: packageId)
        applyLifecycleResponse(response, generation: operationGeneration)
        return response.record
    }

    /// Enables a package and records the latest lifecycle response.
    @discardableResult
    public func enable(packageId: String) async throws -> AteliaPackageLifecycleRecord {
        let operationGeneration = beginOperation()
        let response = try await client.packageEnableResponse(for: session, packageId: packageId)
        applyLifecycleResponse(response, generation: operationGeneration)
        return response.record
    }

    /// Removes a package and records the latest lifecycle response.
    @discardableResult
    public func remove(packageId: String) async throws -> AteliaPackageLifecycleRecord {
        let operationGeneration = beginOperation()
        let response = try await client.packageRemoveResponse(for: session, packageId: packageId)
        applyLifecycleResponse(response, generation: operationGeneration)
        return response.record
    }

    /// Loads one package status and records it by package identifier.
    @discardableResult
    public func status(packageId: String) async throws -> AteliaPackageStatus {
        let operationGeneration = beginOperation()
        let response = try await client.packageStatusResponse(for: session, packageId: packageId)
        if shouldApply(operationGeneration, after: latestStatusGeneration) {
            latestStatusGeneration = operationGeneration
            latestStatusResponse = response
            applyMetadata(response.metadata, generation: operationGeneration)
        }
        upsertPackageStatus(response.package, generation: operationGeneration)
        return response.package
    }

    /// Loads package statuses and replaces the current package index.
    @discardableResult
    public func list(request: AteliaPackageListRequest = .init()) async throws -> [AteliaPackageStatus] {
        let operationGeneration = beginOperation()
        let response = try await client.packageListResponse(for: session, request: request)
        guard shouldApply(operationGeneration, after: latestListGeneration) else {
            return response.packages
        }
        latestListGeneration = operationGeneration
        latestListResponse = response
        applyMetadata(response.metadata, generation: operationGeneration)
        replacePackageStatuses(response.packages, generation: operationGeneration)
        return response.packages
    }

    /// Applies one blocklist entry and records the latest blocklist response.
    @discardableResult
    public func applyBlocklist(
        request: AteliaPackageBlocklistRequest
    ) async throws -> AteliaPackageBlocklistEntry {
        let operationGeneration = beginOperation()
        let response = try await client.packageBlocklistApplyResponse(for: session, request: request)
        if shouldApply(operationGeneration, after: latestBlocklistApplyGeneration) {
            latestBlocklistApplyGeneration = operationGeneration
            latestBlocklistApplyResponse = response
            applyMetadata(response.metadata, generation: operationGeneration)
        }
        upsertBlocklistEntry(response.entry, generation: operationGeneration)
        return response.entry
    }

    /// Loads blocklist entries and records the latest blocklist response.
    @discardableResult
    public func listBlocklist() async throws -> [AteliaPackageBlocklistEntry] {
        let operationGeneration = beginOperation()
        let response = try await client.packageBlocklistListResponse(for: session)
        guard shouldApply(operationGeneration, after: latestBlocklistListGeneration) else {
            return response.entries
        }
        latestBlocklistListGeneration = operationGeneration
        latestBlocklistListResponse = response
        applyMetadata(response.metadata, generation: operationGeneration)
        replaceBlocklistEntries(response.entries, generation: operationGeneration)
        return response.entries
    }

    /// Clears cached lifecycle, status, and blocklist state.
    public func clear() {
        clearGeneration = nextOperationGeneration
        latestLifecycleResponse = nil
        latestRollbackResponse = nil
        latestStatusResponse = nil
        latestListResponse = nil
        latestBlocklistApplyResponse = nil
        latestBlocklistListResponse = nil
        latestMetadata = nil
        latestRecordValue = nil
        packageOrder.removeAll(keepingCapacity: true)
        packagesByID.removeAll(keepingCapacity: true)
        packageGenerations.removeAll(keepingCapacity: true)
        blocklistEntriesValue.removeAll(keepingCapacity: true)
        blocklistEntryGenerations.removeAll(keepingCapacity: true)
    }

    /// Returns the latest lifecycle response, if one has completed.
    public var lifecycleResponse: AteliaPackageLifecycleResponse? {
        latestLifecycleResponse
    }

    /// Returns the latest rollback response, if one has completed.
    public var rollbackResponse: AteliaPackageRollbackResponse? {
        latestRollbackResponse
    }

    /// Returns the latest package status response, if one has completed.
    public var statusResponse: AteliaPackageStatusResponse? {
        latestStatusResponse
    }

    /// Returns the latest package list response, if one has completed.
    public var listResponse: AteliaPackageListResponse? {
        latestListResponse
    }

    /// Returns the latest blocklist apply response, if one has completed.
    public var blocklistApplyResponse: AteliaPackageBlocklistApplyResponse? {
        latestBlocklistApplyResponse
    }

    /// Returns the latest blocklist list response, if one has completed.
    public var blocklistListResponse: AteliaPackageBlocklistListResponse? {
        latestBlocklistListResponse
    }

    /// Returns the latest protocol metadata from the most recent cached response.
    public var metadata: AteliaProtocolMetadata? {
        latestMetadata
    }

    /// Returns the latest lifecycle or rollback record.
    public var latestRecord: AteliaPackageLifecycleRecord? {
        latestRecordValue
    }

    /// Returns package statuses currently known to the store.
    public var packages: [AteliaPackageStatus] {
        packageOrder.compactMap { packagesByID[$0] }
    }

    /// Returns the latest known blocklist entries.
    public var blocklistEntries: [AteliaPackageBlocklistEntry] {
        blocklistEntriesValue
    }

    /// Returns the latest known package status for an identifier.
    public func package(id packageId: String) -> AteliaPackageStatus? {
        packagesByID[packageId]
    }

    /// Returns an atomic snapshot of the cached lifecycle, package, and blocklist state.
    public func snapshot() -> AteliaPackageLifecycleStoreSnapshot {
        AteliaPackageLifecycleStoreSnapshot(
            lifecycleResponse: latestLifecycleResponse,
            rollbackResponse: latestRollbackResponse,
            statusResponse: latestStatusResponse,
            listResponse: latestListResponse,
            blocklistApplyResponse: latestBlocklistApplyResponse,
            blocklistListResponse: latestBlocklistListResponse,
            metadata: latestMetadata,
            latestRecord: latestRecordValue,
            packages: packages,
            blocklistEntries: blocklistEntriesValue
        )
    }

    /// Advances and returns the operation generation for a newly started request.
    private func beginOperation() -> Int {
        nextOperationGeneration += 1
        return nextOperationGeneration
    }

    /// Returns whether an operation generation is newer than the last clear.
    private func shouldApply(_ operationGeneration: Int) -> Bool {
        operationGeneration > clearGeneration
    }

    /// Returns whether an operation generation can replace an existing cached generation.
    private func shouldApply(_ operationGeneration: Int, after appliedGeneration: Int) -> Bool {
        shouldApply(operationGeneration) && operationGeneration > appliedGeneration
    }

    /// Applies a lifecycle response to latest response, metadata, record, and package caches.
    private func applyLifecycleResponse(
        _ response: AteliaPackageLifecycleResponse,
        generation operationGeneration: Int
    ) {
        if shouldApply(operationGeneration, after: latestLifecycleGeneration) {
            latestLifecycleGeneration = operationGeneration
            latestLifecycleResponse = response
            applyMetadata(response.metadata, generation: operationGeneration)
            applyRecord(response.record, generation: operationGeneration)
        }
        upsertPackageStatus(Self.status(from: response.record), generation: operationGeneration)
    }

    /// Stores metadata when it is from the newest applicable operation.
    private func applyMetadata(_ metadata: AteliaProtocolMetadata, generation operationGeneration: Int) {
        guard shouldApply(operationGeneration, after: latestMetadataGeneration) else {
            return
        }
        latestMetadataGeneration = operationGeneration
        latestMetadata = metadata
    }

    /// Stores the latest package lifecycle record when it is from the newest applicable operation.
    private func applyRecord(_ record: AteliaPackageLifecycleRecord, generation operationGeneration: Int) {
        guard shouldApply(operationGeneration, after: latestRecordGeneration) else {
            return
        }
        latestRecordGeneration = operationGeneration
        latestRecordValue = record
    }

    /// Replaces the package cache with a list response while preserving newer per-package updates.
    private func replacePackageStatuses(
        _ packages: [AteliaPackageStatus],
        generation operationGeneration: Int
    ) {
        guard shouldApply(operationGeneration, after: latestPackageListGeneration) else {
            return
        }
        latestPackageListGeneration = operationGeneration
        let newerPackages = packageOrder.reduce(into: [String: AteliaPackageStatus]()) { index, packageId in
            guard let generation = packageGenerations[packageId],
                  generation > operationGeneration else {
                return
            }
            index[packageId] = packagesByID[packageId]
        }
        let listedPackageIDs = Set(packages.map(\.packageId))
        let newerUnlistedPackageIDs = packageOrder.filter { packageId in
            newerPackages[packageId] != nil && !listedPackageIDs.contains(packageId)
        }
        packageOrder = packages.map(\.packageId) + newerUnlistedPackageIDs
        packagesByID.removeAll(keepingCapacity: true)
        for package in packages {
            if let newerPackage = newerPackages[package.packageId] {
                packagesByID[package.packageId] = newerPackage
            } else {
                packagesByID[package.packageId] = package
                packageGenerations[package.packageId] = operationGeneration
            }
        }
        for packageId in newerUnlistedPackageIDs {
            packagesByID[packageId] = newerPackages[packageId] ?? packagesByID[packageId]
        }
    }

    /// Builds a package status row from a lifecycle record.
    private static func status(from record: AteliaPackageLifecycleRecord) -> AteliaPackageStatus {
        AteliaPackageStatus(
            packageId: record.packageId,
            record: record
        )
    }

    /// Inserts or updates a package status when it is newer than the cached row.
    private func upsertPackageStatus(_ package: AteliaPackageStatus, generation operationGeneration: Int) {
        let packageGeneration = packageGenerations[package.packageId] ?? 0
        guard shouldApply(operationGeneration, after: packageGeneration) else {
            return
        }
        if packagesByID[package.packageId] == nil,
           latestPackageListGeneration > operationGeneration {
            return
        }
        if packagesByID[package.packageId] == nil {
            packageOrder.append(package.packageId)
        }
        packageGenerations[package.packageId] = operationGeneration
        packagesByID[package.packageId] = package
    }

    /// Replaces blocklist entries while preserving entries from newer operations.
    private func replaceBlocklistEntries(
        _ entries: [AteliaPackageBlocklistEntry],
        generation operationGeneration: Int
    ) {
        let newerEntries = blocklistEntriesValue.filter { entry in
            blocklistGeneration(for: entry.key) > operationGeneration
        }
        let listedKeys = entries.map(\.key)
        let newerUnlistedEntries = newerEntries.filter { entry in
            !listedKeys.contains(entry.key)
        }
        blocklistEntriesValue = entries.map { entry in
            newerEntries.first { $0.key == entry.key } ?? entry
        } + newerUnlistedEntries
        for entry in entries where blocklistGeneration(for: entry.key) <= operationGeneration {
            setBlocklistGeneration(operationGeneration, for: entry.key)
        }
    }

    /// Inserts or updates one blocklist entry when it is newer than the cached entry.
    private func upsertBlocklistEntry(
        _ entry: AteliaPackageBlocklistEntry,
        generation operationGeneration: Int
    ) {
        let entryGeneration = blocklistGeneration(for: entry.key)
        guard shouldApply(operationGeneration, after: entryGeneration) else {
            return
        }
        if !blocklistEntriesValue.contains(where: { $0.key == entry.key }),
           latestBlocklistListGeneration > operationGeneration {
            return
        }
        if let index = blocklistEntriesValue.firstIndex(where: { $0.key == entry.key }) {
            blocklistEntriesValue[index] = entry
        } else {
            blocklistEntriesValue.append(entry)
        }
        setBlocklistGeneration(operationGeneration, for: entry.key)
    }

    /// Returns the cached generation for a blocklist key.
    private func blocklistGeneration(for key: AteliaPackageTrustIndexEntry.Block.Key) -> Int {
        blocklistEntryGenerations[key] ?? 0
    }

    /// Records the generation that last wrote a blocklist key.
    private func setBlocklistGeneration(
        _ generation: Int,
        for key: AteliaPackageTrustIndexEntry.Block.Key
    ) {
        blocklistEntryGenerations[key] = generation
    }
}
