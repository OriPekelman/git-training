---
title: Récupérer et envoyer du code
slug: "git-clone-pull-remote"
weight: 13
---
# Récupérer et envoyer du code

Nous savons maintenant ce qu'est un **remote** : un nom pour une URL et un **refspec**, écrits dans `.git/config`. Nous savons que `origin/master` est un cache local et non le serveur. Il est temps de déplacer réellement des objets.

Trois commandes font tout le travail : `git clone` pour obtenir un dépôt en premier lieu, `git fetch` pour faire descendre ce qui a changé, `git push` pour faire monter ce que nous avons changé. `git pull` est une quatrième qui est en réalité la deuxième plus une fusion, et nous allons être un peu impolis à son sujet.

Nous continuerons à utiliser un répertoire de notre propre disque comme dépôt distant, exactement comme au chapitre précédent. Tout ce qui est montré ici se comporte de manière identique face à une URL SSH ou HTTPS — la seule différence, c'est l'URL et quelques lignes de progression.

## Reproduire localement du code stocké ailleurs : `git clone`

```console
cd ~/projects
git clone ~/projects/my_first_git_project.git my_project_clone
```
```console
Cloning into 'my_project_clone'...
done.
```

Laconique. Sur un réseau, vous verriez aussi une poignée de lignes de progression — `remote: Enumerating objects`, `remote: Counting objects`, `Receiving objects`, `Resolving deltas` — qui sont Git et le serveur se disant l'un à l'autre combien de travail il reste. En local, il n'y a rien à énumérer, donc : `done.`

Or, `clone` ressemble à une opération mais en fait cinq, et savoir lesquelles explique toutes les questions que vous vous poserez jamais à son sujet. Dans l'ordre :

1. **`git init`** un nouveau dépôt dans le répertoire cible. Si nous ne donnons pas de nom de répertoire, Git en dérive un depuis l'URL (`my_first_git_project`, en laissant tomber le `.git`).
2. **Ajouter un dépôt distant appelé `origin`** pointant vers l'URL que nous avons donnée. *Voilà* d'où vient la convention — rien de plus mystique qu'une valeur par défaut dans `clone`.
3. **Tout récupérer** : tous les objets atteignables depuis toutes les branches et étiquettes du dépôt distant, dans `.git/objects`.
4. **Créer les références de suivi distant**, selon le refspec : chaque `refs/heads/*` de là-bas devient un `refs/remotes/origin/*` ici.
5. **Créer une seule branche locale** — correspondant à ce vers quoi pointe le **HEAD** du dépôt distant — établir son **upstream**, et l'extraire dans l'arbre de travail.

Chacune de ces cinq étapes est visible. Étapes 1 et 5 :

```console
cd my_project_clone
ls -a
```
```console
.  ..  .git  media  readme.md
```

Étape 2, et l'upstream de l'étape 5 :

```console
cat .git/config
```
```console
[core]
	{..}
[remote "origin"]
	url = /Users/oripekelman/projects/my_first_git_project.git
	fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
	remote = origin
	merge = refs/heads/master
```

Pas une ligne de tout cela ne nous est nouvelle. Nous avons écrit exactement la même chose à la main au chapitre précédent avec `git remote add` et `git push -u`. `clone` est une enveloppe de commodité, et vous pourriez maintenant l'implémenter vous-même.

Étape 4, et la réponse à « où sont mes références » :

```console
tree .git/refs
cat .git/packed-refs
```
```console
.git/refs
├── heads
│   └── master
├── remotes
│   └── origin
│       └── HEAD
└── tags
```
```console
# pack-refs with: peeled fully-peeled sorted
973f21b9767b572145add7f9e4444a14529fc1fe refs/remotes/origin/master
1213fc5f325573870748535e5d457573a9c80b50 refs/remotes/origin/shopping_cart
```

Remarquez l'asymétrie : `refs/heads/master` est un fichier isolé, parce que Git l'a écrit en dernier et n'a pas encore rangé, tandis que les références de suivi distant sont déjà **empaquetées**. Remarquez aussi `refs/remotes/origin/HEAD` — une note indiquant quelle branche le serveur considère comme celle par défaut, ce qui explique que `git branch -a` puisse dire :

```console
git branch -a
```
```console
* master
  remotes/origin/HEAD -> origin/master
  remotes/origin/master
  remotes/origin/shopping_cart
```

Et la conséquence la plus importante de l'étape 5, qui surprend les gens :

```console
git branch -vv
```
```console
* master 973f21b [origin/master] Add readme.md and the media directory
```

**Une seule** branche locale. Le serveur en a deux, nous avons obtenu des références de suivi pour les deux, mais Git n'a créé une branche locale que pour celle par défaut. `shopping_cart` n'est pas absente — `git checkout shopping_cart` créera sur-le-champ une branche locale qui suit `origin/shopping_cart`, parce que Git remarque que le nom n'est pas ambigu parmi vos dépôts distants. Mais tant que vous ne le demandez pas, elle reste un marque-page.

### Options utiles de `clone`

