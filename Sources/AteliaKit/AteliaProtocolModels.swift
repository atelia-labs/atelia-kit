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

    public enum TrustState: Sendable, Codable, Equatable, RawRepresentable {
        case unspecified
        case trusted
        case readOnly
        case blocked
        case unknown(String)

        public init(rawValue: String) {
            switch rawValue {
            case "unspecified":
                self = .unspecified
            case "trusted":
                self = .trusted
            case "read_only":
                self = .readOnly
            case "blocked":
                self = .blocked
            default:
                self = .unknown(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .unspecified:
                return "unspecified"
            case .trusted:
                return "trusted"
            case .readOnly:
                return "read_only"
            case .blocked:
                return "blocked"
            case .unknown(let rawValue):
                return rawValue
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
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

    public enum Kind: Sendable, Codable, Equatable, RawRepresentable {
        case unspecified
        case repository
        case explicitPaths
        case readOnly
        case unknown(String)

        public init(rawValue: String) {
            switch rawValue {
            case "unspecified":
                self = .unspecified
            case "repository":
                self = .repository
            case "explicit_paths":
                self = .explicitPaths
            case "read_only":
                self = .readOnly
            default:
                self = .unknown(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .unspecified:
                return "unspecified"
            case .repository:
                return "repository"
            case .explicitPaths:
                return "explicit_paths"
            case .readOnly:
                return "read_only"
            case .unknown(let rawValue):
                return rawValue
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.kind = try container.decode(Kind.self, forKey: .kind)
        self.roots = try container.decode([String].self, forKey: .roots)
        self.includePatterns = try container.decodeIfPresent([String].self, forKey: .includePatterns) ?? []
        self.excludePatterns = try container.decodeIfPresent([String].self, forKey: .excludePatterns) ?? []
    }
}

/// Platform-neutral project identity used by client coordination surfaces.
public struct AteliaProjectIdentity: Sendable, Codable, Equatable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case repositoryId = "repository_id"
    }

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
    private enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case title
    }

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
    case unknown(rawValue: String, id: String, displayName: String?)

    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case displayName = "display_name"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let id = try container.decode(String.self, forKey: .id)
        switch type {
        case "user":
            self = .user(id: id, displayName: try container.decodeIfPresent(String.self, forKey: .displayName))
        case "agent":
            self = .agent(id: id, displayName: try container.decodeIfPresent(String.self, forKey: .displayName))
        case "extension":
            self = .extension(id: id)
        case "system":
            self = .system(id: id)
        default:
            self = .unknown(
                rawValue: type,
                id: id,
                displayName: try container.decodeIfPresent(String.self, forKey: .displayName)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .user(let id, let displayName):
            try container.encode("user", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(displayName, forKey: .displayName)
        case .agent(let id, let displayName):
            try container.encode("agent", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(displayName, forKey: .displayName)
        case .extension(let id):
            try container.encode("extension", forKey: .type)
            try container.encode(id, forKey: .id)
        case .system(let id):
            try container.encode("system", forKey: .type)
            try container.encode(id, forKey: .id)
        case .unknown(let rawValue, let id, let displayName):
            try container.encode(rawValue, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(displayName, forKey: .displayName)
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

    public enum Status: Sendable, Codable, Equatable, RawRepresentable {
        case queued
        case running
        case succeeded
        case failed
        case blocked
        case canceled
        case unknown
        case unrecognized(String)

        public init(rawValue: String) {
            switch rawValue {
            case "queued":
                self = .queued
            case "running":
                self = .running
            case "succeeded":
                self = .succeeded
            case "failed":
                self = .failed
            case "blocked":
                self = .blocked
            case "canceled":
                self = .canceled
            case "unknown":
                self = .unknown
            default:
                self = .unrecognized(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .queued:
                return "queued"
            case .running:
                return "running"
            case .succeeded:
                return "succeeded"
            case .failed:
                return "failed"
            case .blocked:
                return "blocked"
            case .canceled:
                return "canceled"
            case .unknown:
                return "unknown"
            case .unrecognized(let rawValue):
                return rawValue
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    public var jobId: String
    public var repositoryId: String
    public var requester: AteliaActor
    public var kind: String
    public var goal: String?
    public var status: Status
    public var policySummary: AteliaPolicySummary?
    public var createdAtUnixMilliseconds: Int64
    public var startedAtUnixMilliseconds: Int64?
    public var completedAtUnixMilliseconds: Int64?
    public var latestEventId: String?
    public var cancellation: AteliaJobCancellation?

    public var id: String { jobId }

    public init(
        jobId: String,
        repositoryId: String,
        requester: AteliaActor,
        kind: String,
        goal: String? = nil,
        status: Status,
        policySummary: AteliaPolicySummary? = nil,
        createdAtUnixMilliseconds: Int64,
        startedAtUnixMilliseconds: Int64? = nil,
        completedAtUnixMilliseconds: Int64? = nil,
        latestEventId: String? = nil,
        cancellation: AteliaJobCancellation? = nil
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

/// Request payload for submitting a bounded job.
public struct AteliaSubmitJobRequest: Sendable, Codable, Equatable {
    /// JSON keys for job submission requests.
    private enum CodingKeys: String, CodingKey {
        case repositoryId = "repository_id"
        case requester
        case kind
        case goal
        case pathScope = "path_scope"
        case requestedCapabilities = "requested_capabilities"
        case idempotencyKey = "idempotency_key"
    }

    private enum PathScopeCodingKeys: String, CodingKey {
        case kind
        case roots
        case includePatterns = "include_patterns"
        case excludePatterns = "exclude_patterns"
    }

    /// Repository the job should run against.
    public var repositoryId: String
    /// Actor requesting the job submission.
    public var requester: AteliaActor
    /// Job kind requested by the caller.
    public var kind: String
    /// Bounded-job intent or summary.
    public var goal: String?
    /// Optional filesystem scope attached to the job request.
    public var pathScope: AteliaPathScope?
    /// Optional capability hints forwarded to Secretary for policy normalization.
    public var requestedCapabilities: [String]?
    /// Optional idempotency token for replayable submissions.
    public var idempotencyKey: String?

    /// Creates a job submission request.
    public init(
        repositoryId: String,
        requester: AteliaActor,
        kind: String,
        goal: String? = nil,
        pathScope: AteliaPathScope? = nil,
        requestedCapabilities: [String]? = nil,
        idempotencyKey: String? = nil
    ) {
        self.repositoryId = repositoryId
        self.requester = requester
        self.kind = kind
        self.goal = goal
        self.pathScope = pathScope
        self.requestedCapabilities = requestedCapabilities
        self.idempotencyKey = idempotencyKey
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(repositoryId, forKey: .repositoryId)
        try container.encode(requester, forKey: .requester)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(goal, forKey: .goal)
        try container.encodeIfPresent(requestedCapabilities, forKey: .requestedCapabilities)
        try container.encodeIfPresent(idempotencyKey, forKey: .idempotencyKey)

        guard let pathScope else { return }

        var pathScopeContainer = container.nestedContainer(
            keyedBy: PathScopeCodingKeys.self,
            forKey: .pathScope
        )
        try pathScopeContainer.encode(pathScope.kind, forKey: .kind)
        try pathScopeContainer.encode(pathScope.roots, forKey: .roots)
        if !pathScope.includePatterns.isEmpty {
            try pathScopeContainer.encode(pathScope.includePatterns, forKey: .includePatterns)
        }
        if !pathScope.excludePatterns.isEmpty {
            try pathScopeContainer.encode(pathScope.excludePatterns, forKey: .excludePatterns)
        }
    }
}

/// Envelope returned by job submission operations.
public struct AteliaSubmitJobResponse: Sendable, Codable, Equatable {
    /// JSON keys for job submission responses.
    private enum CodingKeys: String, CodingKey {
        case metadata
        case job
        case policy
    }

    /// Protocol metadata attached to the response.
    public var metadata: AteliaProtocolMetadata
    /// Persisted job projection returned by Secretary.
    public var job: AteliaJob
    /// Top-level policy decision returned with the job submission.
    public var policy: AteliaPolicyDecision

    /// Creates a job submission response.
    public init(metadata: AteliaProtocolMetadata, job: AteliaJob, policy: AteliaPolicyDecision) {
        self.metadata = metadata
        self.job = job
        self.policy = policy
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
    public var outcome: AteliaPolicyDecision.Outcome
    public var riskTier: AteliaPolicyDecision.RiskTier
    public var reasonCode: String

    public init(
        decisionId: String,
        outcome: AteliaPolicyDecision.Outcome,
        riskTier: AteliaPolicyDecision.RiskTier,
        reasonCode: String
    ) {
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

    public enum Outcome: Sendable, Codable, Equatable, RawRepresentable {
        case allowed
        case audited
        case needsApproval
        case blocked
        case unknown(String)

        public init(rawValue: String) {
            switch rawValue {
            case "allowed":
                self = .allowed
            case "audited":
                self = .audited
            case "needs_approval":
                self = .needsApproval
            case "blocked":
                self = .blocked
            default:
                self = .unknown(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .allowed:
                return "allowed"
            case .audited:
                return "audited"
            case .needsApproval:
                return "needs_approval"
            case .blocked:
                return "blocked"
            case .unknown(let rawValue):
                return rawValue
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    public enum RiskTier: Sendable, Codable, Equatable, RawRepresentable {
        case r0
        case r1
        case r2
        case r3
        case r4
        case unknown(String)

        public init(rawValue: String) {
            switch rawValue {
            case "r0", "R0":
                self = .r0
            case "r1", "R1":
                self = .r1
            case "r2", "R2":
                self = .r2
            case "r3", "R3":
                self = .r3
            case "r4", "R4":
                self = .r4
            default:
                self = .unknown(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .r0:
                return "r0"
            case .r1:
                return "r1"
            case .r2:
                return "r2"
            case .r3:
                return "r3"
            case .r4:
                return "r4"
            case .unknown(let rawValue):
                return rawValue
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
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
    private enum CodingKeys: String, CodingKey {
        case id
        case status
        case policyDecisionId = "policy_decision_id"
        case requestedBy = "requested_by"
        case reason
    }

    public enum Status: Sendable, Codable, Equatable, RawRepresentable {
        case notRequired
        case pending
        case approved
        case denied
        case expired
        case unknown(String)

        public init(rawValue: String) {
            switch rawValue {
            case "not_required":
                self = .notRequired
            case "pending":
                self = .pending
            case "approved":
                self = .approved
            case "denied":
                self = .denied
            case "expired":
                self = .expired
            default:
                self = .unknown(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .notRequired:
                return "not_required"
            case .pending:
                return "pending"
            case .approved:
                return "approved"
            case .denied:
                return "denied"
            case .expired:
                return "expired"
            case .unknown(let rawValue):
                return rawValue
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
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
    private enum CodingKeys: String, CodingKey {
        case id
        case repositoryId = "repository_id"
        case jobId = "job_id"
        case policyDecisionId = "policy_decision_id"
        case message
    }

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
    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case repositoryId = "repository_id"
        case jobId = "job_id"
        case policyDecisionId = "policy_decision_id"
        case priority
    }

    public enum Kind: Sendable, Codable, Equatable, RawRepresentable {
        case approval
        case review
        case policy
        case audit
        case job
        case unknown(String)

        public init(rawValue: String) {
            switch rawValue {
            case "approval":
                self = .approval
            case "review":
                self = .review
            case "policy":
                self = .policy
            case "audit":
                self = .audit
            case "job":
                self = .job
            default:
                self = .unknown(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .approval:
                return "approval"
            case .review:
                return "review"
            case .policy:
                return "policy"
            case .audit:
                return "audit"
            case .job:
                return "job"
            case .unknown(let rawValue):
                return rawValue
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
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
