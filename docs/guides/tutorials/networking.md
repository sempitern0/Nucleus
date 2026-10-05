# Tutorial: build a local Host / Join / Leave networking lab

This tutorial proves Nucleus transport/bootstrap before you add replicated
players.

At the end two game instances can:

- start an ENet host;
- connect a client through `127.0.0.1`;
- display connection state;
- report peer join/leave;
- shut down cleanly.

It deliberately does **not** synchronize gameplay yet.

## 1. Create the scene

```text
NetworkLab : Control
├── Network : NucleusNetworkHandler
└── VBoxContainer
    ├── Address : LineEdit
    ├── Host : Button
    ├── Join : Button
    ├── Leave : Button
    ├── Status : Label
    └── Peers : Label
```

Instance the network node from:

```text
res://modules/networking/network_handler.tscn
```

Set `Address.text` to:

```text
127.0.0.1
```

for the first local test.

## 2. Connect lifecycle signals

Attach a script to `NetworkLab`:

```gdscript
extends Control

const PORT := 42069

@onready var network: NucleusNetworkHandler = %Network


func _ready() -> void:
    network.state_changed.connect(_on_state_changed)
    network.peer_connected.connect(_on_peer_connected)
    network.peer_disconnected.connect(_on_peer_disconnected)
    network.connected_to_server.connect(_on_connected_to_server)
    network.connection_failed.connect(_on_connection_failed)
    network.server_disconnected.connect(_on_server_disconnected)
    network.start_failed.connect(_on_start_failed)

    %Host.pressed.connect(_host)
    %Join.pressed.connect(_join)
    %Leave.pressed.connect(_leave)
    _refresh_status()
```

## 3. Host

```gdscript
func _host() -> void:
    var error: Error = network.start_enet_server(
        PORT,
        8,
    )

    if error != OK:
        %Status.text = "Host failed: %s" % error_string(error)
        return

    _refresh_status()
```

A successfully created server enters `SERVER` state immediately.

## 4. Join

```gdscript
func _join() -> void:
    var error: Error = network.start_enet_client(
        %Address.text.strip_edges(),
        PORT,
    )

    if error != OK:
        %Status.text = "Client start failed: %s" % error_string(error)
        return

    _refresh_status()
```

The client first enters `CONNECTING`.

Do not treat the return value `OK` as "fully connected". Wait for:

```text
connected_to_server
```

which moves the handler to `CLIENT` state.

## 5. Leave

```gdscript
func _leave() -> void:
    network.shutdown()
    _refresh_status()
```

`shutdown()` closes the peer and restores `OfflineMultiplayerPeer`.

## 6. Display state

```gdscript
func _refresh_status() -> void:
    var state_name: String = NucleusNetworkTypes.State.keys()[network.state]
    var peer_id: int = network.get_unique_id()

    %Status.text = "State: %s | Peer ID: %d" % [
        state_name,
        peer_id,
    ]

    %Peers.text = "Peers: %s" % [
        str(network.get_connected_peers()),
    ]
```

## 7. React to signals

```gdscript
func _on_state_changed(_previous: int, _state: int) -> void:
    _refresh_status()


func _on_peer_connected(peer_id: int) -> void:
    print("Peer connected: ", peer_id)
    _refresh_status()


func _on_peer_disconnected(peer_id: int) -> void:
    print("Peer disconnected: ", peer_id)
    _refresh_status()


func _on_connected_to_server() -> void:
    print("Connected to server")
    _refresh_status()


func _on_connection_failed() -> void:
    %Status.text = "Connection failed"


func _on_server_disconnected() -> void:
    %Status.text = "Server disconnected"


func _on_start_failed(error: Error) -> void:
    print("Peer start failed: ", error_string(error))
```

## 8. Test with two instances

Use two running copies of the project.

A simple local workflow is:

1. run one copy and press **Host**;
2. run a second copy;
3. keep address `127.0.0.1` and press **Join**;
4. verify the host receives `peer_connected`;
5. verify the client reaches `CLIENT`;
6. press **Leave** on the client;
7. verify the host receives `peer_disconnected`;
8. leave the host and confirm both return to `OFFLINE`.

Use an exported/debug executable for the second copy if your editor workflow only
runs one game instance conveniently.

## 9. Test failure behavior

Run only a client and try to connect to `127.0.0.1:42069` with no server.

The important behavior is:

```text
CONNECTING
→ connection failure
→ peer closed
→ OfflineMultiplayerPeer restored
→ OFFLINE
```

This proves reconnection can start from a clean state.

## 10. Try WebSocket transport

On a native host:

```gdscript
network.start_websocket_server(PORT)
```

Client:

```gdscript
network.start_websocket_client(
    "ws://127.0.0.1:%d" % PORT
)
```

A browser build may be a WebSocket client, but the current Nucleus handler does
not allow browser/server startup.

## 11. Stop before you synchronize a Player

At this stage, networking is healthy if connection lifecycle is healthy.

Do not immediately write:

```text
client sets position
→ RPC to everyone
```

without first deciding authority.

The next learning step is:

```text
client input
→ intent
→ server validation
→ authoritative mutation
→ replication
```

Continue with:

[`../online_replication_quickstart.md`](../online_replication_quickstart.md)

## Common mistakes

- debugging player replication before basic connect/disconnect works;
- making `NetworkHandler` globally persistent without a session-lifetime reason;
- assuming client input is automatically trusted;
- assuming ENet and WebSocket are interchangeable on Web exports;
- hiding connection-state transitions from the UI.

## Technical contract

- [`../networking_quickstart.md`](../networking_quickstart.md)
- [`../../modules/networking.md`](../../modules/networking.md)
- [`../../modules/online_replication.md`](../../modules/online_replication.md)
