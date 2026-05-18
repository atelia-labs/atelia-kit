import Foundation

/// Request payload for repository registration.
public struct AteliaRegisterRepositoryRequest: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case rootPath = "root_path"
        case allowedScope = "allowed_scope"
        case requester
    }

    public var displayName: String
    public var rootPath: String
    public var allowedScope: AteliaPathScope
    public var requester: AteliaActor

    public init(
        displayName: String,
        rootPath: String,
        allowedScope: AteliaPathScope,
        requester: AteliaActor
    ) {
        self.displayName = displayName
        self.rootPath = rootPath
        self.allowedScope = allowedScope
        self.requester = requester
    }
}

/// Envelope returned by repository registration operations.
public struct AteliaRegisterRepositoryResponse: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case metadata
        case repository
        case policy
    }

    public var metadata: AteliaProtocolMetadata
    public var repository: AteliaRepository
    public var policy: AteliaPolicyDecision?

    public init(
        metadata: AteliaProtocolMetadata,
        repository: AteliaRepository,
        policy: AteliaPolicyDecision?
    ) {
        self.metadata = metadata
        self.repository = repository
        self.policy = policy
    }
}

/// Request payload for canceling a job.
public struct AteliaCancelJobRequest: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case requester
        case reason
    }

    public var requester: AteliaActor
    public var reason: String

    public init(requester: AteliaActor, reason: String) {
        self.requester = requester
        self.reason = reason
    }
}

/// Envelope returned by job inspection operations.
public struct AteliaGetJobResponse: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case metadata
        case job
    }

    public var metadata: AteliaProtocolMetadata
    public var job: AteliaJob

    public init(metadata: AteliaProtocolMetadata, job: AteliaJob) {
        self.metadata = metadata
        self.job = job
    }
}

/// Envelope returned by job cancellation operations.
public struct AteliaCancelJobResponse: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case metadata
        case job
        case cancellation
    }

    public var metadata: AteliaProtocolMetadata
    public var job: AteliaJob
    public var cancellation: AteliaJobCancellation

    public init(metadata: AteliaProtocolMetadata, job: AteliaJob, cancellation: AteliaJobCancellation) {
        self.metadata = metadata
        self.job = job
        self.cancellation = cancellation
    }
}

/// Subject type attached to a Secretary event.
public enum AteliaEventSubjectType: Sendable, Codable, Equatable, RawRepresentable {
    case unspecified
    case daemon
    case repository
    case job
    case policyDecision
    case lockDecision
    case toolInvocation
    case toolResult
    case auditRecord
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "unspecified":
            self = .unspecified
        case "daemon":
            self = .daemon
        case "repository":
            self = .repository
        case "job":
            self = .job
        case "policy_decision":
            self = .policyDecision
        case "lock_decision":
            self = .lockDecision
        case "tool_invocation":
            self = .toolInvocation
        case "tool_result":
            self = .toolResult
        case "audit_record":
            self = .auditRecord
        default:
            self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .unspecified:
            return "unspecified"
        case .daemon:
            return "daemon"
        case .repository:
            return "repository"
        case .job:
            return "job"
        case .policyDecision:
            return "policy_decision"
        case .lockDecision:
            return "lock_decision"
        case .toolInvocation:
            return "tool_invocation"
        case .toolResult:
            return "tool_result"
        case .auditRecord:
            return "audit_record"
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

/// Severity of a Secretary event.
public enum AteliaEventSeverity: Sendable, Codable, Equatable, RawRepresentable {
    case debug
    case info
    case warning
    case error
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "debug":
            self = .debug
        case "info":
            self = .info
        case "warning":
            self = .warning
        case "error":
            self = .error
        default:
            self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .debug:
            return "debug"
        case .info:
            return "info"
        case .warning:
            return "warning"
        case .error:
            return "error"
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

/// Subject metadata attached to a Secretary event.
public struct AteliaEventSubject: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case type
        case id
    }

    public var type: AteliaEventSubjectType
    public var id: String

    public init(type: AteliaEventSubjectType, id: String) {
        self.type = type
        self.id = id
    }
}

/// Cross-reference metadata attached to a Secretary event.
public struct AteliaEventRefs: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case repositoryId = "repository_id"
        case jobId = "job_id"
        case policyDecisionId = "policy_decision_id"
        case lockDecisionId = "lock_decision_id"
        case toolInvocationId = "tool_invocation_id"
        case toolResultId = "tool_result_id"
        case contentType = "content_type"
        case auditRef = "audit_ref"
    }

    public var repositoryId: String?
    public var jobId: String?
    public var policyDecisionId: String?
    public var lockDecisionId: String?
    public var toolInvocationId: String?
    public var toolResultId: String?
    public var contentType: String?
    public var auditRef: String?

    public init(
        repositoryId: String? = nil,
        jobId: String? = nil,
        policyDecisionId: String? = nil,
        lockDecisionId: String? = nil,
        toolInvocationId: String? = nil,
        toolResultId: String? = nil,
        contentType: String? = nil,
        auditRef: String? = nil
    ) {
        self.repositoryId = repositoryId
        self.jobId = jobId
        self.policyDecisionId = policyDecisionId
        self.lockDecisionId = lockDecisionId
        self.toolInvocationId = toolInvocationId
        self.toolResultId = toolResultId
        self.contentType = contentType
        self.auditRef = auditRef
    }
}

