# francais-skills

**Compétences IA pour faciliter la vie en France.**

Une collection de *skills* (compétences) pour assistants IA, conçues pour aider les personnes qui vivent en France à comprendre, analyser et gérer les documents et tâches du quotidien français : convocations d'assemblée générale de copropriété, formulaires administratifs, courriers du syndic, démarches officielles, etc.

> Ces skills fonctionnent avec **Claude Code**, **Codex**, **opencode**, ou tout autre runner compatible avec le format de skills standard. Le code est neutre vis-à-vis de l'outil — aucun chemin de stockage ne dépend d'un agent particulier.

---

## Pourquoi ce dépôt ?

La vie administrative en France s'accompagne de beaucoup de documents : convocations d'AG de 50 pages, devis de travaux, courriers du syndic, formulaires CAF, avis d'imposition, baux, états des lieux… Ces documents sont rédigés dans un français juridique-administratif dense, plein de termes techniques (*tantièmes*, *quitus*, *recommandée avec AR*, *trêve hivernale*) qui décourage la lecture.

Ce dépôt rassemble des **skills réutilisables** qui :

- ingèrent un document une seule fois,
- en extraient les informations qui comptent (dates, montants, votes, échéances),
- permettent de poser des questions de suivi en français ou en anglais,
- ne donnent **jamais de conseils juridiques** — l'assistant explique, l'utilisateur décide.

---

## Skills disponibles

### `ag-copro` — Assistant pour les Assemblées Générales de copropriété

Aide un copropriétaire à comprendre la convocation annuelle d'Assemblée Générale (AG) envoyée par le syndic.

- **Ingère** le PDF de la convocation (30–60 pages) une seule fois.
- **Extrait** : date et lieu de la réunion, date limite du vote par correspondance, toutes les résolutions avec l'article de majorité requis (24, 25, 26), comparaison du budget année par année (Annexe N°3), tantièmes du propriétaire, solde débiteur/créditeur, points de vigilance (gros travaux, devis, ravalement).
- **Répond** aux questions ultérieures à partir du résumé sauvegardé, sans relire le PDF complet.

**Exemples de questions :**

```
"À quelle date est mon AG et comment voter par correspondance ?"
"Pourquoi le budget augmente de 17 % cette année ?"
"Que veut dire la résolution N°16 et pourquoi elle est inhabituelle ?"
"Quels sont les trois points auxquels je dois faire attention avant de voter ?"
```

**Syndics testés :** Immo de France, VPàt Immo.
**Syndics compatibles (parsing par repères) :** Foncia, Citya, Nexity, Loiselet & Daigremont, et tout syndic suivant la structure standard (loi du 10/07/1965, décret 67-223).

Détails techniques et limites : [`skills/ag-copro/docs/README.md`](skills/ag-copro/docs/README.md).

### *À venir*

Idées de skills futures :

- `bail-locataire` — analyser un bail, repérer les clauses abusives, calculer les charges récupérables.
- `etat-des-lieux` — comparer deux états des lieux (entrée/sortie) et estimer les retenues sur dépôt de garantie.
- `avis-imposition` — relire un avis d'imposition, vérifier les rubriques, simuler l'année suivante.
- `caf-courrier` — comprendre un courrier de la CAF et identifier la marche à suivre.
- `devis-travaux` — comparer plusieurs devis d'artisan, repérer les lignes douteuses, vérifier la TVA.

