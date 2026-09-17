---
title: L'intégration continue avec Git
slug: "git-ci"
weight: 42
---
# L'intégration continue avec Git

## À quoi sert l'intégration continue

L'intégration continue, ce n'est pas « nous avons un serveur de build ». Un serveur de build est
une machine. L'intégration continue est une *promesse*, et cette promesse a deux moitiés :

1. la ligne principale est toujours connue comme bonne, si bien que n'importe qui peut en tirer
   une branche à tout moment sans hériter du désordre de quelqu'un d'autre ;
2. le retour arrive pendant que l'auteur se souvient encore du changement.

La seconde moitié est celle que les gens sous-estiment. Un test qui échoue et vous parvient en
quatre-vingt-dix secondes est une petite contrariété. Le même échec qui vous parvient demain matin
est une fouille archéologique, parce que vous avez déjà commencé autre chose et que votre tête est
vide du contexte qui aurait rendu le bogue évident.

C'est aussi pourquoi l'intégration continue et le développement sur tronc commun sont la même idée
vue sous deux angles. « Intégrer constamment de petits changements dans la ligne principale » et
« garder la ligne principale au vert » sont les deux moitiés d'une seule phrase : on ne peut
intégrer constamment que si la ligne principale est digne de confiance, et la ligne principale ne
le reste que si tout le monde intègre de petits changements. Les branches de longue durée sont la
manière dont les équipes se retrouvent avec de grosses fusions effrayantes ; l'intégration
continue est la manière dont elles cessent d'en avoir besoin. Nous avons discuté du versant
« branches » de cet argument dans
[Un peu de structure SVP](../2-collaborating/4-git-repo-structure.md "Un peu de structure SVP").

## Ce que le système d'intégration continue reçoit réellement

Ceci est un cours sur Git, alors regardons le mécanisme plutôt que le tableau de bord d'un
éditeur.

Quand vous faites `git push`, le serveur fait deux choses. Il met à jour une référence — puis il
dit à ses abonnés, en HTTP, qu'une référence a bougé. Cette notification est le webhook, et
conceptuellement elle transporte très peu de chose :

```console
ref:    refs/heads/my-feature
before: 9c4f1b0e1a1c0f8b6d5a34e2b7c8d9e0f1a2b3c4
after:  3f2e1d0c9b8a77665544332211ffeeddccbbaa99
repo:   you/your-project
pusher: you@example.com
```

C'est le même triplet `<oldrev> <newrev> <refname>` qu'un hook `pre-receive` ou `post-receive` lit
sur son entrée standard — nous en écrirons un à la main au
[chapitre suivant](3-git-static-site.md "Déployer un site statique tout simple"). Un système
d'intégration continue hébergé est un hook `post-receive` auquel on a attaché une jolie page web,
et chaque chose astucieuse qu'il fait est bâtie sur ces trois valeurs plus un clone.

Le runner clone ensuite votre dépôt, en extrait quelque chose, et exécute vos commandes. Deux de
ces étapes méritent un regard appuyé, parce que toutes deux cachent des pièges.

## Les clones superficiels, et ce qu'ils cassent

Cloner dix ans d'historique pour faire tourner un test de cinq secondes est du gaspillage, donc
les systèmes d'intégration continue clonent superficiellement par défaut. Chez GitHub Actions
c'est `actions/checkout` avec `fetch-depth: 1` — un commit, pas d'historique. GitLab appelle cela
`GIT_DEPTH`.

C'est un gain de vitesse réel, et cela casse quatre choses :

* `git describe --tags` — il n'y a ni étiquettes ni historique, donc l'estampillage de version
  échoue ou ment.
* L'archéologie par `git log`, `git blame`, `git bisect` — il n'y a rien à parcourir.
* « ce qui a changé depuis la branche de base » — la branche de base n'est pas du tout dans le
  clone.
* Tout outil qui calcule une version ou un journal des changements à partir de l'historique :
  `semantic-release`, `git-cliff`, et compagnie.

Donc : `fetch-depth: 0` sur les travaux qui ont besoin de l'historique, `fetch-depth: 1` sur ceux
qui n'en ont pas besoin. Le mode de défaillance est assez déroutant pour mériter un avertissement.

