---
title: Arbres de travail et agents, du travail parallèle à la vitesse de la machine
slug: "git-worktree-agents"
weight: 32
---
# Arbres de travail et agents, du travail parallèle à la vitesse de la machine

Le chapitre précédent enseignait une fonctionnalité de 2015. Celui-ci porte sur la raison pour
laquelle, dix ans plus tard, beaucoup de gens ont soudain découvert qu'ils en avaient besoin.

## Ce qui a changé

Depuis qu'il existe de la gestion de version, le rythme auquel un dépôt changeait était borné par la
vitesse de frappe des humains. Une personne, un éditeur, un répertoire de travail : l'outillage
collait à la biologie.

Les agents de codage ont brisé cette hypothèse. Quel que soit celui que vous utilisez — Claude Code,
Codex, Aider, les agents d'arrière-plan de Cursor, les Devin-likes, et ce qui sortira le mois
prochain — la propriété intéressante n'est pas qu'il écrit du code. C'est que vous pouvez en faire
tourner **plusieurs à la fois**. Et dès que vous le pouvez, le goulot d'étranglement se déplace. Ce
n'est plus la vitesse de frappe. C'est le nombre de changements indépendants que vous pouvez avoir en
vol sans qu'ils se percutent.

Et maintenant regardez votre répertoire de travail. Un jeu de fichiers. Un **index**. Un **HEAD**.

Un arbre de travail unique est un **mutex**.

Deux agents qui éditent des fichiers dans le même répertoire produisent du n'importe quoi, et ils le
produisent silencieusement. L'agent A lit un fichier, y réfléchit huit secondes, et le réécrit — par
dessus la version que l'agent B a écrite entre-temps. Personne n'émet d'erreur. `git status` montre
un diff d'apparence plausible. Les tests échouent quelque part sans rapport, une heure plus tard. Git
ne vous sauvera pas : Git voit un répertoire de travail, et un répertoire de travail n'a aucune
notion de qui a écrit quoi.

C'est un problème de concurrence, et il a la forme de tous les problèmes de concurrence : soit on
sérialise l'accès, soit on donne à chaque travailleur sa propre copie de l'état mutable.

Git a la seconde option depuis 2015.

## Le motif de base

Un arbre de travail par agent et par tâche. Chacun sur sa propre branche. Tous partageant une seule
base de données d'objets.

```console
git worktree add ../wt-rounding  -b agent/rounding  main
git worktree add ../wt-coupon    -b agent/coupon    main
git worktree add ../wt-empty     -b agent/empty     main
```

Puis lancez un agent dans chaque répertoire, avec la contrainte que son répertoire de travail *soit*
cet arbre de travail. Voilà toute l'idée. Tout le reste de ce chapitre n'en est que la conséquence.

En voici une version exécutable. Rien n'y est astucieux, et c'est bien le propos :

```console
#!/bin/sh
# fan-out.sh <fichier-de-tâche>...  un arbre de travail, une branche, un agent par tâche
set -e
root=$(git rev-parse --show-toplevel)
parent=$(dirname "$root")
base=${BASE:-main}
git -C "$root" fetch --quiet origin "$base" 2>/dev/null || true

for task in "$@"; do
  slug=$(basename "$task" .md)
  dir="$parent/wt-$slug"
  git -C "$root" worktree add --quiet -b "agent/$slug" "$dir" "$base"
  if [ -x "$dir/setup-worktree.sh" ]; then (cd "$dir" && ./setup-worktree.sh); fi
  echo "==> agent/$slug ready in $dir"
  # lancez votre agent ici, avec $dir comme répertoire de travail, par ex.
  # (cd "$dir" && your-agent --prompt-file "$root/$task") &
done
git -C "$root" worktree list
```

```console
sh fan-out.sh tasks/rounding.md tasks/coupon.md

  bootstrap: installing deps in /home/ori/fanlab/wt-rounding
==> agent/rounding ready in /home/ori/fanlab/wt-rounding
  bootstrap: installing deps in /home/ori/fanlab/wt-coupon
==> agent/coupon ready in /home/ori/fanlab/wt-coupon
/home/ori/fanlab/app          da53256 [main]
/home/ori/fanlab/wt-coupon    da53256 [agent/coupon]
/home/ori/fanlab/wt-rounding  da53256 [agent/rounding]
```

