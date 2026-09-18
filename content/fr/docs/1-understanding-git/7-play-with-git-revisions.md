---
title: Jouer avec nos révisions
slug: "play-with-git-revisions"
weight: 7
---
# Jouer avec nos révisions

Maintenant nous avons appris à créer des versions de notre code. Vous avez changé un fichier ? On tape `git commit -am'Added some CSS styles for header'`. Voilà, une nouvelle révision vient de se créer.

## Voir la liste des révisions : `git log`

Nous pouvons maintenant taper `git log` ; cette commande, fort utile, liste toutes les modifications dans l'ordre, la plus récente d'abord.

```console
commit 49c6166b1deb64004016a2ffe1c1b75eeadc4a4c (HEAD -> master)
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:25:44 2026 +0100

    Rename files to media

commit 17baa688a633434ea561c8e4ada42d1f9db6c058
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:22:10 2026 +0100

    Remove license file

commit 13688773276850af857c23ef9125d1f19a0f92f1
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:17:22 2026 +0100

    Add .gitkeep so files will be added to the repository

commit cabdb6f9270182945008cee8acb9871dcf9fc03f
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:15:42 2026 +0100

    Adding a license file

commit 72c4234bd6c3c16c3b567b851e2c58cedbb019be
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:10:30 2026 +0100

    Add the list of commands we learned today.

commit 0ab682bba608f1b175dd716f8f62de4d462f604f
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:06:51 2026 +0100

    Added readme.md
```

Voilà, on a une jolie liste de tout ce qui s'est passé, les six commits que nous avons faits depuis le début. Et si on regarde de près, il n'y a rien là qui doive nous surprendre… **commit** et son **sha**, puis l'auteur, et finalement la date et notre message de commit. Une seule chose s'est ajoutée là, à la première ligne : **(HEAD -> master)**. Nous expliquerons ça un peu plus bas. Pour le moment, continuons…

> :information_source:
> `git log` fait passer sa sortie dans un pageur (généralement `less`), donc sur un long historique vous défilez avec les touches fléchées ou la barre d'espace, et vous quittez avec `q`. Si cela vous a surpris la première fois, vous êtes en excellente compagnie.

Et si nous modifiions `readme.md` pour rendre compte de ce que nous venons d'apprendre ? Vous pouvez ouvrir votre éditeur de texte préféré et modifier `readme.md` ; moi, je vais encore utiliser la ligne de commande pour ajouter la ligne.

```console
printf '\n5. `git log` view all revisions\n' >> readme.md
```

Le `>>` (plutôt que `>`) ajoute à la fin au lieu d'écraser — une distinction qu'il vaut mieux comprendre du premier coup que du second.

Et de nouveau, on va ajouter un petit commit :

```console
git commit -am'added git log command'
```

Cool. Ça continue à marcher. Maintenant, si je tape à nouveau `git log`, je verrai en haut de la liste mon nouveau commit :

```console
commit 4b8243a7e2f6defd29aa50fb48c741040971aaad (HEAD -> master)
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:31:09 2026 +0100

    added git log command
```

Donc maintenant on a déjà fait pas mal de choses dans notre petit dépôt Git. Nous travaillons sur une seule branche : **master**. Chaque fois qu'on a ajouté un **commit**, notre **index** a été mis à jour. Et **HEAD**, ce pointeur vers notre zone de travail, pointait vers le **commit** le plus récent.

Voilà toute la forme de ce que nous avons construit, et voici les sept commits que vous venez de faire :

{{< mermaid >}}
graph TD
  H["HEAD"] --> M
  M["master"] --> C7
  C7["4b8243a<br/>added git log command"] --> C6
  C6["49c6166<br/>Rename files to media"] --> C5
  C5["17baa68<br/>Remove license file"] --> C4
  C4["1368877<br/>Add .gitkeep…"] --> C3
  C3["cabdb6f<br/>Adding a license file"] --> C2
  C2["72c4234<br/>Add the list of commands…"] --> C1
  C1["0ab682b<br/>Added readme.md"]
{{< /mermaid >}}

