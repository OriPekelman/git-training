---
title: Un dépôt, plusieurs arbres de travail
slug: "git-worktree"
weight: 31
---
# Un dépôt, plusieurs arbres de travail

Voici une situation que vous avez déjà vécue.

Vous êtes à trois heures de travail dans une branche de fonctionnalité. La moitié des fichiers sont modifiés, certains sont indexés et d'autres non, il y a un `TODO à moitié fait` dans un fichier que vous n'avez même pas encore nommé correctement. Rien ne compile. Et voilà que la production prend feu, et qu'il vous faut regarder `main` **tout de suite**.

Ou une version plus douce : votre suite de tests prend onze minutes, vous venez de la lancer, et vous aimeriez bien relire la pull request d'un collègue pendant qu'elle tourne — sans tuer l'exécution.

Ou encore : vous voulez faire un `git bisect` pour trouver lequel des deux cents derniers commits a cassé la page de connexion. Bissecter veut dire extraire vingt commits différents, l'un après l'autre, et votre travail en cours est très franchement dans le passage.

Jusqu'ici ce cours vous a donné deux réponses à ces trois situations, et toutes deux sont mauvaises.

## Les deux mauvaises réponses

**`git stash`.** Nous l'avons rencontré dans [Collaborer grâce à Git](../2-collaborating/1-collaborate-with-git.md "Collaborer grâce à Git"). Ça marche. C'est aussi opaque : une pile d'entrées anonymes appelées `stash@{0}`, `stash@{1}`, `stash@{2}`, qu'au bout de deux jours vous ne distinguez plus. Dépilez la mauvaise, ou dépilez-la sur la mauvaise branche, et vous avez un nœud à défaire. Et cela vous oblige à faire aller et venir un unique répertoire de travail — chaque bascule touchant des fichiers, invalidant votre cache de construction, redémarrant votre surveillant de fichiers.

**Un second `git clone`.** Cela marche aussi, et les gens le font sans arrêt. Mais vous avez désormais deux bases de données d'objets contenant les mêmes objets en double, deux jeux de dépôts distants, deux jeux de branches qui divergent, deux fichiers `.git/config`, deux jeux de hooks. Commitez quelque chose dans le clone A et le clone B ne peut pas le voir tant que vous ne l'avez pas poussé quelque part. Ce dernier point se révèle énormément important, et nous y reviendrons dans [Arbres de travail et agents](2-git-worktree-agents.md "Arbres de travail et agents").

Il existe une troisième réponse, `git worktree`. C'est la bonne, elle existe depuis Git 2.5 — sorti en **juillet 2015** — et presque personne ne l'utilise.

## Le modèle mental, d'abord

Avant de taper quoi que ce soit, mettons l'idée au clair, parce que tout le reste en découle.

Un dépôt Git, ce sont deux choses boulonnées ensemble.

1. **L'historique.** La base de données d'objets (`.git/objects` : vos **blobs**, **arbres**, **commits** et **étiquettes**) plus les références qui nomment des points d'entrée dedans (`.git/refs`, `packed-refs`). C'est la partie qui compte. C'est celle dont la perte vous ferait pleurer.
2. **Une extraction.** Un unique **commit**, déplié en de vrais fichiers que vous pouvez ouvrir dans un éditeur, plus un **index** (`.git/index`) décrivant ce qui est indexé.

La partie 1 de ce cours vous a enseigné exactement cela. Et maintenant regardez-la à nouveau : il n'y a aucune raison qu'il n'y ait qu'*un* seul (2).

Un **arbre de travail** (*worktree*) est une extraction supplémentaire — son propre répertoire de fichiers, son propre **HEAD**, son propre **index** — adossée à la *même* base de données d'objets et aux *mêmes* références.

Un historique. Plusieurs bureaux.

> :information_source:
> Vocabulaire. Le répertoire que Git a créé quand vous avez lancé `git init` ou `git clone` est l'**arbre de travail principal**. Tout ce que vous ajoutez ensuite est un **arbre de travail lié**. Git les traite presque identiquement ; nous signalerons la poignée d'endroits où « presque » compte.

## Construisons-en un

Un tout petit dépôt pour jouer, pour que la sortie ci-dessous soit reproductible — trois commits, puis la fonctionnalité à moitié finie du premier paragraphe :

```console
git init -b main shop
cd shop
printf '# Shop\n\nA tiny shop.\n' > readme.md
git add readme.md && git commit -m'Add readme'
mkdir -p lib views
printf 'function cart() { return []; }\n' > lib/cart.js
git add lib/cart.js && git commit -m'Add an empty shopping cart'
printf '<html><body>cart</body></html>\n' > views/cart.html
git add views/cart.html && git commit -m'Add the cart template'

git init --bare ../shop-origin.git          # un ersatz de forge
git remote add origin ../shop-origin.git
git push -u origin main

git switch -c cart-discounts
printf 'function discount(p) { return p * 0.9; }\n' >> lib/cart.js
printf 'TODO half done\n' > lib/coupon.js
git add lib/coupon.js
```

```console
git status --short

 M lib/cart.js
A  lib/coupon.js
```

Un arbre de travail sale, un **index** partiellement rempli. Exactement l'état dans lequel on ne veut jamais être quand la production brûle.

> :information_source:
> Dans les sorties ci-dessous, j'ai raccourci les chemins absolus en `/home/ori/code/...`. Git affiche toujours les chemins d'arbres de travail en entier, donc le vôtre dira là où vous êtes réellement. Vos **SHA** différeront des miens également : ils dépendent des horodatages de vos commits.

### `git worktree add`

