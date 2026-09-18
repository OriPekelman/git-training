---
title: Collaborer grâce à Git
slug: "collaborate-with-git"
weight: 11
---
# Collaborer grâce à Git

Nous avons appris à sauvegarder notre travail en créant un dépôt Git. Puis comment suivre les changements de fichiers et de répertoires. Nous savons même repasser dans l'histoire, voir ce qui a changé.

Nous avons travaillé sur une seule branche de notre code (celle créée par défaut, **master**), et d'ailleurs elle est rapidement devenue un peu le bazar, mais nous avons aussi appris à revenir dans le passé pour faire du propre.

Mais quand nous allons travailler avec d'autres, ou même tout seuls, ceci n'est pas la bonne méthode. Assez souvent, le travail de l'informaticien est exploratoire. On se lance sur une piste. On essaie un truc ; ça ne marche pas. On débogue. Ou on découvre qu'on peut faire mieux, plus propre. Et nous ne voulons pas passer notre vie à réécrire l'historique du dépôt, ni laisser à tout jamais chaque petit bout d'exploration.

La vie est belle. Git est vraiment fait pour ça. Comme je vous l'ai raconté au tout début, Git nous permet de travailler en même temps sur plusieurs versions de son code. La bonne pratique est de ne jamais travailler directement sur **master**. Et évidemment de ne jamais réécrire le passé de **master** (ou de toute autre branche qu'on aura partagée avec d'autres).

## Collaborer avec soi-même. Les branches et leurs structures.

Chaque fois que nous allons commencer à travailler sur une nouvelle fonctionnalité ou sur la correction d'un bogue, nous avons tout intérêt à créer une nouvelle branche. Ce sera notre espace de travail exploratoire, où nous apporterons nos changements successifs. Quand nous serons contents de nos changements, nous pourrons tout simplement les réintégrer dans le « tronc principal ».

Comment créer une branche ?

### Créer des branches

La commande `git checkout` que nous avons déjà vue nous permet non seulement de se mettre sur un autre commit… mais aussi de créer une nouvelle branche.

```console
git checkout -b my_new_feature
```

Ceci crée une nouvelle branche à partir du commit sur lequel pointe notre **HEAD**, et bascule dessus. Git nous le dit :

```console
Switched to a new branch 'my_new_feature'
```

> :information_source:
> Depuis Git 2.23, il existe une seconde manière, plus claire, de dire la même chose : `git switch -c my_new_feature`. Comme nous l'avons mentionné au chapitre précédent, `git checkout` a été scindé en `git switch` (se déplacer entre les branches) et `git restore` (remettre des fichiers en place), précisément parce que faire les deux métiers avec une seule commande était une source d'accidents bien connue. Nous continuons à utiliser `checkout` dans ce cours parce que c'est ce que vous verrez dans tous les tutoriels existants, toutes les réponses Stack Overflow et le terminal de tous vos collègues — mais `switch` est la meilleure habitude.

Mais nous aimons comprendre ce qui se passe sous le capot… n'est-ce pas ? Jetons un coup d'œil à notre répertoire `.git`.

```
.
...
├── HEAD
...
├── logs
│   ├── HEAD
│   └── refs
│       └── heads
│           ├── master
│           └── my_new_feature
...
└── refs
    ├── heads
    │   ├── master
    │   └── my_new_feature
    └── tags
```

Notre HEAD a changé. Si nous regardons à l'intérieur avec un `cat .git/HEAD`, il dit : `ref: refs/heads/my_new_feature` ; avant il disait `ref: refs/heads/master`… et ça, c'est un raccourci, un lien, un pointeur vers un autre petit fichier qui vient d'apparaître.

Sous `.git/refs/heads` apparaît `my_new_feature`. Un coup d'œil à l'intérieur : `cat refs/heads/my_new_feature` nous dit `120539df2817da4656c85af54061b06e15ae4b38`. Donc « HEAD » nous permet de connaître le « commit actuel ». Quand il contient une référence comme `refs/heads/my_new_feature`, cela veut dire qu'on est sur le sommet d'une branche (« branch tip » en anglais) appelée `my_new_feature`.

