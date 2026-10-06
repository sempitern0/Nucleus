# Iteration 32 — Multiplayer Production Path

## Goal

Turn the existing Networking + Online Replication contracts into a practical
path from the first local multiplayer connection to a deployable authoritative
server.

This iteration is primarily documentation and production guidance. The review
did not justify replacing Godot networking or adding another global
`NetworkManager` abstraction.

Prepared as a cumulative delta on top of:

```text
main
ddd9652e67f7571487d4b5c644518f1b0038a528
```

The package also contains Iterations 30 and 31 because those development-tool
iterations are not assumed to be present in the baseline checkout.

## Review conclusion

The existing ownership split remains sound:

```text
NucleusNetworkHandler
    peer/transport lifecycle

Godot MultiplayerSpawner / MultiplayerSynchronizer / RPC
    native replication primitives

Nucleus online replication helpers
    intent admission + transform interpolation

game
    authority policy, auth, matchmaking, persistence and deployment
```

No generic NAT traversal, relay, authentication backend, matchmaking service or
container orchestrator was added.

## Delivered

### Production networking tutorial

`docs/guides/tutorials/networking.md` now follows one project through:

```text
localhost
LAN
Internet listen server
NAT / CGNAT decision
server-authoritative gameplay
dedicated local headless process
dedicated Linux export
public VM deployment
firewall
systemd
authentication boundary
monitoring
capacity and cost
```

### Deployment and cost guide

`docs/guides/multiplayer_deployment_quickstart.md` provides:

```text
current entry-level VM price examples
bandwidth estimation formula
server sizing guidance
firewall baseline
service supervision
secret/storage boundaries
scaling decision points
prototype budget examples
```

Pricing is explicitly dated so it is not mistaken for a stable API contract.

### Game-owned server bootstrap example

```text
examples/networking/authoritative_server_bootstrap.gd
examples/networking/nucleus-server.service.example
examples/networking/server.env.example
```

The bootstrap uses:

```text
OS.has_feature("dedicated_server")
OR
--server from OS.get_cmdline_user_args()
```

instead of blindly treating every headless run as a production server.

This matters because Nucleus itself uses headless Godot for imports, parsing,
tests and CI.

## Topology terminology

The documentation now distinguishes:

```text
listen server
    player host is also the authority

provider P2P / relay
    provider-specific connectivity path

dedicated authoritative server
    standalone public authority process
```

The localhost Host / Join lab is therefore described accurately as the first
listen-server topology, not as symmetric peer-to-peer simulation.

## Cost principle

The iteration intentionally recommends one boring Linux VM before any fleet or
orchestration layer.

The first useful capacity equation is based on evidence:

```text
measured server CPU/RAM
measured outbound kbps per player
average concurrency
matches/worlds per process
```

Only then should a project choose stronger instances, more processes, multiple
regions, autoscaling or orchestration.

## Security principle

A reachable socket is not an admitted player and an RPC is not authorization.

Public servers still require game/provider policy for:

```text
identity
authentication/session admission
build/protocol compatibility
semantic validation
secret handling
persistence authorization
moderation/abuse response
```

The Nucleus rate limiter is documented as admission hygiene, not DDoS
protection.

## Version

This iteration does not add a new public Nucleus runtime abstraction, so the
package keeps:

```text
0.12.0-dev.1
```

## Validation

The iteration modifies documentation and adds a game-owned example script.
Static source conventions should be run after applying the package.

Runtime acceptance remains the normal Nucleus gate:

```text
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py

godot --headless --path . --import
godot --headless --path . --check-only --script res://tests/headless/test_runner.gd
godot --headless --path . --script res://tests/headless/test_runner.gd
```

The networking tutorial additionally requires manual multi-process/network
testing because a headless unit test cannot prove router, NAT, firewall or real
latency behavior.
