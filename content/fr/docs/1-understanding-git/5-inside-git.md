---
title: Au cœur du dépôt, au cœur du commit
slug: "inside-git"
weight: 5
---
# Au cœur du dépôt, au cœur du commit

Le **commit** est l'objet le plus intéressant de Git, notre outil principal pour construire un historique de notre code, pour nommer des versions, pour collaborer avec d'autres.

Chaque fois que nous tapons la commande `git commit`, nous créons un nouvel enregistrement, un nouveau point d'étape.

## Mais au juste, c'est quoi précisément un **commit** ?

Pour bien comprendre le **commit**, nous devons faire un petit détour et rencontrer deux autres concepts. Le **blob**, qui est le contenu de nos fichiers, et les **tree**, qui sont les arborescences successives de fichiers.

Pour comprendre, entamons un nouveau voyage dans les entrailles de la bête. Où en est le contenu de notre répertoire caché `.git` — et plus précisément de son sous-répertoire `objects` ?

```console
tree .git/objects
```

Ce qui nous donne :

```console
.git/objects
├── 0b
│   └── a5adce31cb9cf9951fed3075d7571a9db5bc32
├── 0c
│   └── 7e1663dd99931898dfa9e25dfd2aba94dbe9ad
├── 38
│   └── 36229b5ce7fd362c59974d286de92bf5191784
├── 46
│   └── 079d29e5c812f3141e2e5a2522c6a5871d2255
├── 5a
│   └── b2caec01348fa809286b406298889992680ed0
├── 83
│   └── 2e299281e32ed167f389f4b34501ec48b302c0
├── 89
│   └── 69130a4c5a09759ca1f60b161a8805edf26042
├── d2
│   └── eafda3f0b5660fd33b0db429d2f5e447c4cd28
├── f1
│   └── 2dd321865c1b55cd32d413e8ef51b6c4ee7741
├── info
└── pack

12 directories, 9 files
```

Wow ! Plein de choses. On n'a ajouté que deux fichiers, et pourtant il y a 9 objets dans le sous-répertoire **objects**. Intéressant ! Étudions.

> :information_source:
> Comme nous vous en avons averti au chapitre précédent, les trois hashes de commit ci-dessous sont les miens et les vôtres seront différents, parce que votre nom, votre e-mail et la seconde à laquelle vous avez committé entrent tous dans le commit. Les hashes de **blob**, en revanche — ceux de `readme.md` et de `LICENSE` — ne dépendent que du contenu des fichiers ; donc si vous avez tapé ce que nous avons tapé, ils correspondent.

En réalité, dans **objects**, Git va mettre _toutes_ les choses qu'il va gérer :
d'abord notre `readme.md` compressé (maintenant on en a même deux versions) ainsi que notre `LICENSE` — ce type d'objet est appelé **blob** (en anglais Binary Large Object).

## Les blobs

Un « **blob** », ça peut représenter un fichier de code source, une image, toute chose. Comme on a fait un changement sur `readme.md`, il va être représenté deux fois. Une pour chaque version.

> :information_source:
> Comme nous l'avons dit, le nom de l'objet est maintenant quelque chose qui représente son contenu. Si on a 10 fichiers qui ont le même contenu, Git va les enregistrer une seule fois sous un seul nom. Pour mieux lire nos **sha**s, souvent, au lieu de référencer les 40 caractères, on va prendre les 7 premiers. Ça nous suffit pour bien les identifier… et ça reste unique dans presque tous les cas. Donc au lieu de parler de `0ba5adce31cb9cf9951fed3075d7571a9db5bc32`, on va le plus souvent parler de `0ba5adc`.

Donc le nom de fichier… il est parti où ?

## Les **tree**s et les **commit**s

Dans le même répertoire Git, un autre type d'objet :

* Les objets de type **tree** — ceux-ci vont contenir nos noms de fichiers, et référencer les objets de type **blob** qui vont avoir le contenu de ces fichiers, ainsi que les droits qui y sont attachés.