**`--branch <nom>`** (ou `-b`) extrait cette branche au lieu de celle par défaut. Cela fonctionne aussi avec une **étiquette**, auquel cas vous atterrissez en **detached head**, ce qui est exactement ce qu'il faut pour « construire cette version ».

```console
git clone --branch shopping_cart ~/projects/my_first_git_project.git cart
cd cart && git branch -vv
```
```console
* shopping_cart 1213fc5 [origin/shopping_cart] Implement shopping cart template
```

**`--single-branch`** va plus loin et rétrécit le refspec pour que vous ne récupériez que cette branche-là, pour toujours, jusqu'à ce que vous l'élargissiez de nouveau.

**`--depth <n>`** fait un clone *superficiel* (*shallow*) : seulement les `n` derniers commits, sans ancêtres. Sur un gros projet, c'est la différence entre trois cents mégaoctets et trois.

```console
git clone --depth 1 ~/projects/my_first_git_project.git shallow_plain
```
```console
Cloning into 'shallow_plain'...
warning: --depth is ignored in local clones; use file:// instead.
done.
```

Voilà la distinction du chapitre précédent, dans la nature. Un chemin nu n'est pas un transport, il n'y a donc pas de protocole sur lequel être superficiel. Ajoutez le schéma et cela fonctionne :

```console
git clone --depth 1 file://$HOME/projects/my_first_git_project.git shallow
cd shallow && git log --oneline
```
```console
5d22437 Expand the contribution guidelines
```

Un commit. Là où devrait se trouver le deuxième, il y a un mensonge :

```console
cat .git/shallow
```
```console
5d224378681f9bf3e68915ad9d3a486ba17bc3ab
```

Ce fichier liste les commits dont Git doit faire semblant qu'ils n'ont pas de parents. C'est tout ce qu'est un clone superficiel — un petit fichier texte qui dit à Git où arrêter de marcher.

Maintenant la partie honnête, parce que les clones superficiels sont recommandés bien trop à la légère. L'historique est ce à quoi Git *sert*, et vous venez de le jeter :

* `git log` sur un fichier s'arrête à la frontière. L'archéologie — « quand cette ligne a-t-elle changé, et pourquoi » — a disparu.
* `git blame` ne fonctionne qu'à l'intérieur de ce que vous avez. `git blame -C`, qui suit le contenu à travers les déplacements de fichiers, n'a rien à suivre.
* `git describe` ne peut pas trouver une étiquette qu'il n'a pas, donc les chaînes de version de votre build deviennent bizarres.
* Les fusions et les rebases à travers la frontière peuvent échouer, parce que Git ne peut pas trouver de base de fusion.
* `git bisect` n'a rien à bissecter.

C'est pourquoi les clones superficiels ont leur place à exactement un endroit : la **CI**. Un agent de build veut le code, une fois, vite, et ensuite il est détruit. Il ne veut pas faire d'archéologie. Pour votre propre copie de travail, clonez le tout ; vous voudrez l'historique la première fois que quelque chose cassera.

Si vous avez fait un clone superficiel et que vous le regrettez :

```console
git fetch --unshallow
git log --oneline
```
```console
5d22437 Expand the contribution guidelines
1b47e8c Add contribution guidelines
2eaa6ce Add a TODO list
9056566 Add a license file
d0dcf58 Describe the project in the readme
973f21b Add readme.md and the media directory
```

Le reste de l'historique arrive et `.git/shallow` disparaît.

**`--filter=blob:none`** est la réponse moderne, et elle est bien meilleure. Elle fait un clone *partiel* : récupérer tous les commits et tous les arbres — toute la forme de l'historique — mais aucun contenu de fichier. Les blobs sont téléchargés paresseusement, un par un, au moment où une commande en a réellement besoin.

```console
git clone --filter=blob:none file://$HOME/projects/my_first_git_project.git partial
cat partial/.git/config
```
```console
[core]
	repositoryformatversion = 1
	{..}
[remote "origin"]
	url = file:///Users/oripekelman/projects/my_first_git_project.git
	fetch = +refs/heads/*:refs/remotes/origin/*
	promisor = true
	partialclonefilter = blob:none
```

`promisor = true` signifie « ce dépôt distant a promis de me donner les objets qui me manquent, chaque fois que je les demanderai ». `git log` est rapide et complet. `git blame` sur un fichier télécharge les blobs de ce fichier-là. Rien n'est un mensonge, contrairement au clone superficiel ; les choses sont simplement absentes, et elles arrivent quand on en a besoin. Il faut en revanche être en ligne pour toucher à du contenu ancien.

Le serveur doit être d'accord, et s'il ne l'est pas, Git vous le dit et continue :

```console
warning: filtering not recognized by server, ignoring
```

Combinez-le avec **`--sparse`** et vous avez la véritable réponse à « notre monorepo est énorme » : n'extrayez pas non plus tout l'arbre.

```console
git clone --filter=blob:none --sparse file://$HOME/projects/my_first_git_project.git sparse
cd sparse && ls
```
```console
CONTRIBUTING.md  LICENSE  readme.md  TODO
```

Les fichiers de la racine, aucun sous-répertoire. Le jeu de règles vit dans un fichier, et il est court :