Chaque flèche pointe *en arrière*, d'un commit vers son parent. C'est la seule direction que Git stocke : un commit sait d'où il vient et n'a aucune idée de ce qui est venu après lui. C'est aussi pour cela que les deux choses en haut sont si peu coûteuses — `master` est un fichier contenant le hash d'un commit, et `HEAD` est un fichier contenant le mot `master`. Ajouter un commit réécrit une ligne dans chacun. Rien d'autre ne bouge.

## Le suivi des changements

Donc nous avons appris à créer un dépôt Git avec `git init`, puis à y ajouter des fichiers avec `git add` et à les valider avec `git commit`.

Nous avons bien compris comment enregistrer les changements successifs : chaque fois que je fais un ensemble de changements cohérents.

> :information_source:
> Par exemple, si je travaille sur le panier de mon site e-commerce, peut-être que j'ai changé le template et ajusté le CSS, ce qui fait ensemble un bout de travail qui a du sens… je vais faire quelque chose comme `git add views/shopping_cart.html public/styles/shopping_cart.css` puis `git commit -m'Add pretty red button to shopping cart ticket #654'`.

Plus tard, je pourrai même revenir dans le passé et voir l'état des choses avant que je n'aie fait ce changement.

Mais comment voir ce qui a changé ?

## `git diff` pour voir ce qui a changé

Donc revenons à notre dépôt : rappelez-vous, notre dernier changement a été d'ajouter une ligne à `readme.md`. La commande `git log` nous donne la liste des changements, n'est-ce pas ? L'avant-dernier commit, c'est **49c6166**, et nous pouvons maintenant voir ce qui a changé depuis.

La commande :

```console
git diff 49c6166
```
nous dira quelque chose comme :
```console
diff --git a/readme.md b/readme.md
index 0c7e166..8457b88 100644
--- a/readme.md
+++ b/readme.md
@@ -6,3 +6,5 @@ Today we learned the following Git commands:
 2. `git status` - find out the status of the working directory relative to the git repository
 3. `git add` - add files to the git index to prepare for a commit
 4. `git commit -m"{commit message}"` - save a milestone in the git repository
+
+5. `git log` view all revisions
```

En gros, il nous donne le résultat de la commande `diff` permettant de calculer la différence entre deux fichiers. Ici nous voyons bien que nous avons ajouté un retour à la ligne puis une ligne de texte.

Le `@@ -6,3 +6,5 @@` est l'**en-tête de section** que nous avons rencontré dans [Au cœur du dépôt, au cœur du commit](5-inside-git.md "Au cœur du dépôt, au cœur du commit") : trois lignes à partir de la ligne 6 dans l'ancien fichier sont devenues cinq lignes à partir de la ligne 6 dans le nouveau. Notez les virgules — `-6,3` signifie « 3 lignes à partir de la ligne 6 », ce n'est pas un nombre décimal. Ce qui suit le `@@` de fermeture, c'est juste Git qui se rend utile : le titre englobant le plus proche, pour que vous sachiez où vous êtes dans le fichier.

> :information_source:
> Git, à la différence d'autres systèmes de gestion de versions, ne conserve pas une chaîne de modifications… mais bien de vrais instantanés de chaque fichier. Quand nous voyons le « diff », la différence entre deux états d'un fichier, il calcule cela à la volée. Mais comme nous l'avons noté plus haut, Git sait être très intelligent et bien compresser les choses : le format **pack** est une chose remarquablement futée et terriblement optimale, et d'ailleurs c'est une des raisons pour lesquelles Git est si rapide. Ceci est un détail interne d'implémentation qui n'a pas d'effet sur votre usage de l'outil, et donc hors du cadre du présent cours : nous allons aussi profondément qu'il le faut pour comprendre ce que l'on fait, précisément — mais pas plus.

## `git diff --cached` pour voir ce que l'on a ajouté à l'index

Une fois qu'on a ajouté des choses à l'index, à notre **staging**, `git diff` ne va plus rien nous dire. Si vous voulez voir les changements qui sont prêts à être **commit**és… `git diff --cached` est notre ami.


## Les différences avec le dernier commit…

Nous avons vu comment utiliser `git diff` avec le **SHA** d'une révision, mais Git nous fournit aussi une syntaxe agréable pour parler en termes relatifs. Par exemple, `git diff HEAD~1` est une manière de dire : donne-moi le **diff** avec le commit précédent — l'avant-dernier. `git diff HEAD~2`, vous l'aurez compris, nous montre la différence avec celui d'avant, deux crans en arrière. C'est bien plus pratique que de recopier des hashes, et c'est ce que vous taperez neuf fois sur dix.

