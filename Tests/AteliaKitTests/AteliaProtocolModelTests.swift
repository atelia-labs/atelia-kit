import Foundation
import Testing
@testable import AteliaKit

/// Verifies repository JSON decodes from canonical protocol keys.
@Test func repositoryDecodesCanonicalSnakeCaseProtocolJSON() throws {
    let data = #"""
    {
      "repository_id": "repo_123",
      "display_name": "Atelia Kit",
      "root_path": "/workspace/atelia-kit",
      "allowed_scope": {
        "kind": "repository",
        "roots": ["/workspace/atelia-kit"],
        "include_patterns": ["Sources/**"],
        "exclude_patterns": [".build/**"]
      },
      "trust_state": "trusted",
      "created_at_unix_ms": 1710000000000,
      "updated_at_unix_ms": 1710000100000
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaRepository.self, from: data)

    #expect(decoded.repositoryId == "repo_123")
    #expect(decoded.allowedScope.kind == .repository)
    #expect(decoded.trustState == .trusted)
    #expect(decoded.allowedScope.excludePatterns == [".build/**"])
}

/// Verifies project-status models retain unknown enum wire values.
@Test func protocolModelsPreserveUnknownEnumValues() throws {
    let data = #"""
    {
      "metadata": {
        "protocol_version": "1.1.0",
        "daemon_version": "0.2.0",
        "storage_version": "0.2.0",
        "capabilities": ["project_status.v1"]
      },
      "repository": {
        "repository_id": "repo_123",
        "display_name": "Atelia Kit",
        "root_path": "/workspace/atelia-kit",
        "allowed_scope": {
          "kind": "workspace_overlay",
          "roots": ["/workspace/atelia-kit"],
          "include_patterns": [],
          "exclude_patterns": []
        },
        "trust_state": "quarantined",
        "created_at_unix_ms": 1710000000000,
        "updated_at_unix_ms": 1710000100000
      },
      "recent_jobs": [
        {
          "job_id": "job_123",
          "repository_id": "repo_123",
          "requester": {
            "type": "automation",
            "id": "automation_secretary",
            "display_name": "Secretary Automation"
          },
          "kind": "tool",
          "goal": "Read package manifest",
          "status": "paused",
          "policy_summary": null,
          "created_at_unix_ms": 1710000000000,
          "started_at_unix_ms": null,
          "completed_at_unix_ms": null,
          "latest_event_id": null,
          "cancellation": {
            "state": "none",
            "requested_by": null,
            "reason": null,
            "requested_at_unix_ms": null,
            "completed_at_unix_ms": null
          }
        }
      ],
      "recent_policy_decisions": [
        {
          "decision_id": "pol_123",
          "outcome": "deferred",
          "risk_tier": "R5",
          "requested_capability": "filesystem.write",
          "reason_code": "new_policy",
          "reason": "New daemon policy",
          "approval_request_ref": null,
          "audit_ref": null
        }
      ],
      "latest_cursor": null,
      "daemon_status": "warming",
      "storage_status": "repairing"
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaProjectStatus.self, from: data)

    #expect(decoded.repository.trustState == .unknown("quarantined"))
    #expect(decoded.repository.allowedScope.kind == .unknown("workspace_overlay"))
    #expect(decoded.recentJobs[0].requester == .unknown(
        rawValue: "automation",
        id: "automation_secretary",
        displayName: "Secretary Automation"
    ))
    #expect(decoded.recentJobs[0].status == .unrecognized("paused"))
    #expect(decoded.recentPolicyDecisions[0].outcome == .unknown("deferred"))
    #expect(decoded.recentPolicyDecisions[0].riskTier == .unknown("R5"))
    #expect(decoded.daemonStatus == .unknown("warming"))
    #expect(decoded.storageStatus == .unknown("repairing"))

    let encoded = try JSONEncoder().encode(decoded)
    let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    let repository = try #require(object["repository"] as? [String: Any])
    let allowedScope = try #require(repository["allowed_scope"] as? [String: Any])
    let jobs = try #require(object["recent_jobs"] as? [[String: Any]])
    let policies = try #require(object["recent_policy_decisions"] as? [[String: Any]])

    #expect(repository["trust_state"] as? String == "quarantined")
    #expect(allowedScope["kind"] as? String == "workspace_overlay")
    let requester = try #require(jobs[0]["requester"] as? [String: Any])
    #expect(requester["type"] as? String == "automation")
    #expect(requester["id"] as? String == "automation_secretary")
    #expect(requester["display_name"] as? String == "Secretary Automation")
    #expect(jobs[0]["status"] as? String == "paused")
    #expect(policies[0]["outcome"] as? String == "deferred")
    #expect(policies[0]["risk_tier"] as? String == "R5")
    #expect(object["daemon_status"] as? String == "warming")
    #expect(object["storage_status"] as? String == "repairing")
}

