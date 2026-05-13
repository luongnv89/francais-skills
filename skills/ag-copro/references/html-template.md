# HTML report template — canonical structure and JSON schema

The ag-copro skill writes a single self-contained HTML file. That file is BOTH the human-readable report AND the machine-readable data source for Query mode. There is no separate `.md` summary.

## Files

- `references/html-template.html` — the actual template. It contains the full Tailwind/Chart.js shell and a placeholder block `{{AG_DATA_JSON}}` inside `<script type="application/json" id="ag-data">…</script>`.
- This file — schema reference + writing instructions.

## How the skill builds the report

1. Extract structured data from the PDF (same as the old workflow, see `ingest.md`).
2. Assemble a JSON object matching the schema below.
3. Read `references/html-template.html`.
4. Substitute placeholders:
   - `{{AG_DATA_JSON}}` → the serialized JSON object (pretty-printed, 2-space indent).
   - `{{LANG}}` → `fr` or `en` (matches `data.language`).
   - `{{YEAR}}` → the meeting year (4 digits, from `data.meeting.date`).
   - `{{RESIDENCE_TITLE}}` → the residence name (used in `<title>` only).
5. Write the result to `./<slug>-<year>.html` in the user's current working directory.

Browser rendering reads only the JSON block — every value displayed on the page is derived from it. **Query mode reads the same block** to answer follow-up questions, so the JSON must be complete and accurate even when the user hasn't asked for a "full" report.

## JSON schema

The embedded JSON must be a single object. Keys not listed below are ignored but preserved — feel free to add `extra_notes` for debugging. Required keys are marked **req**.

```jsonc
{
  "schema_version": "1.1",       // req — bumped from 1.0 when per-field `pages` was added
  "skill": "ag-copro",            // req — fixed string
  "language": "fr",               // req — "fr" or "en", drives label translations

  "residence": "LE VERGER À PALAISEAU",  // req — display name, used in hero
  "address": "4/12 Rue Maurice Berteaux, 91120 Palaiseau",
  "syndic": "IMMO DE FRANCE PARIS ILE-DE-FRANCE",   // req
  "syndic_address": "7 ter rue de la Porte de Buc, 78000 Versailles",

  "meeting": {
    "date": "2026-06-16",         // req — ISO yyyy-mm-dd
    "date_fr": "Mardi 16 juin 2026",  // optional pretty form quoted from the PDF
    "time": "19:00",
    "location": "Salle de réunion de la copropriété, 4/12 Rue …",
    "vote_correspondence_deadline": "2026-06-12",       // ISO
    "vote_correspondence_deadline_fr": "12 juin 2026",  // pretty form
    "return_email": "chrystel.fayette@immodefrance.com",
    "return_postal": "IMMO DE FRANCE PARIS IDF, 78000 Versailles",
    "dossier_ref": "3211 / 364 / AG 45086",
    "pages": [1, 2]               // optional — pages where meeting metadata is printed
  },

  "owner": {
    "name": "M. NGUYEN Van Luong",
    "address": "31 Rue de Tessé, 78910 Tacoignieres",
    "lots": "Lot 36 (Appartement), Lot 20 (Cave)",
    "tantiemes": 233,             // integer, owner's voting weight
    "balance_eur": null,          // null = no entry in Annexe N°6; positive = créditeur; negative = débiteur
    "balance_note": "Balance nulle — n'apparaît pas dans l'Annexe N°6",
    "fonds_alur_eur": 633.78,     // optional — owner's quote-part Annexe N°8
    "cs_president": "Sébastien LOUCHARD",
    "balance_pages": [44],        // optional — pages of Annexe N°6 where owner balance was checked
    "fonds_alur_pages": [48]      // optional — pages of Annexe N°8
  },

  "budget": {                     // req — drives the main budget bar chart + delta card
    "n_label": "2025 voté",
    "n_eur": 49350.00,
    "n_realise_eur": 43400.95,    // optional — if the PDF shows realized vs voted, include
    "n_plus_1_label": "2026 actualisé",
    "n_plus_1_eur": 57950.00,
    "n_plus_2_label": "2027 à voter",
    "n_plus_2_eur": 57950.00,     // req — main vote
    "delta_pct": 17.4,             // (n_plus_2 / n - 1) * 100, 1 dp
    "excedent_2025_eur": 14349.05,
    "currency": "EUR",
    "pages": [38, 39, 40]         // optional — pages of Annexe N°3 (budget totals)
  },

  "budget_lines": [               // notable Annexe N°3 lines (delta > 20 % or > 500 € abs)
    {
      "compte": "781",            // account code
      "label": "Émetteurs",
      "n_vote": 0,
      "n_realise": 322.98,
      "n_plus_1": 7800,
      "n_plus_2": 7800,
      "delta_pct": null,          // null when starting from zero
      "note": "nouvelle ligne — à clarifier en séance",
      "pages": [39]               // optional — page(s) of Annexe N°3 row
    }
    // … 5 to 15 lines, sorted in source order; the template sorts/clips itself
  ],

  "resolutions": [                // req — every numbered item; the template renders all
    {
      "num": "11",                // string (can be "12.x" for sub-items)
      "title": "Approbation du budget prévisionnel 2027 — 57 950 € TTC",
      "article": "24",            // "24" | "25" | "25-1" | "26" | "26-1" | "Titre" | "—"
      "vote": "oui",              // "oui" | "sans vote"
      "tag": "budget",            // free-form: budget, syndic, travaux, comptes, contrat, autorisation, procedural, informatif
      "amount_eur": 57950,         // null if no euro amount
      "summary": "Vote principal du budget 2027 …",  // 1–3 sentences, plain language
      "pages": [17]               // optional — page(s) of "PROJETS DE RESOLUTIONS" body for this item
    }
  ],

  "travaux": [                    // optional — Annexe N°5 ongoing works ledger
    {
      "label": "Ravalement Bâtiment A",
      "vote_date": "2024-02-15",  // ISO
      "vote_eur": 732279.29,
      "paye_eur": 353332.09,
      "solde_eur": 378947.20,
      "pages": [42]               // optional — page of Annexe N°5 entry
    }
  ],

  "briefing": [                   // req — the 3-7 "à retenir avant de voter" items
    {
      "title": "Budget 2027 : +17,4 %",
      "resolutions": ["11"],
      "article": "24",
      "body": "Hausse à 57 950 € due principalement à deux nouvelles lignes …",
      "severity": "high",         // "high" | "med" | "low"
      "pages": [17, 39]           // optional — pages backing this point (résolution + annexe)
    }
  ],

  "source": {                     // req — provenance
    "pdf_path": "/abs/path/to/source.pdf",  // req — absolute path to the original PDF
    "pdf_path_relative": "../resources/source.pdf", // optional — relative to the HTML; preferred for the link if the user moves both files together
    "pdf_pages": 51,
    "ingested_at": "2026-05-13"   // ISO date
  }
}
```

