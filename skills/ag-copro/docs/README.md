<!--
AI: Skip this file. It's for humans. The skill instructions live in SKILL.md.
-->

# ag-copro

Helps a French copropriétaire (joint-property owner) read and understand the **convocation d'Assemblée Générale** sent once a year by the syndic. The document is usually 30–60 pages of legal-accounting French and contains the meeting date, the agenda, the resolutions you'll vote on, and the budget for the year ahead.

## What it does

- **Ingests** the AG PDF once — extracts meeting date and location, every résolution with the article-of-majority required, the financial year-over-year breakdown (Annexe N°3), your tantièmes and personal balance, and the big-ticket *travaux* votes.
- **Renders** a single self-contained interactive HTML report in your current working directory: `./ag-<residence>-<year>.html`. Open it in any modern browser — no build, no server, just a file. Includes:
  - Hero KPIs (meeting date, vote deadline, budget, your tantièmes).
  - 5-point colour-coded "à retenir avant de voter" briefing.
  - Filterable, searchable résolutions table — toggle articles, hide procedurals, full-text search.
  - Year-over-year budget bar chart + a horizontal-bar of the top-variation account lines.
  - Donut + per-chantier progress cards for ongoing *travaux*.
  - Owner-specific cards (tantièmes, fonds ALUR, balance Annexe N°6).
  - "Imprimer / PDF" button that hides interactive controls for clean printing.
- **Embeds the full structured data as JSON** inside the HTML, so:
  - You can come back days or weeks later and the report is still there.
  - The skill can answer follow-up questions from the same file without re-reading the PDF.
- **Answers** follow-up questions from the embedded data, in French or English. Examples:
  - "When is my AG and how do I vote by correspondence?"
  - "Why is next year's budget 17 % higher?"
  - "What's résolution N°16 about and why should I care?"
  - "What are the three things I should pay attention to before voting?"

## Workflow

```
You: /ag-copro /path/to/convocation.pdf
Skill: [reads the PDF, writes ./ag-le-verger-a-palaiseau-2026.html,
        prints a 3-line briefing recap, points you at the file]

You: open ./ag-le-verger-a-palaiseau-2026.html
[your browser shows the interactive report]

(days later, new conversation)

You: /ag-copro
Skill: I see one report: ./ag-le-verger-a-palaiseau-2026.html. Continue with that?
You: yes — what's the deadline to vote by mail?
Skill: 12 June 2026. Send the form to chrystel.fayette@immodefrance.com or to the
       Versailles office. Note: form must be received 3 jours francs before the meeting.
```

## What's in the HTML

Open the report in a browser. The page is structured top-to-bottom:

1. Sticky nav (hidden in print) with section anchors.
2. Hero — residence name, year chip, 4 KPI cards.
3. §1 La réunion — date, location, syndic, dossier ref, vote-by-correspondence panel.
4. §2 À retenir avant de voter — the 3–7 most important points, colour-coded by severity.
5. §3 Résolutions — donut chart of articles + filterable table with search and toggles.
6. §4 Budget — dark band with totals bar chart, key-takeaway card, top-variation horizontal bar.
7. §5 Travaux — donut of paid vs outstanding + per-chantier progress cards (hidden if no data).
8. §6 Mon lot — owner identity, tantièmes, fonds ALUR, balance.
9. Footer — generation date + legal disclaimer.

## Supported syndics

Tested layouts:
- **Immo de France** (Paris IDF)
- **VPàt Immo** (Versailles)

Untested but should work via landmark-based parsing:
- Foncia, Citya, Nexity, Loiselet & Daigremont, and any other syndic following the standard French AG structure (loi du 10/07/1965, décret 67-223).

If the parsing misses things on your syndic's layout, run the skill anyway and report what was missed — the playbook can be extended.

## What it deliberately doesn't do

- **No legal advice.** The skill explains the document; you (or your conseil syndical / avocat) decide how to vote.
- **No vote casting.** The skill doesn't fill out the formulaire de vote par correspondance for you. It only tells you the deadline and what's at stake.
- **No multi-document comparison out of the box.** One residence at a time. If you have AGs from multiple years, you can ingest them one by one — each writes its own HTML file in the current directory.
- **No non-AG documents.** Not for actes de vente, baux, états des lieux, or fiscal documents.

## File locations

- Output: wherever you run the skill (current working directory). Use `cd` to control where the file lands.
- Source PDFs: wherever you store them (the JSON inside the HTML records the absolute path).

The HTML is **self-contained** and **tool-neutral**: it uses public CDNs (Tailwind, Chart.js, Google Fonts) and parses fine in Claude Code, Codex, opencode, or any agent runner that loads this skill.

## Limitations

- French language UI is the default. Pass `language: "en"` in the JSON for English labels (preserves French legal terms verbatim).
- The skill reads page-by-page; PDFs > 60 pages may need manual chunking.
- Scanned-image PDFs work but with reduced accuracy on Annexe tables (OCR drift on numbers).
- Owner-specific balance extraction depends on the syndic including Annexe N°6. Some don't.
- The report depends on three public CDNs (cdn.tailwindcss.com, cdn.jsdelivr.net/chart.js, fonts.googleapis.com). Offline use degrades the visual styling but the embedded JSON remains valid.

## License

Same as the parent francais-skills project.