/// Verifies job, policy, and actor models round-trip through Codable.
@Test func jobPolicyAndActorRoundTrip() throws {
    let job = AteliaJob(
        jobId: "job_123",
        repositoryId: "repo_123",
        requester: .agent(id: "agent_secretary", displayName: "Secretary"),
        kind: "tool",
        goal: "Read package manifest",
        status: .running,
        policySummary: AteliaPolicySummary(
            decisionId: "pol_123",
            outcome: .audited,
            riskTier: .r1,
            reasonCode: "bounded_read"
        ),
        createdAtUnixMilliseconds: 1710000000000,
        startedAtUnixMilliseconds: 1710000001000,
        latestEventId: "evt_123",
        cancellation: AteliaJobCancellation(state: "none")
    )

    let data = try JSONEncoder().encode(job)
    let decoded = try JSONDecoder().decode(AteliaJob.self, from: data)

    #expect(decoded == job)
}

/// Verifies job decoding keeps cancellation optional for older payloads.
@Test func jobDecodesWhenCancellationIsOmitted() throws {
    let data = #"""
    {
      "job_id": "job_123",
      "repository_id": "repo_123",
      "requester": {
        "type": "agent",
        "id": "agent_secretary",
        "display_name": "Secretary"
      },
      "kind": "tool",
      "goal": "Read package manifest",
      "status": "queued",
      "policy_summary": {
        "decision_id": "pol_123",
        "outcome": "audited",
        "risk_tier": "R1",
        "reason_code": "bounded_read"
      },
      "created_at_unix_ms": 1710000000000,
      "started_at_unix_ms": null,
      "completed_at_unix_ms": null,
      "latest_event_id": null
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaJob.self, from: data)

    #expect(decoded.cancellation == nil)
    #expect(decoded.policySummary?.outcome == .audited)
    #expect(decoded.policySummary?.riskTier == .r1)
}

/// Verifies policy decisions decode approval and audit references.
@Test func policyDecisionDecodesApprovalAndAuditRefs() throws {
    let data = #"""
    {
      "decision_id": "pol_123",
      "outcome": "needs_approval",
      "risk_tier": "R3",
      "requested_capability": "filesystem.write",
      "reason_code": "approval_required",
      "reason": "Writes require approval",
      "approval_request_ref": "approval_123",
      "audit_ref": "aud_123"
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPolicyDecision.self, from: data)

    #expect(decoded.outcome == .needsApproval)
    #expect(decoded.riskTier == .r3)
    #expect(decoded.auditRef == "aud_123")
}

/// Verifies canonical project status JSON decodes from protocol keys.
@Test func projectStatusDecodesCanonicalProtocolJSON() throws {
    let data = #"""
    {
      "metadata": {
        "protocol_version": "1.0.0",
        "daemon_version": "0.1.0",
        "storage_version": "0.1.0",
        "capabilities": ["health.v1", "project_status.v1"]
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
        "sequence": 42,
        "event_id": "evt_42"
      },
      "daemon_status": "running",
      "storage_status": "ready"
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaProjectStatus.self, from: data)

    #expect(decoded.metadata.protocolVersion == "1.0.0")
    #expect(decoded.repository.repositoryId == "repo_123")
    #expect(decoded.latestCursor?.sequence == 42)
    #expect(decoded.daemonStatus == .running)
}