> :warning:
> Un clone superficiel peut faire produire à une commande *correcte* une *mauvaise réponse* plutôt
> qu'une erreur. `git describe --tags --always` dans un clone de profondeur 1 affiche
> tranquillement le **SHA** abrégé et sort avec un code zéro, si bien que votre artefact est
> estampillé `3f2e1d0` au lieu de `v1.4.2` et que personne ne le remarque avant un incident.

Le clone partiel est l'option moderne plus chirurgicale — `git clone --filter=blob:none` récupère
tous les commits et tous les arbres mais aucun contenu de fichier tant que rien ne le demande.
Vous obtenez un véritable historique et un petit téléchargement. La prise en charge par les
runners d'intégration continue est inégale ; cela vaut le coup d'essayer quand un clone complet
est la partie la plus lente de votre build.

## Quel commit l'intégration continue teste-t-elle, au juste ?

Voici la chose la plus déroutante de l'intégration continue, et presque aucun tutoriel ne
l'explique.

Quand vous ouvrez une pull request, la plupart des systèmes ne testent **pas** votre branche. Ils
testent une *fusion* de votre branche dans la branche cible — un commit qui n'existe dans aucun
dépôt vous appartenant.

GitHub matérialise cela sous la forme d'une paire de références côté serveur, et vous pouvez les
voir avec du Git tout simple. Voici la vraie sortie d'une vraie commande contre le dépôt du projet
Git lui-même :

```console
$ git ls-remote https://github.com/git/git 'refs/pull/100/*'
d604669e32e847c2ba5010c89895dd707ba45f55	refs/pull/100/head
55ab0c9399879683b4cc6e1baea5dc41484ca52f	refs/pull/100/merge
```

* `refs/pull/100/head` est la pointe de la branche du contributeur, exactement telle qu'il l'a
  poussée.
* `refs/pull/100/merge` est un commit de fusion que GitHub a *créé* en fusionnant cette branche
  dans la branche cible telle qu'elle est en ce moment. Personne n'a tapé `git merge`. Il
  n'apparaît dans le `git log` de personne. Il est recalculé dès que l'un des deux côtés bouge.

Par défaut, `actions/checkout` extrait la référence `merge` lors d'un événement `pull_request`.
GitLab fait la même chose sous `refs/merge-requests/<n>/merge` (avec la pointe de la branche à
`refs/merge-requests/<n>/head`), et le pipeline qui la teste s'appelle un *merged results
pipeline*.

Deux conséquences en découlent, et toutes deux expliquent des choses que vous avez probablement
vécues.

**« Ça a passé l'intégration continue et ensuite ça a cassé `main`. »** En général, non. La
référence de fusion a été calculée contre `main` telle qu'elle était il y a une heure. Entre ce
moment-là et votre bouton de fusion, trois autres pull requests ont atterri. Le commit que
l'intégration continue a béni et le commit qui a fini sur `main` sont des commits différents, et
personne n'a jamais testé le second.

**« Le diff que l'intégration continue me montre n'est pas mon diff. »** Si vous testez la
référence de fusion, `HEAD` est un commit de fusion dont le premier parent est `main`, donc
`HEAD~1` est *le commit de quelqu'un d'autre*. Tout script qui raisonne sur « le dernier commit »
est désormais silencieusement faux.

Les files de fusion sont le remède. Au lieu de fusionner quand vous cliquez, la plateforme met
votre pull request dans une file, construit une branche temporaire contenant `main` **plus les
changements qui vous précèdent dans la file** plus les vôtres, et teste *cela*. Ce n'est que si
c'est vert que le lot atterrit. GitHub appelle cela la merge queue et émet un événement
`merge_group` distinct que votre workflow doit écouter ; GitLab appelle cela les merge trains. Si
votre équipe est assez grande pour avoir ressenti la course, vous en voulez une.

### Extraire une pull request en local

Ces références sont récupérables, ce qui est l'astuce la plus utile de ce chapitre pour les
relecteurs :

```console
git fetch origin pull/100/head:pr-100
git switch pr-100
```

Sur GitLab :

```console
git fetch origin merge-requests/100/head:mr-100
git switch mr-100
```