Remarquez le point d'accroche `setup-worktree.sh`. Nous avons soutenu au chapitre précédent qu'un
projet dont les arbres de travail sont peu coûteux à créer est un projet doté de bons scripts
d'amorçage. Avec des agents, cela cesse d'être un point esthétique et devient porteur, parce que vous
allez le faire vingt fois par jour. Un agent peut aussi lancer le script lui-même — c'est une très
bonne chose à mettre dans ses instructions.

> :information_source:
> Ce motif est en train de devenir standard dans les harnais eux-mêmes plutôt que quelque chose que
> vous construisez. Depuis Claude Code 2.1, par exemple, `claude -w` / `claude --worktree [nom]`
> démarre une session dans un arbre de travail neuf, et `--tmux` (qui exige `--worktree`) met chacune
> dans son propre panneau de terminal. D'autres outils ont leurs propres orthographes, et certains
> créent des arbres de travail dans votre dos sans vous le dire. Vérifiez la version que vous avez
> réellement — les options dans ce coin du monde changent tous les mois. Le *Git* en dessous, non.

## Pourquoi pas les solutions alternatives

### Plusieurs clones

Cela fonctionne. Les gens le font. Cela coûte du disque et, sur un gros dépôt, de la bande passante
et beaucoup d'attente.

Mais la véritable objection est ailleurs, et c'est l'argument de tout ce chapitre : **avec des clones
séparés, les agents ne peuvent pas voir le travail les uns des autres.**

L'agent A commite dans le clone A. L'agent B, dans le clone B, n'a aucun moyen de voir ce commit tant
que quelqu'un ne l'a pas poussé vers un dépôt distant partagé et que quelqu'un d'autre ne l'a pas
récupéré. Vous ne pouvez donc pas comparer leurs travaux. Vous ne pouvez pas fusionner l'un dans
l'autre. Vous ne pouvez pas demander « ont-ils résolu cela de la même façon ? » sans un aller-retour
par un serveur.

Avec des arbres de travail, `refs/heads/*` est partagé. À l'instant où l'agent A commite, sa branche
existe pour tout le monde :

```console
git diff agent/a agent/b
git log --oneline agent/a..agent/b
git range-diff main..agent/a main..agent/b
```

Pas de push. Pas de fetch. Pas de réseau. C'est l'argument massue et ce n'est même pas serré.

### Un conteneur ou une machine virtuelle par agent

Une isolation plus forte, et la bonne réponse quand vous ne faites pas entièrement confiance à
l'agent avec votre machine — ce qui est une position parfaitement raisonnable. C'est plus lourd : une
image, un volume, un coût de démarrage, et l'avantage du magasin d'objets partagé ci-dessus
disparaît, à moins de l'y monter.

Et notez que ce ne sont pas des choix concurrents. À l'intérieur du conteneur, vous voulez toujours un
arbre de travail, parce que vous voulez toujours chaque agent sur sa propre branche dans un seul
magasin d'objets.

> :warning:
> Un arbre de travail n'est **pas un bac à sable**. Il isole les *fichiers et les références*. Il
> n'isole pas les *processus et les appels système*. L'agent peut faire `cd ..` dans votre arbre de
> travail principal. Il peut lire `.git/config`, y compris les identifiants ou les URL qui s'y
> trouvent. Il peut lire et modifier le `hooks/` partagé. Il peut faire `git push`. Il peut faire
> `rm -rf` sur tout ce que votre compte utilisateur peut atteindre. Si votre modèle de menace inclut
> « l'agent fait quelque chose de destructeur », un arbre de travail ne vous apporte rien et il vous
> faut un conteneur, une machine virtuelle, ou une machine dont vous vous fichez.

### Un seul arbre de travail, les agents chacun leur tour

Simple, et *correct* quand les tâches touchent le même code. Si deux changements se recouvrent
réellement, les paralléliser ne les rend pas plus rapides — cela en fait un conflit de fusion que
vous résoudrez à la main. Sérialiser n'est pas un échec. C'est souvent la réponse honnête.

## Les motifs d'éclatement et de regroupement

### Des tâches parallèles indépendantes

N tickets sans rapport, N arbres de travail, N branches, on relit et on fusionne chacun. La mécanique
est triviale. La partie difficile est la question d'ordonnancement : **quelles tâches sont réellement
indépendantes ?**

Git peut vous aider à deviner, parce que votre historique enregistre déjà quels fichiers changent
ensemble. Si deux zones du code ne sont jamais apparues dans le même **commit**, on peut probablement
y travailler simultanément sans risque. Si elles apparaissent toujours ensemble, non :

```console
git log --pretty=format:'--' --name-only -- src | head -40
```

