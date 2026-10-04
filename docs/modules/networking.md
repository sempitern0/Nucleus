# Optional Networking Module

## Status

`modules/networking` is optional and is not loaded by default.

It is transport/bootstrap infrastructure, not an online game framework.

## NetworkHandler responsibility

`NucleusNetworkHandler` wraps Godot's high-level `MultiplayerAPI` peer lifecycle.

Supported convenience paths include:

```text
ENet server/client
WebSocket server/client
shutdown/offline restoration
peer/state signals
connected-peer queries
server-side disconnect
```

It intentionally does not implement:

```text
gameplay replication
RPC schema
authentication
matchmaking
lobbies
reconciliation/prediction
backend services
```

Those concerns remain game/module specific.

## Platform behavior

ENet server/client startup is unavailable on Web in the current handler.
Browsers cannot listen for incoming WebSocket connections, so WebSocket server
startup is also unavailable there.

WebSocket clients remain the portable browser-facing transport option.

`NucleusNetworkUtils` provides port validation, local IPv4 helpers, nonce
generation, and WebSocket URL validation.

## Ownership

The game decides whether the handler is scene-owned or promoted to an Autoload.
Do not add it to the baseline merely because the project may eventually have
multiplayer.

## Godot-native APIs

The module delegates to:

```text
MultiplayerAPI
MultiplayerPeer
ENetMultiplayerPeer
WebSocketMultiplayerPeer
OfflineMultiplayerPeer
TLSOptions
IP
Crypto
```

Nucleus does not maintain a parallel networking stack.

## Security boundary

Nonce generation and TLS options are helpers, not authentication. Authorization,
identity, secret storage, protocol validation, rate limiting, and backend trust
must be designed by the game/service layer.

## Web/export testing

Iteration 18 smoke-exports the whole template to Web so optional networking code
continues to parse/export even though ENet startup is blocked at runtime.
