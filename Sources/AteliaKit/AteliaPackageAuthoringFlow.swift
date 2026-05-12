import Foundation

/// Canonical package source classes used by client package authoring flows.
public enum AteliaPackageSourceClass: Sendable, Codable, Equatable, Hashable, RawRepresentable {
    case hostShippedBuiltIn
    case workspaceLocal
    case userSelected
    case verifiedRegistry
    case bundledOfficial
    case development
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "host-shipped-built-in":
            self = .hostShippedBuiltIn
        case "workspace-local":
            self = .workspaceLocal
        case "user-selected":
            self = .userSelected
        case "verified-registry":
            self = .verifiedRegistry
        case "bundled-official":
            self = .bundledOfficial
        case "development":
            self = .development
        default:
            self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .hostShippedBuiltIn:
            return "host-shipped-built-in"
        case .workspaceLocal:
            return "workspace-local"
        case .userSelected:
            return "user-selected"
        case .verifiedRegistry:
            return "verified-registry"
        case .bundledOfficial:
            return "bundled-official"
        case .development:
            return "development"
        case .unknown(let rawValue):
            return rawValue
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = Self(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Client-visible package authoring flow stages.
public enum AteliaPackageAuthoringStage: Sendable, Codable, Equatable, Hashable, RawRepresentable {
    case install
    case inspect
    case validate
    case remix
    case publish
    case registrySearch
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "install":
            self = .install
        case "inspect":
            self = .inspect
        case "validate":
            self = .validate
        case "remix":
            self = .remix
        case "publish":
            self = .publish
        case "registry_search":
            self = .registrySearch
        default:
            self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .install:
            return "install"
        case .inspect:
            return "inspect"
        case .validate:
            return "validate"
        case .remix:
            return "remix"
        case .publish:
            return "publish"
        case .registrySearch:
            return "registry_search"
        case .unknown(let rawValue):
            return rawValue
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = Self(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Client-visible state for one package authoring flow step.
public enum AteliaPackageAuthoringStepState: Sendable, Codable, Equatable, Hashable, RawRepresentable {
    case available
    case blocked
    case requiresValidation
    case requiresConsent
    case inProgress
    case complete
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "available":
            self = .available
        case "blocked":
            self = .blocked
        case "requires_validation":
            self = .requiresValidation
        case "requires_consent":
            self = .requiresConsent
        case "in_progress":
            self = .inProgress
        case "complete":
            self = .complete
        default:
            self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .available:
            return "available"
        case .blocked:
            return "blocked"
        case .requiresValidation:
            return "requires_validation"
        case .requiresConsent:
            return "requires_consent"
        case .inProgress:
            return "in_progress"
        case .complete:
            return "complete"
        case .unknown(let rawValue):
            return rawValue
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = Self(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// GitHub-backed publication actions the clients can show without becoming a package storefront.
public enum AteliaPackageGitHubPublicationAction: Sendable, Codable, Equatable, Hashable, RawRepresentable {
    case createRepository
    case forkRepository
    case createBranch
    case commitChanges
    case openPullRequest
    case prepareReleaseMetadata
    case submitRegistryMetadata
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "create_repository":
            self = .createRepository
        case "fork_repository":
            self = .forkRepository
        case "create_branch":
            self = .createBranch
        case "commit_changes":
            self = .commitChanges
        case "open_pull_request":
            self = .openPullRequest
        case "prepare_release_metadata":
            self = .prepareReleaseMetadata
        case "submit_registry_metadata":
            self = .submitRegistryMetadata
        default:
            self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .createRepository:
            return "create_repository"
        case .forkRepository:
            return "fork_repository"
        case .createBranch:
            return "create_branch"
        case .commitChanges:
            return "commit_changes"
        case .openPullRequest:
            return "open_pull_request"
        case .prepareReleaseMetadata:
            return "prepare_release_metadata"
        case .submitRegistryMetadata:
            return "submit_registry_metadata"
        case .unknown(let rawValue):
            return rawValue
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = Self(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Publication visibility for a private remix or GitHub-backed package source.
public enum AteliaPackagePublicationVisibility: Sendable, Codable, Equatable, Hashable, RawRepresentable {
    case privateRemix
    case unlistedShare
    case publicSearchable
    case official
    case unknown(String)

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

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = Self(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// GitHub-backed package source reference used by install, remix, and publication flows.
public struct AteliaPackageGitHubSourceReference: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case repository
        case ref
        case manifestPath = "manifest_path"
        case manifestDigest = "manifest_digest"
        case artifactDigests = "artifact_digests"
    }

    public var repository: String
    public var ref: String?
    public var manifestPath: String
    public var manifestDigest: String?
    public var artifactDigests: [String]

    public init(
        repository: String,
        ref: String? = nil,
        manifestPath: String,
        manifestDigest: String? = nil,
        artifactDigests: [String] = []
    ) {
        self.repository = repository
        self.ref = ref
        self.manifestPath = manifestPath
        self.manifestDigest = manifestDigest
        self.artifactDigests = artifactDigests
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.repository = try container.decode(String.self, forKey: .repository)
        self.ref = try container.decodeIfPresent(String.self, forKey: .ref)
        self.manifestPath = try container.decode(String.self, forKey: .manifestPath)
        self.manifestDigest = try container.decodeIfPresent(String.self, forKey: .manifestDigest)
        self.artifactDigests = try container.decodeIfPresent([String].self, forKey: .artifactDigests) ?? []
    }
}

/// Client projection for a GitHub-backed package publication path.
public struct AteliaPackagePublicationPlan: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case visibility
        case sourceClass = "source_class"
        case source
        case githubActions = "github_actions"
        case requiresRegistrySubmission = "requires_registry_submission"
        case productionInstallable = "production_installable"
    }

    public var visibility: AteliaPackagePublicationVisibility
    public var sourceClass: AteliaPackageSourceClass
    public var source: AteliaPackageGitHubSourceReference?
    public var githubActions: [AteliaPackageGitHubPublicationAction]
    public var requiresRegistrySubmission: Bool
    public var productionInstallable: Bool

    public init(
        visibility: AteliaPackagePublicationVisibility,
        sourceClass: AteliaPackageSourceClass,
        source: AteliaPackageGitHubSourceReference? = nil,
        githubActions: [AteliaPackageGitHubPublicationAction] = [],
        requiresRegistrySubmission: Bool,
        productionInstallable: Bool
    ) {
        self.visibility = visibility
        self.sourceClass = sourceClass
        self.source = source
        self.githubActions = githubActions
        self.requiresRegistrySubmission = requiresRegistrySubmission
        self.productionInstallable = productionInstallable
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.visibility = try container.decode(AteliaPackagePublicationVisibility.self, forKey: .visibility)
        self.sourceClass = try container.decode(AteliaPackageSourceClass.self, forKey: .sourceClass)
        self.source = try container.decodeIfPresent(AteliaPackageGitHubSourceReference.self, forKey: .source)
        self.githubActions = try container.decodeIfPresent([AteliaPackageGitHubPublicationAction].self, forKey: .githubActions) ?? []
        self.requiresRegistrySubmission = try container.decode(Bool.self, forKey: .requiresRegistrySubmission)
        self.productionInstallable = try container.decode(Bool.self, forKey: .productionInstallable)
    }
}

/// One host-rendered step in the client package authoring flow.
public struct AteliaPackageAuthoringFlowStep: Sendable, Codable, Equatable, Identifiable {
    public typealias ID = AteliaPackageAuthoringStage

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case state
        case requiresExplicitConsent = "requires_explicit_consent"
        case policyNotes = "policy_notes"
    }

    public var id: AteliaPackageAuthoringStage
    public var title: String
    public var state: AteliaPackageAuthoringStepState
    public var requiresExplicitConsent: Bool
    public var policyNotes: [String]

    public init(
        id: AteliaPackageAuthoringStage,
        title: String,
        state: AteliaPackageAuthoringStepState,
        requiresExplicitConsent: Bool = false,
        policyNotes: [String] = []
    ) {
        self.id = id
        self.title = title
        self.state = state
        self.requiresExplicitConsent = requiresExplicitConsent
        self.policyNotes = policyNotes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(AteliaPackageAuthoringStage.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.state = try container.decode(AteliaPackageAuthoringStepState.self, forKey: .state)
        self.requiresExplicitConsent = try container.decodeIfPresent(Bool.self, forKey: .requiresExplicitConsent) ?? false
        self.policyNotes = try container.decodeIfPresent([String].self, forKey: .policyNotes) ?? []
    }
}

/// Shared Mac/iOS model for install, inspect, validate, remix, publish, and registry-search flows.
public struct AteliaPackageAuthoringFlow: Sendable, Codable, Equatable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case id = "package_id"
        case sourceClass = "source_class"
        case source
        case steps
        case publicationPlan = "publication_plan"
    }

    public var id: String
    public var sourceClass: AteliaPackageSourceClass
    public var source: AteliaPackageGitHubSourceReference?
    public var steps: [AteliaPackageAuthoringFlowStep]
    public var publicationPlan: AteliaPackagePublicationPlan?

    public init(
        packageId: String,
        sourceClass: AteliaPackageSourceClass,
        source: AteliaPackageGitHubSourceReference? = nil,
        steps: [AteliaPackageAuthoringFlowStep],
        publicationPlan: AteliaPackagePublicationPlan? = nil
    ) {
        self.id = packageId
        self.sourceClass = sourceClass
        self.source = source
        self.steps = steps
        self.publicationPlan = publicationPlan
    }

    /// Returns steps that must stop for user consent before the client continues.
    public var stepsRequiringConsent: [AteliaPackageAuthoringFlowStep] {
        steps.filter { step in
            step.requiresExplicitConsent || step.state == .requiresConsent
        }
    }
}

/// Request payload used to fetch the package authoring flow contract for a package id.
public struct AteliaPackageAuthoringFlowRequest: Sendable, Codable, Equatable {
    /// JSON keys for authoring-flow request bodies.
    private enum CodingKeys: String, CodingKey {
        /// Package identifier whose authoring flow is requested.
        case packageId = "package_id"
        /// Whether private or draft-only steps should be returned.
        case includePrivateSteps = "include_private_steps"
    }

    /// Package identifier.
    public var packageId: String
    /// Whether private/draft-only flow steps should be returned.
    public var includePrivateSteps: Bool

    /// Creates a package authoring flow request.
    public init(
        packageId: String,
        includePrivateSteps: Bool = true
    ) {
        self.packageId = packageId
        self.includePrivateSteps = includePrivateSteps
    }

    /// Decodes authoring-flow requests preserving default values when omitted.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.packageId = try container.decode(String.self, forKey: .packageId)
        self.includePrivateSteps = try container.contains(.includePrivateSteps)
            ? container.decode(Bool.self, forKey: .includePrivateSteps)
            : true
    }
}

/// Envelope returned for authoring-flow retrieval.
public struct AteliaPackageAuthoringFlowResponse: Sendable, Codable, Equatable {
    /// JSON keys for authoring-flow responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Authoring flow details.
        case flow
    }

    /// Protocol metadata.
    public var metadata: AteliaProtocolMetadata
    /// Authoring flow payload used by UI contract and state machines.
    public var flow: AteliaPackageAuthoringFlow
}

/// Request payload used to trigger or refresh a package remix flow.
public struct AteliaPackageRemixRequest: Sendable, Codable, Equatable {
    /// JSON keys for remix request bodies.
    private enum CodingKeys: String, CodingKey {
        /// Package identifier being remixed.
        case packageId = "package_id"
        /// Source class for the remixed result.
        case sourceClass = "source_class"
        /// Source reference used by the remix operation.
        case source
        /// Optional manifest payload to seed the flow.
        case manifest
    }

    /// Package identifier being remixed.
    public var packageId: String
    /// Source class for the remix result.
    public var sourceClass: AteliaPackageSourceClass
    /// Source reference used by the remix operation.
    public var source: AteliaPackageGitHubSourceReference?
    /// Optional manifest payload used for manifest-aware remixes.
    public var manifest: AteliaPackageManifest?

    /// Creates a package remix request.
    public init(
        packageId: String,
        sourceClass: AteliaPackageSourceClass,
        source: AteliaPackageGitHubSourceReference? = nil,
        manifest: AteliaPackageManifest? = nil
    ) {
        self.packageId = packageId
        self.sourceClass = sourceClass
        self.source = source
        self.manifest = manifest
    }

    /// Decodes remix requests while preserving a workspace-local source fallback.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.packageId = try container.decode(String.self, forKey: .packageId)
        self.sourceClass = try container.contains(.sourceClass)
            ? container.decode(AteliaPackageSourceClass.self, forKey: .sourceClass)
            : .workspaceLocal
        self.source = try container.decodeIfPresent(
            AteliaPackageGitHubSourceReference.self,
            forKey: .source
        )
        self.manifest = try container.decodeIfPresent(
            AteliaPackageManifest.self,
            forKey: .manifest
        )
    }
}

/// Envelope returned after remix operations.
public struct AteliaPackageRemixResponse: Sendable, Codable, Equatable {
    /// JSON keys for remix responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Authoring flow details after remix submission.
        case flow
    }