Maintenant, les noms de fichiers de tous ces objets sous `.git/objects` se ressemblent (ce sont tous des choses dont le nom de fichier est un « hash »). Juste en regardant cette liste de fichiers, on ne peut pas les distinguer, mais à l'intérieur les **commit**s, les **tree**s et les **blob**s ont des formats différents.


## Voir les objets avec `git show`

`git show` est une commande très pratique : on lui donne un objet git de n'importe quel type et elle montre le contenu. Utilisons-la pour découvrir les arbres. On peut l'utiliser pour voir nos **blob**s, mais aussi nos **commit**s et nos **tree**s.

### À l'intérieur du **tree** — notre arborescence

Parmi nos neuf objets, celui appelé **8969130** est une arborescence, un « **tree** » :

```console
git show 8969130
```

Le résultat de la commande est très simple :

```console
tree 8969130

LICENSE
readme.md
```

Voilà, **8969130** est tout simplement une liste de fichiers. On en a deux ici. Mais nous avons pris l'habitude de creuser un peu plus… donc nous allons utiliser une commande de plus bas niveau qui nous donnera bien plus de détails, `git ls-tree` :

```console
git ls-tree 8969130
```

Et voilà notre résultat bien plus détaillé :

```console
100644 blob 0ba5adce31cb9cf9951fed3075d7571a9db5bc32	LICENSE
100644 blob 0c7e1663dd99931898dfa9e25dfd2aba94dbe9ad	readme.md
```

Le vrai contenu du **tree** n'a pas uniquement les noms de fichiers, mais quatre champs :

```
{filemode} {type} {sha} {filename}
```

* **filemode** — ce sont les métadonnées sur le fichier tel qu'il est sur le système de fichiers. Ici par exemple, *100644* représente un fichier régulier non exécutable. Si on avait *100755*, cela aurait été un fichier avec des droits d'exécution, *120000* eût été un lien symbolique et *040000* un répertoire (si ces termes ne vous sont pas familiers, cherchez « permissions de fichiers Unix » et `chmod`) — mais passons, cela n'est pas très important pour l'instant. Notez que Git stocke bien moins de choses que le système de fichiers : il enregistre seulement si un fichier est exécutable, et rien d'autre — ni le propriétaire, ni le groupe, ni les bits de permission complets.
* **type** peut être soit **blob**, soit **tree**. Donc soit un fichier, soit un sous-répertoire.
* **sha** — vous l'aurez deviné, c'est le « hash », ou le nom de fichier de quelque chose qui va apparaître dans notre `.git/objects`
* **filename**, finalement, est notre nom de fichier (ou de répertoire)

Voilà, on voit comment tout se remet en place… avec nos **blob**s et nos **tree**s, nous pouvons recréer des arborescences avec les bons noms de fichiers, rangés là où ils sont censés être et avec un contenu bien spécifique.

> :information_source:
> Le lecteur astucieux aura remarqué qu'on a perdu quelque chose à quoi on est habitués : la date de création et de modification de ces fichiers. Nous retrouvons des dates au niveau des **commits**.

### Les sous-répertoires

Donc chaque **tree** nous permet de reconstruire un état d'un répertoire avec des fichiers qui ont un contenu connu. Essayons maintenant de créer un sous-répertoire ; nous avons déjà rencontré la commande `mkdir` :

```console
mkdir files
```
et puis notre vieil ami qui nous montre l'état de notre zone de travail :

```console
git status
```

```console
On branch master
nothing to commit, working tree clean
```

> :warning:
> Quoi ? Rien ? Quelle trahison ?! Nous avons créé un nouveau répertoire mais Git ne nous dit rien — il dit que l'arbre de travail est *propre*. En effet, Git ne sait pas suivre des répertoires vides. C'est normal quand on y pense. Dans Git, un **tree** est quelque chose qui représente une liste de fichiers ayant chacun un contenu particulier ; s'il n'y a pas de contenu, vers quoi va-t-il pointer ?

