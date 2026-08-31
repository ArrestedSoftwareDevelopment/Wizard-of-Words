# Effects and Online Two-Player Roadmap

Status: implementation plan, August 2026

This roadmap deliberately puts the foundational effects work before remote play. Both systems should consume the same canonical `MatchEvent` stream, but neither belongs inside the game rules. Once that seam exists, local play, AI play, replay, and remote play can all present the same match without duplicating behavior.

## The governing rule

The match engine owns facts. Presentation owns atmosphere.

The following are synchronized game facts:

- match configuration and deterministic seed;
- player identity and turn ownership;
- rack operations and tile locations;
- committed words, scores, bonus hits, passes, trades, and match results;
- event sequence and deterministic state checksum.

The following remain local:

- backdrop, animation, particles, screen treatment, and sound;
- commentary wording selected from a theme language pack;
- effect intensity, reduced-motion preference, and volume;
- hover, selection, drag previews, and other immediate interface feedback.

No network packet should ever say “play the purple smoke animation.” It should say that move 37 committed `MOONLIGHT` at these positions, with this bonus. The receiving program decides how its chosen theme makes that fact beautiful.

---

# Part I — Effects foundation

## E0. Establish one event-to-presentation bridge

Today `Main` applies a command, adopts the changed state, refreshes controls, writes commentary, and sometimes launches the AI. Effects must not add another branch to every one of those call sites.

Create a `MatchCoordinator` whose only responsibilities are:

1. submit a `MatchCommand` through the active transport;
2. accept a canonical command/event batch;
3. adopt the resulting `MatchState`;
4. emit one ordered `events_presented(events, context)` signal.

Local and AI games use a `LocalMatchTransport` that resolves immediately. Online games later substitute a `WebSocketMatchTransport`. `Main`, `ThemeLanguage`, `EffectDirector`, logging, and future replay recording all consume the coordinator's accepted events.

Required cleanup while making this seam:

- route pass, trade, placement, recall, shuffle, commit, and AI moves through the same submission path;
- attach an event index to each event in a batch;
- expose the pre-state and post-state checksums to diagnostics;
- add newly revealed fog cells to the committed event payload instead of making presentation compare entire states;
- provide stable rejection codes separately from friendly displayed errors;
- make `BoardView.cell_global_center(position)` available to effects.

### Effect identity and retry safety

Every presentation cue receives a stable identity:

`match_id : sequence : event_index : cue_id`

`EffectDirector` retains a small recently-played set. A duplicated network acknowledgment, retry, or restored command therefore cannot fire the same cannon, sparkle, or score burst twice. Loading a snapshot produces only a quiet resynchronization cue; it never replays historical fireworks.

### Acceptance gate E0

- Existing local and AI tests still pass through `LocalMatchTransport`.
- Every accepted command emits exactly one ordered event batch.
- Duplicate command acknowledgments do not duplicate commentary, logs, or effects.
- A headless test can feed recorded events to the presentation bridge without rendering.

### Progress (2026-08-31)

The first effects vertical slice is implemented. `EffectDirector` consumes ordered canonical event batches, assigns `match:sequence:event-index:cue` identities, suppresses duplicate cues, and applies Effects Off/Subtle/Full plus reduced-motion policy before presentation. A mouse-transparent `EffectLayer` provides atmosphere, board, and foreground canvases, with reusable vector-rendered settle, trace, score, pulse, bonus, and victory cues. All seven themes now load their cue palettes and vocabulary from `data/effects/`, and a headless fixture proves profile coverage, retry safety, ordered batch emission, settings behavior, and input transparency.

The remaining E0 work is deliberately explicit: extract `MatchCoordinator` and `LocalMatchTransport`, route commentary/logging through the accepted batch, attach newly revealed fog cells to commit payloads, and prove pre/post checksum diagnostics at that application boundary. The current slice establishes the presentation consumer without pretending the whole coordinator refactor is finished.

## E1. Add the effect layers

Add one mouse-transparent `EffectLayer` scene with three canvases:

1. **Atmosphere layer** — above the backdrop, below the board and HUD. Slow smoke, dust, stars, steam, and light.
2. **Board layer** — follows board geometry. Tile landings, word traces, bonus-square blooms, fog reveals, and score bursts.
3. **Foreground layer** — above the board and HUD. Reserved for brief match openings, victories, and exceptional full-board surges.

The foreground layer must never intercept clicks. It should also avoid obscuring the rack or score for more than a fraction of a second.

### Core reusable cue scenes