/// Ordered event record surfaced by Secretary.
public struct AteliaEvent: Sendable, Codable, Equatable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case sequence
        case occurredAtUnixMilliseconds = "occurred_at_unix_ms"
        case subject
        case kind
        case severity
        case message
        case refs
    }

    public var eventId: String
    public var sequence: UInt64
    public var occurredAtUnixMilliseconds: Int64
    public var subject: AteliaEventSubject
    public var kind: String
    public var severity: AteliaEventSeverity
    public var message: String
    public var refs: AteliaEventRefs

    public var id: String { eventId }

    public init(
        eventId: String,
        sequence: UInt64,
        occurredAtUnixMilliseconds: Int64,
        subject: AteliaEventSubject,
        kind: String,
        severity: AteliaEventSeverity,
        message: String,
        refs: AteliaEventRefs
    ) {
        self.eventId = eventId
        self.sequence = sequence
        self.occurredAtUnixMilliseconds = occurredAtUnixMilliseconds
        self.subject = subject
        self.kind = kind
        self.severity = severity
        self.message = message
        self.refs = refs
    }
}

/// Event cursor shape used by event list and replay routes.
public enum AteliaEventRouteCursor: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case sequenceNumber = "sequence_number"
        case eventId = "event_id"
    }

    private enum Kind: String, Codable {
        case beginning
        case afterSequence = "after_sequence"
        case afterEventId = "after_event_id"
    }

    case beginning
    case afterSequence(_ sequenceNumber: UInt64)
    case afterEventId(_ eventId: String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .beginning:
            self = .beginning
        case .afterSequence:
            let sequenceNumber = try container.decode(UInt64.self, forKey: .sequenceNumber)
            self = .afterSequence(sequenceNumber)
        case .afterEventId:
            let eventId = try container.decode(String.self, forKey: .eventId)
            self = .afterEventId(eventId)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .beginning:
            try container.encode(Kind.beginning, forKey: .kind)
        case .afterSequence(let sequenceNumber):
            try container.encode(Kind.afterSequence, forKey: .kind)
            try container.encode(sequenceNumber, forKey: .sequenceNumber)
        case .afterEventId(let eventId):
            try container.encode(Kind.afterEventId, forKey: .kind)
            try container.encode(eventId, forKey: .eventId)
        }
    }
}

/// Request payload for polling-friendly event listing.
public struct AteliaListEventsRequest: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case repositoryId = "repository_id"
        case cursor
        case subjectIds = "subject_ids"
        case jobIds = "job_ids"
        case minSeverity = "min_severity"
        case pageSize = "page_size"
        case pageToken = "page_token"
    }

    public var repositoryId: String?
    public var cursor: AteliaEventRouteCursor?
    public var subjectIds: [String]
    public var jobIds: [String]
    public var minSeverity: AteliaEventSeverity?
    public var pageSize: Int?
    public var pageToken: String?

    public init(
        repositoryId: String? = nil,
        cursor: AteliaEventRouteCursor? = nil,
        subjectIds: [String] = [],
        jobIds: [String] = [],
        minSeverity: AteliaEventSeverity? = nil,
        pageSize: Int? = nil,
        pageToken: String? = nil
    ) {
        self.repositoryId = repositoryId
        self.cursor = cursor
        self.subjectIds = subjectIds
        self.jobIds = jobIds
        self.minSeverity = minSeverity
        self.pageSize = pageSize
        self.pageToken = pageToken
    }
}

/// Response envelope returned by event listing operations.
public struct AteliaListEventsResponse: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case metadata
        case events
        case nextPageToken = "next_page_token"
    }

    public var metadata: AteliaProtocolMetadata
    public var events: [AteliaEvent]
    public var nextPageToken: String?

    public init(metadata: AteliaProtocolMetadata, events: [AteliaEvent], nextPageToken: String?) {
        self.metadata = metadata
        self.events = events
        self.nextPageToken = nextPageToken
    }
}

/// Request payload for bounded event replay.
public struct AteliaReplayEventsRequest: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case repositoryId = "repository_id"
        case cursor
        case subjectIds = "subject_ids"
        case minSeverity = "min_severity"
        case limit
    }

    public var repositoryId: String
    public var cursor: AteliaEventRouteCursor?
    public var subjectIds: [String]
    public var minSeverity: AteliaEventSeverity?
    public var limit: Int?

    public init(
        repositoryId: String,
        cursor: AteliaEventRouteCursor? = nil,
        subjectIds: [String] = [],
        minSeverity: AteliaEventSeverity? = nil,
        limit: Int? = nil
    ) {
        self.repositoryId = repositoryId
        self.cursor = cursor
        self.subjectIds = subjectIds
        self.minSeverity = minSeverity
        self.limit = limit
    }
}

/// Response envelope returned by event replay operations.
public struct AteliaReplayEventsResponse: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case metadata
        case events
        case cursor
    }

    public var metadata: AteliaProtocolMetadata
    public var events: [AteliaEvent]
    public var cursor: AteliaEventRouteCursor?

    public init(metadata: AteliaProtocolMetadata, events: [AteliaEvent], cursor: AteliaEventRouteCursor?) {
        self.metadata = metadata
        self.events = events
        self.cursor = cursor
    }
}