```console
git worktree add ../feature-x

Preparing worktree (new branch 'feature-x')
HEAD is now at 4a188a9 Add the cart template
```

Lisez cette première ligne attentivement : **il a créé une branche**. Sans autre argument,
`git worktree add <chemin>` invente une nouvelle branche nommée d'après le dernier élément du
chemin — ici `feature-x` — à partir de votre **HEAD** courant. C'est un défaut véritablement utile,
et aussi une petite surprise la première fois.

Nous avons maintenant un second répertoire à côté de `shop`, contenant une extraction complète, et
notre travail sale sur `cart-discounts` est parfaitement intact.

Si vous voulez nommer la branche vous-même, `-b` fonctionne exactement comme pour `git switch` :

```console
git worktree add ../hotfix -b hotfix/urgent

Preparing worktree (new branch 'hotfix/urgent')
HEAD is now at 4a188a9 Add the cart template
```

Donnez-lui un **commit-ish** qui n'est pas une branche locale et vous obtenez une **tête détachée**,
ce qui est précisément ce qu'il faut pour « je veux seulement regarder » :

```console
git worktree add ../review origin/main
Preparing worktree (detached HEAD 4a188a9)
HEAD is now at 4a188a9 Add the cart template
```

```console
git worktree add --detach ../inspect 5744dc5
Preparing worktree (detached HEAD 5744dc5)
HEAD is now at 5744dc5 Add an empty shopping cart
```

`--detach` est la forme explicite : « pas de branche, merci, mets simplement le commit `5744dc5` sur
le disque ».

Un dernier défaut agréable : nommez une branche qui n'existe que sur le **dépôt distant** et Git fait
la chose évidente.

```console
git worktree add ../rel release-1.0

Preparing worktree (new branch 'release-1.0')
branch 'release-1.0' set up to track 'origin/release-1.0'.
HEAD is now at 4a188a9 Add the cart template
```

Une branche locale, qui suit `origin/release-1.0`. `--guess-remote` étend l'astuce au nom du
répertoire, de sorte que `git worktree add --guess-remote ../release-1.0` n'a besoin d'aucun argument
de branche.

### `git worktree list`

```console
git worktree list

/home/ori/code/shop       4a188a9 [cart-discounts]
/home/ori/code/feature-x  4a188a9 [feature-x]
/home/ori/code/hotfix     4a188a9 [hotfix/urgent]
/home/ori/code/inspect    5744dc5 (detached HEAD)
/home/ori/code/review     4a188a9 (detached HEAD)
```

Cinq bureaux, un historique. L'arbre de travail principal est toujours listé en premier.

Et parce que vous finirez par vouloir scripter cela, il existe une forme stable lisible par une
machine — des enregistrements séparés par des lignes vides, une `clé valeur` par ligne :

```console
git worktree list --porcelain

worktree /home/ori/code/shop
HEAD 4a188a970657161edc4170d398922dedb34d0dfe
branch refs/heads/cart-discounts

worktree /home/ori/code/inspect
HEAD 5744dc5743e6c525869fd8f2231ab7635f7fac00
detached
```

Nous analyserons ceci au chapitre suivant.

### Il n'y a qu'un seul dépôt

Voilà la partie qui rend les arbres de travail dignes d'être appris. Entrez dans n'importe lequel de
ces répertoires et `git log`, `git branch` et `git tag` vous montrent les *mêmes* choses, parce qu'il
n'y a qu'un dépôt :

```console
cd ../feature-x
git branch -vv

+ cart-discounts 4a188a9 (/home/ori/code/shop) Add the cart template
* feature-x      4a188a9 Add the cart template
+ hotfix/urgent  4a188a9 (/home/ori/code/hotfix) Add the cart template
  main           4a188a9 [origin/main] Add the cart template
```

Regardez ce `+` dans la première colonne, et le chemin entre parenthèses. Le `*` veut toujours dire
« extraite ici ». Le `+` veut dire « extraite dans un *autre* arbre de travail, là-bas ».
`git branch` a acquis cette notation pour exactement cette fonctionnalité.

Même le **stash** est partagé. Remisez dans `feature-x` :

```console
git stash push -m "from the feature-x worktree"
Saved working directory and index state On main: from the feature-x worktree
```

et listez-le depuis l'arbre de travail principal :

```console
cd ../shop
git stash list
stash@{0}: On main: from the feature-x worktree
```

Ce qui est ravissant ou horrifiant selon ce que vous attendiez. Gardez-le en tête ; nous le mettrons
sur une liste dans un instant.

## Sous le capot

Maintenant la partie amusante. Faites un `cd` dans l'arbre de travail lié et regardez son `.git` :

```console
cd ../feature-x
file .git

.git: ASCII text
```

`.git` n'est **pas un répertoire**. C'est un petit fichier texte :

```console
cat .git

gitdir: /home/ori/code/shop/.git/worktrees/feature-x
```

Voilà toute l'astuce. Une ligne, `gitdir:` suivi d'un chemin. C'est le même mécanisme de **lien
gitdir** que Git utilise pour les sous-modules, et il dit : « mon répertoire administratif est
là-bas. »

Alors allons là-bas.

```console
cd ../shop
tree -a .git/worktrees

.git/worktrees
├── feature-x
│   ├── commondir
│   ├── gitdir
│   ├── HEAD
│   ├── index
│   ├── logs
│   │   └── HEAD
│   ├── ORIG_HEAD
│   └── refs
└── hotfix
    └── ... les mêmes huit entrées
```

Un répertoire par arbre de travail lié, et dans chacun, une poignée de fichiers dont vous connaissez
déjà les noms. Lisons-les.

```console
cat .git/worktrees/feature-x/HEAD

ref: refs/heads/feature-x
```