```console
cat .git/info/sparse-checkout
```
```console
/*
!/*/
```

« Tout au premier niveau, mais aucun des répertoires. » Ces deux lignes sont le « cone mode » de Git, ce qui veut simplement dire que les motifs sont restreints à des répertoires entiers pour que Git puisse décider vite. Ensuite vous choisissez d'ajouter les parties sur lesquelles vous travaillez :

```console
git sparse-checkout add media
git sparse-checkout list
```
```console
media
```
```console
ls
```
```console
CONTRIBUTING.md  LICENSE  media  readme.md  TODO
```

`git sparse-checkout set lib views` remplace la liste, `git sparse-checkout disable` désactive tout et extrait l'ensemble. Rien n'est perdu — c'est un filtre sur l'arbre de travail, le dépôt a toujours tout (ou peut promettre de le récupérer).

**`--recurse-submodules`** clone et initialise les sous-modules du projet d'un seul coup. Sans cela, vous obtenez des répertoires vides là où les sous-modules devraient être, et un après-midi déroutant. Si vous avez oublié : `git submodule update --init --recursive`.

**`--bare`** clone la base de données sans arbre de travail — la forme que nous avons disséquée au chapitre précédent :

```console
git clone --bare ~/projects/my_first_git_project.git bare_copy.git
cat bare_copy.git/config
```
```console
[core]
	{..}
	bare = true
[remote "origin"]
	url = /Users/oripekelman/projects/my_first_git_project.git
```

Regardez de près ce bloc `[remote "origin"]` : **il n'y a pas de refspec de fetch**. Il n'y a donc pas de références de suivi distant ; les branches sont descendues directement dans `refs/heads/` :

```console
cat bare_copy.git/packed-refs
```
```console
# pack-refs with: peeled fully-peeled sorted
5d224378681f9bf3e68915ad9d3a486ba17bc3ab refs/heads/master
1213fc5f325573870748535e5d457573a9c80b50 refs/heads/shopping_cart
```

Ce qui est bien ce que vous voulez pour un serveur : son `master` est *son propre* `master`, pas le cache de celui de quelqu'un d'autre.

**`--mirror`** ressemble à la même chose et ne l'est pas :

```console
git clone --mirror ~/projects/my_first_git_project.git mirror_copy.git
cat mirror_copy.git/config
```
```console
[core]
	{..}
	bare = true
[remote "origin"]
	url = /Users/oripekelman/projects/my_first_git_project.git
	tagOpt = --no-tags
	fetch = +refs/*:refs/*
	mirror = true
```

Voilà le refspec, et lisez-le : `+refs/*:refs/*`. Pas seulement les branches — *tout*, projeté sur soi-même. Les branches, les étiquettes, les notes, les références de suivi distant de l'original, le lot, aux mêmes chemins. Plus `mirror = true`, qui fait que `git push` renvoie tout cela et supprime tout ce que la source a supprimé.

Donc : `--bare`, c'est « une copie serveur des branches ». `--mirror`, c'est « une réplique exacte qui se met à jour toute seule ». `--mirror` plus `git remote update` dans une tâche cron, c'est une stratégie de sauvegarde en deux lignes pour un hébergeur Git, et c'est ainsi que l'on déplace un dépôt d'un hébergeur à un autre sans perdre une étiquette.

> :warning:
> `git push --mirror`, ou pousser depuis un clone miroir, supprimera joyeusement sur la destination les références que la source n'a pas. C'est là tout l'intérêt d'un miroir. C'est aussi ainsi que des gens suppriment accidentellement quarante branches. Relisez l'URL deux fois.

## Récupérer les changements faits par d'autres : `git fetch` et `git pull`

Quelqu'un d'autre a travaillé. Dans notre petit monde, « quelqu'un d'autre » est le clone que nous venons de faire ; il a committé et poussé. Que faisons-nous ?

Nous ne commençons **pas** par `git pull`. Nous commençons par `git fetch`, et je veux expliquer pourquoi avec de vraies sorties plutôt qu'avec une affirmation.

Pour l'instant, notre `git status` prétend que nous sommes à jour, et — comme nous l'avons établi au chapitre précédent — cette prétention porte sur notre *souvenir* du serveur, pas sur le serveur. Alors allons demander :

```console
git fetch
```
```console
From /Users/oripekelman/projects/my_first_git_project
   973f21b..d0dcf58  master     -> origin/master
```

**C'est tout ce que `git fetch` a fait.** Il a téléchargé des objets dans `.git/objects` et déplacé une référence de suivi distant de `973f21b` à `d0dcf58`. Il n'a pas touché `refs/heads/master`. Il n'a pas touché à l'**index**. Il n'a pas touché à un seul fichier de notre répertoire de travail. Si nous avions des modifications à moitié terminées ouvertes dans un éditeur, elles sont exactement telles qu'elles étaient.

C'est pourquoi `git fetch` est la commande la plus sûre de Git après `git status`. Elle ne peut pas perdre de travail, elle ne peut pas causer de conflit, elle ne peut pas vous surprendre. Lancez-la chaque fois que vous avez envie de savoir des choses.