### Hard rules for the JSON

- **All monetary values are numbers** (no string units, no commas as thousands separators). The template formats with `Intl.NumberFormat`.
- **All dates in ISO `YYYY-MM-DD`** in the structured fields. The `*_fr` companion fields preserve the document's original phrasing.
- **No invented values.** Use `null` (or omit) when the document doesn't say. The template renders `—`.
- **`resolutions` order matters** — keep document order, not sorted by article. Users expect Rés N°1, N°2, … to render top to bottom.
- **`briefing` order matters** — highest impact first; the template numbers them 1, 2, 3 in display order.
- **`language`** drives the few generated labels (nav, "Lecture clé", "À retenir", "Payé / Solde"). Body text inside `summary`, `body`, `note` stays in the language you wrote it in.
- **`pages` is always an array of integers** — never a scalar, never a string. Use `[12]` for a single page, `[12, 13]` for spans, omit (or `[]`) when unknown. 1-indexed (same convention as the PDF reader). The template renders `p. 12` for a single page and `p. 12–13` for a range; missing/empty `pages` simply hides the chip.

### Page references — what to record and where

Every block that the user might want to verify against the source PDF carries an optional `pages` array. The template renders these as small clickable chips (`p. 17`, `p. 38–39`) next to the corresponding figure. When `source.pdf_path` is set, each chip becomes a deep link of the form `<pdf>#page=N` that opens the PDF at the right page in the browser's built-in viewer (Chrome, Firefox, Edge, Safari, Acrobat).

| Block | Where the page should come from |
|-------|---------------------------------|
| `resolutions[].pages` | Page(s) of "PROJETS DE RESOLUTIONS" where this résolution's full text appears. |
| `budget.pages` | Page(s) of Annexe N°3 totals (usually the last page of the annexe). |
| `budget_lines[].pages` | Page of Annexe N°3 where this account line is listed. |
| `briefing[].pages` | Composite — the pages backing the claim (the résolution body + the annexe row). |
| `travaux[].pages` | Page of Annexe N°5 listing this chantier. |
| `meeting.pages` | Page(s) of the convocation letter (typically pages 1–2). |
| `owner.balance_pages` | Page of Annexe N°6 where the owner balance is read (or stated as missing). |
| `owner.fonds_alur_pages` | Page of Annexe N°8 where the owner's fonds ALUR quote-part is listed. |

