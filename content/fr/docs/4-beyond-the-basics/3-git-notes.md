---
title: Détourner git notes pour le plaisir et le profit
slug: "git-notes"
weight: 33
---
# Détourner git notes pour le plaisir et le profit

Un **commit** est immuable. La partie 1 l'a martelé : changez un octet du message, un caractère du
nom de l'auteur, et vous obtenez un **SHA** différent, un objet différent, un commit différent. Ce
n'est pas un bogue, c'est tout le propos. L'identité *est* le contenu.

Mais des informations sur un commit continuent d'arriver après que le commit existe. Celui-ci a été
relu par Sophie. Celui-là a passé l'intégration continue en 4 min 12 s et a produit un artefact
d'empreinte `sha256:9f2a1c`. Celui-ci est parti en production mardi à 18 h 22. Celui-là, trois
semaines plus tard, s'est révélé être la cause de l'incident INC-482. Celui-ci a été écrit par un
agent, à partir d'une invite que nous aimerions bien conserver.

Rien de tout cela n'était connu quand nous avons tapé `git commit`. Et nous ne pouvons pas faire un
`git commit --amend` pour l'ajouter, parce qu'amender fabrique un *nouveau* commit et rend orphelin
tout ce qui suit. Réécrire l'histoire afin d'enregistrer l'histoire est une mauvaise blague.

`git notes` est la réponse de Git : attacher des métadonnées mutables à un objet immuable, sans
toucher à l'objet.

C'est la partie de Git qui donne l'impression de trouver une porte au fond de l'armoire. Puis vous
la franchissez et remarquez que personne n'est venu ici depuis dix ans, que l'interrupteur ne marche
pas, et qu'il y a des raisons à cela. Nous ferons les deux moitiés honnêtement : d'abord le plaisir,
puis les réserves — et les réserves ne sont pas décoratives.

## Notre première note

Nous sommes dans un petit dépôt à trois **commits** — `eacb04c` « Added readme.md », `6ca3554`
« Adding a license file », et à la pointe `d688689` « Add pretty red button to shopping cart ».
Attachons quelque chose à la pointe. Pas de sortie, pas de cérémonie :

```console
git notes add -m 'Reviewed-by: Sophie <sophie@example.com>' HEAD
```

Maintenant `git log` :

```console
git log -1

commit d68868997648ff6e3e6ae505743b668f7a6d5763
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Mon Mar 2 09:31:00 2026 +0100

    Add pretty red button to shopping cart

Notes:
    Reviewed-by: Sophie <sophie@example.com>
```

Un bloc `Notes:`, indenté comme le message mais qui n'*est* pas le message. L'identifiant du commit
est inchangé — `d688689` avant, `d688689` après. Nous avons ajouté de l'information à un commit sans
changer le commit.

Les notes s'accumulent. `append` ajoute un paragraphe, et `git notes edit` ouvre la note dans votre
éditeur :

```console
git notes append -m 'Deployed-to: production 2026-03-04' HEAD
git notes show HEAD

Reviewed-by: Sophie <sophie@example.com>

Deployed-to: production 2026-03-04
```

`git notes list` montre tous les objets annotés :

```console
git notes list

e8d2354ee95b6fd191c28e0ca02f1bea96ab3add d68868997648ff6e3e6ae505743b668f7a6d5763
```

Deux **SHA**. Le second, nous le reconnaissons — c'est notre commit. Le premier est autre chose, et
c'est la moitié intéressante. Gardez cette pensée trente secondes.

`git show` affiche aussi les notes, et tout ce qui est bâti sur la machinerie du log également. D'où
notre première petite surprise : les notes sont affichées *par défaut*, si bien qu'à l'instant où
vous en ajoutez une, la sortie de `git log` de vos collègues change de forme. `git log --no-notes`
la désactive pour une invocation. Et quand vous utilisez `--format`, les notes ne sont *pas*
incluses à moins de les demander avec `%N` — le substitut sur lequel repose tout usage astucieux des
notes. Retenez-le, nous y reviendrons.

## Sous le capot : il n'y a pas de fonctionnalité ici

Maintenant la bonne partie. `git notes` n'est pas un sous-système boulonné sur Git. C'est le modèle
d'objets de la partie 1, pointé sur lui-même.

Les notes vivent dans une **référence**, et par défaut cette référence est `refs/notes/commits` :

```console
cat .git/refs/notes/commits

5d46e022bad174733a2199ec500e37419dc28d3b
```

Un fichier sous `.git/refs` contenant quarante caractères, exactement comme `.git/refs/heads/master`
— et `git rev-parse refs/notes/commits` est d'accord. Alors, quel genre d'objet est `5d46e02` ?