    /// Protocol metadata.
    public var metadata: AteliaProtocolMetadata
    /// Authoring flow details after remix submission.
    public var flow: AteliaPackageAuthoringFlow
}

/// Request payload used to prepare a package publication flow.
public struct AteliaPackagePublicationRequest: Sendable, Codable, Equatable {
    /// JSON keys for publication request bodies.
    private enum CodingKeys: String, CodingKey {
        /// Package identifier being published.
        case packageId = "package_id"
        /// Source class for publication.
        case sourceClass = "source_class"
        /// Optional GitHub source reference when publication targets a source artifact.
        case source
        /// Publication visibility mode.
        case visibility
        /// Planned GitHub action list.
        case githubActions = "github_actions"
        /// Whether registry submission is required.
        case requiresRegistrySubmission = "requires_registry_submission"
        /// Whether publication artifacts are installable in production.
        case productionInstallable = "production_installable"
    }

    /// Package identifier being published.
    public var packageId: String
    /// Source class for publication.
    public var sourceClass: AteliaPackageSourceClass
    /// Optional GitHub source reference when publication targets a source artifact.
    public var source: AteliaPackageGitHubSourceReference?
    /// Publication visibility mode.
    public var visibility: AteliaPackagePublicationVisibility
    /// Planned GitHub actions for publication.
    public var githubActions: [AteliaPackageGitHubPublicationAction]
    /// Whether publication requires registry submission.
    public var requiresRegistrySubmission: Bool
    /// Whether published artifacts are production-installable.
    public var productionInstallable: Bool