## Comment savoir quand un changement a été introduit ? `git blame`

Assez souvent, quand nous lisons du code, nous ne sommes pas sûrs de tout comprendre. On voit une ligne. Et on se demande… mais pourquoi, pourquoi oh grands dieux ai-je fait ceci ? Git, qui se souvient de tout, peut nous aider.

Si `git diff` nous donne la différence entre deux commits, et `git log` la liste de tous les commits… `git blame` peut nous dire, pour un fichier à un **commit** spécifique, quand et pourquoi chaque ligne a été ajoutée ou modifiée.

```console
git blame readme.md
```

```console
^0ab682b (Ori Pekelman 2026-02-02 06:06:51 +0100  1) # My first Git project
72c4234b (Ori Pekelman 2026-02-02 06:10:30 +0100  2) 
72c4234b (Ori Pekelman 2026-02-02 06:10:30 +0100  3) Today we learned the following Git commands:
72c4234b (Ori Pekelman 2026-02-02 06:10:30 +0100  4) 
72c4234b (Ori Pekelman 2026-02-02 06:10:30 +0100  5) 1. `git init` - initialize a new git repository
72c4234b (Ori Pekelman 2026-02-02 06:10:30 +0100  6) 2. `git status` - find out the status of the working directory relative to the git repository
72c4234b (Ori Pekelman 2026-02-02 06:10:30 +0100  7) 3. `git add` - add files to the git index to prepare for a commit
72c4234b (Ori Pekelman 2026-02-02 06:10:30 +0100  8) 4. `git commit -m"{commit message}"` - save a milestone in the git repository
4b8243a7 (Ori Pekelman 2026-02-02 06:31:09 +0100  9) 
4b8243a7 (Ori Pekelman 2026-02-02 06:31:09 +0100 10) 5. `git log` view all revisions
```

Ici nous pouvons voir que la toute première ligne a été ajoutée dans le commit initial (c'est ce que marque le `^` : la ligne est là depuis le début de l'historique). Puis nous avons deux autres commits. Nous pouvons ainsi remonter dans le temps… et comprendre précisément le pourquoi et le comment.

> :warning:
> Attention à la casse du nom de fichier. Notre fichier est `readme.md`, en minuscules. `git blame README.md` aura l'air de fonctionner sur macOS et Windows, parce que leurs systèmes de fichiers sont insensibles à la casse par défaut, et échouera sous Linux — et sur la CI de votre collègue. Git, lui, tient toujours compte de la casse. Tapez le nom tel que le fichier est nommé.

## `git show` pour voir le contenu du commit

Nous pouvons maintenant regarder un commit particulier avec la commande `git show` et voir quand le changement a été introduit.

```console
git show 4b8243a
```

```console
commit 4b8243a7e2f6defd29aa50fb48c741040971aaad
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:31:09 2026 +0100

    added git log command

diff --git a/readme.md b/readme.md
index 0c7e166..8457b88 100644
--- a/readme.md
+++ b/readme.md
@@ -6,3 +6,5 @@ Today we learned the following Git commands:
 2. `git status` - find out the status of the working directory relative to the git repository
 3. `git add` - add files to the git index to prepare for a commit
 4. `git commit -m"{commit message}"` - save a milestone in the git repository
+
+5. `git log` view all revisions
```

> :information_source: la commande `git show` est très utile ; elle peut nous montrer non seulement le contenu d'un **commit** mais aussi celui d'un **tree** ou d'un **blob**.

Si vous utilisez la commande sans argument, elle vous montrera le tout dernier commit, celui qui se trouve à la pointe de votre branche **master**. Mais sans même faire `git log`, Git nous donne des raccourcis très utiles pour parler d'un commit sans connaître son **SHA**.

 * `git show HEAD^` — le petit chapeau nous permet de référencer le parent de notre commit. Donc le commit précédent.
 * `git show HEAD^^^` — on peut en mettre plusieurs. Ici nous verrons l'arrière-grand-parent de notre commit.
 * `git show HEAD~10` — mais si nous ne voulons pas avoir dix petits chapeaux… le tilde `~` fait la même chose, mais suivi d'un nombre. Ici nous verrons ce qui s'est passé dix commits en arrière.