Le voilà. Un **HEAD** par arbre de travail, exactement dans le format que nous avons disséqué dans
[Jouer avec nos révisions](../1-understanding-git/7-play-with-git-revisions.md "Jouer avec nos révisions") —
`ref: refs/heads/<branche>` quand il est attaché, un **SHA** nu quand il est détaché. Tout ce temps
passé à fixer `.git/HEAD` était pour ce moment.

```console
cat .git/worktrees/feature-x/commondir

../..
```

`commondir` est le pointeur de retour. Relativement à `.git/worktrees/feature-x`, `../..` est `.git`
— la partie partagée. C'est ainsi que Git, ayant suivi le lien `gitdir:` jusque dans un répertoire
propre à un arbre de travail, retrouve le chemin des objets et des références.

```console
cat .git/worktrees/feature-x/gitdir

/home/ori/code/feature-x/.git
```

Et `gitdir` est le lien *inverse* : le chemin du fichier `.git` qui pointe ici. Les deux fichiers
forment une paire aller-retour, et quand l'un d'eux devient périmé — parce que vous avez déplacé un
répertoire — les choses cassent d'une manière que nous corrigerons avec `git worktree repair` plus
bas.

`index` est l'**index** propre à cet arbre de travail, la zone d'indexation. `ORIG_HEAD` est son
propre « où j'étais avant le dernier grand mouvement ». Et `logs/HEAD` est un reflog exactement dans
le format que nous avons lu dans
[Collaborer grâce à Git](../2-collaborating/1-collaborate-with-git.md "Collaborer grâce à Git") — ce
qui veut dire que **chaque arbre de travail a son propre reflog de HEAD**, de sorte qu'un
`git reflog` dans `feature-x` vous dit ce qui s'est passé *dans feature-x* et rien d'autre. Les
reflogs de branches, `logs/refs/heads/*`, restent dans le `.git` partagé et sont visibles de partout.

### Le seul tableau à retenir

Chaque bogue d'arbre de travail que vous rencontrerez vient d'une erreur là-dessus, alors le voici
explicitement.

**Par arbre de travail** (chacun a le sien) :

* `HEAD`
* l'**index**
* les fichiers de l'arbre de travail eux-mêmes
* `ORIG_HEAD`
* tout l'état d'une opération en cours : `MERGE_HEAD`, `MERGE_MSG`, `AUTO_MERGE`,
  `CHERRY_PICK_HEAD`, `REVERT_HEAD`, `BISECT_LOG`, `rebase-merge/`, `rebase-apply/`
* `logs/HEAD` — le reflog de **HEAD**
* `refs/bisect/*`
* `info/sparse-checkout`
* `config.worktree`, si `extensions.worktreeConfig` est activé (voir plus bas)

**Partagé** (il y en a exactement un, pour tout le dépôt) :

* la base de données d'objets — tous les **blobs**, **arbres**, **commits**, **étiquettes**
* `refs/heads/*` — toutes les branches
* `refs/tags/*`, `refs/remotes/*`, `packed-refs`
* les reflogs de branches, `logs/refs/*`
* `.git/config`
* `hooks/`
* `info/exclude`
* **`refs/stash`** — oui, le stash est partagé
* les métadonnées `worktrees/` elles-mêmes

Vous n'avez pas à le mémoriser, parce que Git vous le dira. Il existe une commande de plomberie dont
le travail entier est de répondre à « où cela vit-il réellement ? ». Demandez-lui, depuis l'intérieur
de `feature-x` :

```console
for p in HEAD index ORIG_HEAD logs/HEAD refs/heads/main refs/stash objects config hooks; do
  printf '%-18s %s\n' "$p" "$(git rev-parse --git-path $p)"
done

HEAD               /home/ori/code/shop/.git/worktrees/feature-x/HEAD
index              /home/ori/code/shop/.git/worktrees/feature-x/index
ORIG_HEAD          /home/ori/code/shop/.git/worktrees/feature-x/ORIG_HEAD
logs/HEAD          /home/ori/code/shop/.git/worktrees/feature-x/logs/HEAD
refs/heads/main    /home/ori/code/shop/.git/refs/heads/main
refs/stash         /home/ori/code/shop/.git/refs/stash
objects            /home/ori/code/shop/.git/objects
config             /home/ori/code/shop/.git/config
hooks              /home/ori/code/shop/.git/hooks
```

Les chemins propres à l'arbre de travail atterrissent dans `worktrees/feature-x/`, les chemins
partagés dans `.git/`. `--git-path` est la bonne manière, pour tout script ou tout hook, de trouver
un fichier sous `.git`, et nous allons voir ce qui arrive aux scripts qui ne l'utilisent pas.

### Trois saveurs de « le répertoire git »

Dans l'arbre de travail principal, trois questions reçoivent deux réponses ennuyeuses —
`git rev-parse --git-dir` et `--git-common-dir` disent tous deux `.git`, et `--show-toplevel` dit
`/home/ori/code/shop`. Dans un arbre de travail lié, elles se séparent :

```console
cd ../feature-x
git rev-parse --git-dir            # /home/ori/code/shop/.git/worktrees/feature-x
git rev-parse --git-common-dir     # /home/ori/code/shop/.git
git rev-parse --show-toplevel      # /home/ori/code/feature-x
```

* `--git-dir` — *mon* répertoire administratif. Les choses propres à l'arbre de travail vivent ici.
* `--git-common-dir` — le partagé. Les objets, les références, la configuration vivent ici.
* `--show-toplevel` — la racine de *mes* fichiers.

