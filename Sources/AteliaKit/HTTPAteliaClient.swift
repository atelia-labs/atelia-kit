import Foundation

/// Errors surfaced by the HTTP/JSON Secretary beta transport.
public enum HTTPAteliaClientError: Error, Sendable, Equatable {
    case invalidURL(path: String)
    case invalidHTTPResponse
    case unsuccessfulStatus(code: Int, reason: String?)
    case apiError(AteliaAPIError)
    case repeatedPageToken(String)
}

/// Stable error shape returned by the daemon transport.
public struct AteliaAPIError: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case code
        case reason
        case recoverable
        case nextState = "next_state"
        case retryAfter = "retry_after"
        case auditRef = "audit_ref"
    }

    public var code: String
    public var reason: String
    public var recoverable: Bool
    public var nextState: String
    public var retryAfter: AteliaRetryAfter?
    public var auditRef: String?

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
    case seconds(Double)
    case token(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let seconds = try? container.decode(Double.self) {
            self = .seconds(seconds)
            return
        }
        self = .token(try container.decode(String.self))
    }

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
    public var send: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    public init(send: @escaping @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)) {
        self.send = send
    }

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
    private let transport: AteliaHTTPTransport
    private let bearerToken: String?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        bearerToken: String? = nil,
        transport: AteliaHTTPTransport = .urlSession()
    ) {
        self.bearerToken = bearerToken
        self.transport = transport
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    public func health(for session: AteliaSession) async throws -> AteliaHealthResponse {
        try await send(
            session: session,
            method: "GET",
            path: "/v1/health",
            body: EmptyRequest()
        )
    }

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

    public func toolRepertoire(for session: AteliaSession) async throws -> [AteliaToolRepertoireEntry] {
        let response: ListToolRepertoireResponse = try await send(
            session: session,
            method: "POST",
            path: "/v1/repertoire:list",
            body: EmptyRequest()
        )
        return response.entries
    }

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

    private static func responseReason(from data: Data) -> String? {
        guard let reason = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !reason.isEmpty else {
            return nil
        }
        return reason
    }

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
}

private struct EmptyRequest: Sendable, Codable, Equatable {}

private struct EmptyResponse: Sendable, Decodable {}

private struct ProjectStatusRequest: Sendable, Encodable {
    private enum CodingKeys: String, CodingKey {
        case repositoryId = "repository_id"
    }

    var repositoryId: String
}

private struct ListRepositoriesRequest: Sendable, Encodable {
    private enum CodingKeys: String, CodingKey {
        case pageToken = "page_token"
    }

    var pageToken: String?
}

private struct ListRepositoriesResponse: Sendable, Decodable {
    var metadata: AteliaProtocolMetadata
    var repositories: [AteliaRepository]
    var nextPageToken: String?

    private enum CodingKeys: String, CodingKey {
        case metadata
        case repositories
        case nextPageToken = "next_page_token"
    }
}

private struct ListToolRepertoireResponse: Sendable, Decodable {
    var metadata: AteliaProtocolMetadata
    var entries: [AteliaToolRepertoireEntry]
}

private enum APIEnvelope<Payload: Decodable>: Decodable {
    case ok(Payload)
    case error(AteliaAPIError)

    private enum CodingKeys: String, CodingKey {
        case status
        case data
        case error
    }

    private enum Status: String, Decodable {
        case ok
        case error
    }

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
