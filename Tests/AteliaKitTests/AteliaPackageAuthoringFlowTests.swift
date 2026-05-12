import Foundation
import Testing
@testable import AteliaKit

/// Verifies package authoring flow models decode canonical snake_case keys.
@Test func packageAuthoringFlowDecodesCanonicalKeys() throws {
    let data = #"""
    {
      "package_id": "com.example.review",
      "source_class": "workspace-local",
      "source": {
        "repository": "atelia-labs/atelia-official-packages",
        "ref": "refs/heads/remix",
        "manifest_path": "packages/review/aep.yaml",
        "manifest_digest": "sha256:aaaaaaaa",
        "artifact_digests": ["sha256:bbbbbbbb"]
      },
      "steps": [
        {
          "id": "inspect",
          "title": "Inspect package",
          "state": "complete",
          "requires_explicit_consent": false,
          "policy_notes": []
        },
        {
          "id": "validate",
          "title": "Validate remix",
          "state": "requires_validation",
          "requires_explicit_consent": true,
          "policy_notes": ["Permission diff requires approval"]
        }
      ],
      "publication_plan": {
        "visibility": "private_remix",
        "source_class": "workspace-local",
        "source": {
          "repository": "atelia-labs/atelia-official-packages",
          "ref": "refs/heads/remix",
          "manifest_path": "packages/review/aep.yaml",
          "manifest_digest": "sha256:aaaaaaaa",
          "artifact_digests": ["sha256:bbbbbbbb"]
        },
        "github_actions": ["fork_repository", "create_branch", "commit_changes", "open_pull_request"],
        "requires_registry_submission": false,
        "production_installable": false
      }
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPackageAuthoringFlow.self, from: data)

    #expect(decoded.id == "com.example.review")
    #expect(decoded.sourceClass == .workspaceLocal)
    #expect(decoded.source?.manifestPath == "packages/review/aep.yaml")
    #expect(decoded.steps.map(\.id) == [.inspect, .validate])
    #expect(decoded.stepsRequiringConsent.map(\.id) == [.validate])
    #expect(decoded.publicationPlan?.visibility == .privateRemix)
    #expect(decoded.publicationPlan?.githubActions == [
        .forkRepository,
        .createBranch,
        .commitChanges,
        .openPullRequest
    ])
}

/// Verifies authoring flow models encode the client contract keys.
@Test func packageAuthoringFlowEncodesCanonicalKeys() throws {
    let flow = AteliaPackageAuthoringFlow(
        packageId: "com.example.review",
        sourceClass: .verifiedRegistry,
        source: AteliaPackageGitHubSourceReference(
            repository: "atelia-labs/atelia-official-packages",
            ref: "v1.0.0",
            manifestPath: "packages/review/aep.yaml",
            manifestDigest: "sha256:aaaaaaaa",
            artifactDigests: ["sha256:bbbbbbbb"]
        ),
        steps: [
            AteliaPackageAuthoringFlowStep(
                id: .install,
                title: "Install package",
                state: .requiresConsent,
                requiresExplicitConsent: true,
                policyNotes: ["Registry validation required"]
            )
        ],
        publicationPlan: AteliaPackagePublicationPlan(
            visibility: .publicSearchable,
            sourceClass: .verifiedRegistry,
            githubActions: [.prepareReleaseMetadata, .submitRegistryMetadata],
            requiresRegistrySubmission: true,
            productionInstallable: true
        )
    )

    let data = try JSONEncoder().encode(flow)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let source = try #require(object["source"] as? [String: Any])
    let steps = try #require(object["steps"] as? [[String: Any]])
    let publicationPlan = try #require(object["publication_plan"] as? [String: Any])

    #expect(object["package_id"] as? String == "com.example.review")
    #expect(object["source_class"] as? String == "verified-registry")
    #expect(source["manifest_path"] as? String == "packages/review/aep.yaml")
    #expect(source["artifact_digests"] as? [String] == ["sha256:bbbbbbbb"])
    #expect(steps[0]["id"] as? String == "install")
    #expect(steps[0]["state"] as? String == "requires_consent")
    #expect(steps[0]["requires_explicit_consent"] as? Bool == true)
    #expect(publicationPlan["visibility"] as? String == "public_searchable")
    #expect(publicationPlan["requires_registry_submission"] as? Bool == true)
    #expect(publicationPlan["production_installable"] as? Bool == true)
}