- `TileSettleCue`: scale/opacity settle for a newly placed rune.
- `WordTraceCue`: travels through committed tile centers in word order.
- `ScoreBurstCue`: compact `+N` display anchored near the word.
- `BoardPulseCue`: restrained shader or color pulse clipped to the board.
- `BonusBloomCue`: triggered once per bonus hit, not once per refresh.
- `FogRevealCue`: soft radial reveal around newly exposed cells.
- `PassCue`: subtle atmospheric response; never punishment-sized.
- `TradeCue`: rack/shelf motion and a brief bag response.
- `MatchEndCue`: a short, theme-specific victory tableau.
- `AmbientLoopCue`: low-opacity, pooled particles or a small looping flipbook.

Effects run asynchronously from game state. A move is committed before its animation begins. Only the human input layer may briefly lock during a major commit presentation, and the maximum lock should be configurable and under 700 ms.

## E2. Make effects data-driven

Each theme receives `data/effects/<theme_id>.json`. The effect director loads only the active theme and maps canonical event types to cue scenes and parameters.

Proposed profile shape:

```json
{
  "theme_id": "pirate",
  "atmosphere": {
    "scene": "res://scenes/effects/atmosphere/sea_haze.tscn",
    "density": 0.3,
    "opacity": 0.18
  },
  "cues": {
    "tile_placed": [{ "id": "rope_tick", "scene": "..." }],
    "move_committed": [{ "id": "compass_trace", "scene": "..." }],
    "theme_bonus": [{ "id": "coin_glint", "scene": "..." }],
    "match_ended": [{ "id": "colors_raised", "scene": "..." }]
  }
}
```

Profiles control color, duration, opacity, scale, particle count, sound key, and optional flipbook. They do not contain score values or change match state.

## E3. Theme effect direction

The current backgrounds are elegant, so effects should be punctuation rather than wallpaper.

| Theme | Ambient atmosphere | Tile/word movement | Bonus response | Victory moment |
|---|---|---|---|---|
| Wizardry | Violet/gold motes and faint candle smoke | Fine rune sparks and a calligraphic light trace | Ley-line ring with restrained arcane flare | Constellation sigil resolves above the board |
| Gothic Horror | Dust, candle smoke, occasional moving shadow | Ink-dark edge bloom and cold silver trace | Raven shadow or distant bell ripple | Darkness recedes toward a thin suggestion of dawn |
| Pirate | Sea haze and slow lantern sway | Rope-knot tick, compass trace, tiny cannon-smoke puff | Coin glints and a map-marked X | Colors rise while warm horizon light crosses the board |
| Space Age | Star drift, low holographic noise | Transporter snap and clean scanline path | Gravity-lens pulse or orbital ring | The board enters a brief, tasteful warp corridor |
| Kitchen Witchery | Steam, ember motes, drifting herb flecks | Spoon-stir spiral and warm tile settle | Cauldron glow with spice-colored sparks | Hearth flare and a curl of celebratory steam |
| Prairie Homestead | Sunlit dust, tiny pollen or seed motes | Thread stitch between letters, soft wooden settle | Prairie breeze with a few wildflower petals | Golden-hour light settles across the homestead |
| Velvet & Leather | Candle smoke, velvet shimmer, brass glints | Controlled ribbon/line motion and precise clasp tick | Deep burgundy pulse with a warm brass edge | Candles brighten into a composed closing tableau |

### Shared restraint rules

- No continuous screen shake.
- No rapid white full-screen flash.
- No effect may make a letter unreadable at decision time.
- Ambient opacity stays below 20% over interactive areas.
- Only the selected theme's runtime effect assets are loaded.
- Cap simultaneous transient cues and recycle them through a small node pool.

## E4. Green-screen and generated-animation pipeline

Generated animation is best used as short, locked-camera elements rather than full-screen video.

1. Generate 8–24 frames against one exact chroma-green matte, with no baked checkerboard and no changing camera.
2. Inspect the raw output before processing. Reject gradients, fake alpha, moving matte, and green reflections that engulf the subject.
3. Remove the background using OpenArt's background-removal tool or the local matte extractor.
4. Decontaminate green fringe, preserve semitransparent smoke, and verify premultiplied edges against black, white, and the actual board.
5. Normalize every frame to one stable bounding box and anchor.
6. Pack a power-of-two flipbook atlas, normally no larger than 2048×2048.
7. Test at actual board-cell size and full-screen size; artwork that only looks good enlarged is not a game asset.
8. Record prompt, model, generation date, processing steps, and final path in `data/graphics/PROMPTS.md`.

