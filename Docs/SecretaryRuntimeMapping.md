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
| repository registration | `AteliaRegisterRepositoryRequest`, `AteliaRegisterRepositoryResponse` | `display_name`, `root_path`, `allowed_scope`, `requester`, `repository`, `policy` (nullable) |
| job | `AteliaJob` | `job_id`, `repository_id`, `requester`, `kind`, optional `goal`, `status`, `latest_event_id` |
| cancellation | `AteliaCancelJobRequest`, `AteliaCancelJobResponse`, `AteliaJobCancellation` | `requester`, `reason`, `job`, `cancellation`, `state`, `requested_by` |
| submit job | `AteliaSubmitJobRequest`, `AteliaSubmitJobToolArgs`, `AteliaSubmitJobResponse` | `repository_id`, `requester`, `kind`, optional `message`, optional `goal`, optional `model_route_key`, optional `permission_mode_route_key`, `path_scope`, `requested_capabilities`, `idempotency_key`, `tool_args`, `job`, `policy` |
| event listing / replay | `AteliaListEventsRequest`, `AteliaListEventsResponse`, `AteliaReplayEventsRequest`, `AteliaReplayEventsResponse`, `AteliaEvent` | listing: `repository_id`, `job_ids`, `cursor`, `page_size`, `page_token`; job-scoped list: `repository_id`, `cursor`, `min_severity`, `page_size`, `page_token`; replay: `repository_id`, `cursor`, `limit`; responses/events: `events`, `next_page_token`, tagged cursor keys (`kind`, optional `sequence_number`, optional `event_id`) |
| project lifecycle cache | `AteliaProjectLifecycleStore`, `AteliaProjectLifecycleStoreSnapshot` | `repository`, `job`, `cancellation`, `events`, `replayResponse`, `metadata`, `latestCursor` |
| policy summary / decision | `AteliaPolicySummary`, `AteliaPolicyDecision` | `decision_id`, `outcome`, `risk_tier`, `approval_request_ref`, `audit_ref` |
| approval state | `AteliaApprovalState` | `id`, `status`, `policy_decision_id`, `requested_by`, `reason` |
| audit reference | `AteliaAuditReference` | `id`, `repository_id`, `job_id`, `policy_decision_id`, `message` |
| review queue item | `AteliaReviewQueueItem` | `id`, `kind`, `title`, `repository_id`, `job_id`, `policy_decision_id`, `priority` |
| event cursor (routes) | `AteliaEventRouteCursor` | `kind` + `sequence_number` / `event_id` |
| project status | `AteliaProjectStatus` | `metadata`, `repository`, `recent_jobs`, `recent_policy_decisions`, `latest_cursor: { sequence, event_id }`, `daemon_status`, `storage_status` |
| package inspect | `AteliaPackageInspect`, `AteliaPackageServices`, `AteliaPackageServiceDependency` | `package_id`, `extension`, `manifest`, `permissions`, `services`, `services.provides[].required_permissions`, `services.consumes[].grants` |
| package trust index | `AteliaPackageTrustIndexResponse`, `AteliaPackageTrustIndexEntry` | `metadata`, `packages`, `package_id`, `status`, `boundary` |
| service broker authorization | `AteliaAuthorizeServiceCallRequest`, `AteliaAuthorizeServiceCallResponse`, `AteliaServiceCallGrant` | `caller_package_id`, `caller_component_id`(optional), `callee_package_id`, `callee_component_id`(optional), `service`, `method`, `schema_version`, `required_permissions`, `grant` |
| service broker live call | `AteliaServiceCallRequest`, `AteliaServiceCallResponse`, `AteliaServiceCallExecutionResult`, `AteliaServiceCallGrant` | `caller_package_id`, `caller_component_id`(optional), `callee_package_id`, `callee_component_id`(optional), `service`, `method`, `schema_version`, `required_permissions`, `metadata`, `grant`, `result`, (`status`, `outcome`, `reason`, `reason_code`) |
| package validation | `AteliaPackageValidationRequest`, `AteliaPackageValidationResponse` | `manifest`, `approve_local_unsigned`, `allow_local_process_runtime`, `approve_source_change`, `boundary` |
| package lifecycle | `AteliaPackageLifecycleRequest`, `AteliaPackageLifecycleResponse`, `AteliaPackageStatus` | `manifest`, `id`, `record`, `extension_id`, `extension`, `extensions`, `previous_version` |
| package authoring | `AteliaPackageAuthoringFlow`, `AteliaPackagePublicationPlan`, `AteliaPackageRegistrySubmissionState` | `package_id`, `source_class`, `source`, `steps`, `publication_plan`, `state` |
| package rollback | `AteliaPackageRollbackResponse`, `AteliaPackageRollbackRecord` | `id`, `version`, `previous_version`, `status`, `rollback_snapshot` |
| beta repertoire projection | `AteliaToolRepertoireEntry` | `tool_id`, `name`, `provider_kind`, `aep_package_id`, `aep_component_id`, `supported_result_formats` |
| tool output rendering | `AteliaToolOutputRenderRequest`, `AteliaToolOutputRenderResponse` | `tool_result`, `format`, `rendered_output`, `rendered_output_metadata`, `truncation` |