/// Verifies canonical package trust index JSON decodes into shared client models.
@Test func packageTrustIndexDecodesCanonicalProtocolJSON() throws {
    let data = #"""
    {
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
            },
            "lineage": {
              "parent_id": "com.example.parent",
              "parent_version": "1.0.0",
              "parent_manifest_digest": "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
              "relationship": "fork"
            }
          },
          "approved_permissions": ["repo.read"],
          "rollback_snapshot": {
            "manifest_digest": "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
            "artifact_digest": "sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
          }
        }
      ]
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPackageTrustIndexResponse.self, from: data)

    #expect(decoded.metadata.capabilities == ["package_trust_index.v1"])
    #expect(decoded.packages.count == 1)
    let entry = try #require(decoded.packages.first)
    #expect(entry.packageId == "com.example.active")
    #expect(entry.status == .installed)
    #expect(entry.boundary == .official)
    #expect(entry.source?.source == "github")
    #expect(entry.source?.publication?.visibility == .publicSearchable)
    #expect(entry.source?.publication?.registrySubmission == .accepted)
    #expect(entry.source?.lineage?.relationship == .fork)
}

/// Verifies package trust index entries derive typed inspection attention from status and block data.
@Test func packageTrustIndexAttentionProjectionMapsStatusBlockAndUnknownValues() {
    let installed = AteliaPackageTrustIndexEntry(
        packageId: "com.example.active",
        status: .installed
    )
    let disabled = AteliaPackageTrustIndexEntry(
        packageId: "com.example.disabled",
        status: .disabled
    )
    let blocked = AteliaPackageTrustIndexEntry(
        packageId: "com.example.blocked",
        status: .blocked,
        block: .init(reason: .policyViolation, key: .extensionId("com.example.blocked"))
    )
    let blockedWithoutReason = AteliaPackageTrustIndexEntry(
        packageId: "com.example.blocked.untyped",
        status: .blocked
    )
    let updating = AteliaPackageTrustIndexEntry(
        packageId: "com.example.updating",
        status: .updating
    )
    let rollingBack = AteliaPackageTrustIndexEntry(
        packageId: "com.example.rollback",
        status: .rollbackInProgress
    )
    let previousVersion = AteliaPackageTrustIndexEntry(
        packageId: "com.example.previous",
        status: .installedPreviousVersion
    )
    let future = AteliaPackageTrustIndexEntry(
        packageId: "com.example.future",
        status: .unknown("quarantined")
    )

    #expect(installed.attentionState == .clear)
    #expect(installed.attentionReason == nil)
    #expect(installed.requiresAttention == false)
    #expect(disabled.attentionState == .attentionNeeded(reason: .disabled))
    #expect(blocked.attentionState == .attentionNeeded(reason: .blockReason(.policyViolation)))
    #expect(blocked.attentionReason == .blockReason(.policyViolation))
    #expect(blocked.requiresAttention == true)
    #expect(blockedWithoutReason.attentionState == .attentionNeeded(reason: .blocked))
    #expect(updating.attentionState == .attentionNeeded(reason: .updating))
    #expect(rollingBack.attentionState == .attentionNeeded(reason: .rollbackInProgress))
    #expect(previousVersion.attentionState == .attentionNeeded(reason: .installedPreviousVersion))
    #expect(future.attentionState == .attentionNeeded(reason: .unknownStatus("quarantined")))
    #expect(future.attentionReason == .unknownStatus("quarantined"))
    #expect(future.requiresAttention == true)
}