```console
git cat-file -p refs/notes/commits

tree 9593c7973ed478fc32d0b5bd16ac511ee1d27104
parent 22475090ba59acd210c74bb247c49c31ac5e4495
author Ori Pekelman <ori+git-training@pekelman.com> 1772445600 +0100
committer Ori Pekelman <ori+git-training@pekelman.com> 1772445600 +0100

Notes added by 'git notes append'
```

Un **commit** ordinaire. Arbre, parent, auteur, committer, message — Git a écrit le message pour
nous, et c'est la seule chose inhabituelle à son sujet. Il a un **arbre** :

```console
git ls-tree refs/notes/commits

100644 blob e8d2354ee95b6fd191c28e0ca02f1bea96ab3add	d68868997648ff6e3e6ae505743b668f7a6d5763
```

Asseyez-vous une seconde avec ceci. Une seule entrée, et le *nom de fichier* est
`d68868997648ff6e3e6ae505743b668f7a6d5763` — le **SHA** du commit que nous avons annoté. La note
attachée au commit `d688689` est littéralement un fichier *nommé* `d688689…`. Et le **blob** est la
note :

```console
git cat-file -p e8d2354ee95b6fd191c28e0ca02f1bea96ab3add

Reviewed-by: Sophie <sophie@example.com>

Deployed-to: production 2026-03-04
```

Voilà tout le mécanisme. Une référence de notes est une branche dont l'arbre, si vous l'extrayiez,
serait un répertoire plein de fichiers nommés d'après des identifiants d'objets, chacun contenant du
texte libre. `git notes` est une enveloppe de confort au-dessus de `git hash-object`, `git mktree`
et `git commit-tree`. Il n'y a pas de cinquième type d'objet. Il n'y en a jamais eu. (Et maintenant
la sortie de `git notes list` prend son sens : elle affiche `<blob-de-note> <objet-annoté>`, les deux
mêmes SHA que la ligne du `ls-tree`.)

### Les notes ont un historique

Si la référence de notes est une branche de commits, elle a un **log** :

```console
git log --oneline refs/notes/commits

5d46e02 Notes added by 'git notes append'
2247509 Notes added by 'git notes add'
```

Un commit pour notre `add`, un pour notre `append`. *Chaque* opération sur les notes écrit un commit.
Et puisque ce sont des commits, nous pouvons comparer nos métadonnées dans le temps :

```console
git diff 2247509 5d46e02

diff --git a/d68868997648ff6e3e6ae505743b668f7a6d5763 b/d68868997648ff6e3e6ae505743b668f7a6d5763
index afa2012..e8d2354 100644
--- a/d68868997648ff6e3e6ae505743b668f7a6d5763
+++ b/d68868997648ff6e3e6ae505743b668f7a6d5763
@@ -1 +1,3 @@
 Reviewed-by: Sophie <sophie@example.com>
+
+Deployed-to: production 2026-03-04
```

Un diff dont le nom de fichier est un identifiant de commit. Si cela ne vous fait pas sourire un
peu, ce chapitre n'est peut-être pas pour vous.

La conséquence pratique : **les notes sont versionnées**, donc une note supprimée est récupérable.
Annotons le commit du milieu, puis détruisons-le :

```console
git notes add -m 'CI: build 3391 passed in 4m12s' HEAD~1
git notes remove HEAD~1

Removing note for object HEAD~1

git notes show HEAD~1

error: no note found for object 6ca3554109e26e6a8571d9a5d7e4966d8b00d025.
```

Disparue. Est-ce le bon moment pour paniquer ? Non. Vous ne devriez jamais paniquer. La référence de
notes a un reflog et l'ancien arbre est toujours un objet, alors nous demandons un *chemin* à
l'intérieur d'une révision précédente de l'arbre de notes — le chemin étant le SHA du commit
annoté :

```console
git show 'refs/notes/commits@{1}:6ca3554109e26e6a8571d9a5d7e4966d8b00d025'

CI: build 3391 passed in 4m12s
```

Et `git update-ref refs/notes/commits refs/notes/commits@{1}` remet tout l'état précédent en place.
Un `git update-ref` sur une référence de notes, parce que ce n'est qu'une référence.

### L'éclatement

Un seul arbre plat avec une entrée par objet annoté convient pour quelques dizaines de notes. Il ne
convient pas pour cinquante mille : un objet arbre est un unique bloc d'octets qu'il faut réécrire
en entier à chaque changement. Alors Git éclate, exactement comme `.git/objects`. Dans un dépôt où
nous avons fait 400 commits en donnant une note à chacun :

