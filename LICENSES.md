# Asset & Data Licenses

Reminder ledger - review before any public release.

## Dictionaries (data/dictionaries/)

| File | Source | License |
|------|--------|---------|
| enable1.txt | ENABLE word list (Dvorak project / Alan Beale) | Public domain |
| tournament_american.txt, extended_american.txt, international_game.txt | Extracted from 12dicts 6.0.2 by Alan Beale (http://wordlist.aspell.net/12dicts/) | Freely usable; author requests acknowledgment in derived works |
| common_english.txt, arcane_lexicon.txt, acronyms.txt, profanity_blacklist.txt, two_letter_whitelist.txt | Curated in-house for Wizard of Words | Ours |

## Rulesets
- classic_grimoire.json bonus layout follows the traditional Scrabble board arrangement. "Scrabble" is a trademark of Hasbro; we use no trademarked assets, only the public knowledge of letter distributions and standard gameplay conventions. Re-verify before commercial release.
- Letter distributions mirror the public-domain standard English Scrabble distribution.

## Fonts / Art
- Glyph symbols (⛤ ☽ ☉ ☿ ♄) are standard Unicode characters; rendering depends on system fonts.
- Typefaces in data/typefaces/ (audited from user-supplied zips):

| Font | Verdict | Basis |
|------|---------|-------|
| Dumbledor-Thin.ttf, Dumbledor-Regular.ttf | USABLE (embedded) | 1001Fonts FFC license: commercial use OK; app embedding allowed; no modification/resale of font files |
| Mage.ttf, Magehunter.ttf | USABLE | Author Dieter Schumacher: private + commercial use free; never sell the font itself |
| bu-glenda-font.zip | CONDITIONAL - do not bundle | Commercial use allowed but author requests contact first (obosilo@aol.com) |
| boring-little-trick-or-treaters-font.zip | UNVERIFIED - do not bundle | "Freeware" tag only; personal-use likely |
| magic-school.zip, wizzta.zip | UNUSABLE - no license file | No provenance; contact authors or replace |

Before commercial release: re-verify each, keep license texts alongside files.

## Code
- All game code original to this project.
