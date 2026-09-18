---
title: Faire sienne la ligne de commande
slug: "git-tools"
weight: 21
---
# Faire sienne la ligne de commande

Tout ce qui précède portait sur Git lui-même : les objets, l'**index**, les références, les branches, les fusions, les rebases, les dépôts distants. Vous savez maintenant ce que Git *est*. Cette partie du cours porte sur l'autre moitié du métier — rendre Git agréable à vivre huit heures par jour.

Nous sommes ici des gens de la ligne de commande sans nous en excuser, et ce chapitre est la raison pour laquelle nous pouvons nous le permettre. Un Git d'origine, sorti de sa boîte, est un très bon outil qui se trouve être configuré pour 2007. Vingt lignes de configuration, six alias et deux ou trois programmes supplémentaires en font quelque chose que vous prenez réellement plaisir à utiliser.

Lisez ce chapitre avec votre `~/.gitconfig` ouvert. Presque tout ici est une ligne que vous collez une fois et dont vous profitez pendant des années.

## La configuration est le véritable outil de puissance : `git config`

Nous réglons de la configuration depuis [Installation et configuration de Git](../6-appendices/1-git-install.md "Installation et configuration de Git") sans jamais nous demander où vivent ces réglages. Demandons-le.

### D'où vient ce réglage ? `--show-origin`

```console
git config --list --show-origin --show-scope
```

```console
system	file:/etc/gitconfig	core.autocrlf=input
global	file:/home/you/.gitconfig	user.name=Ori Pekelman
global	file:/home/you/.gitconfig	user.email=ori+git-training@pekelman.com
global	file:/home/you/.gitconfig	init.defaultbranch=main
global	file:/home/you/.gitconfig	pull.ff=only
local	file:.git/config	user.email=ori@work.example.com
```

Trois choses à remarquer. D'abord, chaque valeur porte le fichier d'où elle vient — c'est la commande de débogage la plus utile de Git, et la réponse à « mais pourquoi diable Git fait-il ça ». Ensuite, `init.defaultBranch` revient sous la forme `init.defaultbranch` : les noms de sections et de clés sont insensibles à la casse et Git les normalise, alors ne paniquez pas quand la casse que vous avez tapée n'est pas celle qu'on vous rend. Enfin, `user.email` apparaît deux fois.

Quand une clé apparaît plus d'une fois, c'est la dernière qui gagne, et les portées sont lues dans l'ordre : **system**, puis **global**, puis **local**, puis **worktree**. Donc :

```console
git config --show-origin --show-scope --get-all user.email
```

```console
global	file:/home/you/.gitconfig	ori+git-training@pekelman.com
local	file:.git/config	ori@work.example.com
```

et `git config --get user.email` répond `ori@work.example.com`. C'est le mécanisme derrière le remède classique au « j'ai committé sur le dépôt du travail avec mon adresse personnelle » : réglez l'identité personnelle globalement, surchargez-la localement dans les dépôts où elle est fausse.

Les quatre portées, concrètement :

* **system** — `/etc/gitconfig`, un fichier pour toute la machine. `git config --system`. Vous y toucherez rarement.
* **global** — `~/.gitconfig` (ou `~/.config/git/config`). `git config --global`. C'est *votre* fichier, celui dont parle ce chapitre.
* **local** — `.git/config`, par dépôt. Un `git config` tout court écrit ici. Non versionné, non cloné — il contient vos dépôts distants et vos upstreams.
* **worktree** — `.git/worktrees/<nom>/config.worktree`, par **worktree** lié, et seulement si `extensions.worktreeConfig` est activé. Voir [Un seul dépôt, plusieurs répertoires de travail](../4-beyond-the-basics/1-git-worktree.md "Un seul dépôt, plusieurs répertoires de travail").

`git config --global --edit` ouvre votre fichier global dans votre éditeur, ce qui est honnêtement la plus agréable façon d'y travailler.

### Une configuration qui vaut la peine d'être collée

Voici le bloc que je mettrais dans `~/.gitconfig` sur une machine neuve. Collez-le, puis lisez les justifications ci-dessous — un fichier de configuration que vous ne comprenez pas est un passif.

```ini
[init]
	defaultBranch = main
[pull]
	ff = only
[push]
	default = simple
	autoSetupRemote = true
[rebase]
	autosquash = true
	autostash = true
	updateRefs = true
[merge]
	conflictStyle = zdiff3
[rerere]
	enabled = true
[diff]
	algorithm = histogram
	colorMoved = zebra
	mnemonicPrefix = true
[fetch]
	prune = true
	writeCommitGraph = true
[log]
	date = iso
[branch]
	sort = -committerdate
[tag]
	sort = version:refname
[column]
	ui = auto
[core]
	excludesFile = ~/.gitignore
	editor = nano
	pager = less -FRX
[help]
	autocorrect = prompt
[transfer]
	fsckObjects = true
```

`init.defaultBranch = main` empêche `git init` d'afficher son conseil à propos de `master` et aligne vos dépôts locaux sur ce que font GitHub, GitLab et compagnie. Rien de technique n'en dépend ; c'est juste moins de friction.

`pull.ff = only` est celui pour lequel je me battrais. Un `git pull` par défaut inventera joyeusement un commit de fusion quand votre branche et le dépôt distant ont tous deux bougé, et c'est ainsi que « Merge branch 'main' of github.com:… » finit dans une centaine d'historiques. Avec `ff = only`, Git refuse et vous dit de décider : `git pull --rebase` ou un `git merge` explicite. Si vous êtes fermement dans le camp du rebase, `pull.rebase = true` le dit à la place — l'un ou l'autre se défend, la valeur par défaut non.

`push.default = simple` pousse la branche courante vers son upstream du même nom et rien d'autre. `push.autoSetupRemote = true` met fin au rituel où votre premier push sur une nouvelle branche échoue et vous tend un `git push --set-upstream origin ma-branche` à copier-coller. Avec cette option, `git push` crée simplement la branche distante. Cette machinerie de refspec est expliquée dans [Récupérer et envoyer du code](../2-collaborating/3-git-clone-pull-remote.md "Récupérer et envoyer du code") ; ce réglage fait que vous cessez d'avoir à y penser.