> :warning:
> Voici le bogue d'arbre de travail le plus courant du monde réel, et il n'est pas dans Git — il est
> dans les scripts shell de tout le monde.
>
> ```console
> "$(git rev-parse --show-toplevel)/.git/hooks/pre-commit"
> ```
>
> Dans un arbre de travail lié, ce chemin est un **fichier**, pas un répertoire, donc le script
> échoue avec quelque chose comme `Not a directory`. Les outils qui écrivent dans
> `$(git rev-parse --show-toplevel)/.git/quelque-chose` sont cassés à l'intérieur des arbres de
> travail. Le remède est toujours le même : utilisez `git rev-parse --git-path <nom>` et laissez Git
> décider, ou `--git-common-dir` quand vous voulez spécifiquement le côté partagé.

### Les hooks sont partagés, et ils le savent

Mettez ceci dans `.git/hooks/pre-commit` de l'arbre de travail principal :

```console
#!/bin/sh
echo "hook: pwd        = $(pwd)"
echo "hook: git-dir    = $(git rev-parse --git-dir)"
echo "hook: common-dir = $(git rev-parse --git-common-dir)"
```

Maintenant commitez dans `feature-x`. Il n'y a pas de répertoire `hooks/` sous
`worktrees/feature-x`, et pourtant :

```console
hook: pwd        = /home/ori/code/feature-x
hook: git-dir    = /home/ori/code/shop/.git/worktrees/feature-x
hook: common-dir = /home/ori/code/shop/.git
```

Le même fichier de hook s'est exécuté, avec le répertoire courant réglé sur *cet* arbre de travail.
Ce qui est ce que vous voulez — mais cela veut dire qu'un hook qui code en dur un chemin, met en
cache quelque chose dans l'arbre de travail principal, ou se croit seul, se comportera mal dès que
vous aurez quatre arbres de travail. Les hooks qui écrivent de l'état devraient l'écrire sous
`git rev-parse --git-path`.

### Les opérations en cours sont réellement privées

Démarrons dans `feature-x` une fusion dont nous savons qu'elle entrera en conflit, et voyons ce qui
apparaît dans son répertoire administratif :

```console
cd ../feature-x
git merge hotfix/urgent
Auto-merging lib/cart.js
CONFLICT (content): Merge conflict in lib/cart.js
Automatic merge failed; fix conflicts and then commit the result.

ls -a ../shop/.git/worktrees/feature-x
AUTO_MERGE  COMMIT_EDITMSG  commondir  gitdir  HEAD
index  logs  MERGE_HEAD  MERGE_MODE  MERGE_MSG  ORIG_HEAD  refs
```

Et pendant ce temps, dans l'arbre de travail principal, `git status` dit
`On branch cart-discounts` et pas un mot d'une fusion. `feature-x` est coincé en plein conflit et
`shop` ne le sait pas et s'en moque. Il en va de même pour un rebase, un cherry-pick, un revert et
une bissection — chaque arbre de travail peut être au milieu de sa propre opération. Même les
références de bissection sont privées :

```console
git worktree add --detach ../bisect main
cd ../bisect
git bisect start && git bisect bad main && git bisect good f4eae73
git for-each-ref 'refs/bisect/*'

4a188a9... commit	refs/bisect/bad
f4eae73... commit	refs/bisect/good-f4eae73ba6a117b58ad81c2a49a01bce351ea215
```

Depuis l'arbre de travail principal, le même `git for-each-ref` n'affiche rien. Un arbre de travail
dédié à la bissection est l'un des plus jolis usages de toute la fonctionnalité : vous pouvez
bissecter une demi-heure sans jamais déranger votre vrai travail.

### La configuration par arbre de travail

La configuration est partagée. En général c'est ce qu'il faut — vous voulez un seul jeu de dépôts
distants. À l'occasion, non : un `user.email` différent pour le dépôt d'un client, un
sparse-checkout différent, un `core.editor` différent.

Il existe une option d'adhésion pour cela. Essayez à froid et Git refuse, puis cède :

```console
git config --worktree user.email bot@example.com
fatal: --worktree cannot be used with multiple working trees unless the config
extension worktreeConfig is enabled. Please read "CONFIGURATION FILE"
section in "git help worktree" for details

git config extensions.worktreeConfig true
git config --worktree user.email bot@example.com
```

Désormais chaque arbre de travail peut surcharger. Réglez `agent-a@example.com` dans `feature-x` et
vous obtenez trois réponses différentes à `git config --get user.email` : `agent-a@example.com`
là-bas, `bot@example.com` dans l'arbre de travail principal, et — depuis `hotfix`, qui n'a rien
réglé — la valeur de votre configuration globale. `git config --list --show-origin` vous dit quel
fichier l'a emporté :

```console
file:/home/ori/.gitconfig	user.email=ori+git-training@pekelman.com
file:/home/ori/code/shop/.git/worktrees/feature-x/config.worktree	user.email=agent-a@example.com
```

Les surcharges de l'arbre de travail principal vivent dans `.git/config.worktree` ; celles d'un arbre
de travail lié dans `.git/worktrees/<nom>/config.worktree`.

> :information_source:
> Vous pourriez trouver `extensions.worktreeConfig` déjà activé sans l'avoir fait vous-même. Un
> `git sparse-checkout` dans un arbre de travail lié l'active pour vous, parce que les réglages de
> sparse-checkout sont intrinsèquement propres à chaque arbre de travail. Si vous voyez un
> `config.worktree` que vous n'avez pas créé, c'est en général pour cela.

## L'entretien

### `git worktree remove`

`git worktree remove ../review` est la manière polie. Le silence vaut succès : le répertoire a
disparu et les fichiers administratifs avec lui. Notez que la *branche* survit — retirer un arbre de
travail n'est pas supprimer du travail.