If page numbering is impossible to extract reliably (e.g. a heavily fragmented scan), omit the `pages` field on that record rather than guess. Reports rendered without `pages` chips remain valid v1.1.

## Output file naming

```
./ag-<residence-slug>-<year>.html
```

- `<residence-slug>` uses the same rules as the old summary slug: lowercase, accent-stripped, non-alphanumeric replaced with hyphens, truncated to 50 chars.
- `<year>` is the 4-digit meeting year.
- Prefix `ag-` so the file is glob-able from the working directory.

Examples:
- `./ag-le-verger-a-palaiseau-2026.html`
- `./ag-17-rue-philippe-de-dangeau-2025.html`

If a file with the same name already exists in CWD, ask the user before overwriting.

## Substitution recipe (pseudocode)

```
data        = build_json_from_pdf(pdf_path)
template    = read("references/html-template.html")
year        = data.meeting.date[:4]
output      = template
              .replace("{{AG_DATA_JSON}}", JSON.stringify(data, indent=2))
              .replace("{{LANG}}",        data.language)
              .replace("{{YEAR}}",        year)
              .replace("{{RESIDENCE_TITLE}}", data.residence)
write("./ag-<slug>-<year>.html", output)
```

Use `JSON.dumps(data, indent=2, ensure_ascii=False)` (Python) or equivalent — preserve accents in the JSON text. The template's `JSON.parse` will handle it correctly.

## Visual structure (for reference)

```
Sticky top nav  ← hidden in print, light paper bg, mark + monospace breadcrumb
Hero            ← dark ink-950 band with champagne radial glow, residence
                  name in serif italic accent, 4 KPI cards on translucent paper
§1 Meeting      ← 2-card grid: light dl + dark "vote deadline" card with glow
§2 Briefing     ← numbered "à retenir" list, color-coded by severity (rose/amber/teal)
§3 Résolutions  ← donut chart + filter UI + interactive table (search, article toggles, hide procedural)
§4 Budget       ← dark band: bar chart of totals + key-takeaway card +
                  horizontal bar of top notable lines, champagne accents on dark
§5 Travaux      ← donut of paid vs outstanding + per-chantier progress cards
                  (hidden if no travaux data)
§6 Mon lot      ← 3 owner cards on paper bg + balance badge in teal/rose
Footer          ← dark ink band, monospace meta + serif italic disclaimer
```

The template auto-hides sections when their data is empty — e.g. an AG with no travaux yields no §5.

## Design language

The report uses the **warm filmic** palette of the logo-designer reference (Fraunces serif + Inter Tight sans + JetBrains Mono):

- **Ink** `#0B0A08` / `#15120E` — hero, budget band, footer
- **Paper** `#F4EFE6` / `#FAFAF7` — text on dark, page background
- **Champagne** `#E9C38B` — primary accent (CTAs, italics, highlights)
- **Amber-warm** `#D98B5F` — secondary accent (section labels, hover, italic display words)
- **Teal** `#7AA2A0` — trust signal (privacy, balance créditeur, paid travaux)
- **Rose** `#C46B57` — debit/overspend warnings

Editorial flourishes lifted from the logo-designer brand-showcase:
- Section titles follow the pattern `4. Le budget, *en clair.*` — last word italic in amber.
- Section labels use `§ Budget` in monospace, uppercase, letter-spaced amber.
- Hero residence name splits the last word into a serif italic in champagne.
- Cards use `rounded-2xl`, subtle `box-shadow: 0 10px 40px -20px rgba(11,10,8,0.2)`, and a paper hairline border.
- Dark cards over the ink band use `border: 1px solid rgba(244,239,230,0.22)` with translucent paper tint.

When updating the JSON schema or rendering logic, keep the visual identity in sync: stick to the Tailwind utilities mapped above so utility-class swaps don't break the look. Chart.js color literals are mirrored in a single `COL = { ... }` object inside the template's `<script>` — update it there if you add chart types.

## Why JSON-in-HTML?

- **Single source of truth.** Charts, tables, and Query mode all read the same block — no risk of drift between "what the chart shows" and "what the markdown says".
- **Tool-neutral.** Any agent harness (Claude Code, Codex, opencode) can `Read` the HTML, regex-extract the `<script id="ag-data">` block, and `JSON.parse` it without needing the browser.
- **Stable contract.** The frontmatter approach in the old markdown was fragile (YAML parsers vary). JSON is universal.
