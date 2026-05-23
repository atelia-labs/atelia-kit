import Foundation

/// Package inspect payload without protocol metadata.
public struct AteliaPackageInspect: Sendable, Codable, Equatable {
    /// JSON keys for package inspect payloads.
    private enum CodingKeys: String, CodingKey {
        /// Stable package identifier.
        case packageId = "package_id"
        /// Current package status in beta wire naming.
        case package = "extension"
        /// Active manifest snapshot.
        case manifest
        /// Active blocklist match, if the package is blocked.
        case block
        /// Permissions approved for the current package version.
        case permissions
        /// Service dependency and provision declarations.
        case services
        /// Whether a rollback target is available.
        case rollbackAvailable = "rollback_available"
        /// Snapshot of the rollback target, when available.
        case rollbackSnapshot = "rollback_snapshot"
        /// Source and provenance snapshot.
        case source
        /// Trust publication and registry metadata.
        case trust
    }

    /// Stable package identifier.
    public var packageId: String
    /// Current package status payload.
    public var package: AteliaPackageStatus
    /// Active manifest snapshot for the package.
    public var manifest: AteliaPackageManifest
    /// Active blocklist match for the package.
    public var block: AteliaPackageTrustIndexEntry.Block?
    /// Approved permissions for the installed revision.
    public var permissions: [String]
    /// Service definitions in the active manifest.
    public var services: AteliaPackageServices
    /// Whether a rollback target exists.
    public var rollbackAvailable: Bool
    /// Snapshot of the rollback target, if present.
    public var rollbackSnapshot: AteliaPackageRollbackRecord.RollbackSnapshot?
    /// Source and provenance metadata.
    public var source: AteliaPackageTrustIndexEntry.SourceSnapshot
    /// Publication and registry trust metadata.
    public var trust: AteliaPackageTrustIndexEntry.Publication?

    /// Creates a package inspect payload.
    public init(
        packageId: String,
        package: AteliaPackageStatus,
        manifest: AteliaPackageManifest,
        block: AteliaPackageTrustIndexEntry.Block? = nil,
        permissions: [String] = [],
        services: AteliaPackageServices = .init(),
        rollbackAvailable: Bool = false,
        rollbackSnapshot: AteliaPackageRollbackRecord.RollbackSnapshot? = nil,
        source: AteliaPackageTrustIndexEntry.SourceSnapshot,
        trust: AteliaPackageTrustIndexEntry.Publication? = nil
    ) {
        self.packageId = packageId
        self.package = package
        self.manifest = manifest
        self.block = block
        self.permissions = permissions
        self.services = services
        self.rollbackAvailable = rollbackAvailable
        self.rollbackSnapshot = rollbackSnapshot
        self.source = source
        self.trust = trust
    }

    /// Decodes with defaults when optional detail fields are omitted.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.package = try container.decode(AteliaPackageStatus.self, forKey: .package)
        self.packageId = try container.decodeIfPresent(String.self, forKey: .packageId) ?? package.packageId
        self.manifest = try container.decode(AteliaPackageManifest.self, forKey: .manifest)
        self.block = try container.decodeIfPresent(AteliaPackageTrustIndexEntry.Block.self, forKey: .block)
        self.permissions = try container.decodeIfPresent([String].self, forKey: .permissions) ?? []
        self.services = try container.decodeIfPresent(AteliaPackageServices.self, forKey: .services) ?? .init()
        self.rollbackAvailable = try container.decodeIfPresent(Bool.self, forKey: .rollbackAvailable) ?? false
        self.rollbackSnapshot = try container.decodeIfPresent(
            AteliaPackageRollbackRecord.RollbackSnapshot.self,
            forKey: .rollbackSnapshot
        )
        self.source = try container.decode(AteliaPackageTrustIndexEntry.SourceSnapshot.self, forKey: .source)
        self.trust = try container.decodeIfPresent(AteliaPackageTrustIndexEntry.Publication.self, forKey: .trust)
    }
}

