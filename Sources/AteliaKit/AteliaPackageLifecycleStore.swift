import Foundation

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
        guard shouldApply(operationGeneration, after: latestBlocklistApplyGeneration) else {
            return response.entry
        }
        latestBlocklistApplyGeneration = operationGeneration
        latestBlocklistApplyResponse = response
        applyMetadata(response.metadata, generation: operationGeneration)
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
        latestBlocklistListResponse?.entries ?? []
    }

    /// Returns the latest known package status for an identifier.
    public func package(id packageId: String) -> AteliaPackageStatus? {
        packagesByID[packageId]
    }

    private func beginOperation() -> Int {
        nextOperationGeneration += 1
        return nextOperationGeneration
    }

    private func shouldApply(_ operationGeneration: Int) -> Bool {
        operationGeneration > clearGeneration
    }

    private func shouldApply(_ operationGeneration: Int, after appliedGeneration: Int) -> Bool {
        shouldApply(operationGeneration) && operationGeneration > appliedGeneration
    }

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

    private func applyMetadata(_ metadata: AteliaProtocolMetadata, generation operationGeneration: Int) {
        guard shouldApply(operationGeneration, after: latestMetadataGeneration) else {
            return
        }
        latestMetadataGeneration = operationGeneration
        latestMetadata = metadata
    }

    private func applyRecord(_ record: AteliaPackageLifecycleRecord, generation operationGeneration: Int) {
        guard shouldApply(operationGeneration, after: latestRecordGeneration) else {
            return
        }
        latestRecordGeneration = operationGeneration
        latestRecordValue = record
    }

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

    private static func status(from record: AteliaPackageLifecycleRecord) -> AteliaPackageStatus {
        AteliaPackageStatus(
            packageId: record.packageId,
            record: record
        )
    }

    private func upsertPackageStatus(_ package: AteliaPackageStatus, generation operationGeneration: Int) {
        let packageGeneration = packageGenerations[package.packageId] ?? 0
        guard shouldApply(operationGeneration, after: packageGeneration) else {
            return
        }
        if packagesByID[package.packageId] == nil {
            packageOrder.append(package.packageId)
        }
        packageGenerations[package.packageId] = operationGeneration
        packagesByID[package.packageId] = package
    }
}