/// Verifies optional collection and consent fields tolerate omitted keys.
@Test func packageAuthoringFlowDecodesDefaultedMissingKeys() throws {
    let data = #"""
    {
      "package_id": "com.example.review",
      "source_class": "workspace-local",
      "source": {
        "repository": "atelia-labs/atelia-official-packages",
        "manifest_path": "packages/review/aep.yaml"
      },
      "steps": [
        {
          "id": "inspect",
          "title": "Inspect package",
          "state": "available"
        }
      ],
      "publication_plan": {
        "visibility": "private_remix",
        "source_class": "workspace-local",
        "requires_registry_submission": false,
        "production_installable": false
      }
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPackageAuthoringFlow.self, from: data)

    #expect(decoded.source?.artifactDigests == [])
    #expect(decoded.steps[0].requiresExplicitConsent == false)
    #expect(decoded.steps[0].policyNotes == [])
    #expect(decoded.publicationPlan?.githubActions == [])
}

/// Verifies unknown enum values remain round-trippable for forward compatibility.
@Test func packageAuthoringFlowPreservesUnknownEnumValues() throws {
    let data = #"""
    {
      "package_id": "com.example.future",
      "source_class": "enterprise-managed",
      "steps": [
        {
          "id": "semantic_diff",
          "title": "Semantic diff",
          "state": "awaiting_secretary",
          "requires_explicit_consent": false,
          "policy_notes": []
        }
      ],
      "publication_plan": {
        "visibility": "team_only",
        "source_class": "enterprise-managed",
        "github_actions": ["request_review"],
        "requires_registry_submission": true,
        "production_installable": false
      }
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPackageAuthoringFlow.self, from: data)

    #expect(decoded.sourceClass == .unknown("enterprise-managed"))
    #expect(decoded.steps[0].id == .unknown("semantic_diff"))
    #expect(decoded.steps[0].state == .unknown("awaiting_secretary"))
    #expect(decoded.publicationPlan?.visibility == .unknown("team_only"))
    #expect(decoded.publicationPlan?.githubActions == [.unknown("request_review")])

    let encoded = try JSONEncoder().encode(decoded)
    let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    let steps = try #require(object["steps"] as? [[String: Any]])
    let publicationPlan = try #require(object["publication_plan"] as? [String: Any])

    #expect(object["source_class"] as? String == "enterprise-managed")
    #expect(steps[0]["id"] as? String == "semantic_diff")
    #expect(steps[0]["state"] as? String == "awaiting_secretary")
    #expect(publicationPlan["visibility"] as? String == "team_only")
    #expect(publicationPlan["github_actions"] as? [String] == ["request_review"])
}

/// Verifies consent helper treats the state enum as a consent gate.
@Test func packageAuthoringFlowConsentHelperIncludesStateGate() {
    let flow = AteliaPackageAuthoringFlow(
        packageId: "com.example.review",
        sourceClass: .workspaceLocal,
        steps: [
            AteliaPackageAuthoringFlowStep(
                id: .inspect,
                title: "Inspect package",
                state: .complete
            ),
            AteliaPackageAuthoringFlowStep(
                id: .install,
                title: "Install package",
                state: .requiresConsent
            ),
            AteliaPackageAuthoringFlowStep(
                id: .publish,
                title: "Publish package",
                state: .available,
                requiresExplicitConsent: true
            )
        ]
    )

    #expect(flow.stepsRequiringConsent.map(\.id) == [.install, .publish])
}

/// Verifies official publication visibility follows the Secretary contract value.
@Test func packagePublicationVisibilityUsesOfficialContractValue() throws {
    let plan = AteliaPackagePublicationPlan(
        visibility: .official,
        sourceClass: .bundledOfficial,
        requiresRegistrySubmission: true,
        productionInstallable: true
    )

    let data = try JSONEncoder().encode(plan)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(object["visibility"] as? String == "official")
    #expect(try JSONDecoder().decode(AteliaPackagePublicationPlan.self, from: data).visibility == .official)
}