/// Verifies package manifests preserve arbitrary JSON shapes through decoding and encoding.
@Test func packageManifestPreservesArbitraryJSONShape() throws {
    let manifestData = #"""
    {
      "schema": "atelia.extension.v1",
      "id": "com.example.review.extension",
      "name": "Review extension",
      "tools": ["read", "write"],
      "compatibility": {
        "protocol": "1.0.0",
        "permissions": {
          "filesystem": ["read", "write"]
        },
        "supports_local": true
      },
      "version": 3
    }
    """#.data(using: .utf8)!

    let manifest = try JSONDecoder().decode(AteliaPackageManifest.self, from: manifestData)
    let encoded = try JSONEncoder().encode(manifest)
    let decoded = try JSONDecoder().decode(AteliaPackageManifest.self, from: encoded)

    #expect(decoded["schema"] == .string("atelia.extension.v1"))
    #expect(decoded["id"] == .string("com.example.review.extension"))
    #expect(decoded["tools"] == .array([.string("read"), .string("write")]))
    #expect(decoded["compatibility"] == .object([
        "protocol": .string("1.0.0"),
        "permissions": .object([
            "filesystem": .array([.string("read"), .string("write")])
        ]),
        "supports_local": .bool(true)
    ]))
    #expect(decoded["version"] == .number(Decimal(3)))
    #expect(decoded == manifest)
}

/// Verifies package manifest numbers decode through Decimal without binary floating-point rounding.
@Test func packageManifestPreservesDecimalNumberPrecision() throws {
    let manifestData = #"""
    {
      "precise": 1.234567890123456789,
      "integer": 1234567890123456789
    }
    """#.data(using: .utf8)!

    let manifest = try JSONDecoder().decode(AteliaPackageManifest.self, from: manifestData)

    #expect(manifest["precise"] == .number(Decimal(string: "1.234567890123456789")!))
    #expect(manifest["integer"] == .number(Decimal(string: "1234567890123456789")!))
}

/// Verifies package validation request decoding uses canonical snake_case request keys.
@Test func packageValidationRequestDecodesCanonicalSnakeCaseProtocolJSON() throws {
    let data = #"""
    {
      "manifest": {
        "schema": "atelia.extension.v1",
        "id": "com.example.review.extension",
        "name": "Review extension"
      },
      "approve_local_unsigned": true,
      "allow_local_process_runtime": false,
      "approve_source_change": true
    }
    """#.data(using: .utf8)!

    let request = try JSONDecoder().decode(AteliaPackageValidationRequest.self, from: data)

    #expect(request.manifest["schema"] == .string("atelia.extension.v1"))
    #expect(request.manifest["name"] == .string("Review extension"))
    #expect(request.approveLocalUnsigned == true)
    #expect(request.allowLocalProcessRuntime == false)
    #expect(request.approveSourceChange == true)
}

/// Verifies omitted package validation flags follow Secretary's default-false contract.
@Test func packageValidationRequestDefaultsOmittedFlagsToFalse() throws {
    let data = #"""
    {
      "manifest": {
        "schema": "atelia.extension.v1",
        "id": "com.example.review.extension",
        "name": "Review extension"
      }
    }
    """#.data(using: .utf8)!

    let request = try JSONDecoder().decode(AteliaPackageValidationRequest.self, from: data)

    #expect(request.manifest["id"] == .string("com.example.review.extension"))
    #expect(request.approveLocalUnsigned == false)
    #expect(request.allowLocalProcessRuntime == false)
    #expect(request.approveSourceChange == false)
}

/// Verifies explicit null validation flags are rejected like Secretary's serde bool fields.
@Test func packageValidationRequestRejectsNullFlags() {
    let data = #"""
    {
      "manifest": {
        "schema": "atelia.extension.v1",
        "id": "com.example.review.extension"
      },
      "approve_local_unsigned": null
    }
    """#.data(using: .utf8)!

    #expect(throws: DecodingError.self) {
        _ = try JSONDecoder().decode(AteliaPackageValidationRequest.self, from: data)
    }
}

/// Verifies package validation response decoding preserves metadata, manifest, and boundary.
@Test func packageValidationResponseDecodesCanonicalProtocolJSON() throws {
    let data = #"""
    {
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
        "source": "github"
      },
      "boundary": "third_party"
    }
    """#.data(using: .utf8)!

    let response = try JSONDecoder().decode(AteliaPackageValidationResponse.self, from: data)

    #expect(response.metadata.protocolVersion == "1.0.0")
    #expect(response.metadata.capabilities == ["extensions.validate.v1"])
    #expect(response.manifest["id"] == .string("com.example.review.extension"))
    #expect(response.boundary == .thirdParty)
}

/// Verifies package validation boundary preserves unknown values for forward compatibility.
@Test func packageValidationResponsePreservesUnknownBoundaryValues() throws {
    let data = #"""
    {
      "metadata": {
        "protocol_version": "1.0.0",
        "daemon_version": "0.1.0",
        "storage_version": "0.1.0",
        "capabilities": ["extensions.validate.v1"]
      },
      "manifest": {
        "schema": "atelia.extension.v1",
        "id": "com.example.review.extension",
        "name": "Review extension"
      },
      "boundary": "experimental_shadow"
    }
    """#.data(using: .utf8)!

    let response = try JSONDecoder().decode(AteliaPackageValidationResponse.self, from: data)

    #expect(response.boundary == .unknown("experimental_shadow"))
}

/// Verifies review queue items remain platform-neutral and Codable.
@Test func reviewQueueItemIsPlatformNeutralAndCodable() throws {
    let data = #"""
    {
      "id": "review_123",
      "kind": "approval",
      "title": "Approve filesystem write",
      "repository_id": "repo_123",
      "job_id": "job_123",
      "policy_decision_id": "pol_123",
      "priority": 2
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaReviewQueueItem.self, from: data)
    let encoded = try JSONEncoder().encode(decoded)
    let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

    #expect(decoded.repositoryId == "repo_123")
    #expect(decoded.jobId == "job_123")
    #expect(decoded.policyDecisionId == "pol_123")
    #expect(object["repository_id"] as? String == "repo_123")
    #expect(object["job_id"] as? String == "job_123")
    #expect(object["policy_decision_id"] as? String == "pol_123")
}

