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
