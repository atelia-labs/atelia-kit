# Atelia Kit

[日本語版 README](README.ja.md)

Atelia Kit is the shared Swift package used by Atelia Mac and Atelia iOS.

This repository owns shared client logic for Apple platform clients, not UI.

Within AEP, Atelia Kit owns shared client-side models for presentation hosts:
Atelia Protocol client state, AEP package / component / permission / risk
models, Surface Protocol presentation declarations, component catalog data,
action routing inputs, package inspection, and permission diff view-model
coordination. It does not run Secretary, execute package code, load downloaded
native UI / JS / WebView rendering surfaces, provide dynamic loaders, expose
direct native API access to packages, or render platform-specific UI.

## Scope

- Atelia Protocol client
- session / connection state
- domain models
- event stream handling
- local cache interfaces
- notification routing
- platform-neutral view model coordination
- AEP package, permission, Surface Protocol, and component catalog models
- package inspector and permission diff view-model support

## Non-goals

- macOS windowing
- iOS navigation
- platform-specific notification behavior
- visual design decisions
- Secretary runtime hosting
- executable package loading

## Development

```sh
swift test
```

## Secretary Runtime Mapping

The shared model and transport boundary follows the Secretary protocol contract.
See [Docs/SecretaryRuntimeMapping.md](Docs/SecretaryRuntimeMapping.md).
