import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import AteliaKit

/// Verifies the HTTP client fetches and decodes the health envelope.
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

/// Verifies repository requests include bearer auth and decode repository pages.
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

/// Verifies repository listing follows page tokens until pagination ends.
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

/// Verifies repeated repository page tokens are rejected to avoid loops.
@Test func httpClientRejectsRepeatedRepositoryPageToken() async throws {
    let client = HTTPAteliaClient(transport: .fixture { _ in
        RepositoryPageRecorder.repositoryResponse(id: "repo_loop", nextPageToken: "page-loop")
    })

    await #expect(throws: HTTPAteliaClientError.repeatedPageToken("page-loop")) {
        _ = try await client.repositories(for: AteliaSession())
    }
}

/// Verifies the HTTP client decodes the beta tool repertoire endpoint.
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
                "aep_source_class": "host-shipped-built-in",
                "aep_package_id": "host.secretary",
                "aep_component_id": "runtime",
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
    #expect(entries[0].aepPackageId == "host.secretary")
    #expect(entries[0].aepComponentId == "runtime")
}

/// Verifies the HTTP client calls the service broker authorization endpoint.
@Test func httpClientAuthorizesServiceCall() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/services/authorize")
        #expect(request.httpMethod == "POST")
        let body = try #require(request.httpBody)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(object["caller_package_id"] as? String == "com.example.consumer")
        #expect(object["callee_package_id"] as? String == "com.example.provider")
        #expect(object["caller_extension_id"] == nil)
        #expect(object["callee_extension_id"] == nil)
        #expect(object["schema_version"] as? String == "v1")
        #expect(object["required_permission"] as? String == "service.review.comments")

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["services.v1"]
            },
            "grant": {
              "caller_package_id": "com.example.consumer",
              "caller_version": "2.0.0",
              "callee_package_id": "com.example.provider",
              "callee_version": "1.2.0",
              "service": "review.comments",
              "method": "summarize",
              "schema_version": "v1",
              "required_permission": "service.review.comments"
            }
          }
        }
        """#
    })

    let grant = try await client.authorizeServiceCall(
        for: AteliaSession(),
        request: AteliaAuthorizeServiceCallRequest(
            callerPackageId: "com.example.consumer",
            calleePackageId: "com.example.provider",
            service: "review.comments",
            method: "summarize",
            schemaVersion: "v1",
            requiredPermission: "service.review.comments"
        )
    )

    #expect(grant.callerVersion == "2.0.0")
    #expect(grant.calleeVersion == "1.2.0")
    #expect(grant.requiredPermission == "service.review.comments")
}

/// Verifies the HTTP client calls the live service broker execution endpoint.
@Test func httpClientCallsService() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/services/call")
        #expect(request.httpMethod == "POST")
        let body = try #require(request.httpBody)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(object["caller_package_id"] as? String == "com.example.consumer")
        #expect(object["callee_package_id"] as? String == "com.example.provider")
        #expect(object["caller_extension_id"] == nil)
        #expect(object["callee_extension_id"] == nil)
        #expect(object["service"] as? String == "review.comments")
        #expect(object["method"] as? String == "summarize")
        #expect(object["schema_version"] as? String == "v1")
        #expect(object["required_permission"] as? String == "service.review.comments")

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["services.v1"]
            },
            "grant": {
              "caller_package_id": "com.example.consumer",
              "caller_version": "2.0.0",
              "callee_package_id": "com.example.provider",
              "callee_version": "1.2.0",
              "service": "review.comments",
              "method": "summarize",
              "schema_version": "v1",
              "required_permission": "service.review.comments"
            },
            "result": {
              "status": "unavailable",
              "outcome": "unavailable",
              "reason": "no executor is configured for this service",
              "reason_code": "no_executor"
            }
          }
        }
        """#
    })

    let response = try await client.callServiceResponse(
        for: AteliaSession(),
        request: AteliaServiceCallRequest(
            callerPackageId: "com.example.consumer",
            calleePackageId: "com.example.provider",
            service: "review.comments",
            method: "summarize",
            schemaVersion: "v1",
            requiredPermission: "service.review.comments"
        )
    )

    #expect(response.result.status == "unavailable")
    #expect(response.result.outcome == "unavailable")
    #expect(response.result.reason == "no executor is configured for this service")
    #expect(response.result.reasonCode == "no_executor")

    let result = try await client.callService(
        for: AteliaSession(),
        request: AteliaServiceCallRequest(
            callerPackageId: "com.example.consumer",
            calleePackageId: "com.example.provider",
            service: "review.comments",
            method: "summarize",
            schemaVersion: "v1",
            requiredPermission: "service.review.comments"
        )
    )
    #expect(result == response.result)
}

/// Verifies the HTTP client calls the package trust index endpoint with the beta transport shape.
@Test func httpClientFetchesPackageTrustIndexEnvelope() async throws {
    let client = HTTPAteliaClient(bearerToken: "token-123", transport: .fixture { request in
        #expect(request.url?.path == "/v1/package-trust-index:list")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token-123")
        let body = try #require(
            JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
        )
        #expect(body["include_blocked"] as? Bool == true)
        #expect(body["discovery_only"] as? Bool == false)

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["package_trust_index.v1"]
            },
            "packages": [
              {
                "package_id": "com.example.active",
                "version": "1.2.3",
                "status": "installed",
                "boundary": "official",
                "manifest_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                "artifact_digest": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                "source": {
                  "source": "github",
                  "repository": "atelia-labs/atelia",
                  "ref": "refs/tags/v1.2.3",
                  "manifest_path": "packages/example/package.yml",
                  "commit": "deadbeef",
                  "registry_identity": "atelia-official",
                  "publication": {
                    "visibility": "public_searchable",
                    "registry_submission": "accepted"
                  }
                },
                "approved_permissions": ["repo.read"],
                "rollback_snapshot": {
                  "manifest_digest": "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
                  "artifact_digest": "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
                }
              },
              {
                "package_id": "com.example.blocked",
                "version": "1.0.0",
                "status": "blocked",
                "boundary": "third_party",
                "manifest_digest": "sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
                "artifact_digest": "sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
                "block": {
                  "reason": "policy_violation",
                  "key": {
                    "artifact_digest": "sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
                  }
                }
              }
            ]
          }
        }
        """#
    })

    let response = try await client.packageTrustIndexResponse(for: AteliaSession())

    #expect(response.metadata.protocolVersion == "1.0.0")
    #expect(response.metadata.capabilities == ["package_trust_index.v1"])
    #expect(response.packages.map(\.packageId) == ["com.example.active", "com.example.blocked"])
    #expect(response.packages[1].status == .blocked)
    #expect(response.packages[1].block?.reason == .policyViolation)
    #expect(response.packages[1].block?.key == .artifactDigest("sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))

    let entries = try await client.packageTrustIndex(for: AteliaSession())
    #expect(entries.map(\.packageId) == ["com.example.active", "com.example.blocked"])
}

/// Verifies the package trust index endpoint receives explicit trust-index request filters.
@Test func httpClientFiltersPackageTrustIndexRequest() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        let body = try #require(
            JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
        )
        #expect(request.url?.path == "/v1/package-trust-index:list")
        #expect(body["include_blocked"] as? Bool == false)
        #expect(body["discovery_only"] as? Bool == true)

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["package_trust_index.v1"]
            },
            "packages": []
          }
        }
        """#
    })

    let response = try await client.packageTrustIndexResponse(
        for: AteliaSession(),
        request: AteliaPackageTrustIndexRequest(includeBlocked: false, discoveryOnly: true)
    )

    #expect(response.packages.isEmpty)
    #expect(response.metadata.capabilities == ["package_trust_index.v1"])
}