`rebase.autosquash = true` fait que `git rebase -i` fond automatiquement dans leurs cibles les commits dont les messages commencent par `fixup!` ou `squash!`, ce qui est ce qui rend `git commit --fixup=<sha>` digne d'être utilisé. `rebase.autostash = true` met votre **worktree** sale de côté et le restaure autour d'un rebase au lieu de refuser de démarrer. `rebase.updateRefs = true` est le plus récent et le plus discrètement brillant : si vous avez une pile de branches (`feature-a`, puis `feature-b` par-dessus, puis `feature-c`), rebaser le sommet laissait autrefois les pointeurs intermédiaires échoués sur les anciens commits. Avec cette option, Git les déplace tous. Les branches empilées cessent d'être une corvée.

`merge.conflictStyle = zdiff3` change l'aspect d'un conflit dans le fichier. Nous le regarderons correctement dans un instant.

`rerere.enabled = true`, c'est « reuse recorded resolution ». Git se souvient de la manière dont vous avez résolu un conflit donné, et s'il revoit le même conflit, il rejoue votre résolution. Si vous avez déjà rebasé une longue branche en heurtant cinq fois le même conflit, vous savez pourquoi cela compte.

`diff.algorithm = histogram` produit des diffs nettement plus humains que celui par défaut dans du code qui a des lignes répétées — le cas classique étant un bloc de lignes `}` et `else` où l'algorithme par défaut aligne les mauvaises. `diff.colorMoved = zebra` colore les lignes déplacées différemment des lignes ajoutées et supprimées, si bien qu'une refactorisation qui remue des fonctions se lit comme « ceci a bougé » au lieu d'un mur de rouge et de vert. `diff.mnemonicPrefix = true` remplace les `a/` et `b/` des en-têtes de diff par des lettres qui veulent dire quelque chose : `i/` pour l'**index**, `w/` pour le **worktree**, `c/` pour un commit.

`fetch.prune = true` supprime les branches de suivi distant dont la branche distante a disparu, si bien que `git branch -r` reflète la réalité au lieu d'accumuler six mois de branches de fonctionnalités fusionnées. `fetch.writeCommitGraph = true` maintient un fichier commit-graph au fetch, ce qui rend spectaculairement plus rapides les commandes qui parcourent le graphe (`git log --graph`, le calcul de la base de fusion) sur les gros dépôts.

`log.date = iso` affiche les dates comme `2026-07-30 00:14:55 +0200` au lieu du `Thu Jul 30 00:14:55 2026 +0200` par défaut de Git. Triable, non ambigu, plus court.

`branch.sort = -committerdate` liste vos branches les plus récemment touchées en premier, ce qui est presque toujours l'ordre que vous voulez. `tag.sort = version:refname` trie les tags comme un humain lit des numéros de version — sortie réelle d'un dépôt qui a trois tags :

```console
git tag
```

```console
v1.9
v1.10
v2.0
```

Sans cela, vous obtenez `v1.10` avant `v1.9`, parce que `1` se trie avant `9`. `column.ui = auto` laisse `git branch` et `git tag` utiliser la largeur de votre terminal au lieu d'un élément par ligne.

`core.excludesFile` est votre liste d'exclusions personnelle, pour les choses qui vous regardent et ne regardent pas le projet — déjections d'éditeur, `.DS_Store`, vos fichiers de brouillon. Voir [Un peu de structure SVP](../2-collaborating/4-git-repo-structure.md "Un peu de structure SVP"). `core.editor` est ce qui s'ouvre pour les messages de commit et le rebase interactif. `core.pager = less -FRX` fait que le pageur se termine tout seul quand la sortie tient sur un écran (`-F`), garde la couleur (`-R`), et n'efface pas l'écran en sortant (`-X`).

`help.autocorrect = prompt` attrape les fautes de frappe et demande :

```console
WARNING: You called a Git command named 'brnach', which does not exist.
Run 'branch' instead [y/N]?
```

Réglez-le sur un nombre à la place et ce nombre est en dixièmes de seconde avant que Git ne lance la correction *sans* demander. Je préfère nettement `prompt`. Les machines qui devinent puis agissent, c'est ainsi qu'on apprend de nouveaux jurons.

`transfer.fsckObjects = true` fait que Git vérifie les objets qu'il reçoit par le réseau au lieu de leur faire confiance. Cela coûte un peu de temps au clonage et ferme une vraie classe d'attaques par dépôt malveillant.

### Le style de conflit, vu correctement

`merge.conflictStyle = zdiff3` mérite sa propre démonstration. Deux branches changent la même ligne ; l'ancêtre commun disait encore autre chose.

```console
git merge theirs
```

```console
Auto-merging meta.yaml
CONFLICT (content): Merge conflict in meta.yaml
Automatic merge failed; fix conflicts and then commit the result.
```

Le fichier se lit maintenant ainsi :

```console
title: Report
<<<<<<< HEAD
author: Grace
||||||| 02b8d1b
author: nobody
=======
author: Ada
>>>>>>> theirs
year: 2024
```

Cette section du milieu entre `|||||||` et `=======` est la **base de fusion** — ce que disait la ligne avant que l'un ou l'autre côté n'y touche — et le style `merge` par défaut ne vous la montre pas. C'est la différence entre « deux personnes ne sont pas d'accord » et « une personne l'a changée et l'autre l'a supprimée », ce qui se résout très différemment. Le déroulé de résolution de conflit est dans [Mettre en œuvre un workflow collaboratif efficace](../2-collaborating/5-git-workflow.md "Mettre en œuvre un workflow collaboratif efficace") ; ce réglage le rend plus facile.

### Rendre à nouveau rapide un gros dépôt

Si `git status` prend trois secondes, Git parcourt tout votre **worktree** et fait un `stat` sur chaque fichier. Deux réglages corrigent cela :

```ini
[core]
	fsmonitor = true
	untrackedCache = true
```

`core.fsmonitor = true` démarre le démon de surveillance du système de fichiers intégré à Git, qui observe le **worktree** et dit à Git ce qui a changé, si bien que `git status` cesse de regarder. `core.untrackedCache = true` met en cache la réponse à « quels fichiers ici sont non suivis », l'autre moitié coûteuse de la même question. Sur un gros dépôt, c'est la différence entre un `git status` inutilisable et un instantané. Il y a aussi `feature.manyFiles`, un réglage parapluie qui active un paquet de ces options.