/// Response envelope returned by `POST /v1/packages/{id}/inspect`.
public struct AteliaPackageInspectResponse: Sendable, Codable, Equatable {
    /// JSON keys for package inspect responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Stable package identifier.
        case packageId = "package_id"
        /// Current package status in beta wire naming.
        case package = "extension"
        /// Active manifest snapshot.
        case manifest
        /// Active blocklist match, if the package is blocked.
        case block
        /// Permissions approved for the current package version.
        case permissions
        /// Service dependency and provision declarations.
        case services
        /// Whether a rollback target is available.
        case rollbackAvailable = "rollback_available"
        /// Snapshot of the rollback target, when available.
        case rollbackSnapshot = "rollback_snapshot"
        /// Source and provenance snapshot.
        case source
        /// Trust publication and registry metadata.
        case trust
    }

    /// Protocol metadata attached to the response.
    public var metadata: AteliaProtocolMetadata
    /// Stable package identifier.
    public var packageId: String
    /// Current package status payload.
    public var package: AteliaPackageStatus
    /// Active manifest snapshot for the package.
    public var manifest: AteliaPackageManifest
    /// Active blocklist match for the package.
    public var block: AteliaPackageTrustIndexEntry.Block?
    /// Approved permissions for the installed revision.
    public var permissions: [String]
    /// Service definitions in the active manifest.
    public var services: AteliaPackageServices
    /// Whether a rollback target exists.
    public var rollbackAvailable: Bool
    /// Snapshot of the rollback target, if present.
    public var rollbackSnapshot: AteliaPackageRollbackRecord.RollbackSnapshot?
    /// Source and provenance metadata.
    public var source: AteliaPackageTrustIndexEntry.SourceSnapshot
    /// Publication and registry trust metadata.
    public var trust: AteliaPackageTrustIndexEntry.Publication?

    /// Metadata-free package inspect payload.
    public var inspect: AteliaPackageInspect {
        AteliaPackageInspect(
            packageId: packageId,
            package: package,
            manifest: manifest,
            block: block,
            permissions: permissions,
            services: services,
            rollbackAvailable: rollbackAvailable,
            rollbackSnapshot: rollbackSnapshot,
            source: source,
            trust: trust
        )
    }

    /// Creates a package inspect response.
    public init(
        metadata: AteliaProtocolMetadata,
        packageId: String,
        package: AteliaPackageStatus,
        manifest: AteliaPackageManifest,
        block: AteliaPackageTrustIndexEntry.Block? = nil,
        permissions: [String] = [],
        services: AteliaPackageServices = .init(),
        rollbackAvailable: Bool = false,
        rollbackSnapshot: AteliaPackageRollbackRecord.RollbackSnapshot? = nil,
        source: AteliaPackageTrustIndexEntry.SourceSnapshot,
        trust: AteliaPackageTrustIndexEntry.Publication? = nil
    ) {
        self.metadata = metadata
        self.packageId = packageId
        self.package = package
        self.manifest = manifest
        self.block = block
        self.permissions = permissions
        self.services = services
        self.rollbackAvailable = rollbackAvailable
        self.rollbackSnapshot = rollbackSnapshot
        self.source = source
        self.trust = trust
    }

    /// Decodes with defaults when optional detail fields are omitted.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try container.decode(AteliaProtocolMetadata.self, forKey: .metadata)
        self.package = try container.decode(AteliaPackageStatus.self, forKey: .package)
        self.packageId = try container.decodeIfPresent(String.self, forKey: .packageId) ?? package.packageId
        self.manifest = try container.decode(AteliaPackageManifest.self, forKey: .manifest)
        self.block = try container.decodeIfPresent(AteliaPackageTrustIndexEntry.Block.self, forKey: .block)
        self.permissions = try container.decodeIfPresent([String].self, forKey: .permissions) ?? []
        self.services = try container.decodeIfPresent(AteliaPackageServices.self, forKey: .services) ?? .init()
        self.rollbackAvailable = try container.decodeIfPresent(Bool.self, forKey: .rollbackAvailable) ?? false
        self.rollbackSnapshot = try container.decodeIfPresent(
            AteliaPackageRollbackRecord.RollbackSnapshot.self,
            forKey: .rollbackSnapshot
        )
        self.source = try container.decode(AteliaPackageTrustIndexEntry.SourceSnapshot.self, forKey: .source)
        self.trust = try container.decodeIfPresent(AteliaPackageTrustIndexEntry.Publication.self, forKey: .trust)
    }
}

/// Service manifests returned by package inspect.
public struct AteliaPackageServices: Sendable, Codable, Equatable {
    /// JSON keys for service sets.
    private enum CodingKeys: String, CodingKey {
        /// Provided service definitions.
        case provides
        /// Consumed service dependencies.
        case consumes
    }

    /// Provided services declared by this package.
    public var provides: [AteliaPackageServiceDefinition]
    /// Consumed services this package depends on.
    public var consumes: [AteliaPackageServiceDependency]