```console
git ls-tree refs/notes/commits | head -3

040000 tree 6d8eb7fd415526489c6e3cb46abb3437ec4f989c	00
040000 tree 46d2b9d94a9d1090a106fc1200f6c3c27ca39f4b	03
040000 tree 87eee3c9c82d836a0b90e316216e56c54eeb6941	07
```

Deux chiffres hexadécimaux de répertoire, le reste comme nom de fichier. Lors de notre essai, le
passage du plat à l'éclaté s'est produit à l'arrivée de la 58e note. Git décide tout seul, les deux
formes sont valides et peuvent coexister, et le seuil exact est un détail d'implémentation sur lequel
il ne faut rien bâtir.

Est-ce que cela passe à l'échelle ? Voici la véritable référence de notes du projet Git lui-même, qui
associe chaque commit au message de liste de diffusion dont il est issu :

```console
git fetch --depth=1 https://github.com/git/git.git 'refs/notes/amlog:refs/notes/amlog'
git ls-tree -r refs/notes/amlog | wc -l

   40030

git ls-tree -r refs/notes/amlog | sed -n '20000p'

100644 blob e8905b07b71a4bae63b2c474efadf70152c46af1	7f/42/31229dd54f4094efefd8a4f62bccf6f53c9d

git cat-file -p e8905b07b71a4bae63b2c474efadf70152c46af1

Message-Id: <3a41ad889cc33a1fc0414b8f14af6438b49c88ee.1723886761.git.gitgitgadget@gmail.com>
```

Quarante mille notes, deux niveaux d'éclatement, maintenues pendant des années par le mainteneur de
Git. La mise à l'échelle n'est pas le problème des notes.

## Les espaces de noms : la fonctionnalité que personne ne connaît

`refs/notes/commits` n'est que le *défaut*. N'importe quel `refs/notes/<ce-que-vous-voulez>` est une
référence de notes, et chacune est un arbre indépendant. C'est ce qui rend les notes véritablement
utiles, et c'est la chose la moins connue à leur sujet.

```console
git notes --ref=ci add -m '{"build":3391,"duration_s":252,"result":"pass","artifact":"sha256:9f2a1c"}' HEAD
git notes --ref=ci add -m '{"build":3388,"duration_s":261,"result":"pass","artifact":"sha256:1bd4e0"}' HEAD~1
git notes --ref=ci add -m '{"build":3385,"duration_s":249,"result":"fail","artifact":null}' HEAD~2
git notes --ref=deploys add -m 'env=production at=2026-03-04T18:22:11Z by=ori rollback-to=6ca3554' HEAD

git for-each-ref refs/notes

85eb48c17708f90719b062903c657c6f658f0ad4 commit	refs/notes/ci
37331e01dfcf9c686a226281393dc0992e33a911 commit	refs/notes/commits
02998e9b79b9467dc27d5cfb1fb2c8f538ecba53 commit	refs/notes/deploys
```

`--ref=ci` veut dire `refs/notes/ci` ; le préfixe est ajouté pour vous. Trois petites bases de
données indépendantes — et `git log` n'affiche que celle par défaut, sauf si nous demandons :

```console
git log -1 --oneline --notes=ci --notes=deploys

d688689 Add pretty red button to shopping cart
Notes (ci):
    {"build":3391,"duration_s":252,"result":"pass","artifact":"sha256:9f2a1c"}

Notes (deploys):
    env=production at=2026-03-04T18:22:11Z by=ori rollback-to=6ca3554
```

Les boutons de réglage, dont la place est dans votre configuration plutôt que dans vos doigts :

* `core.notesRef` — quelle référence `git notes` lit et écrit par défaut (`git notes get-ref`
  affiche l'actuelle ; `GIT_NOTES_REF` fait la même chose dans l'environnement).
* `notes.displayRef` — quelles références `git log` *affiche*, et cela accepte des jokers :
  `git config notes.displayRef 'refs/notes/*'`. Réglez-le une fois et tous les espaces de noms
  apparaissent dans votre log.
* `--notes=<réf>`, `--notes='*'` et `--no-notes` pour une invocation.

## Vous pouvez annoter n'importe quoi

Les notes s'attachent à des *objets*, pas à des commits. L'entrée d'arbre est un nom de fichier, et
tout identifiant d'objet fait un nom de fichier valide. Alors annotons un **blob** :

```console
git notes --ref=provenance add -m 'Generated by an agent from prompt: "make the cart button red"' $(git rev-parse HEAD:style.css)
git ls-tree refs/notes/provenance

100644 blob d67def0628781ef5fb38669b60b1453f71f2cbc7	d9ef44daba3c84a1e7213ec3f231f03f57d7c63a
```

