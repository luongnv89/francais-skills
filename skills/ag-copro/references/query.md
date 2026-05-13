# Query playbook — answering follow-up questions from the HTML report

Once a report is loaded, every user question is answered **from the JSON data embedded in the HTML**, not from the source PDF. The JSON is the working memory.

## Loading the report

1. Identify the HTML file. Options:
   - The user gave a path. Use it.
   - The user named a residence ("le verger"). Glob CWD for `ag-<slug>-*.html`; if 1 match, use it; if multiple, ask.
   - No hint. Glob CWD for `ag-*.html` and list them; ask the user to pick.
2. `Read` the HTML file.
3. Extract the JSON block between `<script type="application/json" id="ag-data">` and the next `</script>`. Use a regex or split on those exact strings.
4. `JSON.parse` (or `json.loads`) the block. This is `data`.

If the file lacks a valid JSON block (corrupted, hand-edited, old format), tell the user and offer to re-ingest.

## Hard rules

1. **Never re-read the source PDF in Query mode** unless the user explicitly says "re-ingest", "the report is wrong", "re-extract", or similar. The PDF is 30–60 pages — re-reading wastes context and produces inconsistencies.
2. **Match the user's question language.** French question → French answer. English question → English answer. Mixed → match the dominant language. Keep French legal terms in French even when answering in English; italicize on first mention.
3. **Cite the source within the report.** "D'après la résolution N°10…" / "From the `budget.n_plus_2_eur` field of the report…". Never bare-assert.
4. **If the information isn't in the JSON, say so.** Offer to re-ingest. Do not invent.

## JSON field → question routing

The full schema is in `html-template.md`. Map user-question hints to JSON fields:

| Question hints | JSON path | Notes |
|----------------|-----------|-------|
| when, date, heure, where, lieu, deadline, vote par correspondance, retour formulaire | `data.meeting.*` | `date_fr` for prose, `date` for arithmetic |
| vote, résolution, ordre du jour, article, majorité, sans vote, "what am I voting on" | `data.resolutions[]` | Filter by `num`, `tag`, or `article` |
| budget, dépense, coût, augmentation, variation, year-over-year | `data.budget.*` + `data.budget_lines[]` | `delta_pct` is the headline number |
| line item, compte, account, salaire, EDF, eau, contrat, ALUR | `data.budget_lines[]` | Find by `compte` or `label` substring |
| tantièmes, solde, je dois, créditeur, débiteur, ma part, my balance | `data.owner.*` | `balance_eur === null` means "not listed in Annexe N°6" |
| fonds ALUR, fonds travaux | `data.owner.fonds_alur_eur` | per-owner quote-part |
| travaux, ravalement, toiture, chantier, devis | `data.travaux[]` + résolutions with `tag === "travaux"` | |
| what should I pay attention to, retenir, briefing | `data.briefing[]` | Order is intentional — render in order |
| syndic, contrat, honoraires | résolutions with `tag === "syndic"`, often `article === "25"` | |

If the question spans multiple sections, combine fields.

## Answer length

Default: 1–6 sentences. The user is reading on phone or tablet, often pressed for time.

Extend only when:
- The user asks "explain in detail" / "détaille" / "give me the full breakdown".
- The question is "what should I pay attention to before voting" — render the entire `briefing` array.
- The user asks a multi-part question — answer each part separately.

## Example Q→A patterns

### "When is my meeting?"
> Votre AG est prévue **le mardi 16 juin 2026 à 19h00**, à la salle de réunion de la copropriété, 4/12 Rue Maurice Berteaux, 91120 Palaiseau. Si vous votez par correspondance, le formulaire doit parvenir au syndic **avant le 12 juin 2026**.

Source fields: `data.meeting.date_fr`, `data.meeting.time`, `data.meeting.location`, `data.meeting.vote_correspondence_deadline_fr`.