Chaque `--` commence un commit ; les noms de fichiers en dessous ont changé ensemble. Passez cela à
un `sort | uniq -c` sur des paires et vous avez une carte de couplage grossière. Grossière suffit —
vous faites une supposition d'ordonnancement, vous ne démontrez pas un théorème.

### La génération concurrente

La même tâche, N agents, N arbres de travail. Puis on compare et on choisit.

L'outil évident est `git diff`, et pour le *résultat* c'est le bon :

```console
git diff --stat try-a try-b

 src/cart.py | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)
```

Mais cela compare deux états finaux. Ce que vous voulez généralement comparer, ce sont deux
*approches* — deux séries entières de commits bâties sur la même base. Il existe une commande
exactement pour cela, `git range-diff`. Elle existe depuis Git 2.19 et presque personne ne la
connaît.

`git range-diff` prend deux plages de commits et produit un **diff de diffs**. Elle apparie les
commits des deux séries qui semblent essayer de faire la même chose, puis montre en quoi ils
diffèrent. Deux tentatives d'agents sur une tâche sont précisément le cas pour lequel elle a été
conçue (elle a été écrite pour comparer les versions d'une série de patchs sur une liste de
diffusion, ce qui est la même forme).

Deux agents qui l'ont résolu différemment :

```console
git range-diff main..try-a main..try-b

1:  afa5504 < -:  ------- Format prices with integer arithmetic
-:  ------- > 1:  31c644d Use Decimal to format prices
2:  f4be4ee = 2:  db33408 Add a test for format_price
```

Lisez la colonne du milieu. Le `<` veut dire « seulement dans la série de gauche ». Le `>` veut dire
« seulement dans la série de droite ». Le `=` veut dire « ces deux commits sont identiques en
contenu ». Donc : ils ont pris des approches complètement différentes pour le correctif, puis ont
écrit *le même test, octet pour octet*. Ce qui est une chose véritablement intéressante à apprendre
en une ligne de sortie.

Maintenant deux agents qui ont pris la même approche, l'un plus soigneusement :

```console
git range-diff main..try-a main..try-c

1:  afa5504 = 1:  e757365 Format prices with integer arithmetic
2:  f4be4ee ! 2:  21945c0 Add a test for format_price
    @@ Metadata
     Author: Ori Pekelman <ori@pekelman.com>

      ## Commit message ##
    -    Add a test for format_price
    +    Add tests for format_price

      ## tests/test_cart.py ##
     @@
    @@ tests/test_cart.py
     +def test_format_price():
     +    from src.cart import format_price
     +    assert format_price(1999) == "19.99"
    ++    assert format_price(5) == "0.05"
```

Un `=` sur le premier commit : correctif identique. Un `!` sur le second : même intention, contenu
différent — puis le diff imbriqué, où le `++` doublé marque une ligne présente uniquement dans
`try-c`. Il a ajouté un test pour le cas des cinq centimes. Voilà votre gagnant, et vous l'avez
découvert en une commande.

`--no-patch` vous donne juste le tableau récapitulatif quand vous ne voulez que la forme :

```console
git range-diff --no-patch main..try-a main..try-c

1:  afa5504 = 1:  e757365 Format prices with integer arithmetic
2:  f4be4ee ! 2:  21945c0 Add a test for format_price
```

Puis choisissez un gagnant et supprimez les perdants, ou faites un cherry-pick des meilleurs commits
de chacun. Un `git cherry-pick` entre branches d'arbres de travail ne coûte rien, parce qu'elles sont
toutes dans un seul magasin d'objets.

### Le pipeline

L'arbre de travail A implémente. L'arbre B relit la branche de A. L'arbre C écrit des tests contre
elle. Parce que les références sont partagées, B et C voient les commits de A **à l'instant où ils
existent** — pas de push, pas de pull, pas de coordination :

```console
cd ../wt-review
git log --oneline main..agent/implement
git diff main...agent/implement
```

C'est le motif qui est véritablement impossible avec des clones séparés, et il vaut la peine de
structurer le travail autour.

### La vérification de longue durée

Un agent qui itère dans un arbre de travail pendant que la suite complète tourne contre un commit
épinglé dans un autre :

```console
git worktree add --detach ../verify agent/implement
cd ../verify && ./run-tests.sh
```

Le `--detach` compte ici : il épingle un **commit** précis, de sorte que le prochain commit de
l'agent ne déplace pas le sol sous une suite de tests en cours. Ce n'est pas un détail, c'est la
raison d'être des arbres de travail détachés.