    /// Creates a service set.
    public init(
        provides: [AteliaPackageServiceDefinition] = [],
        consumes: [AteliaPackageServiceDependency] = []
    ) {
        self.provides = provides
        self.consumes = consumes
    }

    /// Decodes with defaults when optional fields are omitted.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.provides = try container.decodeIfPresent([AteliaPackageServiceDefinition].self, forKey: .provides) ?? []
        self.consumes = try container.decodeIfPresent([AteliaPackageServiceDependency].self, forKey: .consumes) ?? []
    }
}

/// Service definition for a service this package provides.
public struct AteliaPackageServiceDefinition: Sendable, Codable, Equatable {
    /// JSON keys for a provided service definition.
    private enum CodingKeys: String, CodingKey {
        /// Service identifier.
        case service
        /// Method within the service.
        case method
        /// Schema version for the service method.
        case schemaVersion = "schema_version"
        /// Canonical array of permissions required by the service method.
        case requiredPermissions = "required_permissions"
        /// Compatibility field for legacy single-permission declarations.
        case requiredPermission = "required_permission"
    }

    /// Service identifier.
    public var service: String
    /// Method within the service.
    public var method: String
    /// Schema version for service contract compatibility.
    public var schemaVersion: String
    /// Canonical array of permissions required to call this service.
    public var requiredPermissions: [String]

    /// Creates a provided service definition.
    public init(
        service: String,
        method: String,
        schemaVersion: String,
        requiredPermissions: [String]
    ) {
        self.service = service
        self.method = method
        self.schemaVersion = schemaVersion
        self.requiredPermissions = requiredPermissions
    }

    /// Decodes canonical `required_permissions` with legacy `required_permission` compatibility.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.service = try container.decode(String.self, forKey: .service)
        self.method = try container.decode(String.self, forKey: .method)
        self.schemaVersion = try container.decode(String.self, forKey: .schemaVersion)

        let canonicalPermissions = try container.decodeIfPresent([String].self, forKey: .requiredPermissions) ?? []
        if !canonicalPermissions.isEmpty {
            self.requiredPermissions = canonicalPermissions
            return
        }

        self.requiredPermissions = try container.decodeIfPresent(String.self, forKey: .requiredPermission).map { [$0] } ?? []
    }

    /// Encodes canonical `required_permissions` only.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(service, forKey: .service)
        try container.encode(method, forKey: .method)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(requiredPermissions, forKey: .requiredPermissions)
    }
}

/// Service dependency this package consumes from another package.
public struct AteliaPackageServiceDependency: Sendable, Codable, Equatable {
    /// JSON keys for a consumed service dependency.
    private enum CodingKeys: String, CodingKey {
        /// Extension providing the consumed service.
        case extensionId = "extension_id"
        /// Consumed service identifier.
        case service
        /// Method within the consumed service.
        case method
        /// Schema version for the consumed service method.
        case schemaVersion = "schema_version"
        /// Canonical set of grants required by the dependency call.
        case grants
        /// Compatibility field for legacy single permission declarations.
        case requiredPermission = "required_permission"
    }

    /// Extension identifier that provides the dependency.
    public var extensionId: String
    /// Service identifier.
    public var service: String
    /// Method within the service.
    public var method: String
    /// Schema version for service contract compatibility.
    public var schemaVersion: String
    /// Grants required by the dependency call.
    public var grants: [String]

    /// Creates a consumed service dependency.
    public init(
        extensionId: String,
        service: String,
        method: String,
        schemaVersion: String,
        grants: [String]
    ) {
        self.extensionId = extensionId
        self.service = service
        self.method = method
        self.schemaVersion = schemaVersion
        self.grants = grants
    }

    /// Decodes compatibility `required_permission` into canonical `grants` when needed.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.extensionId = try container.decode(String.self, forKey: .extensionId)
        self.service = try container.decode(String.self, forKey: .service)
        self.method = try container.decode(String.self, forKey: .method)
        self.schemaVersion = try container.decode(String.self, forKey: .schemaVersion)

        let decodedGrants = try container.decodeIfPresent([String].self, forKey: .grants) ?? []
        if !decodedGrants.isEmpty {
            self.grants = decodedGrants
            return
        }

        self.grants = try container.decodeIfPresent(String.self, forKey: .requiredPermission).map { [$0] } ?? []
    }

    /// Encodes canonical `grants` only.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extensionId, forKey: .extensionId)
        try container.encode(service, forKey: .service)
        try container.encode(method, forKey: .method)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(grants, forKey: .grants)
    }
}
