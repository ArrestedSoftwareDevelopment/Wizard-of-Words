# Wizard of Words - Design Grimoire

Living design document. Wishlist items move down as they are implemented.

Implementation boundaries and the staged local/online refactor are tracked in `ARCHITECTURE.md`.

## Vision
A word-crafting duel where the board itself is alive: hidden magic blooms outward from played runes, discovered through play rather than read in advance.

## Art Direction: 8-Bit Wizard Retro
- Pixel-art tiles (crisp, nearest-neighbor filtering), chunky bitmap UI font
- Limited palette per ruleset ("palette swap" = free theme variants)
- Splash screen: animated title sigil, "PRESS START" pulse, wizard sprite casting letters
- CRT/scanline shader as toggle; chiptune SFX/music hooks
- Glow effects achieved retro-style: blinking outlines, palette-bright halos instead of smooth bloom
- Tile design (done): large rune + score hidden by default, fades in on mouseover; letter is the hero so swappable open typefaces (OFL: e.g. Press Start 2P, VT323, Silkscreen) can restyle whole tilesets via theme
- **Glyph notation** (done): bonuses use tarot/astrology glyphs, not Scrabble abbreviations — ☿ ♄ letter bonuses, ☽ ☉ word bonuses, ⛤ center pentagram; overridable per-ruleset via legend `glyph` field
- Board coordinates A–O / 1–15 (done) for cell references and replay logs

---