### Le problème du regroupement

Voilà où l'optimisme va mourir. N branches toutes fondées sur le même `main` entreront en conflit
entre elles proportionnellement à leur recouvrement, et vous ne le découvrez qu'au moment de la
fusion.

Ce qui aide, à peu près par ordre d'efficacité :

* **Fusionnez par taille croissante.** Les changements petits et manifestement corrects d'abord.
  Chaque fusion que vous faites atterrir rend le rebase suivant plus bruyant, alors payez ce coût
  sur les branches qui peuvent l'absorber.
* **`git rerere`.** Activez-le (`git config rerere.enabled true`) et Git enregistre la manière dont
  vous avez résolu un conflit, puis rejoue cette résolution la fois suivante où le même conflit se
  présente. Avec une branche c'est un agrément. Avec cinq branches que vous allez rebaser encore et
  encore sur un `main` mouvant, c'est la différence entre agaçant et insupportable. Nous l'avons vu
  fonctionner en vraie sortie : à la deuxième tentative de la même fusion, Git a affiché
  `Resolved 'src/format.py' using previous resolution.` et a laissé le fichier correct.
* **Rebasez chaque branche sur la précédente** plutôt que toutes sur `main`, quand les changements
  sont liés. Vous résolvez chaque conflit une fois, dans un petit contexte, au lieu d'en résoudre un
  tas à la fin.
* **L'hygiène du push forcé.** Les agents rebasent et amendent, donc ils poussent en force.
  `--force-with-lease` plutôt que `--force`, toujours. Mais lisez l'avertissement ci-dessous, parce
  que dans cette configuration précise le bail est plus faible que vous ne le croyez.

> :warning:
> Un piège vérifié et non évident. `--force-with-lease` vous protège en comparant le dépôt distant à
> votre **référence de suivi** locale. Les références de suivi sont *partagées entre les arbres de
> travail*. Ainsi, quand l'agent B pousse sur une branche, `refs/remotes/origin/<branche>` est mis à
> jour pour **tout le monde** — y compris pour l'agent A, qui n'a jamais vu le commit de B. Le bail
> de A semble alors parfaitement à jour, et son push forcé détruit le travail de B :
>
> ```console
> # arbre de travail A, qui n'a jamais récupéré le commit de B :
> git push --force-with-lease origin topic
> To ../o.git
>  + f0a048b...d218b5a topic -> topic (forced update)
> ```
>
> Le même scénario entre deux *clones* séparés est refusé, parce que là les références de suivi sont
> indépendantes :
>
> ```console
> git push --force-with-lease origin topic
> To /home/ori/lease2/o.git
>  ! [rejected]        topic -> topic (stale info)
> ```
>
> La leçon : donnez à chaque agent son **propre espace de noms de branches** (`agent/<slug>/...`) et
> ne laissez jamais deux d'entre eux pousser sur une même branche.
> `--force-with-lease --force-if-includes` aide un peu, mais ne pas partager de branche aide
> complètement.

## La réalité opérationnelle

C'est la partie que les gens apprennent à la dure. Rien de tout cela ne concerne Git.

**Le coût d'amorçage.** Chaque arbre de travail a besoin de dépendances. Les caches partagés sont le
remède : `CARGO_TARGET_DIR`, `UV_CACHE_DIR`, le magasin pnpm, `ccache`. Faites un lien symbolique
vers `.env`. Utilisez `direnv` pour qu'un `.envrc` par arbre de travail exporte les bonnes valeurs
quand quoi que ce soit y entre. Puis mettez tout cela dans `setup-worktree.sh`, commitez-le, et
laissez l'agent le lancer.

**Les collisions de ports.** Si chaque agent démarre un serveur de développement, ils veulent tous le
`:3000`. Attribuez-les de manière déterministe à partir du nom de l'arbre de travail, pour que ce
soit stable d'un redémarrage à l'autre :

```console
for n in feature-x hotfix wt-coupon; do
  printf '%-12s %s\n' "$n" $(( 3000 + $(printf '%s' "$n" | cksum | cut -d' ' -f1) % 100 ))
done

feature-x    3067
hotfix       3032
wt-coupon    3001
```

Dans l'arbre de travail lui-même, cela donne
`port=$(( 3000 + $(printf '%s' "$(basename "$PWD")" | cksum | cut -d' ' -f1) % 100 ))`, et `direnv`
est l'endroit naturel où le mettre. Ce n'est pas à l'épreuve des collisions — hachez dans une plage
plus large, ou tenez un fichier d'index, si vous en faites tourner beaucoup.

