import Foundation

/// Metadata returned with versioned daemon responses.
public struct AteliaProtocolMetadata: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol_version"
        case daemonVersion = "daemon_version"
        case storageVersion = "storage_version"
        case capabilities
    }

    public var protocolVersion: String
    public var daemonVersion: String
    public var storageVersion: String
    public var capabilities: [String]

    public init(
        protocolVersion: String,
        daemonVersion: String,
        storageVersion: String,
        capabilities: [String]
    ) {
        self.protocolVersion = protocolVersion
        self.daemonVersion = daemonVersion
        self.storageVersion = storageVersion
        self.capabilities = capabilities
    }
}

/// Opaque repository identity and scope advertised by Secretary.
public struct AteliaRepository: Sendable, Codable, Equatable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case repositoryId = "repository_id"
        case displayName = "display_name"
        case rootPath = "root_path"
        case allowedScope = "allowed_scope"
        case trustState = "trust_state"
        case createdAtUnixMilliseconds = "created_at_unix_ms"
        case updatedAtUnixMilliseconds = "updated_at_unix_ms"
    }

    public enum TrustState: String, Sendable, Codable, Equatable {
        case unspecified
        case trusted
        case readOnly = "read_only"
        case blocked
    }

    public var repositoryId: String
    public var displayName: String
    public var rootPath: String
    public var allowedScope: AteliaPathScope
    public var trustState: TrustState
    public var createdAtUnixMilliseconds: Int64
    public var updatedAtUnixMilliseconds: Int64

    public var id: String { repositoryId }

    public init(
        repositoryId: String,
        displayName: String,
        rootPath: String,
        allowedScope: AteliaPathScope,
        trustState: TrustState,
        createdAtUnixMilliseconds: Int64,
        updatedAtUnixMilliseconds: Int64
    ) {
        self.repositoryId = repositoryId
        self.displayName = displayName
        self.rootPath = rootPath
        self.allowedScope = allowedScope
        self.trustState = trustState
        self.createdAtUnixMilliseconds = createdAtUnixMilliseconds
        self.updatedAtUnixMilliseconds = updatedAtUnixMilliseconds
    }
}

/// Filesystem scope attached to repositories and job requests.
public struct AteliaPathScope: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case roots
        case includePatterns = "include_patterns"
        case excludePatterns = "exclude_patterns"
    }

    public enum Kind: String, Sendable, Codable, Equatable {
        case unspecified
        case repository
        case explicitPaths = "explicit_paths"
        case readOnly = "read_only"
    }

    public var kind: Kind
    public var roots: [String]
    public var includePatterns: [String]
    public var excludePatterns: [String]

    public init(
        kind: Kind,
        roots: [String] = [],
        includePatterns: [String] = [],
        excludePatterns: [String] = []
    ) {
        self.kind = kind
        self.roots = roots
        self.includePatterns = includePatterns
        self.excludePatterns = excludePatterns
    }
}

/// Platform-neutral project identity used by client coordination surfaces.
public struct AteliaProjectIdentity: Sendable, Codable, Equatable, Identifiable {
    public var id: String
    public var displayName: String
    public var repositoryId: String?

    public init(id: String, displayName: String, repositoryId: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.repositoryId = repositoryId
    }
}

/// Platform-neutral thread identity used by Mac and iOS navigation.
public struct AteliaThreadIdentity: Sendable, Codable, Equatable, Identifiable {
    public var id: String
    public var projectId: String
    public var title: String

    public init(id: String, projectId: String, title: String) {
        self.id = id
        self.projectId = projectId
        self.title = title
    }
}

/// Actor identity attached to jobs, policy decisions, and cancellation records.
public enum AteliaActor: Sendable, Codable, Equatable {
    case user(id: String, displayName: String?)
    case agent(id: String, displayName: String?)
    case `extension`(id: String)
    case system(id: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case displayName = "display_name"
    }