Il vous protégera de vous-même, et ne vous laissera pas tirer sur celui où vous êtes assis :

```console
git worktree remove ../inspect
fatal: '../inspect' contains modified or untracked files, use --force to delete it

git worktree remove .
fatal: '.' is a main working tree
```

`--force` fait le premier quand même, et vous perdez ces fichiers pour de bon.

### `git worktree prune`

Maintenant la chose que vous ferez réellement, parce que vous êtes un être humain normal :
supprimer le répertoire avec `rm -rf` et oublier.

```console
rm -rf ../feature-x
git worktree list

/home/ori/code/shop       4a188a9 [cart-discounts]
/home/ori/code/feature-x  4a188a9 [feature-x] prunable
/home/ori/code/hotfix     4a188a9 [hotfix/urgent]
```

Git l'a remarqué, et dit `prunable`. `--porcelain` ajoute une ligne qui vous dit pourquoi :
`prunable gitdir file points to non-existent location`. Le répertoire administratif est toujours
posé sous `.git/worktrees`. Balayez-le :

```console
git worktree prune -v

Removing worktrees/feature-x: gitdir file points to non-existent location
```

`-n` est un essai à blanc, `-v` est bavard. `--expire <durée>` n'élague que les entrées plus vieilles
qu'un âge donné, ce qui est pratique dans une tâche cron.

Les entrées d'arbres de travail périmées sont pour l'essentiel inoffensives, avec une conséquence
réelle : tant que l'entrée existe, son `HEAD` et son reflog gardent des objets atteignables, donc
`git gc` ne peut pas les collecter. Un dépôt plein d'arbres de travail oubliés ne rétrécit jamais.
Nous y reviendrons au chapitre suivant, où les arbres de travail oubliés sont la norme.

### `git worktree lock` et `unlock`

Certains arbres de travail vivent sur un support amovible ou un montage réseau. Quand le montage est
absent, Git voit un répertoire manquant et propose gaiement d'élaguer les métadonnées. `lock` dit
non — et stocke votre raison, qu'il vous relit quand vous essayez quand même :

```console
git worktree lock --reason "on a USB drive that is not always plugged in" ../hotfix
git worktree remove ../hotfix

fatal: cannot remove a locked working tree, lock reason: on a USB drive that is not always plugged in
use 'remove -f -f' to override or unlock first
```

`git worktree list` affiche un tel arbre de travail comme `locked`, et
`git worktree unlock ../hotfix` le libère.

### `git worktree move`

```console
git worktree move ../feature-x ../feat-x
```

Il déplace les fichiers *et* corrige les deux moitiés de la paire de liens `gitdir:`, ce qui est
exactement ce que `mv` ne fait pas.

### `git worktree repair`

Et maintenant la commande dont vous aurez besoin un mardi après-midi, parce que vous avez déplacé un
répertoire dans le Finder ou avec `mv` comme une personne normale.

Déplacez un arbre de travail lié à la main et les dégâts sont subtils. De l'intérieur, tout
fonctionne encore — son fichier `.git` pointe vers un répertoire administratif valide. Mais le
fichier `gitdir` dans l'*autre* sens est maintenant faux, si bien que le dépôt principal a
discrètement rayé l'arbre de travail de ses tablettes :

```console
mv ../feat-x ../moved-by-hand
git worktree list

/home/ori/code/shop    4a188a9 [cart-discounts]
/home/ori/code/feat-x  4a188a9 [feature-x] prunable
```

`prunable` — c'est-à-dire que le prochain `git worktree prune` jettera les métadonnées d'un arbre de
travail qui existe encore. Lancez `repair` depuis l'intérieur du répertoire déplacé :

```console
cd ../moved-by-hand
git worktree repair

repair: gitdir incorrect: /home/ori/code/shop/.git/worktrees/feature-x/gitdir
```

L'autre sens est plus bruyant. Déplacez le dépôt *principal* et le fichier `.git` de chaque arbre de
travail lié pointe désormais dans le vide :

```console
mv shop shop-renamed
cd moved-by-hand
git status

fatal: not a git repository: /home/ori/code/shop/.git/worktrees/feature-x
```

Rien n'est perdu — c'est un fichier texte par arbre de travail qui est faux. Lancez `repair` depuis
le dépôt principal, en nommant les arbres de travail :

```console
cd ../shop-renamed
git worktree repair ../moved-by-hand ../hotfix

repair: .git file broken: /home/ori/code/hotfix
repair: .git file broken: /home/ori/code/moved-by-hand
```

> :information_source:
> Règle empirique : après avoir déplacé des *arbres de travail*, lancez `git worktree repair` depuis
> n'importe où dans le dépôt. Après avoir déplacé le *dépôt principal*, lancez
> `git worktree repair <chemin>...` depuis le dépôt principal, en listant les arbres de travail. Ou,
> bien sûr, utilisez `git worktree move` et n'y pensez jamais.

## Les règles, et les pièges

### Vous ne pouvez pas extraire deux fois la même branche

```console
cd ../hotfix
git switch feature-x
fatal: 'feature-x' is already used by worktree at '/home/ori/code/feature-x'

git worktree add ../another feature-x
Preparing worktree (checking out 'feature-x')
fatal: 'feature-x' is already used by worktree at '/home/ori/code/feature-x'
```

Ce n'est pas Git qui fait des chichis. Pensez à ce qu'*est* une branche : une référence qui se
déplace vers votre dernier **commit**. Deux arbres de travail sur une branche, cela veut dire deux
arbres de travail et deux index avec une seule réponse partagée à « qu'est-ce qui est commité ici ? ».
Commitez dans l'un, et l'autre découvre silencieusement que son **HEAD** a bougé sous ses pieds et
que tout son arbre de travail se lit désormais comme un gigantesque diff non commité. Git refuse
parce que la situation n'a aucun sens raisonnable.