    /// Creates a package publication request.
    public init(
        packageId: String,
        sourceClass: AteliaPackageSourceClass,
        source: AteliaPackageGitHubSourceReference? = nil,
        visibility: AteliaPackagePublicationVisibility,
        githubActions: [AteliaPackageGitHubPublicationAction] = [],
        requiresRegistrySubmission: Bool,
        productionInstallable: Bool
    ) {
        self.packageId = packageId
        self.sourceClass = sourceClass
        self.source = source
        self.visibility = visibility
        self.githubActions = githubActions
        self.requiresRegistrySubmission = requiresRegistrySubmission
        self.productionInstallable = productionInstallable
    }

    /// Decodes publication requests while preserving protocol defaults.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.packageId = try container.decode(String.self, forKey: .packageId)
        self.sourceClass = try container.contains(.sourceClass)
            ? container.decode(AteliaPackageSourceClass.self, forKey: .sourceClass)
            : .workspaceLocal
        self.source = try container.decodeIfPresent(
            AteliaPackageGitHubSourceReference.self,
            forKey: .source
        )
        self.visibility = try container.decode(AteliaPackagePublicationVisibility.self, forKey: .visibility)
        self.githubActions = try container.decodeIfPresent(
            [AteliaPackageGitHubPublicationAction].self,
            forKey: .githubActions
        ) ?? []
        self.requiresRegistrySubmission = try container.contains(.requiresRegistrySubmission)
            ? container.decode(Bool.self, forKey: .requiresRegistrySubmission)
            : true
        self.productionInstallable = try container.contains(.productionInstallable)
            ? container.decode(Bool.self, forKey: .productionInstallable)
            : true
    }
}

