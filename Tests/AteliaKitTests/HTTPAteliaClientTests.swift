import Foundation
import Testing
@testable import AteliaKit

@Test func httpClientFetchesHealthFromEnvelope() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.absoluteString == "http://127.0.0.1:8080/v1/health")
        #expect(request.httpMethod == "GET")

        return #"""
        {
          "status": "ok",
          "data": {
            "daemon_status": "running",
            "daemon_version": "0.1.0",
            "protocol_version": "1.0.0",
            "storage_version": "0.1.0",
            "storage_status": "ready",
            "capabilities": ["health.v1"],
            "beta_state": null
          }
        }
        """#
    })

    let health = try await client.health(
        for: AteliaSession(endpoint: AteliaEndpoint(host: "127.0.0.1"))
    )

    #expect(health.daemonStatus == .running)
    #expect(health.protocolVersion == "1.0.0")
}

@Test func httpClientSendsBearerTokenAndDecodesRepositories() async throws {
    let client = HTTPAteliaClient(bearerToken: "token-123", transport: .fixture { request in
        #expect(request.url?.absoluteString == "http://localhost:8080/v1/repositories:list")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token-123")

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["repositories.v1"]
            },
            "repositories": [
              {
                "repository_id": "repo_123",
                "display_name": "Atelia Kit",
                "root_path": "/workspace/atelia-kit",
                "allowed_scope": {
                  "kind": "repository",
                  "roots": ["/workspace/atelia-kit"],
                  "include_patterns": [],
                  "exclude_patterns": []
                },
                "trust_state": "trusted",
                "created_at_unix_ms": 1710000000000,
                "updated_at_unix_ms": 1710000100000
              }
            ],
            "next_page_token": null
          }
        }
        """#
    })

    let repositories = try await client.repositories(for: AteliaSession())

    #expect(repositories.map(\.repositoryId) == ["repo_123"])
}

@Test func httpClientPaginatesRepositoriesUntilTokenIsNil() async throws {
    let recorder = RepositoryPageRecorder()
    let client = HTTPAteliaClient(transport: .fixture { request in
        try await recorder.response(for: request)
    })

    let repositories = try await client.repositories(for: AteliaSession())
    let pageTokens = await recorder.pageTokens

    #expect(repositories.map(\.repositoryId) == ["repo_1", "repo_2"])
    #expect(pageTokens == [nil, "page-2"])
}

@Test func httpClientDecodesToolRepertoire() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/repertoire:list")

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["repertoire.v1"]
            },
            "entries": [
              {
                "tool_id": "secretary.echo",
                "name": "Secretary Echo",
                "description": "Echo input.",
                "provider_kind": "builtin",
                "provider_id": "atelia-secretary",
                "risk_tier": "R0",
                "default_result_format": "toon",
                "supported_result_formats": ["toon", "json"],
                "idempotency": "idempotent",
                "cancellable": false,
                "streaming": false,
                "timeout_ms": 0
              }
            ]
          }
        }
        """#
    })

    let entries = try await client.toolRepertoire(for: AteliaSession())

    #expect(entries.map(\.toolId) == ["secretary.echo"])
}

@Test func httpClientSurfacesStructuredAPIError() async throws {
    let client = HTTPAteliaClient(transport: .fixture(statusCode: 401) { _ in
        #"""
        {
          "status": "error",
          "error": {
            "code": "unauthorized",
            "reason": "missing or invalid Authorization header",
            "recoverable": false,
            "next_state": "authentication_required"
          }
        }
        """#
    })

    await #expect(throws: HTTPAteliaClientError.apiError(
        AteliaAPIError(
            code: "unauthorized",
            reason: "missing or invalid Authorization header",
            recoverable: false,
            nextState: "authentication_required"
        )
    )) {
        _ = try await client.health(for: AteliaSession())
    }
}

private extension AteliaHTTPTransport {
    static func fixture(
        statusCode: Int = 200,
        respond: @escaping @Sendable (URLRequest) async throws -> String
    ) -> Self {
        Self { request in
            let body = try await respond(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (body.data(using: .utf8)!, response)
        }
    }
}

private actor RepositoryPageRecorder {
    private(set) var pageTokens: [String?] = []

    func response(for request: URLRequest) throws -> String {
        let pageToken = try pageToken(from: request)
        pageTokens.append(pageToken)

        switch pageToken {
        case nil:
            return repositoryResponse(id: "repo_1", nextPageToken: "page-2")
        case "page-2":
            return repositoryResponse(id: "repo_2", nextPageToken: nil)
        default:
            Issue.record("Unexpected page token: \(String(describing: pageToken))")
            return repositoryResponse(id: "repo_unexpected", nextPageToken: nil)
        }
    }

    private func pageToken(from request: URLRequest) throws -> String? {
        guard let body = request.httpBody, !body.isEmpty else {
            return nil
        }

        let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        return object?["page_token"] as? String
    }

    private func repositoryResponse(id: String, nextPageToken: String?) -> String {
        let encodedNextPageToken = nextPageToken.map { #""\#($0)""# } ?? "null"
        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["repositories.v1"]
            },
            "repositories": [
              {
                "repository_id": "\#(id)",
                "display_name": "\#(id)",
                "root_path": "/workspace/\#(id)",
                "allowed_scope": {
                  "kind": "repository",
                  "roots": ["/workspace/\#(id)"],
                  "include_patterns": [],
                  "exclude_patterns": []
                },
                "trust_state": "trusted",
                "created_at_unix_ms": 1710000000000,
                "updated_at_unix_ms": 1710000100000
              }
            ],
            "next_page_token": \#(encodedNextPageToken)
          }
        }
        """#
    }
}