/// Verifies approval and review queue enums preserve unknown values.
@Test func approvalAndReviewQueueEnumsPreserveUnknownValues() throws {
    let approvalData = #"""
    {
      "id": "approval_123",
      "status": "escalated",
      "policy_decision_id": "pol_123",
      "requested_by": {
        "type": "user",
        "id": "user_123",
        "display_name": "Approver"
      },
      "reason": null
    }
    """#.data(using: .utf8)!
    let reviewData = #"""
    {
      "id": "review_123",
      "kind": "handoff",
      "title": "Human handoff",
      "repository_id": null,
      "job_id": null,
      "policy_decision_id": null,
      "priority": 1
    }
    """#.data(using: .utf8)!

    let approval = try JSONDecoder().decode(AteliaApprovalState.self, from: approvalData)
    let review = try JSONDecoder().decode(AteliaReviewQueueItem.self, from: reviewData)
    let encodedApproval = try JSONEncoder().encode(approval)
    let approvalObject = try #require(JSONSerialization.jsonObject(with: encodedApproval) as? [String: Any])

    #expect(approval.status == .unknown("escalated"))
    #expect(approval.policyDecisionId == "pol_123")
    #expect(approval.requestedBy == .user(id: "user_123", displayName: "Approver"))
    #expect(approvalObject["policy_decision_id"] as? String == "pol_123")
    #expect(approvalObject["requested_by"] != nil)
    #expect(review.kind == .unknown("handoff"))
}

/// Verifies approval-state contract keys remain stable for PDH-126 smoke checks.
@Test func approvalStatePreservesCanonicalContractKeys() throws {
    let data = #"""
    {
      "id": "approval_123",
      "status": "approved",
      "policy_decision_id": "pol_123",
      "requested_by": {
        "type": "user",
        "id": "user_123",
        "display_name": "Approver"
      },
      "reason": "Policy review complete"
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaApprovalState.self, from: data)
    let encoded = try JSONEncoder().encode(decoded)
    let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

    #expect(decoded.id == "approval_123")
    #expect(decoded.status == .approved)
    #expect(decoded.policyDecisionId == "pol_123")
    #expect(decoded.reason == "Policy review complete")
    #expect(object["id"] as? String == "approval_123")
    #expect(object["status"] as? String == "approved")
    #expect(object["policy_decision_id"] as? String == "pol_123")
    #expect(object["reason"] as? String == "Policy review complete")
    #expect((object["requested_by"] as? [String: Any]) != nil)
}

