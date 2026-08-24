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
| 2 | Gothic Horror | `gothic_horror` | Accepted and downloaded |
| 3 | Pirate | `pirate` | Accepted and downloaded |
| 4 | Space Age | `space_age` | Accepted and downloaded |
| 5 | Kitchen Witchery | `kitchen_witchery` | Accepted and downloaded |
| 6 | Prairie Homestead | `prairie_homestead` | Accepted and downloaded |
| 7 | Velvet & Leather | `velvet_leather` | Accepted and downloaded |

Backdrop-wide constraints: 16:9 at 2K, bright enough to retain shadow detail, with a broad quiet center and lower-center area for the board and HUD. Decoration belongs at the edges and corners. Backdrops contain no board, grid, tiles, rack, UI, text, people, or logos.

Each pack uses independent generations so the images remain directly usable rather than being cropped from a concept sheet:

1. `backdrop` - 16:9 environmental surface, subdued center, no board or interface.
2. `tile` - square blank tile face, orthographic, no glyphs or text.
3. `rack` - wide front-facing shelf or holder on a plain removable background.

The backdrop supplies the full-screen environmental framing. Runtime board treatment should be limited to a subtle bevel, rim light, or shadow. Generate a separate ornate frame only if a specific theme proves to need one after integration.

### Wizardry (Arcane Codex)

Deep violet wizard study, aged parchment and dark walnut, antique-gold filigree, restrained cyan and magenta magical glints, candlelit dark-academia atmosphere.

Generated backdrops:

- `backgrounds/generated/arcane_codex/Arcane Codex Backdrop v1-dark.png` - OpenArt history `JQykjlQwXwRMIAt9Jk5W`, GPT Image 2 text-to-image, 2304x1296 PNG.
- `backgrounds/generated/arcane_codex/Arcane Codex Backdrop v2-bright.png` - OpenArt history `9tEFfkqQ1EU8V3FHFXIA`, GPT Image 2 image-to-image lighting revision, 2304x1296 PNG. Current integration candidate.

Generated premium glyphs:

- `glyphs/generated/wizardry/Wizardry Glyph Atlas v1.png` - Codex built-in image generation, 1536x1024 opaque PNG arranged as a strict 3x2 atlas: double letter, triple letter, center, double word, triple word, empty. Antique brass, amethyst and celestial geometry. The generator twice represented transparency as a baked pale checkerboard; runtime neutral-background extraction is therefore applied by `shaders/glyph_alpha.gdshader` and must be checked at final cell size.

Final glyph prompt summary: five coordinated Wizardry premium-square emblems in a strict 3x2 atlas with the sixth cell empty; circular double/triple letter seals with two/three amethyst accents; eight-point center star; diamond double/triple word crests with two crescent or three sun accents; engraved antique brass and restrained amethyst; broad 48-pixel-readable silhouettes; no text, numbers, tiles, panels or extra symbols. The extraction revision requested that only the checkerboard be removed while preserving the five emblems and atlas layout.

### Gothic Horror

Elegant haunted Victorian library and crypt materials: charcoal stone, blackened carved oak, tarnished silver, dried crimson roses, smoky candlelight and cool moonlight. Frightening but refined; no gore, monsters, bodies, or faces.

Generated backdrops:

- `backgrounds/generated/gothic_horror/Gothic Horror Backdrop v1.png` - OpenArt history `EInqkIfCufr2QefwHhd1`, GPT Image 2 text-to-image, 2304x1296 PNG. Accepted.

Final prompt summary: full-screen premium painterly game backdrop; elegant haunted Victorian library merging into crypt architecture; charcoal stone, carved black oak, tarnished silver, dried crimson roses, candles and moonlight; open midtone shadows; broad uncluttered center/lower center; decoration at edges; no board, tiles, UI, text, figures, monsters, or gore.

### Pirate

Weathered captain's cabin: dark teak, sea charts, rope, brass navigation instruments, salt-worn canvas, lantern gold and stormy ocean-blue light.

Generated backdrops:

- `backgrounds/generated/pirate/Pirate Backdrop v1.png` - OpenArt history `Kk5uVWW59C7cNS2l6ZJY`, GPT Image 2 text-to-image, 2304x1296 PNG. Accepted.

Generated tiles:

- `tiles/generated/pirate/Pirate Tile v2.png` - Codex built-in image generation, 1254x1254 opaque PNG. Dark salt-worn teak, warm parchment inset, thin antique-brass line and four pinheads; hard square corners with teak covering every image edge. Accepted after rejecting a rounded v1 with baked black corner background.

Final tile prompt summary: seamless full-bleed blank Pirate tile repeated across a 15x15 grid; calm aged-parchment center covering at least 82%; dark salt-worn teak border, thin antique-brass inset and four small pinheads; hard square corners with brown teak in all literal corner pixels; no nautical emblems, text, background, checkerboard, or multiple tiles.

Final prompt summary: full-screen premium painterly pirate captain's cabin; dark teak, salt-worn canvas, rope, charts, brass instruments and lanterns; storm-blue sea through stern windows; bright open midtones; broad uncluttered plank center; props at edges; no central table, board, tiles, UI, readable text, figures, skeletons, or violence.