Use `AnimatedSprite2D` for authored sequences and `GPUParticles2D` for sparks, dust, stars, and trails. Godot also supports flipbook textures on particle systems, which is ideal for small smoke and ember variations.

### Performance budget

- 60 fps target at 1920×1080 on the current development machine.
- At most 12 transient cue nodes alive simultaneously.
- At most 3 visually dominant cues simultaneously.
- Under roughly 32 MB of additional loaded effect textures for the active theme.
- Ambient effects pause when the window is unfocused or reduced effects are selected.
- No per-frame image processing; matte extraction and atlas packing happen offline.

## E5. Accessibility and controls

Add three presentation settings, stored locally and excluded from `MatchConfig`:

- Effects: Off / Subtle / Full
- Reduced motion: Off / On
- Effect volume: 0–100%

Reduced motion replaces travel, zoom, shake, and large pulses with short opacity/color changes. Gameplay timing and remote readiness never depend on another player's effect setting.

### Effects completion gate

Effects are ready for online integration when:

- all seven themes have atmosphere, tile, committed-word, bonus, and victory cues;
- repeated events are idempotent;
- resize during a cue does not leave sprites stranded;
- changing theme/new game clears every old cue safely;
- local, AI, and replay-style event injection use the same director;
- effects-off and reduced-motion modes pass visual and headless tests;
- a 30-minute automated match does not show unbounded node or texture growth.

---

# Part II — Private online two-player

## N0. Scope and trust model

Version one is a private duel for two trusted people. It is not a public matchmaking service and does not need spectators, rankings, accounts, chat moderation, or horizontal scale.

Use a host-authoritative deterministic lockstep model:

- The host creates the room, chooses match settings, and is the only authority that accepts commands.
- The guest proposes commands.
- The host validates and applies each command, then broadcasts the canonical accepted command, derived event batch, new sequence, and gameplay checksum.
- The host applies the command once; the guest applies that same canonical command to identical seeded state. Both independently derive presentation from the accepted event batch.
- The relay coordinates two sockets and room membership. It does not know word rules, calculate scores, or manufacture effects.

This is exceptionally low traffic. A tile placement or drag is a small JSON message; backdrop and effect assets never cross the socket.

### Honest privacy boundary

Lockstep means both programs possess the deterministic bag and both racks even though the interface hides the opponent's rack. That is appropriate for a trusted private game, but it is not cheat-resistant. If the application ever becomes public, migrate to a fully authoritative server with player-redacted state views and server-owned draws.

## N1. Transport abstraction

Create a small transport contract independent of Godot's high-level RPC tree:

```text
MatchTransport
  connect(options)
  disconnect()
  send_envelope(dictionary)
  signal connected(session)
  signal envelope_received(dictionary)
  signal disconnected(reason)
  signal status_changed(status)
```

Implementations:

- `LocalMatchTransport`: immediate in-process authority; used by local and AI modes.
- `MemoryDuplexTransport`: two endpoints with controllable latency, duplication, dropping, and reordering; used by tests.
- `WebSocketMatchTransport`: production client using `WebSocketPeer`, `wss://`, regular polling, bounded buffers, and text JSON frames.

Avoid direct scene-tree RPCs. Explicit protocol envelopes are easier to version, test, log safely, relay through a tiny service, and replay.

## N2. Protocol envelopes

Every frame is an object with:

```json
{
  "protocol": 1,
  "type": "command_proposal",
  "room": "ABCD1234",
  "session": "random-session-id",
  "message_id": "unique-id",
  "payload": {}
}
```

Required message types:

### Connection and room setup

- `hello`: protocol version, application build, requested room, invite secret, display name.
- `room_joined`: assigned role (`host` or `guest`) and player index.
- `peer_status`: waiting, joined, disconnected, or reconnected.
- `match_offer`: complete normalized match configuration and compatibility fingerprints.
- `ready`: guest accepts and confirms local compatibility.
- `match_start`: canonical configuration, seed, match ID, and initial checksum.

### Gameplay

- `command_proposal`: guest command with expected sequence and idempotency key.
- `command_accepted`: canonical command, event batch, resulting sequence, and checksum.
- `command_rejected`: stable reason code, expected sequence, and optional friendly details.
- `snapshot_request`: last known sequence and checksum.
- `snapshot`: canonical state, sequence, and checksum.
- `leave`: graceful room departure.

