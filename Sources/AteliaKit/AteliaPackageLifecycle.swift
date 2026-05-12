import Foundation

/// Shared request contract for package install and update operations.
public struct AteliaPackageLifecycleRequest: Sendable, Codable, Equatable {
    /// JSON keys for package install/update requests.
    private enum CodingKeys: String, CodingKey {
        /// Extension manifest payload.
        case manifest
        /// Whether local unsigned manifests are accepted.
        case approveLocalUnsigned = "approve_local_unsigned"
        /// Whether local-process runtime can be used.
        case allowLocalProcessRuntime = "allow_local_process_runtime"
        /// Whether a source authority change is accepted.
        case approveSourceChange = "approve_source_change"
    }

    /// Manifest body used for install and update operations.
    public var manifest: AteliaPackageManifest
    /// Allows installation from local unsigned artifacts.
    public var approveLocalUnsigned: Bool
    /// Allows local process runtime execution mode.
    public var allowLocalProcessRuntime: Bool
    /// Allows source authority replacement.
    public var approveSourceChange: Bool

    /// Creates a package lifecycle request.
    public init(
        manifest: AteliaPackageManifest,
        approveLocalUnsigned: Bool = false,
        allowLocalProcessRuntime: Bool = false,
        approveSourceChange: Bool = false
    ) {
        self.manifest = manifest
        self.approveLocalUnsigned = approveLocalUnsigned
        self.allowLocalProcessRuntime = allowLocalProcessRuntime
        self.approveSourceChange = approveSourceChange
    }

    /// Decodes install/update requests with Secretary's default-false contract.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.manifest = try container.decode(AteliaPackageManifest.self, forKey: .manifest)
        self.approveLocalUnsigned = try container.contains(.approveLocalUnsigned)
            ? container.decode(Bool.self, forKey: .approveLocalUnsigned)
            : false
        self.allowLocalProcessRuntime = try container.contains(.allowLocalProcessRuntime)
            ? container.decode(Bool.self, forKey: .allowLocalProcessRuntime)
            : false
        self.approveSourceChange = try container.contains(.approveSourceChange)
            ? container.decode(Bool.self, forKey: .approveSourceChange)
            : false
    }
}

/// Envelope returned after package install and update actions.
public struct AteliaPackageLifecycleResponse: Sendable, Codable, Equatable {
    /// JSON keys for lifecycle operation envelopes.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Installed package revision record.
        case record
    }

    /// Protocol metadata.
    public var metadata: AteliaProtocolMetadata
    /// Installed package revision record.
    public var record: AteliaPackageLifecycleRecord
}

/// Envelope returned by package install operations.
public typealias AteliaPackageInstallResponse = AteliaPackageLifecycleResponse
/// Envelope returned by package update operations.
public typealias AteliaPackageUpdateResponse = AteliaPackageLifecycleResponse
/// Envelope returned by package disable operations.
public typealias AteliaPackageDisableResponse = AteliaPackageLifecycleResponse
/// Envelope returned by package enable operations.
public typealias AteliaPackageEnableResponse = AteliaPackageLifecycleResponse
/// Envelope returned by package remove operations.
public typealias AteliaPackageRemoveResponse = AteliaPackageLifecycleResponse

/// Alias for the canonical package install/update/remove record shape.
public typealias AteliaPackageLifecycleRecord = AteliaPackageRollbackRecord

/// Package status request body for list filtering.
public struct AteliaPackageListRequest: Sendable, Codable, Equatable {
    /// JSON keys for package list requests.
    private enum CodingKeys: String, CodingKey {
        /// Whether blocked packages should be included.
        case includeBlocked = "include_blocked"
    }

    /// Whether blocked packages should be included.
    public var includeBlocked: Bool

    /// Creates a package list request.
    public init(includeBlocked: Bool = true) {
        self.includeBlocked = includeBlocked
    }

    /// Decodes list requests with Secretary's default-true contract.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.includeBlocked = try container.contains(.includeBlocked)
            ? container.decode(Bool.self, forKey: .includeBlocked)
            : true
    }
}

/// One package status entry in list status responses.
public struct AteliaPackageStatus: Sendable, Codable, Equatable {
    /// JSON keys for a package status entry.
    private enum CodingKeys: String, CodingKey {
        /// Package identifier retained as extension terminology in the wire contract.
        case extensionId = "extension_id"
        /// Installed revision record, when known.
        case record
        /// Active blocklist match for the package.
        case block
    }