Maintenant que les faits sont locaux, nous pouvons *regarder* avant de sauter :

```console
git status
```
```console
On branch master
Your branch is behind 'origin/master' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
```

```console
git log --oneline HEAD..origin/master
```
```console
d0dcf58 Describe the project in the readme
```

```console
git diff HEAD origin/master
```
```console
diff --git a/readme.md b/readme.md
index 3836229..94190ef 100644
--- a/readme.md
+++ b/readme.md
@@ -1 +1,3 @@
 # My first Git project
+
+A project about learning Git.
```

Quels commits arrivent, et ce qu'ils vont faire à mes fichiers. *Avant* qu'ils ne le fassent. `git log --stat HEAD..origin/master` si vous préférez voir la liste des fichiers plutôt que le diff.

Et alors seulement nous intégrons. Comme notre branche n'a pas de commits à elle, c'est le **fast-forward** que nous avons rencontré en partie 1 — Git déplace simplement la référence :

```console
git merge
```
```console
Updating 973f21b..d0dcf58
Fast-forward
 readme.md | 2 ++
 1 file changed, 1 insertion(+)
```

Un `git merge` nu, sans argument, fusionne l'upstream configuré, ce qui est ce que nous voulons.

### Alors qu'est-ce que `git pull` ?

`git pull`, c'est `git fetch` suivi de `git merge`. Ou `git fetch` suivi de `git rebase`, si vous l'avez configuré ainsi. Lequel des deux vous obtenez dépend d'une configuration dont vous ne vous souvenez peut-être pas.

```console
git pull
```
```console
From /Users/oripekelman/projects/my_first_git_project
   69dd359..d07371b  master     -> origin/master
Updating 69dd359..d07371b
Fast-forward
 TODO | 1 +
 1 file changed, 1 insertion(+)
```

Vous voyez la couture : les deux premières lignes sont le fetch, les trois dernières sont le merge.

Voici mon opinion, énoncée comme une opinion. **`git pull` est une commodité qui masque laquelle de deux opérations très différentes vous venez d'effectuer.** Dans le cas facile — vous n'avez pas de commits locaux, le dépôt distant a avancé — il fait un fast-forward et rien ne peut mal tourner, et taper `git pull` est très bien. Dans le cas intéressant — vous avez des commits, ils ont des commits — il effectue soit une fusion (créant un commit de fusion, gardant les deux historiques), soit un rebase (réécrivant vos commits par-dessus les leurs). Ces deux-là produisent des historiques différents, et l'un des deux réécrit des commits que vous avez déjà faits.

Vous devriez savoir lequel se produit. `fetch`, puis regarder, puis choisir, vous coûte cinq secondes et vous achète un dépôt que vous comprenez. Et un jour où quelque chose est devenu étrange, c'est la différence entre une énigme et une panique.

### Branches divergentes : l'avertissement que Git a ajouté exprès

Rendons cela intéressant. Nous committons en local ; pendant ce temps quelqu'un d'autre pousse. Les deux branches ont bougé. Maintenant :

```console
git pull
```
```console
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint:
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
```

Git refuse de deviner. Cela est arrivé dans Git 2.27 (2020) et c'est l'un des meilleurs changements que le projet ait jamais faits, parce que pendant quinze ans la valeur par défaut était une fusion silencieuse, et le résultat a été des millions de commits « Merge branch 'master' of … » accidentels dans les historiques du monde entier.

Les trois réponses :

* **`pull.ff only`** — ne jamais faire autre chose qu'un fast-forward. Si les historiques ont divergé, ne rien faire et le dire. C'est le réglage que je recommande, et voici pourquoi : il ne vous surprend jamais, et il transforme une situation ambiguë en une décision explicite.
* **`pull.rebase true`** — rejouer mes commits par-dessus les leurs. Historique linéaire, pas de commits de fusion. Très agréable, et cela réécrit vos commits locaux, ce qui est très bien tant qu'ils sont locaux.
* **`pull.rebase false`** — fusionner. La valeur par défaut historique.

Donc, une fois, sur votre machine :

```console
git config --global pull.ff only
```

Maintenant un pull divergent dit ceci à la place :

```console
git pull
```
```console
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
```

Rien n'est arrivé à votre dépôt, et Git vous a tendu les deux commandes entre lesquelles choisir. Ce qui est ce que nous voulions : une décision, pas une valeur par défaut.

Le choix lui-même, en deux phrases : la **fusion** garde un enregistrement fidèle de ce qui s'est passé, y compris le fait que deux lignes de travail ont existé en parallèle, au prix d'un historique plus grumeleux ; le **rebase** produit une ligne droite et propre, plus facile à lire et à bissecter, au prix de faire semblant que les événements se sont produits dans un ordre qui n'est pas le leur, et de réécrire des commits. La vraie discussion, y compris les cas où rebaser est activement dangereux, est dans [Mettre en œuvre un workflow collaboratif efficace](5-git-workflow.md "Mettre en œuvre un workflow collaboratif efficace").

Ici, nous prenons simplement la version linéaire, pour le plaisir de la voir marcher :

