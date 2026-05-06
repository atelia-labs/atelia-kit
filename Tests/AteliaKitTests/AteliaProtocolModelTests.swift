import Foundation
import Testing
@testable import AteliaKit

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
            outcome: "audited",
            riskTier: "R1",
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

@Test func reviewQueueItemIsPlatformNeutralAndCodable() throws {
    let item = AteliaReviewQueueItem(
        id: "review_123",
        kind: .approval,
        title: "Approve filesystem write",
        repositoryId: "repo_123",
        jobId: "job_123",
        policyDecisionId: "pol_123",
        priority: 2
    )

    let data = try JSONEncoder().encode(item)
    let decoded = try JSONDecoder().decode(AteliaReviewQueueItem.self, from: data)

    #expect(decoded == item)
}

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
