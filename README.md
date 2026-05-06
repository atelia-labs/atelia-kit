# Atelia Kit

[日本語版 README](README.ja.md)

Atelia Kit is the shared Swift package used by Atelia Mac and Atelia iOS.

This repository owns shared client logic for Apple platform clients, not UI.

## Scope

- Atelia Protocol client
- session / connection state
- domain models
- event stream handling
- local cache interfaces
- notification routing
- platform-neutral view model coordination

## Non-goals

- macOS windowing
- iOS navigation
- platform-specific notification behavior
- visual design decisions

## Development

```sh
swift test
```

## Secretary Runtime Mapping

The shared model and transport boundary follows the Secretary protocol contract.
See [Docs/SecretaryRuntimeMapping.md](Docs/SecretaryRuntimeMapping.md).