    private enum ActorType: String, Codable {
        case user
        case agent
        case `extension`
        case system
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ActorType.self, forKey: .type)
        let id = try container.decode(String.self, forKey: .id)
        switch type {
        case .user:
            self = .user(id: id, displayName: try container.decodeIfPresent(String.self, forKey: .displayName))
        case .agent:
            self = .agent(id: id, displayName: try container.decodeIfPresent(String.self, forKey: .displayName))
        case .extension:
            self = .extension(id: id)
        case .system:
            self = .system(id: id)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .user(let id, let displayName):
            try container.encode(ActorType.user, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(displayName, forKey: .displayName)
        case .agent(let id, let displayName):
            try container.encode(ActorType.agent, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(displayName, forKey: .displayName)
        case .extension(let id):
            try container.encode(ActorType.extension, forKey: .type)
            try container.encode(id, forKey: .id)
        case .system(let id):
            try container.encode(ActorType.system, forKey: .type)
            try container.encode(id, forKey: .id)
        }
    }
}

/// Secretary job projection suitable for status lists and detail surfaces.
public struct AteliaJob: Sendable, Codable, Equatable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case repositoryId = "repository_id"
        case requester
        case kind
        case goal
        case status
        case policySummary = "policy_summary"
        case createdAtUnixMilliseconds = "created_at_unix_ms"
        case startedAtUnixMilliseconds = "started_at_unix_ms"
        case completedAtUnixMilliseconds = "completed_at_unix_ms"
        case latestEventId = "latest_event_id"
        case cancellation
    }

    public enum Status: String, Sendable, Codable, Equatable {
        case queued
        case running
        case succeeded
        case failed
        case blocked
        case canceled
        case unknown
    }

    public var jobId: String
    public var repositoryId: String
    public var requester: AteliaActor
    public var kind: String
    public var goal: String
    public var status: Status
    public var policySummary: AteliaPolicySummary?
    public var createdAtUnixMilliseconds: Int64
    public var startedAtUnixMilliseconds: Int64?
    public var completedAtUnixMilliseconds: Int64?
    public var latestEventId: String?
    public var cancellation: AteliaJobCancellation

    public var id: String { jobId }

    public init(
        jobId: String,
        repositoryId: String,
        requester: AteliaActor,
        kind: String,
        goal: String,
        status: Status,
        policySummary: AteliaPolicySummary? = nil,
        createdAtUnixMilliseconds: Int64,
        startedAtUnixMilliseconds: Int64? = nil,
        completedAtUnixMilliseconds: Int64? = nil,
        latestEventId: String? = nil,
        cancellation: AteliaJobCancellation = AteliaJobCancellation()
    ) {
        self.jobId = jobId
        self.repositoryId = repositoryId
        self.requester = requester
        self.kind = kind
        self.goal = goal
        self.status = status
        self.policySummary = policySummary
        self.createdAtUnixMilliseconds = createdAtUnixMilliseconds
        self.startedAtUnixMilliseconds = startedAtUnixMilliseconds
        self.completedAtUnixMilliseconds = completedAtUnixMilliseconds
        self.latestEventId = latestEventId
        self.cancellation = cancellation
    }
}

public struct AteliaJobCancellation: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case state
        case requestedBy = "requested_by"
        case reason
        case requestedAtUnixMilliseconds = "requested_at_unix_ms"
        case completedAtUnixMilliseconds = "completed_at_unix_ms"
    }

    public var state: String
    public var requestedBy: AteliaActor?
    public var reason: String?
    public var requestedAtUnixMilliseconds: Int64?
    public var completedAtUnixMilliseconds: Int64?

    public init(
        state: String = "none",
        requestedBy: AteliaActor? = nil,
        reason: String? = nil,
        requestedAtUnixMilliseconds: Int64? = nil,
        completedAtUnixMilliseconds: Int64? = nil
    ) {
        self.state = state
        self.requestedBy = requestedBy
        self.reason = reason
        self.requestedAtUnixMilliseconds = requestedAtUnixMilliseconds
        self.completedAtUnixMilliseconds = completedAtUnixMilliseconds
    }
}

public struct AteliaPolicySummary: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case decisionId = "decision_id"
        case outcome
        case riskTier = "risk_tier"
        case reasonCode = "reason_code"
    }

    public var decisionId: String
    public var outcome: String
    public var riskTier: String
    public var reasonCode: String

    public init(decisionId: String, outcome: String, riskTier: String, reasonCode: String) {
        self.decisionId = decisionId
        self.outcome = outcome
        self.riskTier = riskTier
        self.reasonCode = reasonCode
    }
}

/// Full policy decision surface shown by approval and audit UI.
public struct AteliaPolicyDecision: Sendable, Codable, Equatable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case decisionId = "decision_id"
        case outcome
        case riskTier = "risk_tier"
        case requestedCapability = "requested_capability"
        case reasonCode = "reason_code"
        case reason
        case approvalRequestRef = "approval_request_ref"
        case auditRef = "audit_ref"
    }

    public enum Outcome: String, Sendable, Codable, Equatable {
        case allowed
        case audited
        case needsApproval = "needs_approval"
        case blocked
    }

    public enum RiskTier: String, Sendable, Codable, Equatable {
        case r0 = "R0"
        case r1 = "R1"
        case r2 = "R2"
        case r3 = "R3"
        case r4 = "R4"
    }

    public var decisionId: String
    public var outcome: Outcome
    public var riskTier: RiskTier
    public var requestedCapability: String
    public var reasonCode: String
    public var reason: String
    public var approvalRequestRef: String?
    public var auditRef: String?

    public var id: String { decisionId }

    public init(
        decisionId: String,
        outcome: Outcome,
        riskTier: RiskTier,
        requestedCapability: String,
        reasonCode: String,
        reason: String,
        approvalRequestRef: String? = nil,
        auditRef: String? = nil
    ) {
        self.decisionId = decisionId
        self.outcome = outcome
        self.riskTier = riskTier
        self.requestedCapability = requestedCapability
        self.reasonCode = reasonCode
        self.reason = reason
        self.approvalRequestRef = approvalRequestRef
        self.auditRef = auditRef
    }
}

public struct AteliaApprovalState: Sendable, Codable, Equatable, Identifiable {
    public enum Status: String, Sendable, Codable, Equatable {
        case notRequired = "not_required"
        case pending
        case approved
        case denied
        case expired
    }

