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
  "schema_version": "1.0",       // req — pin to "1.0" for now
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
    "dossier_ref": "3211 / 364 / AG 45086"
  },

  "owner": {
    "name": "M. NGUYEN Van Luong",
    "address": "31 Rue de Tessé, 78910 Tacoignieres",
    "lots": "Lot 36 (Appartement), Lot 20 (Cave)",
    "tantiemes": 233,             // integer, owner's voting weight
    "balance_eur": null,          // null = no entry in Annexe N°6; positive = créditeur; negative = débiteur
    "balance_note": "Balance nulle — n'apparaît pas dans l'Annexe N°6",
    "fonds_alur_eur": 633.78,     // optional — owner's quote-part Annexe N°8
    "cs_president": "Sébastien LOUCHARD"
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
    "currency": "EUR"
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
      "note": "nouvelle ligne — à clarifier en séance"
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
      "summary": "Vote principal du budget 2027 …"  // 1–3 sentences, plain language
    }
  ],

  "travaux": [                    // optional — Annexe N°5 ongoing works ledger
    {
      "label": "Ravalement Bâtiment A",
      "vote_date": "2024-02-15",  // ISO
      "vote_eur": 732279.29,
      "paye_eur": 353332.09,
      "solde_eur": 378947.20
    }
  ],

  "briefing": [                   // req — the 3-7 "à retenir avant de voter" items
    {
      "title": "Budget 2027 : +17,4 %",
      "resolutions": ["11"],
      "article": "24",
      "body": "Hausse à 57 950 € due principalement à deux nouvelles lignes …",
      "severity": "high"          // "high" | "med" | "low"
    }
  ],

  "source": {                     // req — provenance
    "pdf_path": "/abs/path/to/source.pdf",
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
Sticky top nav  ← hidden in print
Hero            ← residence name + 4 KPI cards (meeting, deadline, budget, tantièmes)
§1 Meeting      ← 2-card grid: details + vote-by-correspondence panel
§2 Briefing     ← numbered "à retenir" list, color-coded by severity
§3 Résolutions  ← donut chart + filter UI + interactive table (search, article toggles, hide procedural)
§4 Budget       ← dark band: bar chart of totals + key-takeaway card + horizontal bar of top notable lines
§5 Travaux      ← donut of paid vs outstanding + per-chantier progress cards (hidden if no travaux data)
§6 Mon lot      ← 3 owner cards (identity, tantièmes, fonds ALUR) + balance badge
Footer          ← generation date + disclaimer
```

The template auto-hides sections when their data is empty — e.g. an AG with no travaux yields no §5.

## Why JSON-in-HTML?

- **Single source of truth.** Charts, tables, and Query mode all read the same block — no risk of drift between "what the chart shows" and "what the markdown says".
- **Tool-neutral.** Any agent harness (Claude Code, Codex, opencode) can `Read` the HTML, regex-extract the `<script id="ag-data">` block, and `JSON.parse` it without needing the browser.
- **Stable contract.** The frontmatter approach in the old markdown was fragile (YAML parsers vary). JSON is universal.