**L'état global mutable, qui est la vraie limite.** Les bases de données de test, les espaces de clés
Redis, les files de messages, les buckets S3, les répertoires de fixtures, les chemins dans `/tmp`.
C'est cela, et non Git, qui vous empêche réellement de faire tourner cinq suites de tests à la fois.
Les remèdes, par ordre de préférence : un nom de base de données ou un schéma par arbre de travail ;
un `COMPOSE_PROJECT_NAME` par arbre de travail pour que Docker Compose ne partage pas les conteneurs ;
ou l'accepter et sérialiser les exécutions de tests tout en parallélisant l'édition. Si votre suite de
tests ne peut pas tourner deux fois simultanément sur une machine, aucune quantité de Git ne rendra
les agents parallèles.

**Le disque.** N × arbre de travail, comme établi. Très bien pour des sources. Pénible dès que votre
dépôt contient de gros binaires — voir [Git LFS](4-git-lfs.md "Git LFS") pour la forme de ce
problème.

**Le processeur et la mémoire vive.** N agents, plus N serveurs de langage, plus N exécutions de
tests. Comme règle empirique, comptez un arbre de travail pour deux cœurs, et vérifiez votre marge
mémoire avant d'y croire — un serveur de langage sur un gros projet peut peser un gigaoctet ou plus,
et le nombre qui marche réellement sur votre machine est quelque chose qui se mesure, pas quelque
chose qui se lit dans un cours. Quand votre portable se met à faire du swap, tout devient plus lent
que si vous aviez fait les tâches une par une, et vous ne le remarquerez pas pendant vingt minutes.

**La discipline de nettoyage.** Les agents créent des branches et des arbres de travail et les
abandonnent sans le moindre remords. Faites tourner quelque chose comme ceci à intervalles réguliers :

```console
#!/bin/sh
# Retirer tout arbre de travail agent/* dont la branche est déjà fusionnée dans $BASE.
set -e
base=${BASE:-main}
root=$(git rev-parse --show-toplevel)
git -C "$root" worktree list --porcelain |
  awk '/^worktree /{w=$2} /^branch /{print $2"\t"w}' |
  while IFS="	" read -r ref dir; do
    branch=${ref#refs/heads/}
    case "$branch" in agent/*) ;; *) continue ;; esac
    if git -C "$root" merge-base --is-ancestor "$ref" "$base"; then
      echo "merged  -> removing $branch"
      git -C "$root" worktree remove "$dir"
      git -C "$root" branch -d "$branch"
    else
      echo "ahead   -> keeping  $branch"
    fi
  done
git -C "$root" worktree prune -v
```

```console
sh fan-in-cleanup.sh

ahead   -> keeping  agent/coupon
merged  -> removing agent/rounding
Deleted branch agent/rounding (was 750878a).
```

Notez l'ordre — l'arbre de travail d'abord, puis la branche — parce que, comme nous l'avons vu, une
branche qu'un arbre de travail détient ne peut pas être supprimée.

> :warning:
> Les arbres de travail abandonnés maintiennent les déchets en vie. Les commits d'un agent sont
> atteignables depuis le `HEAD` et le `logs/HEAD` de cet arbre de travail, donc `git gc` ne peut pas
> les collecter, même avec `--prune=now`. J'ai fait un commit jetable dans un arbre de travail
> détaché, lancé `git gc --prune=now`, et `git cat-file -t <sha>` répondait toujours `commit`. Après
> un `git worktree remove` plus un `git reflog expire --expire-unreachable=now --all`, le même
> `git cat-file` a enfin dit `could not get object info`. Un dépôt qui accumule des arbres de travail
> d'agents abandonnés ne rétrécit tout simplement jamais.

**L'observabilité.** Avec cinq agents en marche, « que se passe-t-il ? » est une vraie question.
Trois commandes y répondent pour l'essentiel.

`git worktree list` est votre tableau de bord — qui est où, sur quoi :

```console
git worktree list

/home/ori/fleet/app            8bc9a36 [main]
/home/ori/fleet/wt-coupon      aa3b806 [bug/coupon]
/home/ori/fleet/wt-empty-cart  daacd41 [bug/empty-cart]
/home/ori/fleet/wt-rounding    95e2fdc [bug/rounding]
```

`git for-each-ref` vous dit qui a réellement produit quelque chose. `%(ahead-behind:main)` affiche
deux nombres, les commits d'avance et les commits de retard :