### Space Age

Optimistic retro-futurist starship: brushed alloy, molded ivory panels, midnight-blue observation windows, luminous instrument accents, subtle stars and restrained nebula color.

Generated backdrops:

- `backgrounds/generated/space_age/Space Age Backdrop v1.png` - OpenArt history `k3V0xhk5Tuwcjre5YvTg`, GPT Image 2 text-to-image, 2304x1296 PNG. Accepted.

Final prompt summary: full-screen premium painterly retro-futurist observation lounge; curved warm-ivory architecture, brushed alloy, restrained cyan/amber lights, starfield, nebula and ringed planet; bright pearlescent illumination; broad uncluttered floor center; details at edges; no central table, board, tiles, UI text, figures, robots, weapons, or combat.

### Kitchen Witchery

Welcoming enchanted cottage kitchen: worn butcher block, hammered copper cookware, drying herbs, apothecary jars, flour-dusted linen and warm hearth glow, with tiny restrained magical glints.

Generated backdrops:

- `backgrounds/generated/kitchen_witchery/Kitchen Witchery Backdrop v1.png` - OpenArt history `Jh7odoMi7f1OF4CvBPhl`, GPT Image 2 text-to-image, 2304x1296 PNG. Accepted.

Generated tiles:

- `tiles/generated/kitchen_witchery/Kitchen Witchery Tile v2.png` - Codex built-in image generation, 1254x1254 opaque PNG. Muted herb-green glazed ceramic, worn butcher-block bevel, thin copper inset and four copper pinheads; hard square corners with wood covering every image edge. Accepted.

Final tile prompt summary: seamless full-bleed blank Kitchen Witchery tile repeated across a 15x15 grid; calm deep herb-green ceramic center covering at least 82%; honey-brown butcher-block border, thin hammered-copper line and four pinheads; hard square corners; no herbs, cookware, food, text, background, checkerboard, or multiple tiles.

Final prompt summary: full-screen premium painterly enchanted cottage kitchen; honeyed wood, cream plaster, copper cookware, herbs, unlabeled jars, linen, morning light and hearth glow; broad immaculate butcher-block center; details at edges; no board, tiles, UI, text, figures, animals, brands, or copyrighted characters.

### Prairie Homestead

1870s American frontier homestead materials: honeyed pine, hand-pieced quilt geometry, pressed prairie wildflowers, blackened iron stove hardware, amber oil-lamp glow, wheat gold and dusty blue. No people, text, logos, or recognizable television imagery.

Generated backdrops:

- `backgrounds/generated/prairie_homestead/Prairie Homestead Backdrop v1.png` - OpenArt history `TKv8RueCuEH30uToEcGI`, GPT Image 2 text-to-image, 2304x1296 PNG. Accepted.

Generated tiles:

- `tiles/generated/prairie_homestead/Prairie Homestead Tile v2.png` - Codex built-in image generation, 1254x1254 opaque PNG. Restrained honeyed maple with a single dusty-blue inset and four wheat-gold corner diamonds; exact orthographic square with artwork extending to every image edge. Accepted after rejecting two fake-transparency variants and an overly busy quilt-border v1.

Final tile prompt summary: seamless edge-to-edge blank Prairie letter tile repeated across a 15x15 grid; calm medium honeyed maple center covering at least 82%; one narrow dusty-blue inset and exactly four tiny wheat-gold corner diamonds; no repeated edge motifs; exact front orthographic view; opaque full-canvas texture; no surrounding background, checkerboard, text, glyphs, scenery, or multiple tiles.

Final prompt summary: full-screen premium painterly 1870s frontier homestead; honeyed pine, iron cookstove, cream crockery, quilts, wildflowers, oil lamps and prairie windows; soft late-afternoon light; broad uncluttered pine center; no board, tiles, UI, text, figures, modern objects, brands, or recognizable copyrighted sets.

### Velvet & Leather

Tasteful consensual-adult BDSM-inspired luxury: black leather, oxblood velvet, quilted panels, brushed brass rings and buckles, candlelit shadows, elegant high-end boudoir craft. Non-explicit; no people, bodies, nudity, anatomy, sexual acts, text, or logos.

Generated backdrops:

- `backgrounds/generated/velvet_leather/Velvet and Leather Backdrop v1.png` - OpenArt history `ato1lIYir6WVefC4RS4a`, GPT Image 2 text-to-image, 2304x1296 PNG. Accepted.

Generated tiles:

- `tiles/generated/velvet_leather/Velvet and Leather Tile v1.png` - Codex built-in image generation, 1254x1254 opaque PNG. Oxblood velvet, matte black leather and aged brass; exact orthographic square with artwork extending to every image edge. Accepted after rejecting a fake-transparency variant.

Final tile prompt summary: seamless edge-to-edge blank Velvet & Leather letter tile; oxblood velvet inset, matte black leather, restrained aged-brass frame and four studs; exact front orthographic view; open candlelit midtones; opaque full-canvas texture; no surrounding background, checkerboard, text, bodies, explicit objects, or multiple tiles.