Il existe une issue de secours :

```console
git worktree add --force ../another feature-x

Preparing worktree (checking out 'feature-x')
HEAD is now at 4a188a9 Add the cart template
```

Vous n'en voulez presque jamais. Si ce que vous voulez réellement est « le même code à deux
endroits », détachez : `git worktree add --detach ../another feature-x` vous donne le même **commit**
sans référence à se disputer. C'est sûr, et c'est la bonne réponse à « faire tourner les tests contre
exactement cet état ».

### La suppression de branche est bloquée aussi

```console
git branch -d feature-x

error: cannot delete branch 'feature-x' used by worktree at '/home/ori/code/feature-x'
```

Le `-D` n'aide pas — il ne s'agit pas de travail non fusionné, mais du fait que la branche est en
usage. Retirez d'abord l'arbre de travail, puis supprimez la branche. Dans cet ordre, toujours. Cela
mord les gens qui écrivent des scripts de nettoyage, et c'est pourquoi le script de nettoyage du
chapitre suivant procède dans cet ordre.

### Deux plus petits, à propos des chemins

Un répertoire existant non vide est refusé (un répertoire vide convient, Git l'utilisera) :

```console
git worktree add ../occupied -b occupied

Preparing worktree (new branch 'occupied')
fatal: '../occupied' already exists
```

Et les chemins relatifs sont résolus par rapport à *votre shell*, pas à la racine du dépôt. Depuis
`lib/deep`, `git worktree add ../../../rel-test` atterrit trois niveaux au-dessus de `lib/deep`.
Évident une fois dit, et une source fiable d'arbres de travail apparaissant à des endroits
surprenants. Dans des scripts, calculez un chemin absolu.

### Les fichiers non suivis ne sont pas là

Voici le gros morceau. La plus grande source de friction avec les arbres de travail, et la raison
pour laquelle les gens les essaient une fois et retournent à `git stash`.

Un nouvel arbre de travail contient **exactement ce qui est commité**. Rien d'autre. Il n'a donc
pas :

* `.env`, `.env.local`, et tout autre fichier porteur de secrets que vous aviez correctement mis
  dans le `.gitignore`
* `node_modules/`, `vendor/`, `venv/`, `.venv/`
* `target/`, `build/`, `dist/`, `.next/`, `__pycache__/`
* votre fichier SQLite local, vos fixtures de test téléversées, votre `docker-compose.override.yml`
* tous les caches de construction qui rendent la deuxième compilation de votre projet rapide

Alors vous faites un `cd` dans votre tout nouvel arbre de travail rutilant, vous lancez les tests, et
tout explose. Ce n'est pas un bogue, c'est la définition d'une extraction propre, et c'est la même
chose qui arriverait à un `git clone` tout neuf.

Trois façons de gérer cela, par ordre croissant de vertu.

**Faire des liens symboliques vers les parties partagées.** Pour les fichiers qui devraient
véritablement être identiques partout :

```console
ln -s ../shop/.env .env
```

Peu coûteux, instantané, et cela veut dire n'éditer le secret qu'une fois. Fonctionne mal pour des
répertoires dans lesquels l'outillage veut écrire.

**Partager les caches, reconstruire le reste.** La plupart des chaînes d'outils de langage vous
laissent déplacer la partie coûteuse hors de l'arbre de travail, ce qui transforme « tout
reconstruire » en « tout lier » :

* Rust : `export CARGO_TARGET_DIR=$HOME/.cache/cargo-target` — un seul répertoire de construction
  partagé pour tous les arbres de travail. Celui-ci est transformateur ; sans lui, chaque arbre de
  travail paie une construction à froid complète.
* Node : `pnpm` tient déjà un magasin global adressé par contenu, donc `pnpm install` dans un nouvel
  arbre de travail se réduit surtout à des liens physiques. Avec npm, faites `npm ci` par arbre de
  travail et laissez le cache HTTP travailler.
* Python : `uv sync` par arbre de travail avec un `UV_CACHE_DIR` partagé. Ne faites *pas* de lien
  symbolique d'un environnement virtuel entre arbres de travail — les chemins cuits dans ses scripts
  vous mentiront.
* C/C++ : `ccache`, qui est conçu exactement pour cela.
* Docker Compose : réglez `COMPOSE_PROJECT_NAME` par arbre de travail, sinon le second adoptera les
  conteneurs du premier.

**Écrire un script d'amorçage.** Mettez un `setup-worktree.sh` dans le dépôt, qui lie ce qui doit
être lié et installe ce qui doit être installé, et lancez-le comme deuxième commande après
`git worktree add`. `direnv` est un bon compagnon ici : un `.envrc` par arbre de travail, chargé
automatiquement quand vous y entrez, exportant un nom de base de données et un port propres à cet
arbre.

> :information_source:
> Voici le bénéfice caché, et je le dis sérieusement. Un projet où créer un arbre de travail est peu
> coûteux est un projet où intégrer un nouveau développeur est peu coûteux, parce que c'est le même
> problème : « à partir des seules sources commitées, atteindre un état qui fonctionne ». Si vos
> arbres de travail sont pénibles, votre `README` ment à quelqu'un. Corriger l'un corrige l'autre.

### Les gros dépôts : `--no-checkout` et le sparse-checkout

Si votre dépôt est énorme, N extractions complètes ne sont pas gratuites. `--no-checkout` crée
l'arbre de travail avec les fichiers administratifs mais laisse les fichiers de côté :

```console
git worktree add --no-checkout ../empty -b sparse-experiment
ls -a ../empty

.  ..  .git
```

L'index dit que les fichiers devraient être là, donc `git status` les signale tous comme supprimés.
Maintenant, restreignez l'extraction à la partie qui vous intéresse et ne peuplez que celle-là :

```console
cd ../empty
git sparse-checkout init --cone
git sparse-checkout set lib
git checkout
ls

lib  readme.md
```

Seuls `lib` et les fichiers racine sont sortis. Parce que `info/sparse-checkout` est propre à chaque
arbre de travail, chacun peut contenir une tranche différente d'un monorepo — ce qui est une chose
assez ravissante à pouvoir faire.

### L'outillage coûte de l'argent

L'arithmétique du disque est aimable. L'historique est partagé, donc N arbres de travail coûtent à
peu près **N × arbre de travail**, pas N × dépôt :

```console
du -sh .git ../feature-x

324K	/home/ori/code/shop/.git
 16K	/home/ori/code/feature-x
```

L'arithmétique de la mémoire vive n'est pas aimable. Votre éditeur démarrera joyeusement un serveur
de langage par arbre de travail, et un `rust-analyzer` ou un serveur TypeScript n'est pas un petit
processus. Les surveillants de fichiers passent à l'échelle de la même façon. Et certains outils
mettent en cache par chemin absolu, de sorte qu'ouvrir le même fichier à deux chemins vous donne
deux entrées dans l'index et, à l'occasion, deux avis contradictoires à son sujet.

Rien de tout cela n'est une raison de ne pas utiliser les arbres de travail. C'est une raison de
fermer ceux dont vous avez fini.

## La disposition en dépôt nu

`git worktree add` fonctionne aussi dans un dépôt **nu**, et c'est devenu un petit mouvement. Au lieu
d'une extraction avec des arbres de travail accrochés dessus, vous ne gardez au centre que
l'historique et *toute* branche est un arbre de travail :

```console
git clone --bare git@example.com:you/shop.git shop.git
cd shop.git
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git fetch origin
git worktree add ../main main
git worktree add ../feature-y -b feature-y main
```

Vous vous retrouvez avec `shop.git` qui tient l'historique et un répertoire frère par branche :

```console
git worktree list

/home/ori/bare/shop.git   (bare)
/home/ori/bare/feature-y  4a188a9 [feature-y]
/home/ori/bare/main       4a188a9 [main]
```

Pourquoi les gens aiment cela : il n'y a pas d'extraction « vraie » privilégiée, donc pas de
tentation d'y travailler et pas d'asymétrie à retenir. `main` est un arbre de travail comme un autre,
et vous le supprimez aussi négligemment que le reste. Le dépôt nu est de l'historique pur — ce qui,
comme nous l'avons établi en tête de ce chapitre, est la seule partie qui compte.

> :warning:
> `git clone --bare` ne met *pas* en place de refspec de récupération, donc un clone nu n'a aucune
> branche de suivi. C'est pourquoi la ligne `git config remote.origin.fetch` ci-dessus n'est pas
> optionnelle. Les refspecs ont été couvertes dans les chapitres sur les dépôts distants ; c'est le
> seul endroit où il faut s'en souvenir à la main.

## Alors, quand un arbre de travail est-il le bon outil ?

**Contre `git stash`** — Les arbres de travail gagnent dès que l'interruption dure plus d'une minute
ou deux. Rien à retenir, rien à dépiler, et votre bureau d'origine est exactement tel que vous
l'aviez laissé, cache de construction compris. Le stash reste très bien pour « tiens-moi ça trente
secondes ».

**Contre un second clone** — Les arbres de travail gagnent presque toujours. Un magasin d'objets, un
jeu de dépôts distants, une configuration, un jeu de hooks. Et l'argument décisif : les commits faits
dans n'importe quel arbre de travail sont *immédiatement* visibles depuis tous les autres, sans push
ni fetch, parce qu'il n'y a qu'un répertoire de références. `git diff feature-x hotfix/urgent`
fonctionne, tout simplement. Des clones séparés ne peuvent pas faire cela du tout.

**Contre `git switch`** — Basculer est le bon geste quand vous *passez à autre chose*. Un arbre de
travail est le bon geste quand vous voulez les deux choses *en même temps* : deux branches ouvertes,
deux serveurs qui tournent, des tests sur l'une pendant que vous éditez l'autre.

**Et la note honnête.** Pour jeter un rapide coup d'œil à un fichier, tout ce qui précède est
disproportionné :

```console
git show main:readme.md
```

affiche ce fichier à ce **commit** sans rien toucher.
`git restore --source=main -- chemin/du/fichier` fait traverser un seul fichier sans changer de
branche. Si votre question est petite, posez-la avec une petite commande.

## Recettes

### Ajouter et entrer dedans d'un seul geste

`git worktree add` ne peut pas changer le répertoire de votre shell — aucun programme ne le peut. Une
fonction shell, si :

```console
wt() {
  local common root name start dir
  common=$(git rev-parse --path-format=absolute --git-common-dir) || return 1
  root=${common%/.git}                     # dépôt normal : retirer le /.git final
  name=${1//\//-}                          # feature/foo -> feature-foo
  start=${2:-$(git rev-parse HEAD)}        # résoudre HEAD *ici*, avant le -C
  dir="${root%/*}/${root##*/}-$name"       # un frère de l'arbre de travail principal
  if git show-ref --verify --quiet "refs/heads/$1"; then
    git -C "$root" worktree add "$dir" "$1" || return 1
  else
    git -C "$root" worktree add "$dir" -b "$1" "$start" || return 1
  fi
  cd "$dir" || return 1
}
```

`wt bug/parser` depuis n'importe où dans le dépôt crée `../shop-bug-parser` sur une nouvelle branche
`bug/parser` et vous y dépose. Fonctionne en bash et en zsh. Notez le
`start=${2:-$(git rev-parse HEAD)}` — la résolution de **HEAD** *avant* de passer la main à
`git -C`, parce que `git -C "$root"` résoudrait `HEAD` dans l'arbre de travail principal, pas là où
vous vous tenez.

### Tester `main` pendant que vous travaillez

```console
git worktree add --detach ../ci main
cd ../ci && ./run-tests.sh
```

`--detach`, pour qu'il ne réclame pas la branche `main` et que vous puissiez encore y fusionner
depuis votre arbre de travail principal.

### Relire une pull request

Configurez la refspec une fois — la plupart des forges publient les têtes de PR sous
`refs/pull/*` :

```console
git config --add remote.origin.fetch '+refs/pull/*/head:refs/remotes/origin/pull/*'
git fetch origin

From ../shop-origin
 * [new ref]         refs/pull/7/head -> origin/pull/7
```

Puis un arbre de travail jetable par relecture :

```console
git worktree add ../pr-7 origin/pull/7

Preparing worktree (detached HEAD 4a188a9)
```

Lisez-le, exécutez-le, `git worktree remove ../pr-7`. Si vous utilisez le CLI d'une forge (`gh`,
`glab`, `tea`), lancez sa commande d'extraction *dans* un arbre de travail neuf plutôt que dans votre
répertoire de travail, et la même propriété tient : votre propre travail n'est jamais dérangé.