Imaginons que nous ayons pris un mauvais virage. Ou que nous voulions simplement savoir ce qui s'est passé dans l'un de nos commits. Comme nous l'avons déjà vu, la commande `git log` nous permet de voir la liste des changements : qui a fait quoi, quand et pourquoi. Et `git checkout` nous permet d'aller prendre un commit passé et de mettre notre zone de travail dans l'état de ce commit.

## Atteindre un état passé avec `git checkout`

Imaginons maintenant que nous voulions revenir dans le temps, avant d'avoir fait ce changement.

Rien de plus simple : dans le log, je vais regarder le **SHA**, le hash du commit précédent, et je peux maintenant taper :

```console
git checkout 49c6166
```

Sa réponse va être un peu bavarde, donc ignorons le milieu pour l'instant et regardons juste la première et la dernière ligne :

```console
Note: switching to '49c6166'.
    # [blah blah blah blah Git essaie d'être super serviable]
HEAD is now at 49c6166 Rename files to media
```

Nous sommes revenus dans le passé. Si nous tapons `cat readme.md`, nous verrons notre fichier tel qu'il était avant que nous ajoutions le point 5.

> :information_source: **`git checkout` fait deux choses complètement différentes, et c'est un piège célèbre.**
> `git checkout <branche>` vous déplace vers une autre branche. `git checkout -- <fichier>` jette vos modifications non validées sur un fichier. L'un est de la navigation, l'autre de la destruction, et c'est le même mot — ce qui est exactement pour cela que des gens ont détruit du travail qu'ils voulaient garder.
> Depuis Git 2.23, les deux métiers ont leurs propres commandes. C'est là toute la raison de la séparation : `checkout` avait accumulé deux comportements sans rapport sous un seul nom, l'un anodin et l'autre irréversible, et rien dans la ligne de commande ne vous disait lequel vous aviez demandé. Les voici séparés :
> * `git switch master` — aller sur une branche.
> * `git switch -c new-feature` — créer une branche et y aller (`-c` pour *create*, là où `checkout` utilisait `-b`).
> * `git switch --detach 49c6166` — aller sur un commit spécifique, en se détachant délibérément (voir plus bas).
> * `git restore readme.md` — jeter les modifications non validées d'un fichier.
> * `git restore --staged readme.md` — retirer un fichier de l'index, en gardant les modifications.
>
> Nous continuons à enseigner `checkout` dans ce cours, parce que `checkout` est ce que vous verrez dans tous les tutoriels, toutes les réponses Stack Overflow et l'historique de shell de tous vos collègues pendant des années encore, et parce que cela fonctionne toujours exactement comme décrit. Mais maintenant vous connaissez la séparation moderne — et, plus important, vous savez *pourquoi* elle existe.

Et nous pouvons taper `git log` à nouveau pour voir.

**Sapristi** ! En effet, nous sommes dans l'état précédent et notre dernier commit a complètement disparu. Est-ce le bon moment pour paniquer ? Non. Il ne faut jamais paniquer.

La commande :

```console
git log --branches
```

> :information_source:
> Git est une grosse bête : pour chaque commande, il y a parfois des dizaines d'options différentes. Nous ne verrons, bien sûr, que l'essentiel.

Donc `git log --branches` va nous montrer que nous n'avons rien perdu. Et en plus, nous verrons quelques informations intéressantes supplémentaires.

```console
commit 4b8243a7e2f6defd29aa50fb48c741040971aaad (master)
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:31:09 2026 +0100

    added git log command

commit 49c6166b1deb64004016a2ffe1c1b75eeadc4a4c (HEAD)
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:25:44 2026 +0100

    Rename files to media

commit 17baa688a633434ea561c8e4ada42d1f9db6c058
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:22:10 2026 +0100

    Remove license file

commit 13688773276850af857c23ef9125d1f19a0f92f1
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:17:22 2026 +0100

    Add .gitkeep so files will be added to the repository

commit cabdb6f9270182945008cee8acb9871dcf9fc03f
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:15:42 2026 +0100

    Adding a license file

commit 72c4234bd6c3c16c3b567b851e2c58cedbb019be
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:10:30 2026 +0100

    Add the list of commands we learned today.

commit 0ab682bba608f1b175dd716f8f62de4d462f604f
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Feb 2 06:06:51 2026 +0100

    Added readme.md
```