## Milestone 1 - Core Duel (DONE)
- 15x15 board, click-to-place tiles, blanks with rune picker
- Cross-word validation, premium scoring, bingo bonus, end penalties
- Hotseat + greedy AI opponent ("Word Wizard")
- Pluggable rulesets (`data/rulesets/*.json`) and dictionaries (`data/dictionaries/*.txt|json`)
- Title screen: Quick Play (last-used config via user://prefs.json) + Create; saved-game resume is a future addition
- Create/prefs screen: Grimoires column (left) vs Bonus Words column (right); per-file defaults from index.json; live board thumbnail
- Tile letters use bundled Dumbledor Regular; titles in Mage (both license-cleared)
- AI word-list awareness: only Archmage plays bonus/theme words; lower tiers stick to core vocabulary

## Milestone 2 - Bloom Board (IN PROGRESS)
The signature departure from Scrabble/WWF:

1. ~~Veiled cells~~ **Fog of War (done)**: `fog_of_war` + `fog_radius` ruleset fields; premiums hidden until revealed within N squares of played tiles; center area starts revealed
2. ~~Static layouts~~ **Spiral Sigil board (done)**: golden-angle gyre of arc-segment bonuses, 180° rotational symmetry, escalating multipliers toward the rim (`spiral_sigil.json`, fog enabled)
3. **Decay (optional)** - bonuses fade after N turns/N uses; prevents late-game saturation
4. **Guardrails** - no TW beside TW, min distance from center early, soft cap on active premiums
5. **Seeded randomness** - visible seed; shareable/replayable games ("Daily Sigil")
6. **Schema v2** - semi-random bloom growth config in ruleset JSON; static layouts remain supported
7. **Reveal styles** per ruleset: full fog / adjacent peek / hover peek

## Dictionary Variants (toggles in ruleset + UI)
- [x] Multi-grimoire merging (check several dictionaries, play against the union)
- [x] Custom word lists - any txt/json drops in
- [x] `min_word_length` (default 2) - the "three letter minimum" option
- [x] `allow_any_two_letter` - accept any 2-letter combo without lookup
- [x] `strict_two_letter` - "no two-letter jargon": 2-letter plays must be in `two_letter_whitelist.txt` even if a grimoire contains them (PI stays, PB/HZ-style junk dies)
- [x] Acronyms ship as their own opt-in grimoire (`acronyms.txt`) - include/exclude per game mode rather than a hard toggle
- [x] Dictionary description cards (`index.json`): title + pros/cons tooltip on each checkbox; also gates what ships in final release
- [ ] **Player's Grimoire**: personal dictionary starting blank; UI to inscribe words ("Add to my grimoire" from post-move banner + manage list screen); stored at `user://my_words.txt`; merges like any checked dictionary. Couples, friend groups, house-rules households put their own stamp on play. Future: share/export grimoires, per-profile when accounts land
- [ ] Proper nouns toggle - needs capitalized entries in dictionary format (`Paris` vs `paris`); loader keeps case when flag present
- [ ] Add-word UI ("inscribe thy own rune") writing to `custom_words.txt`
- [x] Better free dictionary: **ENABLE** (172k), **12dicts 6of12** (24k tournament-style), **2of12inf** (75k), **3of6game** (61k international) — all free-use; proper nouns stripped during extraction
- [ ] ODict (github.com/TheOpenDictionary/odict) - compiled lexical-entry format; candidate for a future "word definitions" lookup feature (GPL-3.0 toolchain, consume exported files only)

## Presentation Wishlist
- [ ] **Responsive board stage**: scale the frame, board, cells, tile faces, and rack together to consume the largest square available on the current display, leaving only a small safe-area border; derive cell size from the board stage rather than a fixed constant.
- **VFX plan (staged)**:
  1. *Commit burst*: particle puff + tile "settle" bounce when a rune lands (Godot Tween + CPUParticles2D)
  2. *Score float*: word score rises from the played line, gold for normal, theme color for surges
  3. *Bloom reveal*: fog cells unveil with a radial light sweep + chime
  4. *Surge resonance*: arcane/bonus words pulse the whole word in its theme color for 1s
  5. *Board ambience*: center pentagram slowly breathes; ley lines shimmer on T-squares
  6. *Screen shake* scaled to points (tiny at 10, chunky at bingo)
- **Art pipeline**: user-generated via OpenArt (Flux/SDXL); prompts in `data/graphics/PROMPTS.md`; title art lives in `data/graphics/title screens/`; board backgrounds live in `data/graphics/backgrounds/`; tile sheets live in `data/graphics/raw tiles/`
- **Audio**: Kenney assets purchased; hook chiptune SFX to commit/recall/trade/surge events
- Tile design: large rune + hover-fade details; swappable open typefaces via theme
- **Glow effects**: pulsing aura on bloom squares; rarity-colored halos (DL cyan, TL blue, DW violet, TW crimson); tiles emit light when part of a scored word
- Tile shapes/materials: rounded rune-stones, engraved letters, particle burst on commit
- Word-score popups floating from played words
- Board background: starfield sigil that subtly reacts to moves
- Screen shake / chime intensity scaled to points earned

### Theme production

Rulesets and themes are independent. **Classic Grimoire** and **Spiral Sigil** remain gameplay configurations; any ruleset can use any visual theme.

The seven canonical visual themes are:

1. **Wizardry** (`wizardry`) - violet wizard study, parchment, antique gold, luminous cyan/magenta sigils. The existing Arcane Codex artwork belongs here.
2. **Gothic Horror** (`gothic_horror`) - haunted Victorian library and crypt materials, blackened oak, tarnished silver, dried crimson roses, moonlight and smoky candles. Eerie and elegant, without gore.
3. **Pirate** (`pirate`) - weathered captain's cabin, nautical charts, dark teak, rope, brass instruments, salt-worn canvas and stormy blue light.
4. **Space Age** (`space_age`) - optimistic retro-futurist starship, brushed alloy, midnight-blue windows, luminous instrument accents and restrained cosmic color.
5. **Kitchen Witchery** (`kitchen_witchery`) - welcoming enchanted cottage kitchen, worn butcher block, copper cookware, herbs, apothecary jars and hearth glow. Existing kitchen tile art belongs here.
6. **Prairie Homestead** (`prairie_homestead`) - 1870s American frontier warmth: honeyed pine, hand-pieced quilt geometry, pressed wildflowers, iron stove hardware, amber lamplight, wheat and dusty blue accents. Period-inspired rather than tied to specific copyrighted characters or scenes.
7. **Velvet & Leather** (`velvet_leather`) - tasteful, consensual-adult BDSM-inspired luxury: black leather, oxblood velvet, brushed brass rings and buckles, quilted surfaces, candlelit shadows, elegant restraint. Non-explicit; no bodies, nudity, text, or sexual acts.

Backdrop production order is Wizardry, Gothic Horror, Pirate, Space Age, Kitchen Witchery, Prairie Homestead, then Velvet & Leather. Finish all seven backdrops before generating frames, tiles, racks, or premium ornaments so the overall visual range can be reviewed as one coherent set.

All seven backdrops are now approved and integrated. Runtime theme selection is independent of ruleset selection; the selected theme's bonus vocabulary is controlled by one **Theme Word Bonuses** switch.

All seven themes now have integrated tile faces. Wizardry, Gothic Horror, and Space Age use the strongest existing single-tile sources; Pirate, Kitchen Witchery, Prairie Homestead, and Velvet & Leather use new edge-to-edge generated textures. The same themed face is applied to board cells and rack letters. Every theme has been rendered at 1680x1050 to check repeated-grid calm, premium-glyph contrast, and rack readability. Prairie uses a restrained runtime tint to sit back into its warm backdrop. Rack-tray artwork and theme-specific action buttons remain the next supporting-art pass; two Wizardry rack drafts were rejected for unusable framing and were not added to the repository.

Starting a match now presents the selected backdrop as a cinematic title card before the board and HUD arrive. Each theme owns its title face and color in the theme catalog. Pirate uses Pirata One, Space Age uses Orbitron, Kitchen Witchery uses Berkshire Swash, and Prairie Homestead uses Rye; these four faces are bundled under the SIL Open Font License with their license files. Wizardry, Gothic Horror, and Velvet & Leather use the existing project display faces.

Premium squares now use theme-owned five-glyph atlases rather than shared Unicode symbols. Only atlas positions are common; every theme is free to use entirely different objects and silhouettes for double letter, triple letter, center, double word, and triple word. Hover text remains the authoritative accessible description of each multiplier. Generated atlases use a uniform pale production matte removed at render time, because the image generator did not provide genuine alpha even when requested.

Empty board cells render at 70% opacity over a transparent board backing, allowing roughly 30% of the environmental backdrop to show through. Premium glyphs, placed letters, pending letters, rack tiles, and all interaction text remain fully opaque.

All seven themes now have curated bonus lexicons. Prairie Homestead adds 60 frontier, homecraft, and handwork terms (+20); Velvet & Leather adds 58 consensual-adult kink and luxury-material terms (+25). Every entry in both sets is covered by the bundled base dictionaries, and asset tests enforce a nonempty, uppercase, duplicate-free theme lexicon.

Every production theme should provide a backdrop, blank tile face, rack/shelf, palette, and optional premium-cell ornament set. The full-screen backdrop is the primary decorative frame; the playable grid should use only a restrained bevel, rim light, or shadow so the board can scale freely without visual overload. Separate ornate board-frame artwork is optional, not a required theme asset. Source prompts and generation records live in `data/graphics/PROMPTS.md`.

## UX Upgrades
- [x] Drag-and-drop tiles (rack -> board, pending -> reposition)
- [ ] Drag pending tiles back to rack
- [ ] Placement ghost/preview showing cross-words formed before committing
- [ ] Keyboard input (type word + arrow placement)
- [ ] Zoom/pan for larger boards

### Flick Casting (proposed signature UX)
Fast word-casting alternatives to tile-by-tile placement:
1. **Direction drag** - on an empty board, drag across the center star horizontally/vertically to declare word axis.
2. **Flick** - flick rack tiles toward the board in order; they fly into position without manual cell targeting. Letters already on the board are auto-skipped (matched in place); blanks pop the rune picker mid-flight.
3. **Ordered runes mode (accessibility option)** - click rack tiles in order (they show rank numbers 1..n), then tap only the starting cell. Same auto-skip logic for existing letters.
4. Both modes reuse the validator; mis-ordered flicks bounce back with feedback.

## Platform & Architecture
- **Modularity**: core sim (board/rules/validation/scoring) stays UI-free and headless-runnable; presentation, AI, and net layers consume it via signals. Ruleset/dictionary plugins stay pure data.
- **Two-player local**: hotseat (done).
- **Two-player online**: Godot high-level multiplayer (ENet/WebSocket); authoritative host or lightweight dedicated server running the headless core; deterministic seeded bloom keeps boards in sync cheaply. Reconnect + spectator mode later.
- **Accounts & email validation**: registration with email verification link (expiring token), password reset; backend service issues JWT/session tokens; game client stores only session, never credentials. Required before ranked/online leaderboards.

## Identity & Caster Classes
Foundation for expansion "every upward" - players are characters, not just scoreboards:
- **Preferences / Ruleset Forge page**: dedicated screen where players build a custom ruleset via toggles (fog on/off + radius, strict two-letter, min word length, bingo size, bag multiplier, difficulty) and save it as their own `my_ruleset.json` - appears in the normal ruleset dropdown
- **Player naming** at setup (persisted per profile once accounts exist)
- **Caster Class / Alignment** picker: pulldown of preset classes (e.g., Alchemist, Oracle, Runesmith, Necrologist...) **plus** a free-text box for custom declarations ("Archon of Toast")
- Classes start as flavor (name plate, color accent, taunt flavor) - the sticky depth comes from identity, mechanics can layer on later
- Future mechanical hooks per class (data-driven in rulesets): bonus affinity (+word vs +letter glyphs), bloom bias (your plays seed your glyph types), bag luck modifiers, unique one-shot powers
- Ties directly into accounts/online: identity travels with you

## Archon-Inspired Ideas (logged)
From the "sneaking Archon feeling":
- **Asymmetric casters**: light/dark or class-vs-class duels where each side bends the board differently
- **Power Node contest**: glyph clusters become capturable territory; controlling blooms grants ongoing income or one-shot powers - victory by points OR by board domination
- Duel intros/outros: wizard avatars posturing before the duel (8-bit portrait art fits perfectly)

## Variants
- **Rune Race (online)** - no turns; both players spell simultaneously on the shared board. Cells are claimed the instant a rune lands (first-come server authority); words must still connect to existing runes. Design questions to solve:
  - Contention: contested cells resolved by latency = frustration; consider soft-lock (cell reserved while you hold letters on it, N-second commit window) or no-overlap zones
  - Balance: cooldown/mana meter per word cast so one fast typist can't carpet-bomb the board
  - Scoring: per-word instant bank + bonus for intercepting (completing/capping an opponent's open line?)
  - Bloom synergy is huge here: the board grows chaotically mid-race, fog reveals become power plays
  - Natural fit for the seeded bloom board - spectators see spells erupt in real time

## Match Structure & Bag Options
- **Letter Bag size** (ruleset): scale the whole distribution (`bag_multiplier`) or set an absolute tile count with proportional sampling; smaller bags = tighter, higher-variance games; huge bags = long engine-style grinds
- **Rounds** (ruleset/setup): play a "game set" of N rounds; per-round board reset (fresh bloom seed), running match score = sum or best-of; round intermission screen with stats
- Round variants to consider: rotating rulesets per round (round 1 classic, round 2 arcane), escalating bag scarcity per round

## Game Statistics (for nerdy users)
Per-player lifetime + per-session:
- High score, best single word, longest word, most words in one move
- Win/loss record vs humans/Wizard, per-ruleset breakdowns
- Bingo count, blank usage efficiency, average points per move
- Tile luck metrics: rack vowel/consonant distribution vs bag expectation ("the bag hates you" meter)
- Bloom board stats: bonuses discovered/farmed/decayed unused
- Stored as local JSON (`user://stats.json`); syncs to account when online exists
- Post-game summary screen + exportable match log

## AI Roadmap
- [x] Difficulty tiers: Apprentice (random valid move) / Adept (greedy, default) / Archmage (deep search budgets) — selectable in setup
- Wizard personalities: taunt lines reacting to player moves
- Exchange-tile strategy instead of always passing

## Known Quirks / Backlog
- Investigate any remaining invalid-move reports (likely wrong-grimoire selection; multi-merge should resolve)
- Long dictionaries (100k+) need fast-load + prefix pruning once Bloom generator ships
- Exported builds: `DirAccess` listing of res:// requires export filters for *.json/*.txt