### Les sous-répertoires vides

L'usage pour garder un répertoire vide est de créer à l'intérieur un petit fichier vide, appelé conventionnellement `.gitkeep`, puis de le committer.

> :warning:
> `.gitkeep` est *une pure convention*. Ce n'est pas une fonctionnalité de Git, Git n'en a jamais entendu parler, et il n'y a rien dans le code source de Git qui le mentionne. À comparer avec `.gitignore`, que Git lit réellement et prend en compte. Vous pourriez nommer le fichier `.keep`, `.placeholder` ou `surtout-ne-me-supprimez-pas.txt` et cela fonctionnerait de manière identique — la seule chose qui compte est que le répertoire contienne *un* fichier suivi. `.gitkeep` est simplement le nom sur lequel tout le monde s'est mis d'accord, alors utilisez-le et les autres comprendront ce que vous vouliez dire.

```console
touch files/.gitkeep
git add files/.gitkeep
git commit -m'Add .gitkeep so files will be added to the repository'
```

```console
[master f0bb8a2] Add .gitkeep so files will be added to the repository
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 files/.gitkeep
```

Dans notre `.git/objects`, on va donc voir apparaître 4 nouveaux objets.

Un objet pour le **commit** (nous verrons ça juste après…), un nouveau **tree** qui représente notre racine, qui a changé :

```console
git ls-tree 3216264

100644 blob 0ba5adce31cb9cf9951fed3075d7571a9db5bc32	LICENSE
040000 tree d564d0bc3dd917926892c55e3706cc116d5b165e	files
100644 blob 0c7e1663dd99931898dfa9e25dfd2aba94dbe9ad	readme.md
```

Un deuxième **tree** (monsieur *d564d0*) qui va simplement contenir :

```console
git ls-tree d564d0

100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391	.gitkeep
```

Puis l'ami *e69de29*, qui est notre fichier vide nommé `.gitkeep`.

> :information_source:
> Nous vous avons raconté que c'est le contenu du fichier qui détermine le nom de l'objet, et rien d'autre. Et là on a un fichier vide. Faites l'exercice : cherchez sur le web `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391` et vous le trouverez partout. Plein de fichiers différents, dans plein de projets différents, complètement vides, avec des noms différents — et tous le même unique objet. `e69de29` est le blob le plus populaire de l'histoire de Git.

Résumons.

Si nous suivons le premier **tree-id** que nous avons vu, **8969130**, cela nous donnera :
```console
.
├── LICENSE
└── readme.md
```
Mais suivre le deuxième **tree**, le **3216264**, nous amènera à :

```console
.
├── LICENSE
├── files
│   └── .gitkeep
└── readme.md
```

### Boucler la boucle avec le **commit**

Le dernier type d'objet que l'on va trouver dans `.git/objects/`, ce sont les **commit**s.