En effet, `git log` nous montre par défaut le passé du point où nous nous trouvons. Rien n'a été perdu. Voici le **log**, qui est la même chose… à un petit détail près : là où en haut nous avions **(HEAD -> master)**, maintenant **4b8243a** est marqué **master** et **49c6166** est marqué **HEAD**. De quoi s'agit-il ?

**HEAD** est un pointeur vers l'endroit où nous nous trouvons maintenant. Nous étions sur le commit **4b8243a** et maintenant notre zone de travail est dans le passé, sur **49c6166**.

Si nous faisons maintenant `git checkout master`, le pointeur **HEAD** va de nouveau se positionner sur notre tout dernier commit, celui qui a le message « added git log command ». Nous pouvons le vérifier avec `git log` ou `git log --branches` (qui, là, feront donc précisément la même chose).

Mais c'est bizarre : nous avons appris à faire `git checkout {sha}` et maintenant, au lieu de mettre plein de caractères bizarres, nous écrivons en clair **master**.

Alors, qu'est-ce que **master** ? **master** est une branche. Comme nous vous l'avons déjà dit en introduction, avec Git nous pouvons travailler non seulement sur des révisions comme une flèche du temps unique… mais sur de multiples versions différentes, en même temps. **master** est, comme son nom l'indique, la version maîtresse, le haut de l'arbre. Un peu plus loin, nous vous montrerons comment créer d'autres branches, comment utiliser `git checkout` pour sauter de l'une à l'autre ; pour le moment, restons sur un seul tronc.

> :information_source:
> Dans d'autres systèmes de gestion de versions, comme les vénérables CVS ou SVN, cette branche maîtresse s'appelait justement « Trunk », le tronc, ce qui donne l'image de cette branche principale d'où toutes les autres sortent. Pour Git, c'est une simplification : il est si puissant et si malléable que ce concept est réducteur… mais allons-y, ne nous compliquons pas trop la vie tout de suite. Imaginez donc **master** comme le tronc principal.

### `master` ou `main` ?

Vous vous souvenez de ce message bavard que Git a affiché tout à l'heure quand nous avons lancé `git init` ? Le voici de nouveau, en entier :

```console
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint:
hint: 	git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint: 	git branch -m <name>
```

Il n'y a rien de magique dans le nom `master`. C'est une branche comme une autre ; Git ne la traite spécialement que dans le sens où `git init` la choisit comme nom de la première. Vers 2020, l'industrie est passée à `main` à la place, pour des raisons culturelles, et aujourd'hui GitHub et GitLab créent tous deux les nouveaux dépôts avec `main`. Git lui-même n'a pas changé sa valeur par défaut — en partie parce que la changer casserait un nombre énorme de scripts — mais il vous tanne désormais jusqu'à ce que vous fassiez un choix.

Faites le choix :

```console
git config --global init.defaultBranch main
```

À partir de là, chaque dépôt que *vous* créez démarre sur `main`, le conseil disparaît, et vous êtes aligné avec ce que font les services d'hébergement. Les dépôts existants ne sont pas affectés ; pour renommer la branche dans l'un d'eux, `git branch -m master main` (et s'il a un dépôt distant, il faudra le dire au distant aussi — nous y reviendrons quand nous parlerons de collaboration).

Nous continuons à dire `master` pour le reste de ce cours, parce que c'est ce que notre dépôt d'exemple a réellement. Si vous avez configuré `main`, lisez chaque `master` ci-dessous comme `main` ; rien d'autre ne change.

Comme **HEAD**, une branche est simplement un pointeur vers un **commit**. Et souvent le **HEAD** pointe vers le sommet de la branche sur laquelle nous sommes. Comme nous sommes sur la branche **master**, **HEAD** pointe vers son « sommet ». Notre dernier commit.

Nous aimons regarder sous le capot, n'est-ce pas ? Regardons quelques autres structures de données à l'intérieur de notre cher `.git` pour être sûrs d'avoir compris.

Assurez-vous d'avoir fait `git checkout master` et nous pouvons essayer les commandes suivantes :