```console
git pull --rebase
```
```console
Rebasing (1/1)Successfully rebased and updated refs/heads/master.
```

### Tirer avant de pousser

Ce qui nous donne l'habitude, et c'est la règle la plus courte de ce cours :

**Faites un fetch avant de pousser. À chaque fois.**

Non pas parce que Git vous laissera casser quelque chose — il ne le fera pas, comme nous allons le voir, il refusera. Mais parce qu'un push rejeté au mauvais moment (vous êtes pressé, c'est vendredi, la mise en production attend) est la manière dont les gens en viennent à `--force`. Deux secondes de `git fetch` au départ suppriment toute la situation.

C'est aussi de la simple politesse : intégrer leur travail dans le vôtre, dans votre propre dépôt, où un conflit est votre problème à résoudre calmement, est plus agréable que de leur faire faire l'intégration autour de vous. Plus sur l'étiquette de tout ceci dans [Mettre en œuvre un workflow collaboratif efficace](5-git-workflow.md "Mettre en œuvre un workflow collaboratif efficace").

## Pousser son code

```console
git push
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
   d0dcf58..2eaa6ce  master -> master
```

Lisez la dernière ligne de droite à gauche : la branche `master` d'ici est devenue la branche `master` de là-bas, qui est passée de `d0dcf58` à `2eaa6ce`.

### Ce sont des refspecs jusqu'au bout

`git push origin master` est un raccourci. La forme complète est :

```console
git push origin refs/heads/master:refs/heads/master
```
```console
Everything up-to-date
```

Même commande. La source à gauche du deux-points, la destination à droite, exactement comme dans la ligne `fetch` de `.git/config`. « Prends mon `refs/heads/master` et rends ton `refs/heads/master` égal à lui. »

Une fois que vous voyez cela, trois choses qui ressemblent à de la syntaxe arbitraire deviennent évidentes :

* `git push origin mon_nom_local:leur_nom_different` pousse une branche sous un nom différent. Occasionnellement très utile.
* `git push origin HEAD:refs/heads/master` pousse ce que vous avez extrait vers leur `master`, que votre branche s'appelle ainsi ou non.
* Et la fameuse, sur laquelle nous reviendrons dans un instant : `git push origin :master` a une *source vide*. « Rends ton `master` égal à rien. » Autrement dit, supprime-le.

Un `git push` nu, sans arguments, utilise `push.default`, dont la valeur depuis Git 2.0 est `simple` : pousser la branche courante vers son upstream configuré, et refuser si l'upstream a un nom différent. Cette dernière clause est une sécurité — elle existe pour que vous ne puissiez pas pousser accidentellement votre `hotfix` sur leur `master` à cause d'un bout de configuration périmé. N'y touchez pas.

Si une branche n'a pas d'upstream du tout, Git s'arrête et vous dit exactement quoi taper :

```console
git push
```
```console
fatal: The current branch typo-fix has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin typo-fix

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.
```

Donc : `git push -u origin typo-fix` la première fois (`-u` étant `--set-upstream`), et un simple `git push` ensuite :

```console
git push -u origin homepage
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 * [new branch]      homepage -> homepage
branch 'homepage' set up to track 'origin/homepage'.
```

Deux choses se sont produites : une nouvelle branche est apparue là-bas, et une section `[branch "homepage"]` est apparue dans notre `.git/config`.

Et si, comme moi, vous trouvez fastidieux de taper `-u` sur chaque nouvelle branche, Git 2.37 a ajouté le conseil ci-dessus :

```console
git config --global push.autoSetupRemote true
```

Maintenant un simple `git push` sur une branche toute neuve fait la chose sensée :

```console
git push
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 * [new branch]      typo-fix -> typo-fix
branch 'typo-fix' set up to track 'origin/typo-fix'.
```

### Supprimer une branche distante

L'écriture moderne, qui se lit comme de l'anglais :

```console
git push origin --delete homepage
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 - [deleted]         homepage
```

Et l'écriture plus ancienne, que vous rencontrerez dans des scripts et sur Stack Overflow, et qui fait exactement la même chose :

```console
git push origin :homepage
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 - [deleted]         homepage
```

Rien à mémoriser. C'est un refspec avec une source vide. Pousser *rien* vers `homepage`. Une fois que vous savez lire les refspecs, la forme avec deux-points cesse d'être une incantation magique et devient la plus logique des deux.

> :information_source:
> Supprimer la branche sur le serveur ne supprime pas votre branche locale, et réciproquement. Ce sont des choses différentes — c'est toute la leçon du chapitre précédent. `git branch -d homepage` s'occupe de la locale. Supprimer la branche distante *supprime bien* votre référence de suivi `origin/homepage`, et laisse celles des autres afficher `[origin/homepage: gone]` jusqu'à ce qu'ils fassent `git fetch --prune`.

### Les étiquettes ne sont pas poussées. Vraiment.

Celle-là attrape tout le monde exactement une fois, généralement le jour d'une mise en production. Regardons-la se produire. Nous avons une étiquette annotée `v1.0` posée sur un commit, nous faisons un autre commit, et nous poussons :

```console
git push
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
   a47856e..69dd359  master -> master
```