/// Verifies audit references still use protocol snake_case keys for transport smoke checks.
@Test func auditReferencePreservesCanonicalContractKeys() throws {
    let data = #"""
    {
      "id": "audit_123",
      "repository_id": "repo_123",
      "job_id": "job_123",
      "policy_decision_id": "pol_123",
      "message": "Policy decision reviewed"
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaAuditReference.self, from: data)
    let encoded = try JSONEncoder().encode(decoded)
    let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

    #expect(decoded.id == "audit_123")
    #expect(decoded.repositoryId == "repo_123")
    #expect(decoded.jobId == "job_123")
    #expect(decoded.policyDecisionId == "pol_123")
    #expect(decoded.message == "Policy decision reviewed")
    #expect(object["id"] as? String == "audit_123")
    #expect(object["repository_id"] as? String == "repo_123")
    #expect(object["job_id"] as? String == "job_123")
    #expect(object["policy_decision_id"] as? String == "pol_123")
    #expect(object["message"] as? String == "Policy decision reviewed")
}

/// Verifies review queue item contract keys remain aligned with shared models.
@Test func reviewQueueItemPreservesCanonicalContractKeys() throws {
    let data = #"""
    {
      "id": "review_456",
      "kind": "audit",
      "title": "Audit review needed",
      "repository_id": "repo_123",
      "job_id": "job_123",
      "policy_decision_id": "pol_456",
      "priority": 3
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaReviewQueueItem.self, from: data)
    let encoded = try JSONEncoder().encode(decoded)
    let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

    #expect(decoded.id == "review_456")
    #expect(decoded.kind == .audit)
    #expect(decoded.title == "Audit review needed")
    #expect(decoded.repositoryId == "repo_123")
    #expect(decoded.jobId == "job_123")
    #expect(decoded.policyDecisionId == "pol_456")
    #expect(decoded.priority == 3)
    #expect(object["id"] as? String == "review_456")
    #expect(object["kind"] as? String == "audit")
    #expect(object["policy_decision_id"] as? String == "pol_456")
    #expect(object["priority"] as? Int == 3)
}

/// Verifies unknown trust-index enum values remain available to clients.
@Test func packageTrustIndexEnumsPreserveUnknownValues() throws {
    let data = #"""
    {
      "metadata": {
        "protocol_version": "1.0.0",
        "daemon_version": "0.1.0",
        "storage_version": "0.1.0",
        "capabilities": ["package_trust_index.v1"]
      },
      "packages": [
        {
          "package_id": "com.example.blocked",
          "version": "9.9.9",
          "status": "quarantined",
          "boundary": "partner_lab",
          "manifest_digest": "sha256:1111111111111111111111111111111111111111111111111111111111111111",
          "artifact_digest": "sha256:2222222222222222222222222222222222222222222222222222222222222222",
          "source": {
            "source": "registry",
            "repository": "example.registry/package",
            "ref": "main",
            "manifest_path": "manifest.yml",
            "commit": "abc123",
            "registry_identity": "example-registry",
            "publication": {
              "visibility": "public_only",
              "registry_submission": "queued"
            },
            "lineage": {
              "parent_id": "com.example.parent",
              "parent_version": null,
              "parent_manifest_digest": null,
              "relationship": "transplanted"
            }
          },
          "block": {
            "reason": "supply_chain_compromise",
            "key": {
              "extension_id": "com.example.blocked"
            }
          }
        }
      ]
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPackageTrustIndexResponse.self, from: data)
    let entry = try #require(decoded.packages.first)

    #expect(entry.status == .unknown("quarantined"))
    #expect(entry.boundary == .unknown("partner_lab"))
    #expect(entry.source?.publication?.visibility == .unknown("public_only"))
    #expect(entry.source?.publication?.registrySubmission == .unknown("queued"))
    #expect(entry.source?.lineage?.relationship == .unknown("transplanted"))
    #expect(entry.block?.reason == .unknown("supply_chain_compromise"))
    #expect(entry.block?.key == .extensionId("com.example.blocked"))
}