### Une branche de documentation extraite en permanence

Si vous publiez depuis une branche façon `gh-pages`, cessez d'y basculer :

```console
git worktree add ../shop-pages gh-pages
```

Construisez dans `../shop-pages`, commitez là-bas, poussez. La branche est toujours prête et votre
extraction de sources ne voit jamais ses fichiers. Même astuce pour un arbre de travail de
bissection, rencontré plus haut : `git worktree add --detach ../bisect main` et vingt extractions,
dont aucune n'est la vôtre.

## Récapitulatif `git worktree`

* Un dépôt est un **historique** partagé (objets + références) plus une extraction. Les arbres de
  travail vous donnent plusieurs extractions sur un seul historique.
* `git worktree add <chemin>` crée un arbre de travail lié, et une branche nommée d'après le
  répertoire. `-b <nom>` la nomme vous-même ; un **commit-ish** ou `--detach` vous donne une **tête
  détachée** ; `--no-checkout` vous donne les métadonnées sans les fichiers.
* `git worktree list` les montre tous ; `--porcelain` en est la forme scriptable et signale les
  entrées `prunable`.
* `git worktree remove` en supprime un (refuse quand il est sale, `--force` insiste) ;
  `git worktree prune` nettoie après un `rm -rf` ; `lock`/`unlock` protègent les arbres de travail
  sur support amovible ; `move` en déplace un sans risque ; `repair` corrige les liens `gitdir:`
  après un déplacement à la main.
