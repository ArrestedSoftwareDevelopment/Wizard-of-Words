# Image Generation Prompts (Wizard of Words)

Recommended models on OpenArt: **Flux.1 (dev)** for clean, text-free game assets and coherent grids; **SDXL** (e.g. Juggernaut or DreamShaper) for painterly/stylized looks. Generate at the largest size available; we scale in-engine.

Current OpenArt production model: **GPT Image 2**, 2K PNG, medium quality unless an asset needs transparent edges or higher detail.

Universal negative prompt:
`letters, text, words, numbers, watermark, signature, tiles with symbols, game pieces, hands, fingers, person, perspective distortion, fisheye, blur, jpeg artifacts`

---

## 1. The Board (full-frame, no tiles) - the money shot
```
Top-down orthographic view of an empty fantasy word-game board, a perfect 15 by 15 square grid of empty cells filling the entire frame edge to edge, aged enchanted parchment inlaid in dark walnut and obsidian wood, thin gold-leaf grid lines, a faint glowing pentagram engraved in the exact center cell, a few cells etched with dim arcane sigil outlines, subtle vignette, candlelit ambiance, flat orthographic camera, perfectly symmetrical, crisp edges, high detail, board game asset
```
Tips: ask for "flat orthographic, no perspective" hard - most models want to add depth. Generate at 1:1 or 4:5. If the grid comes out warped, try "isometric-free, architectural plan view" or generate a seamless texture of single cells instead and let us tile it.

## 2. Blank rune-stone tiles (sprite sheet)
```
Sprite sheet of blank rectangular game tiles arranged in a neat 4 by 4 grid, polished deep purple runestone with engraved gold border trim, slightly beveled top face catching warm candlelight from upper left, empty faces with no letters or numbers, uniform size and spacing, dark neutral background, orthographic top-down view, stylized fantasy game asset, high detail
```
Variant swap ideas: `bone-white ivory tiles with violet engraving`, `obsidian with ember-orange cracks`, `pale birch wood with blue ink inlay`.

## 3. Title screen art (1024x1024+, leave lower third simple)
```
Epic fantasy illustration, two wizards facing each other across a floating stone board covered in glowing runes, streams of golden letters spiraling between them like comets, dark academia color palette of deep purple, midnight blue and antique gold, dramatic rim lighting, arcane sigils floating in the mist, painterly digital art, rich detail, composition leaves the bottom third relatively dark and uncluttered
```
The "bottom third uncluttered" clause is what keeps our buttons readable - keep it in every title variant.

## 4. Bonus glyph medallions (for future premium-cell art)
```
Set of six circular arcane medallion icons arranged in a grid, each etched with a single occult symbol: crescent moon, sun, pentagram, mercury sigil, saturn sigil, star, embossed antique gold on dark violet stone, consistent style and lighting, orthographic top-down, game icon asset sheet
```

## 5. Tile rack / shelf (UI element)
```
Ornate horizontal wooden shelf bracket carved with arcane runes, dark stained wood with gold inlay, front orthographic view, wide thin banner shape, transparent-friendly plain dark background, fantasy UI asset, high detail
```

---

## Canonical theme packs

Visual themes are reusable skins and do not define gameplay. Classic Grimoire and Spiral Sigil are rulesets, so they are not separate asset packs.

| Order | Theme | Asset ID | Backdrop status |
| --- | --- | --- | --- |
| 1 | Wizardry | `wizardry` | Accepted and downloaded (Arcane Codex v2-bright) |
| 2 | Gothic Horror | `gothic_horror` | Next |
| 3 | Pirate | `pirate` | Queued |
| 4 | Space Age | `space_age` | Queued |
| 5 | Kitchen Witchery | `kitchen_witchery` | Queued |
| 6 | Prairie Homestead | `prairie_homestead` | Queued |
| 7 | Velvet & Leather | `velvet_leather` | Queued |

Backdrop-wide constraints: 16:9 at 2K, bright enough to retain shadow detail, with a broad quiet center and lower-center area for the board and HUD. Decoration belongs at the edges and corners. Backdrops contain no board, grid, tiles, rack, UI, text, people, or logos.

Each pack uses four independent generations so the images remain directly usable rather than being cropped from a concept sheet:

1. `backdrop` - 16:9 environmental surface, subdued center, no board or interface.
2. `frame` - square top-down ornamental border with a large, clean central opening.
3. `tile` - square blank tile face, orthographic, no glyphs or text.
4. `rack` - wide front-facing shelf or holder on a plain removable background.

### Wizardry (Arcane Codex)

Deep violet wizard study, aged parchment and dark walnut, antique-gold filigree, restrained cyan and magenta magical glints, candlelit dark-academia atmosphere.

Generated backdrops:

- `backgrounds/generated/arcane_codex/Arcane Codex Backdrop v1-dark.png` - OpenArt history `JQykjlQwXwRMIAt9Jk5W`, GPT Image 2 text-to-image, 2304x1296 PNG.
- `backgrounds/generated/arcane_codex/Arcane Codex Backdrop v2-bright.png` - OpenArt history `9tEFfkqQ1EU8V3FHFXIA`, GPT Image 2 image-to-image lighting revision, 2304x1296 PNG. Current integration candidate.

### Gothic Horror

Elegant haunted Victorian library and crypt materials: charcoal stone, blackened carved oak, tarnished silver, dried crimson roses, smoky candlelight and cool moonlight. Frightening but refined; no gore, monsters, bodies, or faces.

### Pirate

Weathered captain's cabin: dark teak, sea charts, rope, brass navigation instruments, salt-worn canvas, lantern gold and stormy ocean-blue light.

### Space Age

Optimistic retro-futurist starship: brushed alloy, molded ivory panels, midnight-blue observation windows, luminous instrument accents, subtle stars and restrained nebula color.

### Kitchen Witchery

Welcoming enchanted cottage kitchen: worn butcher block, hammered copper cookware, drying herbs, apothecary jars, flour-dusted linen and warm hearth glow, with tiny restrained magical glints.

### Prairie Homestead

1870s American frontier homestead materials: honeyed pine, hand-pieced quilt geometry, pressed prairie wildflowers, blackened iron stove hardware, amber oil-lamp glow, wheat gold and dusty blue. No people, text, logos, or recognizable television imagery.

### Velvet & Leather

Tasteful consensual-adult BDSM-inspired luxury: black leather, oxblood velvet, quilted panels, brushed brass rings and buckles, candlelit shadows, elegant high-end boudoir craft. Non-explicit; no people, bodies, nudity, anatomy, sexual acts, text, or logos.
