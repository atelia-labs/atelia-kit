import Foundation

/// Rollback response envelope returned by Secretary.
public struct AteliaPackageRollbackResponse: Sendable, Codable, Equatable {
    /// JSON keys for the rollback response envelope.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata attached to the response envelope.
        case metadata
        /// The rollback record returned by Secretary.
        case record
    }

    /// Protocol metadata attached to the rollback response.
    public var metadata: AteliaProtocolMetadata
    /// Rollback record for the target package.
    public var record: AteliaPackageRollbackRecord

    /// Creates a rollback response.
    public init(metadata: AteliaProtocolMetadata, record: AteliaPackageRollbackRecord) {
        self.metadata = metadata
        self.record = record
    }
}

/// Rollback record returned by Secretary after a package operation.
public struct AteliaPackageRollbackRecord: Sendable, Codable, Equatable, Identifiable {
    /// JSON keys for rollback records.
    private enum CodingKeys: String, CodingKey {
        /// Stable package identifier.
        case packageId = "id"
        /// Package version after the rollback completes.
        case version
        /// Manifest digest retained by Secretary.
        case manifestDigest = "manifest_digest"
        /// Artifact digest retained by Secretary.
        case artifactDigest = "artifact_digest"
        /// Source and provenance snapshot.
        case source
        /// Trust boundary classification.
        case boundary
        /// Install or block status after the rollback.
        case status
        /// Previous package version, when known.
        case previousVersion = "previous_version"
        /// Permissions retained by the package.
        case approvedPermissions = "approved_permissions"
        /// Snapshot of the target rollback state.
        case rollbackSnapshot = "rollback_snapshot"
    }

    /// Snapshot of the target rollback state.
    public struct RollbackSnapshot: Sendable, Codable, Equatable {
        /// JSON keys for rollback snapshots.
        private enum CodingKeys: String, CodingKey {
            /// Manifest digest retained by Secretary.
            case manifestDigest = "manifest_digest"
            /// Artifact digest retained by Secretary.
            case artifactDigest = "artifact_digest"
        }

        /// Manifest digest retained by Secretary.
        public var manifestDigest: String
        /// Artifact digest retained by Secretary.
        public var artifactDigest: String

        /// Creates a rollback snapshot.
        public init(manifestDigest: String, artifactDigest: String) {
            self.manifestDigest = manifestDigest
            self.artifactDigest = artifactDigest
        }
    }

    /// Stable package identifier.
    public var packageId: String
    /// Package version after the rollback completes.
    public var version: String
    /// Manifest digest retained by Secretary.
    public var manifestDigest: String
    /// Artifact digest retained by Secretary.
    public var artifactDigest: String
    /// Source and provenance snapshot.
    public var source: AteliaPackageTrustIndexEntry.SourceSnapshot
    /// Trust boundary classification.
    public var boundary: AteliaPackageTrustIndexEntry.Boundary
    /// Install or block status after the rollback.
    public var status: AteliaPackageTrustIndexEntry.Status
    /// Previous package version, when known.
    public var previousVersion: String?
    /// Permissions retained by the package.
    public var approvedPermissions: [String]
    /// Snapshot of the target rollback state.
    public var rollbackSnapshot: RollbackSnapshot?

    /// Stable package identity for collection diffing.
    public var id: String { packageId }

    /// Creates a rollback record.
    public init(
        packageId: String,
        version: String,
        manifestDigest: String,
        artifactDigest: String,
        source: AteliaPackageTrustIndexEntry.SourceSnapshot,
        boundary: AteliaPackageTrustIndexEntry.Boundary,
        status: AteliaPackageTrustIndexEntry.Status,
        previousVersion: String? = nil,
        approvedPermissions: [String] = [],
        rollbackSnapshot: RollbackSnapshot? = nil
    ) {
        self.packageId = packageId
        self.version = version
        self.manifestDigest = manifestDigest
        self.artifactDigest = artifactDigest
        self.source = source
        self.boundary = boundary
        self.status = status
        self.previousVersion = previousVersion
        self.approvedPermissions = approvedPermissions
        self.rollbackSnapshot = rollbackSnapshot
    }
}
