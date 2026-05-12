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

/// Verifies authoring-flow request defaults keep private-step visibility by default.
@Test func packageAuthoringFlowRequestDefaultsPrivateSteps() throws {
    let data = #"""
    {
      "package_id": "com.example.review"
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPackageAuthoringFlowRequest.self, from: data)
    let encoded = try JSONEncoder().encode(decoded)

    let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

    #expect(decoded.packageId == "com.example.review")
    #expect(decoded.includePrivateSteps == true)
    #expect(object["include_private_steps"] as? Bool == true)
}

/// Verifies remix request decoding applies default source class semantics.
@Test func packageRemixRequestDefaultsSourceClass() throws {
    let data = #"""
    {
      "package_id": "com.example.remix",
      "source": {
        "repository": "atelia-labs/atelia",
        "manifest_path": "packages/review/package.yml"
      }
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPackageRemixRequest.self, from: data)
    #expect(decoded.packageId == "com.example.remix")
    #expect(decoded.sourceClass == .workspaceLocal)
    #expect(decoded.source?.repository == "atelia-labs/atelia")
}

/// Verifies publication request defaults preserve compatibility-oriented behavior.
@Test func packagePublicationRequestDefaults() throws {
    let data = #"""
    {
      "package_id": "com.example.publish",
      "visibility": "public_searchable"
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPackagePublicationRequest.self, from: data)
    let object = try #require(
        JSONSerialization.jsonObject(with: try JSONEncoder().encode(decoded)) as? [String: Any]
    )

    #expect(decoded.packageId == "com.example.publish")
    #expect(decoded.sourceClass == .workspaceLocal)
    #expect(decoded.requiresRegistrySubmission == true)
    #expect(decoded.productionInstallable == true)
    #expect(object["requires_registry_submission"] as? Bool == true)
    #expect(object["production_installable"] as? Bool == true)
}

/// Verifies registry submission requests preserve unknown states and use submitted defaults.
@Test func packageRegistrySubmissionRequestDefaultsAndUnknownState() throws {
    let data = #"""
    {
      "package_id": "com.example.registry",
      "state": "submitted"
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPackageRegistrySubmissionRequest.self, from: data)
    let encoded = try JSONEncoder().encode(decoded)
    let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    let fallback = try JSONDecoder().decode(
        AteliaPackageRegistrySubmissionRequest.self,
        from: #"""
        {
          "package_id": "com.example.registry"
        }
        """#.data(using: .utf8)!
    )

    #expect(decoded.state == .submitted)
    #expect(object["state"] as? String == "submitted")
    #expect(fallback.state == .submitted)

    let unknownData = #"""
    {
      "package_id": "com.example.registry",
      "state": "awaiting_humane_review"
    }
    """#.data(using: .utf8)!
    let decodedUnknown = try JSONDecoder().decode(AteliaPackageRegistrySubmissionRequest.self, from: unknownData)

    #expect(decodedUnknown.state == .unknown("awaiting_humane_review"))
}

/// Verifies registry submission responses map package id and state from wire format.
@Test func packageRegistrySubmissionResponseDecodesCanonicalShape() throws {
    let data = #"""
    {
      "metadata": {
        "protocol_version": "1.0.0",
        "daemon_version": "0.1.0",
        "storage_version": "0.1.0",
        "capabilities": ["extensions.registry-submission.v1"]
      },
      "package_id": "com.example.review",
      "state": "rejected",
      "message": "awaiting manual review"
    }
    """#.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AteliaPackageRegistrySubmissionResponse.self, from: data)

    #expect(decoded.packageId == "com.example.review")
    #expect(decoded.state == .rejected)
    #expect(decoded.message == "awaiting manual review")
    #expect(decoded.flow == nil)
}