```console
git for-each-ref --sort=-committerdate refs/heads/ \
  --format='%(refname:short)|%(ahead-behind:main)|%(contents:subject)'

bug/empty-cart|1 0|Refuse to check out an empty cart
bug/coupon|1 0|Clamp coupons so a total can never go negative
bug/rounding|1 0|Round prices with integer arithmetic
main|0 0|Initial app
```

Trois branches, chacune avec un commit d'avance sur `main`, aucune en retard. Et
`git log --all --oneline --graph` montre la forme de toute la flotte d'un coup :

```console
* daacd41 Refuse to check out an empty cart
| * aa3b806 Clamp coupons so a total can never go negative
|/
| * 95e2fdc Round prices with integer arithmetic
|/
* 8bc9a36 Initial app
```

Trois dents sur une seule base. Cette image est à quoi ressemble un éclatement en bonne santé, et un
coup d'œil vous dit quand il cesse d'en être un.

**L'hygiène des commits.** Les agents commitent mal dans les deux sens : un commit énorme pour un
changement qui avait quatre parties séparables, ou onze commits appelés `fix`, `fix again`, `wip`.
Les deux se corrigent avec `git rebase -i` *avant* qu'un humain ne voie la branche, et le faire vaut
les deux minutes — vous vous apprêtez à demander à quelqu'un de relire cela.

Plus important encore : demandez à l'agent d'écrire le message de commit en expliquant **pourquoi**.
Le diff dit déjà quoi. Un agent a le contexte — quel test échouait, quel rapport, ce qu'il a essayé
en premier — au moment où il commite, et ce contexte a disparu pour toujours dix minutes plus tard.
C'est le même argument que tout ce cours tient sur les messages de commit, sauf que maintenant vous
pouvez le mettre dans une invite et l'obtenir gratuitement.

**Les hooks se déclenchent partout.** Les hooks sont partagés, et chaque arbre de travail les
exécute. Un hook `pre-commit` de trois secondes qui lance votre linter complet est une nuisance pour
vous et un impôt multiplié par N agents qui commitent chacun toutes les quelques minutes. Rendez le
hook rapide, ou faites-lui ne vérifier que les fichiers indexés.

## Les garde-fous

Une courte liste de choses que vous devriez simplement refuser à une flotte d'agents. Pas par
paranoïa — chacune est quelque chose que j'ai vu mal tourner.

**Pas de push forcé sur une branche partagée.** Vu plus haut : le bail ne vous protège pas ici. Un
espace de noms de branches par agent.

**Pas de `git clean -xfd`.** Les agents s'en saisissent parce que c'est la manière académique
d'obtenir un arbre immaculé. Dans un arbre de travail, cela supprime exactement les fichiers non
suivis qui font fonctionner l'arbre de travail :

```console
git clean -xfdn
Would remove .env

git clean -xfd
Removing .env
```

Le lien symbolique meurt et l'original survit, donc cette fois-là vous vous en tirez. Si vous aviez
*copié* le `.env` au lieu de le lier, il est perdu. Préférez `git stash --include-untracked` ou
`git restore`, ou rendez la garde explicite dans les instructions de l'agent.

**Pas d'amend ni de rebase sur quoi que ce soit de déjà poussé.** La règle de
[Jouer avec nos révisions](../1-understanding-git/7-play-with-git-revisions.md "Jouer avec nos révisions")
n'est pas suspendue parce que c'est une machine qui tape. Si un humain ou un travail d'intégration
continue a vu le commit, c'est de l'histoire désormais.

**Pas de push sur `main`.** Les branches protégées de votre forge sont la vraie application ; une
règle dans une invite est une suggestion. Utilisez les deux.

Deux mesures structurelles valent plus que ces quatre règles réunies.

*La configuration par arbre de travail.* Avec `extensions.worktreeConfig` activé, donnez à chaque
arbre de travail d'agent sa propre identité :

```console
git config --worktree user.name  "agent-rounding"
git config --worktree user.email "agent-rounding@example.invalid"
```

Désormais `git log`, `git blame` et `git shortlog -n -s` vous disent quel agent a écrit quelle ligne,
pour toujours. Cela vaut beaucoup quand vous faites un audit.

*Un dépôt distant où ils peuvent pousser et qui n'est pas le vrai.* La version forte : pointez
l'`origin` des agents vers un dépôt nu sur votre propre disque, relisez là-bas, et poussez en amont
vous-même. Cela coûte un `git init --bare` et cela supprime toute une catégorie d'accidents.