/// Verifies package install requests hit the package install route and decode the lifecycle envelope.
@Test func httpClientInstallsPackage() async throws {
    let manifestFixture = try JSONDecoder().decode(
        AteliaPackageManifest.self,
        from: #"""
        {
          "schema": "atelia.extension.v1",
          "id": "com.example.review.extension",
          "name": "Review extension",
          "version": "1.0.0"
        }
        """#.data(using: .utf8)!
    )
    let request = AteliaPackageLifecycleRequest(
        manifest: manifestFixture,
        approveLocalUnsigned: true,
        allowLocalProcessRuntime: true,
        approveSourceChange: true
    )

    let client = HTTPAteliaClient(
        bearerToken: "token-123",
        transport: .fixture { request in
            #expect(request.url?.path == "/v1/packages/install")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token-123")

            let body = try #require(
                JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
            )
            let manifestObject = try #require(body["manifest"] as? [String: Any])
            #expect(manifestObject["id"] as? String == "com.example.review.extension")
            #expect(body["approve_local_unsigned"] as? Bool == true)
            #expect(body["allow_local_process_runtime"] as? Bool == true)
            #expect(body["approve_source_change"] as? Bool == true)

            return #"""
            {
              "status": "ok",
              "data": {
                "metadata": {
                  "protocol_version": "1.0.0",
                  "daemon_version": "0.1.0",
                  "storage_version": "0.1.0",
                  "capabilities": ["extensions.install.v1"]
                },
                "record": {
                  "id": "com.example.review.extension",
                  "version": "1.0.0",
                  "manifest_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                  "artifact_digest": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                  "source": {
                    "source": "github",
                    "repository": "atelia-labs/atelia",
                    "ref": "refs/tags/v1.0.0",
                    "manifest_path": "packages/review/package.yml",
                    "commit": "deadbeef"
                  },
                  "boundary": "third_party",
                  "status": "installed",
                  "approved_permissions": ["repo.read"],
                  "rollback_snapshot": {
                    "manifest_digest": "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
                    "artifact_digest": "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
                  }
                }
              }
            }
            """#
        }
    )

    let response = try await client.packageInstallResponse(for: AteliaSession(), request: request)

    #expect(response.metadata.capabilities == ["extensions.install.v1"])
    #expect(response.record.packageId == "com.example.review.extension")
    #expect(response.record.status == .installed)
}

/// Verifies package updates hit the package update route and decode the lifecycle envelope.
@Test func httpClientUpdatesPackage() async throws {
    let manifestFixture = try JSONDecoder().decode(
        AteliaPackageManifest.self,
        from: #"""
        {
          "schema": "atelia.extension.v1",
          "id": "com.example.review.extension",
          "name": "Review extension",
          "version": "1.1.0"
        }
        """#.data(using: .utf8)!
    )
    let request = AteliaPackageLifecycleRequest(
        manifest: manifestFixture,
        approveLocalUnsigned: false,
        allowLocalProcessRuntime: false,
        approveSourceChange: false
    )

    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/update")
        #expect(request.httpMethod == "POST")
        let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
        #expect(body["manifest"] != nil)
        #expect(body["approve_local_unsigned"] as? Bool == false)
        #expect(body["allow_local_process_runtime"] as? Bool == false)
        #expect(body["approve_source_change"] as? Bool == false)

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["extensions.update.v1"]
            },
            "record": {
              "id": "com.example.review.extension",
              "version": "1.1.0",
              "manifest_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
              "artifact_digest": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
              "source": {
                "source": "github",
                "repository": "atelia-labs/atelia",
                "ref": "refs/tags/v1.1.0",
                "manifest_path": "packages/review/package.yml",
                "commit": "feedface"
              },
              "boundary": "third_party",
              "status": "installed",
              "approved_permissions": ["repo.read"]
            }
          }
        }
        """#
    })

    let response = try await client.packageUpdateResponse(for: AteliaSession(), request: request)

    #expect(response.metadata.capabilities == ["extensions.update.v1"])
    #expect(response.record.version == "1.1.0")
}

/// Verifies package status checks the package status endpoint and decodes package status response naming.
@Test func httpClientGetsPackageStatus() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/com.example.review.extension/status")
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == Data("{}".utf8))

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["extensions.status.v1"]
            },
            "extension": {
              "extension_id": "com.example.review.extension",
              "record": {
                "id": "com.example.review.extension",
                "version": "1.0.0",
                "manifest_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                "artifact_digest": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                "source": {
                  "source": "github",
                  "repository": "atelia-labs/atelia",
                  "ref": "refs/tags/v1.0.0",
                  "manifest_path": "packages/review/package.yml",
                  "commit": "deadbeef"
                },
                "boundary": "official",
                "status": "installed",
                "approved_permissions": ["repo.read"],
                "rollback_snapshot": {
                  "manifest_digest": "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
                  "artifact_digest": "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
                }
              },
              "block": null
            }
          }
        }
        """#
    })

    let status = try await client.packageStatus(for: AteliaSession(), packageId: "com.example.review.extension")
    #expect(status.packageId == "com.example.review.extension")
    #expect(status.record?.status == .installed)
}

/// Verifies package inspect checks the package inspect endpoint and decodes detail-only fields.
@Test func httpClientInspectsPackage() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/com.example.review.extension/inspect")
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == Data("{}".utf8))

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["package_inspect.v1"]
            },
            "package_id": "com.example.review.extension",
            "extension": {
              "extension_id": "com.example.review.extension",
              "record": {
                "id": "com.example.review.extension",
                "version": "2.0.0",
                "manifest_digest": "sha256:2222222222222222222222222222222222222222222222222222222222222222",
                "artifact_digest": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                "source": {
                  "source": "github",
                  "repository": "atelia-labs/review-package",
                  "ref": "refs/tags/v2.0.0",
                  "manifest_path": "package.yml",
                  "commit": "deadbeef"
                },
                "boundary": "third_party",
                "status": "installed",
                "previous_version": "1.0.0",
                "approved_permissions": ["service.review.comments"]
              },
              "block": null
            },
            "manifest": {
              "schema": "atelia.extension.v1",
              "id": "com.example.review.extension",
              "name": "Review Package",
              "version": "2.0.0"
            },
            "block": null,
            "permissions": ["service.review.comments"],
            "services": {
              "provides": [],
              "consumes": []
            },
            "rollback_available": true,
            "rollback_snapshot": {
              "manifest_digest": "sha256:1111111111111111111111111111111111111111111111111111111111111111",
              "artifact_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            },
            "source": {
              "source": "github",
              "repository": "atelia-labs/review-package",
              "ref": "refs/tags/v2.0.0",
              "manifest_path": "package.yml",
              "commit": "deadbeef"
            },
            "trust": null
          }
        }
        """#
    })

    let inspect = try await client.packageInspect(for: AteliaSession(), packageId: "com.example.review.extension")

    #expect(inspect.packageId == "com.example.review.extension")
    #expect(inspect.package.record?.version == "2.0.0")
    #expect(inspect.manifest["version"] == .string("2.0.0"))
    #expect(inspect.permissions == ["service.review.comments"])
    #expect(inspect.rollbackAvailable)
    #expect(
        inspect.rollbackSnapshot?.artifactDigest
            == "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    )
}

