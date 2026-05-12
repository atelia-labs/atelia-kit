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

/// Verifies package install requests hit the extension install route and decode the lifecycle envelope.
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
            #expect(request.url?.path == "/v1/extensions/install")
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

/// Verifies package updates hit the extension update route and decode the lifecycle envelope.
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
        #expect(request.url?.path == "/v1/extensions/update")
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

/// Verifies package status checks the extension status endpoint and decodes extension naming.
@Test func httpClientGetsPackageStatus() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/extensions/com.example.review.extension/status")
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

/// Verifies package list calls the extensions list endpoint with list filters.
@Test func httpClientListsPackages() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/extensions/list")
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
        #expect(request.url?.path == "/v1/extensions/com.example.review.extension/disable")
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
        #expect(request.url?.path == "/v1/extensions/com.example.review.extension/enable")
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

/// Verifies package removals use the identifier-scoped remove endpoint.
@Test func httpClientRemovesPackage() async throws {
    let client = HTTPAteliaClient(transport: .fixture { request in
        #expect(request.url?.path == "/v1/extensions/com.example.review.extension/remove")
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
            #expect(request.url?.path == "/v1/extensions/blocklist/apply")
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
        #expect(request.url?.path == "/v1/extensions/blocklist/list")
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
        #expect(request.url?.path == "/v1/extensions/com.example.review.extension/rollback")
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

/// Verifies the HTTP client calls POST `/v1/extensions/validate` with the beta envelope shape.
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
            #expect(request.url?.path == "/v1/extensions/validate")
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
