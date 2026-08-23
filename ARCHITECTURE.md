# Wizard of Words - Architecture Roadmap

This document is the implementation plan for growing the current vertical slice into a maintainable local and online game. `DESIGN.md` remains the product vision and feature backlog; this file owns module boundaries, sequencing, and technical acceptance criteria.

## Architectural goals

1. One authoritative, UI-free match engine serves hotseat, AI, replay, tests, listen-server, and dedicated-server play.
2. UI scenes render state and emit player intent. They do not validate moves, mutate scores, draw tiles, or advance turns directly.
3. A match is reproducible from its setup, seed, and ordered commands.
4. Networking transports commands and events rather than mirroring the UI scene tree.
5. Art layout data is explicit. A frame should never depend on a guessed percentage of its texture dimensions.

## Target project shape

```text
scenes/
  app.tscn
  screens/
    title_screen.tscn
    setup_screen.tscn
    game_screen.tscn
  components/
    board_shell.tscn
    board_view.tscn
    rack_view.tscn
    match_hud.tscn
    move_log_view.tscn
    blank_picker.tscn
    trade_dialog.tscn

scripts/
  core/
    match_config.gd
    match_state.gd
    match_engine.gd
    match_command.gd
    match_event.gd
    board.gd
    move_logic.gd
    ruleset.gd
    dictionary.gd
    tile_bag.gd
    match_serializer.gd
  application/
    app_controller.gd
    local_match_controller.gd
    remote_match_controller.gd
    replay_controller.gd
    ai_turn_service.gd
    preferences_store.gd
  network/
    protocol.gd
    multiplayer_transport.gd
    godot_transport.gd
    match_server.gd
    lobby_client.gd
  ui/
    title_screen.gd
    setup_screen.gd
    game_screen.gd
    board_shell.gd
    board_view.gd
    rack_view.gd
    match_hud.gd
  ai/
    ai_player.gd
  server/
    dedicated_server.gd
```

The exact filenames can evolve, but dependencies should only point inward:

```text
UI -> application controllers -> core
network -> application controllers -> core
AI -> core
dedicated server -> network + core
core -> no UI or networking
```

## Core match contract

`MatchState` owns all durable game state: board, bag, racks, scores, current player, pass count, revealed cells, turn number, seed, and game-over result.

`MatchEngine` is the only object allowed to mutate `MatchState`. It accepts typed commands such as:

- `PlaceTile`, `MovePendingTile`, `RecallTile`
- `CommitMove`, `TradeTiles`, `PassTurn`
- `ChooseBlankLetter`
- `StartMatch`

It returns typed events such as:

- `TilePlaced`, `TileRecalled`, `MoveRejected`
- `MoveCommitted`, `WordsScored`, `CellsRevealed`
- `TilesTraded`, `TurnAdvanced`, `MatchEnded`

Pending placement may remain client-side for responsiveness, but `CommitMove`, `TradeTiles`, and `PassTurn` are authoritative commands. The server revalidates every authoritative command.

Every committed command receives a monotonically increasing sequence number. `MatchSerializer` can save a full snapshot and encode/decode commands and events using protocol-safe dictionaries. This becomes the shared foundation for saved games, replay logs, reconnection, spectators, desync diagnosis, and automated simulations.

## Board and frame layout

The first extracted UI component should be `BoardShell`, because it addresses the current visual defect and establishes a clean seam in `main.gd`.

`BoardShell` contains:

```text
BoardShell (bounded square canvas)
  TextureRect (frame, aspect-covered)
  MarginContainer (catalog-derived frame insets)
    PanelContainer (board background)
      BoardView (centered grid)
```

Rules:

- The grid determines its natural content size from cell size, board dimensions, and grid gaps.
- Framed layouts use a bounded 800-pixel canvas and reduce cell size as needed to fit the artwork's real opening; the grid itself is never stretched.
- Each frame has independent left/top/right/bottom content ratios in `data/graphics/frames/index.json`. Do not calculate all four margins from one percentage.
- Insets are independently tunable because ornamental art is rarely symmetrical.
- `BoardShell` owns frame/background loading and sizing. `BoardView` knows only cells.
- Add a debug toggle that outlines the frame rect, content rect, and grid rect while tuning assets.

Rulesets may override catalog values when a skin needs custom alignment:

```json
{
  "frame": "res://data/graphics/frames/Ornate with runes.png",
  "frame_content_ratios": { "left": 0.16, "top": 0.18, "right": 0.16, "bottom": 0.19 },
  "background": "res://data/graphics/backgrounds/Parchment Background.png",
  "tiles": "res://data/graphics/raw tiles/Single Wizard Tile.png"
}
```

Ratios describe the artwork's inner opening after aspect-cover cropping. A later visual skin editor can expose them as four draggable guides.

### Progress (2026-08-23)

- Added asset-reference coverage for title art, ruleset skins, and the frame catalog.
- Added minimum-length cross-word regression coverage and corrected the validator.
- Extracted `BoardShell` and `BoardView` scenes/scripts from `main.gd`.
- Added per-frame content geometry and visually verified all four shipped frames at 1280x900.

## Online play model

Use an authoritative server model from the beginning of online work:

1. A client sends a command carrying match ID, player ID, expected sequence number, and command payload.
2. The server authenticates membership and turn ownership, validates the command through the same `MatchEngine` used locally, and assigns the next sequence number.
3. The server broadcasts accepted events or returns a rejection only to the sender.
4. Clients reduce those events into their local snapshot and update views.
5. On reconnect or sequence mismatch, the client requests a fresh snapshot followed by events newer than that snapshot.

Do not trust client scores, racks, bag order, word validity, fog reveals, clocks, or random results. The server owns the match seed and random-number state. A client may preview a score locally, but the server's result wins.