WebSocket ping/pong maintains the connection at the transport level. A slower application heartbeat may update the visible connection indicator but must not spam the relay.

### Command flow

1. A client builds a command with its current expected sequence.
2. Host commands go directly to host authority; guest commands cross the relay as proposals.
3. The host verifies room role, player index, sequence, idempotency key, payload shape, and turn ownership.
4. The host applies the command exactly once.
5. The host broadcasts `command_accepted` to both clients.
6. The host presents the events it already derived; it does not reapply its own acknowledgment.
7. The guest applies the canonical command locally and compares derived events and checksum.
8. Both presentation bridges receive the accepted event batch.
9. Any mismatch freezes input and requests a snapshot.

Version one should use pessimistic interaction for synchronized actions: a guest tile lands definitively after host acknowledgment. With two humans and tiny messages this should feel immediate. Optimistic prediction and rollback are unnecessary complexity for a turn-based word game.

## N3. Compatibility and deterministic state

`MatchConfig` needs a schema upgrade before online play. Add:

- `match_id`;
- `theme_id`;
- selected bonus-vocabulary setting;
- normalized ruleset payload or ruleset fingerprint, not only a local file path;
- selected lexicon filenames plus SHA-256 fingerprints;
- application content/build fingerprint;
- protocol version independent of save schema version.

The guest must reject a match when rules, dictionary contents, or protocol are incompatible. Do not send a 170,000-word dictionary over the socket; verify identical local resources by fingerprint.

### Fix checksum canonicalization

The current state checksum serializes dictionaries in their existing insertion order and includes processed-command history. Before networking:

- create a canonical recursive serializer that sorts dictionary keys;
- sort every position/event array whose semantic order is otherwise unspecified;
- hash only gameplay state, configuration, RNG state, and the ordered command sequence;
- exclude local presentation, connection state, and the processed-command cache;
- add a two-engine test proving identical checksums after serialization round trips.

Keep processed idempotency keys in a bounded rolling window rather than allowing them to grow for the life of the match.

## N4. Reconnection and recovery

Version one recovery assumes the host application remains open.

- A reconnecting guest sends match ID, session token, sequence, and checksum.
- If sequence/checksum match, play resumes without a snapshot.
- If they differ, the host sends a snapshot and the guest atomically replaces local state.
- Snapshot replacement clears pending visual cues and plays one quiet resync effect.
- If the host disconnects, the guest displays “Host reconnecting” and preserves local state, but cannot advance the match.
- If both users close the application, the private room may expire; durable match persistence is a later option.

Persist a local recovery save after each accepted turn-ending command. Do not write after every rack reorder or hover. A recovery save contains protocol/config fingerprints so an incompatible build cannot silently resume it.

## N5. Relay deployment

Recommended production relay: one Cloudflare Worker routing each private room to a SQLite-backed Durable Object using the WebSocket Hibernation API.

Why it fits:

- one Durable Object naturally represents one two-person room;
- WebSocket connections remain attached while idle objects hibernate;
- turn-based games spend nearly all their time idle;
- the current free plan supports SQLite-backed Durable Objects and is vastly beyond this two-user traffic level;
- no router port forwarding or home IP exposure is required.

The relay should contain no Godot rules engine. Its responsibilities are limited to:

- create/join a room with a high-entropy invite secret;
- allow at most one host and one guest;
- attach role/session metadata to sockets;
- validate envelope shape, size, room, role, and allowed message direction;
- forward frames to the other peer;
- retain only minimal reconnect metadata;
- expire abandoned rooms promptly.

No external connector is needed through the effects work or local duplex networking. Deployment will require access to a Cloudflare account; the Cloudflare Codex plugin is optional convenience, since the relay can also be deployed manually with Wrangler.

### Relay safety limits

- `wss://` only in production.
- Invite secrets must be unguessable and excluded from logs.
- Maximum two active sockets per room.
- Maximum frame size around 64 KB; ordinary commands should be far smaller.
- Strict allowlist of message types and required fields.
- Per-room and per-IP connection/message rate limits.
- Reject binary/object deserialization; accept UTF-8 JSON only.
- Never evaluate remote code or use Godot's unsafe object-decoding options.
- Avoid logging rack contents, bag order, invite secrets, or full snapshots.

## N6. Online interface

Add an Online Duel choice without complicating local setup:

### Host flow

1. Choose Host Private Duel.
2. Select theme, rules, dictionaries, bonuses, and display name.
3. Receive a room code/invite secret with Copy button.
4. Wait for the guest and show compatibility status.
5. Start when both sides are ready.