    public var id: String
    public var status: Status
    public var policyDecisionId: String?
    public var requestedBy: AteliaActor?
    public var reason: String?

    public init(
        id: String,
        status: Status,
        policyDecisionId: String? = nil,
        requestedBy: AteliaActor? = nil,
        reason: String? = nil
    ) {
        self.id = id
        self.status = status
        self.policyDecisionId = policyDecisionId
        self.requestedBy = requestedBy
        self.reason = reason
    }
}

public struct AteliaAuditReference: Sendable, Codable, Equatable, Identifiable {
    public var id: String
    public var repositoryId: String?
    public var jobId: String?
    public var policyDecisionId: String?
    public var message: String?

    public init(
        id: String,
        repositoryId: String? = nil,
        jobId: String? = nil,
        policyDecisionId: String? = nil,
        message: String? = nil
    ) {
        self.id = id
        self.repositoryId = repositoryId
        self.jobId = jobId
        self.policyDecisionId = policyDecisionId
        self.message = message
    }
}

public struct AteliaReviewQueueItem: Sendable, Codable, Equatable, Identifiable {
    public enum Kind: String, Sendable, Codable, Equatable {
        case approval
        case review
        case policy
        case audit
        case job
    }

    public var id: String
    public var kind: Kind
    public var title: String
    public var repositoryId: String?
    public var jobId: String?
    public var policyDecisionId: String?
    public var priority: Int

    public init(
        id: String,
        kind: Kind,
        title: String,
        repositoryId: String? = nil,
        jobId: String? = nil,
        policyDecisionId: String? = nil,
        priority: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.repositoryId = repositoryId
        self.jobId = jobId
        self.policyDecisionId = policyDecisionId
        self.priority = priority
    }
}

public struct AteliaEventCursor: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case sequence
        case eventId = "event_id"
    }

    public var sequence: UInt64
    public var eventId: String

    public init(sequence: UInt64, eventId: String) {
        self.sequence = sequence
        self.eventId = eventId
    }
}

public struct AteliaProjectStatus: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case metadata
        case repository
        case recentJobs = "recent_jobs"
        case recentPolicyDecisions = "recent_policy_decisions"
        case latestCursor = "latest_cursor"
        case daemonStatus = "daemon_status"
        case storageStatus = "storage_status"
    }

    public var metadata: AteliaProtocolMetadata
    public var repository: AteliaRepository
    public var recentJobs: [AteliaJob]
    public var recentPolicyDecisions: [AteliaPolicyDecision]
    public var latestCursor: AteliaEventCursor?
    public var daemonStatus: AteliaHealthResponse.DaemonStatus
    public var storageStatus: AteliaHealthResponse.StorageStatus

    public init(
        metadata: AteliaProtocolMetadata,
        repository: AteliaRepository,
        recentJobs: [AteliaJob],
        recentPolicyDecisions: [AteliaPolicyDecision],
        latestCursor: AteliaEventCursor?,
        daemonStatus: AteliaHealthResponse.DaemonStatus,
        storageStatus: AteliaHealthResponse.StorageStatus
    ) {
        self.metadata = metadata
        self.repository = repository
        self.recentJobs = recentJobs
        self.recentPolicyDecisions = recentPolicyDecisions
        self.latestCursor = latestCursor
        self.daemonStatus = daemonStatus
        self.storageStatus = storageStatus
    }
}

/// Live built-in tool projection returned by Secretary `ListRepertoire`.
public struct AteliaToolRepertoireEntry: Sendable, Codable, Equatable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case toolId = "tool_id"
        case name
        case description
        case providerKind = "provider_kind"
        case providerId = "provider_id"
        case riskTier = "risk_tier"
        case defaultResultFormat = "default_result_format"
        case supportedResultFormats = "supported_result_formats"
        case idempotency
        case cancellable
        case streaming
        case timeoutMilliseconds = "timeout_ms"
    }

    public var toolId: String
    public var name: String
    public var description: String
    public var providerKind: String
    public var providerId: String
    public var riskTier: String
    public var defaultResultFormat: String
    public var supportedResultFormats: [String]
    public var idempotency: String
    public var cancellable: Bool
    public var streaming: Bool
    public var timeoutMilliseconds: UInt32

    public var id: String { toolId }

    public init(
        toolId: String,
        name: String,
        description: String,
        providerKind: String,
        providerId: String,
        riskTier: String,
        defaultResultFormat: String,
        supportedResultFormats: [String],
        idempotency: String,
        cancellable: Bool,
        streaming: Bool,
        timeoutMilliseconds: UInt32
    ) {
        self.toolId = toolId
        self.name = name
        self.description = description
        self.providerKind = providerKind
        self.providerId = providerId
        self.riskTier = riskTier
        self.defaultResultFormat = defaultResultFormat
        self.supportedResultFormats = supportedResultFormats
        self.idempotency = idempotency
        self.cancellable = cancellable
        self.streaming = streaming
        self.timeoutMilliseconds = timeoutMilliseconds
    }
}
