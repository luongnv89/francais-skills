<!--
AI: Skip this file. It's for humans. The skill instructions live in SKILL.md.
-->

# ag-copro

Helps a French copropriétaire (joint-property owner) read and understand the **convocation d'Assemblée Générale** sent once a year by the syndic. The document is usually 30–60 pages of legal-accounting French and contains the meeting date, the agenda, the resolutions you'll vote on, and the budget for the year ahead.

## What it does

- **Ingests** the AG PDF once — extracts meeting date and location, every résolution with the article-of-majority required, the financial year-over-year breakdown (Annexe N°3), your tantièmes and personal balance, and the big-ticket *travaux* votes.
- **Saves** a structured summary to `~/.ag-copro/summaries/<residence>-<year>.md`. You can come back days or weeks later and the summary is still there.
- **Answers** follow-up questions from the summary, in French or English. You can ask things like:
  - "When is my AG and how do I vote by correspondence?"
  - "Why is next year's budget 17 % higher?"
  - "What's résolution N°16 about and why should I care?"
  - "What are the three things I should pay attention to before voting?"

## Workflow

```
You: /ag-copro /path/to/convocation.pdf
Skill: [reads the PDF, writes the summary, briefs you in 5 bullets]

(days later, new conversation)

You: /ag-copro
Skill: I see one ingested AG: "le-verger-a-palaiseau-2026". Continue with that?
You: yes — what's the deadline to vote by mail?
Skill: 12 June 2026. Send the form to chrystel.fayette@immodefrance.com or to the
       Versailles office. Note: form must be received 3 jours francs before the meeting.
```

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
- **No multi-document comparison out of the box.** One residence at a time. If you have AGs from multiple years, you can ingest them one by one and compare manually by referencing two summary files.
- **No non-AG documents.** Not for actes de vente, baux, états des lieux, or fiscal documents.

## File locations

- Summaries: `~/.ag-copro/summaries/<residence-slug>-<year>.md`
- Source PDFs: wherever you store them (the summary records the absolute path).

The storage path is **tool-neutral**: it doesn't live under `~/.claude/`, so the same summary file is reachable from Claude Code, Codex, opencode, or any other agent runner that loads this skill.

## Limitations

- French language only.
- The skill reads page-by-page; PDFs > 60 pages may need manual chunking.
- Scanned-image PDFs work but with reduced accuracy on Annexe tables (OCR drift on numbers).
- Owner-specific balance extraction depends on the syndic including Annexe N°6. Some don't.

## License

Same as the parent francais-skills project.