Project status uses a flat `latest_cursor` (`sequence`, `event_id`) from the RPC EventCursor path.
Event listing / replay routes use tagged `cursor` envelopes through `AteliaEventRouteCursor`
(`kind`, optional `sequence_number` / `event_id`) on list/replay models.

`services.provides[].required_permissions` is the canonical shape for package service permissions in
Kit, and decode compatibility accepts legacy `services.provides[].required_permission`.
Service broker model keys are canonicalized to package/component IDs, while decoding
keeps compatibility with legacy `*_extension_id` request and response keys.

The third column is a representative drift guard, not an exhaustive schema
listing. It includes envelope keys such as `metadata`, collection keys such as
`packages`, and high-risk model keys that have already drifted across client and
Secretary implementations. Codable tests cover the exact keys most likely to
break the client/server contract; add focused tests before changing any
protocol-facing model shape.

`AteliaRegisterRepositoryRequest` intentionally requires both `requester` and
`allowed_scope` for client-originated repository registration, even though the
Secretary transport accepts them as optional. Mac MDP clients should register
repositories with an explicit actor and allowed path scope so audit, policy, and
runtime safety decisions do not depend on server-side defaults.

## Transport Boundary

`HTTPAteliaClient` implements the beta HTTP/JSON calls needed by the first Mac
and iOS operating surfaces:

- `GET /v1/health`
- `POST /v1/repositories:list`
- `POST /v1/repositories:register`
- `POST /v1/repertoire:list`
- `POST /v1/project-status:get`
- `POST /v1/jobs/submit`
- `GET /v1/jobs/{job_id}`
- `POST /v1/jobs/{job_id}/cancel`
- `POST /v1/events/list`
- `POST /v1/jobs/{job_id}/events`
- `POST /v1/events/replay`
- `POST /v1/package-trust-index:list`
- `POST /v1/services/authorize`
- `POST /v1/services/call`
- `POST /v1/packages/validate`
- `POST /v1/packages/install`
- `POST /v1/packages/update`
- `POST /v1/packages/list`
- `POST /v1/packages/{package_id}/status`
- `POST /v1/packages/{package_id}/disable`
- `POST /v1/packages/{package_id}/enable`
- `POST /v1/packages/{package_id}/remove`
- `POST /v1/packages/{package_id}/rollback`
- `POST /v1/packages/blocklist/apply`
- `POST /v1/packages/blocklist/list`
- `POST /v1/packages/{package_id}/authoring-flow`
- `POST /v1/packages/{package_id}/remix`
- `POST /v1/packages/{package_id}/publication`
- `POST /v1/packages/{package_id}/registry-submission`
- `POST /v1/tool-results:render`

The client accepts an `AteliaHTTPTransport`, so tests and future transports do
not need UI-specific mocking. Bearer authentication is optional at construction
time because local development may run the daemon with auth disabled, while beta
clients should pass the generated daemon token.

## Client Rules

- Treat protocol ids as opaque strings.
- Do not display ids as primary user-facing labels.
- Treat unknown capabilities as recoverable protocol information.
- Keep Mac windowing, iOS navigation, and visual design outside this package.
- Keep Secretary execution, broker decisions, and package runtime hosting
  outside this package.
- Add Codable tests before changing any protocol-facing model shape.