```console
cat .git/HEAD
```
Qui nous sortira :

```console
ref: refs/heads/master
```
Donc ceci est une référence, qui pointe vers `refs/heads/master` — et ce truc est aussi un fichier sous `.git`. Nous pouvons suivre la trace et taper :

```console
cat .git/refs/heads/master
```

Et il nous répondra avec le **SHA**, le **commit-id** de notre tout dernier commit :

```console
4b8243a7e2f6defd29aa50fb48c741040971aaad
```

Quarante et un octets dans un fichier texte tout simple. C'est tout ce qu'est une branche.

> :information_source:
> Sur un dépôt qui a beaucoup de branches et d'étiquettes, vous pourrez trouver `.git/refs/heads` presque vide et un fichier appelé `.git/packed-refs` à la place. Git empaquette périodiquement ses références dans ce fichier unique pour éviter d'en garder des milliers de minuscules. Même information, stockage plus dense. La commande `git rev-parse master` vous donne la réponse dans les deux cas, et c'est celle que vous devriez utiliser dans un script.

Tout à l'heure, quand nous avons fait `git checkout 49c6166`, Git a affiché un gros message que nous avons choisi d'ignorer. Lisons-le maintenant :

```console
Note: switching to '49c6166'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 49c6166 Rename files to media
```

Voilà ce qu'il nous dit : hé, vous avez choisi de faire un `checkout` non pas sur le sommet d'une branche, mais sur un **commit** spécifique. **HEAD**, la tête, le pointeur de l'état courant, est maintenant « détaché » de sa branche — le fameux **detached head**.

Notez que le conseil de Git lui-même parle ici de `git switch`, pas de `git checkout`. Git vous pousse vers les nouvelles commandes même quand vous avez utilisé l'ancienne.

> :information_source: nous pouvons faire `git checkout {le-nom-d-une-branche}` parce que la branche n'est qu'un pointeur vers un **commit** ; donc `git checkout master` nous ramène au sommet de notre arbre, à notre dernier **commit**.


## Nous sommes-nous vraiment trompés ? Repartir propre avec `git reset`

Nous avons déjà pu revenir dans le passé avec `git checkout`, qui a mis notre zone de travail dans l'état d'un commit précédent. Mais nous étions alors dans cet état un peu bizarre. Le **detached head** : HEAD ne pointait plus vers le sommet de notre branche. Si nous le voulions, nous pourrions revenir dans le temps de manière à pouvoir repartir de là.

Imaginons par exemple que toutes ces tergiversations autour du nom de notre répertoire `media` encombrent notre historique, qu'elles n'apportent aucune valeur au futur lecteur de notre code. Ou le fait que nous avons ajouté le fichier LICENSE juste pour le supprimer ensuite ?

Notre historique actuel — cette fois avec un format compact d'une ligne par commit, qui est la manière dont vous voudrez généralement le regarder :

```console
git log --graph --pretty=format:'%h - (%ad) %s - %an%d' --date=short
```

```console
* 4b8243a - (2026-02-02) added git log command - Ori Pekelman (HEAD -> master)
* 49c6166 - (2026-02-02) Rename files to media - Ori Pekelman
* 17baa68 - (2026-02-02) Remove license file - Ori Pekelman
* 1368877 - (2026-02-02) Add .gitkeep so files will be added to the repository - Ori Pekelman
* cabdb6f - (2026-02-02) Adding a license file - Ori Pekelman
* 72c4234 - (2026-02-02) Add the list of commands we learned today. - Ori Pekelman
* 0ab682b - (2026-02-02) Added readme.md - Ori Pekelman
```

Assurez-vous d'être revenu sur la branche (`git checkout master`) avant ce qui suit. Puis :

```console
git reset 72c4234
```

Ceci remet **HEAD** sur ce commit et — contrairement à `git checkout` — entraîne la branche **master** avec lui. Mais notre zone de travail est laissée exactement telle quelle. Git nous le dit d'ailleurs :

```console
Unstaged changes after reset:
M	readme.md
```

et un `git status` nous dira :

```console
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   readme.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	media/

no changes added to commit (use "git add" and/or "git commit -a")
```