Le push a réussi. Alors, quelles étiquettes le serveur a-t-il ?

```console
git ls-remote --tags origin
```

Pas une seule ligne de sortie. Aucune étiquette. Parce que regardez de nouveau le refspec — `refs/heads/*` — et rappelez-vous où vivent les étiquettes : `refs/tags/`. Elles n'ont jamais été dans le périmètre. Un push envoie des branches. Les étiquettes sont une course à part :

```console
git push origin v1.0
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 * [new tag]         v1.0 -> v1.0
```

```console
git push --tags
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 * [new tag]         v0.9-wip -> v0.9-wip
```

`--tags` les envoie toutes, y compris les étiquettes de brouillon privées que vous n'aviez jamais eu l'intention de publier. Mieux vaut `--follow-tags`, qui n'envoie que les étiquettes *annotées* atteignables depuis les commits que vous poussez :

```console
git push --follow-tags
```

C'est presque toujours le comportement que vous vouliez réellement, et `git config --global push.followTags true` en fait la valeur par défaut. Supprimer une étiquette sur le serveur est encore un refspec : `git push origin --delete v0.9-wip`.

Nous n'avons pas encore correctement présenté les étiquettes — cela arrive dans [Un peu de structure SVP](4-git-repo-structure.md "Un peu de structure SVP"), avec la raison pour laquelle ce sont les annotées qui comptent. Pour l'instant : retenez que `git push` ne les envoie pas.

## Quand le push est rejeté

Bien. Cassons-le.

Quelqu'un d'autre a poussé pendant que nous travaillions, et nous poussons quand même :

```console
git push
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 ! [rejected]        master -> master (fetch first)
error: failed to push some refs to '/Users/oripekelman/projects/my_first_git_project.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

Est-ce le bon moment pour paniquer ? Non. Il ne faut jamais paniquer. Rien n'a été perdu, rien n'a été changé, d'aucun côté. Git a regardé ce que nous demandions et a décliné.

Lisez la raison, parce que c'est tout ce qui compte : *le dépôt distant contient du travail que vous n'avez pas.* Si Git avait accepté notre push, `refs/heads/master` sur le serveur pointerait maintenant vers notre commit — et leur commit ne serait plus atteignable depuis aucune branche. Il serait techniquement toujours posé dans `.git/objects` là-bas, jusqu'à ce que le ramasse-miettes l'emporte. De tout point de vue pratique, nous aurions supprimé le travail d'un collègue en tapant quatre caractères.

Git impose donc une règle sur les push : **un push ne peut que faire avancer une branche.** La nouvelle valeur doit être un descendant de l'ancienne. C'est cela que « fast-forward » veut dire, et un push qui n'en est pas un se fait rejeter.

Notez l'étiquette : `(fetch first)`. Git est précis. Notre `origin/master` était périmé, donc Git ne pouvait même pas nous dire quelle était la forme du problème — va regarder, dit-il. Faisons ce qu'on nous dit :

```console
git fetch
```
```console
From /Users/oripekelman/projects/my_first_git_project
   2eaa6ce..1b47e8c  master     -> origin/master
```
```console
git status
```
```console
On branch master
Your branch and 'origin/master' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
```

Maintenant l'image est claire. Un commit chacun, partant dans des directions différentes. Et si nous poussons obstinément de nouveau, l'étiquette change :

```console
git push
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 ! [rejected]        master -> master (non-fast-forward)
error: failed to push some refs to '/Users/oripekelman/projects/my_first_git_project.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

`(non-fast-forward)` : le même refus, mais maintenant Git a des informations fraîches et peut nommer le vrai problème.

**La solution est d'intégrer, pas de forcer.** Fusionnez leur commit dans le vôtre, ou rebasez le vôtre par-dessus le leur, puis poussez. C'est la réponse normale, quotidienne et correcte, et c'est ce que dit le conseil.

### `--force` et `--force-with-lease`

Git vous laissera passer outre, de deux manières.

`git push --force` dit : rends la branche distante égale à la mienne, quoi que cela détruise. Et c'est exactement ce qu'il fait.

`git push --force-with-lease` dit quelque chose de bien plus prudent : rends la branche distante égale à la mienne, **mais seulement si le dépôt distant est toujours là où je l'ai vu pour la dernière fois**. Git compare la valeur actuelle du serveur à votre référence de suivi distant — votre « bail » — et si quelqu'un a poussé depuis votre dernier fetch, il refuse :

```console
git push --force-with-lease
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 ! [rejected]        master -> master (stale info)
error: failed to push some refs to '/Users/oripekelman/projects/my_first_git_project.git'
```

`(stale info)` — une troisième étiquette, et une bien jolie. Elle veut dire « votre information sur mon état est périmée, je ne vous laisse donc rien écraser sur cette base ». Ce qui est précisément la protection que `--force` jette par-dessus bord.

La différence en pratique : `--force` peut détruire un commit poussé il y a trente secondes par quelqu'un que vous n'avez jamais rencontré. `--force-with-lease` ne peut détruire que des commits que vous aviez déjà vus et pris en compte. **Si vous devez forcer, c'est celui-ci qu'il faut utiliser.** Certains en font un alias par-dessus `--force` pour ne pas pouvoir se tromper, et c'est une bonne idée.

