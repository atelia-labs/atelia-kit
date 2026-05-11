import Foundation

/// Read-only package trust index projection returned by Secretary.
public struct AteliaPackageTrustIndexResponse: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case metadata
        case packages
    }

    /// Protocol metadata attached to the trust index response.
    public var metadata: AteliaProtocolMetadata
    /// Trust-index entries for visible packages, including blocked ones.
    public var packages: [AteliaPackageTrustIndexEntry]

    /// Creates a trust index response.
    public init(metadata: AteliaProtocolMetadata, packages: [AteliaPackageTrustIndexEntry]) {
        self.metadata = metadata
        self.packages = packages
    }
}

/// Trust-index entry for one installed package revision.
public struct AteliaPackageTrustIndexEntry: Sendable, Codable, Equatable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case packageId = "package_id"
        case version
        case status
        case boundary
        case manifestDigest = "manifest_digest"
        case artifactDigest = "artifact_digest"
        case source
        case block
    }

    /// Install status for trust-index projections.
    public enum Status: Sendable, Codable, Equatable, RawRepresentable {
        /// Package is installed and enabled.
        case installed
        /// Package is installed but disabled.
        case disabled
        /// Package is blocked by Secretary policy or blocklist.
        case blocked
        /// Package update is in progress.
        case updating
        /// Package rollback is in progress.
        case rollbackInProgress
        /// Previous package version is installed after rollback.
        case installedPreviousVersion
        /// Unknown status retained for forward compatibility.
        case unknown(String)

        /// Creates a status from its Secretary wire value.
        public init(rawValue: String) {
            switch rawValue {
            case "installed":
                self = .installed
            case "disabled":
                self = .disabled
            case "blocked":
                self = .blocked
            case "updating":
                self = .updating
            case "rollback_in_progress":
                self = .rollbackInProgress
            case "installed_previous_version":
                self = .installedPreviousVersion
            default:
                self = .unknown(rawValue)
            }
        }

        /// Secretary wire value for the status.
        public var rawValue: String {
            switch self {
            case .installed:
                return "installed"
            case .disabled:
                return "disabled"
            case .blocked:
                return "blocked"
            case .updating:
                return "updating"
            case .rollbackInProgress:
                return "rollback_in_progress"
            case .installedPreviousVersion:
                return "installed_previous_version"
            case .unknown(let rawValue):
                return rawValue
            }
        }

        /// Decodes a status while preserving unknown wire values.
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        /// Encodes the status as its Secretary wire value.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    /// Boundary classification for the package revision.
    public enum Boundary: Sendable, Codable, Equatable, RawRepresentable {
        /// Host-official package boundary.
        case official
        /// Third-party package boundary.
        case thirdParty
        /// Local development package boundary.
        case localDevelopment
        /// Unknown boundary retained for forward compatibility.
        case unknown(String)

        /// Creates a boundary from its Secretary wire value.
        public init(rawValue: String) {
            switch rawValue {
            case "official":
                self = .official
            case "third_party":
                self = .thirdParty
            case "local_development":
                self = .localDevelopment
            default:
                self = .unknown(rawValue)
            }
        }

        /// Secretary wire value for the boundary.
        public var rawValue: String {
            switch self {
            case .official:
                return "official"
            case .thirdParty:
                return "third_party"
            case .localDevelopment:
                return "local_development"
            case .unknown(let rawValue):
                return rawValue
            }
        }

        /// Decodes a boundary while preserving unknown wire values.
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        /// Encodes the boundary as its Secretary wire value.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    /// Snapshot of the package source and retained provenance metadata.
    public struct SourceSnapshot: Sendable, Codable, Equatable {
        private enum CodingKeys: String, CodingKey {
            case source
            case repository
            case sourceRef = "ref"
            case manifestPath = "manifest_path"
            case commit
            case registryIdentity = "registry_identity"
            case lineage
            case publication
        }

        /// Provenance source kind retained with the install record.
        public var source: String?
        /// Source repository, when repository-backed.
        public var repository: String?
        /// Source ref, when repository-backed.
        public var sourceRef: String?
        /// Manifest path inside the source repository.
        public var manifestPath: String?
        /// Source commit retained for audit.
        public var commit: String?
        /// Registry identity, when registry-backed.
        public var registryIdentity: String?
        /// Lineage metadata retained with the installed revision.
        public var lineage: Lineage?
        /// Publication metadata retained with the installed revision.
        public var publication: Publication?

        /// Creates a source snapshot.
        public init(
            source: String? = nil,
            repository: String? = nil,
            sourceRef: String? = nil,
            manifestPath: String? = nil,
            commit: String? = nil,
            registryIdentity: String? = nil,
            lineage: Lineage? = nil,
            publication: Publication? = nil
        ) {
            self.source = source
            self.repository = repository
            self.sourceRef = sourceRef
            self.manifestPath = manifestPath
            self.commit = commit
            self.registryIdentity = registryIdentity
            self.lineage = lineage
            self.publication = publication
        }
    }

    /// Lineage metadata retained with a package revision.
    public struct Lineage: Sendable, Codable, Equatable {
        private enum CodingKeys: String, CodingKey {
            case parentId = "parent_id"
            case parentVersion = "parent_version"
            case parentManifestDigest = "parent_manifest_digest"
            case relationship
        }

        /// Relationship between the package and its parent.
        public enum Relationship: Sendable, Codable, Equatable, RawRepresentable {
            /// User-owned remix relationship.
            case remix
            /// Fork relationship.
            case fork
            /// Derived package relationship.
            case derived
            /// Unknown relationship retained for forward compatibility.
            case unknown(String)

            /// Creates a lineage relationship from its Secretary wire value.
            public init(rawValue: String) {
                switch rawValue {
                case "remix":
                    self = .remix
                case "fork":
                    self = .fork
                case "derived":
                    self = .derived
                default:
                    self = .unknown(rawValue)
                }
            }

            /// Secretary wire value for the relationship.
            public var rawValue: String {
                switch self {
                case .remix:
                    return "remix"
                case .fork:
                    return "fork"
                case .derived:
                    return "derived"
                case .unknown(let rawValue):
                    return rawValue
                }
            }

            /// Decodes a relationship while preserving unknown wire values.
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self = Self(rawValue: rawValue)
            }

            /// Encodes the relationship as its Secretary wire value.
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(rawValue)
            }
        }

        /// Parent package id.
        public var parentId: String
        /// Parent package version, when known.
        public var parentVersion: String?
        /// Parent manifest digest, when known.
        public var parentManifestDigest: String?
        /// Relationship to the parent package.
        public var relationship: Relationship

        /// Creates a lineage snapshot.
        public init(
            parentId: String,
            parentVersion: String? = nil,
            parentManifestDigest: String? = nil,
            relationship: Relationship
        ) {
            self.parentId = parentId
            self.parentVersion = parentVersion
            self.parentManifestDigest = parentManifestDigest
            self.relationship = relationship
        }
    }

    /// Publication metadata retained with a package revision.
    public struct Publication: Sendable, Codable, Equatable {
        private enum CodingKeys: String, CodingKey {
            case visibility
            case registrySubmission = "registry_submission"
        }

        /// Visibility state for the publication.
        public enum Visibility: Sendable, Codable, Equatable, RawRepresentable {
            /// Private remix visible inside the user's harness or workspace.
            case privateRemix
            /// Directly shared package that is not publicly searchable.
            case unlistedShare
            /// Publicly searchable package.
            case publicSearchable
            /// Host-official publication.
            case official
            /// Unknown visibility retained for forward compatibility.
            case unknown(String)

            /// Creates a visibility value from its Secretary wire value.
            public init(rawValue: String) {
                switch rawValue {
                case "private_remix":
                    self = .privateRemix
                case "unlisted_share":
                    self = .unlistedShare
                case "public_searchable":
                    self = .publicSearchable
                case "official":
                    self = .official
                default:
                    self = .unknown(rawValue)
                }
            }

            /// Secretary wire value for the visibility.
            public var rawValue: String {
                switch self {
                case .privateRemix:
                    return "private_remix"
                case .unlistedShare:
                    return "unlisted_share"
                case .publicSearchable:
                    return "public_searchable"
                case .official:
                    return "official"
                case .unknown(let rawValue):
                    return rawValue
                }
            }

            /// Decodes a visibility value while preserving unknown wire values.
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self = Self(rawValue: rawValue)
            }

            /// Encodes the visibility as its Secretary wire value.
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(rawValue)
            }
        }

        /// Registry submission state for the publication.
        public enum RegistrySubmission: Sendable, Codable, Equatable, RawRepresentable {
            /// Package has not been submitted to a registry.
            case notSubmitted
            /// Package has been submitted and awaits a registry decision.
            case submitted
            /// Package has been accepted by registry policy.
            case accepted
            /// Package has been rejected by registry policy.
            case rejected
            /// Unknown submission state retained for forward compatibility.
            case unknown(String)

            /// Creates a registry submission state from its Secretary wire value.
            public init(rawValue: String) {
                switch rawValue {
                case "not_submitted":
                    self = .notSubmitted
                case "submitted":
                    self = .submitted
                case "accepted":
                    self = .accepted
                case "rejected":
                    self = .rejected
                default:
                    self = .unknown(rawValue)
                }
            }

            /// Secretary wire value for the registry submission state.
            public var rawValue: String {
                switch self {
                case .notSubmitted:
                    return "not_submitted"
                case .submitted:
                    return "submitted"
                case .accepted:
                    return "accepted"
                case .rejected:
                    return "rejected"
                case .unknown(let rawValue):
                    return rawValue
                }
            }

            /// Decodes a registry submission state while preserving unknown wire values.
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self = Self(rawValue: rawValue)
            }

            /// Encodes the registry submission state as its Secretary wire value.
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(rawValue)
            }
        }

        /// Visibility classification for the package publication.
        public var visibility: Visibility
        /// Registry submission state for the package revision.
        public var registrySubmission: RegistrySubmission

        /// Creates a publication snapshot.
        public init(visibility: Visibility, registrySubmission: RegistrySubmission) {
            self.visibility = visibility
            self.registrySubmission = registrySubmission
        }
    }

    /// Blocklist marker retained with the trust index.
    public struct Block: Sendable, Codable, Equatable {
        private enum CodingKeys: String, CodingKey {
            case reason
            case key
        }

        /// Why the package is blocked.
        public enum Reason: Sendable, Codable, Equatable, RawRepresentable {
            /// Package was classified as malware.
            case malware
            /// Package manifest did not match expected metadata or digest.
            case manifestMismatch
            /// Package requested excessive permissions.
            case overPermissioned
            /// Package version is vulnerable.
            case vulnerableVersion
            /// Package signer is compromised.
            case compromisedSigner
            /// Package violates policy.
            case policyViolation
            /// User explicitly blocked the package.
            case userBlocked
            /// Registry removed the package.
            case registryRemoved
            /// Unknown reason retained for forward compatibility.
            case unknown(String)

            /// Creates a block reason from its Secretary wire value.
            public init(rawValue: String) {
                switch rawValue {
                case "malware":
                    self = .malware
                case "manifest_mismatch":
                    self = .manifestMismatch
                case "over_permissioned":
                    self = .overPermissioned
                case "vulnerable_version":
                    self = .vulnerableVersion
                case "compromised_signer":
                    self = .compromisedSigner
                case "policy_violation":
                    self = .policyViolation
                case "user_blocked":
                    self = .userBlocked
                case "registry_removed":
                    self = .registryRemoved
                default:
                    self = .unknown(rawValue)
                }
            }

            /// Secretary wire value for the block reason.
            public var rawValue: String {
                switch self {
                case .malware:
                    return "malware"
                case .manifestMismatch:
                    return "manifest_mismatch"
                case .overPermissioned:
                    return "over_permissioned"
                case .vulnerableVersion:
                    return "vulnerable_version"
                case .compromisedSigner:
                    return "compromised_signer"
                case .policyViolation:
                    return "policy_violation"
                case .userBlocked:
                    return "user_blocked"
                case .registryRemoved:
                    return "registry_removed"
                case .unknown(let rawValue):
                    return rawValue
                }
            }

            /// Decodes a block reason while preserving unknown wire values.
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self = Self(rawValue: rawValue)
            }

            /// Encodes the block reason as its Secretary wire value.
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(rawValue)
            }
        }

        /// Blocklist key matched by Secretary.
        public enum Key: Sendable, Codable, Equatable {
            /// Block matched by package id.
            case extensionId(String)
            /// Block matched by package id and version.
            case version(id: String, version: String)
            /// Block matched by artifact digest.
            case artifactDigest(String)
            /// Block matched by signer.
            case signer(String)
            /// Block matched by publisher.
            case publisher(String)
            /// Block matched by source repository.
            case sourceRepository(String)
            /// Block matched by permission pattern.
            case permissionPattern(String)
            /// Block matched by vulnerability identifier.
            case vulnerabilityId(String)
            /// Unknown key name retained for decode-only forward compatibility.
            case unknown(name: String)

            private struct DynamicCodingKey: CodingKey {
                var stringValue: String
                var intValue: Int? { nil }

                /// Creates a dynamic key from a string value.
                init?(stringValue: String) {
                    self.stringValue = stringValue
                }

                /// Dynamic block keys do not support integer coding keys.
                init?(intValue: Int) {
                    _ = intValue
                    return nil
                }
            }

            private enum VersionCodingKeys: String, CodingKey {
                case id
                case version
            }

            /// Decodes the externally tagged Secretary block key.
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: DynamicCodingKey.self)
                let keys = container.allKeys
                guard keys.count == 1, let key = keys.first else {
                    throw DecodingError.dataCorrupted(.init(
                        codingPath: container.codingPath,
                        debugDescription: "Expected exactly one key in block.key, found \(keys.count)."
                    ))
                }

                switch key.stringValue {
                case "extension_id":
                    self = .extensionId(try container.decode(String.self, forKey: key))
                case "version":
                    let version = try container.nestedContainer(keyedBy: VersionCodingKeys.self, forKey: key)
                    self = .version(
                        id: try version.decode(String.self, forKey: .id),
                        version: try version.decode(String.self, forKey: .version)
                    )
                case "artifact_digest":
                    self = .artifactDigest(try container.decode(String.self, forKey: key))
                case "signer":
                    self = .signer(try container.decode(String.self, forKey: key))
                case "publisher":
                    self = .publisher(try container.decode(String.self, forKey: key))
                case "source_repository":
                    self = .sourceRepository(try container.decode(String.self, forKey: key))
                case "permission_pattern":
                    self = .permissionPattern(try container.decode(String.self, forKey: key))
                case "vulnerability_id":
                    self = .vulnerabilityId(try container.decode(String.self, forKey: key))
                default:
                    self = .unknown(name: key.stringValue)
                }
            }

            /// Encodes the externally tagged Secretary block key.
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: DynamicCodingKey.self)
                switch self {
                case .extensionId(let id):
                    try container.encode(id, forKey: DynamicCodingKey(stringValue: "extension_id")!)
                case .version(let id, let version):
                    var versionContainer = container.nestedContainer(
                        keyedBy: VersionCodingKeys.self,
                        forKey: DynamicCodingKey(stringValue: "version")!
                    )
                    try versionContainer.encode(id, forKey: .id)
                    try versionContainer.encode(version, forKey: .version)
                case .artifactDigest(let digest):
                    try container.encode(digest, forKey: DynamicCodingKey(stringValue: "artifact_digest")!)
                case .signer(let signer):
                    try container.encode(signer, forKey: DynamicCodingKey(stringValue: "signer")!)
                case .publisher(let publisher):
                    try container.encode(publisher, forKey: DynamicCodingKey(stringValue: "publisher")!)
                case .sourceRepository(let repository):
                    try container.encode(repository, forKey: DynamicCodingKey(stringValue: "source_repository")!)
                case .permissionPattern(let pattern):
                    try container.encode(pattern, forKey: DynamicCodingKey(stringValue: "permission_pattern")!)
                case .vulnerabilityId(let id):
                    try container.encode(id, forKey: DynamicCodingKey(stringValue: "vulnerability_id")!)
                case .unknown(let name):
                    throw EncodingError.invalidValue(
                        self,
                        .init(
                            codingPath: container.codingPath,
                            debugDescription: "Cannot encode unknown block key '\(name)' without preserving its raw value."
                        )
                    )
                }
            }
        }

        /// Block reason from the Secretary blocklist.
        public var reason: Reason
        /// Block key matched by Secretary.
        public var key: Key

        /// Creates a block marker.
        public init(reason: Reason, key: Key) {
            self.reason = reason
            self.key = key
        }
    }

    /// Package id for the trust-index entry.
    public var packageId: String
    /// Revision version, when known.
    public var version: String?
    /// Install status, when the package is installed or blocked.
    public var status: Status?
    /// Boundary classification, when the install record is present.
    public var boundary: Boundary?
    /// Manifest digest retained by the install record.
    public var manifestDigest: String?
    /// Artifact digest retained by the install record.
    public var artifactDigest: String?
    /// Source snapshot retained by the install record.
    public var source: SourceSnapshot?
    /// Block marker if the package is blocklisted.
    public var block: Block?

    /// Stable package identity for SwiftUI and collection diffing.
    public var id: String { packageId }

    /// Creates a trust-index entry.
    public init(
        packageId: String,
        version: String? = nil,
        status: Status? = nil,
        boundary: Boundary? = nil,
        manifestDigest: String? = nil,
        artifactDigest: String? = nil,
        source: SourceSnapshot? = nil,
        block: Block? = nil
    ) {
        self.packageId = packageId
        self.version = version
        self.status = status
        self.boundary = boundary
        self.manifestDigest = manifestDigest
        self.artifactDigest = artifactDigest
        self.source = source
        self.block = block
    }
}
