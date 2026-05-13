---
name: ag-copro
description: "Ingest a French Assemblée Générale (AG) PDF and answer questions on meeting date, vote deadline, year-over-year budget, résolutions, and what to watch before voting. Don't use for non-AG French docs (acte, bail), tax files, or non-French copropriété."
metadata:
  version: 1.1.0
  author: francais-skills
---

# ag-copro — Assemblée Générale assistant for French house owners

Helps a copropriétaire understand the annual AG convocation document: extract meeting info, audit the budget, flag what needs attention before voting, then answer follow-up questions in their language.

## When this skill triggers

- User shares a French AG PDF (e.g. "convocation assemblée générale", "ordre du jour", "résolutions").
- User asks "when is my AG meeting?", "what's the new budget?", "what am I voting on?", "explain résolution N°7", "compare last year vs next year budget".
- User invokes `/ag-copro` with or without a path.

Do not trigger for: French legal documents that aren't AG convocations (acte de vente, bail, état des lieux), tax/fiscal documents, non-French copropriété files.

## Workflow (single entry, two internal modes)

The skill has one entry point but two operating modes. Decide which by looking at inputs:

1. **No summary loaded yet** → **Ingest mode**. Read the PDF, extract structured content, write a summary file, then proceed to query mode with that summary in hand.
2. **Summary loaded** → **Query mode**. Answer the user's question from the summary. Never re-read the PDF unless the user explicitly asks ("re-extract", "re-ingest", "the summary is wrong").

### Routing — decide mode at start of every turn

```
1. Was a PDF path provided?
   - Yes → compute summary path; if it exists and is fresh, jump to Query mode.
          Otherwise enter Ingest mode.
2. Was a summary path or residence name provided?
   - Yes → load that summary, jump to Query mode.
3. Nothing provided?
   - List files in ~/.ag-copro/summaries/.
     - If 1+ summaries exist: ask the user to pick one, OR provide a new PDF path.
     - If empty: ask the user for a PDF path.
```

### Storage

All summaries live in `~/.ag-copro/summaries/` — a tool-neutral location so the skill works the same under Claude Code, Codex, opencode, or any other runner. Create the directory if it doesn't exist; do not assume any particular agent harness owns it.

Filename convention:

```
<residence-slug>-<year>.md
```

Examples: `le-verger-palaiseau-2026.md`, `17-rue-philippe-de-dangeau-2025.md`. The slug uses lowercase, hyphens, no accents.

If the user provides a PDF and a summary file with the same residence+year already exists, ask before overwriting — they may want to keep the old version for comparison.

## Ingest mode — extracting the AG PDF

Full playbook: see `references/ingest.md`. Quick version:

1. Read the PDF (use the `Read` tool, paging through if >20 pages — most AGs run 30–60 pages).
2. Identify the syndic (Immo de France, VPàt Immo, Foncia, Loiselet & Daigremont, etc.) so layout assumptions don't bite. Look for the logo block and the contract holder in the first 2 pages.
3. Extract these blocks in order:
   - **Meeting metadata** — date, time, location, syndic, vote-by-correspondence deadline.
   - **Resolutions** — every numbered item with its article-of-majority (Article 24/25/26/26-1) and "Sans vote" flag.
   - **Financial Y-o-Y from Annexe N°3** — totals for exercise N (just closed), N+1 (current year, often re-voted), N+2 (next year, the main vote). Line items with >20 % swing.
   - **Owner-specific data + travaux highlights** — owner's tantièmes, debit/credit balance from Annexe N°6 if listed, big-ticket travaux votes (ravalement, toiture, fonds ALUR, devis >5 000 €).
4. Write `~/.ag-copro/summaries/<slug>-<year>.md` following `references/summary-template.md`.
5. After saving, output the Step Completion Report (below), then immediately answer the user's first implicit question — "what should I pay attention to?" — with a 5-bullet briefing.

Cross-syndic note: layouts vary. **Anchor on landmarks** ("ORDRE DU JOUR", "RESOLUTION N°", "ANNEXE N°", "tantièmes", "vote par correspondance") rather than fixed page numbers.

## Query mode — answering follow-up questions

Full playbook: see `references/query.md`. Quick version:

1. Load the summary file. **Do not re-read the PDF** unless the user explicitly asks.
2. Match the question against summary sections:
   - "when / where / deadline" → Meeting metadata
   - "vote / résolution / what am I voting on / article" → Resolutions section
   - "budget / dépense / coût / augmentation / variation" → Financial Y-o-Y section
   - "tantièmes / solde / je dois / travaux / ravalement" → Owner-specific + travaux section
3. Answer in the user's question language (French if asked in French, English if asked in English). Keep French legal terms intact (*quitus*, *tantièmes*, *travaux*, *Article 25*) — translating them loses precision.
4. Always cite the resolution number or page reference if relevant.
5. If the answer isn't in the summary, say so explicitly — don't invent it. Offer to re-ingest.

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
  Saved to:           √ ~/.ag-copro/summaries/[slug]-[year].md
  ____________________________
  Result:             PASS

[5-bullet briefing of what to pay attention to before voting]
```

### After query

Plain answer, 1–6 sentences, in the user's language. Cite résolution number / annexe / page when relevant. End with a one-line offer: "Want me to dig deeper into any résolution?" — only if the answer was short and surface-level.

## Constraints

- The summary file is the source of truth in Query mode. Treat it like the user's working memory. If you contradict it, the user will lose trust.
- Never invent numbers. If the AG document leaves a field blank (e.g. `Vote d'un budget de _____ €`), say "left blank in the convocation".
- Keep French legal terms in French even when answering in English. Quote the original phrase in italics on first mention.
- Do not give legal advice. The skill explains the document; the user (or their conseil syndical / lawyer) decides how to vote.

## Reference files

- `references/ingest.md` — full extraction playbook, per-block landmarks, multi-syndic notes.
- `references/query.md` — full Q&A playbook with example question→section mappings.
- `references/summary-template.md` — canonical markdown layout for the summary file.
