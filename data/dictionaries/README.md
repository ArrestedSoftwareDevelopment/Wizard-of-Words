# Wizard of Words Lexicon System

The dictionary directory has three deliberately separate kinds of data. `index.json` is the machine-readable catalog and the single source of truth for how each file behaves.

## 1. Base grimoires

Exactly one broad base is checked by default. Players may choose a smaller or differently curated base instead.

- `enable1.txt`: expansive North American game vocabulary; the default.
- `tournament_american.txt`: compact, familiar American vocabulary.
- `extended_american.txt`: a larger American list with inflections.
- `international_game.txt`: internationally oriented game vocabulary.
- `common_english.txt`: a small relaxed-play foundation.

The inherited source snapshots remain separate and minimally altered so their provenance stays auditable. A future compiler can emit non-overlapping generated tiers without destroying those snapshots.

## 2. Opt-in modules

Modules add a clearly named kind of word without changing the base dictionary:

- acronyms and initialisms;
- given names;
- African American English lexicalized forms;
- technology and science jargon;
- Spanish, French, and Italian starter vocabulary;
- the selected board's bonus vocabulary.

Foreign-language modules currently use only spellings representable by the A-Z tile bag. Italian records one explicit ASCII-folding exception (`CITTA`). Full multilingual play should add native letters, scoring distributions, collation, and display fonts before these modules grow substantially.

African American English is not represented as “slang.” Its starter file is intentionally small because much of AAE's distinctiveness is systematic grammar and aspect, which a one-word-per-line game lexicon cannot express.

## 3. Policy and reference sets

Files with `"selectable": false` never appear as grimoires. Rulesets may use them to reject or adjudicate words:

- profanity;
- slurs and abusive terms;
- proper nouns;
- brands, products, and trademarks;
- trusted two-letter words.

Brand/trademark and proper-noun lists are intentionally non-exhaustive. They are table-rule aids, not legal registries or universal linguistic claims. Context-sensitive and reclaimed language is kept out of the slur list unless a conservative default is clearly useful.

## Catalog fields

- `category`: `base`, `module`, `language_module`, `jargon_module`, `bonus`, or `policy`.
- `selectable`: whether setup shows the file as a grimoire; defaults to true.
- `default_checked`: whether a selectable file begins enabled.
- `policy_role`: runtime destination for a hidden policy set.
- `source_id`: short provenance key tied to `LICENSES.md`.
- `normalization`: any representation compromise required by the current board.
- `bonus_points` and `bonus_flavor`: themed scoring behavior.

## Data invariants

Project-curated files are uppercase A-Z, one word per line, sorted, and duplicate-free. Inherited source snapshots may be lowercase; the loader normalizes all playable words to uppercase. `tests/language_data_test.gd` checks the catalog, formats, minimum useful sizes, all seven language packs, deterministic rendering, unresolved placeholders, and every policy path.

## Source policy

Only public-domain, permissively licensed, U.S. government factual data, or original project curation may enter the repository. Every imported compilation must receive a row in `LICENSES.md` before use. Do not scrape a commercial dictionary, naming site, slang glossary, or trademark directory merely because its pages are public.
