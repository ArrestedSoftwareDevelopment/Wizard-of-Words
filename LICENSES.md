# Asset & Data Licenses

Provenance ledger. Re-check upstream notices before a public or commercial release.

## Dictionaries (data/dictionaries/)

| File | Source | License |
|------|--------|---------|
| enable1.txt | ENABLE2K / Alan Beale ([source notice](https://github.com/BartMassey/wordlists/blob/main/README-enable2k.txt)) | Explicitly released to the public domain; source credit requested |
| tournament_american.txt | 12dicts 6.0.2 `6of12` family / Alan Beale ([official readme](https://wordlist.aspell.net/12dicts-readme/)) | Public domain; acknowledgment requested |
| extended_american.txt | 12dicts 6.0.2 `2of12inf` family / Alan Beale | Alan Beale imposes no added restriction, but the upstream AGID-derived inflection material carries its own notices; retain the complete 12dicts/AGID notices when redistributing |
| international_game.txt | 12dicts 6.0.2 international game family / Alan Beale | Public domain components; acknowledgment requested; retain the upstream readme with redistributed derivatives |
| given_names.txt | Project curation sampled across eras from [U.S. Social Security published name rankings](https://www.ssa.gov/oact/babynames/) | U.S. government factual data; project selection and normalization are ours |
| african_american_english.txt | Project curation, informed by the [Yale Grammatical Diversity Project](https://ygdp.yale.edu/african-american-language-and-grammatical-diversity-2020) | Project-authored sampler; no external glossary copied |
| brands_trademarks.txt, proper_nouns_reference.txt | Project-curated factual reference terms; [USPTO public data](https://www.uspto.gov/trademarks/apply/check-status-view-documents/trademark-bulk-data) is a verification reference | Project curation; trademarks remain property of their respective owners; inclusion is not a registration or ownership claim |
| common_english.txt, acronyms.txt, profanity_blacklist.txt, slur_blacklist.txt, two_letter_whitelist.txt | Curated in-house for Wizard of Words | Project-authored data |
| tech_jargon.txt, science_jargon.txt | Curated in-house for Wizard of Words | Project-authored data |
| spanish_starter.txt, french_starter.txt, italian_starter.txt | Curated in-house; limited to current A-Z board representation | Project-authored data; individual words are facts, no external compilation copied |
| arcane_lexicon.txt, cosmic_canticle.txt, gothic_grimoire.txt, kitchen_witchery.txt, pirate_pillage.txt, prairie_homestead.txt, velvet_leather.txt, medieval_might.txt | Curated in-house for Wizard of Words | Project-authored data |

The current ESDB/SCOWL project also confirms that 12dicts and ENABLE2K are its principal public-domain sources in its [copyright ledger](https://github.com/en-wl/wordlist/blob/v2/Copyright). Wizard of Words does not currently redistribute ESDB/SCOWL itself.

The thematic commentary packs under `data/language/` are original Wizard of Words writing.

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