## De bout en bout

Une exécution concrète. Trois bogues indépendants dans une petite application Python : les prix sont
mal arrondis, les coupons peuvent rendre un total négatif, et la validation de commande accepte un
panier vide. Trois fichiers distincts — et c'est *pourquoi* nous pouvons les paralléliser.

L'éclatement :

```console
for b in rounding coupon empty-cart; do
  git worktree add -q "../wt-$b" -b "bug/$b" main
done
git worktree list

/home/ori/fleet/app            8bc9a36 [main]
/home/ori/fleet/wt-coupon      8bc9a36 [bug/coupon]
/home/ori/fleet/wt-empty-cart  8bc9a36 [bug/empty-cart]
/home/ori/fleet/wt-rounding    8bc9a36 [bug/rounding]
```

**[Narration.]** Maintenant trois agents tournent, un par répertoire, chacun chargé de corriger son
bogue et de commiter avec un message expliquant pourquoi. Je ne vais pas vous montrer une sortie de
terminal inventée pour un outil d'IA. Ce qui suit est une vraie sortie Git de l'état qu'ils ont
laissé derrière eux.

Chaque branche a un commit :

```console
git log --oneline main..bug/rounding
95e2fdc Round prices with integer arithmetic

git diff --stat main...bug/rounding
 src/format.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Et le message s'explique de lui-même, ce qui est toute la demande :

```console
git log -1 bug/rounding

commit 95e2fdc531dab793a8f03a715f54c169031bd580
Author: Ori Pekelman <ori@pekelman.com>
Date:   Wed Jul 29 07:20:00 2026 +0200

    Round prices with integer arithmetic

    Float division rendered 5 cents as 0.05000000000000001. Money is integral,
    so divmod on cents has no representation error to begin with.
```

Avant de fusionner, vérifions que l'hypothèse d'indépendance était vraie :

```console
for b in bug/rounding bug/coupon bug/empty-cart; do
  echo "$b:"; git diff --name-only "main...$b" | sed 's/^/    /'
done

bug/rounding:
    src/format.py
bug/coupon:
    src/cart.py
bug/empty-cart:
    src/checkout.py
```

Trois branches, trois fichiers, aucun recouvrement. Ce sera indolore — et si cela n'avait *pas*
ressemblé à cela, c'était le moment de changer l'ordre de fusion plutôt que de le découvrir en plein
conflit.

Le regroupement :

```console
git merge --no-ff -m'Merge bug/rounding'   bug/rounding
git merge --no-ff -m'Merge bug/coupon'     bug/coupon
git merge --no-ff -m'Merge bug/empty-cart' bug/empty-cart

Merge made by the 'ort' strategy.
 src/format.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
Merge made by the 'ort' strategy.
 src/cart.py | 4 ++++
 1 file changed, 4 insertions(+)
Merge made by the 'ort' strategy.
 src/checkout.py | 2 ++
 1 file changed, 2 insertions(+)
```

```console
git log --oneline --graph

*   acc977c Merge bug/empty-cart
|\
| * daacd41 Refuse to check out an empty cart
* |   f1df641 Merge bug/coupon
|\ \
| * | aa3b806 Clamp coupons so a total can never go negative
| |/
* |   5c1c370 Merge bug/rounding
|\ \
| |/
|/|
| * 95e2fdc Round prices with integer arithmetic
|/
* 8bc9a36 Initial app
```

Le `--no-ff` est délibéré : les commits de fusion enregistrent qu'il s'agissait de trois efforts
parallèles, ce qui est vrai et ce que la personne qui lira cet historique dans six mois voudra
savoir.

Le nettoyage — les arbres de travail d'abord, les branches ensuite :

```console
git branch --merged main

+ bug/coupon
+ bug/empty-cart
+ bug/rounding
* main
```

Les marqueurs `+` sont Git qui vous dit que ces branches sont encore détenues par des arbres de
travail, ce qui est exactement pourquoi la ligne suivante vient avant celle d'après :

```console
for b in rounding coupon empty-cart; do git worktree remove "../wt-$b"; done
git branch --merged main --format='%(refname:short)' | grep -v '^main$' | xargs git branch -d

Deleted branch bug/coupon (was aa3b806).
Deleted branch bug/empty-cart (was daacd41).
Deleted branch bug/rounding (was 95e2fdc).
```

```console
git worktree list
/home/ori/fleet/app  acc977c [main]