`d9ef44d` n'est pas un commit — c'est le contenu de `style.css`. Nous avons annoté une *version de
fichier*, et cette annotation suit ce contenu exact dans chaque branche et chaque clone qui le
détiendra jamais. La même chose fonctionne sur un **arbre**, et sur un objet **étiquette** annotée :
`git notes --ref=provenance add -m 'Signed off by legal' $(git rev-parse v0.1)`.

> :warning:
> Ravissant, et à moitié pris en charge. `git log` et `git show` n'*affichent* les notes que
> lorsqu'ils montrent un commit. `git show <blob>` affiche le contenu du fichier et ne dit rien de
> votre magnifique note. Pour lire des notes sur d'autres objets, vous utilisez
> `git notes show <objet>`, ou vous passez sous le capot avec `git ls-tree` et `git cat-file`. Rien
> d'autre dans l'écosystème ne les fera remonter pour vous.

## Le plaisir et le profit

Maintenant que nous savons que ce ne sont que des arbres et des blobs, voici à quoi servent
réellement les notes.

**Les métadonnées d'intégration continue et de construction.** L'usage canonique, et celui pour
lequel les notes sont véritablement bonnes. Le système de construction connaît l'identifiant du
commit, et il connaît le numéro de build, la durée, l'empreinte de l'artefact, le nombre de tests —
alors il les écrit sur ce commit exact. Pas de table joignant un SHA à un build, pas d'URL qui
expire : les métadonnées voyagent avec le dépôt.

**Les enregistrements de revue de code.** Pas hypothétique. Le greffon `reviewnotes` de Gerrit écrit
des métadonnées de revue dans `refs/notes/review` : `Submitted-by:`, `Submitted-at:`, `Reviewed-on:`
avec un lien vers le changement, `Code-Review+2:` par relecteur, `Comments-Total:`,
`Comments-Unresolved:`. C'est un greffon plutôt que du Gerrit de base depuis la 2.6, et il n'est pas
récupéré par défaut (petite anticipation) — mais il existe, en production, à l'échelle.

**La provenance des déploiements et l'annotation rétroactive** — la seconde étant ce que les messages
de commit ne peuvent structurellement pas faire, parce que la vérité est arrivée plus tard :

```console
git notes --ref=deploys append -m 'env=production at=2026-03-05T09:40:00Z by=bob rollback-to=6ca3554' HEAD
git notes --ref=incidents add -m 'Root cause of INC-482. Reverted by 9f2a1c3.' 6ca3554
git notes --ref=papers add -m 'Figure 3 of the preprint was generated from this commit.' eacb04c
```

**Faire suivre une note à travers un cherry-pick.** `git notes copy` déplace une annotation d'un
objet à un autre. Nous avons cherry-pické un correctif urgent (`380015b`) sur `master`, et le nouveau
commit n'a pas de note, donc :

```console
git notes --ref=ci copy 380015b HEAD
git notes --ref=ci list

cec5a2aa204a87d381914d163a162f157ea31fe6 380015bf6aae44b48f8773f0e050508b79c3654f
cec5a2aa204a87d381914d163a162f157ea31fe6 c4772c92069db44285928750a3671487456aa407
```

Regardez attentivement : deux commits annotés, *un* blob de note. Le stockage adressé par contenu ne
stocke pas deux fois la même note, donc copier une note coûte une entrée d'arbre. (Copier sur un
objet qui a déjà une note est refusé à moins d'ajouter `-f`.)

**Faire suivre les notes à travers une réécriture, automatiquement.** Par défaut,
`git commit --amend` et `git rebase` n'emportent *pas* vos notes — la note reste collée à l'ancien
commit, désormais orphelin, et `git notes list` continue gaiement de pointer vers un SHA que
personne ne référence. Ce comportement est piloté par la configuration, et la configuration est
désactivée à la sortie de la boîte :

```console
git config notes.rewriteRef 'refs/notes/*'
git rebase master
git notes show HEAD

CI: build 43 passed
```

Apparentés : `notes.rewrite.amend` et `notes.rewrite.rebase` (tous deux à vrai par défaut, mais sans
effet tant que `notes.rewriteRef` n'est pas réglé) et `notes.rewriteMode` (`concatenate` par défaut ;
aussi `overwrite`, `cat_sort_uniq`, `ignore`) pour quand la cible a déjà une note. Si vous utilisez
les notes, réglez `notes.rewriteRef`. C'est la différence entre des notes qui survivent à votre
méthode de travail et des notes qui s'évaporent à la première fois où vous rangez une branche.

