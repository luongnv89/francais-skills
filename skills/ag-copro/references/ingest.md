# Ingest playbook — parsing a French AG convocation PDF

Convocations d'AG run 30–60 pages and follow a regulated structure (loi du 10/07/1965, décret 67-223), but the layout varies between syndics.

**Find by landmark, record by page.** Don't *look up* facts by fixed page numbers (page 17 in Immo de France is page 22 in VPàt Immo). Do *record* the page where you found each fact, so the report can cite it back to the user — that's what the `pages` arrays in the JSON schema are for.

## Step 1 — Identify the syndic and document type

Read the first 2–4 pages. Look for:

- The syndic logo / "RCS …" line / address block (Immo de France, VPàt Immo, Foncia, Citya, Loiselet & Daigremont, Nexity, etc.).
- A "CONVOCATION D'ASSEMBLÉE GÉNÉRALE" title (ordinaire / extraordinaire).
- The owner's name and address as recipient.

If the document is **not** a convocation d'AG (e.g. it's a procès-verbal, an état descriptif, a bail), stop and tell the user. Don't try to force-fit.

## Step 2 — Page through the entire PDF

For PDFs > 20 pages, you must page with the `Read` tool using the `pages` parameter. Typical chunks: 1–8, 9–16, 17–24, etc. Build a mental ToC as you go.

Common section sequence (varies by syndic):
1. Cover / convocation letter (1–3 pages)
2. Ordre du jour (1–3 pages)
3. Projets de résolutions (5–15 pages)
4. Formulaire de vote par correspondance + Intentions de vote (3–6 pages)
5. Espace client / mentions légales (optional, 1–4 pages)
6. **Annexes comptables** (key part for financials):
   - **Annexe N°1** — Etat financier (recettes / dépenses globales)
   - **Annexe N°2** — Compte de gestion travaux et opérations exceptionnelles
   - **Annexe N°3** — Compte de gestion pour opérations courantes + budget prévisionnel (the budget breakdown by account)
   - **Annexe N°4** — Compte de gestion travaux article 14-2 (works ledger)
   - **Annexe N°5** — État des travaux votés non encore clôturés (works in progress)
   - **Annexe N°6** — Liste des copropriétaires débiteurs / créditeurs (per-owner balances)
7. Devis et contrats joints (optional)

## Step 3 — Extract the four required blocks

### Block 1 — Meeting metadata

Search the early pages for these specific phrases (regex hints in **bold**):

- Meeting date/time: looks like `**MARDI 16 JUIN 2026 à 19 H 00**` or `**Mercredi 14 Mai 2025 à 18 heures 00**`. Convert to ISO `YYYY-MM-DD` for frontmatter, but preserve the original French phrase in prose.
- Location: typically follows "à l'adresse suivante" or "qui se tiendra le … à". Multi-line — keep room name + street + postal code.
- Syndic name: from the letterhead or from "Désignation du syndic" resolution.
- **Vote-by-correspondence deadline**: look in the "FORMULAIRE DE VOTE PAR CORRESPONDANCE" section for "Avant la date limite de réception le : **[date]**". By default this is 3 jours francs avant l'AG (loi 10/07/1965, art. 17-1 A). If the form doesn't state a deadline explicitly, compute meeting_date − 3 working days but flag the assumption.
- Postal/email return address for the form.

### Block 2 — Résolutions

Locate the `ORDRE DU JOUR` section (an enumerated list with article numbers in the right margin) and the `PROJETS DE RESOLUTIONS` section (the full text of each one).

