# Secretary Runtime Mapping

`atelia-kit` is the shared Apple-client boundary for the Secretary protocol and
Surface Protocol client models. It keeps daemon transport, runtime identity,
package inspection, action routing inputs, and client coordination models
outside Mac-only and iOS-only UI code. It is client infrastructure, not a
Secretary host and not an executable package loader.

## Contract Sources

Early MVP/MDP contract references now point to the canonical
`docs/protocol-contract.md` in `atelia-secretary` for the current contract
surface.

- [Secretary Protocol Contract](https://github.com/atelia-labs/atelia-secretary/blob/main/docs/protocol-contract.md)
- [Secretary Runtime Architecture](https://github.com/atelia-labs/atelia-secretary/blob/main/docs/runtime-architecture.md)
- [Client UX](https://github.com/atelia-labs/atelia/blob/main/docs/client-ux.md)
- [Surface Protocol](https://github.com/atelia-labs/atelia/blob/main/docs/surface-protocol.md)
- [AEP Presentation](https://github.com/atelia-labs/atelia/blob/main/docs/aep-presentation.md)
- [Component Catalog](https://github.com/atelia-labs/atelia/blob/main/docs/component-catalog.md)

The current shipping beta transport is HTTP/JSON. The Rust RPC boundary remains
transport-neutral, so `atelia-kit` keeps the transport implementation small and
replaceable.

## Model Mapping

| Secretary contract area | Atelia Kit model | Representative canonical protocol keys |
| --- | --- | --- |
| protocol metadata | `AteliaProtocolMetadata` | `metadata` |
| health response | `AteliaHealthResponse` | `daemon_status`, `daemon_version`, `protocol_version`, `storage_status`, `storage_version`, `capabilities` |
| repository | `AteliaRepository` | `repository`, `repository_id`, `allowed_scope` |
| allowed path scope | `AteliaPathScope` | `kind`, `roots`, `include_patterns`, `exclude_patterns` |
| project/thread client identity | `AteliaProjectIdentity`, `AteliaThreadIdentity` | `repository_id`, `project_id`, `id`, `title`, `display_name` |
| actor | `AteliaActor` | `type`, `id`, `display_name` |
| job | `AteliaJob` | `job_id`, `repository_id`, `requester`, `kind`, `status` |
| cancellation | `AteliaJobCancellation` | `state`, `requested_by`, `reason` |
| policy summary / decision | `AteliaPolicySummary`, `AteliaPolicyDecision` | `decision_id`, `outcome`, `risk_tier`, `approval_request_ref`, `audit_ref` |
| approval state | `AteliaApprovalState` | `id`, `status`, `policy_decision_id`, `requested_by`, `reason` |
| audit reference | `AteliaAuditReference` | `id`, `repository_id`, `job_id`, `policy_decision_id`, `message` |
| review queue item | `AteliaReviewQueueItem` | `id`, `kind`, `title`, `repository_id`, `job_id`, `policy_decision_id`, `priority` |
| event cursor | `AteliaEventCursor` | `sequence`, `event_id` |
| project status | `AteliaProjectStatus` | `metadata`, `repository`, `recent_jobs`, `recent_policy_decisions`, `latest_cursor`, `daemon_status`, `storage_status` |
| package trust index | `AteliaPackageTrustIndexResponse`, `AteliaPackageTrustIndexEntry` | `metadata`, `packages`, `package_id`, `status`, `boundary` |
| beta repertoire projection | `AteliaToolRepertoireEntry` | `tool_id`, `name`, `provider_kind`, `supported_result_formats` |

The third column is a representative drift guard, not an exhaustive schema
listing. It includes envelope keys such as `metadata`, collection keys such as
`packages`, and high-risk model keys that have already drifted across client and
Secretary implementations. Codable tests cover the exact keys most likely to
break client/server compatibility; add focused tests before changing any
protocol-facing model shape.

## Transport Boundary

`HTTPAteliaClient` implements the beta HTTP/JSON calls needed by the first Mac
and iOS operating surfaces:

- `GET /v1/health`
- `POST /v1/repositories:list`
- `POST /v1/repertoire:list`
- `POST /v1/project-status:get`
- `POST /v1/package-trust-index:list`

The client accepts an `AteliaHTTPTransport`, so tests and future transports do
not need UI-specific mocking. Bearer authentication is optional at construction
time because local development may run the daemon with auth disabled, while beta
clients should pass the generated daemon token.

## Client Rules

- Treat protocol ids as opaque strings.
- Do not display ids as primary user-facing labels.
- Treat unknown capabilities as recoverable compatibility information.
- Keep Mac windowing, iOS navigation, and visual design outside this package.
- Keep Secretary execution, broker decisions, and package runtime hosting
  outside this package.
- Add Codable tests before changing any protocol-facing model shape.
