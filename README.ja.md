# Atelia Kit

[English README](README.md)

Atelia Kit は、Atelia Mac と Atelia iOS が共有する Swift package です。

このリポジトリは、UI ではなく、Apple platform clients が共有するクライアントロジックを扱います。

## スコープ

- Atelia Protocol client
- session / connection state
- domain models
- event stream handling
- local cache interfaces
- notification routing
- platform-neutral view model coordination

## 対象外

- macOS のウィンドウ管理
- iOS navigation
- platform-specific notification behavior
- visual design decisions

## 開発

```sh
swift test
```