Les objets de type **commit** — ça, c'est un élément central ! Le **commit** est cette trace de nos changements. Un commit identifie principalement un **tree** particulier plus ses **commit**s parents : exactement un dans le cas ordinaire, aucun du tout pour le tout premier commit d'un dépôt (c'est pourquoi Git l'a appelé `root-commit` quand nous l'avons fait), et deux ou plus pour une fusion.

Le commit nous permet de construire les relations entre les **tree**s, d'enregistrer les changements.

Pour rappel, dans cette leçon nous avons déjà utilisé la commande `git commit` quatre fois :

1. Quand nous avons ajouté `readme.md` (__commit d2eafda__)
2. Quand nous avons modifié `readme.md` pour ajouter la liste des commandes que nous avons apprises (__commit 46079d2__)
3. Quand nous avons ajouté `LICENSE` (__commit 5ab2cae__)
4. Puis quand nous avons ajouté `files/.gitkeep` (__commit f0bb8a2__)

Nous allons étudier le deuxième, **46079d2**. Pour voir l'objet brut, exactement tel que Git le stocke, il y a une commande de plomberie :

```console
git cat-file -p 46079d2
```

Et son contenu ressemble à ceci :

```console
tree 832e299281e32ed167f389f4b34501ec48b302c0
parent d2eafda3f0b5660fd33b0db429d2f5e447c4cd28
author Ori Pekelman <ori@pekelman.com> 1770009030 +0100
committer Ori Pekelman <ori@pekelman.com> 1770009030 +0100

Add the list of commands we learned today.
```
Donc la structure est :

* tree {tree_sha} — c'est la référence, le **sha**, le **tree-id** qui représente notre arborescence
* parent {parents} — c'est le commit parent, on y reviendra
* author {author_name} <{author_email}> {author_date_seconds} {author_date_timezone} — c'est l'auteur du code, avec son nom, son e-mail et un **timestamp**, le moment auquel le code aura été créé
* committer {committer_name} <{committer_email}> {committer_date_seconds} {committer_date_timezone} — c'est la personne qui a committé le code, qui n'est pas toujours l'auteur… puis le moment où le commit a été fait (notons que d'habitude **author** et **committer** sont la même personne)
* {commit message} — le message, celui qu'on a ajouté avec le drapeau `-m'...'`, qui contient le « pourquoi » du changement.

> :information_source:
> Ici, les timestamps de l'auteur et du committeur sont identiques, parce que nous avons écrit et committé dans le même souffle. Ils diffèrent quand le patch de quelqu'un d'autre est appliqué à votre dépôt, ou quand un commit est rebasé : la paternité (et sa date) est préservée, la ligne `committer` enregistre qui l'a mis là et quand. C'est aussi exactement pour cela que vos commit-ids diffèrent des miens, même pour des fichiers identiques octet pour octet — votre nom, votre e-mail et vos timestamps font partie de ce qui est haché.

Donc on a bien compris : le commit, c'est une référence vers un **tree-id** (et lui, on a déjà vu qu'il nous permet de reconstituer un espace de travail… une arborescence avec des fichiers ayant un contenu spécifique) ; cette référence contient quelques informations supplémentaires : qui a fait le changement, quand, pourquoi… et… le « commit parent ». Le commit parent, c'est donc l'état précédent de notre arborescence. Donc chaque **commit** peut aussi être appelé une « révision ». Quand nous irons, plus tard, voir la liste des **commits**, nous verrons la liste de toutes les révisions apportées à notre dépôt.

Mais d'habitude, nous n'allons jamais regarder les structures internes de Git : nous utiliserons des commandes qui, en plus, nous donnent davantage d'informations. Regardons donc le deuxième **commit** avec la commande `git show` :

```console
git show 46079d2
```

```console
commit 46079d29e5c812f3141e2e5a2522c6a5871d2255
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:10:30 2026 +0100

    Add the list of commands we learned today.

diff --git a/readme.md b/readme.md
index 3836229..0c7e166 100644
--- a/readme.md
+++ b/readme.md
@@ -1 +1,8 @@
 # My first Git project
+
+Today we learned the following Git commands:
+
+1. `git init` - initialize a new git repository
+2. `git status` - find out the status of the working directory relative to the git repository
+3. `git add` - add files to the git index to prepare for a commit
+4. `git commit -m"{commit message}"` - save a milestone in the git repository
```

Donc là, nous ne voyons plus le **tree**, qui est en gros un détail interne, mais uniquement les informations qui ont trait à notre changement. Voyons ligne par ligne :

1. commit — l'identifiant du commit, son **sha**, le **commit-id**
2. Author: — qui a fait le changement
3. Date: — quand le changement a été fait
4. Le message du commit
5. Le diff. La différence entre le fichier `readme.md` quand il avait le sha `3836229`, puis quand il a eu le sha `0c7e166`.