/// Verifies package list calls the packages list endpoint with list filters.
@Test func httpClientListsPackages() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/list")
        #expect(request.httpMethod == "POST")
        let body = try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
        #expect(body?["include_blocked"] as? Bool == false)

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["extensions.list.v1"]
            },
            "extensions": [
              {
                "extension_id": "com.example.active",
                "record": {
                  "id": "com.example.active",
                  "version": "1.2.3",
                  "manifest_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                  "artifact_digest": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                  "source": {
                    "source": "github",
                    "repository": "atelia-labs/atelia",
                    "ref": "refs/tags/v1.2.3"
                  },
                  "boundary": "official",
                  "status": "installed",
                  "approved_permissions": ["repo.read"]
                }
              },
              {
                "extension_id": "com.example.blocked",
                "record": {
                  "id": "com.example.blocked",
                  "version": "1.0.0",
                  "manifest_digest": "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
                  "artifact_digest": "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
                  "source": {
                    "source": "github",
                    "repository": "atelia-labs/atelia",
                    "ref": "refs/tags/v1.0.0"
                  },
                  "boundary": "third_party",
                  "status": "blocked",
                  "approved_permissions": []
                },
                "block": {
                  "reason": "policy_violation",
                  "key": {
                    "extension_id": "com.example.blocked"
                  }
                }
              }
            ]
          }
        }
        """#
    })

    let packages = try await client.packageList(for: AteliaSession(), request: AteliaPackageListRequest(includeBlocked: false))

    #expect(packages.map(\.packageId) == ["com.example.active", "com.example.blocked"])
    #expect(packages[1].block?.reason == .policyViolation)
}

/// Verifies package disable and enable use identifier-scoped lifecycle endpoints.
@Test func httpClientDisablesAndEnablesPackage() async throws {
    let disableClient = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/com.example.review.extension/disable")
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == Data("{}".utf8))

        return lifecycleRecordResponse(capability: "extensions.disable.v1", status: "disabled")
    })

    let disabled = try await disableClient.packageDisable(
        for: AteliaSession(),
        packageId: "com.example.review.extension"
    )

    #expect(disabled.packageId == "com.example.review.extension")
    #expect(disabled.status == .disabled)

    let enableClient = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/com.example.review.extension/enable")
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == Data("{}".utf8))

        return lifecycleRecordResponse(capability: "extensions.enable.v1", status: "installed")
    })

    let enabled = try await enableClient.packageEnable(
        for: AteliaSession(),
        packageId: "com.example.review.extension"
    )

    #expect(enabled.packageId == "com.example.review.extension")
    #expect(enabled.status == .installed)
}

/// Verifies package authoring-flow requests hit the identifier-scoped endpoint and decode.
@Test func httpClientFetchesPackageAuthoringFlow() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/com.example.review.extension/authoring-flow")
        #expect(request.httpMethod == "POST")
        let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
        #expect(body["package_id"] as? String == "com.example.review.extension")
        #expect(body["include_private_steps"] as? Bool == true)

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["extensions.authoring-flow.v1"]
            },
            "flow": {
              "package_id": "com.example.review.extension",
              "source_class": "workspace-local",
              "steps": [
                {
                  "id": "inspect",
                  "title": "Inspect package",
                  "state": "complete",
                  "requires_explicit_consent": false,
                  "policy_notes": []
                }
              ],
              "publication_plan": {
                "visibility": "public_searchable",
                "source_class": "workspace-local",
                "requires_registry_submission": false,
                "production_installable": true
              }
            }
          }
        }
        """#
    })

    let response = try await client.packageAuthoringFlowResponse(
        for: AteliaSession(),
        request: AteliaPackageAuthoringFlowRequest(
            packageId: "com.example.review.extension",
            includePrivateSteps: true
        )
    )

    #expect(response.metadata.capabilities == ["extensions.authoring-flow.v1"])
    #expect(response.flow.id == "com.example.review.extension")
    #expect(response.flow.steps.map(\.id) == [.inspect])
}

/// Verifies package remix requests hit the identifier-scoped endpoint and decode.
@Test func httpClientStartsPackageRemix() async throws {
    let request = AteliaPackageRemixRequest(
        packageId: "com.example.review.extension",
        sourceClass: .workspaceLocal,
        source: AteliaPackageGitHubSourceReference(
            repository: "atelia-labs/atelia",
            manifestPath: "packages/review/package.yml"
        ),
        manifest: nil
    )

    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/com.example.review.extension/remix")
        #expect(request.httpMethod == "POST")
        let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
        #expect(body["package_id"] as? String == "com.example.review.extension")
        #expect(body["source_class"] as? String == "workspace-local")
        let source = try #require(body["source"] as? [String: Any])
        #expect(source["repository"] as? String == "atelia-labs/atelia")

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["extensions.remix.v1"]
            },
            "flow": {
              "package_id": "com.example.review.extension",
              "source_class": "workspace-local",
              "steps": [
                {
                  "id": "remix",
                  "title": "Remix package",
                  "state": "available",
                  "requires_explicit_consent": false,
                  "policy_notes": []
                }
              ]
            }
          }
        }
        """#
    })

    let response = try await client.packageRemixResponse(for: AteliaSession(), request: request)
    let flow = try await client.packageRemix(for: AteliaSession(), request: request)

    #expect(response.metadata.capabilities == ["extensions.remix.v1"])
    #expect(response.flow.id == "com.example.review.extension")
    #expect(response.flow == flow)
}

/// Verifies publication requests hit the identifier-scoped endpoint and decode.
@Test func httpClientStartsPackagePublication() async throws {
    let request = AteliaPackagePublicationRequest(
        packageId: "com.example.review.extension",
        sourceClass: .verifiedRegistry,
        visibility: .publicSearchable,
        githubActions: [.prepareReleaseMetadata, .submitRegistryMetadata],
        requiresRegistrySubmission: true,
        productionInstallable: true
    )

    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/com.example.review.extension/publication")
        #expect(request.httpMethod == "POST")
        let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
        #expect(body["package_id"] as? String == "com.example.review.extension")
        #expect(body["source_class"] as? String == "verified-registry")
        #expect(body["visibility"] as? String == "public_searchable")
        #expect(body["requires_registry_submission"] as? Bool == true)
        #expect(body["production_installable"] as? Bool == true)

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["extensions.publication.v1"]
            },
            "flow": {
              "package_id": "com.example.review.extension",
              "source_class": "verified-registry",
              "steps": [
                {
                  "id": "publish",
                  "title": "Publish package",
                  "state": "blocked",
                  "requires_explicit_consent": true,
                  "policy_notes": ["Registry submission required"]
                }
              ],
              "publication_plan": {
                "visibility": "public_searchable",
                "source_class": "verified-registry",
                "github_actions": ["prepare_release_metadata", "submit_registry_metadata"],
                "requires_registry_submission": true,
                "production_installable": true
              }
            }
          }
        }
        """#
    })

    let response = try await client.packagePublicationResponse(for: AteliaSession(), request: request)
    let flow = try await client.packagePublication(for: AteliaSession(), request: request)

    #expect(response.metadata.capabilities == ["extensions.publication.v1"])
    #expect(response.flow == flow)
    #expect(response.flow.id == "com.example.review.extension")
}