**Des données structurées, et les interroger.** Rien n'empêche de mettre du JSON dans une note, et
`%N` le ressort. Le `grep .` supprime les lignes vides qu'émet `%N` pour les commits non annotés :

```console
git log --format='%h %N' --notes=ci | grep .

d688689 {"build":3391,"duration_s":252,"result":"pass","artifact":"sha256:9f2a1c"}
6ca3554 {"build":3388,"duration_s":261,"result":"pass","artifact":"sha256:1bd4e0"}
eacb04c {"build":3385,"duration_s":249,"result":"fail","artifact":null}
```

À partir de là, ce n'est que de l'Unix — `git log --format='%h %s %N' --notes=ci | grep
'"result":"fail"'` liste les commits dont la construction a échoué, et avec `jq` nous pouvons aller
plus loin :

```console
git log --format='%N' --notes=ci | grep . | jq -s 'map(.duration_s) | add / length'

254
```

La durée moyenne de construction sur l'historique d'une branche, calculée depuis le dépôt, hors
ligne, sans qu'aucun serveur de construction ne soit impliqué. Voilà une chose véritablement
agréable à pouvoir faire.

**La provenance des agents et de l'IA.** Les notes conviennent à cela mieux que la plupart des
solutions de rechange. Quand un commit est produit par un agent, il y a des métadonnées qu'un lecteur
humain du log ne veut pas dans le message : l'invite, l'identifiant du modèle, la version de l'outil,
lequel de cinq correctifs candidats a été retenu, le verdict de la relecture. Mettez cela dans
`refs/notes/agent` et le message de commit reste un message de commit. Cela se compose avec les
arbres de travail par agent de
[Arbres de travail et agents](2-git-worktree-agents.md "Arbres de travail et agents") — le harnais
écrit la note, l'humain lit le message. Rien ici n'est magique et rien n'est une pratique établie ;
c'est un endroit raisonnable où mettre du contexte généré par une machine, et c'est un domaine qui
bouge vite.

**Les attestations.** Les notes sont un endroit populaire où ranger des déclarations signées — des
SBOM, de la provenance, des résultats d'analyse. Très bien, avec une réserve que les gens manquent :
une note n'est pas signée du fait d'être une note. Les *commits* de notes peuvent être signés comme
n'importe quel autre commit, et la charge utile peut être une signature détachée que vous vérifiez
vous-même, mais une note ordinaire n'a pas plus d'autorité qu'un fichier texte.

**Le tour de passe-passe.** Puisqu'une référence de notes est un arbre de fichiers nommés d'après des
identifiants d'objets, vous pouvez la détourner en un minuscule magasin clé/valeur à l'intérieur du
dépôt. Les clés doivent être des identifiants d'objets — alors faites-les en devenir :

```console
KEY=$(printf 'deploy-target' | git hash-object -w --stdin)
git notes --ref=kv add -m 'eu-west-1' $KEY
git notes --ref=kv show $(printf 'deploy-target' | git hash-object --stdin)

eu-west-1
```

On hache la clé en un blob, on annote le blob, on la retrouve en rehachant la clé. Cela fonctionne,
c'est versionné, cela se réplique gratuitement — et c'est complètement dérangé ; un fichier YAML dans
l'arbre vaut mieux à tous égards. Mais `refs/notes/*` n'est qu'un espace de noms, et Git est plein de
gens qui font ce genre de chose : `refs/replace` pour la substitution d'objets, `refs/stash` pour les
remises, `refs/pull/*` sur GitHub pour les têtes de pull requests. Personne n'a promis que l'espace
de noms des références resterait bien rangé.

## Les réserves, qui ne sont pas petites

Tout ce qui précède est vrai. Voici pourquoi presque personne n'utilise les notes, et pourquoi c'est
en partie mérité.

### Les notes ne sont ni récupérées ni poussées

Voilà le coup fatal. `git clone` n'apporte pas les notes. `git fetch` ne les met pas à jour.
`git push` ne les envoie pas. Les refspecs par défaut couvrent `refs/heads/*` et les étiquettes, point
final.

Clonez un dépôt dont le serveur détient quatre références de notes, lancez `git notes list`, et vous
n'obtenez rien. Pas une erreur — *rien*. Il faut demander, par leur nom, avec une **refspec** :

```console
git fetch origin 'refs/notes/*:refs/notes/*'

From ../origin
 * [new ref]         refs/notes/ci         -> refs/notes/ci
 * [new ref]         refs/notes/commits    -> refs/notes/commits
 * [new ref]         refs/notes/deploys    -> refs/notes/deploys
 * [new ref]         refs/notes/provenance -> refs/notes/provenance
```