> :warning:
> Forcer un push sur une branche partagée est la seule chose véritablement antisociale que l'on puisse faire avec Git. Tous ceux qui avaient les anciens commits ont maintenant un dépôt dont l'historique est en désaccord avec celui du serveur ; leur prochain pull fera quelque chose de baroque, et quelqu'un y passera un après-midi. `main`, `master`, `develop`, les branches de release, tout ce qui a plus d'un lecteur : **jamais**. Votre propre branche de fonctionnalité, que personne d'autre n'a extraite, après un rebase que vous vouliez faire : très bien, et utilisez `--force-with-lease`. Si vous avez forcé un push sur quelque chose de partagé et que vous voulez le défaire, [Garder un historique propre, se remettre de ses erreurs](6-git-cleanup.md "Garder un historique propre, se remettre de ses erreurs") est votre chapitre.

Il y a un autre rejet qu'il vaut la peine de reconnaître, et nous l'avons produit au chapitre précédent : `! [remote rejected] master -> master (branch is currently checked out)`, qui signifie que l'autre bout n'est pas un dépôt bare et que Git protège son arbre de travail.

## Quand Git ne vous laisse pas entrer : l'authentification

Dès que vous pousserez vers un vrai hébergeur plutôt que vers un répertoire, vous rencontrerez ceci. Il vaut la peine de savoir les lire d'un coup d'œil, parce qu'aucun de ces messages ne dit « votre clé est absente » en toutes lettres.

**`Permission denied (publickey)`**

```console
git@github.com: Permission denied (publickey).
```

SSH. Vous avez atteint le serveur — le DNS a fonctionné, le port était ouvert, l'hôte a répondu — et il a décliné vos clés. Soit vous n'avez pas de clé, soit la clé que vous avez n'a jamais été ajoutée à votre compte, soit votre agent SSH en propose une autre. Rien à voir avec Git ; testez-le directement :

```console
ssh -T git@github.com
```
```console
Hi OriPekelman! You've successfully authenticated, but GitHub does not provide shell access.
```

Ça, c'est un succès. « Does not provide shell access » n'est pas une erreur, c'est GitHub qui est aimable. Si à la place vous obtenez `Permission denied (publickey)`, allez à [Configurer Git avec une clé SSH](../6-appendices/2-git-ssh.md "Configurer Git avec une clé SSH") et reprenez depuis le début.

**Password authentication is not supported**

```console
remote: Invalid username or token. Password authentication is not supported for Git operations.
fatal: Authentication failed for 'https://github.com/you/your-project.git/'
```

HTTPS vers GitHub, avec quelque chose qui n'est pas un token valide. Les mots de passe de compte ont cessé de fonctionner pour Git en août 2021 — vous trouverez peut-être encore la formulation plus ancienne, « Support for password authentication was removed », citée dans des billets de blog et dans votre mémoire. Même cause, et le remède est le même : générez un jeton d'accès personnel (Settings → Developer settings → Personal access tokens) et utilisez *celui-là* là où vous tapiez un mot de passe. Ou basculez le dépôt distant en SSH.

**HTTP Basic: Access denied**

```console
remote: HTTP Basic: Access denied. If a password was provided for Git authentication, the password was incorrect or you're required to use a token instead of a password. If a token was provided, it was either incorrect, expired, or improperly scoped.
fatal: Authentication failed for 'https://gitlab.com/you/your-project.git/'
```

La version GitLab de la même conversation, et notez le mot supplémentaire utile : **scoped**, la portée. Les tokens GitLab ont des portées, et un token sans `write_repository` s'authentifiera parfaitement puis refusera de vous laisser pousser. L'expiration est l'autre cas courant ; les tokens ont des dates de fin et elles arrivent discrètement.

**`Repository not found` / `remote: Repository not found.`**

Cela ressemble à une faute de frappe, et parfois ça l'est. Mais sur GitHub, un dépôt *privé* que vous ne pouvez pas voir est signalé comme n'existant pas, délibérément, pour que personne ne puisse énumérer les dépôts privés. Ce message signifie donc « pas de dépôt de ce nom, **ou** vous n'êtes pas authentifié comme quelqu'un autorisé à le voir ». Si vous êtes certain de l'URL, traitez-le comme un problème d'authentification.

### Les credential helpers, ou : arrêtez de taper votre token

Chaque opération HTTPS a besoin du token. Vous ne voulez pas le coller quarante fois par jour, et vous ne voulez *surtout* pas le mettre dans l'URL, où il atterrit dans `.git/config` en clair et se retrouve copié dans une capture d'écran.

Un **credential helper** le stocke dans le trousseau de votre système d'exploitation et le tend à Git à la demande. Une commande, une fois :

```console
git config --global credential.helper osxkeychain
```

Ça, c'est macOS, où le helper est livré avec Git. Sous Linux, `libsecret` (vous devrez peut-être installer `git-credential-libsecret`) ; sous Windows, `manager`, que Git for Windows installe. La prochaine fois que Git demandera votre token, il le demandera une fois, puis plus jamais.

