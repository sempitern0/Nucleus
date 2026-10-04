# Optional Networking Module

## Status

`modules/networking` is optional and is not loaded by default.

It now has two layers:

```text
transport/bootstrap
gameplay replication helpers
```

It is still not a matchmaking/backend framework.

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

Transport remains separate from gameplay replication.

## Gameplay replication

Iteration 25 adds:

```text
NucleusNetworkIntentChannel
NucleusNetworkSequenceTracker
NucleusNetworkRateLimiter
NucleusTransformSnapshotBuffer2D
NucleusTransformSnapshotBuffer3D
NucleusNetworkTransformReplicator2D
NucleusNetworkTransformReplicator3D
```

These solve client-to-server intent admission and optional transform smoothing.

They do not replace native:

```text
MultiplayerSpawner
MultiplayerSynchronizer
SceneReplicationConfig
RPC
```

See:

```text
docs/modules/online_replication.md
docs/guides/online_replication_quickstart.md
```

## Platform behavior

ENet server/client startup is unavailable on Web in the current handler.

Browsers cannot listen for incoming WebSocket connections, so WebSocket server
startup is also unavailable there.

WebSocket clients remain the portable browser-facing transport option.

`NucleusNetworkUtils` provides port validation, local IPv4 helpers, nonce
generation, and WebSocket URL validation.

Provider-specific transports such as storefront/P2P plugins remain outside
NetworkHandler's built-in convenience constructors. A consuming game may
configure Godot MultiplayerAPI using the provider's supported MultiplayerPeer.

## Ownership

The game decides whether the handler is scene-owned or promoted to an Autoload.

Do not add it to the baseline merely because the project may eventually have
multiplayer.

Replication components are normally owned by the replicated gameplay scenes.

## Godot-native APIs

The module delegates to:

```text
MultiplayerAPI
MultiplayerPeer
SceneMultiplayer
MultiplayerSpawner
MultiplayerSynchronizer
SceneReplicationConfig
ENetMultiplayerPeer
WebSocketMultiplayerPeer
OfflineMultiplayerPeer
TLSOptions
IP
Crypto
```

Nucleus does not maintain a parallel networking stack.

## Security boundary

Nonce generation, TLS options, intent sequence checks, and basic rate limiting
are infrastructure.

They are not authentication or full gameplay authorization.

A production game must still design:

```text
identity/authentication
session admission
semantic RPC validation
gameplay authority
anti-cheat requirements
backend trust
secret storage
provider token verification
```

The server should remain authoritative for gameplay-critical state.

## Web/export testing

Iteration 18 smoke-exports the whole template to Web so optional networking code
continues to parse/export even though ENet startup is blocked at runtime.
