# Atelia Kit

[English README](README.md)

Atelia Kit は、Atelia Mac と Atelia iOS が共有する Swift package です。

このリポジトリは、UI ではなく、Apple platform clients が共有するクライアントロジックを扱います。

AEP において、Atelia Kit は presentation host が共有する client-side model を担当します。Atelia Protocol client state、AEP package / component / permission / risk model、Surface Protocol presentation declaration、component catalog data、action routing input、package inspection、permission diff の view-model coordination を扱います。Secretary の実行、package code の実行、package-supplied web runtime UI の load、package への platform API access、platform-specific UI の描画は行いません。

## スコープ

- Atelia Protocol client
- session / connection state
- domain models
- event stream handling
- local cache interfaces
- notification routing
- platform-neutral view model coordination
- AEP package、permission、Surface Protocol、component catalog model
- package inspector と permission diff の view-model support

## 対象外

- macOS のウィンドウ管理
- iOS navigation
- platform-specific notification behavior
- visual design decisions
- Secretary runtime hosting
- executable package loading

## 開発

```sh
swift test
```