/// Verifies malformed block keys fail instead of decoding arbitrary data.
@Test func packageTrustIndexBlockKeyRejectsAmbiguousPayloads() throws {
    let data = #"""
    {
      "extension_id": "com.example.blocked",
      "artifact_digest": "sha256:2222222222222222222222222222222222222222222222222222222222222222"
    }
    """#.data(using: .utf8)!

    #expect(throws: DecodingError.self) {
        _ = try JSONDecoder().decode(AteliaPackageTrustIndexEntry.Block.Key.self, from: data)
    }
}

/// Verifies unknown block keys are not re-encoded without their raw payload.
@Test func packageTrustIndexUnknownBlockKeyDoesNotEncodeWithoutRawPayload() throws {
    let key = AteliaPackageTrustIndexEntry.Block.Key.unknown(name: "future_key")

    #expect(throws: EncodingError.self) {
        _ = try JSONEncoder().encode(key)
    }
}

/// Verifies client identity and audit references use protocol snake_case keys.
@Test func clientIdentityAndAuditReferencesUseProtocolSnakeCaseKeys() throws {
    let identityData = #"""
    {
      "id": "project_123",
      "display_name": "Atelia Project",
      "repository_id": "repo_123"
    }
    """#.data(using: .utf8)!
    let threadData = #"""
    {
      "id": "thread_123",
      "project_id": "project_123",
      "title": "Review protocol"
    }
    """#.data(using: .utf8)!
    let auditData = #"""
    {
      "id": "audit_123",
      "repository_id": "repo_123",
      "job_id": "job_123",
      "policy_decision_id": "pol_123",
      "message": "Recorded policy decision"
    }
    """#.data(using: .utf8)!

    let identity = try JSONDecoder().decode(AteliaProjectIdentity.self, from: identityData)
    let thread = try JSONDecoder().decode(AteliaThreadIdentity.self, from: threadData)
    let audit = try JSONDecoder().decode(AteliaAuditReference.self, from: auditData)
    let encodedIdentity = try JSONEncoder().encode(identity)
    let encodedThread = try JSONEncoder().encode(thread)
    let encodedAudit = try JSONEncoder().encode(audit)
    let identityObject = try #require(JSONSerialization.jsonObject(with: encodedIdentity) as? [String: Any])
    let threadObject = try #require(JSONSerialization.jsonObject(with: encodedThread) as? [String: Any])
    let auditObject = try #require(JSONSerialization.jsonObject(with: encodedAudit) as? [String: Any])

    #expect(identity.displayName == "Atelia Project")
    #expect(identity.repositoryId == "repo_123")
    #expect(thread.projectId == "project_123")
    #expect(audit.repositoryId == "repo_123")
    #expect(audit.jobId == "job_123")
    #expect(audit.policyDecisionId == "pol_123")
    #expect(identityObject["display_name"] as? String == "Atelia Project")
    #expect(identityObject["repository_id"] as? String == "repo_123")
    #expect(threadObject["project_id"] as? String == "project_123")
    #expect(auditObject["repository_id"] as? String == "repo_123")
    #expect(auditObject["job_id"] as? String == "job_123")
    #expect(auditObject["policy_decision_id"] as? String == "pol_123")
}

/// Verifies beta tool repertoire JSON decodes from protocol keys.
@Test func toolRepertoireDecodesBetaProjection() throws {
    let data = #"""
    {
      "tool_id": "fs.read",
      "name": "Filesystem Read",
      "description": "Read a file from an allowed repository scope.",
      "provider_kind": "builtin",
      "provider_id": "atelia-secretary",
      "risk_tier": "R1",
      "default_result_format": "toon",
      "supported_result_formats": ["toon", "json"],
      "idempotency": "idempotent",
      "cancellable": false,
      "streaming": false,
      "timeout_ms": 0
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaToolRepertoireEntry.self, from: data)

    #expect(decoded.id == "fs.read")
    #expect(decoded.supportedResultFormats == ["toon", "json"])
}