### Guest flow

1. Choose Join Private Duel.
2. Paste room invite and enter display name.
3. Preview host settings.
4. Resolve any content mismatch before Ready becomes available.
5. Enter the same existing theme introduction and board transition.

### During play

- Small status jewel: Connected / Waiting / Reconnecting / Out of sync.
- Input disabled when it is not the local player's turn or while awaiting authority.
- Opponent pending letters appear from canonical placement events.
- A nonmodal reconnect overlay preserves the board underneath.
- New Game offers rematch with the same room or return to title.

## N7. Test ladder

### Protocol unit tests

- protocol and schema version rejection;
- malformed/oversized message rejection;
- wrong player and wrong turn rejection;
- stale sequence rejection;
- duplicate idempotency key returns the same accepted result;
- dictionary/ruleset fingerprint mismatch;
- canonical checksum stability across JSON round trips.

### Two-engine synchronization tests

Run host and guest states through `MemoryDuplexTransport`:

- placement, pending move, recall, blank choice, shuffle, reorder, trade, pass, and commit;
- bonus vocabulary and fog reveal;
- duplicate, delayed, dropped, and reordered frames;
- intentional checksum corruption followed by snapshot recovery;
- guest disconnect/reconnect at every command boundary;
- match completion and rematch.

After every accepted command, host and guest gameplay checksums must match.

### Presentation isolation tests

- Host effects Full, guest effects Off: state remains identical.
- Both clients use the host-selected canonical theme in version one, while keeping independent effect intensity, motion, and volume settings.
- Duplicate accepted frame does not replay commentary or effects.
- Snapshot recovery does not replay the move history.

### Relay integration tests

- exactly two clients can join;
- third client is rejected;
- wrong invite is rejected without revealing room existence;
- reconnect token restores the correct role;
- room expires after configured abandonment;
- hibernation wake preserves socket metadata;
- production TLS connection works from the Godot export.

## N8. Delivery phases

### Online Phase 1 — local architecture

- Extract `MatchCoordinator`.
- Add `LocalMatchTransport` and `MemoryDuplexTransport`.
- Route every current game mode through the coordinator.
- Canonicalize checksums and bound idempotency history.

**Gate:** all existing tests pass, plus two in-memory clients complete a match with identical checksums.

### Online Phase 2 — socket client and room UX

- Implement `WebSocketMatchTransport`.
- Add host/join/ready/status screens.
- Run against a local relay.
- Add snapshot recovery and local recovery saves.

**Gate:** two local application instances complete, disconnect, reconnect, and finish a match.

### Online Phase 3 — private deployment

- Implement and test the two-seat Durable Object relay.
- Deploy `wss://` endpoint.
- Add production secrets/configuration without committing credentials.
- Test from two separate networks and packaged builds.

**Gate:** a full private game survives ordinary internet latency and a forced reconnect without divergence.

### Online Phase 4 — polish, not scale

- Rematch flow.
- Better connection messages.
- Optional encrypted/persisted recovery snapshot.
- Latency metrics in a hidden diagnostics panel.
- Exportable sanitized protocol log for debugging.

Public matchmaking, accounts, spectators, server-side dictionaries, and anti-cheat remain explicitly out of scope.

---

# Recommended implementation order

1. Event/presentation bridge and local transport abstraction.
2. Reusable effect layer and core cues.
3. Seven restrained theme profiles.
4. Generated flipbook pipeline and selected hero effects.
5. Effects accessibility, soak testing, and completion gate.
6. Canonical checksum and in-memory two-client lockstep.
7. WebSocket transport and private-room interface.
8. Local relay, reconnection, and snapshot recovery.
9. Cloudflare private relay deployment.
10. Two-network acceptance test and rematch polish.

This order prevents effects from leaking into the protocol while ensuring the networking layer is built around the final event vocabulary. It also produces useful, testable milestones: the game becomes prettier before it becomes remote, and remote play reuses the exact command and event engine already proven locally.

## Technical references

- [Godot WebSocketPeer](https://docs.godotengine.org/en/stable/classes/class_websocketpeer.html)
- [Godot 2D particle systems](https://docs.godotengine.org/en/stable/tutorials/2d/particle_systems_2d.html)
- [Godot AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html)
- [Cloudflare Durable Objects WebSockets](https://developers.cloudflare.com/durable-objects/best-practices/websockets/)
- [Cloudflare Durable Objects pricing](https://developers.cloudflare.com/durable-objects/platform/pricing/)