Et pour GitHub en particulier, le véritable chemin de moindre résistance :

```console
gh auth login
```

L'outil en ligne de commande `gh` vous guide à travers une connexion par navigateur, puis configure le credential helper de Git pour vous et peut téléverser une clé SSH au passage. Si vous êtes sur GitHub et que vous vous battez avec l'authentification, arrêtez de vous battre et lancez cela.

> :information_source:
> Il existe un helper appelé `store`, qui écrit votre token dans `~/.git-credentials` en clair. Il fonctionne. Ne le faites pas. Et si vous l'avez déjà fait, ce fichier mérite d'être supprimé et le token d'être renouvelé.

## Récapitulatif : `git clone`, `git fetch`, `git pull`, `git push`

* `git clone`, c'est cinq opérations : `init`, ajouter un dépôt distant appelé `origin`, récupérer les objets, créer les références de suivi distant à partir du refspec, puis créer et extraire **une seule** branche locale qui suit le **HEAD** du dépôt distant.
* `--branch <nom>` vous fait démarrer sur une autre branche ou une étiquette ; `--single-branch` rétrécit le refspec à celle-là seule ; `--recurse-submodules` amène aussi les sous-modules.
* `--depth <n>` est un clone superficiel, enregistré dans `.git/shallow`. Il casse l'archéologie de `git log`, `git blame -C`, `git describe`, `git bisect` et certaines fusions — parfait pour la CI, mauvais pour votre copie de travail. `git fetch --unshallow` le répare.
* `--filter=blob:none` est un clone partiel : tout l'historique, les contenus de fichiers récupérés à la demande (`promisor = true`). La réponse moderne à « le dépôt est trop gros ». Ajoutez `--sparse` plus `git sparse-checkout add/set/disable` pour un gros *arbre*.
* `--bare` est une copie en forme de serveur **sans refspec de fetch**, si bien que les branches atterrissent dans `refs/heads/`. `--mirror` est bare *plus* `fetch = +refs/*:refs/*` et `mirror = true` — une réplique exacte qui renvoie les suppressions. Bon pour les migrations, dangereux par conception.
* `git fetch` télécharge des objets et met à jour les références de suivi distant. **Il ne touche jamais à vos branches, à votre index ni à votre arbre de travail.**
* Regardez avant d'intégrer : `git log --oneline HEAD..origin/main`, `git log --stat`, `git diff HEAD origin/main`. `A..B` veut dire « atteignable depuis B mais pas depuis A ».
* `git pull` = `git fetch` + `git merge` (ou `+ git rebase`). Il masque laquelle de deux choses très différentes vous avez faite. Depuis Git 2.27, un pull divergent refuse de deviner — *« fatal: Need to specify how to reconcile divergent branches. »* Choisissez avec `pull.rebase false` (fusion), `pull.rebase true` (rebase), ou `pull.ff only`, que nous recommandons. Le débat fusion contre rebase lui-même est dans [Mettre en œuvre un workflow collaboratif efficace](5-git-workflow.md "Mettre en œuvre un workflow collaboratif efficace").
* `git push origin main` est un raccourci pour `git push origin refs/heads/main:refs/heads/main` — source deux-points destination, comme un refspec de fetch. C'est pourquoi `git push origin :<branche>` supprime une branche, tout comme le plus clair `git push origin --delete <branche>`.
* `git push -u origin <branche>` établit l'**upstream** la première fois ; `push.autoSetupRemote = true` le fait pour vous. `push.default = simple` (la valeur par défaut) pousse la branche courante vers son upstream et refuse si les noms diffèrent.
* **Les étiquettes ne sont pas poussées**, parce que le refspec ne couvre que `refs/heads/*`. `git push origin v1.0` pour une, `--tags` pour toutes, `--follow-tags` (ou `push.followTags = true`) pour les annotées atteignables — ce qui est ce que vous vouliez dire.
* Un push ne peut que faire **avancer** une branche : `! [rejected] … (fetch first)` tant que votre référence de suivi est périmée, `(non-fast-forward)` une fois qu'elle ne l'est plus. Les deux signifient que le dépôt distant a des commits que vous n'avez pas, et la solution est de faire un fetch et d'intégrer. `--force` écrase quoi qu'il arrive ; `--force-with-lease` n'écrase que si le dépôt distant est là où vous l'avez vu pour la dernière fois, sinon `(stale info)`. Si vous devez forcer, forcez avec un bail — et jamais sur une branche partagée.
* Faites un fetch avant de pousser. À chaque fois.
* `Permission denied (publickey)` — clé SSH ; testez avec `ssh -T git@github.com`. `Password authentication is not supported` / `HTTP Basic: Access denied` — il vous faut un token, avec la bonne portée et non expiré. `Repository not found` peut vouloir dire « non autorisé ».
* `git config --global credential.helper osxkeychain` (macOS) / `libsecret` (Linux) / `manager` (Windows) garde le token dans votre trousseau ; `gh auth login` configure GitHub pour vous. Jamais le helper `store`.
