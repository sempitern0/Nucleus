# Optional Networking

`NucleusNetworkHandler` is an optional facade over Godot's high-level
`MultiplayerAPI`.

It is not an Autoload by default.

Nucleus does not replace:

```text
@rpc
MultiplayerSpawner
MultiplayerSynchronizer
SceneMultiplayer authentication
custom matchmaking
backend services
```

Those remain project responsibilities.

## Why optional

Many games are entirely offline. A networking singleton in every project would
add global state with no value.

Recommended scene ownership:

```text
GameSession
└── NetworkHandler : NucleusNetworkHandler
```

A project that genuinely wants application-wide networking can manually add:

```ini
NucleusNetwork="*res://modules/networking/network_handler.gd"
```

## ENet

Native Windows/Linux/macOS/mobile builds can use:

```gdscript
network.start_enet_server(
    42069,
    8,
)
```

or:

```gdscript
network.start_enet_client(
    "192.168.1.42",
    42069,
)
```

Godot's ENet peer uses UDP and integrates directly with `MultiplayerAPI`.

ENet startup returns `ERR_UNAVAILABLE` on Web because browsers do not expose raw
UDP sockets.

## WebSocket

Client:

```gdscript
network.start_websocket_client(
    "wss://example.com/game"
)
```

Native server:

```gdscript
network.start_websocket_server(
    42069
)
```

WebSocket clients work on Web and native exports.

A browser export cannot host a listening socket, so WebSocket server creation is
disabled there.

## Transport state

```text
OFFLINE
STARTING
CONNECTING
SERVER
CLIENT
```

and:

```text
NONE
ENET
WEBSOCKET
```

Connection events mirror the useful `MultiplayerAPI` signals:

```gdscript
peer_connected
peer_disconnected
connected_to_server
connection_failed
server_disconnected
```

## LAN discovery

`NucleusLanDiscovery` is separate from the multiplayer transport.

```text
NetworkHandler
    → authoritative connection

LanDiscovery
    → find candidate servers on a local network
```

Example:

```gdscript
discovery.start_listening()

discovery.start_announcing(
    {
        "name": "Daniel's Lobby",
        "port": 42069,
        "players": 2,
    }
)
```

Discovery uses UDP broadcast and returns `ERR_UNAVAILABLE` on Web.

The broadcaster intentionally does not bind a source port. Godot can select an
ephemeral source port, which makes local multi-instance testing less prone to
port collisions.

Discovery packets are JSON and capped at 8 KiB. They are discovery hints only
and must never be treated as trusted authentication data.

## Utilities salvaged from OmniKit

```gdscript
NucleusNetworkUtils.is_valid_port(...)
NucleusNetworkUtils.random_port(...)
NucleusNetworkUtils.get_local_ipv4_addresses(...)
NucleusNetworkUtils.get_preferred_local_ipv4()
NucleusNetworkUtils.generate_nonce(...)
```

Not retained:

- HTTP "internet ping" checks;
- URL opening;
- giant IPv4/IPv6 regular expressions;
- hardcoded Google/Cloudflare reachability probes;
- manually guessed subnet broadcast addresses;
- generic signal-disconnection helpers.

Those responsibilities either belong elsewhere or were unreliable proxies for
actual game-server reachability.

## Web portability

Godot Web exports support WebSocket/WebRTC but do not expose raw TCP/UDP.

Nucleus therefore treats transport support as a runtime capability instead of
pretending one peer technology works everywhere.

WebRTC is not wrapped in this iteration because signaling architecture is
project/backend-specific. It can be added later as another transport without
changing the public role of `NucleusNetworkHandler`.