Et pour l'entretien, la réponse moderne n'est pas une tâche cron qui lance `git gc` :

```console
git maintenance start
```

Cela enregistre le dépôt auprès de l'ordonnanceur de votre système (launchd, timers systemd, cron, le Planificateur de tâches) et lance les bonnes tâches à la bonne cadence — commit-graph, objets isolés, repack incrémental, prefetch. `git maintenance run --task=commit-graph` lance une tâche à la main. `git maintenance unregister` défait tout cela.

### Survivre à un reformatage de masse

Quelqu'un passe le formateur sur toute la base de code et maintenant `git blame` dit que chaque ligne a été touchée en dernier par lui, dans ce commit. La correction :

```ini
[blame]
	ignoreRevsFile = .git-blame-ignore-revs
```

Mettez les SHAs des commits de changement de masse dans un fichier `.git-blame-ignore-revs` à la racine du dépôt, un par ligne, les commentaires avec `#`, et committez-le. `git blame` les saute et montre à nouveau le véritable auteur de chaque ligne.

> :warning:
> Réglez celui-ci **localement**, par dépôt, pas globalement. Si le fichier n'existe pas, `git blame` ne hausse pas les épaules — il meurt avec `fatal: could not open object name list: .git-blame-ignore-revs`. Un `blame.ignoreRevsFile` global casse blame dans tous les dépôts qui n'en ont pas. L'alternative est `git blame --ignore-revs-file=...` en ligne de commande quand vous en avez besoin.

## Les alias

Les alias, ce n'est que de la configuration. C'est le gain de confort le moins cher de Git.

```console
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.sw switch
git config --global alias.br branch
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.amend "commit --amend --no-edit"
git config --global alias.undo "reset --soft HEAD^"
git config --global alias.last "log -1 --stat"
```

`git lg` est celui que vous utiliserez toutes les heures — tout le graphe, une ligne par commit, avec les noms de branches et de tags dessus :

```console
* 112dc50 (HEAD -> main) Set the author to Grace
| * d723515 (theirs) Set the author to Ada
|/
* 02b8d1b Add metadata
```

`git amend` réutilise le message courant et fond discrètement vos changements indexés dans le dernier commit. `git undo` dé-committe le dernier commit en laissant tous ses changements indexés — le bouton « oups, mauvais message, mauvais fichiers, mauvais tout ». Les deux réécrivent l'historique, ils sont donc réservés aux commits que vous n'avez pas poussés ; voir [Garder un historique propre, se remettre de ses erreurs](../2-collaborating/6-git-cleanup.md "Garder un historique propre, se remettre de ses erreurs").

Un alias dont la valeur commence par `!` est passé au shell plutôt qu'à Git, ce qui veut dire qu'il peut enchaîner des commandes et utiliser des arguments :

```ini
[alias]
	wip = "!git add -A && git commit -m 'wip: savepoint' --no-verify"
	unstage = "reset HEAD --"
	pushf = "push --force-with-lease"
```

`git wip` est un point de sauvegarde : tout indexer, committer avec un message jetable, sauter les hooks. Ce n'est pas un commit que l'on garde — c'est ce que l'on tape avant d'aller déjeuner, et que l'on écrase plus tard.

> :information_source:
> Les alias shell s'exécutent depuis la **racine du dépôt**, pas depuis le répertoire où vous les avez tapés. Si vous avez besoin du répertoire où vous vous teniez, Git le met dans `$GIT_PREFIX`.

Il existe un second mécanisme, plus puissant. **Tout exécutable nommé `git-<quelquechose>` présent dans votre `PATH` devient une sous-commande Git.** Déposez un script appelé `git-hello` quelque part dans votre `PATH`, faites un `chmod +x`, et `git hello world` l'exécute — sur ma machine il répond `hello from a custom subcommand, args: world`. C'est tout ce qu'est une sous-commande personnalisée. Ce cours en livre une : `utilities/git-object-read`, qui affiche un objet isolé avec son en-tête intact, fonctionne exactement ainsi. Il y a un exemple plus long, `git-chuck`, dans [Briller en société et épater ses amis avec le Gitfoo](../5-automation/5-git-foo.md "Briller en société et épater ses amis avec le Gitfoo").

## L'intégration au shell : complétion et invite

La complétion d'abord, parce qu'elle est gratuite. Git livre `contrib/completion/git-completion.bash` et `git-completion.zsh` ; votre gestionnaire de paquets les a presque certainement déjà installés (`brew install git` et la plupart des paquets `git` sous Linux les branchent). Avec la complétion activée, compléter au tabulateur des noms de branches, de dépôts distants, de clés de configuration et d'options `--` est une tout autre expérience.

Pour zsh, le plugin `git` d'oh-my-zsh apporte la complétion plus un gros tas d'alias. Pour fish, la complétion est intégrée.

Puis l'invite. Git livre `contrib/completion/git-prompt.sh`, qui définit une fonction shell `__git_ps1` :

```console
source /usr/share/git-core/contrib/completion/git-prompt.sh
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM=auto
PS1='\w$(__git_ps1 " (%s)") \$ '
```

Cela vous donne le nom de la branche dans votre invite, avec un `*` pour les changements non indexés, un `+` pour les indexés, un `%` pour les fichiers non suivis, et `<`/`>`/`<>` pour en retard/en avance/divergé par rapport à l'upstream. Une fois que vous l'avez, vous ne taperez plus jamais `git status` juste pour savoir sur quelle branche vous êtes.