/// Verifies registry-submission requests hit the identifier-scoped endpoint and decode state.
@Test func httpClientSubmitsRegistrySubmissionState() async throws {
    let request = AteliaPackageRegistrySubmissionRequest(
        packageId: "com.example.review.extension",
        state: .accepted,
        note: "approved by release"
    )
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/com.example.review.extension/registry-submission")
        #expect(request.httpMethod == "POST")
        let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
        #expect(body["package_id"] as? String == "com.example.review.extension")
        #expect(body["state"] as? String == "accepted")
        #expect(body["note"] as? String == "approved by release")

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["extensions.registry-submission.v1"]
            },
            "package_id": "com.example.review.extension",
            "state": "accepted",
            "message": "queued",
            "flow": {
              "package_id": "com.example.review.extension",
              "source_class": "workspace-local",
              "steps": [
                {
                  "id": "registry_search",
                  "title": "Check registry state",
                  "state": "blocked",
                  "requires_explicit_consent": false,
                  "policy_notes": []
                }
              ]
            }
          }
        }
        """#
    })

    let response = try await client.packageRegistrySubmissionResponse(for: AteliaSession(), request: request)
    let state = try await client.packageRegistrySubmissionState(
        for: AteliaSession(),
        request: request
    )

    #expect(response.metadata.capabilities == ["extensions.registry-submission.v1"])
    #expect(response.packageId == "com.example.review.extension")
    #expect(response.state == .accepted)
    #expect(response.flow?.id == "com.example.review.extension")
    #expect(response.message == "queued")
    #expect(state == .accepted)
}

/// Verifies job submissions hit the submit route and encode canonical request fields.
@Test func httpClientSubmitsJob() async throws {
    let request = AteliaSubmitJobRequest(
        repositoryId: "repo_123",
        requester: .agent(id: "agent_secretary", displayName: "Secretary"),
        kind: "documentation_review",
        message: "Please review the protocol references.",
        goal: "Review protocol references",
        modelRouteKey: "models/atelia-balanced",
        permissionModeRouteKey: "permissions/full-access",
        pathScope: AteliaPathScope(
            kind: .explicitPaths,
            roots: ["README.md"]
        ),
        requestedCapabilities: ["filesystem.read"],
        idempotencyKey: "submit-job-123",
        toolArgs: nil
    )

    let client = HTTPAteliaClient(bearerToken: "token-123", transport: .fixture { request in
        #expect(request.url?.path == "/v1/jobs/submit")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token-123")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
        #expect(body["repository_id"] as? String == "repo_123")
        #expect(body["kind"] as? String == "documentation_review")
        #expect(body["message"] as? String == "Please review the protocol references.")
        #expect(body["goal"] as? String == "Review protocol references")
        #expect(body["model_route_key"] as? String == "models/atelia-balanced")
        #expect(body["permission_mode_route_key"] as? String == "permissions/full-access")
        #expect(body["requested_capabilities"] as? [String] == ["filesystem.read"])
        #expect(body["idempotency_key"] as? String == "submit-job-123")
        #expect(body["tool_args"] == nil)

        let requester = try #require(body["requester"] as? [String: Any])
        #expect(requester["type"] as? String == "agent")
        #expect(requester["id"] as? String == "agent_secretary")

        let pathScope = try #require(body["path_scope"] as? [String: Any])
        #expect(pathScope["kind"] as? String == "explicit_paths")
        #expect(pathScope["roots"] as? [String] == ["README.md"])
        #expect(pathScope["include_patterns"] == nil)
        #expect(pathScope["exclude_patterns"] == nil)

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["jobs.submit.v1"]
            },
            "job": {
              "job_id": "job_123",
              "repository_id": "repo_123",
              "requester": {
                "type": "agent",
                "id": "agent_secretary",
                "display_name": "Secretary"
              },
              "kind": "documentation_review",
              "goal": "Review protocol references",
              "status": "queued",
              "policy_summary": {
                "decision_id": "pol_123",
                "outcome": "audited",
                "risk_tier": "r1",
                "reason_code": "bounded_read"
              },
              "created_at_unix_ms": 1710000000000,
              "started_at_unix_ms": null,
              "completed_at_unix_ms": null,
              "latest_event_id": null,
              "cancellation": {
                "state": "not_requested",
                "requested_by": null,
                "reason": null,
                "requested_at_unix_ms": null,
                "completed_at_unix_ms": null
              }
            },
            "policy": {
              "decision_id": "pol_123",
              "outcome": "audited",
              "risk_tier": "r1",
              "requested_capability": "filesystem.read",
              "reason_code": "bounded_read",
              "reason": "Read-only request is permitted"
            }
          }
        }
        """#
    })

    let response = try await client.submitJobResponse(for: AteliaSession(), request: request)
    let job = try await client.submitJob(for: AteliaSession(), request: request)

    #expect(response.metadata.capabilities == ["jobs.submit.v1"])
    #expect(response.job.jobId == "job_123")
    #expect(response.job.status == .queued)
    #expect(response.job.goal == "Review protocol references")
    #expect(response.job.policySummary?.decisionId == "pol_123")
    #expect(response.policy.decisionId == "pol_123")
    #expect(response.policy.riskTier == .r1)
    #expect(job == response.job)
}

/// Verifies submit-job requests can carry Secretary filesystem tool arguments.
@Test func httpClientSubmitsJobWithFilesystemToolArgs() async throws {
    let request = AteliaSubmitJobRequest(
        repositoryId: "repo_123",
        requester: .agent(id: "agent_secretary", displayName: "Secretary"),
        kind: "tool",
        pathScope: AteliaPathScope(
            kind: .explicitPaths,
            roots: ["Sources"]
        ),
        requestedCapabilities: ["filesystem.search"],
        idempotencyKey: "search-123",
        toolArgs: AteliaSubmitJobToolArgs(
            pattern: "AteliaSubmitJobRequest",
            max: 10
        )
    )

    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/jobs/submit")
        #expect(request.httpMethod == "POST")

        let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
        #expect(body["requested_capabilities"] as? [String] == ["filesystem.search"])
        let toolArgs = try #require(body["tool_args"] as? [String: Any])
        #expect(toolArgs["pattern"] as? String == "AteliaSubmitJobRequest")
        #expect(toolArgs["max"] as? Int == 10)
        #expect(toolArgs["comparison_path"] == nil)
        #expect(toolArgs["max_bytes"] == nil)
        #expect(toolArgs["max_chars"] == nil)

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["jobs.submit.v1"]
            },
            "job": {
              "job_id": "job_123",
              "repository_id": "repo_123",
              "requester": {
                "type": "agent",
                "id": "agent_secretary",
                "display_name": "Secretary"
              },
              "kind": "tool",
              "status": "queued",
              "policy_summary": null,
              "created_at_unix_ms": 1710000000000,
              "started_at_unix_ms": null,
              "completed_at_unix_ms": null,
              "latest_event_id": null,
              "cancellation": null
            },
            "policy": {
              "decision_id": "pol_123",
              "outcome": "audited",
              "risk_tier": "r1",
              "requested_capability": "filesystem.search",
              "reason_code": "bounded_search",
              "reason": "Search request is permitted"
            }
          }
        }
        """#
    })

    let response = try await client.submitJobResponse(for: AteliaSession(), request: request)

    #expect(response.job.kind == "tool")
    #expect(response.policy.requestedCapability == "filesystem.search")
}

/// Verifies job submission HTTP payloads omit nil goals and responses tolerate omitted job goals.
@Test func httpClientSubmitsJobWithOmittedGoal() async throws {
    let request = AteliaSubmitJobRequest(
        repositoryId: "repo_123",
        requester: .agent(id: "agent_secretary", displayName: "Secretary"),
        kind: "documentation_review"
    )

    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/jobs/submit")
        #expect(request.httpMethod == "POST")

        let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
        #expect(body["repository_id"] as? String == "repo_123")
        #expect(body["kind"] as? String == "documentation_review")
        #expect(body["goal"] == nil)

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["jobs.submit.v1"]
            },
            "job": {
              "job_id": "job_123",
              "repository_id": "repo_123",
              "requester": {
                "type": "agent",
                "id": "agent_secretary",
                "display_name": "Secretary"
              },
              "kind": "documentation_review",
              "status": "queued",
              "policy_summary": null,
              "created_at_unix_ms": 1710000000000,
              "started_at_unix_ms": null,
              "completed_at_unix_ms": null,
              "latest_event_id": null,
              "cancellation": null
            },
            "policy": {
              "decision_id": "pol_123",
              "outcome": "audited",
              "risk_tier": "r1",
              "requested_capability": "filesystem.read",
              "reason_code": "bounded_read",
              "reason": "Read-only request is permitted"
            }
          }
        }
        """#
    })

    let response = try await client.submitJobResponse(for: AteliaSession(), request: request)

    #expect(response.job.jobId == "job_123")
    #expect(response.job.goal == nil)
    #expect(response.policy.decisionId == "pol_123")
}