Pour rendre cela permanent, ajoutez une seconde ligne `fetch` au dépôt distant dans `.git/config` :

```console
git config --add remote.origin.fetch '+refs/notes/*:refs/notes/*'

[remote "origin"]
	url = ../origin.git
	fetch = +refs/heads/*:refs/remotes/origin/*
	fetch = +refs/notes/*:refs/notes/*
```

Pousser en est l'image miroir — `git push origin 'refs/notes/*:refs/notes/*'`, qui signale
` * [new reference]   refs/notes/ci -> refs/notes/ci` et compagnie. Vous pouvez mettre cela dans une
refspec `push` aussi, mais faites-le en connaissance de cause : cela veut dire que chaque espace de
noms de votre machine monte à chaque fois.

Ce seul défaut est, j'en suis à peu près sûr, toute l'explication du peu d'amour porté aux notes.
Quelqu'un les essaie, elles fonctionnent à merveille, il pousse, un collègue clone, les notes n'y
sont pas, et la conclusion raisonnable est « git notes ne marche pas ». Si, ça marche. C'est
simplement invisible tant que chaque participant n'a pas édité sa configuration.

> :warning:
> Remarquez le `+` de cette refspec de récupération : il veut dire *force*. Si vous récupérez
> `+refs/notes/*:refs/notes/*` alors que vous détenez des notes locales que le serveur n'a pas, votre
> référence de notes locale est écrasée et votre travail ne survit que dans le reflog. Nous nous
> sommes fait exactement cela en écrivant ce chapitre. Plus sûr : récupérez dans un espace de noms
> latéral avec `git fetch origin 'refs/notes/*:refs/notes/remote/*'` et fusionnez délibérément.

### Fusionner des notes est une vraie opération avec de vrais conflits

Deux personnes annotent le même commit dans le même espace de noms et les références de notes
divergent. Bob pousse en second :

```console
git push origin 'refs/notes/deploys:refs/notes/deploys'

 ! [rejected]        refs/notes/deploys -> refs/notes/deploys (fetch first)
error: failed to push some refs to '../origin.git'
```

Pas d'avance rapide, exactement comme une branche, parce que c'*est* une branche. Alors Bob récupère
la leur de côté et fusionne :

```console
git fetch origin 'refs/notes/deploys:refs/notes/theirs'
git notes --ref=deploys merge refs/notes/theirs

Automatic notes merge failed. Fix conflicts in .git/NOTES_MERGE_WORKTREE and commit the result with 'git notes merge --commit', or abort the merge with 'git notes merge --abort'.
Auto-merging notes for d68868997648ff6e3e6ae505743b668f7a6d5763
CONFLICT (content): Merge conflict in notes for object d68868997648ff6e3e6ae505743b668f7a6d5763
```

Il y a tout un arbre de travail de conflit, dans un répertoire que vous n'avez jamais regardé,
contenant un fichier par note en conflit — nommé, bien sûr, d'après le commit annoté :

```console
cat .git/NOTES_MERGE_WORKTREE/*

env=production at=2026-03-04T18:22:11Z by=ori rollback-to=6ca3554

env=staging at=2026-03-05T08:02:00Z by=alice

<<<<<<< refs/notes/deploys
env=production at=2026-03-05T09:40:00Z by=bob
=======
env=staging at=2026-03-05T08:02:00Z by=alice
>>>>>>> refs/notes/theirs
```

Vous l'éditez, puis `git notes merge --commit` — ou `git notes merge --abort`.

Les stratégies (`-s`, ou `notes.mergeStrategy`) sont `manual` (le défaut, ci-dessus), `ours`,
`theirs`, `union` et `cat_sort_uniq`. Pour des journaux en ajout seul — déploiements, constructions,
résultats d'analyse — `union` est en général ce que vous voulez. Mais il n'y a pas de repas gratuit :
`union` est une *concaténation bête*, donc les paragraphes que les deux côtés partageaient déjà
apparaissent deux fois dans le résultat. Et `cat_sort_uniq` déduplique, au prix d'un tri de vos
lignes : fusionner deux journaux de déploiement de cette façon nous a donné `deployed: canary`,
`deployed: production`, `deployed: staging` — une jolie liste alphabétique de choses qui se sont
produites dans un tout autre ordre. Choisissez votre poison, et préférez un seul rédacteur par espace
de noms si vous pouvez vous arranger ainsi.

### Les forges ne les affichent pas

GitHub n'affiche pas les notes. Il l'a fait autrefois : la fonctionnalité a été annoncée en août 2010
— les notes apparaissaient au bas du diff d'un commit — et ce même billet de blog porte aujourd'hui
une mise à jour datée du 14 août 2014 disant que l'affichage des notes Git n'est plus pris en charge.
Les demandes de retour sont toujours ouvertes dans les discussions communautaires de GitHub. GitLab
ne les affiche pas non plus, et a des tickets ouverts de longue date qui le réclament. Tous deux
stockeront et serviront parfaitement les références — vous pouvez pousser et récupérer des notes chez
l'un comme chez l'autre — mais l'interface web est muette.

Sans détour : si la source de vérité de votre équipe est une interface web, les notes sont
invisibles, et les métadonnées invisibles pourrissent. Six mois plus tard la moitié est fausse et
personne ne le sait, parce que personne ne les a jamais vues.

Il existe une version plus petite et plus drôle du même problème : les commits de notes sont des
commits qui vivent dans `refs/`, si bien qu'un `git log --all` dans notre petit dépôt de trois
commits en liste maintenant seize, dont treize avec des messages comme
`Notes added by 'git notes add'` et `Notes removed by 'git notes remove'`. Inoffensif, et une bonne
illustration du peu de Git qui sait ce qu'est une note.

### Rien d'autre ne les lit

`git log`, `git show`, `git notes`. Voilà la liste. La gouttière de blame de votre IDE n'affiche pas
les notes. Votre outil de relecture de PR non plus. `git blame` non plus. Tout ce que vous bâtissez
sur les notes, vous le bâtissez vous-même — en général un script shell et un `--format='%N'`.

### Ce n'est pas une base de données

Pas d'index, pas de langage de requête, pas de transactions, pas de contrôle d'accès. Chaque écriture
réécrit un arbre et ajoute un commit ; deux rédacteurs en course sur une référence, cela veut dire
que l'un d'eux voit son push rejeté et doit fusionner. Les lectures sont un parcours complet de
`git log`, sauf à construire votre propre index.

Quarante mille notes : très bien. Une note par commit et par exécution d'intégration continue : très
bien. Un journal d'événements par requête : absolument pas. Les notes sont un meuble à classeurs, pas
une base de données de séries temporelles.

### Elles sont mutables, ce qui est le propos et le danger

Une note n'est pas une preuve. Quiconque peut pousser sur `refs/notes/*` peut réécrire tout
l'historique des notes, et la seule trace hors de sa propre machine est qu'une référence a bougé sans
avance rapide. `git notes remove`, `git update-ref`, push forcé, et voilà — et le log ensuite a
l'air parfaitement innocent.

Si vous avez besoin de détecter les altérations, il vous faut des signatures : signez les commits de
notes, ou mettez une charge signée dans la note et vérifiez-la vous-même. La note seule ne prouve
rien.

### `git gc` et `git notes prune`

Les notes sont atteignables depuis leur référence, donc les commits de notes et les blobs de notes
sont à l'abri de `git gc`. Supprimez une référence de notes, en revanche, et tout son historique
devient un déchet au prochain `gc`.

L'autre direction est `git notes prune`, qui jette les notes dont l'objet annoté n'existe plus.
Lancez `git notes prune -n` d'abord — il affiche les identifiants d'objets dont les notes
partiraient. Et notez que « n'existe plus » veut dire *vraiment* disparu : un commit inatteignable
qui n'a pas encore été ramassé compte encore comme existant, donc `prune` est une guillotine plus
lente qu'il n'y paraît. Le retrait est lui-même un commit de notes, donc il est récupérable depuis le
reflog aussi longtemps que dure le reflog. Récupérable-pour-l'instant n'est pas la même chose que
sûr.

## Alors, quand devrions-nous réellement utiliser les notes ?

Ma recommandation honnête, après avoir beaucoup joué avec.

**Saisissez-vous des notes quand** les métadonnées sont générées par une machine, produites par de
l'automatisation, consommées par de l'automatisation, dans un dépôt que vous contrôlez de bout en
bout, dans son propre espace de noms avec un seul rédacteur. Résultats d'intégration continue,
provenance des constructions, métadonnées d'agents, correspondances commit-vers-identifiant-externe.
Réglez `notes.rewriteRef`, mettez les refspecs de récupération et de push dans l'outillage plutôt que
de demander à des humains de s'en souvenir, choisissez `union`, et ne laissez jamais deux systèmes
écrire dans le même espace de noms.

**Ne vous saisissez pas des notes quand** un humain doit le voir dans une pull request ; quand cela
doit faire autorité ou résister aux altérations ; quand cela doit survivre à une réécriture ; ou
quand cela doit être visible pour quelqu'un qui a cloné le dépôt et n'a rien configuré.

Pour ces cas-là, les solutions ennuyeuses valent mieux, et le dire est plus utile que de gagner le
débat :

* **Les lignes de fin de message de commit.** `Co-authored-by:`, `Signed-off-by:`, `Reviewed-by:`,
  `Fixes:`, ou votre propre `Build-Id:`. Elles vivent *dans* le message, donc elles sont immuables,
  visibles dans tous les outils et toutes les interfaces de forge, et elles survivent à un clone tout
  neuf sans la moindre configuration. `git interpret-trailers` les écrit et
  `git log --format='%(trailers:key=Fixes)'` les relit. Si l'information existe au moment du commit,
  c'est presque toujours la bonne réponse.
* **Les étiquettes annotées** pour les métadonnées de version : un objet **étiquette** contient un
  message, un étiqueteur, une date et une signature, et les gens poussent déjà les étiquettes par
  habitude.
* **Un système externe indexé par le SHA du commit.** Une table avec une colonne `commit_sha` est
  sans glamour et vous donne des index, des requêtes, des permissions et une piste d'audit. Tous les
  systèmes d'intégration continue de la terre font cela. Ce n'est pas une erreur.
* **Un magasin d'artefacts d'intégration continue** pour tout ce qui est gros, binaire ou volumineux.
  Les rapports de tests n'ont pas leur place dans un objet Git.

Les notes sont une jolie pièce de conception : le modèle d'objets retourné sur lui-même, pas de
concepts nouveaux, toute la puissance des références, des arbres et des blobs braquée sur des
métadonnées. Le mécanisme est excellent. Ce sont les valeurs par défaut, et quinze ans
d'indifférence de l'écosystème, qui le desservent. Apprenez-les, utilisez-les là où elles conviennent,
et ne soyez pas la personne qui a mis le journal de déploiement à un endroit où ses coéquipiers
n'iront jamais regarder.

## Récapitulatif `git notes`

* `git notes add -m'<texte>' <objet>` attache une note mutable à un objet immuable ; `-f` écrase une
  note existante
* `git notes append`, `edit`, `show`, `list`, `copy`, `remove`, `prune` et `get-ref` sont les autres
  verbes
* `git notes merge <réf>` fusionne deux références de notes divergentes, avec
  `-s manual|ours|theirs|union|cat_sort_uniq` ; les conflits manuels atterrissent dans
  `.git/NOTES_MERGE_WORKTREE` et se terminent par `git notes merge --commit` ou `--abort`
* **référence de notes** — les notes vivent dans `refs/notes/commits` par défaut, ou
  `refs/notes/<n'importe quoi>` avec `--ref=<nom>`. C'est une référence ordinaire qui pointe vers un
  **commit** ordinaire, dont l'**arbre** a une entrée par objet annoté : le *nom de fichier* est le
  **SHA** de l'objet et le **blob** est le texte de la note
* Chaque opération sur les notes crée un commit, donc `git log -p refs/notes/commits` est l'historique
  de vos métadonnées, et `refs/notes/commits@{1}` récupère ce que vous venez de supprimer
* Les arbres de notes **s'éclatent** automatiquement en sous-répertoires `ab/cdef…` à mesure qu'ils
  grossissent, comme `.git/objects`
* Les notes peuvent annoter **n'importe quel** objet — **commit**, **blob**, **arbre**, **étiquette**
  — mais seuls les commits les voient affichées automatiquement
* `git log --notes=<réf>`, `--notes='*'`, `--no-notes` et `--format='%N'` contrôlent et extraient les
  notes ; `core.notesRef`, `notes.displayRef`, `notes.mergeStrategy`, `notes.rewriteRef` et
  `notes.rewriteMode` sont la configuration
* `notes.rewriteRef` est ce qui fait suivre les notes à travers `git commit --amend` et
  `git rebase` ; sans lui, réécrire l'historique les rend orphelines
* **Les notes ne sont ni clonées, ni récupérées, ni poussées par défaut** — il faut des refspecs
  explicites : `git push origin 'refs/notes/*:refs/notes/*'`, et une ligne
  `fetch = +refs/notes/*:refs/notes/*` dans la configuration du dépôt distant. C'est l'unique raison
  pour laquelle la plupart des gens concluent que les notes ne marchent pas
* Les interfaces web des forges n'affichent pas les notes, presque aucun outil tiers ne les lit, les
  notes sont mutables et donc ne sont pas des preuves, et ce sont un meuble à classeurs plutôt qu'une
  base de données
* Quand les notes sont le mauvais outil, utilisez les **lignes de fin de message de commit**, les
  **étiquettes annotées**, un système externe indexé par le SHA du commit, ou un magasin d'artefacts
  d'intégration continue
