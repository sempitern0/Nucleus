# Networking Quickstart

This guide covers connection/bootstrap with `NucleusNetworkHandler`.

It intentionally stops before gameplay replication.

For a complete host/join exercise, see:

[`tutorials/networking.md`](tutorials/networking.md)

For authoritative gameplay replication, continue later with:

[`online_replication_quickstart.md`](online_replication_quickstart.md)

## What the networking module owns

`NucleusNetworkHandler` owns convenience around Godot peer lifecycle:

```text
ENet server/client
WebSocket server/client
MultiplayerAPI peer installation
connection state
peer connect/disconnect signals
shutdown back to OfflineMultiplayerPeer
```

It does not own:

```text
matchmaking
lobbies
authentication
account identity
RPC semantics
gameplay authority
anti-cheat
backend services
```

## 1. Add the handler

The module is optional and is not an Autoload by default.

Instance:

```text
res://modules/networking/network_handler.tscn
```

A normal session-owned setup is:

```text
GameSession
├── Network : NucleusNetworkHandler
└── World
```

Promote it to an Autoload only if your game intentionally needs the connection
to survive complete session/scene replacement.

## 2. Host an ENet session

```gdscript
var error: Error = network.start_enet_server(
    42069,
    8,
)

if error != OK:
    push_error("Host failed: %s" % error_string(error))
```

After success:

```gdscript
network.is_server()
network.get_unique_id()
network.get_connected_peers()
```

become the convenient public queries.

## 3. Join an ENet session

```gdscript
var error: Error = network.start_enet_client(
    "127.0.0.1",
    42069,
)

if error != OK:
    push_error("Client start failed: %s" % error_string(error))
```

A successful constructor means the connection attempt started. Use
`connected_to_server` to know when the client is actually connected.

## 4. Observe lifecycle signals

Useful signals include:

```text
state_changed
peer_connected
peer_disconnected
connected_to_server
connection_failed
server_disconnected
start_failed
```

UI should derive status from those signals rather than polling every frame.

## 5. Understand states

The shared state enum is:

```text
OFFLINE
STARTING
CONNECTING
SERVER
CLIENT
```

Use `is_server()`, `is_client()`, and `is_online()` when you do not need to care
about the exact transitional state.

## 6. Leave cleanly

```gdscript
network.shutdown()
```

This closes the active peer and restores Godot's `OfflineMultiplayerPeer`.

If the handler is scene-owned, `shutdown_on_exit = true` also makes teardown a
safe default.

## 7. WebSocket path

Native/server builds can host a WebSocket server:

```gdscript
network.start_websocket_server(42069)
```

Clients can connect with:

```gdscript
network.start_websocket_client("ws://127.0.0.1:42069")
```

Browser exports cannot listen for incoming connections. ENet startup is also
unavailable on Web through the current convenience handler.

Use a WebSocket client or a provider-specific transport for browser-facing
projects.

## 8. Test transport before replication

Before adding synchronized players, prove this first:

```text
host starts
client connects
host sees peer_connected
client reaches CLIENT state
client disconnects
host sees peer_disconnected
both can return to OFFLINE
```

This isolates transport problems from gameplay replication problems.

## 9. Authority comes next

A connection does not decide who may change health, inventory, transforms, or
world state.

For gameplay-critical state, a recommended starting model is:

```text
client input
→ client intent
→ server validates
→ server mutates authoritative gameplay state
→ state/snapshot is replicated
→ clients present it
```

Use native Godot `MultiplayerSpawner`, `MultiplayerSynchronizer`, RPC, and
`SceneReplicationConfig` where they fit. Nucleus adds helpers around repeated
intent/snapshot patterns; it does not replace Godot networking.

## Common mistakes

Avoid:

- making the handler an Autoload without a lifetime reason;
- treating a successful `start_enet_client()` call as a completed connection;
- starting gameplay replication before host/join/disconnect is stable;
- trusting client-reported gameplay-critical state;
- assuming transport solves authentication or matchmaking;
- writing platform-specific P2P assumptions into generic gameplay code.

## Related documentation

- [`tutorials/networking.md`](tutorials/networking.md)
- [`optional_modules_quickstart.md`](optional_modules_quickstart.md)
- [`online_replication_quickstart.md`](online_replication_quickstart.md)
- [`../modules/networking.md`](../modules/networking.md)
- [`../modules/online_replication.md`](../modules/online_replication.md)