Quand notre **HEAD** contient un **hash**, alors on est dans cette situation de « detached head » que nous avons déjà vue ; quand il contient la référence d'une branche… il va bouger avec le sommet de cette branche. Ainsi, si on ajoute maintenant un **commit** sur la branche `my_new_feature`, notre **HEAD** restera synchronisé avec elle et il pointera vers notre nouveau **commit**.

> :warning: nous avons le droit de mettre pas mal de choses dans les noms de branches. Mais je vous suggère très fortement de vous limiter à l'alphanumérique, avec des caractères toujours en minuscules, et `-`, `_`, `/` et `.` comme caractères supplémentaires tout au plus. Nous avons déjà noté que l'un des intérêts de Git est qu'on peut l'intégrer dans pas mal d'automatismes. Plus vous serez baroque dans vos choix de noms, plus vous aurez de chances d'avoir quelque chose qui casse. Vous pouvez utiliser de l'unicode. Vous pouvez utiliser des emojis. Mais c'est une mauvaise idée.

## Sauter de branche en branche : `git checkout {branch_name}`

Rien de plus simple : `git checkout master` va nous permettre de revenir à notre branche principale. Puis `git checkout my_new_feature`, et hop, on est revenus sur notre nouvelle branche.

## Mais si j'ai fait des changements, puis que je change de branche, qu'est-ce qui se passe ?

Vous ne pouvez être que dans l'un de deux états. Soit on a déjà fait des **commits**, soit non.

### On a fait un commit avant de changer de branche

Si on a fait un changement et qu'on l'a appliqué en faisant un **commit** avant de changer de branche : on arrive sur la nouvelle branche et notre zone de travail est mise à jour (on ne verra donc pas ce changement).

### On n'a pas fait de commit avant de changer de branche

Si on a fait un changement mais qu'on ne l'a pas appliqué avec un commit :

1. Soit aucun autre changement n'a été fait sur les mêmes fichiers… et alors Git va mettre à jour la zone de travail pour ce qui n'a pas changé. Nos modifications vont encore être là.
2. Soit sur les deux branches il y a eu des changements sur les mêmes fichiers (donc on a fait un **commit** dans l'autre branche sur l'un des fichiers) que l'on a touchés, et Git va se plaindre. Il va nous dire : « Hé ! Si vous voulez changer de branche, il faut d'abord faire soit un `git commit`, soit un `git stash` ».

> :information_source:
> Nous n'allons pas tout voir tout de suite ; mais sachez que `git stash` est une commande fort utile. Parfois nous sommes au milieu du travail, on n'a rien encore committé. Et nous voulons aller voir ce qui se passe sur une autre branche. `git stash` nous permet de sauvegarder l'état actuel de notre zone de travail et de remettre celle-ci au propre. C'est un peu comme le `git reset` que nous avons déjà vu… sauf que cette commande ne détruit rien. Elle place nos changements dans une zone tampon (un peu comme le « presse-papier »). Nous pouvons maintenant aller voir ailleurs, même faire des commits sur d'autres branches… puis revenir à la nôtre, faire un petit `git stash pop`, et notre zone de travail aura de nouveau les changements qui étaient en cours. On peut l'imaginer comme un « commit temporaire ».


## Comment suivre nos changements de branches ? `git reflog`

Le **reflog** est un mécanisme qui enregistre les moments où la pointe des branches est mise à jour. Et la commande `reflog` permet de gérer les informations qui y sont enregistrées. En gros, chaque fois que notre **HEAD** change, chaque fois qu'on ajoute un **commit** à une branche et que cette branche pointe donc vers un nouveau commit, Git enregistre ces changements.

> :warning: vous allez vous emmêler les pinceaux plus d'une fois pendant votre apprentissage de Git… surtout quand vous allez commencer à utiliser des commandes plus poussées. Chaque fois que vous êtes perdu… souvenez-vous : un `git reflog` pourra souvent vous expliquer ce qui s'est passé.

Dans notre cas, `git reflog` va nous donner l'historique complet de tout ce que l'on a fait jusqu'à maintenant :