Si vous avez besoin d'une de ces skills (ou d'une autre), [ouvrez une issue](https://github.com/luongnv89/francais-skills/issues/new) en décrivant le document et les questions que vous voulez pouvoir poser.

---

## Installation

### Avec Claude Code

```bash
# Cloner le dépôt
git clone https://github.com/luongnv89/francais-skills.git
cd francais-skills

# Copier la skill dans le répertoire des skills Claude Code
mkdir -p ~/.claude/skills
cp -r skills/ag-copro ~/.claude/skills/
```

Puis dans Claude Code : `/ag-copro /chemin/vers/votre-convocation.pdf`.

### Avec Codex

```bash
git clone https://github.com/luongnv89/francais-skills.git
cd francais-skills

# Codex lit les skills depuis ~/.codex/skills/
mkdir -p ~/.codex/skills
cp -r skills/ag-copro ~/.codex/skills/
```

### Avec opencode

```bash
git clone https://github.com/luongnv89/francais-skills.git
cd francais-skills

# opencode lit les skills depuis ~/.opencode/skills/
mkdir -p ~/.opencode/skills
cp -r skills/ag-copro ~/.opencode/skills/
```

### Avec un autre runner

La structure d'une skill est standard : un fichier `SKILL.md` à la racine, un dossier `references/` pour les playbooks détaillés, un dossier `docs/` pour la documentation humaine. Copiez le dossier `skills/ag-copro/` à l'emplacement attendu par votre runner.

---

## Où sont stockés les résumés ?

Les résumés produits par les skills sont sauvegardés dans `~/.ag-copro/summaries/` (chemin neutre, indépendant de l'outil utilisé). Si vous changez de runner (Claude → Codex), vos résumés restent accessibles.

Format des fichiers : Markdown avec un en-tête YAML structuré. Vous pouvez les lire directement, les sauvegarder, ou les transmettre à un autre membre de la copropriété.

---

## Confidentialité

- **Aucune donnée n'est envoyée à un service tiers** par les skills elles-mêmes. Tout reste sur votre machine.
- Le runner que vous utilisez (Claude Code, Codex, opencode…) peut, lui, envoyer vos documents à son fournisseur LLM. Vérifiez sa politique de confidentialité avant de lui faire lire des documents sensibles.
- Les exemples de PDF qui ont servi à tester `ag-copro` **ne sont pas inclus dans ce dépôt** — ils contiennent des données personnelles (nom, adresse, soldes financiers).

---

## Contribuer

Les contributions sont bienvenues, notamment :

- **Ajouter le support d'un nouveau syndic** dans `skills/ag-copro/references/ingest.md` (la section "Multi-syndic notes").
- **Créer une nouvelle skill** pour un type de document français (bail, avis d'imposition, courrier CAF…).
- **Améliorer les playbooks** : si une skill se trompe sur votre document, ouvrez une issue avec le type de document et l'erreur observée. **N'envoyez pas le document original** s'il contient des données personnelles — décrivez la structure ou anonymisez.

### Créer une nouvelle skill

Chaque skill suit la structure suivante :

```
skills/ma-skill/
├── SKILL.md              # Point d'entrée (frontmatter YAML + instructions)
├── docs/README.md        # Documentation humaine
├── references/           # Playbooks détaillés (un par mode si besoin)
│   ├── ingest.md
│   └── query.md
└── evals/evals.json      # Cas de test
```

Le fichier `SKILL.md` contient un en-tête YAML avec `name`, `description`, `metadata.version`, `metadata.author`. La `description` est la phrase qui déclenche la skill — soyez précis sur le quand et le pourquoi, et **incluez une clause négative** ("Ne pas utiliser pour…") pour éviter les déclenchements inopportuns.

---

## Licence

[MIT](LICENSE). Utilisez librement, modifiez, redistribuez. Si vous améliorez une skill, pensez à proposer un pull request — ça aidera tout le monde.

---

## Avertissement

Ces skills sont des **aides à la lecture et à la compréhension**. Elles ne remplacent pas :

- un avis juridique professionnel (avocat, notaire),
- un conseil financier (expert-comptable, syndic),
- la lecture personnelle du document avant un vote ou une signature.

Si une décision importante dépend du contenu d'un document (vote en AG, signature de bail, déclaration fiscale), **lisez le document vous-même** et consultez un professionnel en cas de doute.
