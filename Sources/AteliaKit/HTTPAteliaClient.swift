import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Errors surfaced by the HTTP/JSON Secretary beta transport.
public enum HTTPAteliaClientError: Error, Sendable, Equatable {
    /// The configured endpoint and request path could not form a valid URL.
    case invalidURL(path: String)
    /// The package identifier cannot be used in an operation path.
    case invalidPackageId(String)
    /// The job identifier cannot be used in an operation path.
    case invalidJobId(String)
    /// The transport returned a non-HTTP response.
    case invalidHTTPResponse
    /// Secretary returned a non-success HTTP status without a structured API error.
    case unsuccessfulStatus(code: Int, reason: String?)
    /// Secretary returned a structured API error envelope.
    case apiError(AteliaAPIError)
    /// Repository pagination repeated a page token, so the client stopped to avoid a loop.
    case repeatedPageToken(String)
}

/// Stable error shape returned by the daemon transport.
public struct AteliaAPIError: Sendable, Codable, Equatable {
    /// JSON keys used by Secretary's structured API error envelope.
    private enum CodingKeys: String, CodingKey {
        /// Stable machine-readable error code.
        case code
        /// Human-readable Secretary error reason.
        case reason
        /// Whether the failed operation can recover.
        case recoverable
        /// Suggested next state for client recovery.
        case nextState = "next_state"
        /// Optional retry timing or token hint.
        case retryAfter = "retry_after"
        /// Optional audit reference for diagnostics.
        case auditRef = "audit_ref"
    }

    /// Stable machine-readable error code.
    public var code: String
    /// Human-readable explanation from Secretary.
    public var reason: String
    /// Whether the operation can be retried after user or system action.
    public var recoverable: Bool
    /// Suggested next state for client recovery flows.
    public var nextState: String
    /// Optional retry hint supplied by Secretary.
    public var retryAfter: AteliaRetryAfter?
    /// Optional audit reference for support and diagnostics.
    public var auditRef: String?

    /// Creates a structured API error.
    public init(
        code: String,
        reason: String,
        recoverable: Bool,
        nextState: String,
        retryAfter: AteliaRetryAfter? = nil,
        auditRef: String? = nil
    ) {
        self.code = code
        self.reason = reason
        self.recoverable = recoverable
        self.nextState = nextState
        self.retryAfter = retryAfter
        self.auditRef = auditRef
    }
}

/// Retry hint returned by Secretary errors.
public enum AteliaRetryAfter: Sendable, Codable, Equatable {
    /// Retry after the given number of seconds.
    case seconds(Double)
    /// Retry after an opaque scheduler token or condition.
    case token(String)

    /// Decodes either a numeric delay or an opaque retry token.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let seconds = try? container.decode(Double.self) {
            self = .seconds(seconds)
            return
        }
        self = .token(try container.decode(String.self))
    }

    /// Encodes the retry hint as either a numeric delay or token.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .seconds(let seconds):
            try container.encode(seconds)
        case .token(let token):
            try container.encode(token)
        }
    }
}

/// Small HTTP transport abstraction used to keep URLSession replaceable in tests.
public struct AteliaHTTPTransport: Sendable {
    /// Sends a URL request and returns the raw response data and HTTP metadata.
    public var send: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    /// Creates a transport from a send closure.
    public init(send: @escaping @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)) {
        self.send = send
    }

    /// Creates a transport backed by `URLSession`.
    public static func urlSession(_ session: URLSession = .shared) -> Self {
        Self { request in
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPAteliaClientError.invalidHTTPResponse
            }
            return (data, httpResponse)
        }
    }
}

/// HTTP/JSON client for the Secretary beta daemon.
public struct HTTPAteliaClient: AteliaClient, Sendable {
    /// Replaceable HTTP transport used for production requests and tests.
    private let transport: AteliaHTTPTransport
    /// Optional bearer token applied to outgoing requests.
    private let bearerToken: String?
    /// JSON decoder used for Secretary envelopes.
    private let decoder: JSONDecoder
    /// JSON encoder used for non-GET request bodies.
    private let encoder: JSONEncoder