Tout ce que nous *voulions* vraiment est toujours sur le disque : le readme avec ses cinq points, et le répertoire `media`. Les quatre commits intermédiaires, c'est ce que nous avons jeté. Nous pouvons maintenant créer de nouveaux **commit**s, propres :

```console
git add readme.md
git commit -m'Add git log to the list of commands we learned'
git add media
git commit -m'Add media directory with .gitkeep'
```

Maintenant notre historique est beaucoup plus propre :

```console
* 4d48f63 - (2026-02-02) Add media directory with .gitkeep - Ori Pekelman (HEAD -> master)
* a07690f - (2026-02-02) Add git log to the list of commands we learned - Ori Pekelman
* 72c4234 - (2026-02-02) Add the list of commands we learned today. - Ori Pekelman
* 0ab682b - (2026-02-02) Added readme.md - Ori Pekelman
```

Remarquez que les deux commits les plus anciens ont gardé leurs hashes — `0ab682b` et `72c4234` sont intacts, nous ne les avons jamais réécrits — tandis que tout ce qui suit le point de reset est flambant neuf. Un commit-id dépend de son parent, donc réécrire l'historique donne nécessairement à chaque descendant une nouvelle identité. Retenez cela ; c'est toute la raison pour laquelle l'avertissement ci-dessous importe.

Dans ce cas, nous voulions revenir à un état précédent tout en gardant les changements que nous avions faits. Mais si nous voulons vraiment nous débarrasser de nos derniers commits ? Nous pouvons faire un reset dur avec `git reset --hard`.

Ainsi, `git reset --hard 0ab682b` nous ramènera à notre état initial, avec un unique fichier `readme.md` qui aura une seule ligne de contenu. Parfois il est agréable de se débarrasser du poids du passé.

> :warning:
> `git reset --hard` est l'une des très rares commandes Git qui détruisent réellement du travail : tout changement dans votre répertoire de travail que vous n'aviez pas validé est perdu, et aucune commande `git` ne le ramènera. Le travail validé est récupérable pendant un certain temps — `git reflog` se souvient des endroits où **HEAD** est passé, donc un `git reset --hard` vers un commit-id que vous y trouvez répare les dégâts — mais le travail non validé n'est pas dans Git du tout, et Git ne peut donc pas vous aider. Committez avant d'expérimenter.

> :warning: Nous allons parler de collaboration plus loin, mais notons quelque chose tout de suite. Quand nous travaillons seuls, sur un dépôt qui nous appartient, sur une branche qui nous appartient, réécrire le passé est agréable et utile. Mais quand nous commençons à travailler avec d'autres, nous n'aurons pas le même luxe : les commits que vos collègues ont déjà récupérés doivent garder leur identité, et comme nous venons de le voir, un reset en donne une nouvelle à chaque commit descendant. Le passé, c'est le passé. Nous avons d'autres commandes Git qui permettent de défaire des choses tout en gardant un historique commun, comme `git revert`, que nous verrons plus tard.

## Récapitulatif : jouer avec l'historique

* `git log` nous permet de voir la liste des **commit**s dans le passé, la liste des révisions
* `git diff` nous permet de voir les changements introduits dans un **commit**
* `git blame` nous permet d'inspecter un fichier et de voir quelle ligne a été modifiée par quel **commit**
* `git show` nous permet d'inspecter un **commit**, mais aussi un **tree** ou un **blob**
* **master** est une branche de notre code, celle que `git init` crée ; `git config --global init.defaultBranch main` fait démarrer les nouveaux dépôts sur **main** à la place, ce qui est ce que font GitHub et GitLab
* **detached head** est la situation où notre pointeur **HEAD** ne pointe pas vers le dernier commit d'une branche
* `git checkout {commit}` déplace le pointeur **HEAD** vers un **commit** spécifique et remet notre répertoire de travail dans l'état qu'il avait au moment de ce commit
* `git switch` et `git restore` (Git 2.23+) séparent en deux les deux métiers de `git checkout` : `git switch` change de branche ou de commit, `git restore` remet des fichiers en place
* `git reset {commit}` déplace **HEAD** comme le fait `git checkout`, mais entraîne aussi la pointe de notre **branche** vers ce commit, en gardant les changements dans notre répertoire de travail
* `git reset --hard {commit}` fait la même chose en jetant tous nos changements non validés dans le répertoire de travail