### "Why is the budget going up?"
> Le budget passe de **49 350 € (exercice clos)** à **57 950 € (exercice à voter)**, soit **+17,4 %**. La hausse vient principalement de deux nouvelles lignes : *781 Émetteurs* (+7 800 €) et *921 Eau froide* (+13 000 €), partiellement compensées par la fin de la ligne *466 Travaux sinistre* (-13 000 €). À demander en séance : que recouvrent précisément ces nouveaux postes ?

Source: `data.budget.n_eur`, `data.budget.n_plus_2_eur`, `data.budget.delta_pct`, top entries of `data.budget_lines` sorted by `n_plus_2 - n_vote`.

### "What's résolution 16 about?"
> Résolution N°16 : vote d'un budget de **350 € pour la pose d'un carrelage sur le balcon de la locataire du SDC**. Article 24 (majorité simple). Faible impact financier mais inhabituel — le SDC finance des travaux pour une locataire (et non un copropriétaire). Vous pouvez demander en séance pourquoi la copropriété supporte ce coût.

Source: `data.resolutions[].find(r => r.num === "16")` — read its `title`, `article`, `summary`.

### "Do I have a debt?"
> D'après l'Annexe N°6, votre solde au 31/12/2025 n'apparaît pas dans la liste des copropriétaires débiteurs/créditeurs : votre compte est donc à zéro à cette date. Si vous voulez vérifier le détail des appels de fonds, il faut consulter votre espace client IMMO DE France ou le relevé de charges courantes.

Source: `data.owner.balance_eur === null` plus `data.owner.balance_note`.

### "What should I pay attention to before voting?"
Render the entire `data.briefing` array — title, body, résolution refs, article — ordered as stored. Lead with the highest-severity items (the JSON already sorts them).

### "Export the report" / "Refresh the HTML" / "Regenerate"
The user already has a JSON-backed report. Re-render without re-reading the PDF:
1. Read the existing HTML, extract the JSON.
2. Read `references/html-template.html`.
3. Substitute fresh placeholders (the JSON, lang, year, residence title).
4. Write back to the same filename — or, if the user wants a different name, the new one.

This is also the recovery path if the user hand-edited the HTML and broke a chart.

## Edge cases

### User asks for a comparison the JSON doesn't directly answer
Example: "How does this year's syndic fee compare to two years ago?". If `data.budget` only carries N to N+2 and the user wants N-3, say:

> Le rapport ne contient que les exercices N à N+2. Pour comparer plus loin dans le passé, il faudrait consulter les convocations d'AG précédentes. Sur les exercices disponibles, les honoraires syndic sont passés de [x] à [y].

### User contests a number
Example: "Are you sure the budget is 57 950 €? My letter said 60 000 €."

The JSON may be wrong. Offer to re-ingest:
> Vérifions. Voulez-vous que je relise le PDF ? Donnez-moi le chemin du fichier source — le rapport indique 57 950 € (résolution N°11) mais une erreur d'extraction reste possible.

### Question in English about a French-only document
Answer in English but quote the French terms verbatim:
> Your *assemblée générale* is on **Tuesday, 16 June 2026, 7:00 pm**, at the building meeting room (4/12 Rue Maurice Berteaux, 91120 Palaiseau). If you vote by mail (*vote par correspondance*), your form must reach the *syndic* by **12 June 2026**.

### User asks about something that needs the original PDF text
Example: "Can you read résolution N°25 verbatim?" The JSON has a `summary` (paraphrase) and a `title` — not the full original text. Say so:
> Le rapport stocke un résumé de la résolution, pas son texte intégral. Voulez-vous que je relise la page correspondante du PDF source pour vous citer le passage exact ?

## Closing offers

End short answers with at most one of:
- "Voulez-vous le détail d'une résolution en particulier ?" (when résolutions were summarized)
- "Souhaitez-vous comparer avec l'exercice précédent ?" (when budget was discussed)
- "Voulez-vous régénérer le rapport HTML ?" (when the user mentions sharing or printing)
- "Want me to flag what's worth raising in the meeting?" (when the user seems to be preparing for the AG)

Skip the closing offer for long answers or when the user's question is fully resolved.