```console
4d48f63 HEAD@{0}: commit: Add media directory with .gitkeep
a07690f HEAD@{1}: commit: Add git log to the list of commands we learned
72c4234 HEAD@{2}: reset: moving to 72c4234bd6c3c16c3b567b851e2c58cedbb019be
4b8243a HEAD@{3}: checkout: moving from 49c6166b1deb64004016a2ffe1c1b75eeadc4a4c to master
49c6166 HEAD@{4}: checkout: moving from master to 49c6166b1deb64004016a2ffe1c1b75eeadc4a4c
4b8243a HEAD@{5}: commit: added git log command
49c6166 HEAD@{6}: commit: Rename files to media
17baa68 HEAD@{7}: commit: Remove license file
1368877 HEAD@{8}: commit: Add .gitkeep so files will be added to the repository
cabdb6f HEAD@{9}: commit: Adding a license file
72c4234 HEAD@{10}: commit: Add the list of commands we learned today.
0ab682b HEAD@{11}: commit (initial): Added readme.md
```

Lisez-le de bas en haut et vous avez un journal honnête de tout le chapitre précédent, y compris les parties que nous avions rangées : les sept commits, l'excursion en **detached head** à `HEAD@{4}` et le chemin du retour à `HEAD@{3}`, le `reset` à `HEAD@{2}` qui a jeté cinq de ces commits hors de la branche, et les deux commits de remplacement que nous avons faits ensuite.

Regardez bien `HEAD@{5}` : `4b8243a`, « added git log command ». Ce commit n'est plus sur aucune branche — nous avons fait un reset au-delà de lui. Il n'est pas dans `git log`. Et il est toujours là, nommé, à une commande de distance. **Rien de ce que nous avons fait n'a été silencieusement perdu.**

> :information_source:
> Chaque référence a son propre reflog, pas seulement **HEAD**. `git reflog show master` vous raconte l'historique des endroits où le pointeur de la branche `master` est passé. Les fichiers sont du texte brut sous `.git/logs/` — allez faire un `cat .git/logs/HEAD` si vous ne nous croyez pas.
>
> Le reflog est aussi la seule partie de Git qui expire. Par défaut, les entrées inatteignables sont élaguées au bout de 30 jours et les atteignables au bout de 90 (`gc.reflogExpireUnreachable`, `gc.reflogExpire`). Le reflog est donc un superbe filet de sécurité pour la catastrophe de la semaine dernière, et d'aucun secours pour celle de l'année dernière.

## Lister les branches

Avant d'aller plus loin, la commande qui nous dit où nous sommes :

```console
git branch -vv
```

```console
  master        4d48f63 Add media directory with .gitkeep
* shopping_cart 4d48f63 Add media directory with .gitkeep
```

Le `*` marque la branche sur laquelle nous sommes. `-vv` montre aussi le dernier commit de chaque branche et, une fois que nous aurons un dépôt distant, quelle branche distante elle suit.

## La forme des branches

Ici il faut corriger quelque chose, parce que le langage que les gens emploient à propos des branches est trompeur et qu'il cause de vraies confusions plus tard.

Vous entendrez constamment que les branches sont « hiérarchiques », qu'une branche est « sous » une autre, que `master` est « la racine ». Mettez cela de côté. **Une branche est un nom pour un commit, et rien d'autre.** Il n'existe aucun champ dans Git qui enregistre « cette branche descend de cette autre branche ». Une fois que vous avez créé une branche, vous pouvez la déplacer n'importe où ; le nom ne se souvient de rien de sa provenance.

Ce qui *est* un graphe — un graphe orienté acyclique, pour être précis — c'est l'historique des **commit**s, parce que chaque commit pointe vers ses parents. Ce graphe-là est réel, et c'est là que « descend de » veut vraiment dire quelque chose.

Donc quand nous dessinons un schéma comme celui ci-dessous, nous dessinons deux choses à la fois : un ensemble de noms de branches, et le graphe de commits dans lequel ils se trouvent pointer. C'est une image utile. Ne prenez simplement pas l'indentation pour quelque chose que Git stocke.

Voyons un scénario d'exemple : imaginons que nous créons un site web e-commerce, et que nous commençons à travailler sur le panier. Puis, dans une sous-branche, nous commençons à travailler sur son gabarit HTML. Ce travail est en cours, et entre-temps nous voulons revenir travailler sur notre page d'accueil.