    /// Creates an HTTP client for a Secretary endpoint.
    public init(
        bearerToken: String? = nil,
        transport: AteliaHTTPTransport = .urlSession()
    ) {
        self.bearerToken = bearerToken
        self.transport = transport
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    /// Fetches the Secretary health envelope for the session.
    public func health(for session: AteliaSession) async throws -> AteliaHealthResponse {
        try await send(
            session: session,
            method: "GET",
            path: "/v1/health",
            body: EmptyRequest()
        )
    }

    /// Lists repositories visible to the session, following Secretary pagination.
    public func repositories(for session: AteliaSession) async throws -> [AteliaRepository] {
        var repositories: [AteliaRepository] = []
        var pageToken: String?
        var seenPageTokens = Set<String>()

        while true {
            let response: ListRepositoriesResponse = try await send(
                session: session,
                method: "POST",
                path: "/v1/repositories:list",
                body: ListRepositoriesRequest(pageToken: pageToken)
            )
            repositories.append(contentsOf: response.repositories)

            guard let nextPageToken = response.nextPageToken else {
                break
            }
            guard seenPageTokens.insert(nextPageToken).inserted else {
                throw HTTPAteliaClientError.repeatedPageToken(nextPageToken)
            }
            pageToken = nextPageToken
        }

        return repositories
    }

    /// Registers a repository root and returns the persisted repository projection.
    public func registerRepositoryResponse(
        for session: AteliaSession,
        request: AteliaRegisterRepositoryRequest
    ) async throws -> AteliaRegisterRepositoryResponse {
        _ = session
        _ = request
        throw AteliaClientError.registerRepositoryUnavailable
    }

    /// Lists beta tool repertoire entries visible to the session.
    public func toolRepertoire(for session: AteliaSession) async throws -> [AteliaToolRepertoireEntry] {
        let response: ListToolRepertoireResponse = try await send(
            session: session,
            method: "POST",
            path: "/v1/repertoire:list",
            body: EmptyRequest()
        )
        return response.entries
    }

    /// Returns the full Secretary package trust index envelope.
    public func packageTrustIndexResponse(for session: AteliaSession) async throws -> AteliaPackageTrustIndexResponse {
        try await packageTrustIndexResponse(for: session, request: .init())
    }

    /// Returns the filtered Secretary package trust index envelope.
    public func packageTrustIndexResponse(
        for session: AteliaSession,
        request: AteliaPackageTrustIndexRequest
    ) async throws -> AteliaPackageTrustIndexResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/package-trust-index:list",
            body: request
        )
    }

    /// Returns the rollback response envelope for a package.
    public func packageRollbackResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRollbackResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makePackageOperationPath(packageId: packageId, operation: "rollback"),
            body: EmptyRequest()
        )
    }

    /// Returns the install response envelope for a package manifest.
    public func packageInstallResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageInstallResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/packages/install",
            body: request
        )
    }

    /// Returns the update response envelope for a package manifest.
    public func packageUpdateResponse(
        for session: AteliaSession,
        request: AteliaPackageLifecycleRequest
    ) async throws -> AteliaPackageUpdateResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/packages/update",
            body: request
        )
    }

    /// Returns the status envelope for a package identifier.
    public func packageStatusResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageStatusResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makePackageOperationPath(packageId: packageId, operation: "status"),
            body: EmptyRequest()
        )
    }

    /// Returns the inspect envelope for a package identifier.
    public func packageInspectResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageInspectResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makePackageOperationPath(packageId: packageId, operation: "inspect"),
            body: EmptyRequest()
        )
    }

    /// Returns the package list envelope, with an optional explicit blocked filter.
    public func packageListResponse(
        for session: AteliaSession,
        request: AteliaPackageListRequest
    ) async throws -> AteliaPackageListResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/packages/list",
            body: request
        )
    }

    /// Returns the authoring flow response for the requested package.
    public func packageAuthoringFlowResponse(
        for session: AteliaSession,
        request: AteliaPackageAuthoringFlowRequest
    ) async throws -> AteliaPackageAuthoringFlowResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makePackageAuthoringPath(packageId: request.packageId, operation: "authoring-flow"),
            body: request
        )
    }

    /// Returns the package remix response for the requested package.
    public func packageRemixResponse(
        for session: AteliaSession,
        request: AteliaPackageRemixRequest
    ) async throws -> AteliaPackageRemixResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makePackageAuthoringPath(packageId: request.packageId, operation: "remix"),
            body: request
        )
    }

    /// Returns the package publication response for the requested package.
    public func packagePublicationResponse(
        for session: AteliaSession,
        request: AteliaPackagePublicationRequest
    ) async throws -> AteliaPackagePublicationResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makePackageAuthoringPath(packageId: request.packageId, operation: "publication"),
            body: request
        )
    }

    /// Returns the registry-submission response for the requested package.
    public func packageRegistrySubmissionResponse(
        for session: AteliaSession,
        request: AteliaPackageRegistrySubmissionRequest
    ) async throws -> AteliaPackageRegistrySubmissionResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makePackageAuthoringPath(packageId: request.packageId, operation: "registry-submission"),
            body: request
        )
    }

    /// Submits a bounded job request to Secretary.
    public func submitJobResponse(
        for session: AteliaSession,
        request: AteliaSubmitJobRequest
    ) async throws -> AteliaSubmitJobResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/jobs/submit",
            body: request
        )
    }

    /// Returns a job projection for a job identifier.
    public func jobResponse(
        for session: AteliaSession,
        jobId: String
    ) async throws -> AteliaGetJobResponse {
        try await send(
            session: session,
            method: "GET",
            path: try makeJobPath(jobId: jobId),
            body: EmptyRequest()
        )
    }

    /// Returns the cancellation response envelope for a job identifier.
    public func cancelJobResponse(
        for session: AteliaSession,
        jobId: String,
        request: AteliaCancelJobRequest
    ) async throws -> AteliaCancelJobResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makeJobOperationPath(jobId: jobId, operation: "cancel"),
            body: request
        )
    }

    /// Returns the polling-friendly event list envelope.
    public func listEventsResponse(
        for session: AteliaSession,
        request: AteliaListEventsRequest
    ) async throws -> AteliaListEventsResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/events/list",
            body: request
        )
    }

    private struct ListJobEventsRequestPayload: Sendable, Codable {
        private enum CodingKeys: String, CodingKey {
            case repositoryId = "repository_id"
            case cursor
            case minSeverity = "min_severity"
            case pageSize = "page_size"
            case pageToken = "page_token"
        }

        var repositoryId: String?
        var cursor: AteliaEventRouteCursor?
        var minSeverity: AteliaEventSeverity?
        var pageSize: Int?
        var pageToken: String?

        init(
            request: AteliaListEventsRequest
        ) {
            repositoryId = request.repositoryId
            cursor = request.cursor
            minSeverity = request.minSeverity
            pageSize = request.pageSize
            pageToken = request.pageToken
        }
    }

    /// Returns the polling-friendly event list envelope for one job.
    public func listJobEventsResponse(
        for session: AteliaSession,
        jobId: String,
        request: AteliaListEventsRequest
    ) async throws -> AteliaListEventsResponse {
        return try await send(
            session: session,
            method: "POST",
            path: try makeJobOperationPath(jobId: jobId, operation: "events"),
            body: ListJobEventsRequestPayload(request: request)
        )
    }

    /// Returns the bounded replay envelope.
    public func replayEventsResponse(
        for session: AteliaSession,
        request: AteliaReplayEventsRequest
    ) async throws -> AteliaReplayEventsResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/events/replay",
            body: request
        )
    }

    /// Returns the disable response envelope for a package identifier.
    public func packageDisableResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageDisableResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makePackageOperationPath(packageId: packageId, operation: "disable"),
            body: EmptyRequest()
        )
    }

    /// Returns the enable response envelope for a package identifier.
    public func packageEnableResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageEnableResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makePackageOperationPath(packageId: packageId, operation: "enable"),
            body: EmptyRequest()
        )
    }

    /// Returns the remove response envelope for a package identifier.
    public func packageRemoveResponse(
        for session: AteliaSession,
        packageId: String
    ) async throws -> AteliaPackageRemoveResponse {
        try await send(
            session: session,
            method: "POST",
            path: try makePackageOperationPath(packageId: packageId, operation: "remove"),
            body: EmptyRequest()
        )
    }

    /// Returns the blocklist apply response envelope.
    public func packageBlocklistApplyResponse(
        for session: AteliaSession,
        request: AteliaPackageBlocklistRequest
    ) async throws -> AteliaPackageBlocklistApplyResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/packages/blocklist/apply",
            body: request
        )
    }

    /// Returns the blocklist list response envelope.
    public func packageBlocklistListResponse(
        for session: AteliaSession
    ) async throws -> AteliaPackageBlocklistListResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/packages/blocklist/list",
            body: EmptyRequest()
        )
    }

    /// Returns the tool-output render response for a canonical tool result and output format.
    public func renderToolOutputResponse(
        for session: AteliaSession,
        request: AteliaToolOutputRenderRequest
    ) async throws -> AteliaToolOutputRenderResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/tool-results:render",
            body: request
        )
    }

    /// Returns the validation response envelope for a package manifest.
    public func packageValidationResponse(
        for session: AteliaSession,
        request: AteliaPackageValidationRequest
    ) async throws -> AteliaPackageValidationResponse {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/packages/validate",
            body: request
        )
    }

    /// Fetches the compact project status snapshot for a repository.
    public func projectStatus(
        for session: AteliaSession,
        repositoryId: String
    ) async throws -> AteliaProjectStatus {
        try await send(
            session: session,
            method: "POST",
            path: "/v1/project-status:get",
            body: ProjectStatusRequest(repositoryId: repositoryId)
        )
    }

    /// Sends one typed request and decodes the Secretary API envelope.
    private func send<Request: Encodable, Response: Decodable>(
        session: AteliaSession,
        method: String,
        path: String,
        body: Request
    ) async throws -> Response {
        let request = try makeRequest(session: session, method: method, path: path, body: body)
        let (data, response) = try await transport.send(request)

        guard (200..<300).contains(response.statusCode) else {
            if let envelope = try? decoder.decode(APIEnvelope<EmptyResponse>.self, from: data),
               case .error(let error) = envelope {
                throw HTTPAteliaClientError.apiError(error)
            }
            throw HTTPAteliaClientError.unsuccessfulStatus(
                code: response.statusCode,
                reason: Self.responseReason(from: data)
            )
        }

        let envelope = try decoder.decode(APIEnvelope<Response>.self, from: data)

        switch envelope {
        case .ok(let data):
            return data
        case .error(let error):
            throw HTTPAteliaClientError.apiError(error)
        }
    }

    /// Extracts a fallback textual reason from an unstructured error body.
    private static func responseReason(from data: Data) -> String? {
        guard let reason = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !reason.isEmpty else {
            return nil
        }
        return reason
    }

    /// Builds a URL request for the configured Secretary endpoint.
    private func makeRequest<Request: Encodable>(
        session: AteliaSession,
        method: String,
        path: String,
        body: Request
    ) throws -> URLRequest {
        guard var components = URLComponents(
            url: session.endpoint.baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw HTTPAteliaClientError.invalidURL(path: path)
        }
        components.path = path

        guard let url = components.url else {
            throw HTTPAteliaClientError.invalidURL(path: path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        if method != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    /// Builds a Secretary path for a package operation after validating the package identifier.
    private func makePackageOperationPath(packageId: String, operation: String) throws -> String {
        try makePackageOperationPath(
            baseSegment: "packages",
            packageId: packageId,
            operation: operation
        )
    }

    /// Builds a Secretary path for package-authoring operations after validating the package identifier.
    private func makePackageAuthoringPath(packageId: String, operation: String) throws -> String {
        try makePackageOperationPath(
            baseSegment: "packages",
            packageId: packageId,
            operation: operation
        )
    }

    /// Builds a Secretary job path after validating the job identifier.
    private func makeJobPath(jobId: String) throws -> String {
        guard isValidJobId(jobId) else {
            throw HTTPAteliaClientError.invalidJobId(jobId)
        }
        return "/v1/jobs/\(jobId)"
    }

    /// Builds a Secretary job operation path after validating the job identifier.
    private func makeJobOperationPath(jobId: String, operation: String) throws -> String {
        guard isValidJobId(jobId) else {
            throw HTTPAteliaClientError.invalidJobId(jobId)
        }
        return "/v1/jobs/\(jobId)/\(operation)"
    }

    /// Builds a Secretary package path after validating the package identifier.
    private func makePackageOperationPath(
        baseSegment: String,
        packageId: String,
        operation: String
    ) throws -> String {
        guard isValidPackageId(packageId) else {
            throw HTTPAteliaClientError.invalidPackageId(packageId)
        }
        return "/v1/\(baseSegment)/\(packageId)/\(operation)"
    }

    /// Returns whether a package identifier can be embedded into a path segment.
    private func isValidPackageId(_ packageId: String) -> Bool {
        guard !packageId.isEmpty, packageId != ".", packageId != ".." else {
            return false
        }
        return packageId.range(
            of: #"^[A-Za-z0-9._-]+$"#,
            options: .regularExpression
        ) != nil
    }

    /// Returns whether a job identifier can be embedded into a path segment.
    private func isValidJobId(_ jobId: String) -> Bool {
        guard !jobId.isEmpty, jobId != ".", jobId != ".." else {
            return false
        }
        return jobId.range(
            of: #"^[A-Za-z0-9._-]+$"#,
            options: .regularExpression
        ) != nil
    }
}

/// Empty request body encoded as `{}` for POST endpoints without parameters.
private struct EmptyRequest: Sendable, Codable, Equatable {}

/// Empty success body used only when decoding structured API errors.
private struct EmptyResponse: Sendable, Decodable {}

/// Request body for the project status endpoint.
private struct ProjectStatusRequest: Sendable, Encodable {
    /// JSON keys for the compact project status request.
    private enum CodingKeys: String, CodingKey {
        /// Repository identifier whose project status is requested.
        case repositoryId = "repository_id"
    }

    /// Repository identifier whose project status should be fetched.
    var repositoryId: String
}

/// Request body for repository pagination.
private struct ListRepositoriesRequest: Sendable, Encodable {
    /// JSON keys for repository pagination requests.
    private enum CodingKeys: String, CodingKey {
        /// Opaque page token returned by the previous response.
        case pageToken = "page_token"
    }

    /// Opaque page token returned by the previous repository page.
    var pageToken: String?
}

/// Response body for one repository page.
private struct ListRepositoriesResponse: Sendable, Decodable {
    /// Protocol metadata attached to the repository list response.
    var metadata: AteliaProtocolMetadata
    /// Repositories returned in the current page.
    var repositories: [AteliaRepository]
    /// Opaque token for the next page, when more repositories are available.
    var nextPageToken: String?

    /// JSON keys for repository list responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata attached to the response.
        case metadata
        /// Repositories returned by the page.
        case repositories
        /// Opaque token for the next page.
        case nextPageToken = "next_page_token"
    }
}

/// Response body for the beta tool repertoire endpoint.
private struct ListToolRepertoireResponse: Sendable, Decodable {
    /// Protocol metadata attached to the tool repertoire response.
    var metadata: AteliaProtocolMetadata
    /// Tool repertoire entries visible to the session.
    var entries: [AteliaToolRepertoireEntry]
}

/// Secretary API envelope wrapping either success data or a structured error.
private enum APIEnvelope<Payload: Decodable>: Decodable {
    /// Successful response payload.
    case ok(Payload)
    /// Structured API error payload.
    case error(AteliaAPIError)

    /// Top-level keys used by the Secretary API envelope.
    private enum CodingKeys: String, CodingKey {
        /// Envelope status discriminator.
        case status
        /// Success payload.
        case data
        /// Structured error payload.
        case error
    }

    /// Envelope status discriminator values.
    private enum Status: String, Decodable {
        /// Successful API response.
        case ok
        /// Structured API error response.
        case error
    }

    /// Decodes the mutually exclusive `ok` or `error` envelope shape.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Status.self, forKey: .status) {
        case .ok:
            self = .ok(try container.decode(Payload.self, forKey: .data))
        case .error:
            self = .error(try container.decode(AteliaAPIError.self, forKey: .error))
        }
    }
}