Vous avez maintenant les véritables commits du contributeur sous forme de **branche** locale, et
vous pouvez les construire, les exécuter, les parcourir avec `git log` et les comparer avec
`git range-diff` au tour de relecture précédent. Cela fonctionne sur n'importe quelle pull request
de n'importe quel dépôt public, y compris ceux où vous ne pouvez pas pousser.

> :information_source:
> `git fetch origin pull/100/head:pr-100`, ce n'est que la syntaxe de refspec vue dans
> [Travailler avec des dépôts distants](../2-collaborating/2-git-remote.md "Travailler avec des dépôts distants") :
> référence source à gauche, destination locale à droite.
> Rien de spécial ne se passe — la forge publie simplement des références supplémentaires en
> dehors de `refs/heads/`, et c'est pourquoi `git clone` ne les emporte pas par défaut.

## Calculer correctement l'ensemble des fichiers modifiés

La moitié de l'intégration continue en monorepo tient dans la question « quels fichiers ont changé
dans cette pull request ? », et la réponse naïve est fausse. Regardez. Une branche avec deux
commits, touchant chacun un fichier différent :

```console
$ git diff --name-only HEAD~1..HEAD
web.py
$ git diff --name-only $(git merge-base origin/main HEAD)..HEAD
api.py
web.py
```

`HEAD~1` veut dire « le commit précédent », c'est-à-dire votre *avant-dernier* changement, pas le
point où votre travail a commencé. Tout changement plus ancien que votre dernier commit lui est
invisible — et sur une référence de fusion, `HEAD~1` n'est même pas de vous.

La bonne question est « qu'est-ce qui a changé depuis que cette branche a quitté la ligne
principale ? », ce qui est exactement la **base de fusion** :

```console
git diff --name-only $(git merge-base origin/main HEAD)..HEAD
```

Depuis Git 2.30 il existe un raccourci qui calcule la base de fusion pour vous, et c'est celui à
retenir :

```console
git diff --name-only --merge-base origin/main HEAD
```

`git diff --name-only origin/main...HEAD` — trois points — fait la même chose, et c'est la forme
que vous verrez dans les scripts plus anciens.

> :warning:
> Les trois exigent que `origin/main` soit réellement *dans* le clone. Une extraction superficielle
> d'intégration continue ne récupère en général que votre branche, si bien que la commande meurt
> sur `fatal: ambiguous argument 'origin/main': unknown revision or path not in the working tree.`
> — un message qui envoie les gens à la chasse à la faute de frappe alors que le vrai problème est
> la profondeur du clone. C'est la manière la plus courante dont le piège du clone superficiel
> mord.

## Les filtres de chemins et l'intégration continue en monorepo

Une fois que vous savez calculer l'ensemble modifié, vous pouvez sauter du travail : ne pas lancer
la construction iOS quand seule la documentation a changé. Tous les systèmes d'intégration
continue offrent cela de manière déclarative (`on: push: paths:` chez GitHub Actions,
`rules: changes:` chez GitLab), et pour des dépôts simples cela suffit.

Il y a un danger d'exactitude, et il est vicieux. Les filtres de chemins expriment *« ces fichiers
ont changé »*, alors que ce dont vous avez réellement besoin est *« ces choses pourraient être
affectées »*. Modifiez une bibliothèque partagée qu'importent quarante services, et un filtre naïf
lance les tests de la bibliothèque et rien d'autre. Tout est vert. Tout est cassé.

Deux issues honnêtes :

* Maintenir la cartographie des dépendances à la main : « si `libs/auth/**` a changé, lancer aussi
  les services qui en dépendent ». Simple, ça marche, et ça pourrit silencieusement à mesure que
  le graphe des dépendances change.
* Laisser un outil de construction le dériver. Bazel, Turborepo, Nx et Pants construisent un graphe
  de cibles, hachent les entrées de chaque cible *y compris les hachages de ses dépendances*, et
  reconstruisent ou retestent exactement les cibles dont le hachage a changé. Ce n'est pas une
  heuristique, c'est une réponse juste.

Et remarquez ce qu'est ce hachage : de l'adressage par contenu, appliqué à des artefacts de
construction plutôt qu'à des **blobs**. L'idée est celle de Git, et nous la regardons de plus près
dans [Ce que Git a inspiré](../4-beyond-the-basics/6-inspired-by-git.md "Ce que Git a inspiré").