* Dans un arbre de travail lié, `.git` est un **fichier** contenant `gitdir: <chemin>`, qui pointe
  vers `.git/worktrees/<nom>/`, lequel contient les `HEAD`, `index`, `ORIG_HEAD`, `logs/HEAD` propres
  à cet arbre, l'état de l'opération en cours, et un `commondir` qui pointe en retour vers le `.git`
  partagé.
* Par arbre de travail : **HEAD**, l'**index**, les fichiers, `ORIG_HEAD`, l'état de
  fusion/rebase/cherry-pick/bissection, le reflog de **HEAD**, `refs/bisect/*`, le sparse-checkout,
  `config.worktree`. Partagés : les objets, toutes les références y compris les branches, les
  étiquettes, les références de suivi et le **stash**, la configuration, les hooks, `info/exclude`.
* `git rev-parse --git-dir` est le répertoire administratif de *cet* arbre de travail ;
  `--git-common-dir` est le partagé ; `--show-toplevel` est la racine de *cet* arbre. `git rev-parse
  --git-path <nom>` résout correctement n'importe quel fichier. Les scripts qui supposent que
  `$(git rev-parse --show-toplevel)/.git` est un répertoire cassent dans les arbres de travail.
* `extensions.worktreeConfig` plus `git config --worktree` donne une configuration par arbre de
  travail dans `config.worktree`.
* Une branche ne peut pas être extraite dans deux arbres de travail, et une branche en usage ne peut
  pas être supprimée. Retirez d'abord l'arbre de travail, puis la branche.
* Les nouveaux arbres de travail n'ont aucun fichier non suivi — pas de `.env`, pas de
  `node_modules`, pas de cache de construction. Les liens symboliques, les caches partagés
  (`CARGO_TARGET_DIR`, `UV_CACHE_DIR`, `ccache`), `direnv` et un `setup-worktree.sh` sont le remède.
* Le coût en disque est à peu près N × arbre de travail, pas N × dépôt. Le coût en mémoire vive est
  de N serveurs de langage, ce qui est la vraie limite.

Tout ce qui est dans ce chapitre est disponible depuis 2015 et est, aux normes de Git, parfaitement
ennuyeux. Ce qui n'est pas ennuyeux, c'est ce qui se passe quand la chose assise à chacun de ces
bureaux n'est pas vous.

Ce qui est
[Arbres de travail et agents, du travail parallèle à la vitesse de la machine](2-git-worktree-agents.md "Arbres de travail et agents, du travail parallèle à la vitesse de la machine").