/// Verifies repository registration hits Secretary's beta registration route.
@Test func httpClientRegistersRepository() async throws {
    let request = AteliaRegisterRepositoryRequest(
        displayName: "Atelia Kit",
        rootPath: "/workspace/atelia-kit",
        allowedScope: AteliaPathScope(
            kind: .repository,
            roots: ["/workspace/atelia-kit"]
        ),
        requester: .user(id: "user_123", displayName: "Ada")
    )

    let client = HTTPAteliaClient(bearerToken: "token-123", transport: .fixture { request in
        #expect(request.url?.path == "/v1/repositories:register")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token-123")

        let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
        #expect(body["display_name"] as? String == "Atelia Kit")
        #expect(body["root_path"] as? String == "/workspace/atelia-kit")
        let requester = try #require(body["requester"] as? [String: Any])
        #expect(requester["type"] as? String == "user")
        #expect(requester["id"] as? String == "user_123")
        let allowedScope = try #require(body["allowed_scope"] as? [String: Any])
        #expect(allowedScope["kind"] as? String == "repository")
        #expect(allowedScope["roots"] as? [String] == ["/workspace/atelia-kit"])

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["repositories.register.v1"]
            },
            "repository": {
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
            },
            "policy": null
          }
        }
        """#
    })

    let response = try await client.registerRepositoryResponse(for: AteliaSession(), request: request)
    let repository = try await client.registerRepository(for: AteliaSession(), request: request)

    #expect(response.metadata.capabilities == ["repositories.register.v1"])
    #expect(response.repository.repositoryId == "repo_123")
    #expect(response.policy == nil)
    #expect(repository == response.repository)
}

/// Verifies the HTTP client can fetch, cancel, and track job events through the lifecycle routes.
@Test func httpClientFetchesCancelsAndTracksJobEvents() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        switch request.url?.path {
        case "/v1/jobs/job_123":
            #expect(request.httpMethod == "GET")
            return #"""
            {
              "status": "ok",
              "data": {
                "metadata": {
                  "protocol_version": "1.0.0",
                  "daemon_version": "0.1.0",
                  "storage_version": "0.1.0",
                  "capabilities": ["jobs.get.v1"]
                },
                "job": {
                  "job_id": "job_123",
                  "repository_id": "repo_123",
                  "requester": {
                    "type": "agent",
                    "id": "agent_secretary",
                    "display_name": "Secretary"
                  },
                  "kind": "documentation_review",
                  "goal": "Review protocol references",
                  "status": "running",
                  "policy_summary": null,
                  "created_at_unix_ms": 1710000000000,
                  "started_at_unix_ms": 1710000001000,
                  "completed_at_unix_ms": null,
                  "latest_event_id": "evt_123",
                  "cancellation": {
                    "state": "not_requested",
                    "requested_by": null,
                    "reason": null,
                    "requested_at_unix_ms": null,
                    "completed_at_unix_ms": null
                  }
                }
              }
            }
            """#
        case "/v1/jobs/job_123/cancel":
            #expect(request.httpMethod == "POST")
            let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
            #expect(body["reason"] as? String == "stop")
            let requester = try #require(body["requester"] as? [String: Any])
            #expect(requester["type"] as? String == "user")
            return #"""
            {
              "status": "ok",
              "data": {
                "metadata": {
                  "protocol_version": "1.0.0",
                  "daemon_version": "0.1.0",
                  "storage_version": "0.1.0",
                  "capabilities": ["jobs.cancel.v1"]
                },
                "job": {
                  "job_id": "job_123",
                  "repository_id": "repo_123",
                  "requester": {
                    "type": "agent",
                    "id": "agent_secretary",
                    "display_name": "Secretary"
                  },
                  "kind": "documentation_review",
                  "goal": "Review protocol references",
                  "status": "canceled",
                  "policy_summary": null,
                  "created_at_unix_ms": 1710000000000,
                  "started_at_unix_ms": 1710000001000,
                  "completed_at_unix_ms": 1710000003000,
                  "latest_event_id": "evt_124",
                  "cancellation": {
                    "state": "completed",
                    "requested_by": {
                      "type": "user",
                      "id": "user_123",
                      "display_name": "Ada"
                    },
                    "reason": "stop",
                    "requested_at_unix_ms": 1710000002000,
                    "completed_at_unix_ms": 1710000003000
                  }
                },
                "cancellation": {
                  "state": "completed",
                  "requested_by": {
                    "type": "user",
                    "id": "user_123",
                    "display_name": "Ada"
                  },
                  "reason": "stop",
                  "requested_at_unix_ms": 1710000002000,
                  "completed_at_unix_ms": 1710000003000
                }
              }
            }
            """#
        case "/v1/jobs/job_123/events":
            #expect(request.httpMethod == "POST")
            let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
            #expect(body["job_ids"] == nil)
            #expect(body["subject_ids"] == nil)
            let cursor = try #require(body["cursor"] as? [String: Any])
            #expect(cursor["kind"] as? String == "after_sequence")
            #expect(cursor["sequence_number"] as? Int == 42)
            return #"""
            {
              "status": "ok",
              "data": {
                "metadata": {
                  "protocol_version": "1.0.0",
                  "daemon_version": "0.1.0",
                  "storage_version": "0.1.0",
                  "capabilities": ["events.list.v1"]
                },
                "events": [
                  {
                    "event_id": "evt_123",
                    "sequence": 42,
                    "occurred_at_unix_ms": 1710000001000,
                    "subject": {
                      "type": "job",
                      "id": "job_123"
                    },
                    "kind": "job.started",
                    "severity": "info",
                    "message": "job started",
                    "refs": {
                      "repository_id": "repo_123",
                      "job_id": "job_123"
                    }
                  }
                ],
                "next_page_token": null
              }
            }
            """#
        case "/v1/events/replay":
            #expect(request.httpMethod == "POST")
            let body = try #require(JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any])
            #expect(body["repository_id"] as? String == "repo_123")
            let cursor = try #require(body["cursor"] as? [String: Any])
            #expect(cursor["kind"] as? String == "after_event_id")
            #expect(cursor["event_id"] as? String == "evt_123")
            return #"""
            {
              "status": "ok",
              "data": {
                "metadata": {
                  "protocol_version": "1.0.0",
                  "daemon_version": "0.1.0",
                  "storage_version": "0.1.0",
                  "capabilities": ["events.replay.v1"]
                },
                "events": [
                  {
                    "event_id": "evt_123",
                    "sequence": 42,
                    "occurred_at_unix_ms": 1710000001000,
                    "subject": {
                      "type": "job",
                      "id": "job_123"
                    },
                    "kind": "job.started",
                    "severity": "info",
                    "message": "job started",
                    "refs": {
                      "repository_id": "repo_123",
                      "job_id": "job_123"
                    }
                  }
                ],
                "cursor": {
                  "kind": "after_event_id",
                  "event_id": "evt_123"
                }
              }
            }
            """#
        default:
            preconditionFailure("unexpected path: \(request.url?.path ?? "nil")")
        }
    })

    let job = try await client.job(for: AteliaSession(), jobId: "job_123")
    let canceledJob = try await client.cancelJob(
        for: AteliaSession(),
        jobId: "job_123",
        request: AteliaCancelJobRequest(
            requester: .user(id: "user_123", displayName: "Ada"),
            reason: "stop"
        )
    )
    let jobEvents = try await client.listJobEvents(
        for: AteliaSession(),
        jobId: "job_123",
        request: AteliaListEventsRequest(
            cursor: .afterSequence(42)
        )
    )
    let replayResponse = try await client.replayEventsResponse(
        for: AteliaSession(),
        request: AteliaReplayEventsRequest(
            repositoryId: "repo_123",
            cursor: .afterEventId("evt_123")
        )
    )

    #expect(job.jobId == "job_123")
    #expect(canceledJob.status == .canceled)
    #expect(jobEvents.map(\.eventId) == ["evt_123"])
    #expect(replayResponse.events.map(\.eventId) == ["evt_123"])
    #expect(replayResponse.cursor == .afterEventId("evt_123"))
}

/// Verifies job-scoped HTTP routes reject identifiers that cannot be embedded in one path segment.
@Test func httpClientRejectsInvalidJobIds() async throws {
    let client = HTTPAteliaClient(transport: .fixture { _ in
        Issue.record("Invalid job ids should fail before transport.")
        return "{}"
    })

    await #expect(throws: HTTPAteliaClientError.invalidJobId("")) {
        _ = try await client.jobResponse(for: AteliaSession(), jobId: "")
    }

    await #expect(throws: HTTPAteliaClientError.invalidJobId("jobs/123")) {
        _ = try await client.jobResponse(for: AteliaSession(), jobId: "jobs/123")
    }

    await #expect(throws: HTTPAteliaClientError.invalidJobId("..")) {
        _ = try await client.cancelJobResponse(
            for: AteliaSession(),
            jobId: "..",
            request: AteliaCancelJobRequest(
                requester: .user(id: "user_123", displayName: "Ada"),
                reason: "stop"
            )
        )
    }

    await #expect(throws: HTTPAteliaClientError.invalidJobId("job 123")) {
        _ = try await client.listJobEventsResponse(
            for: AteliaSession(),
            jobId: "job 123",
            request: AteliaListEventsRequest(repositoryId: "repo_123")
        )
    }
}

/// Verifies package removals use the identifier-scoped remove endpoint.
@Test func httpClientRemovesPackage() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/com.example.review.extension/remove")
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == Data("{}".utf8))

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["extensions.remove.v1"]
            },
            "record": {
              "id": "com.example.review.extension",
              "version": "1.0.0",
              "manifest_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
              "artifact_digest": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
              "source": {
                "source": "github",
                "repository": "atelia-labs/atelia",
                "ref": "refs/tags/v1.0.0"
              },
              "boundary": "official",
              "status": "installed_previous_version",
              "previous_version": "2.0.0",
              "approved_permissions": ["repo.read"]
            }
          }
        }
        """#
    })

    let response = try await client.packageRemoveResponse(for: AteliaSession(), packageId: "com.example.review.extension")

    #expect(response.record.packageId == "com.example.review.extension")
    #expect(response.record.previousVersion == "2.0.0")
    #expect(response.record.status == .installedPreviousVersion)
}