Commencer à travailler sur la branche `shopping_cart`, à partir de `master` :

```console
git checkout master
git checkout -b shopping_cart
```

Tap… tap… tap, code… code… code… créons les fichiers et validons nos changements, puis créons une nouvelle branche pour le gabarit :

```console
mkdir -p lib
touch lib/shopping_cart.js
git add lib
git commit -m 'Initial shopping cart code'
git checkout -b shopping_cart_template
```

> :warning:
> Attention au raccourci `-a` ici. `git commit -am '...'` ne prend que les fichiers que Git suit déjà. Notre tout nouveau `lib/shopping_cart.js` n'a jamais été ajouté, il est donc **untracked**, et `-a` va joyeusement l'ignorer — vous vous retrouveriez avec un commit vide et une erreur déroutante. Les nouveaux fichiers ont toujours besoin d'un `git add` explicite au préalable. Celle-là, tout le monde se fait avoir.

Tap… tap… tap, code… code… code… on valide, puis retour sur master pour commencer la page d'accueil :

```console
mkdir -p views
touch views/shopping_cart.html
git add views
git commit -m 'Implement shopping cart template'
git checkout master
git checkout -b homepage
```

Nous sommes partis de `master`, nous avons créé `shopping_cart` à partir de lui, puis `shopping_cart_template` à partir de *celle-là*, puis nous sommes revenus sur `master` et avons créé `homepage`. Dessinés comme un arbre généalogique, nos quatre noms de branches se placent dans le graphe de commits comme ceci :

```
master
├── shopping_cart
│   └── shopping_cart_template
└── homepage
```

Et voici la même chose telle que Git la voit réellement — quatre noms, chacun pointant vers un commit :

```console
git branch -vv
```

```console
* homepage               4d48f63 Add media directory with .gitkeep
  master                 4d48f63 Add media directory with .gitkeep
  shopping_cart          41d6720 Initial shopping cart code
  shopping_cart_template 5c37832 Implement shopping cart template
```

Remarquez que `homepage` et `master` pointent vers le *même* commit. Nous avons créé la branche et nous n'y avons pas encore committé, donc il n'y a véritablement rien pour les distinguer. Une branche coûte 41 octets à Git, et aucune réflexion.

C'est tout ce que c'est : une branche est un synonyme d'un **commit**, et committer sur une branche veut dire « avance ce nom jusqu'au nouveau commit ». Vous pouvez le voir se produire en allant regarder à l'intérieur de `.git/refs/heads/`.

## Appliquer les changements d'une branche à une autre. Le **merge** de Git.

La commande `merge` de Git permet d'appliquer un ensemble de changements d'une branche à une autre.

Donc, vous avez fait la logique du panier dans une branche, `shopping_cart`, et le design dans une autre, dans notre exemple `shopping_cart_template`. Pour avoir un panier fonctionnel, il nous faudra les deux changements. Nous allons donc apporter tout ce qui vient de la seconde branche dans la première.

> :information_source:
> Pour simplifier, nous allons imaginer que dans chaque ensemble de commits vous avez touché des fichiers différents. Nous verrons plus tard ce qui se passe quand les mêmes fichiers ont été modifiés dans deux branches différentes. Pour être sûrs de ne pas nous mettre tout de suite dans l'embarras (et plus tard, nous nous y mettrons), vérifions d'abord que notre travail est bien validé. Notre bon ami `git status`.

```console
git checkout shopping_cart
git status
```

```console
On branch shopping_cart
nothing to commit, working tree clean
```

Maintenant, vérifions vers quoi cette branche pointe. Nous avons déjà vu la commande `git log` ; `git log -1` ne montre que le **commit** le plus récent de la branche courante.

```console
commit 41d6720b05bbb8c051b35a75b164957b38753ab8
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:46:00 2026 +0100

    Initial shopping cart code
```

Il nous dit que notre **HEAD** pointe, comme prévu, vers la référence de la branche `shopping_cart`, qui se trouve actuellement au commit `41d6720`.

Donc, nous sommes sur la branche `shopping_cart`. Si nous lançons la commande `git merge shopping_cart_template`, Git va faire des choses très intelligentes et appliquer à celle-ci tous les changements que nous avons faits dans cette seconde branche.

