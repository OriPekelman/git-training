---
title: On sait sauvegarder… mais comment modifier ? supprimer ? annuler ?
slug: "modify-delete-files-with-git"
weight: 6
---
# On sait sauvegarder… mais comment modifier ? supprimer ? annuler ?

Rappelons-nous deux choses importantes : le **commit** pointe vers un **tree-id**, donc vers une arborescence et un contenu de fichiers dans un état spécifique, et il pointe aussi vers des **parents**, donc vers des **commit**s précédents (qui, eux, pointent naturellement à leur tour vers des **tree-id**s). Supprimer est donc chose simple : si un fichier est dans le **tree** du **commit** parent mais pas dans le **tree** de notre **commit** actuel, alors ce fichier a été supprimé.

## Supprimer un fichier avec Git

Nous pouvons tester ça. Disons que nous ne souhaitons plus avoir le fichier LICENSE.

```console
rm LICENSE
```

Maintenant `git status` va nous dire :

```console
On branch master
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	deleted:    LICENSE

no changes added to commit (use "git add" and/or "git commit -a")
```
Cela veut dire que le fichier LICENSE existe dans l'**index** mais n'existe pas dans la zone de travail. Pour le supprimer, on va devoir ajouter la suppression à l'index. Donc `git add LICENSE`. Puis nous allons appliquer ce changement avec un `git commit -m"Remove license file"`.

```console
[master f2c06df] Remove license file
 1 file changed, 8 deletions(-)
 delete mode 100644 LICENSE
```
Voilà, le fichier a disparu.

> :information_source: Comme nous l'avons compris… tout reste dans l'historique : notre commit actuel pointe vers un objet **tree** dont l'arborescence ne contient pas ce fichier. Mais le **commit** précédent pointe vers un **tree** qui le contient.

Mais tout ceci est fastidieux, et Git nous donne une commande unique qui enlève le fichier de la zone de travail et de l'index d'un seul coup. Ne la lancez pas maintenant — notre LICENSE a déjà disparu, donc elle ne ferait que se plaindre — mais voici ce que nous aurions pu taper à la place du `rm` suivi du `git add` ci-dessus :

```console
git rm LICENSE
```

Elle répond, laconique :

```console
rm 'LICENSE'
```

et laisse la suppression déjà mise en attente, si bien qu'un `git status` montrerait :

```console
On branch master
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	deleted:    LICENSE

```

Donc cette paire :

```console
git rm LICENSE
git commit -m"Remove license file"
```

est parfaitement équivalente à ce que nous venons de faire — à condition que le fichier n'ait pas été modifié (autrement Git va se plaindre et refuser, ce qui est une gentillesse de sa part : il refuse de jeter du travail que vous n'avez sauvegardé nulle part).

## Changer les noms de fichiers et de répertoires

Précisément de la même manière, nous pouvons procéder à des renommages. Mais là, on a tout intérêt à toujours utiliser plutôt la commande intégrée.

Pour changer le nom de notre répertoire `files` en `media`, rien de plus simple :

```console
git mv files media
```

Voilà, un petit `git status` nous dira :

```console
On branch master
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	renamed:    files/.gitkeep -> media/.gitkeep

```
Comme toujours, pour appliquer les changements, un **commit** :

```console
git commit -m'Rename files to media'
```

Qui nous dira :
```console
[master 2937bcc] Rename files to media
 1 file changed, 0 insertions(+), 0 deletions(-)
 rename {files => media}/.gitkeep (100%)
```

> :information_source:
> Remarquez que Git dit *rename*, mais il n'existe rien qui s'appelle un renommage dans un objet Git. `git mv` est une commodité : il déplace le fichier sur le disque et met à jour l'index, et c'est tout. Le commit enregistre simplement un **tree** dans lequel `.gitkeep` se trouve sous `media` au lieu de `files`. Le mot « rename » dans cette sortie, c'est la *détection* de renommage de Git, calculée à la volée en comparant les deux arbres et en remarquant qu'un blob au contenu identique a disparu d'un chemin et est apparu à un autre. C'est aussi pour cela que Git sait repérer les renommages que vous avez effectués avec votre éditeur — à condition que vous lui ayez parlé des deux moitiés.

> :warning: Petite subtilité : Git ignore d'habitude les répertoires vides (souvenez-vous, c'est pour cela que nous avons créé le petit fichier caché `.gitkeep`). Mais ici, si le répertoire `media` existait déjà (qu'il existe dans notre **index** ou non), le résultat de la commande sera différent et notre `files` se retrouvera à l'intérieur de `media`, avec une arborescence comme ceci : `media/files/.gitkeep`.

Nous aurions évidemment pu utiliser les commandes de notre système d'exploitation pour faire le renommage, mais notre historique en eût été moins beau.

```console
mv files media
git status
```

```console
On branch master
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	deleted:    files/.gitkeep

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	media/

no changes added to commit (use "git add" and/or "git commit -a")
```

En effet, à ce stade, Git ne peut pas voir que `files` a changé de nom. Il voit un fichier suivi disparaître, et un répertoire non suivi apparaître. Il nous faudrait mettre en attente les *deux* moitiés — `git add files media`, ou simplement `git add -A` — avant que Git puisse les apparier et appeler cela un renommage.

> :information_source: Nous y reviendrons, mais notre ambition en utilisant Git est de garder un historique « propre ». Cela facilite énormément la collaboration. Donc pour ce qui est de renommer des fichiers et des répertoires dans un dépôt Git, **utilisez toujours `git mv` plutôt que `mv`.**


## Récapitulatif : `git rm` et `git mv`

* `git rm` nous permet de supprimer des fichiers et des répertoires
* `git mv` nous permet de renommer des fichiers et des répertoires