    /// Package identifier in canonical package language.
    public var packageId: String
    /// Optional package install record.
    public var record: AteliaPackageLifecycleRecord?
    /// Optional blocklist match.
    public var block: AteliaPackageTrustIndexEntry.Block?

    /// Creates a package status entry.
    public init(
        packageId: String,
        record: AteliaPackageLifecycleRecord? = nil,
        block: AteliaPackageTrustIndexEntry.Block? = nil
    ) {
        self.packageId = packageId
        self.record = record
        self.block = block
    }

    /// Decodes a package status entry using extension wire naming.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.packageId = try container.decode(String.self, forKey: .extensionId)
        self.record = try container.decodeIfPresent(
            AteliaPackageLifecycleRecord.self,
            forKey: .record
        )
        self.block = try container.decodeIfPresent(
            AteliaPackageTrustIndexEntry.Block.self,
            forKey: .block
        )
    }

    /// Encodes a package status entry using canonical package fields.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(packageId, forKey: .extensionId)
        try container.encodeIfPresent(record, forKey: .record)
        try container.encodeIfPresent(block, forKey: .block)
    }
}

/// Envelope returned by package status operations.
public struct AteliaPackageStatusResponse: Sendable, Codable, Equatable {
    /// JSON keys for package status responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Package status payload, retained as `extension` in the beta wire contract.
        case package = "extension"
    }

    /// Protocol metadata.
    public var metadata: AteliaProtocolMetadata
    /// Package status.
    public var package: AteliaPackageStatus
}

/// Envelope returned by package list operations.
public struct AteliaPackageListResponse: Sendable, Codable, Equatable {
    /// JSON keys for package list responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Package status entries, retained as `extensions` in the beta wire contract.
        case packages = "extensions"
    }

    /// Protocol metadata.
    public var metadata: AteliaProtocolMetadata
    /// Package entries returned by list.
    public var packages: [AteliaPackageStatus]
}

/// Entry used by blocklist apply/list operations.
public struct AteliaPackageBlocklistEntry: Sendable, Codable, Equatable {
    /// JSON keys for blocklist entries.
    private enum CodingKeys: String, CodingKey {
        /// Block reason from blocklist policy evaluation.
        case reason
        /// Block key selected by Secretary.
        case key
        /// Optional human annotation.
        case note
    }

    /// Block reason from policy.
    public var reason: AteliaPackageTrustIndexEntry.Block.Reason
    /// Matched block key.
    public var key: AteliaPackageTrustIndexEntry.Block.Key
    /// Optional admin or UX note.
    public var note: String?

    /// Creates a blocklist entry.
    public init(
        reason: AteliaPackageTrustIndexEntry.Block.Reason,
        key: AteliaPackageTrustIndexEntry.Block.Key,
        note: String? = nil
    ) {
        self.reason = reason
        self.key = key
        self.note = note
    }
}

/// Request body for package blocklist apply operations.
public struct AteliaPackageBlocklistRequest: Sendable, Codable, Equatable {
    /// JSON keys for blocklist apply requests.
    private enum CodingKeys: String, CodingKey {
        /// Entry to apply.
        case entry
    }

    /// Blocklist entry to apply.
    public var entry: AteliaPackageBlocklistEntry

    /// Creates a blocklist-apply request.
    public init(entry: AteliaPackageBlocklistEntry) {
        self.entry = entry
    }
}

/// Envelope returned by package blocklist apply operations.
public struct AteliaPackageBlocklistApplyResponse: Sendable, Codable, Equatable {
    /// JSON keys for blocklist apply responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Persisted blocklist entry.
        case entry
    }

    /// Protocol metadata.
    public var metadata: AteliaProtocolMetadata
    /// Applied blocklist entry.
    public var entry: AteliaPackageBlocklistEntry
}

/// Envelope returned by package blocklist list operations.
public struct AteliaPackageBlocklistListResponse: Sendable, Codable, Equatable {
    /// JSON keys for blocklist list responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Matching blocklist entries.
        case entries
    }

    /// Protocol metadata.
    public var metadata: AteliaProtocolMetadata
    /// Active blocklist entries.
    public var entries: [AteliaPackageBlocklistEntry]
}