## Le cache

L'autre grand gain de vitesse. Restaurer `node_modules`, `~/.cargo`, `~/.m2`, `.venv` depuis
l'exécution précédente au lieu de retélécharger Internet.

Indexez le cache sur un hachage du **fichier de verrouillage**, jamais sur le nom de la branche.
`package-lock.json`, `poetry.lock`, `Cargo.lock`, `go.sum` — c'est précisément à cela que servent
les fichiers de verrouillage : ce sont un hachage du contenu de votre ensemble de dépendances,
donc si le fichier de verrouillage n'a pas changé le cache est valide, et s'il a changé le cache
doit manquer. Un cache indexé sur un nom de branche vous servira joyeusement les mauvaises
dépendances pendant des semaines.

Et ne mettez rien en cache que vous ne seriez pas à l'aise de trouver dans la construction d'un
collègue. Un cache est un état mutable partagé entre des exécutions de code non fiable ; traitez-le
comme tel.

## Faire tourner les tests

La construction elle-même, puis les tests, à peu près dans l'ordre de la vitesse à laquelle ils
échouent.

* **Construction / compilation.** Si cela ne compile pas, rien d'autre n'a d'importance. Échouez
  ici d'abord.
* **Tests unitaires.** Rapides, hermétiques, sans réseau. Ils devraient tourner en quelques
  secondes et devraient aussi tourner sur le portable du développeur avant le push.
* **Tests d'intégration.** Vraie base de données, vraie file, vrai HTTP. Plus lents, plus
  instables, et les seuls tests qui attrapent les erreurs qui comptent. Faites-les tourner, mais
  après les tests unitaires.
* **Tests de bout en bout.** Précieux et coûteux. Gardez l'ensemble petit et délibéré.

Deux opinions, présentées comme telles.

Ordonnez les travaux de sorte que le contrôle le moins coûteux susceptible d'échouer passe en
premier : un échec de lint en trente secondes est bien plus aimable qu'une suite de tests de
quarante minutes qui échoue sur un point-virgule manquant.

Et traitez un test instable comme un test cassé. Une suite qui échoue une fois sur cinq apprend à
tout le monde à cliquer sur « relancer », ce qui revient à ne pas avoir de suite du tout — et cela
détruit `git bisect`, sur lequel nous nous apprêtons à compter.

## L'analyse statique

Tout ce qui suit est un contrôle qui lit votre code sans l'exécuter. Regroupés, avec une
recommandation attachée.