/// Verifies package blocklist apply/list endpoints round-trip their payloads.
@Test func httpClientAppliesAndListsPackageBlocklist() async throws {
    let applyClient = HTTPAteliaClient(
        bearerToken: "token-123",
        transport: .fixture { request in
            #expect(request.url?.path == "/v1/packages/blocklist/apply")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token-123")

            let body = try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
            let entry = try #require(body?["entry"] as? [String: Any])
            #expect((entry["reason"] as? String) == "user_blocked")
            let key = try #require(entry["key"] as? [String: Any])
            #expect(key["extension_id"] as? String == "com.example.review.extension")

            return #"""
            {
              "status": "ok",
              "data": {
                "metadata": {
                  "protocol_version": "1.0.0",
                  "daemon_version": "0.1.0",
                  "storage_version": "0.1.0",
                  "capabilities": ["extensions.blocklist.apply.v1"]
                },
                "entry": {
                  "reason": "user_blocked",
                  "key": {
                    "extension_id": "com.example.review.extension"
                  },
                  "note": "risk exception"
                }
              }
            }
            """#
        }
    )
    let applyRequest = AteliaPackageBlocklistRequest(
        entry: AteliaPackageBlocklistEntry(
            reason: .userBlocked,
            key: .extensionId("com.example.review.extension"),
            note: "risk exception"
        )
    )
    let applyResponse = try await applyClient.packageBlocklistApplyResponse(
        for: AteliaSession(),
        request: applyRequest
    )
    #expect(applyResponse.metadata.capabilities == ["extensions.blocklist.apply.v1"])
    #expect(applyResponse.entry.note == "risk exception")

    let listClient = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/blocklist/list")
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == Data("{}".utf8))

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["extensions.blocklist.list.v1"]
            },
            "entries": [
              {
                "reason": "user_blocked",
                "key": {
                  "extension_id": "com.example.review.extension"
                },
                "note": "risk exception"
              },
              {
                "reason": "policy_violation",
                "key": {
                  "artifact_digest": "sha256:cccc"
                },
                "note": null
              }
            ]
          }
        }
        """#
    })

    let blocklist = try await listClient.packageBlocklistListResponse(for: AteliaSession())
    #expect(blocklist.entries.count == 2)
    #expect(blocklist.entries[0].reason == .userBlocked)
    #expect(blocklist.entries[0].key == .extensionId("com.example.review.extension"))
    #expect(blocklist.entries[1].reason == .policyViolation)
}