For each résolution:
- Number.
- Title (use the wording from "ORDRE DU JOUR" — it's terser than the body).
- Article-of-majority:
  - **Article 24** — majorité simple (>50% of votes cast, abstentions excluded).
  - **Article 25** — majorité absolue (>50% of all tantièmes — voted or not — count).
  - **Article 25-1** — second vote at art. 24 majority if art. 25 fails but reached 1/3 of tantièmes.
  - **Article 26** — double majorité (2/3 of tantièmes).
  - **Article 26-1** — fallback when art. 26 fails.
  - **"Sans vote"** / **Titre** — informational only, no vote.
- Plain-language summary, 1–3 sentences. Quote any euro amount.

Look for special markers in the body — "Le cas échéant second vote à la majorité simple" indicates an art. 25-1 fallback chain. Flag these.

### Block 3 — Financial year-over-year (Annexe N°3)

This is the most important block for the user — and the most error-prone, because it's a wide table that often gets fragmented across pages.

Annexe N°3 has columns labelled:
- **N-1** — exercise approved (2 years ago).
- **N** — current exercise — split into "budget voté" and "réalisé" (sometimes two subcolumns).
- **N+1** — current year's preliminary budget (sometimes voted last year, sometimes being re-voted as "actualisation").
- **N+2** — proposed budget for the next exercise — **this is the main vote**.

The dates labelling these columns are at the top of each Annexe page. **Always read those dates** — don't assume "N+2" is two years from the meeting; it can be the year immediately after the meeting.

Extraction:
- **Totals**: bottom-of-page totals or "TOTAL CHARGES NETTES". Sum across all sub-tables (charges communes générales + charges bâtiment A + bâtiment B + compteurs + …). Verify the sum matches the printed total within 1 €.
- **Y-o-Y deltas**: compute `(N+2 − N) / N × 100`, rounded 1 dp.
- **Notable lines**: keep any account whose delta is >20 % or whose absolute change is >500 €. Highlight new lines (N=0, N+2>0).

If the budget grew significantly, look for an "Actualisation du budget" résolution and a "Désignation du syndic" résolution — a new syndic contract often explains a bump.

Plausible explanations for big swings:
- New "salaires employé d'immeuble" line → embauche de gardien.
- "honoraires syndic" jump → contract renewal at higher rate.
- "fonds travaux ALUR" increase → upcoming major works.
- "EDF / eau / chauffage" jumps → utility tariff hikes.

Mark these as "plausible explanation" not "fact" — the document rarely confirms.

### Block 4 — Owner-specific data + travaux highlights

**Owner identity**: look for the recipient block on the first page ("M. NGUYEN Van Luong, 31 rue de Tessé …"). The voting form repeats this and adds tantièmes: "Représentant **233 tantièmes** de copropriété".

**Owner balance**: scan Annexe N°6 ("Liste des copropriétaires débiteurs / créditeurs"). Find the row matching the owner's name. Two columns:
- `débiteurs` (left) — the owner owes.
- `créditeurs` (right) — the syndicat owes the owner.
If the name appears in neither: write "balance nulle ou non listé".

**Travaux highlights**: list every résolution that mentions:
- *travaux*, *ravalement*, *toiture*, *réfection*, *fonds travaux ALUR*
- *devis* (quote) with a euro amount
- *Plan Pluriannuel de Travaux* (P.P.P.T.)

For each, capture the euro amount and majority article. These are usually the highest-impact votes.

## Step 4 — Assemble the JSON payload and render the HTML report

The output is a single interactive HTML file. **There is no markdown summary.**

1. Build a JSON object matching the schema in `html-template.md`. Every value the user will read on the page comes from this object — be thorough.
2. **Attach `pages` to every record where the user would plausibly want to verify the figure against the original PDF.** The `Read` tool returns 1-indexed page numbers in its output; carry those over directly. Records that should carry pages: `resolutions[].pages`, `budget.pages`, `budget_lines[].pages`, `briefing[].pages`, `travaux[].pages`, `meeting.pages`, `owner.balance_pages`, `owner.fonds_alur_pages`. Always an array of ints. Omit (or use `[]`) when you genuinely cannot pinpoint the page.
3. **Set `source.pdf_path`** to the absolute path of the source PDF. If the report is being written next to the PDF (or one directory away), also set `source.pdf_path_relative` to the path *relative to the HTML's directory* (e.g. `../resources/2-residence-du-verger-2026.pdf`). The renderer prefers the relative path so the deep links keep working when the user moves the HTML + PDF together.
4. Compose the `briefing` array (3 to 7 items) **inside the JSON**, not as a separate prose block. Each item:
   - `title` — 4–8 words.
   - `resolutions` — array of résolution numbers as strings.
   - `article` — `"24"`, `"25"`, `"26"`, `"25-1"`, `"26-1"`, or `"—"`.
   - `body` — 1–3 sentences naming the euro amount (or "no euro amount"), the majority required, and why it matters.
   - `severity` — `"high"` (budget jump, syndic change, big-ticket travaux), `"med"` (unusual but small), `"low"` (procedural quirks).
   - `pages` — pages backing the claim (résolution body + supporting annexe row).
   - Lead with the highest impact; the template numbers them 1, 2, 3 in display order.
5. Read `references/html-template.html`. Substitute:
   - `{{AG_DATA_JSON}}` → `JSON.stringify(payload, null, 2)` (preserve accents — `ensure_ascii=False` if using Python).
   - `{{LANG}}` → `data.language` (`"fr"` or `"en"`).
   - `{{YEAR}}` → first 4 chars of `data.meeting.date`.
   - `{{RESIDENCE_TITLE}}` → `data.residence` (for the `<title>` tag).
6. Write the result to `./ag-<slug>-<year>.html` in the user's **current working directory**.

Slug rules:
- Strip accents (`é` → `e`).
- Lowercase.
- Replace non-alphanumeric with hyphens.
- Collapse consecutive hyphens.
- Truncate to 50 chars max.
- Year is the **meeting year** (4 digits).

Examples:
- "LE VERGER A PALAISEAU", meeting 16/06/2026 → `ag-le-verger-a-palaiseau-2026.html`
- "17 RUE PHILIPPE DE DANGEAU", meeting 14/05/2025 → `ag-17-rue-philippe-de-dangeau-2025.html`

**Overwrite protection**: if a file with that name already exists in CWD, ask the user before clobbering it.

## Step 5 — Output the Step Completion Report and a short briefing

After writing the HTML, immediately:

1. Output the `◆ Ingest complete` Step Completion Report block (see SKILL.md for the format). Make sure the `Report saved to:` line shows the absolute path to the HTML.
2. Tell the user how to open the report: "Ouvrez le fichier dans votre navigateur — toutes les charts et le tableau filtrable sont déjà dedans." (or English equivalent if the user wrote in English).
3. Give a 3–5 bullet recap of what's in the briefing. **Keep this short** — the HTML already shows the full detail with severity color-coding. Each bullet:
   - Names the résolution numbers involved.
   - States the euro amount or the qualitative impact.
   - Says in one sentence why it matters.
   - References the article-of-majority.

Don't pad with procedural items (élection du président de séance, etc.) — those are filler.

## Multi-syndic notes

| Syndic | Notes |
|--------|-------|
| Immo de France | Convocation + Ordre du jour + Résolutions + Vote form + Annexes. Annexes labelled "ANNEXE N°1" through "ANNEXE N°6". Owner identity on every page. |
| VPàt Immo | More compact. Convocation cover + Ordre du jour + résolutions inline. Sometimes splits Annexes into separate sub-PDFs. Budget columns labelled with explicit dates. |
| Foncia / Citya / Nexity | Similar to Immo de France but section ordering varies. Look for "ETAT FINANCIER" + "BUDGET PREVISIONNEL" rather than "Annexe N°X" labels. |

If the syndic isn't on this list, fall back to landmark-based parsing. Don't fail — extract what you can and add an `extra_notes` array to the JSON payload listing unknowns (the template ignores unknown keys but they remain readable by Query mode).

## Common pitfalls

- **OCR drift in scanned tables**: Annexe pages are often image-scans of accounting software output. Numbers like `8 300,00` may come back as `8300.00` or `8 300, 00`. Normalize to the raw number `8300.00` in JSON — the template formats with `Intl.NumberFormat` for display (`8 300 €`).
- **Two budgets, two votes**: documents often have an "Actualisation N+1" and a "Budget prévisionnel N+2" résolution. The first re-votes the current year (rarely refused); the second sets next year. Distinguish them clearly.
- **Sans vote items**: items 4–6 in many AGs are informational ("Rapport du conseil syndical", "Information sur les procédures en cours"). Mark them but don't drag the user through them in the briefing.
- **Reused résolution language**: some résolutions reference earlier ones ("Montant des honoraires du syndic pour la gestion des travaux objets de la résolution n° 22"). When summarizing, link them explicitly.
- **Blank-amount résolutions**: a résolution may say "L'assemblée générale décide de fixer à _____ € T.T.C". Mark as "amount left blank — to be decided in séance".
