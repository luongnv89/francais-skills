---
name: ag-copro
description: "Ingest a French Assemblée Générale (AG) PDF and generate an interactive HTML report (Tailwind + Chart.js) with meeting info, résolutions, year-over-year budget, travaux progress, and a 5-point pre-vote briefing. Don't use for non-AG French docs (acte, bail), tax files, or non-French copropriété."
metadata:
  version: 1.2.0
  author: francais-skills
---

# ag-copro — Assemblée Générale assistant for French house owners

Helps a copropriétaire understand the annual AG convocation document: extract the meeting info, audit the budget, flag what needs attention before voting — and produce a single self-contained interactive HTML report the user can open in any browser. Then answers follow-up questions from that report.

## When this skill triggers

- User shares a French AG PDF (e.g. "convocation assemblée générale", "ordre du jour", "résolutions").
- User asks "when is my AG meeting?", "what's the new budget?", "what am I voting on?", "explain résolution N°7", "compare last year vs next year budget".
- User asks for the **HTML report** / **rapport interactif** / **export HTML** of an AG they've already ingested.
- User invokes `/ag-copro` with or without a path.

Do not trigger for: French legal documents that aren't AG convocations (acte de vente, bail, état des lieux), tax/fiscal documents, non-French copropriété files.

## Output: one interactive HTML file

The skill writes **a single self-contained HTML file** to the user's current working directory:

```
./ag-<residence-slug>-<year>.html
```

That file:

- Renders with TailwindCSS (Play CDN) and Chart.js — open in any modern browser; no build, no server.
- Shows hero KPIs, a 5-point briefing, a filterable résolutions table, a Y-o-Y budget chart, top-variation account lines, travaux progress donut, and owner-specific cards.
- Embeds **the full structured data** as JSON inside `<script type="application/json" id="ag-data">…</script>` — this is the source of truth for both the visualization AND for Query mode.
- Supports print to PDF (`Imprimer / PDF` button hides interactive controls).

There is **no separate markdown summary**. The HTML is both the report and the storage format.

## Workflow (single entry, two internal modes)

The skill has one entry point but two operating modes. Decide which by looking at inputs:

1. **No HTML report loaded yet** → **Ingest mode**. Read the PDF, extract structured data, render the HTML, save it to CWD, then proceed to query mode with the JSON data in hand.
2. **HTML report loaded** → **Query mode**. Answer the user's question from the embedded JSON. Never re-read the PDF unless the user explicitly asks ("re-extract", "re-ingest", "the report is wrong").

### Routing — decide mode at start of every turn

```
1. Was a PDF path provided?
   - Yes → compute output filename; if it exists in CWD and is fresh, jump to Query mode.
          Otherwise enter Ingest mode.
2. Was an HTML report path or residence name provided?
   - Yes → load that HTML, parse the embedded JSON, jump to Query mode.
3. Nothing provided?
   - Glob CWD for `ag-*.html`.
     - If 1+ reports exist: ask the user to pick one, OR provide a new PDF path.
     - If none in CWD, also check `~/.ag-copro/summaries/` for legacy `*.md` files
       and offer to re-render them as HTML.
     - If both are empty: ask the user for a PDF path.
```

### Storage

The report is written to the **current working directory** where the skill was invoked — `./ag-<slug>-<year>.html`. CWD is the user's choice (`cd` to wherever you want output to land).

Filename slug rules:
- Strip accents (`é` → `e`).
- Lowercase.
- Replace non-alphanumeric with hyphens; collapse consecutive hyphens.
- Truncate to 50 chars.
- Year is the **meeting year** (4 digits).

Examples:
- "LE VERGER À PALAISEAU", meeting 16/06/2026 → `ag-le-verger-a-palaiseau-2026.html`
- "17 RUE PHILIPPE DE DANGEAU", meeting 14/05/2025 → `ag-17-rue-philippe-de-dangeau-2025.html`

If a file with the same name already exists in CWD, ask before overwriting — the user may want to keep the old version for comparison.

The legacy folder `~/.ag-copro/summaries/` is no longer written to. If it exists with old `.md` files from previous skill versions, leave them alone unless the user explicitly asks to migrate.

## Ingest mode — extracting the AG PDF

Full playbook: see `references/ingest.md`. Quick version:

1. Read the PDF (use the `Read` tool, paging through if >20 pages — most AGs run 30–60 pages).
2. Identify the syndic (Immo de France, VPàt Immo, Foncia, Loiselet & Daigremont, etc.) so layout assumptions don't bite. Look for the logo block and the contract holder in the first 2 pages.
3. Extract the data needed to fill the JSON schema (see `references/html-template.md` for the schema):
   - **Meeting metadata** — date, time, location, syndic, vote-by-correspondence deadline.
   - **Resolutions** — every numbered item with its article-of-majority (Article 24/25/26/26-1) and "Sans vote" flag.
   - **Financial Y-o-Y from Annexe N°3** — totals for exercise N (just closed), N+1 (current year, often re-voted), N+2 (next year, the main vote). Line items with >20 % swing or >500 € absolute change.
   - **Owner-specific data + travaux highlights** — owner's tantièmes, debit/credit balance from Annexe N°6 if listed, big-ticket travaux (ravalement, toiture, fonds ALUR, devis >5 000 €).
   - **Briefing** — 3 to 7 prioritized "à retenir avant de voter" items the user should actually read.
4. Read `references/html-template.html`. Substitute `{{AG_DATA_JSON}}` (serialized JSON, 2-space indent), `{{LANG}}` (fr/en), `{{YEAR}}`, `{{RESIDENCE_TITLE}}`.
5. Write the result to `./ag-<slug>-<year>.html` in the user's CWD.
6. Output the Step Completion Report (below), then briefly summarize the briefing (3–5 bullets max, since the report itself shows them in detail).

Cross-syndic note: layouts vary. **Anchor on landmarks** ("ORDRE DU JOUR", "RESOLUTION N°", "ANNEXE N°", "tantièmes", "vote par correspondance") rather than fixed page numbers.

## Query mode — answering follow-up questions

Full playbook: see `references/query.md`. Quick version:

1. Read the HTML file. Extract the JSON between `<script type="application/json" id="ag-data">` and `</script>`. Parse it.
2. **Do not re-read the PDF** unless the user explicitly asks.
3. Match the question against the JSON sections:
   - "when / where / deadline" → `meeting`
   - "vote / résolution / what am I voting on / article" → `resolutions`
   - "budget / dépense / coût / augmentation / variation" → `budget` + `budget_lines`
   - "tantièmes / solde / je dois / mon lot" → `owner`
   - "travaux / ravalement / chantier" → `travaux` + the matching résolutions
   - "what should I pay attention to" → `briefing`
4. Answer in the user's question language (French if asked in French, English if asked in English). Keep French legal terms intact (*quitus*, *tantièmes*, *travaux*, *Article 25*).
5. Cite the résolution number or annexe reference when relevant.
6. If the answer isn't in the JSON, say so explicitly — don't invent it. Offer to re-ingest.
7. If the user asks to **regenerate** the report (new export, "refresh the HTML"), re-render the same JSON through the template without re-reading the PDF.

## Output format

### After ingest

```
◆ Ingest complete ([N] résolutions, [budget €] budget N+2)
··································································
  Meeting date:       √ [date] at [time] — [location]
  Vote deadline:      √ [date]
  Syndic:             √ [name]
  Résolutions:        √ [count] votables, [count] sans vote
  Annexe N°3 budget:  √ N: [x€]  N+1: [y€]  N+2: [z€]  (Δ [pct])
  Owner data:         √ [name] — [tantièmes] tantièmes
  Report saved to:    √ ./ag-[slug]-[year].html
  ____________________________
  Result:             PASS

Ouvrez le fichier dans votre navigateur pour le rapport interactif.
[3–5 bullet recap of what to pay attention to — the HTML itself has the detail]
```

### After query

Plain answer, 1–6 sentences, in the user's language. Cite résolution number / annexe / page when relevant. End with a one-line offer (e.g. "Want me to dig deeper into any résolution?") only if the answer was short and surface-level.

## Constraints

- The JSON inside the HTML is the source of truth in Query mode. Treat it like the user's working memory. If you contradict it, the user will lose trust.
- Never invent numbers. If the AG document leaves a field blank (e.g. `Vote d'un budget de _____ €`), record `null` and say "left blank in the convocation" in the corresponding `summary` or `note`.
- Keep French legal terms in French even when answering in English. Quote the original phrase in italics on first mention.
- Do not give legal advice. The skill explains the document; the user (or their conseil syndical / lawyer) decides how to vote.
- The HTML uses external CDNs (Tailwind, Chart.js, Google Fonts). Offline use will degrade the visualization but the JSON block remains intact and Query mode still works.

## Reference files

- `references/ingest.md` — full extraction playbook, per-block landmarks, multi-syndic notes.
- `references/query.md` — full Q&A playbook with example question→JSON-field mappings.
- `references/html-template.md` — JSON schema reference + template substitution recipe.
- `references/html-template.html` — the actual HTML shell with placeholder `{{AG_DATA_JSON}}`.