/// Envelope returned after publication preparation.
public struct AteliaPackagePublicationResponse: Sendable, Codable, Equatable {
    /// JSON keys for publication responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Authoring flow details after publication step.
        case flow
    }

    /// Protocol metadata.
    public var metadata: AteliaProtocolMetadata
    /// Authoring flow details after publication submission.
    public var flow: AteliaPackageAuthoringFlow
}

/// Registry-submission state used by publication contracts.
public enum AteliaPackageRegistrySubmissionState: Sendable, Codable, Equatable, Hashable, RawRepresentable {
    /// Registry submission has not been initiated.
    case notSubmitted
    /// Registry submission has been submitted and awaits a registry decision.
    case submitted
    /// Registry submission has been accepted for indexing.
    case accepted
    /// Registry submission has been rejected.
    case rejected
    /// Unknown registry submission state retained for forward compatibility.
    case unknown(String)

    /// Creates state from its Secretary wire value.
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

    /// Secretary wire value for state.
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

    /// Decodes registry submission state from wire value.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = Self(rawValue: try container.decode(String.self))
    }

    /// Encodes the registry submission state as wire value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Request payload for updating publication-to-registry state.
public struct AteliaPackageRegistrySubmissionRequest: Sendable, Codable, Equatable {
    /// JSON keys for registry-submission request bodies.
    private enum CodingKeys: String, CodingKey {
        /// Package identifier.
        case packageId = "package_id"
        /// Requested registry-submission state.
        case state
        /// Optional human-readable note for submission requests.
        case note
    }