/// Verifies the HTTP client sends render requests and decodes render responses.
@Test func httpClientRendersToolOutput() async throws {
    let request = AteliaToolOutputRenderRequest(
        toolResult: AteliaToolResultRef(
            toolResultId: "tool_result_123",
            toolInvocationId: "tool_invocation_123",
            jobId: "job_123",
            repositoryId: "repo_123",
            contentType: "application/json"
        ),
        format: .json
    )

    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/tool-results:render")
        #expect(request.httpMethod == "POST")

        let body = try #require(
            JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
        )
        let toolResult = try #require(body["tool_result"] as? [String: Any])
        #expect(toolResult["tool_result_id"] as? String == "tool_result_123")
        #expect(toolResult["tool_invocation_id"] as? String == "tool_invocation_123")
        #expect(toolResult["job_id"] as? String == "job_123")
        #expect(toolResult["repository_id"] as? String == "repo_123")
        #expect(toolResult["content_type"] as? String == "application/json")
        #expect(body["format"] as? String == "json")

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["tool_output_render.v1"]
            },
            "tool_result": {
              "tool_result_id": "tool_result_123",
              "tool_invocation_id": "tool_invocation_123",
              "job_id": "job_123",
              "repository_id": "repo_123",
              "content_type": "application/json"
            },
            "format": "json",
            "rendered_output": "{\"foo\": \"bar\"}",
            "rendered_output_metadata": {
              "degraded": true,
              "fallback_reason": "render policy compacted output",
              "truncation": {
                "original_bytes": 16,
                "retained_bytes": 8,
                "reason": "runtime truncate_with_metadata"
              }
            }
          }
        }
        """#
    })

    let response = try await client.renderToolOutputResponse(for: AteliaSession(), request: request)

    #expect(response.metadata.capabilities == ["tool_output_render.v1"])
    #expect(response.format == .json)
    #expect(response.toolResult.toolResultId == "tool_result_123")
    #expect(response.renderedOutput == "{\"foo\": \"bar\"}")
    #expect(response.renderedOutputMetadata.degraded == true)
    #expect(response.renderedOutputMetadata.fallbackReason == "render policy compacted output")
    #expect(response.renderedOutputMetadata.truncation?.originalBytes == 16)
    #expect(response.renderedOutputMetadata.truncation?.retainedBytes == 8)
    #expect(response.renderedOutputMetadata.truncation?.reason == "runtime truncate_with_metadata")
}

/// Verifies the HTTP client calls Secretary's beta rollback endpoint with package-named API.
@Test func httpClientRollsBackPackage() async throws {
    let client = HTTPAteliaClient(bearerToken: "token-123", transport: .fixture { request in
        #expect(request.url?.path == "/v1/packages/com.example.review.extension/rollback")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token-123")
        #expect(request.httpBody == Data("{}".utf8))

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["extensions.rollback.v1"]
            },
            "record": {
              "id": "com.example.review.extension",
              "version": "1.0.0",
              "manifest_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
              "artifact_digest": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
              "source": {
                "source": "github",
                "repository": "atelia-labs/atelia",
                "ref": "refs/tags/v1.0.0",
                "manifest_path": "packages/review/package.yml",
                "commit": "deadbeef",
                "registry_identity": "atelia-official"
              },
              "boundary": "official",
              "status": "installed_previous_version",
              "previous_version": "2.0.0",
              "approved_permissions": ["repo.read"],
              "rollback_snapshot": {
                "manifest_digest": "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
                "artifact_digest": "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
              }
            }
          }
        }
        """#
    })

    let response = try await client.packageRollbackResponse(
        for: AteliaSession(),
        packageId: "com.example.review.extension"
    )

    #expect(response.metadata.capabilities == ["extensions.rollback.v1"])
    #expect(response.record.packageId == "com.example.review.extension")
    #expect(response.record.id == "com.example.review.extension")
    #expect(response.record.version == "1.0.0")
    #expect(response.record.status == .installedPreviousVersion)
    #expect(response.record.boundary == .official)
    #expect(response.record.previousVersion == "2.0.0")
    #expect(response.record.approvedPermissions == ["repo.read"])
    #expect(response.record.source.sourceRef == "refs/tags/v1.0.0")
    #expect(response.record.rollbackSnapshot?.manifestDigest == "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc")

    let record = try await client.packageRollback(
        for: AteliaSession(),
        packageId: "com.example.review.extension"
    )
    #expect(record.packageId == "com.example.review.extension")
}