> :information_source:
> Cette ligne `@@ -1 +1,8 @@` s'appelle un **en-tête de section** (*hunk header* en anglais) et il vaut la peine de savoir la lire : à gauche, la région de l'*ancien* fichier (à partir de la ligne 1, sur une ligne de long — quand la longueur vaut 1, Git l'omet) ; à droite, la région du *nouveau* fichier (à partir de la ligne 1, sur huit lignes de long). Notez la virgule : `+1,8` signifie « 8 lignes à partir de la ligne 1 ». Puis une ligne de contexte précédée d'une espace, et sept lignes ajoutées précédées d'un `+`. Les lignes supprimées porteraient un `-`.

Si le **tree** nous a beaucoup servi pour comprendre la structure interne de Git, il s'agit bien d'une chose interne. Dans notre travail de tous les jours, c'est presque exclusivement avec les **commits** que nous allons interagir.

> :information_source: Git ne sauvegarde pas les différences entre les deux fichiers, mais réellement le contenu de chacune des versions, à part. Cette différence, ce **diff** que nous voyons, est calculé dynamiquement quand nous utilisons la commande `git show`.

> :information_source:
> Nous avons un tout petit peu simplifié l'histoire : si vous regardez un vrai dépôt Git avec plein de fichiers et plein de **commits**, vous ne verrez pas un objet pour chaque fichier. En effet, Git va de temps en temps faire du nettoyage et compresser un peu plus loin (le mot-clé est **pack**). Mais ceci est en dehors du cadre du présent cours.

## Récapitulatif : **blob**, **commit** et **tree**

* **blob** — le blob est le contenu d'un fichier de la zone de travail qui a été ajouté à l'index. Il contient le vrai contenu du fichier dans une forme compressée, son nom étant composé de 40 caractères (**SHA**) qui sont une signature de son contenu. Un blob ne sait rien de son propre nom de fichier.
* **tree** — contient la liste des fichiers (donc des identifiants de blobs de 40 caractères)… avec leurs noms et leur bit d'exécution. On peut aussi, dans la liste, se référer à un autre **tree** par son **tree-id**, ce qui va nous donner un sous-répertoire.
* **commit** — c'est l'enregistrement d'un état, la validation ; à partir d'un **commit**, nous pouvons reconstruire notre zone de travail avec un **tree** spécifique. Il contient des informations sur l'auteur du changement et sa raison. Il pointe aussi vers son commit parent, ou ses commits parents.

Voici le tout, dessiné avec les objets du dépôt que vous venez de construire — chaque hash ci-dessous est un hash que vous pouvez afficher vous-même avec `git cat-file -p` :

{{< mermaid >}}
graph TD
  C["commit f0bb8a2<br/>qui, quand, pourquoi"]
  P["commit 5ab2cae<br/>le parent"]
  T["tree 3216264"]
  F["tree d564d0b"]
  L["blob 0ba5adc"]
  R["blob 0c7e166"]
  K["blob e69de29"]

  C -->|parent| P
  C -->|tree| T
  T -->|"LICENSE"| L
  T -->|"files/"| F
  T -->|"readme.md"| R
  F -->|".gitkeep"| K
{{< /mermaid >}}

Regardez où sont les noms de fichiers. Ils sont sur les **flèches**, pas dans les boîtes : `0ba5adc` est le contenu de `LICENSE` et ne sait rien du fait de s'appeler ainsi. C'est pour cela que renommer un fichier ne crée aucun nouveau blob, et c'est pour cela qu'un `.gitkeep` vide dans votre dépôt est le même objet `e69de29` qu'un fichier vide dans le dépôt de tout le monde.

Toute la magie de git va se déployer à partir de ce concept simple de **commit**. Git va nous permettre de faire nos modifications ; chaque fois, nous allons enregistrer des états. Puis il va nous permettre de sauter de l'un à l'autre. De comparer deux états… même d'en faire des mélanges.

Mais ça, c'est dans les chapitres suivants…