Final prompt summary: full-screen premium painterly consensual-adult kink-inspired private salon; oxblood velvet, matte black leather, mahogany, brass rings and buckles, decorative ropework, chains, candles and smoked mirrors; bright open center; no board, tiles, UI, text, people, anatomy, activity, violence, or explicit objects.

## Premium Glyph Atlas Pass

All final atlases were produced with Codex built-in image generation at 1536x1024. They use a strict 3x2 placement grid (`d`, `t`, `*` / `D`, `T`, empty) solely for runtime slicing. The objects and silhouettes are intentionally unconstrained between themes. The requested transparency was not genuine, so final production prompts use a uniform white matte removed by the runtime glyph shader.

- `glyphs/generated/gothic_horror/Gothic Horror Glyph Atlas v2.png` - crossed raven feathers, three-candle candelabrum, cathedral rose window, paired moonlit lancets, and thorned three-drop reliquary. Accepted. An earlier matching-medallion draft was rejected.
- `glyphs/generated/pirate/Pirate Glyph Atlas v2.png` - crossed marlinspikes, three-coin tricorn, captain's compass rose, paired charts with divider, and ship's wheel with three pennants. Accepted. An earlier matching-medallion draft was rejected.
- `glyphs/generated/space_age/Space Age Glyph Atlas v1.png` - orbital gyroscope, triangular three-lens scanner, stellar reactor core, paired-planet hologram, and three-fin hyperspace beacon. Accepted for board validation.
- `glyphs/generated/kitchen_witchery/Kitchen Witchery Glyph Atlas v1.png` - crossed spoons with rosemary, three-steam green kettle, copper flame rosette, paired herb measures, and three-flame hearth cauldron. Accepted for board validation.
- `glyphs/generated/prairie_homestead/Prairie Homestead Glyph Atlas v1.png` - knitting needles and indigo yarn, wheat horseshoe, painted barn star, paired wheat sheaves, and stitched flying-geese quilt block. Accepted for board validation.
- `glyphs/generated/velvet_leather/Velvet and Leather Glyph Atlas v1.png` - linked leather cuffs, three-strand silk knot, garnet starburst, paired roses, and three-ring leather lattice. Accepted for board validation; objects only, non-explicit.

The original atlas files above are retained as design sources. Their baked white/checker mattes and unequal object bounds are not used at runtime. `tools/extract_neutral_matte.gd` now removes only connected neutral matte components—preserving pale enamel, parchment, linen, and enclosed highlights—then decontaminates the cutout edge. `tools/normalize_pictograph_atlas.gd` fits every object to a common 370-pixel maximum extent and centers it in an exact 512x512 cell.

Runtime atlases produced by that deterministic pipeline:

- `glyphs/generated/wizardry/Wizardry Pictograph Atlas v2.png`
- `glyphs/generated/gothic_horror/Gothic Horror Pictograph Atlas v3.png`
- `glyphs/generated/pirate/Pirate Pictograph Atlas v3.png`
- `glyphs/generated/space_age/Space Age Pictograph Atlas v2.png`
- `glyphs/generated/kitchen_witchery/Kitchen Witchery Pictograph Atlas v2.png`
- `glyphs/generated/prairie_homestead/Prairie Homestead Pictograph Atlas v2.png`
- The hand-authored `Velvet and Leather Pictograph Atlas v2.svg` was rejected after live testing: its simplified redraws became crude heavy shapes at board size and did not preserve the quality of the generated design. It has been removed from the runtime assets.
- `glyphs/generated/velvet_leather/Velvet and Leather Pictograph Atlas v3 source.png` - built-in image generation design source, 1536x1024 opaque PNG. Five refined, simplified oxblood-and-gold pictographs in a strict 3x2 atlas. Its checkerboard was baked into the RGB pixels, so it is retained only as the reproducible source for matte extraction and is not loaded at runtime.
- `glyphs/generated/velvet_leather/Velvet and Leather Pictograph Atlas v3.png` - the v3 source processed by `tools/extract_neutral_matte.gd`, then optically normalized by `tools/normalize_pictograph_atlas.gd`. Preserves the generated artwork while replacing the pale checker with genuine alpha, decontaminating its antialiased edges, equalizing its five symbol bounds, and centering each symbol in an exact 512x512 cell. This is the runtime Velvet & Leather atlas and bypasses the legacy matte-removal shader.
- `glyphs/generated/velvet_leather/Velvet and Leather Pictograph Atlas v4.png` - the original v1 black-leather, garnet, oxblood-silk, rose, and quilted-plaque artwork reprocessed through the final connected-matte and optical-normalization pipeline. Replaces the stylistically incongruous v3 runtime atlas while retaining true alpha and exact centers.

Final prompt pattern: five completely different theme-native artifacts, centered with equal padding in the five occupied cells of an exact 1536x1024 3x2 atlas; distinct silhouettes with no shared ornamental frames; broad and crisp at 48 pixels; flat uniform white production matte; no text, numbers, labels, people, tile faces, extra objects, checkerboard, or watermark. Each theme prompt specified the five objects and materials listed above.
