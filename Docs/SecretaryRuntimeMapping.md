# Secretary Runtime Mapping

`atelia-kit` is the shared Apple-client boundary for the Secretary protocol and
Surface Protocol client models. It keeps daemon transport, runtime identity,
package inspection, action routing inputs, and client coordination models
outside Mac-only and iOS-only UI code. It is client infrastructure, not a
Secretary host and not an executable package loader.

## Contract Sources

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

| Secretary contract | Atelia Kit model |
| --- | --- |
| protocol metadata | `AteliaProtocolMetadata` |
| health response | `AteliaHealthResponse` |
| repository | `AteliaRepository` |
| allowed path scope | `AteliaPathScope` |
| project/thread client identity | `AteliaProjectIdentity`, `AteliaThreadIdentity` |
| actor | `AteliaActor` |
| job | `AteliaJob` |
| cancellation | `AteliaJobCancellation` |
| policy summary / decision | `AteliaPolicySummary`, `AteliaPolicyDecision` |
| approval state | `AteliaApprovalState` |
| audit reference | `AteliaAuditReference` |
| review queue item | `AteliaReviewQueueItem` |
| event cursor | `AteliaEventCursor` |
| project status | `AteliaProjectStatus` |
| beta repertoire projection | `AteliaToolRepertoireEntry` |

## Transport Boundary

`HTTPAteliaClient` implements the beta HTTP/JSON calls needed by the first Mac
and iOS operating surfaces:

- `GET /v1/health`
- `POST /v1/repositories:list`
- `POST /v1/repertoire:list`
- `POST /v1/project-status:get`

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
