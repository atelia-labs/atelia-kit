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
    private var latestAppliedGeneration = 0
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
        guard shouldApply(operationGeneration) else {
            return response.record
        }
        latestAppliedGeneration = operationGeneration
        latestRollbackResponse = response
        latestMetadata = response.metadata
        latestRecordValue = response.record
        upsertPackageStatus(Self.status(from: response.record))
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
        guard shouldApply(operationGeneration) else {
            return response.package
        }
        latestAppliedGeneration = operationGeneration
        latestStatusResponse = response
        latestMetadata = response.metadata
        upsertPackageStatus(response.package)
        return response.package
    }

    /// Loads package statuses and replaces the current package index.
    @discardableResult
    public func list(request: AteliaPackageListRequest = .init()) async throws -> [AteliaPackageStatus] {
        let operationGeneration = beginOperation()
        let response = try await client.packageListResponse(for: session, request: request)
        guard shouldApply(operationGeneration) else {
            return response.packages
        }
        latestAppliedGeneration = operationGeneration
        latestListResponse = response
        latestMetadata = response.metadata
        packageOrder = response.packages.map(\.packageId)
        packagesByID = response.packages.reduce(into: [:]) { index, package in
            index[package.packageId] = package
        }
        return response.packages
    }

    /// Applies one blocklist entry and records the latest blocklist response.
    @discardableResult
    public func applyBlocklist(
        request: AteliaPackageBlocklistRequest
    ) async throws -> AteliaPackageBlocklistEntry {
        let operationGeneration = beginOperation()
        let response = try await client.packageBlocklistApplyResponse(for: session, request: request)
        guard shouldApply(operationGeneration) else {
            return response.entry
        }
        latestAppliedGeneration = operationGeneration
        latestBlocklistApplyResponse = response
        latestMetadata = response.metadata
        return response.entry
    }

    /// Loads blocklist entries and records the latest blocklist response.
    @discardableResult
    public func listBlocklist() async throws -> [AteliaPackageBlocklistEntry] {
        let operationGeneration = beginOperation()
        let response = try await client.packageBlocklistListResponse(for: session)
        guard shouldApply(operationGeneration) else {
            return response.entries
        }
        latestAppliedGeneration = operationGeneration
        latestBlocklistListResponse = response
        latestMetadata = response.metadata
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
        operationGeneration > latestAppliedGeneration && operationGeneration > clearGeneration
    }

    private func applyLifecycleResponse(
        _ response: AteliaPackageLifecycleResponse,
        generation operationGeneration: Int
    ) {
        guard shouldApply(operationGeneration) else {
            return
        }
        latestAppliedGeneration = operationGeneration
        latestLifecycleResponse = response
        latestMetadata = response.metadata
        latestRecordValue = response.record
        upsertPackageStatus(Self.status(from: response.record))
    }

    private static func status(from record: AteliaPackageLifecycleRecord) -> AteliaPackageStatus {
        AteliaPackageStatus(
            packageId: record.packageId,
            record: record
        )
    }

    private func upsertPackageStatus(_ package: AteliaPackageStatus) {
        if packagesByID[package.packageId] == nil {
            packageOrder.append(package.packageId)
        }
        packagesByID[package.packageId] = package
    }
}
