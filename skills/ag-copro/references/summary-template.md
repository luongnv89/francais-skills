# Summary template — canonical layout for `~/.ag-copro/summaries/<slug>-<year>.md`

The summary file is plain Markdown with a YAML frontmatter header. Stable section order matters — Query mode pattern-matches on section names.

## Required structure

```markdown
---
residence: "LE VERGER A PALAISEAU"
address: "4/12 Rue Maurice Berteaux, 91120 Palaiseau"
syndic: "IMMO DE FRANCE PARIS IDF"
meeting_date: "2026-06-16"
meeting_time: "19:00"
meeting_location: "Salle de réunion de la copropriété, 4/12 Rue Maurice Berteaux, 91120 Palaiseau"
vote_correspondence_deadline: "2026-06-12"
source_pdf: "/abs/path/to/source.pdf"
source_pdf_pages: 51
ingested_at: "2026-05-13"
language: "fr"
owner_name: "M. NGUYEN Van Luong"
owner_tantiemes: 233
owner_balance_eur: null       # null if not in document, otherwise number (positive=créditeur, negative=débiteur)
total_budget_n: 49350.00       # exercise just closed
total_budget_n_plus_1: 57950.00 # current exercise, often re-voted (actualisation)
total_budget_n_plus_2: 57950.00 # next exercise — the main vote
budget_delta_pct: 17.4          # (N+2 / N - 1) * 100, rounded 1 decimal
resolutions_total: 19
resolutions_sans_vote: 3
---

# Assemblée Générale — [residence] — [year]

## 1. Meeting metadata

- **Date / heure** : [Mardi 16 juin 2026 à 19h00]
- **Lieu** : [adresse complète]
- **Syndic** : [nom]
- **Date limite vote par correspondance** : [date — quote the exact phrase from the form]
- **Adresse pour retourner le formulaire** : [email + adresse postale]

## 2. Résolutions

| # | Titre | Article | Vote | Notes |
|---|-------|---------|------|-------|
| 1 | Election du président de séance | 24 | oui | procédural |
| 4 | Point sur le dossier ravalement : Présence du Cabinet TECHMO | — | sans vote | informatif |
| 7 | Approbation des comptes de l'exercice clos au 31/12/2025 | 24 | oui | |
| ... | | | | |

After the table, add one paragraph per **non-trivial** resolution (skip procedural items 1–3) explaining what it means in plain language. 1–3 sentences each. Quote any euro amount from the document.

Example:
> **Résolution 10 — Actualisation du budget prévisionnel de l'exercice en cours.** Le syndic demande d'ajuster le budget de l'exercice actuel à **57 950 €** (au lieu des 49 350 € votés l'an dernier). L'augmentation est répartie sur les appels trimestriels non encore échus. Article 24 (majorité simple).

## 3. Financial year-over-year (Annexe N°3)

### Totaux

| Période | Montant (€) | Variation vs N |
|---------|-------------|----------------|
| N (exercice clos) | 49 350,00 | — |
| N+1 (en cours, voté) | 57 950,00 | +17,4 % |
| N+2 (à voter) | 57 950,00 | +17,4 % |

### Lignes notables (variation > 20 %)

Only include line items whose N+2 vs N delta is greater than 20 % or whose absolute change is greater than 500 €. For each, show: account label, N approved, N realized (if shown), N+1 voted, N+2 to vote, % change, and a one-line plausible explanation (or "no explanation given").

| Compte | N approuvé | N réalisé | N+1 voté | N+2 à voter | Δ vs N | Note |
|--------|-----------|----------|---------|------------|--------|------|
| 321 SALAIRES EMPLOYÉ D'IMMEUBLE | — | 1 256,35 | 13 000 | 13 000 | nouvelle ligne | embauche de gardien probable |
| 162 CONTRAT DESINSECTISATION | 275 | — | 600 | 500 | +82 % | |
| 354 FRAIS BANCAIRES | 115 | 118 | 150 | 150 | +27 % | |

### Travaux & opérations exceptionnelles (Annexe N°2 / N°4)

If the document includes a separate works ledger, list ongoing operations:
- **TM RAVALTGARDE CORPS/ISOLATION A** — voted 732 279,29 € le 15/02/2024 — paid to date: 522 944,69 € — solde en attente: 378 947,20 €
- ...

## 4. Owner-specific data & travaux highlights

### Owner status

- **Nom** : M. NGUYEN Van Luong
- **Tantièmes représentés** : 233
- **Solde au 31/12/[N]** : [montant € — créditeur / débiteur, or "non listé dans l'Annexe N°6"]

### À retenir avant de voter (3 to 7 bullets)

The most important section for the user. Each bullet:
- Names the résolution number.
- States the financial impact (or "no euro amount") and the majority required.
- Says in one sentence why it matters.

Example:
> - **Résolutions 10 & 11** — Budget prévisionnel passe de 49 350 € à 57 950 € (+17,4 %). La hausse principale vient de la nouvelle ligne *salaires employé d'immeuble* (13 000 €). À demander en séance : embauche de gardien ? Article 24.
> - **Résolution 16** — Budget de 350 € pour pose d'un carrelage sur le balcon de la locataire du SDC. Faible impact mais inhabituel : faire confirmer pourquoi la copropriété finance des travaux chez un locataire. Article 24.
> - **Résolution 19** — Demande d'autorisation pour poser 2 bâches publicitaires sur le bâtiment A afin de percevoir une rémunération. Décision réversible mais affecte l'esthétique du bâtiment. Article 25 (majorité absolue).

## 5. Raw extraction notes (for debugging)

- Layout: [Immo de France / VPàt Immo / other]
- Pages successfully parsed: [list]
- Anything skipped or unclear: [list]
```

## Notes on filling the template

- **All monetary values in EUR.** Use `,` as decimal separator in French prose ("57 950,00 €") and `.` in the YAML frontmatter (`57950.00`). Keep both — humans read the prose, future code reads the frontmatter.
- **Dates in ISO format in frontmatter** (`YYYY-MM-DD`). In prose, use the French form quoted from the document.
- **Null values**: if a field isn't in the document, write `null` in frontmatter and "non précisé dans la convocation" in prose. Never invent.
- **Don't truncate the résolutions list.** Include every numbered item, even the boring procedural ones — Query mode needs them to answer "what's résolution N°12 about?"
- **Section order is fixed.** Query mode pattern-matches on the H2 headings (`## 1. Meeting metadata`, etc.). Renaming them breaks Q&A.