git branch
* main
```

Retour à un seul bureau. Trois bogues corrigés.

## Une note de clôture honnête

L'outillage d'agents de ce chapitre a un an ou deux. Des options seront renommées, les harnais
développeront leur propre orchestration, certains des produits nommés ici n'existeront plus dans
trois ans, et le `claude -w` précis que j'ai vérifié en écrivant ceci aura peut-être bougé quand vous
le lirez. Traitez chaque détail de produit ci-dessus comme un instantané.

Le Git en dessous date de 2015 et ne s'en va nulle part. `git worktree`, le lien `gitdir:`, un seul
magasin d'objets partagé, un **HEAD** et un **index** par arbre de travail, `git range-diff`,
`rerere`. Rien de tout cela n'a été conçu pour ceci et tout s'y ajuste, parce que c'était conçu
autour de la structure réelle du problème : l'historique est partagé, les extractions ne le sont pas.

Ce qui est, enfin, la récompense de tout le temps que ce cours a passé à vous faire faire
`cat .git/HEAD`. Vous pouvez désormais évaluer n'importe quel nouveau harnais d'agents — y compris
ceux qui n'existent pas encore — avec trois questions :

1. Que fait-il à **HEAD** ?
2. Que fait-il à l'**index** ?
3. Que fait-il à mes **références**, et peut-il pousser ?

Tout ce qui répond honnêtement à ces questions mérite d'être essayé. Tout ce qui ne peut pas y
répondre fait à votre dépôt quelque chose que vous devriez découvrir avant de lui confier votre
travail.

## Récapitulatif, arbres de travail et agents

* Un arbre de travail unique est un mutex. Des agents concurrents dans un répertoire s'écrasent
  silencieusement les uns les autres, et Git ne peut pas le détecter.
* Le motif : un arbre de travail par agent et par tâche, chacun sur sa propre branche, tous
  partageant un seul magasin d'objets.
* Les arbres de travail battent les clones multiples parce que **les références sont partagées** —
  les commits de chaque agent sont instantanément visibles de tous les autres, de sorte que
  `git diff`, `git log A..B`, `git range-diff` et `git cherry-pick` fonctionnent entre agents sans
  aucun réseau.
* Un arbre de travail n'est **pas un bac à sable**. Il isole des fichiers et des références, pas des
  processus. Utilisez des conteneurs quand vous avez besoin d'une vraie frontière — avec des arbres
  de travail à l'intérieur.
* Les motifs : des tâches parallèles indépendantes ; la génération concurrente comparée avec
  `git range-diff` ; des pipelines où un arbre de travail relit la branche d'un autre à mesure
  qu'elle apparaît ; la vérification de longue durée contre un commit épinglé par `--detach`.
* `git range-diff <plage-a> <plage-b>` compare deux *séries* de commits. `=` identique, `!` même
  intention et contenu différent (avec un diff imbriqué), `<` et `>` présent d'un seul côté. C'est le
  bon outil pour comparer deux tentatives sur une même tâche.
* `git rerere` gagne son salaire dès que vous avez plusieurs branches à rebaser sur un `main`
  mouvant.
* `--force-with-lease` est plus faible entre arbres de travail qu'entre clones, parce que les
  références de suivi sont partagées. Donnez à chaque agent son propre espace de noms de branches.
* Les vraies limites ne sont pas Git : le coût d'amorçage, les collisions de ports, les bases de
  données de test partagées et le reste de l'état global mutable, le disque, et la mémoire vive.
  Corrigez-les avec `setup-worktree.sh`, des ports déterministes par arbre de travail, des noms de
  bases de données par arbre de travail et `COMPOSE_PROJECT_NAME`.
* Nettoyez à intervalles réguliers : retirez l'arbre de travail *avant* de supprimer sa branche,
  `git worktree prune`, et souvenez-vous que le `HEAD` et le reflog d'un arbre de travail abandonné
  maintiennent des objets en vie face à `git gc`.
* Observez avec `git worktree list`,
  `git for-each-ref --format='%(refname:short)|%(ahead-behind:main)|%(contents:subject)'` et
  `git log --all --oneline --graph`.
* Les garde-fous qui valent d'être imposés : pas de push forcé sur des branches partagées, pas de
  `git clean -xfd` (il retire le `.env` que vous aviez lié), pas d'amend ni de rebase sur quoi que ce
  soit de déjà poussé, pas de push sur `main`. Dans la version forte, donnez aux agents un dépôt
  distant qui n'est pas le vrai.