    /// Package identifier.
    public var packageId: String
    /// Requested registry-submission state.
    public var state: AteliaPackageRegistrySubmissionState
    /// Optional human-readable note.
    public var note: String?

    /// Creates a registry-submission request.
    public init(
        packageId: String,
        state: AteliaPackageRegistrySubmissionState,
        note: String? = nil
    ) {
        self.packageId = packageId
        self.state = state
        self.note = note
    }

    /// Decodes registry-submission requests while preserving defaults.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.packageId = try container.decode(String.self, forKey: .packageId)
        self.state = try container.contains(.state)
            ? container.decode(AteliaPackageRegistrySubmissionState.self, forKey: .state)
            : .submitted
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
    }
}

/// Envelope returned by registry-submission operations.
public struct AteliaPackageRegistrySubmissionResponse: Sendable, Codable, Equatable {
    /// JSON keys for registry-submission responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Package identifier.
        case packageId = "package_id"
        /// Current registry-submission state.
        case state
        /// Optional submission note returned by the daemon.
        case message
        /// Optional current authoring flow.
        case flow
    }

    /// Protocol metadata.
    public var metadata: AteliaProtocolMetadata
    /// Package identifier.
    public var packageId: String
    /// Current registry-submission state.
    public var state: AteliaPackageRegistrySubmissionState
    /// Optional message from the service.
    public var message: String?
    /// Optional current authoring flow payload.
    public var flow: AteliaPackageAuthoringFlow?
}
