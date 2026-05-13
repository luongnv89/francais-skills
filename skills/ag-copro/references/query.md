# Query playbook — answering follow-up questions from a summary

Once a summary file is loaded, every user question is answered **from the summary**, not from the source PDF. The summary is the working memory.

## Hard rules

1. **Never re-read the source PDF in Query mode** unless the user says "re-ingest", "the summary is wrong", "re-extract", or similar. The PDF is 30–60 pages — re-reading wastes context and produces inconsistencies.
2. **Match the user's question language.** French question → French answer. English question → English answer. Mixed → match the dominant language. Keep French legal terms in French even when answering in English; italicize on first mention.
3. **Cite the source within the summary.** "D'après la résolution N°10…" / "From the Annexe N°3 totals row…". Never bare-assert.
4. **If the information isn't in the summary, say so.** Offer to re-ingest. Do not invent.

## Section pattern-matching

The summary uses fixed section names (see `summary-template.md`). Route the question to the right section:

| Question hints | Section | Key fields |
|----------------|---------|-----------|
| when, date, heure, where, lieu, where is the AG, deadline, vote par correspondance, retour formulaire | **1. Meeting metadata** | meeting_date, meeting_time, meeting_location, vote_correspondence_deadline |
| vote, résolution, ordre du jour, article, majorité, sans vote, election, désignation, autorisation, "what am I voting on" | **2. Résolutions** | the résolutions table + per-résolution paragraphs |
| budget, dépense, coût, augmentation, variation, year-over-year, comparison, salaire, EDF, eau, contrat, ALUR | **3. Financial year-over-year** | total_budget_n, n_plus_1, n_plus_2, budget_delta_pct, line items |
| tantièmes, solde, je dois, créditeur, débiteur, ma part, my share, my balance, my charges | **4. Owner-specific data** | owner_name, owner_tantiemes, owner_balance_eur |
| travaux, ravalement, toiture, devis, fonds, P.P.P.T., big-ticket, what should I pay attention to | **4. Owner-specific + travaux highlights** | the "À retenir avant de voter" bullets |

If the question spans multiple sections (e.g. "explain résolution 10 and its budget impact"), combine answers from the relevant sections.

## Answer length

Default: 1–6 sentences. The user is reading on phone or tablet, often pressed for time.

Extend only when:
- The user asks "explain in detail" / "détaille" / "give me the full breakdown".
- The question is "what should I pay attention to before voting" — give the full 5–7 bullet briefing.
- The user asks a multi-part question — answer each part separately.

## Example Q→A patterns

### "When is my meeting?"
> Votre AG est prévue **le mardi 16 juin 2026 à 19h00**, à la salle de réunion de la copropriété, 4/12 Rue Maurice Berteaux, 91120 Palaiseau. Si vous votez par correspondance, le formulaire doit parvenir au syndic **avant le 12 juin 2026**.

### "Why is the budget going up?"
> Le budget passe de **49 350 € (exercice clos)** à **57 950 € (exercice à voter)**, soit **+17,4 %**. L'augmentation principale vient de la nouvelle ligne *Salaires employé d'immeuble* (13 000 € — probablement l'embauche d'un gardien) et d'une hausse marquée des contrats (désinsectisation +82 %, frais bancaires +27 %). À demander en séance : confirmation du recrutement du gardien et détail du contrat associé.

### "What's résolution 16 about?"
> Résolution N°16 : vote d'un budget de **350 € pour la pose d'un carrelage sur le balcon de la locataire du SDC** (Syndicat des Copropriétaires). Article 24, majorité simple. Faible impact financier mais inhabituel — le SDC finance des travaux pour une locataire (et non un copropriétaire). Vous pouvez demander en séance pourquoi la copropriété supporte ce coût.

### "Do I have a debt?"
> D'après l'Annexe N°6, votre solde au 31/12/2025 n'apparaît pas dans la liste des copropriétaires débiteurs/créditeurs : votre compte est donc à zéro à cette date. Si vous voulez vérifier le détail des appels de fonds, il faut consulter votre espace client IMMO DE France ou le relevé de charges courantes.

### "What should I pay attention to before voting?"
Give the full "À retenir avant de voter" briefing from section 4 of the summary, expanded slightly if useful. Lead with the highest-impact item.

## Edge cases

### User asks for a comparison the summary doesn't directly answer
Example: "How does this year's syndic fee compare to two years ago?". If the summary has N-1, N, N+1, N+2 only and the user wants N-3, say:

> Le résumé ne contient que les exercices N-1 à N+2. Pour comparer plus loin dans le passé, il faudrait consulter les convocations d'AG précédentes. Sur les années disponibles, les honoraires syndic sont passés de [x] à [y].

### User contests a number
Example: "Are you sure the budget is 57 950 €? My letter said 60 000 €."

The summary may be wrong. Offer to re-ingest:
> Vérifions. Voulez-vous que je relise le PDF ? Donnez-moi le chemin du fichier source — le résumé indique 57 950 € (résolution N°11) mais une erreur d'extraction reste possible.

### Question in English about a French-only document
Answer in English but quote the French terms verbatim:
> Your *assemblée générale* is on **Tuesday, 16 June 2026, 7:00 pm**, at the building meeting room (4/12 Rue Maurice Berteaux, 91120 Palaiseau). If you vote by mail (*vote par correspondance*), your form must reach the *syndic* by **12 June 2026**.

### User asks about something that requires the PDF
Example: "Can you read résolution N°25 verbatim?" If the summary has only a paraphrase, say so and offer to re-extract that résolution from the source. Don't fabricate.

## Closing offers

End short answers with at most one of:
- "Voulez-vous le détail d'une résolution en particulier ?" (when résolutions were summarized)
- "Souhaitez-vous comparer avec l'exercice précédent ?" (when budget was discussed)
- "Want me to flag what's worth raising in the meeting?" (when the user seems to be preparing for the AG)

Skip the closing offer for long answers or when the user's question is fully resolved.