Start with direct-address or LAN rooms using Godot's high-level multiplayer API and an `ENetMultiplayerPeer`. Keep it behind `MultiplayerTransport` so a WebSocket transport can be added if a browser build becomes a target. Godot supports running an ordinary export headlessly or producing a dedicated-server export, so the server can reuse the same core without loading client art.

Protocol requirements before public testing:

- Integer `protocol_version` and ruleset schema version
- Stable command/event names and explicit payload validation
- Maximum payload sizes and per-peer rate limits
- Idempotency key for commands retried after connection loss
- Server-side turn timeouts and disconnect policy
- Snapshot checksum for desync detection
- Structured server logs with match ID and sequence number
- Compatibility policy: initially require identical client/server protocol versions

Accounts, email validation, matchmaking, ranked ratings, and persistent statistics should remain outside the match server. Add a small service boundary later for identity, lobby discovery, and match records; do not make the deterministic match engine depend on those services.

## Refactor sequence

### Phase 0 - Safety rails

- Add an asset-reference test covering title art and every ruleset skin path.
- Add regression tests for minimum-length cross-words and end-game scoring.
- Record several fixed-seed match fixtures before moving behavior.
- Establish version control and a repeatable headless test command.

Exit: existing behavior is protected and asset moves fail loudly.

### Phase 1 - Board presentation seam (FIRST SLICE COMPLETE)

- Extract `BoardShell` and `BoardView` from `_build_game_ui()`.
- Add explicit frame insets to skin metadata.
- Keep the current main script as the temporary controller.
- Verify 15x15 layouts at the minimum supported window size and at 16:9 resolutions.

Exit: every shipped frame hugs the board, and board rendering no longer lives in `main.gd`.

### Phase 2 - Screen and component extraction

- Convert title, setup, game HUD, rack, blank picker, and trade dialog into scenes.
- Replace direct calls into `main.gd` with intent signals and render/update methods.
- Move font, color, and button styling into a Godot Theme where practical.

Exit: `main.gd` is a small screen/application coordinator, not a UI factory.

Progress (2026-08-23): title, setup, game HUD, blank picker, and trade dialog are now signal-driven scenes. Shared styling and asset helpers live in `UiFactory`; rack rendering remains in the temporary match coordinator until the authoritative engine establishes its state/view contract.

### Phase 3 - Authoritative local engine

- Introduce `MatchConfig`, `MatchState`, `MatchEngine`, commands, and events.
- Move bag creation, turn progression, scoring application, trading, passing, fog reveal, and end-game handling out of the UI.
- Make hotseat and AI both drive the engine through commands.

Exit: a complete match can run headlessly without instantiating `main.tscn`.

Progress (2026-08-23): the first authoritative engine is complete. `MatchConfig` and `MatchState` serialize with schema versions and checksums; `MatchCommand` and `MatchEvent` provide protocol-versioned envelopes; `TileBag` owns seeded randomness; and `MatchEngine` now owns start, placement, pending movement/recall, commit/scoring, fog reveal, refill, rack order, pass, trade, turn advancement, and match-end mutations. `main.gd` is a compatibility adapter and UI/AI coordinator.

### Phase 4 - Serialization and replay

- Serialize snapshots, commands, and events with schema versions.
- Convert the current JSONL logger into a replayable event log.
- Add save/resume and deterministic replay tests.

Exit: replaying a match produces the same final checksum as the original.

### Phase 5 - AI boundary and performance

- Move AI turns behind `AiTurnService` so thinking never blocks frame rendering.
- Replace rack-only word filtering with anchor/cross-check generation that uses existing board letters.
- Give the AI only a read-only snapshot; submit its chosen move as a normal command.

Exit: the AI can find longer hooked plays, obeys a time budget, and cannot mutate match state directly.

### Phase 6 - Online vertical slice

- Implement `MultiplayerTransport`, `GodotTransport`, protocol encoding, and `MatchServer`.
- Support create/join by address, two players, commit/pass/trade, reconnect, and resign.
- Run two clients against a local headless dedicated server in an automated integration test.

Exit: a full remote match survives one client disconnecting and reconnecting without desync.

### Phase 7 - Hosted play

- Package a lean dedicated-server export.
- Add lobby discovery/invitations and deployment configuration.
- Add identity only when needed; guest/private-room play should precede ranked accounts.
- Add monitoring, match retention, abuse controls, and staged protocol rollout.

Exit: private remote games are operable and diagnosable in production.

## Testing layers

- Core unit tests: move validity, scoring, bag, turns, fog, end conditions
- Contract tests: command/event and snapshot round trips across schema versions
- Simulation tests: thousands of seeded AI matches checking invariants
- UI component tests: BoardShell geometry, rack interactions, dialogs
- Network integration tests: two clients plus headless server, reconnect, duplicate command, stale sequence
- Asset tests: every configured path exists and loads as the expected resource type

Critical invariants include conservation of tiles, one authoritative turn owner, strictly increasing event sequence numbers, no occupied-cell overwrite, server-only hidden information, and identical replay checksums.

## Immediate next implementation slice

Begin Phase 4 by making the existing match log replayable:

1. Write accepted command/event envelopes rather than presentation-only move summaries.
2. Add snapshot save/load with schema and protocol compatibility checks.
3. Add deterministic replay from the initial config/seed and accepted commands.
4. Compare final snapshot checksums between original and replayed matches.
5. Add a compact save/resume flow before introducing a network transport.

This turns the authoritative local engine into a durable protocol and proves the exact mechanism remote clients will later use to reconnect and repair desynchronization.

## Technical references

- Godot high-level multiplayer: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- Godot dedicated-server exports: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html