/// Verifies the HTTP client calls POST `/v1/packages/validate` with the beta envelope shape.
@Test func httpClientValidatesPackageManifest() async throws {
    let manifestFixture = try JSONDecoder().decode(
        AteliaPackageManifest.self,
        from: #"""
        {
          "schema": "atelia.extension.v1",
          "id": "com.example.review.extension",
          "name": "Review extension",
          "metadata": {
            "source": "github",
            "publisher": "atelia-labs"
          }
        }
        """#.data(using: .utf8)!
    )
    let validationRequest = AteliaPackageValidationRequest(
        manifest: manifestFixture,
        approveLocalUnsigned: true,
        allowLocalProcessRuntime: true,
        approveSourceChange: false
    )

    let client = HTTPAteliaClient(
        bearerToken: "token-123",
        transport: .fixture { request in
            #expect(request.url?.path == "/v1/packages/validate")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token-123")

            let body = try #require(
                JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
            )
            let manifestObject = try #require(body["manifest"] as? [String: Any])
            #expect(manifestObject["id"] as? String == "com.example.review.extension")
            #expect(manifestObject["name"] as? String == "Review extension")
            #expect(body["approve_local_unsigned"] as? Bool == true)
            #expect(body["allow_local_process_runtime"] as? Bool == true)
            #expect(body["approve_source_change"] as? Bool == false)

            return #"""
            {
              "status": "ok",
              "data": {
                "metadata": {
                  "protocol_version": "1.0.0",
                  "daemon_version": "0.1.0",
                  "storage_version": "0.1.0",
                  "capabilities": ["extensions.validate.v1"]
                },
                "manifest": {
                  "schema": "atelia.extension.v1",
                  "id": "com.example.review.extension",
                  "name": "Review extension",
                  "tools": ["read", "write"],
                  "compatibility": {
                    "protocol": "1.0.0",
                    "capabilities": ["filesystem", "network"]
                  }
                },
                "boundary": "third_party"
              }
            }
            """#
        }
    )

    let response = try await client.packageValidationResponse(
        for: AteliaSession(),
        request: validationRequest
    )
    #expect(response.metadata.capabilities == ["extensions.validate.v1"])
    #expect(response.boundary == .thirdParty)
    #expect(response.manifest["id"] == .string("com.example.review.extension"))
    #expect(response.manifest["tools"] == .array([.string("read"), .string("write")]))

    let validatedManifest = try await client.packageValidation(
        for: AteliaSession(),
        request: validationRequest
    )
    #expect(validatedManifest["name"] == .string("Review extension"))
}

/// Verifies package validation errors are surfaced as typed API errors.
@Test func httpClientSurfacesPackageValidationAPIError() async throws {
    let client = HTTPAteliaClient(transport: .fixture(statusCode: 409) { _ in
        #"""
        {
          "status": "error",
          "error": {
            "code": "invalid_manifest",
            "reason": "manifest is missing required fields",
            "recoverable": false,
            "next_state": "revision_needed"
          }
        }
        """#
    })
    let validationRequest = AteliaPackageValidationRequest(
        manifest: AteliaPackageManifest(fields: ["id": .string("com.example.missing")])
    )

    await #expect(throws: HTTPAteliaClientError.apiError(
        AteliaAPIError(
            code: "invalid_manifest",
            reason: "manifest is missing required fields",
            recoverable: false,
            nextState: "revision_needed"
        )
    )) {
        _ = try await client.packageValidationResponse(
            for: AteliaSession(),
            request: validationRequest
        )
    }
}

/// Verifies package operation paths reject identifiers that Secretary cannot route.
@Test func httpClientRejectsInvalidPackageOperationIds() async throws {
    let client = HTTPAteliaClient(transport: .fixture { _ in
        Issue.record("Invalid package ids should fail before transport.")
        return "{}"
    })

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("")) {
        _ = try await client.packageRollbackResponse(for: AteliaSession(), packageId: "")
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("a/b")) {
        _ = try await client.packageRollbackResponse(for: AteliaSession(), packageId: "a/b")
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("..")) {
        _ = try await client.packageRollbackResponse(for: AteliaSession(), packageId: "..")
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("com.example package")) {
        _ = try await client.packageRollbackResponse(for: AteliaSession(), packageId: "com.example package")
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("..")) {
        _ = try await client.packageStatusResponse(for: AteliaSession(), packageId: "..")
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("a/b")) {
        _ = try await client.packageDisableResponse(for: AteliaSession(), packageId: "a/b")
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("..")) {
        _ = try await client.packageEnableResponse(for: AteliaSession(), packageId: "..")
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("a/b")) {
        _ = try await client.packageRemoveResponse(for: AteliaSession(), packageId: "a/b")
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("a/b")) {
        _ = try await client.packageAuthoringFlowResponse(
            for: AteliaSession(),
            request: AteliaPackageAuthoringFlowRequest(packageId: "a/b")
        )
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("..")) {
        _ = try await client.packageRemixResponse(
            for: AteliaSession(),
            request: AteliaPackageRemixRequest(
                packageId: "..",
                sourceClass: .workspaceLocal
            )
        )
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId(" ")) {
        _ = try await client.packagePublicationResponse(
            for: AteliaSession(),
            request: AteliaPackagePublicationRequest(
                packageId: " ",
                sourceClass: .workspaceLocal,
                visibility: .publicSearchable,
                requiresRegistrySubmission: false,
                productionInstallable: false
            )
        )
    }

    await #expect(throws: HTTPAteliaClientError.invalidPackageId("a/b")) {
        _ = try await client.packageRegistrySubmissionResponse(
            for: AteliaSession(),
            request: AteliaPackageRegistrySubmissionRequest(
                packageId: "a/b",
                state: .submitted
            )
        )
    }
}

/// Verifies the HTTP client fetches compact project status snapshots.
@Test func httpClientFetchesProjectStatus() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/project-status:get")
        #expect(request.httpMethod == "POST")

        let body = try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
        #expect(body?["repository_id"] as? String == "repo_123")

        return #"""
        {
          "status": "ok",
          "data": {
            "metadata": {
              "protocol_version": "1.0.0",
              "daemon_version": "0.1.0",
              "storage_version": "0.1.0",
              "capabilities": ["project_status.v1"]
            },
            "repository": {
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
            },
            "recent_jobs": [],
            "recent_policy_decisions": [],
            "latest_cursor": {
              "sequence": 7,
              "event_id": "evt_7"
            },
            "daemon_status": "running",
            "storage_status": "ready"
          }
        }
        """#
    })

    let status = try await client.projectStatus(
        for: AteliaSession(),
        repositoryId: "repo_123"
    )

    #expect(status.repository.repositoryId == "repo_123")
    #expect(status.latestCursor?.eventId == "evt_7")
    #expect(status.daemonStatus == .running)
    #expect(status.storageStatus == .ready)
}

/// Verifies structured API error envelopes surface as typed client errors.
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

/// Verifies structured API errors preserve retry and audit recovery fields.
@Test func httpClientPreservesErrorRecoveryFields() async throws {
    let client = HTTPAteliaClient(transport: .fixture(statusCode: 429) { _ in
        #"""
        {
          "status": "error",
          "error": {
            "code": "rate_limited",
            "reason": "retry after daemon cooldown",
            "recoverable": true,
            "next_state": "retry_same_request",
            "retry_after": 2.5,
            "audit_ref": "aud_123"
          }
        }
        """#
    })

    await #expect(throws: HTTPAteliaClientError.apiError(
        AteliaAPIError(
            code: "rate_limited",
            reason: "retry after daemon cooldown",
            recoverable: true,
            nextState: "retry_same_request",
            retryAfter: .seconds(2.5),
            auditRef: "aud_123"
        )
    )) {
        _ = try await client.health(for: AteliaSession())
    }
}

/// Verifies non-JSON HTTP errors preserve a fallback textual reason.
@Test func httpClientSurfacesNonJSONHTTPErrorBody() async throws {
    let client = HTTPAteliaClient(transport: .fixture(statusCode: 502) { _ in
        "<html>bad gateway</html>"
    })

    await #expect(throws: HTTPAteliaClientError.unsuccessfulStatus(
        code: 502,
        reason: "<html>bad gateway</html>"
    )) {
        _ = try await client.health(for: AteliaSession())
    }
}

/// Fixture helpers for replacing HTTP transport calls in tests.
private extension AteliaHTTPTransport {
    /// Creates a transport that returns a fixture HTTP response.
    static func fixture(
        statusCode: Int = 200,
        respond: @escaping @Sendable (URLRequest) async throws -> String
    ) -> Self {
        Self { request in
            let body = try await respond(request)
            guard let url = request.url else {
                throw FixtureError.missingRequestURL
            }
            guard let data = body.data(using: .utf8) else {
                throw FixtureError.responseBodyEncodingFailed
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
            guard let response else {
                throw FixtureError.responseConstructionFailed(statusCode: statusCode)
            }
            return (data, response)
        }
    }
}

/// Errors produced by HTTP test fixtures.
private enum FixtureError: Error, Equatable {
    /// The request did not include a URL.
    case missingRequestURL
    /// The string fixture could not be encoded as UTF-8 data.
    case responseBodyEncodingFailed
    /// Foundation could not build the HTTP response fixture.
    case responseConstructionFailed(statusCode: Int)
}

/// Builds a compact package lifecycle record response.
private func lifecycleRecordResponse(capability: String, status: String) -> String {
    #"""
    {
      "status": "ok",
      "data": {
        "metadata": {
          "protocol_version": "1.0.0",
          "daemon_version": "0.1.0",
          "storage_version": "0.1.0",
          "capabilities": ["\#(capability)"]
        },
        "record": {
          "id": "com.example.review.extension",
          "version": "1.0.0",
          "manifest_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          "artifact_digest": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
          "source": {
            "source": "github",
            "repository": "atelia-labs/atelia",
            "ref": "refs/tags/v1.0.0"
          },
          "boundary": "official",
          "status": "\#(status)",
          "approved_permissions": ["repo.read"]
        }
      }
    }
    """#
}

/// Records repository pagination requests and returns fixture pages.
private actor RepositoryPageRecorder {
    /// Page tokens observed in request bodies.
    private(set) var pageTokens: [String?] = []

    /// Returns a repository list fixture for the request page token.
    func response(for request: URLRequest) throws -> String {
        let pageToken = try pageToken(from: request)
        pageTokens.append(pageToken)

        switch pageToken {
        case nil:
            return Self.repositoryResponse(id: "repo_1", nextPageToken: "page-2")
        case "page-2":
            return Self.repositoryResponse(id: "repo_2", nextPageToken: nil)
        default:
            Issue.record("Unexpected page token: \(String(describing: pageToken))")
            return Self.repositoryResponse(id: "repo_unexpected", nextPageToken: nil)
        }
    }

    /// Extracts the optional page token from a JSON request body.
    private func pageToken(from request: URLRequest) throws -> String? {
        guard let body = request.httpBody, !body.isEmpty else {
            return nil
        }

        let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        return object?["page_token"] as? String
    }

    /// Builds a repository list response fixture.
    static func repositoryResponse(id: String, nextPageToken: String?) -> String {
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