Les options plus sophistiquées sont [starship](https://starship.rs/) (un binaire unique, configuré en TOML, fonctionne dans tous les shells) et [powerlevel10k](https://github.com/romkatv/powerlevel10k) (zsh uniquement, célèbre pour sa rapidité). Les deux font le même travail avec une meilleure typographie.

> :warning:
> Une invite qui calcule l'état Git lance Git à **chaque dessin de l'invite** — c'est-à-dire une fois par commande, et avec certaines configurations une fois par frappe. Dans un dépôt de 100 000 fichiers, `GIT_PS1_SHOWDIRTYSTATE=1` donnera l'impression que votre shell est cassé. La correction bon marché est de désactiver les parties liées à l'état sale (`GIT_PS1_SHOWDIRTYSTATE=` et `GIT_PS1_SHOWUNTRACKEDFILES=`, ou `git_status.disabled = true` chez starship), ou de régler `git config --local bash.showDirtyState false` dans le dépôt fautif. Mais la *vraie* correction est celle de la section précédente : `core.fsmonitor = true` et `core.untrackedCache = true` rendent la question sous-jacente rapide, si bien que l'invite peut continuer d'y répondre.

## `git log` et `git diff` comme outils d'enquête

La plupart des gens apprennent `git log` et s'arrêtent là. C'est en réalité un langage de requête sur votre historique, et le connaître fait la différence entre « je n'ai aucune idée de quand ça a cassé » et une réponse en deux minutes.

### La forme

```console
git log --oneline --graph --decorate --all
```

C'est le `git lg` de plus haut, et c'est la photographie du dépôt. `--all` compte : sans lui, vous ne voyez que l'historique atteignable depuis **HEAD**, ce qui cache exactement la branche que vous cherchiez.

```console
git log --oneline --first-parent
```

Sur une branche pleine de commits de fusion, `--first-parent` ne suit que le premier parent de chaque fusion, ce qui, sur un `main` qui reçoit des pull requests fusionnées, vous donne une ligne par fonctionnalité fusionnée au lieu de chaque commit jamais écrit par quiconque. C'est ce que Git a de plus proche d'un journal des modifications de version.

### `A..B` contre `A...B` — ce que tout le monde se trompe

Deux points et trois points, ce n'est pas la même chose, et la différence mord. Construisons la situation : `main` et `feature` ont divergé après un commit commun.

```console
git log --oneline --graph --decorate --all
```

```console
* 655127f (feature) Feature: second step
* 8cbd8b2 Feature: first step
| * b19fd04 (HEAD -> main) Main: a hotfix
|/
* 3854e08 Initial commit
```

`main..feature` veut dire « les commits atteignables depuis `feature` mais pas depuis `main` » — ce que la branche de fonctionnalité a et que `main` n'a pas :

```console
git log --oneline main..feature
```

```console
655127f Feature: second step
8cbd8b2 Feature: first step
```

Inversez et vous obtenez l'autre côté, qui est une réponse complètement différente :

```console
git log --oneline feature..main
```

```console
b19fd04 Main: a hotfix
```

Trois points, c'est la **différence symétrique** : tout ce qui est d'un côté ou de l'autre sans être des deux.

```console
git log --oneline main...feature
```

```console
b19fd04 Main: a hotfix
655127f Feature: second step
8cbd8b2 Feature: first step
```

`--left-right` vous dit de quel côté est chaque commit — `<` pour la gauche, `>` pour la droite :

```console
git log --oneline --left-right main...feature
```

```console
< b19fd04 Main: a hotfix
> 655127f Feature: second step
> 8cbd8b2 Feature: first step
```

> :warning:
> `git diff` utilise les deux mêmes écritures pour des sens *presque opposés*, et c'est là le vrai piège. Pour `diff`, `main..feature` est la simple différence entre les deux commits — il vous montrera le correctif de `main` comme une *suppression*, parce que ce fichier n'est pas sur `feature`. `main...feature` compare à partir de la **base de fusion**, ce qui est le sens de « qu'est-ce que ma branche change ? » et ce que montre toute revue de code. Comparez :
>
> ```console
> git diff --stat main..feature
> ```
>
> ```console
>  file.txt  | 2 ++
>  other.txt | 1 -
>  2 files changed, 2 insertions(+), 1 deletion(-)
> ```
>
> ```console
> git diff --stat main...feature
> ```
>
> ```console
>  file.txt | 2 ++
>  1 file changed, 2 insertions(+)
> ```
>
> La suppression de `other.txt` dans le premier est un mensonge sur votre branche. Utilisez trois points pour relire une branche.

### Les filtres

`--since=2.weeks`, `--until=yesterday`, `--author=ada`, `--grep=timeout` (cherche dans les *messages* de commit), `--no-merges`, `-- chemin/vers/fichier` pour restreindre à un chemin. Ils se composent. `git log --no-merges --since=1.month --author=ada -- src/` est une chose parfaitement ordinaire à taper.

`git shortlog -sn` compte les commits par auteur, ce qui est la manière de découvrir à qui demander à propos d'un sous-système :

```console
git shortlog -sn --all
```

```console
     4	Ori Pekelman
```

### Le pic à glace : chercher du *contenu* à travers le temps

C'est la fonctionnalité qui fait de Git une machine à remonter le temps plutôt qu'une archive. `-S<chaîne>` trouve les commits où le *nombre d'occurrences* d'une chaîne a changé — c'est-à-dire où elle a été introduite ou retirée.

```console
git log --oneline -S 'TIMEOUT = 30'
```

```console
fbd72a6 Raise the timeout because CI is slow
e04de64 Add the greeter
```

Deux commits : celui qui a ajouté cette ligne, et celui qui l'a enlevée. Pas les commits qui ont simplement touché au fichier — les commits qui ont changé *ce texte*. `-G<regex>` est la cousine plus lâche : tout commit dont le diff correspond à la regex, y compris une ligne qui a été déplacée.

`-L` suit un intervalle de lignes à travers l'historique :

```console
git log --oneline -L 4,4:greeter.py
```

```console
fbd72a6 Raise the timeout because CI is slow

diff --git a/app.py b/app.py
--- a/app.py
+++ b/app.py
@@ -4,1 +4,1 @@
-TIMEOUT = 30
+TIMEOUT = 90
e04de64 Add the greeter

diff --git a/app.py b/app.py
--- /dev/null
+++ b/app.py
@@ -0,0 +4,1 @@
+TIMEOUT = 30
```

Vous pouvez aussi écrire `-L :nomdefonction:fichier` pour suivre une fonction entière.

> :warning:
> `-L` prend une forme *différente* dans `git log` et dans `git blame`, et chacun rejette catégoriquement l'écriture de l'autre. `git log` veut un seul argument joint par un deux-points — `git log -L :greet:app.py` — et `git log -L :greet app.py` meurt avec `fatal: -L<range>:<file> cannot be used with pathspec`. `git blame` les veut séparés — `git blame -L :greet app.py` — et la forme avec deux-points affiche juste le message d'usage. Il n'y a aucune bonne raison à cela ; c'est l'un des accidents dont nous parlions dans [Git et son écosystème](../1-understanding-git/2-git-ecosystem.md "Git et son écosystème"). Retenez que les deux ne sont pas d'accord et vous vous épargnerez une minute de perplexité.

Et `--follow` conserve l'historique d'un fichier à travers les renommages — notez que le fichier s'appelait `app.py` dans les diffs ci-dessus :

```console
git log --oneline --follow greeter.py
```

```console
32101ee Rename app.py to greeter.py
fbd72a6 Raise the timeout because CI is slow
1cc7f30 Use an f-string
e04de64 Add the greeter
```

### Mieux lire les diffs

`git diff --stat` pour la forme d'un changement. `--word-diff` quand une ligne a été éditée plutôt que réécrite :

```console
git diff --word-diff HEAD~3 HEAD~2 -- app.py
```

```console
@@ -1,4 +1,4 @@
def greet(name):
    return [-"Hello " + name-]{+f"Hello {name}"+}

TIMEOUT = 30
```

`--color-moved` (ou la configuration `diff.colorMoved` de tout à l'heure) distingue les lignes qui ont bougé de celles qui ont changé. Sur une revue de « j'ai extrait ceci dans une fonction utilitaire », c'est la différence entre lire 400 lignes et en lire 4.

### `git range-diff` : le diff de deux diffs

Vous avez rebasé une branche, ou amendé un commit en son milieu, et vous voulez maintenant savoir *ce qui a réellement changé dans le changement*. `git diff` ne peut pas répondre à cela — les deux versions de la branche ont des parents différents. `git range-diff`, si :

```console
git range-diff main feature feature-v2
```

```console
1:  8cbd8b2 = 1:  8cbd8b2 Feature: first step
2:  655127f ! 2:  70ef0e7 Feature: second step
    @@ Metadata
     Author: Ori Pekelman <ori+git-training@pekelman.com>

      ## Commit message ##
     -    Feature: second step
     +    Feature: second step, with a better message

      ## file.txt ##
     @@
-:  ------- > 3:  a97c54b Feature: polish
```

Lisez les marqueurs : `=` veut dire que ce commit a traversé la réécriture intact, `!` veut dire qu'il a changé et voici comment, `-:`/`>` veut dire que celui-ci est nouveau. Si vous relisez la branche force-poussée d'un collègue et voulez vérifier qu'il n'a traité que vos commentaires, c'est la commande. C'est aussi ainsi que vous auditez votre propre rebase interactif.

### `git bisect run` : l'outil le plus tranchant de la boîte

Vous savez que ça marchait douze commits en arrière et que c'est cassé maintenant. Ne lisez pas douze diffs. Écrivez un script qui sort avec `0` quand tout va bien et non nul quand c'est cassé, et laissez Git faire une recherche dichotomique :

```console
git bisect start HEAD HEAD~11
git bisect run ./test.sh
```

```console
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[62f0c3867f74bc72f055938b7a3ad54507c8477f] Commit 6: harmless note
running './test.sh'
Bisecting: 2 revisions left to test after this (roughly 2 steps)
[b83108de0b02c7233d6b51e7896f185f24d65e08] Commit 9: harmless note
running './test.sh'
Bisecting: 0 revisions left to test after this (roughly 1 step)
[67baa58510d9badf79e28e4fbb2be9a1354aa6e6] Commit 8: harmless note
running './test.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[5d20f59bd6ea1ff63b19d75a9cef312b00e9ab21] Commit 7: an innocent refactor
running './test.sh'
5d20f59bd6ea1ff63b19d75a9cef312b00e9ab21 is the first bad commit
commit 5d20f59bd6ea1ff63b19d75a9cef312b00e9ab21
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Thu Jul 30 00:03:37 2026 +0200

    Commit 7: an innocent refactor

 answer.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit
```

Quatre étapes automatisées pour trouver le coupable parmi douze commits, et il a affiché le diff. `git bisect reset` vous remet là où vous étiez. Le script peut être votre suite de tests, un seul test de celle-ci, un `grep`, un `curl` — n'importe quoi qui a un code de retour. Le code de retour `125` veut dire « impossible de tester ce commit, saute-le ».

C'est le meilleur argument qui soit en faveur de petits commits autonomes qui compilent toujours : ce sont eux qui font marcher `git bisect run`.

## L'indexation interactive : `git add -p`

L'autre habitude à cultiver. Vous avez fait trois changements sans rapport dans un fichier et vous voulez trois commits. `git add -p` vous fait parcourir le diff section par section :

```console
git add -p
```

```console
diff --git a/words.txt b/words.txt
index e0396ff..ac57c0a 100644
--- a/words.txt
+++ b/words.txt
@@ -1,8 +1,8 @@
 alpha
 bravo
-charlie
+CHARLIE
 delta
 echo
-foxtrot
+FOXTROT
 golf
 hotel
(1/1) Stage this hunk [y,n,q,a,d,s,e,p,?]?
```

`?` affiche la liste complète des touches, qui mérite d'être lue une fois. L'essentiel : `y` on l'indexe, `n` on la saute, `q` on quitte, `a` on indexe celle-ci et tout le reste de ce fichier, `d` on saute celle-ci et tout le reste de ce fichier, `j`/`k` pour remettre une décision à plus tard.

Les deux que personne n'apprend sont les deux qui comptent.

**`s` scinde la section.** Ces deux changements ci-dessus sont arrivés comme une seule section parce qu'ils sont proches l'un de l'autre. Appuyez sur `s` :

```console
(1/1) Stage this hunk [y,n,q,a,d,s,e,p,?]? Split into 2 hunks.
@@ -1,5 +1,5 @@
 alpha
 bravo
-charlie
+CHARLIE
 delta
 echo
(1/2) Stage this hunk [y,n,q,a,d,j,J,g,/,e,p,?]?
```

Maintenant vous pouvez prendre l'une et laisser l'autre. Si Git dit `Sorry, cannot split this hunk`, c'est que les changements sont adjacents sans ligne de contexte entre eux — et c'est à cela que sert `e`.

**`e` ouvre la section dans votre éditeur.** Vous obtenez le diff brut et vous l'éditez à la main : supprimez une ligne `+` pour ne pas l'indexer, transformez un `-` en espace pour garder cette suppression hors de ce commit. Les instructions que Git met en bas du tampon vous donnent les règles. C'est de l'indexation ligne par ligne, et c'est la seule manière de scinder deux changements qui vivent dans le voisinage de la même ligne. Rien de ce que vous faites ici ne touche vos fichiers — seulement l'**index**.

Il existe aussi une interface plus ancienne, pilotée par menu, `git add -i`, depuis laquelle `p` vous amène au mode patch ci-dessus :

```console
git add -i
```

```console
           staged     unstaged path
  1:    unchanged        +2/-2 words.txt

*** Commands ***
  1: [s]tatus	  2: [u]pdate	  3: [r]evert	  4: [a]dd untracked
  5: [p]atch	  6: [d]iff	  7: [q]uit	  8: [h]elp
What now>
```

Son `4: add untracked` est véritablement pratique pour piocher quelques nouveaux fichiers parmi beaucoup.

La même machinerie `-p` apparaît dans plusieurs autres commandes :

* `git stash -p` ne met de côté que les sections que vous choisissez — « range mon débogage, garde la vraie correction ».
* `git restore -p` ne jette que les sections que vous choisissez. Attention : contrairement aux autres, celle-ci détruit du travail.
* `git checkout -p` et `git reset -p` existent aussi, et se comportent comme vous vous y attendez désormais.

## Les outils que j'installerais vraiment

L'écosystème Git compte des centaines d'outils. Voici ceux qui, à mon avis, méritent leur place, dans l'ordre où je les installerais. Les clients graphiques et les intégrations d'éditeurs ont leurs propres chapitres — [Les clients Git graphiques](3-git-guis.md "Les clients Git graphiques") et [Les éditeurs, les IDE et le navigateur de fichiers](4-git-ides.md "Les éditeurs, les IDE et le navigateur de fichiers") — cette liste ne concerne donc que les outils du terminal.

**lazygit** est ce que je recommanderais à la plupart des gens, et c'est celui que j'installerais en premier sur une machine neuve. C'est une interface terminal plein écran : des panneaux pour le statut, les branches, les commits, le stash et le diff, et les opérations qui sont fastidieuses en ligne de commande — indexer des lignes individuelles, réordonner des commits, résoudre des conflits, le rebase interactif — deviennent deux ou trois frappes. Surtout, ce n'est pas un substitut à la compréhension de Git ; c'est une manière plus rapide de piloter le Git que vous comprenez désormais.

**delta** est le plus grand gain de confort par octet de configuration. C'est un pageur pour `git diff` : coloration syntaxique, mode côte à côte, numéros de ligne, et un bien meilleur rendu du code déplacé.

```ini
[core]
	pager = delta
[interactive]
	diffFilter = delta --color-only
[delta]
	navigate = true
	side-by-side = true
	line-numbers = true
[merge]
	conflictStyle = zdiff3
```

La ligne `interactive.diffFilter` est celle que les gens oublient — sans elle, `git add -p` garde le diff ordinaire. La section `[delta]` n'est pas un réglage Git ; Git ignore les sections qu'il ne connaît pas, et delta lit sa propre configuration dans votre `~/.gitconfig`.

**difftastic** (le binaire s'appelle `difft`) est une idée différente, et qui mérite d'être comprise plutôt que simplement installée. Tous les outils de diff ci-dessus comparent des *lignes*. difftastic analyse les deux fichiers avec une vraie grammaire et compare des *arbres syntaxiques*. Ainsi, réindenter un bloc, envelopper du code dans un `if`, ou renommer un paramètre apparaît comme le petit changement structurel que c'est, au lieu d'un gros changement textuel. Branchez-le comme un second avis, pas comme votre outil par défaut :

```ini
[difftool "difftastic"]
	cmd = difft "$LOCAL" "$REMOTE"
[difftool]
	prompt = false
[alias]
	dft = "-c diff.external=difft diff"
```

`git dft` vous donne alors un diff structurel et un simple `git diff` vous donne toujours le familier. (Oui, un alias peut commencer par `-c` ; Git développe l'alias dans sa propre liste d'arguments.)

**tig** est un navigateur ncurses pour le log, le blame et le statut, et il est installé ici :

```console
tig --version
```

```console
tig version 2.6.0
```

Lancez `tig` dans un dépôt et vous obtenez le graphe ; les touches qui comptent sont `Entrée` pour ouvrir le commit sous le curseur dans une vue divisée, `d` pour son diff, `t` pour l'arbre à ce commit, `b` pour un blame sur le fichier que vous regardez, `/` pour chercher, `h` pour l'aide et `q` pour reculer d'un niveau. `tig blame <fichier>` et `tig status` (où vous pouvez indexer des sections) vont droit à ces vues. Il est plus petit et plus ciblé que lazygit : un très bon *lecteur* d'historique.

**gitui** est un autre client terminal plein écran, écrit en Rust, sur le même territoire que lazygit. Il est aussi ici (`gitui --version` rapporte `gitui nightly 2025-01-14`). Essayez les deux et gardez celui qui va à vos mains.

**git-absorb** résout magnifiquement un problème agaçant : vous avez une pile de commits en relecture et trois petites corrections dans votre **worktree**, et chaque correction appartient à un commit différent. `git absorb --and-rebase` détermine à quel commit appartient chaque section, crée les commits `fixup!` et les écrase dedans. C'est `--fixup` sans la comptabilité.

**gh** et **glab** sont les clients en ligne de commande de GitHub et GitLab. Ce ne sont pas Git — ils parlent à l'API de la forge — mais `gh pr create`, `gh pr checkout 42` et `gh run watch` suppriment beaucoup de va-et-vient entre onglets. `gh` est installé ici (`gh version 2.80.0`). Voir [Héberger Git, et l'héberger soi-même](2-git-hosting.md "Héberger Git, et l'héberger soi-même").

Voilà la liste. Pas vingt outils : deux interfaces terminal entre lesquelles choisir, un pageur, un outil de diff structurel, un navigateur d'historique, un correcteur de niche, un client de forge.

## Outils de diff et de fusion

Git peut confier un diff ou un conflit à un programme externe.

```console
git difftool
git difftool -t vimdiff HEAD~1
git mergetool
```

`git difftool` se comporte comme `git diff` mais ouvre chaque paire de fichiers dans l'outil que vous avez configuré ; `git mergetool` parcourt les fichiers en conflit après une fusion ratée. Ce qui est disponible dépend de votre machine :

```console
git mergetool --tool-help
```

```console
'git mergetool --tool=<tool>' may be set to one of the following:
		araxis           Use Araxis Merge (requires a graphical session)
		opendiff         Use FileMerge (requires a graphical session)
		vimdiff          Use Vim with a custom layout (see `git help mergetool`'s `BACKEND SPECIFIC HINTS` section)
		vimdiff1         Use Vim with a 2 panes layout (LOCAL and REMOTE)
		vimdiff2         Use Vim with a 3 panes layout (LOCAL, MERGED and REMOTE)
		vimdiff3         Use Vim where only the MERGED file is shown
		vscode           Use Visual Studio Code (requires a graphical session)
```

En configurer un fait deux lignes, et n'importe quel programme peut être un outil de fusion parce que Git se contente de lui passer quatre noms de fichiers :

```ini
[merge]
	tool = my-tool
[mergetool "my-tool"]
	cmd = my-tool "$LOCAL" "$BASE" "$REMOTE" "$MERGED"
[mergetool]
	prompt = false
	keepBackup = false
```

Ces quatre noms constituent tout le modèle d'une interface de fusion à trois points, et la manière la plus sûre de les voir est de fabriquer un « outil de fusion » qui ne fait qu'afficher leurs noms. En faisant exactement cela pendant le conflit de tout à l'heure :

```console
Normal merge conflict for 'meta.yaml':
  {local}: modified file
  {remote}: modified file
BASE   (./meta_BASE_78557.yaml):
    title: Report
    author: nobody
    year: 2024
LOCAL  (./meta_LOCAL_78557.yaml):
    title: Report
    author: Grace
    year: 2024
REMOTE (./meta_REMOTE_78557.yaml):
    title: Report
    author: Ada
    year: 2024
MERGED (meta.yaml) is the file Git will keep
```

* **BASE** est la **base de fusion**, l'ancêtre commun — le même contenu que `zdiff3` vous montre entre les marqueurs `|||||||`.
* **LOCAL** est votre côté, la branche sur laquelle vous êtes.
* **REMOTE** est leur côté, la branche que vous fusionnez.
* **MERGED** est le fichier de travail avec les marqueurs de conflit, et c'est le seul qui survit. Une interface à trois panneaux vous montre les trois premiers en lecture seule et vous laisse construire le quatrième.

`mergetool.keepBackup = false` empêche Git de laisser derrière lui des fichiers `.orig`, et `mergetool.prompt = false` l'empêche de demander la permission avant chaque fichier. Tout ce qui concerne la résolution du conflit lui-même est dans [Mettre en œuvre un workflow collaboratif efficace](../2-collaborating/5-git-workflow.md "Mettre en œuvre un workflow collaboratif efficace").

## Les hooks : faire exécuter votre code par Git

Un **hook** est un exécutable que Git lance à un moment défini. Chaque dépôt naît avec un répertoire d'exemples :

```console
ls .git/hooks
```

```console
applypatch-msg.sample
commit-msg.sample
fsmonitor-watchman.sample
post-update.sample
pre-applypatch.sample
pre-commit.sample
pre-merge-commit.sample
pre-push.sample
pre-rebase.sample
pre-receive.sample
prepare-commit-msg.sample
push-to-checkout.sample
sendemail-validate.sample
update.sample
```

La règle est simple : enlevez le suffixe `.sample`, rendez le fichier exécutable, et Git le lance. Le langage n'a pas d'importance — un shebang, un code de retour, voilà le contrat. **Un code de retour non nul d'un hook en « pre- » avorte l'opération.**

Ceux qui méritent votre temps :

* `pre-commit` — s'exécute avant que le message de commit ne soit écrit. Formater, linter, refuser les restes de débogage.
* `commit-msg` — reçoit le fichier du message. Imposer une convention, refuser un sujet vide, exiger un numéro de ticket.
* `prepare-commit-msg` — édite le message *avant* que vous ne le voyiez, par exemple en préremplissant un identifiant de ticket depuis le nom de la branche.
* `pre-push` — s'exécute avant que les objets ne partent sur le réseau. Le bon endroit pour la suite de tests, ou pour un garde-fou « pas vers `main` ».
* `pre-receive` et `update` — s'exécutent sur le **serveur**. C'est le seul type de hook qu'un développeur ne peut pas contourner, c'est donc là que vit la véritable politique.
* `post-receive` — s'exécute sur le serveur après la mise à jour des références. C'est ainsi que fonctionne le déploiement par push, et [Déployer un site statique simple](../5-automation/3-git-static-site.md "Déployer un site statique simple") en construit un vrai.

`core.hooksPath` déplace le répertoire des hooks, ce qui est ce qui rend les hooks partageables :

```console
git config core.hooksPath .githooks
```

Maintenant les hooks vivent dans un répertoire `.githooks/` versionné dans le dépôt. En committant celui-ci et en le lançant :

```console
git commit -m "add a breakpoint"
```

```console
pre-commit: checking for stray debugger statements
pre-commit: found a breakpoint(), refusing the commit
```

Le commit n'a pas eu lieu ; le hook est sorti avec `1`. `git commit --no-verify` (ou `-n`) saute les hooks côté client, ce qui est exactement pourquoi ceux qui comptent vraiment vivent sur le serveur.

> :information_source:
> **Les hooks ne sont pas versionnés et ne sont pas transférés par un clone.** `.git/hooks` est à l'intérieur de `.git`, il ne fait donc partie d'aucun **commit**, et `git clone` ne le copie pas. C'est délibéré — un dépôt qui pourrait livrer du code que votre machine exécute au `git commit` serait une charmante attaque — et c'est aussi pourquoi « nous avons un hook de pre-commit » n'est jamais une politique. Votre nouveau collègue ne l'a tout simplement pas.

Les frameworks existent pour combler exactement ce vide. Ils gardent la configuration dans un fichier versionné et installent localement un petit hook aiguilleur :

* **pre-commit** (l'outil Python, [pre-commit.com](https://pre-commit.com/)) est le standard de fait, et il est agnostique quant au langage malgré son écriture en Python. Vous committez un `.pre-commit-config.yaml` listant les hooks et leurs versions ; chaque contributeur lance `pre-commit install` une fois, et l'outil les récupère et les lance dans des environnements isolés.
  ```yaml
  repos:
    - repo: https://github.com/pre-commit/pre-commit-hooks
      rev: v5.0.0
      hooks:
        - id: trailing-whitespace
        - id: end-of-file-fixer
        - id: check-yaml
  ```
* **husky** plus **lint-staged** est la réponse du monde JavaScript : husky règle `core.hooksPath` sur un répertoire versionné, lint-staged lance vos linters sur les seuls fichiers indexés.
* **lefthook** est un binaire unique configuré dans `lefthook.yml`, sans environnement d'exécution propre, et il lance ses tâches en parallèle.

Quel que soit votre choix, gardez les hooks *rapides*. Un hook de `pre-commit` qui prend quinze secondes est un hook de `pre-commit` que tout le monde contourne avec `-n`. Le formatage et le lint sur les fichiers indexés ont leur place dans `pre-commit` ; la suite de tests complète a la sienne dans `pre-push` ou, mieux, dans [L'intégration continue avec Git](../5-automation/2-git-ci.md "L'intégration continue avec Git"), qui est le seul endroit où une vérification ne peut pas être contournée.

> :warning:
> Les hooks sont du **code exécutable qui arrive avec un dépôt**, et vous devriez les considérer ainsi. Un `.githooks/pre-commit` committé plus un `core.hooksPath` dans les instructions d'installation, un `.pre-commit-config.yaml` pointant vers un dépôt de hooks que vous n'avez jamais lu, un script `prepare` de `package.json` qui lance `husky` — chacun de ceux-là est un chemin de « j'ai cloné ceci et lancé la commande d'installation » vers « du code arbitraire s'est exécuté sous mon identité ». C'est une surface de chaîne d'approvisionnement, et elle a été utilisée. Donc : lisez les hooks avant de les activer, épinglez les dépôts de hooks à un tag ou à un **SHA** plutôt qu'à une branche mouvante, et ne lancez pas `npm install`, `pre-commit install` ni un script d'installation dans un dépôt auquel vous ne faites pas confiance. Cloner un dépôt est sûr. Lancer son outillage ne l'est pas.

## Récapitulatif : `git config`, `git bisect`, `git range-diff`, `git maintenance`

* `git config --list --show-origin --show-scope` vous dit d'où vient chaque réglage, à travers les portées **system**, **global**, **local** et **worktree**, la dernière l'emportant.
* Une douzaine de lignes de configuration corrigent les plus vieux défauts de Git : `pull.ff = only` contre les commits de fusion accidentels, `push.autoSetupRemote` contre la danse de l'upstream, `merge.conflictStyle = zdiff3` pour voir la **base de fusion** dans un conflit, `rerere.enabled` pour cesser de résoudre deux fois le même conflit, `rebase.updateRefs` pour les branches empilées, `diff.algorithm = histogram` et `diff.colorMoved` pour des diffs lisibles, `fetch.prune` pour une liste de branches véridique.
* `core.fsmonitor` et `core.untrackedCache` sont le vrai remède à un `git status` lent et donc à une invite de shell lente. `git maintenance start` est le remplaçant moderne d'un `git gc` en cron.
* `blame.ignoreRevsFile` vous rend un `git blame` utilisable après un reformatage de masse — réglez-le par dépôt, parce qu'un fichier absent est une erreur fatale.
* Les alias sont de la configuration ; un alias qui commence par `!` s'exécute dans le shell ; et tout exécutable nommé `git-<nom>` dans votre `PATH` devient une sous-commande Git.
* La complétion et une invite `__git_ps1`, starship ou powerlevel10k se remboursent chaque jour — tant que le `git status` sous-jacent est rapide.
* `A..B`, c'est « atteignable depuis B, pas depuis A » ; `A...B`, c'est la différence symétrique, et pour `git diff` cela veut dire « diff depuis la **base de fusion** », ce qui est ce que vous voulez pour relire une branche. `--left-right` étiquette les côtés.
* `-S` et `-G` cherchent du contenu à travers l'historique, `-L` suit des lignes, `--follow` suit les renommages, `--first-parent` lit un historique fusionné, `git shortlog -sn` compte les auteurs.
* `git range-diff` compare deux versions d'une branche — l'outil pour relire un push forcé ou auditer son propre rebase.
* `git bisect run <script>` trouve le commit qui a cassé quelque chose en log₂ étapes, ce qui est la meilleure raison de faire de petits commits.
* `git add -p` indexe section par section ; `s` scinde une section et `e` vous laisse l'éditer à la main. Le même `-p` fonctionne avec `stash`, `restore`, `checkout` et `reset`.
* À installer : `lazygit` (ou `gitui`), `delta` comme pageur, `difftastic` pour les diffs structurels, `tig` pour lire l'historique, `git-absorb`, et `gh`/`glab` pour votre forge.
* `git difftool` et `git mergetool` confient des fichiers à un programme externe ; une interface de fusion à trois points montre LOCAL, BASE et REMOTE, et vous construisez MERGED.
* Les hooks vivent dans `.git/hooks` ou là où pointe `core.hooksPath`, ne sont **pas** versionnés et **pas** clonés ; `pre-commit`, `husky` + `lint-staged` et `lefthook` corrigent cela, et chacun d'eux est une surface de chaîne d'approvisionnement à traiter avec suspicion.