Tapez la commande et vous devriez voir :

```console
git merge shopping_cart_template
```

```console
Updating 41d6720..5c37832
Fast-forward
 views/shopping_cart.html | 8 ++++++++
 1 file changed, 8 insertions(+)
 create mode 100644 views/shopping_cart.html
```

Des choses très intéressantes viennent de se produire. Décortiquons-les. Comme nous l'avons appris, les **commit**s ont des parents et les **branch**es sont des références vers des **commit**s. Git dit qu'il a mis à jour `41d6720` vers `5c37832`. Il dit aussi qu'il a fait un **Fast-forward**, sur quoi nous revenons dans une seconde. Puis il nous dit ce qui a réellement changé : il a créé `views/shopping_cart.html`, comme prévu. Notre zone de travail l'a maintenant (avec `tree -C`) :

```console
.
├── lib
│   └── shopping_cart.js
├── media
├── readme.md
└── views
    └── shopping_cart.html
```

Et le graphe rend toute la situation limpide d'un coup d'œil :

```console
git log --oneline --graph --decorate --all
```

```console
* 5c37832 (HEAD -> shopping_cart, shopping_cart_template) Implement shopping cart template
* 41d6720 Initial shopping cart code
* 4d48f63 (master, homepage) Add media directory with .gitkeep
* a07690f Add git log to the list of commands we learned
* 72c4234 Add the list of commands we learned today.
* 0ab682b Added readme.md
```

Regardez bien trois choses. `shopping_cart` et `shopping_cart_template` pointent maintenant vers le *même* commit. **HEAD** pointe vers `shopping_cart`. Et l'historique est une seule ligne droite — il n'y a de fourche nulle part dans cette image, parce que Git n'en a pas créé.

C'était le scénario le plus simple possible. `shopping_cart_template` avait été créée à partir de `shopping_cart`, et rien d'autre ne s'était passé sur `shopping_cart` entre-temps, si bien que l'historique de la seconde branche contenait déjà entièrement celui de la première. Git n'avait donc absolument rien à fusionner. Il a simplement déplacé un pointeur : il a mis le **sommet** de `shopping_cart` sur le sommet de `shopping_cart_template`. C'est cela, un **fast-forward**, et c'est pourquoi aucun **commit** de fusion n'apparaît et pourquoi le graphe reste plat.

> :warning:
> C'est la première fois dans ce cours que nous n'allons pas vous dire toute la vérité. Bien que `merge` soit l'une des commandes que vous utiliserez le plus souvent, se construire une compréhension réelle et détaillée de ce qu'elle fait est véritablement **compliqué** — et un fast-forward est précisément le cas où elle ne fait presque rien. Dans [Mettre en œuvre un workflow collaboratif efficace](5-git-workflow.md "Mettre en œuvre un workflow collaboratif efficace"), nous payons cette dette en entier : la base de fusion, la fusion à trois points, les vrais commits de fusion avec deux parents, et les conflits. Pour l'instant, sachez que vous avez vu le cas facile, et qu'il a considérablement flatté Git.

## Récapitulatif : les branches

* **Une branche est un nom pour un commit.** Rien de plus. Elle n'enregistre rien de sa provenance — c'est le graphe des **commit**s qui fait cela.
* `git branch -vv` liste les branches, marque la branche courante d'un `*`, et montre le commit vers lequel chacune pointe.
* `git checkout -b branch_name` crée une nouvelle branche au **commit** sur lequel pointe notre **HEAD**, et bascule dessus. L'écriture moderne est `git switch -c branch_name`.
* `git checkout branch_name` change de branche, en mettant à jour **HEAD** et notre zone de travail. Écriture moderne : `git switch branch_name`.
* `git stash` met de côté les changements non validés de notre zone de travail, en la laissant propre ; `git stash pop` les rapporte.
* `git reflog` montre chaque déplacement qu'a fait **HEAD** — la commande la plus utile qui soit quand on est perdu.
* `git merge` apporte les changements d'une branche dans une autre. Quand l'historique de la cible contient déjà le nôtre, il le fait en déplaçant simplement un pointeur : un **fast-forward**.