**Les linters et les formateurs.** Faites-les tourner, et — opinion tranchée — rendez le formatage
*automatique et non négociable*. Adoptez `gofmt`, `black`, `ruff format`, `prettier`, `rustfmt`,
celui qui est idiomatique, acceptez ses valeurs par défaut, et ne discutez plus jamais
d'espacement dans une revue de code. Un humain qui relit de l'indentation est un humain qui ne
relit pas votre logique. Le cadre [pre-commit](https://pre-commit.com/) est la manière standard de
les lancer avant même que le commit ne soit fait ; voir
[Faire sienne la ligne de commande](../3-tooling-ecosystem/1-git-tools.md "Faire sienne la ligne de commande")
pour la mécanique des hooks.

**Les vérificateurs de types.** `mypy`, `pyright`, `tsc --noEmit`. Si votre langage a un
vérificateur de types optionnel, le faire tourner en intégration continue est la chasse aux bogues
la moins chère que vous achèterez jamais.

**L'analyse statique et le SAST.** `golangci-lint`, `clippy`, Semgrep, CodeQL. Ceux-ci cherchent
des motifs de bogues et des anti-patrons de sécurité plutôt que du style. Commencez par le jeu de
règles par défaut ; un outil de sécurité qui crie au loup finit ignoré, et un outil ignoré est pire
que pas d'outil du tout.

**L'analyse des dépendances et des vulnérabilités.** `pip-audit`, `cargo audit`, `npm audit`,
`osv-scanner`, plus Dependabot ou Renovate pour ouvrir les pull requests de mise à niveau à votre
place. Renovate est le plus configurable des deux ; Dependabot est déjà activé là où vous êtes.

**La recherche de secrets.** [gitleaks](https://github.com/gitleaks/gitleaks) ou l'analyseur
intégré de votre forge. Celui-ci est véritablement important, à cause de l'avertissement du
chapitre [GitOps](1-git-ops.md "GitOps") : un secret qui atteint le serveur doit être changé, pas
supprimé. Analyser dans un hook `pre-commit` l'arrête avant qu'il n'existe ; analyser en
intégration continue attrape ce qui a contourné le hook. Faites les deux.

**Les contrôles de licences.** Si vous vendez du logiciel, quelqu'un finira par demander quelles
licences se trouvent dans votre arbre de dépendances. Une machine peut répondre à cela ;
faites-la répondre.

**Les contrôles au niveau des commits.** Les plus spécifiquement teintés de Git, et ils sont peu
coûteux : les conventions de message de commit (`commitlint`), la signature DCO (`git commit -s`),
« pas de commits de fusion sur cette branche », « pas de fichier de plus d'un mégaoctet » — avant
qu'il ne devienne une partie permanente de l'historique — et « pas de commits `fixup!` restés dans
la série ».

> :information_source:
> Remarquez combien d'entre eux ont leur place *aux deux endroits* : un hook `pre-commit` pour le
> retour rapide, et l'intégration continue pour la garantie. Les hooks sont indicatifs — ils vivent
> dans `.git/hooks`, ils ne sont pas clonés, et n'importe quel collègue peut passer outre avec
> `--no-verify`. L'intégration continue est l'endroit où la règle est réellement imposée. Les hooks
> sont une politesse ; l'intégration continue est un contrat.

## `git bisect run`, ou pourquoi une ligne principale verte se rembourse

Un matin, un test échoue et personne ne sait lequel des quarante commits de la semaine dernière en
est la cause. Git peut le trouver pour vous, automatiquement, en six étapes environ :

```console
git bisect start HEAD HEAD~40      # HEAD est mauvais, HEAD~40 était bon
git bisect run ./test.sh
```

Git extrait le point médian, exécute votre script, lit son code de sortie — zéro c'est bon, non
nul c'est mauvais — et réduit encore la plage de moitié, jusqu'à :

```console
running './test.sh'
8228d7412652f77476b8c08ea3a3833035955d86 is the first bad commit
commit 8228d7412652f77476b8c08ea3a3833035955d86
Author: Ori Pekelman <ori@pekelman.com>

    commit 4

 app.py | 2 ++
 1 file changed, 2 insertions(+)
bisect found first bad commit
```

Puis `git bisect reset` pour rentrer à la maison. (Vos hachages seront différents, évidemment.)

Le script peut être n'importe quoi qui sort avec un code nul ou non nul :
`pytest -x tests/test_login.py`, `make check`, un `grep` de deux lignes. Le code de sortie 125 veut
dire « impossible de tester ce commit, saute-le ».

Maintenant l'argument. La bissection fonctionne en *supposant que chaque commit passe ou échoue
pour une raison*. Si votre ligne principale est un marécage de commits cassés, la bissection
atterrit sur un commit qui ne compile pas, vous êtes forcé de le `skip`, et la recherche dégénère
en devinette. Une ligne principale verte est ce qui rend la bissection automatisée possible —
autrement dit, garder l'intégration continue au vert n'est pas du remplissage de cases, c'est vous
acheter un super-pouvoir de débogage pour plus tard.

## Les contrôles obligatoires, la protection de branche, et la course qu'ils ne corrigent pas

Toutes les forges vous laissent marquer des contrôles comme *obligatoires* : on ne peut fusionner
dans `main` que si les contrôles passent. Activez cela. Combiné à « exiger une relecture » et
« exiger que la branche soit à jour », c'est 90 % de ce que les gens appellent du processus.

Mais retenez ce que nous avons appris plus haut. Deux pull requests, chacune verte contre `main`,
chacune relue individuellement. A renomme une fonction ; B ajoute un appelant de l'ancien nom.
Toutes deux fusionnent. `main` est cassée, et aucun test n'a jamais tourné contre la combinaison.
« Exiger que les branches soient à jour avant la fusion » corrige cela en forçant un rebase et une
réexécution sur la seconde — au prix de sérialiser votre équipe, puisque chaque fusion invalide
toutes les autres pull requests ouvertes.

La file de fusion en est la version adulte : elle regroupe, construit `main` + les changements en
file, teste le lot, et le fait atterrir. Même garantie, sans le tapis roulant du rebase manuel.

## Les éditeurs, brièvement et équitablement

* **GitHub Actions.** Omniprésent, du YAML, une énorme place de marché d'actions réutilisables, un
  niveau gratuit généreux pour les dépôts publics. Le débogage est médiocre et la syntaxe des
  expressions est un langage que personne n'a choisi.
* **GitLab CI.** Un seul `.gitlab-ci.yml`, un modèle cohérent d'étapes et d'artefacts, une
  excellente histoire d'auto-hébergement. Le YAML devient baroque à l'échelle.
* **Forgejo Actions.** Des workflows compatibles Actions sur une forge petite, auto-hébergeable et
  véritablement libre. Bon si vous voulez quitter les grandes plateformes sans tout réécrire.
* **CircleCI.** Rapide, mature, de bonnes primitives de cache et de parallélisme.
* **Buildkite.** Vous hébergez les runners, ils hébergent la coordination. Le favori des équipes
  aux constructions grandes et bizarres.
* **Jenkins.** Encore partout, et honnêtement : les gens partent parce que le pipeline vit dans
  l'état mutable d'un serveur et dans une centaine de greffons plutôt que dans le dépôt, ce qui le
  rend difficile à reproduire et difficile à relire. Si votre configuration Jenkins est dans Git
  sous forme de `Jenkinsfile`, l'essentiel de cette objection disparaît.
* **Woodpecker** et **Drone.** Petits, pensés pour les conteneurs, agréables, auto-hébergés.

> :warning:
> Épinglez les actions tierces à un **SHA de commit**, pas à une étiquette :
> `uses: some-org/some-action@a1b2c3d4…`, pas `@v3`. Une étiquette est une **référence** — un
> pointeur mobile vers un commit — et la personne qui la possède peut la déplacer quand elle veut,
> y compris vers du code qui exfiltre vos secrets. Ce n'est pas de la paranoïa ; c'est ainsi qu'ont
> fonctionné plusieurs vraies attaques sur la chaîne d'approvisionnement. Un SHA est adressé par
> son contenu et ne peut pas être repointé. La documentation de GitHub elle-même épingle ainsi les
> actions dans ses exemples OIDC. Tout ce que nous avons appris en partie 1 sur branches contre
> hachages se révèle être une propriété de sécurité.

Et une option de plus, qui est le conseil que je donne réellement : mettez vos contrôles dans un
`Makefile` ou un fichier [`just`](https://github.com/casey/just) — `make lint`, `make test` — et
laissez l'intégration continue se contenter de les *invoquer*. Si l'intégration continue ne peut
être exécutée que par l'intégration continue, vous avez un problème de débogage : chaque
expérience coûte un push et cinq minutes d'attente. Si `make test` est la même chose en local et à
distance, vous pouvez corriger sur votre portable.

## Un workflow complet que vous pouvez coller

GitHub Actions, parce que c'est ce que la plupart des lecteurs ont. Une extraction avec assez de
profondeur, une chaîne d'outils, un cache, du lint, des tests, et un travail qui ne tourne que
lorsqu'un répertoire particulier a changé.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
  merge_group:          # nécessaire pour que la file de fusion voie ces contrôles

permissions:
  contents: read        # moindre privilège ; n'en ajoutez que là où un travail en a besoin

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # Versions majeures courantes à la mi-2026. Pour les actions tierces, épinglez un
      # SHA de commit plutôt qu'une étiquette ; pour actions/* une étiquette majeure est
      # un compromis raisonnable.
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0            # on veut l'historique : describe, blame, merge-base

      - uses: actions/setup-node@v7
        with:
          node-version: '22'
          cache: npm                # indexé sur package-lock.json pour nous

      - run: npm ci
      - run: make lint              # la même cible que sur nos portables
      - run: make test

  changed:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    outputs:
      docs: ${{ steps.filter.outputs.docs }}
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0

      - id: filter
        env:
          BASE: ${{ github.event.pull_request.base.ref }}
        run: |
          git fetch --quiet origin "$BASE"
          files=$(git diff --name-only --merge-base "origin/$BASE" HEAD)
          echo "changed files:"; echo "$files"
          if echo "$files" | grep -q '^docs/'; then
            echo "docs=true" >> "$GITHUB_OUTPUT"
          else
            echo "docs=false" >> "$GITHUB_OUTPUT"
          fi

  docs:
    needs: changed
    if: needs.changed.outputs.docs == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: make docs
```

> :information_source:
> Le travail `changed` ne tourne que sur les pull requests, parce que lors d'un `push` la base de
> fusion de `origin/main` et de `HEAD` *est* `HEAD` et que le diff revient vide. Pour un push, la
> plage équivalente est `${{ github.event.before }}..${{ github.sha }}` — les deux SHA du webhook
> par lequel nous avons commencé ce chapitre.

Les mêmes formes chez GitLab, pour que vous voyiez que rien ici n'est propre à GitHub :

```yaml
# .gitlab-ci.yml
stages: [test]

default:
  image: node:22

variables:
  GIT_DEPTH: "0"          # historique complet, même raison que fetch-depth: 0

cache:
  key:
    files:
      - package-lock.json # cache indexé sur le contenu du fichier de verrouillage
  paths:
    - node_modules/

lint:
  stage: test
  script:
    - npm ci
    - make lint

test:
  stage: test
  script:
    - npm ci
    - make test

docs:
  stage: test
  rules:
    - changes:
        - docs/**/*      # GitLab calcule l'ensemble modifié pour nous
  script:
    - make docs
```

Deux fichiers, deux dialectes, une seule idée : récupérer le bon commit, restaurer un cache indexé
sur un fichier de verrouillage, lancer les mêmes cibles que chez soi.

## Récapitulatif `git ls-remote` `git diff --merge-base` `git bisect run`

* L'intégration continue existe pour garder la ligne principale connue comme bonne et pour donner
  un retour tant que le changement est encore frais. C'est le développement sur tronc commun vu du
  côté de l'outillage.
* Un déclencheur d'intégration continue est un webhook qui transporte `<before>`, `<after>` et une
  référence — le même triplet que lit un hook `post-receive` — plus un clone.
* Les clones superficiels (`fetch-depth: 1`, `GIT_DEPTH`) cassent `git describe`, `blame`,
  `bisect`, la génération de journaux de changements et le calcul de la base de fusion. Utilisez
  `fetch-depth: 0` là où l'historique compte.
* Sur une pull request, l'intégration continue teste en général un **commit de fusion qui n'existe
  dans aucun dépôt** : `refs/pull/<n>/merge` chez GitHub, `refs/merge-requests/<n>/merge` chez
  GitLab. `…/head` est la pointe de la branche. `git ls-remote` vous montre les deux.
* C'est pourquoi « ça a passé l'intégration continue puis ça a cassé `main` » arrive, et pourquoi
  les files de fusion (le `merge_group` de GitHub) et les merge trains (GitLab) existent.
* `git fetch origin pull/<n>/head:pr-<n>` extrait n'importe quelle pull request en local.
* Calculez les fichiers modifiés avec `git diff --name-only --merge-base origin/main HEAD`, jamais
  avec `HEAD~1`.
* Les filtres de chemins évitent du travail mais peuvent manquer les dépendants ; les graphes de
  construction à hachage de contenu (Bazel, Nx, Turborepo) sont la réponse rigoureuse.
* Indexez les caches sur les hachages des fichiers de verrouillage.
* Faites tourner la construction, les tests unitaires, les tests d'intégration, les formateurs, les
  linters, les vérificateurs de types, le SAST, l'analyse des dépendances et des secrets, les
  contrôles de licences et ceux au niveau des commits — beaucoup d'entre eux dans un hook
  `pre-commit` *et* en intégration continue.
* `git bisect run ./test.sh` trouve le commit fautif automatiquement — et ne marche bien que si la
  ligne principale est majoritairement verte.
* Épinglez les actions tierces à un **SHA** de commit, parce que les étiquettes bougent.
* Mettez les vraies commandes dans des cibles `make`/`just` pour que l'intégration continue ne soit
  pas le seul endroit où on puisse les lancer.
