---
title: Garder un historique propre, se remettre de ses erreurs
slug: "git-cleanup"
weight: 16
---
# Garder un historique propre, se remettre de ses erreurs

C'est le chapitre à mettre en favori.

Tout ce qui précède portait sur le fait de faire les choses exprès. Celui-ci porte sur l'autre moitié de la journée de travail : le moment où votre estomac se noue, où vous fixez le terminal, et où vous pensez *oh non*.

Voici la bonne nouvelle, et elle est plus grande que vous ne le pensez : **Git ne perd presque jamais des données qui ont été committées.** Pas « rarement ». Presque jamais. Un commit est un objet immuable dans `.git/objects`, et Git ne supprime pas les objets quand vous cessez de pointer vers eux — il les garde, pendant des semaines, et il garde un journal de chaque référence que vous avez jamais déplacée. Presque chaque catastrophe de ce chapitre est un problème de *pointeur*, et les pointeurs, on peut les repointer.

Ce chapitre est donc organisé de la manière dont la panique arrive réellement : sous forme d'une phrase que l'on dit à voix haute. Symptôme, puis ce qui s'est réellement passé, puis quoi faire.

## D'abord : ne paniquez pas, et ne fermez pas le terminal

Trois habitudes, avant toutes les recettes.

**Lancez `git status`.** À chaque fois. Git est étonnamment bon pour vous dire où vous êtes et quelles sont vos options — pendant une fusion, pendant un rebase, pendant un cherry-pick, en **detached head**. La plupart des recettes de ce chapitre sont déjà imprimées dans la sortie de `git status`. Lisez-la avant de taper quoi que ce soit.

**Ne fermez pas le terminal.** Votre historique d'affichage contient des **SHA**s qui sont sur le point de devenir précieux. Quand Git a dit `Deleted branch experiment (was 34d8133)`, il vous a tendu la clé de la porte que vous veniez de verrouiller. Recopiez-la quelque part.

**Préférez les commandes qui créent à celles qui détruisent.** `git revert` crée un commit ; `git reset --hard` en jette un. `git branch` crée un nom gratuitement. Quand vous avez peur, prenez l'option réversible — et en cas de doute, faites d'abord une branche de sauvegarde. `git branch panic-backup` ne coûte rien et a sauvé tout le monde au moins une fois.

## « Zut, j'ai fait quelque chose de terriblement mal, dites-moi que Git a une machine à remonter le temps ?! »

Il en a une, et elle s'appelle `git reflog`. Nous l'avons brièvement rencontrée dans [Collaborer grâce à Git](1-collaborate-with-git.md "Collaborer grâce à Git") ; voici à quoi elle sert vraiment.

Chaque fois qu'une référence bouge — chaque commit, checkout, fusion, rebase, reset, amend — Git ajoute une ligne à un journal sous `.git/logs`. Ce journal ne fait pas partie de votre historique. C'est le carnet privé de ce que *vos* pointeurs ont fait, dans l'ordre.

```console
git reflog

03b7787 HEAD@{0}: reset: moving to HEAD~2
62ac72c HEAD@{1}: checkout: moving from master to sale-banner
525030a HEAD@{2}: reset: moving to HEAD~1
3645fbe HEAD@{3}: checkout: moving from sale-banner to master
62ac72c HEAD@{4}: cherry-pick: Fix the currency symbol
eab0f86 HEAD@{5}: checkout: moving from master to sale-banner
```

Lisez-le de haut en bas comme « le plus récent d'abord ». `HEAD@{1}` veut dire « où pointait `HEAD` un déplacement en arrière ». Ce qui nous donne l'annulation la plus utile de Git :

```console
git reset --hard HEAD@{1}
```

« Remets-moi là où j'étais avant ce que je viens de faire. »

D'autres formes à connaître :

* `git reflog <branche>` — le carnet d'une branche plutôt que celui de `HEAD`. `git reflog master`.
* `master@{1}`, `master@{5}` — où pointait cette branche N déplacements en arrière.
* `HEAD@{2.hours.ago}`, `master@{yesterday}` — par le temps, et oui, cette syntaxe fonctionne vraiment.
* `git log -g` — la même information au format `git log`, avec les dates et les messages complets.

> :information_source: Les entrées du reflog expirent : 90 jours par défaut pour les commits atteignables, 30 pour les inatteignables (`gc.reflogExpire`, `gc.reflogExpireUnreachable`). Passé ce délai, un `git gc` peut véritablement supprimer les objets. En pratique, cela veut dire que vous avez des semaines, pas des minutes. Mais le reflog est **local** : il n'existe pas dans un clone tout frais et il n'est jamais poussé. Le dépôt de quelqu'un d'autre ne peut pas sauver votre reflog.

> :warning: Le reflog ne connaît que les choses qui ont été *committées* — ou mises de côté par un stash. Il n'a aucune idée de ce qui était dans votre éditeur.

## « Mince, j'ai committé et j'ai immédiatement réalisé qu'il fallait faire une petite correction ! »

**Ce qui s'est passé :** rien de grave. Vous avez fait un commit il y a trente secondes et personne ne l'a vu.

**Quoi faire :** faites la correction, indexez-la, et fondez-la dans le commit que vous venez de faire.

```console
# corriger la chose
git add lib/search.js
git commit --amend --no-edit
```

`--no-edit` garde le message existant et saute votre éditeur. Comme nous l'avons vu dans [le chapitre précédent](5-git-workflow.md "Mettre en œuvre un workflow collaboratif efficace"), `--amend` ne modifie pas le commit — il en construit un nouveau et y déplace la branche, donc le **SHA** change. L'ancien commit est toujours dans le reflog.

Le cas classique est le fichier oublié :

```console
git add lib/search.test.js
git commit --amend --no-edit
git show --stat --oneline HEAD

70f0200 Implement the search lookup
 lib/search.js      | 4 +++-
 lib/search.test.js | 1 +
 2 files changed, 4 insertions(+), 1 deletion(-)
```

> :warning: Si vous avez déjà poussé ce commit sur une branche que d'autres utilisent, ne l'amendez pas. Faites plutôt un second commit, honnête. Sur votre propre branche de pull request : amendez, puis `git push --force-with-lease`.

## « Zut, je dois changer le message de mon dernier commit ! »

```console
git commit --amend -m'Implement the search lookup'
```

Ou `git commit --amend` sans `-m`, pour ouvrir votre éditeur sur le message existant — plus agréable quand vous voulez ajouter un corps.

**Et si ce n'est pas le dernier commit ?** Alors c'est un rebase interactif avec un `reword` :

```console
git rebase -i HEAD~5
```

Changez `pick` en `reword` (ou juste `r`) sur la ligne qui vous intéresse, enregistrez, et Git s'arrêtera pour ouvrir votre éditeur sur ce message avant de continuer.

```console
pick 63dee6d # Add the search entry point
reword 1c37e7f # Add the synonyms table
```

Rappelez-vous que ceci réécrit ce commit *et tous les commits suivants* — ils reçoivent tous de nouveaux SHAs, parce que leur parent a changé. La règle d'or du rebase s'applique : très bien sur votre propre branche, pas sur une branche partagée.

## « Zut, j'ai committé sur master par accident, ça aurait dû aller sur une toute nouvelle branche ! »

**Ce qui s'est passé :** vous avez fait deux ou trois commits sans changer de branche d'abord. Tout le monde fait ça. `master` a maintenant deux commits d'avance sur là où il devrait être, et ces commits sont parfaitement bons — ils sont juste au mauvais endroit.

**Quoi faire :** nommez-les, puis rembobinez `master`. Dans cet ordre.

```console
git log --oneline

eab0f86 Style the sale banner
03b7787 Add the sale banner
525030a Commit number 3
17b22a9 Commit number 2
a7300ee Commit number 1
```

```console
git branch sale-banner
git reset --hard HEAD~2

HEAD is now at 525030a Commit number 3
```

```console
git log --oneline --all --decorate --graph

* eab0f86 (sale-banner) Style the sale banner
* 03b7787 Add the sale banner
* 525030a (HEAD -> master) Commit number 3
* 17b22a9 Commit number 2
* a7300ee Commit number 1
```

Deux commandes, et il vaut la peine de comprendre pourquoi elles sont dans cet ordre. `git branch sale-banner` crée un *deuxième* nom pour le commit sur lequel `HEAD` se trouve — il ne vous déplace pas, il ne touche pas à vos fichiers, il écrit juste un SHA dans `.git/refs/heads/sale-banner`. Maintenant deux références pointent vers `eab0f86`. Donc quand `git reset --hard HEAD~2` tire `master` en arrière, les commits restent atteignables par l'autre nom et rien n'est en danger.

Faites-le dans l'autre sens — reset d'abord, puis tenter de créer la branche — et vous voilà à chasser le SHA dans le reflog. Il y sera. Mais pourquoi s'infliger ça ?

La variante avec `switch` fait la même chose en vous emmenant avec elle :

```console
git switch -c sale-banner
git switch master
git reset --hard HEAD~2
```

> :information_source: `git reset --hard` n'est sûr ici *que parce que* votre travail est committé et nommé. Des changements non committés dans l'arbre de travail seraient détruits. Si `git status` n'est pas propre, faites d'abord `git stash`.

## « Zut, j'ai committé sur la mauvaise branche ! »

**Ce qui s'est passé :** un commit a atterri sur `master` et il appartenait à `sale-banner`. Légèrement différent du cas précédent, parce que la branche cible existe déjà.

**Quoi faire (option 1) : le recopier, puis rembobiner.**

```console
git log --oneline -1 master

3645fbe Fix the currency symbol
```

```console
git switch sale-banner
git cherry-pick master

[sale-banner 62ac72c] Fix the currency symbol
 1 file changed, 1 insertion(+)
 create mode 100644 hotfix.txt
```

`git cherry-pick <commit>` prend le changement introduit par ce commit et l'applique ici comme un nouveau commit — essentiellement un rebase d'un seul commit, avec un nouveau SHA (`3645fbe` est devenu `62ac72c`). Puis allez faire le ménage sur la branche où il n'aurait jamais dû être :

```console
git switch master
git reset --hard HEAD~1

HEAD is now at 525030a Commit number 3
```

```console
git log --graph --oneline --all --decorate

* 62ac72c (sale-banner) Fix the currency symbol
* eab0f86 Style the sale banner
* 03b7787 Add the sale banner
* 525030a (HEAD -> master) Commit number 3
{..}
```

**Quoi faire (option 2) : dé-committer et re-committer.** Si vous n'avez pas encore changé de branche, `--soft` est plus propre. Il ramène le pointeur de branche en arrière mais laisse l'index et l'arbre de travail exactement tels qu'ils sont, si bien que le changement est toujours indexé et prêt à partir :

```console
git reset --soft HEAD~1
git status --short

A  w.txt
```

```console
git switch -c right-branch
git commit -m'Work that belongs elsewhere'
```

C'est le troisième visage de `git reset`, et c'est le bon moment pour mettre les trois côte à côte. [Jouer avec nos révisions](../1-understanding-git/7-play-with-git-revisions.md "Jouer avec nos révisions") vous en a montré deux :

| | pointeur de branche | index | arbre de travail |
|---|---|---|---|
| `git reset --soft <c>` | se déplace | intact | intact |
| `git reset <c>` (`--mixed`, par défaut) | se déplace | remis à `<c>` | intact |
| `git reset --hard <c>` | se déplace | remis à `<c>` | remis à `<c>` |

Les trois déplacent la branche. Ils ne diffèrent que par ce qu'ils emmènent avec eux. `--soft` est le doux : « dé-committe, garde tout indexé ». `--hard` est le seul qui puisse détruire du travail que vous n'avez pas committé.

## « Mince, j'ai fait un `git reset --hard` et mon travail a disparu ! »

**Ce qui s'est passé :** cela dépend entièrement d'une seule question. *Avait-il été committé un jour, ou au moins ajouté à l'index ?*

**S'il a été committé :** tout va bien. Vraiment.

```console
git log --oneline -1

62ac72c Fix the currency symbol
```

```console
git reset --hard HEAD~2
git log --oneline -1

03b7787 Add the sale banner
```

```console
git reflog | head -3

03b7787 HEAD@{0}: reset: moving to HEAD~2
62ac72c HEAD@{1}: checkout: moving from master to sale-banner
525030a HEAD@{2}: reset: moving to HEAD~1
```

```console
git reset --hard HEAD@{1}

HEAD is now at 62ac72c Fix the currency symbol
```

De retour. Temps total écoulé : quatre secondes.

**Si le reflog ne peut pas aider** — parce que vous êtes dans un clone tout frais, ou que le reflog a été expiré par un `gc` — il y a une seconde ligne de défense. Les objets de Git sont toujours sur le disque même quand aucune référence et aucun reflog ne les mentionne :

```console
git reflog expire --expire=now --all      # on simule le pire des cas
git fsck --lost-found

dangling commit 37f0a8b9f4553ae6eca06efb066397884c16fc8d
```

```console
git log --oneline -1 37f0a8b

37f0a8b Three days of work
```

`git fsck --lost-found` écrit ce qu'il trouve dans `.git/lost-found/` et l'affiche. `git fsck --unreachable --no-reflogs` est la version plus chirurgicale — et le `--no-reflogs` compte, parce que sans lui `fsck` traite les entrées du reflog comme des racines et rapporte joyeusement que rien n'est inatteignable.

**Et vérifiez le stash**, que les gens oublient complètement. Le stash est son propre reflog (`refs/stash`), donc une entrée de stash survit à des choses qui écrasent vos branches :

```console
git stash list

stash@{0}: On master: wip on a
```

```console
git stash show -p stash@{0}

diff --git a/a b/a
index 7898192..3199773 100644
--- a/a
+++ b/a
@@ -1 +1,2 @@
 a
+wip
```

Maintenant la partie où je ne vais pas être gentil avec vous.

> :warning: **Les changements qui n'ont jamais été committés et jamais ajoutés à l'index sont perdus. Complètement. Pour toujours.**
>
> `git reset --hard` écrase l'arbre de travail à partir de l'index. Git n'a jamais eu de copie de ce qui était dans ces fichiers, il n'y a donc rien à restaurer, et aucune commande ne le ramènera. `git fsck` n'aidera pas ; il n'y a aucun objet à trouver.
>
> La seule miette d'espoir : si vous aviez lancé `git add` à un moment quelconque — même quelques minutes plus tôt, même sans jamais committer — Git a écrit un **blob** pour cette version, et `git fsck --lost-found` pourrait bien le trouver. `git add` ne sert pas seulement à préparer un commit ; c'est un point de sauvegarde. C'est une vraie raison d'indexer tôt et souvent.
>
> Un faux espoir est pire qu'une mauvaise nouvelle. Si ça n'a jamais été indexé et jamais committé, arrêtez de chercher et commencez à retaper. Certains éditeurs gardent leur propre historique local (les IDE JetBrains, l'*historique local* de VS Code, les fichiers d'annulation de `vim`) — c'est un meilleur endroit où chercher que Git.

## « Zut, j'ai supprimé une branche et elle avait deux jours de travail dessus ! »

**Ce qui s'est passé :** vous avez supprimé un *nom*. Les commits sont intacts.

Et Git, aimable, vous a dit exactement quel commit vous avez orphelin :

```console
git branch -D experiment

Deleted branch experiment (was 34d8133).
```

**Quoi faire :** pointez un nouveau nom dessus.

```console
git branch experiment 34d8133
```

Voilà. Si vous n'avez pas gardé le SHA, le reflog de la branche est parti avec elle, mais le reflog de `HEAD` se souvient que vous y étiez :

```console
git reflog | head -3

41796f0 HEAD@{0}: checkout: moving from experiment to main
34d8133 HEAD@{1}: commit: Two days of careful work
41796f0 HEAD@{2}: checkout: moving from main to experiment
```

Et si même cela est épuisé :

```console
git fsck --unreachable --no-reflogs

unreachable tree 259ba6c099bcee4e99d38a56970b0fa4db7041a5
unreachable commit 34d8133aa4ab96e591877833bccffba9e5977e11
unreachable blob b8f99f5be53f536f79ef622abaa77b9942a9e142
```

Voilà notre commit. `git log --oneline 34d8133` pour confirmer que c'est le bon, puis `git branch experiment 34d8133` pour le sauver.

## « Mince, je dois annuler un commit que j'ai déjà poussé ! »

**Ce qui s'est passé :** le commit est dans la nature. D'autres l'ont. Ce qui exclut toutes les options qui impliquent une réécriture.

**Quoi faire :** `git revert`. Il calcule l'inverse d'un commit et l'applique comme un *nouveau* commit.

```console
git revert HEAD

[master 0179544] Revert "Change f on master"
 1 file changed, 1 insertion(+), 1 deletion(-)
```

```console
git log --oneline

0179544 Revert "Change f on master"
d82c967 Change f on master
710bcdb Initial commit
```

Les deux commits sont dans l'historique : l'erreur, et la correction. Rien n'a été réécrit, personne n'a à forcer un push, le clone de personne ne casse. Tout le monde peut tirer normalement.

Ce dernier point est tout l'argument. `git reset --hard HEAD~1` suivi d'un push forcé supprimerait *aussi* le changement, et il :

* casserait tous les collègues dont la branche est basée sur ce commit,
* serait rejeté d'emblée par la protection de branche de tout serveur bien configuré,
* et masquerait discrètement le fait que le mauvais changement ait jamais existé — ce qui est exactement l'information dont la prochaine personne qui déboguera ceci a besoin.

`revert` garde l'historique honnête. Utilisez-le sur tout ce qui est partagé, sans hésiter.

> :information_source: Un revert peut entrer en conflit, comme toute autre fusion à trois points — si le code a évolué depuis le commit que vous annulez, Git doit trouver comment le dé-appliquer. `git revert --abort` et `git revert --continue` se comportent exactement comme leurs équivalents pour `merge`. Et vous pouvez toujours annuler l'annulation : Git le nomme même pour vous, `Reapply "…"`.

## « Zut, je veux annuler toute une fusion ! »

**Ce qui s'est passé :** vous avez fusionné une branche de fonctionnalité dans `master`, vous l'avez poussée, et il s'avère maintenant que la fonctionnalité est cassée.

**Quoi faire :** `git revert -m 1`. Comme nous l'avons vu au chapitre précédent, un commit de fusion a deux parents, il faut donc dire à `revert` lequel est la ligne principale. Pour une fusion dans la branche sur laquelle vous êtes, c'est toujours le parent 1.

```console
git revert -m 1 5096af3

[master 42db35e] Revert "Merge branch 'banner'"
 2 files changed, 2 deletions(-)
 delete mode 100644 banner.css
 delete mode 100644 views_banner.html
```

```console
git log --graph --oneline

* 42db35e Revert "Merge branch 'banner'"
*   5096af3 Merge branch 'banner'
|\
| * 994a8ef Style the top banner
| * fd93999 Add the top banner markup
|/
* 8c85815 Add a
* b70b5a2 Initial commit
```

Le code de la fonctionnalité a disparu de l'arbre de travail ; la fusion et son annulation sont toutes deux visibles dans l'historique. Jusque-là, tout va bien.

Et maintenant le piège. Il est célèbre, il attrape tout le monde exactement une fois, et son mode de défaillance est le *silence*.

Deux semaines plus tard, la branche est réparée, alors vous la fusionnez de nouveau :

```console
git merge banner

Already up to date.
```

```console
ls

a.txt
```

« Already up to date » — et aucun des fichiers de la fonctionnalité n'est là.

**Pourquoi :** Git calcule la base de fusion et voit que `994a8ef` est déjà un ancêtre de `master`, parce que la première fusion a réellement eu lieu et est toujours dans l'historique. La fusion est définie en termes d'*ascendance*, pas de contenu. Du point de vue de Git, la branche **est** fusionnée ; le fait qu'un commit ultérieur ait supprimé tous ses fichiers n'est qu'un changement ordinaire sur `master` que vous aviez vraisemblablement l'intention de faire.

**Quoi y faire :** annuler l'annulation.

```console
git revert 42db35e

[master 10f2155] Reapply "Merge branch 'banner'"
 2 files changed, 2 insertions(+)
 create mode 100644 banner.css
 create mode 100644 views_banner.html
```

```console
ls

a.txt
banner.css
views_banner.html
```

Les fichiers sont de retour, et tous les nouveaux commits faits sur `banner` depuis se fusionneront désormais normalement.

> :warning: La conséquence pour la forme de votre travail : **une fois que vous avez annulé une fusion, cette branche ne peut pas simplement être refusionnée.** Soit vous annulez l'annulation, comme ci-dessus, en gardant les commits d'origine de la branche — soit vous abandonnez la branche et rebasez le travail restant sur le `master` actuel sous forme de nouveaux commits. Décider laquelle des deux *avant* de commencer vous économisera un après-midi.

## « Mince, je dois désindexer un fichier ! »

**Ce qui s'est passé :** vous avez tapé `git add` avec un peu trop d'enthousiasme.

**Quoi faire**, en Git moderne :

```console
git restore --staged lib/secret_debug_hack.js
```

L'ancienne écriture, que vous verrez encore partout et qui fait exactement la même chose :

```console
git reset HEAD lib/secret_debug_hack.js
```

`git restore` et `git switch` ont été introduits dans Git 2.23 pour scinder l'impossiblement surchargé `git checkout`. Apprenez `restore` ; reconnaissez `reset HEAD`.

Maintenant la partie qui fait trébucher les gens. Il y a trois « annule mes changements » différents, et les confondre est la manière dont on perd du travail. Partons de `log.txt` contenant trois lignes dans le dernier commit, une quatrième ligne indexée, et une cinquième ligne dans le fichier mais non indexée :

```console
git status --short

MM log.txt
```

**`git restore --staged log.txt`** — l'index seulement. Votre fichier est intact ; l'indexation disparaît.

```console
git restore --staged log.txt
git status --short

 M log.txt
```

L'arbre de travail a toujours tout ce que vous avez tapé. Complètement sûr.

**`git restore log.txt`** — l'arbre de travail seulement, repris depuis l'index.

```console
git restore log.txt
git status --short

M  log.txt
```

Le fichier correspond maintenant à ce qui était indexé. **La ligne non indexée a disparu, et elle n'est pas récupérable.** C'est celui qui détruit.

**`git restore --staged --worktree log.txt`** — les deux, depuis `HEAD`.

```console
git restore --staged --worktree log.txt
git status --short
```

Propre. Le fichier est revenu au dernier commit ; tout ce que vous lui aviez fait a disparu.

> :warning: `git restore <fichier>` et `git restore --staged --worktree <fichier>` écrasent votre arbre de travail sans reflog et sans annulation. Il n'existe pas de `git restore --abort`. Quand vous n'êtes pas certain, faites plutôt `git stash` — c'est la même opération « rends mon arbre de travail propre », sauf qu'elle est réversible.

## « Mince, j'ai essayé de faire un diff mais rien ne s'est passé ?! »

**Ce qui s'est passé :** vous avez indexé les changements, puis posé la mauvaise question.

`git diff` sans argument veut dire *arbre de travail contre index*. Une fois que vous avez lancé `git add`, ces deux-là sont identiques, il n'y a donc rien à montrer. Git répond correctement ; vous avez posé la question sur la mauvaise paire.

Il y a trois paires, et trois commandes :

```console
git diff              # arbre de travail vs index  -> ce qui n'est PAS indexé
git diff --cached     # index vs HEAD              -> ce qui EST indexé
git diff HEAD         # arbre de travail vs HEAD   -> tout, indexé ou non
```

Avec une ligne indexée et une autre ligne seulement dans le fichier :

```console
git diff

diff --git a/log.txt b/log.txt
index ae31c32..3ddc309 100644
--- a/log.txt
+++ b/log.txt
@@ -2,3 +2,4 @@ line 1
 line 2
 line 3
 staged change
+and an unstaged one
```

```console
git diff --cached

diff --git a/log.txt b/log.txt
index a92d664..ae31c32 100644
--- a/log.txt
+++ b/log.txt
@@ -1,3 +1,4 @@
 line 1
 line 2
 line 3
+staged change
```

```console
git diff HEAD

diff --git a/log.txt b/log.txt
index a92d664..3ddc309 100644
--- a/log.txt
+++ b/log.txt
@@ -1,3 +1,5 @@
 line 1
 line 2
 line 3
+staged change
+and an unstaged one
```

`--staged` est un alias de `--cached` : comportement identique, nom plus sympathique.

La même logique explique l'autre non-événement classique. `git diff <branche>` compare votre arbre de travail au sommet de cette branche, tandis que `git diff <branche>...HEAD` — trois points — compare à la **base de fusion**, ce qui est presque toujours ce que vous vouliez dire en demandant « qu'est-ce que ma branche ajoute ? ».

## « Oh non. J'ai committé un énorme fichier. Ou pire, une clé d'API. »

Deux problèmes qui se ressemblent et qui n'en sont pas un seul. Séparons-les tout de suite, parce que l'important n'est pas celui qui concerne Git.

### S'il s'agit d'un secret

> :warning: **Un secret poussé est un secret compromis. Faites-le tourner. Maintenant. Avant de lire la suite de cette section.**
>
> Réécrire l'historique ne dé-divulgue rien. Au moment où vous l'avez remarqué, l'identifiant peut déjà exister dans : tous les clones et forks que quiconque a faits, y compris ceux que vous ne pouvez pas voir ; les journaux de build et les caches de votre fournisseur de CI ; le stockage de votre hébergeur lui-même, où un objet « pendant » reste atteignable par URL longtemps et où les références de pull request maintiennent en vie d'anciens commits même après que vous avez forcé le push de la branche ; le scraper qui a trouvé votre dépôt, et ils sont rapides — les dépôts publics sont scrutés à la recherche de clés en l'espace de *secondes* après un push ; l'éditeur de quelqu'un, l'historique de shell de quelqu'un, un copier-coller dans Slack.
>
> Révoquez la clé, émettez-en une nouvelle, et vérifiez les journaux d'accès de l'ancienne. Nettoyer l'historique est un ménage que vous faites après, et il est optionnel. Faire tourner l'identifiant ne l'est pas.

Bien. Maintenant le ménage.

### Retirer un fichier de tout l'historique

Si le fichier n'est que dans un commit que vous n'avez pas encore poussé, c'est facile : `git reset --soft HEAD~1`, désindexez-le, ajoutez-le au `.gitignore`, committez de nouveau.

S'il est plus profond dans l'historique, il faut réécrire chaque commit à partir de ce point. Il existe une commande pour cela que vous trouverez dans toutes les vieilles réponses Stack Overflow, et la page de manuel de Git elle-même s'ouvre désormais ainsi :

```console
git help filter-branch

WARNING
       git filter-branch has a plethora of pitfalls that can produce
       non-obvious manglings of the intended history rewrite (and can leave
       you with little time to investigate such problems since it has such
       abysmal performance). These safety and performance issues cannot be
       backward compatibly fixed and as such, its use is not recommended.
       Please use an alternative history filtering tool such as git
       filter-repo.
```

Ce n'est pas mon opinion, c'est le manuel livré avec Git 2.51. N'utilisez pas `git filter-branch`.

Utilisez **`git-filter-repo`** (un unique script Python, installable depuis votre gestionnaire de paquets ou avec `pip`), ou **BFG Repo-Cleaner** (un JAR ; plus rapide sur les très gros dépôts, moins souple). Voici `filter-repo` qui fait le travail :

```console
git log --oneline

fdd6136 Improve the app
6dae2b0 Add the env file
b2e54c6 Initial commit
```

```console
git filter-repo --invert-paths --path .env --force

Parsed 3 commits
New history written in 0.07 seconds; now repacking/cleaning...
Repacking your repo and cleaning out old unneeded objects
Completely finished after 0.23 seconds.
```

```console
git log --oneline

6c57530 Improve the app
b2e54c6 Initial commit
```

Le fichier `.env` a disparu de chaque commit, et le commit qui consistait uniquement à l'ajouter a disparu avec lui. Notez les SHAs : `fdd6136` est devenu `6c57530`. Chaque commit après le point de réécriture est un objet différent.

Ce qui est le vrai coût, et il n'est pas mince :

> :warning: Une réécriture d'historique change chaque SHA à partir du point de réécriture. Cela signifie que **tout le monde doit recloner.** Leurs clones existants ne partagent aucun historique avec le nouveau, donc tout `git pull` essaiera de fusionner deux copies parallèles du projet entier. Les pull requests ouvertes seront confuses ou cassées. Les tags doivent être repoussés. `git filter-repo` supprime délibérément votre dépôt distant `origin` ensuite, pour vous empêcher de forcer un push avant d'y avoir réfléchi.
>
> Annoncez-le, choisissez un moment, et assurez-vous que tout le monde a poussé son travail d'abord.

### La prévention, qui est bien moins chère

* **Mettez vos fichiers de secrets dans `.gitignore` avant de les écrire.** Voir [Un peu de structure SVP](4-git-repo-structure.md "Un peu de structure SVP"). `.env`, `*.pem`, `credentials.json`, `id_rsa`. Committez un `.env.example` avec les clés et sans les valeurs.
* **Un hook de pre-commit qui cherche les secrets.** `gitleaks` et `trufflehog` sont les deux scanners bien connus ; les deux tournent volontiers depuis un hook ou dans la CI, et le framework `pre-commit` les branche en quelques lignes.
* **Activez le scan de votre hébergeur.** Le *secret scanning* de GitHub vous alerte quand un format d'identifiant connu atterrit dans votre dépôt, et la *push protection* rejette le push avant même que le secret n'existe sur le serveur — ce qui en fait le seul mécanisme de cette section qui empêche véritablement la fuite au lieu de la signaler. GitLab a un équivalent. Les deux sont gratuits pour les dépôts publics. Activez-les.
* **Pour le problème du fichier énorme en particulier :** Git LFS, ou tout simplement ne pas mettre la vidéo de 400 Mo dans le dépôt du tout. Git stocke chaque version d'un binaire en entier ; un dépôt qui en a accumulé quelques-unes est lent à cloner pour toujours.

## « Zut, j'ai douze commits WIP et mon collègue doit relire ça. »

**Ce qui s'est passé :** rien de mal du tout. C'est ainsi que le travail se fait réellement : `wip`, `wip2`, `actually fix it`, `revert that`, `ok now`. L'erreur serait de l'infliger à un relecteur.

**Quoi faire :** `git rebase -i` contre la branche dans laquelle vous fusionnerez, et transformez la liste de tâches en l'histoire que vous auriez aimé écrire.

```console
git rebase -i main
```

* Réordonnez les lignes pour grouper le travail apparenté.
* `squash` ou `fixup` les commits « oups » dans le commit qu'ils corrigent.
* `reword` les messages qui avaient du sens à 2 h du matin.
* `drop` les commits qui n'existent que pour en annuler d'autres.
* `git rebase -i --exec 'npm test' main` pour vérifier que chaque commit résultant compile bien.

Si vous avez marqué vos fixups au fil de l'eau avec `git commit --fixup <commit>` — voir [le chapitre précédent](5-git-workflow.md "Mettre en œuvre un workflow collaboratif efficace") — alors `--autosquash` construit l'essentiel de la liste de tâches pour vous.

### Scinder un commit en deux

La manœuvre qui ressemble à de la magie. Vous avez un commit qui corrige un bug *et* rectifie une coquille sans rapport, et cela devrait être deux commits.

```console
git log --oneline

f30a4c5 Fix the cart and also a typo
e2ab2ee Initial commit
```

Démarrez un rebase interactif et marquez ce commit `edit` :

```console
git rebase -i HEAD~1
```

```console
edit f30a4c5 # Fix the cart and also a typo
```

Git applique le commit et s'arrête, vous laissant debout dessus :

```console
Stopped at f30a4c5...  Fix the cart and also a typo
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
```

Maintenant dé-committez-le, en gardant les changements dans l'arbre de travail :

```console
git reset HEAD^
git status --short

 M a.txt
 M b.txt
```

Le commit a disparu ; son contenu non. Committez les morceaux séparément — et quand les deux moitiés vivent dans le *même* fichier, `git add -p` vous fait parcourir le diff section par section en demandant « on indexe celle-ci ? », ce qui est l'outil qui rend toute la technique possible :

```console
git add a.txt
git commit -m'Fix the cart total'
git add b.txt
git commit -m'Fix a typo in the product page'
git rebase --continue

Successfully rebased and updated refs/heads/master.
```

```console
git log --oneline

4099c04 Fix a typo in the product page
bd3a26d Fix the cart total
e2ab2ee Initial commit
```

Un commit est devenu deux, dans le bon ordre, au milieu d'une branche.

## « Mince, quelque chose est cassé et je n'ai aucune idée de quel commit l'a fait. »

**Ce qui s'est passé :** ça marchait la semaine dernière, ça ne marche plus, et il y a deux cents commits entre les deux.

**Quoi faire :** arrêtez de lire des commits. Laissez Git faire une recherche dichotomique. `git bisect` est la commande la plus sous-utilisée de Git et elle est véritablement magique.

Voici un dépôt où `./price.sh` devrait afficher `12` et affiche `13` :

```console
git log --oneline

74604a1 Reorder the functions
8dd3203 Bump the version
0beff0b Add a second helper
de7a387 Update the developer docs
4c5fe6a Introduce the configurable tax rate
9d35fcf Tidy up the whitespace
18aa588 Refactor the rounding
ef6169b Add the currency symbol
a153a12 Document the price helper
92dfde8 Rename the price helper
46371db Add the price script
```

Dites à Git un commit qui est cassé et un qui allait bien :

```console
git bisect start
git bisect bad
git bisect good 46371db

Bisecting: 4 revisions left to test after this (roughly 2 steps)
[9d35fcf070ec73c1683b9ab1f99a0bdf6c3a2940] Tidy up the whitespace
```

`git bisect bad` sans argument veut dire « le commit sur lequel je suis ». Git a maintenant extrait le milieu de l'intervalle et attend. Testez-le, et dites-lui ce que vous avez trouvé :

```console
./price.sh

12
```

```console
git bisect good

Bisecting: 2 revisions left to test after this (roughly 1 step)
[de7a387111fa72a0e6daa3238b6042f3113c716e] Update the developer docs
```

```console
./price.sh

13
```

```console
git bisect bad

Bisecting: 0 revisions left to test after this (roughly 0 steps)
[4c5fe6a24048ed630e626aa791e899a5bba7fc08] Introduce the configurable tax rate
```

Dix commits, trois tests. C'est cela, la recherche dichotomique : chaque réponse divise l'intervalle par deux, donc mille commits vous coûtent dix tests.

### `git bisect run` : la partie qui est réellement magique

Si vous pouvez exprimer « est-ce cassé ? » sous forme d'un script qui sort avec 0 pour bon et non nul pour mauvais, vous n'avez pas du tout besoin de rester là.

```console
cat check.sh

#!/bin/sh
test "$(./price.sh)" = "12"
```

```console
git bisect start
git bisect bad
git bisect good 46371db
```

```console
git bisect run ./check.sh

running './check.sh'
Bisecting: 2 revisions left to test after this (roughly 1 step)
[de7a387111fa72a0e6daa3238b6042f3113c716e] Update the developer docs
running './check.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[4c5fe6a24048ed630e626aa791e899a5bba7fc08] Introduce the configurable tax rate
running './check.sh'
4c5fe6a24048ed630e626aa791e899a5bba7fc08 is the first bad commit
commit 4c5fe6a24048ed630e626aa791e899a5bba7fc08
Author: Ori Pekelman <ori@pekelman.com>
Date:   Tue Feb 17 14:00:00 2026 +0100

    Introduce the configurable tax rate

 notes.md | 1 +
 price.sh | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
bisect found first bad commit
```

Vous avez tapé quatre lignes et Git vous a tendu le commit, l'auteur, la date et le diff. Sur un vrai projet, c'est généralement quelque chose comme `git bisect run npx jest path/to/failing.test.js` ou `git bisect run pytest -x tests/test_thing.py`, qu'on laisse tourner pendant qu'on va faire un café.

Écrivez le script de vérification *d'abord*, et rendez-le aussi étroit que possible. Un script qui prend deux secondes transforme une bissection de vingt commits en pause café ; un qui lance toute la suite pendant huit minutes, non.

**Quand vous avez terminé, toujours :**

```console
git bisect reset

Previous HEAD position was 4c5fe6a Introduce the configurable tax rate
Switched to branch 'master'
```

Cela vous remet sur la branche d'où vous êtes parti. L'oublier vous laisse assis dans un **detached head** à vous demander pourquoi votre éditeur affiche du vieux code.

Deux de plus :

* `git bisect skip` — ce commit ne peut pas être testé (il ne compile pas, une dépendance est cassée). Git le contourne.
* `git bisect log` — la transcription jusqu'ici. Sauvegardez-la ; `git bisect replay <fichier>` la rejoue, ce qui est la manière de s'en sortir quand on a répondu de travers.

> :information_source: La bissection ne fonctionne que si l'historique est bissectable — c'est-à-dire si la plupart des commits compilent et tournent. C'est l'argument pratique et égoïste en faveur de toute la discipline du chapitre précédent : de petits commits qui marchent chacun, fusionnés avec `--no-ff` pour que `git bisect start --first-parent` puisse parcourir des fonctionnalités plutôt que des frappes au clavier. Un historique de commits `wip` qui ne compilent pas ne peut pas être bissecté, et vous le découvrirez le jour où vous en aurez le plus besoin.

## « Zut, mon arbre de travail est un désastre et je veux tout reprendre à zéro. »

**Ce qui s'est passé :** des modifications à moitié faites dans neuf fichiers, quatre scripts expérimentaux, un répertoire de sortie de débogage. Vous voulez l'état que vous aviez ce matin.

**Quoi faire :** trois commandes, par ordre croissant de violence.

**1. Jeter les changements des fichiers suivis :**

```console
git restore .
```

**2. S'occuper des fichiers non suivis** — et là vous devez faire attention, parce que `git clean` est l'une des très rares commandes Git qui détruisent des données sans retour possible. Regardez toujours d'abord, avec `-n` (simulation) :

```console
git clean -nd

Would remove oops.txt
Would remove scratch/
```

Lisez cette liste. Puis, et alors seulement :

```console
git clean -fd

Removing oops.txt
Removing scratch/
```

`-f` c'est force (Git refuse sans, exprès), `-d` inclut les répertoires.

> :warning: **`git clean` n'a ni reflog, ni stash, ni annulation.** Les fichiers non suivis n'ont jamais été dans Git, Git n'en a donc aucune copie. `git clean -fd` les supprime comme `rm -rf` les supprime.
>
> Et `-x` est pire. Il retire aussi les fichiers **ignorés** — c'est-à-dire votre `.env`, votre `node_modules/`, votre `venv/`, votre base de données locale, vos réglages `.idea/`, tout ce que `.gitignore` protège. `git clean -fdx` est une commande légitime ; c'est la bonne manière d'obtenir un arbre véritablement immaculé, et les exécuteurs de CI l'utilisent. Mais lancez `git clean -ndx` d'abord, à chaque fois, et lisez la liste :

```console
git clean -ndx

Would remove .env
Would remove node_modules/
Would remove oops.txt
Would remove scratch/
```

Ce sont vos clés d'API et quarante minutes de `npm install`. Cela vaut dix secondes de lecture.

**3. Rembobiner entièrement jusqu'au dernier commit :**

```console
git reset --hard
```

Sans argument, cela veut dire `git reset --hard HEAD` : index et arbre de travail ramenés au dernier commit. Combiné avec `git clean -fd`, c'est le bouton de réinitialisation complet.

> :information_source: L'habitude la plus sûre, et celle que je suggérerais : au lieu de `git restore .` plus `git clean -fd`, utilisez `git stash push -u -m 'le bazar du 3 mars'`. Votre arbre finit tout aussi propre, et tout est encore là s'il s'avère que l'un de ces neuf fichiers contenait la bonne idée. Les stashes sont bon marché ; vous pourrez les jeter la semaine prochaine.

## « Zut, je suis au milieu de quelque chose et je dois changer de contexte tout de suite. »

**Ce qui s'est passé :** la production est en feu, ou un collègue a besoin d'une relecture, et votre arbre de travail contient une demi-fonctionnalité.

**Quoi faire :** `git stash`. Nous l'avons rencontré dans [Collaborer grâce à Git](1-collaborate-with-git.md "Collaborer grâce à Git") ; voici le jeu complet.

```console
git stash push -u -m 'wip: VAT on the cart total'

Saved working directory and index state On master: wip: VAT on the cart total
```

Deux options qui comptent :

* **`-m <message>`.** Toujours. Une liste de six stashes disant tous `WIP on master: 51de6d1 Initial shopping cart code` est une énigme que vous vous êtes posée à vous-même.
* **`-u`** (`--include-untracked`). Sans elle, les fichiers tout neufs sont *laissés derrière dans votre arbre de travail*, ce qui est une manière très déroutante de découvrir que votre arbre « propre » ne l'est pas. `-a` inclut aussi les fichiers ignorés, ce que vous ne voulez presque jamais.

Ensuite :

```console
git stash list

stash@{0}: On master: wip: VAT on the cart total
```

* `git stash show --stat` — ce qu'il y a dans le stash du dessus. Ajoutez `-p` pour le patch, et `--include-untracked` pour voir aussi les nouveaux fichiers ; il ne les montre pas par défaut, ce qui surprend les gens.
* `git stash pop` — appliquer le stash du dessus et le supprimer.
* `git stash apply` — l'appliquer et le *garder*. Utilisez celui-ci quand vous n'êtes pas sûr qu'il s'appliquera proprement ; vous pourrez toujours le jeter ensuite.
* `git stash drop stash@{1}` — en supprimer un. `git stash clear` les supprime tous, et n'a pas d'annulation sur laquelle compter.
* `git stash branch <nom>` — le sous-estimé. Il crée une branche à partir du commit sur lequel le stash a été fait, y applique le stash, et le supprime. C'est la bonne réponse quand un stash est devenu périmé et ne s'applique plus à votre branche courante :

```console
git stash branch vat-experiment

Switched to a new branch 'vat-experiment'
On branch vat-experiment
Changes not staged for commit:
	modified:   cart.js

Untracked files:
	cart.test.js

Dropped refs/stash@{0} (84f5108c32f515a93f3dab9ee44f3f09019a0521)
```

Et parce que nous aimons regarder sous le capot : un stash n'est pas une structure de données spéciale. C'est un commit, sur une référence appelée `refs/stash`, et avec `-u` il a *trois* parents.

```console
git cat-file -p stash@{0}

tree 31ee6cd9e70d9b4dc8cd2d087b525135c863c155
parent 51de6d1143332b4224d19af5d4fdce11f1b2878e
parent 615417a415e96155d1eb0025278b16786a9970ff
parent f8c0a1974c63e9d2d1a9f687c3dbe92f131dd14d
author Ori Pekelman <ori@pekelman.com> 1772532000 +0100
committer Ori Pekelman <ori@pekelman.com> 1772532000 +0100

On master: wip: VAT on the cart total
```

Le commit sur lequel vous étiez, un commit contenant votre index, et un commit contenant vos fichiers non suivis. C'est pourquoi un stash survit à presque tout : c'est un commit ordinaire, avec un reflog ordinaire.

> :information_source: Le stash est une pile, et il est facile de la laisser devenir un tas de choses que vous ne regarderez plus jamais — six stashes de profondeur, aucun étiqueté, tous périmés. Si ce que vous voulez réellement, c'est « travailler sur deux choses à la fois », un **worktree** est presque toujours la meilleure réponse : un second répertoire, extrait sur une autre branche, partageant le même `.git`. Pas de stash, pas de changement de contexte, les deux choses ouvertes en même temps. Voir [Un seul dépôt, plusieurs répertoires de travail](../4-beyond-the-basics/1-git-worktree.md "Un seul dépôt, plusieurs répertoires de travail").

## « Zut, je suis en “detached HEAD” et je ne sais pas où je suis. »

**Ce qui s'est passé :** vous avez extrait un commit, une étiquette, ou une branche de suivi distant directement — ou vous êtes au milieu d'une bissection ou d'un rebase. **HEAD** contient un SHA au lieu de `ref: refs/heads/...`, exactement comme nous l'avons vu dans [Jouer avec nos révisions](../1-understanding-git/7-play-with-git-revisions.md "Jouer avec nos révisions"). Les commits que vous faites ici n'appartiennent à aucune branche.

**Quoi faire :** d'abord, demandez.

```console
git status

HEAD detached at 4c5fe6a
nothing to commit, working tree clean
```

Rien n'a mal tourné. Un **detached head** est un état normal et utile — c'est ainsi qu'on regarde le passé.

**Si vous avez fait des commits ici et que vous voulez les garder**, donnez-leur un nom :

```console
git switch -c experiment

Switched to a new branch 'experiment'
```

```console
git log --oneline -2

b90c247 An experiment made in detached HEAD
4c5fe6a Introduce the configurable tax rate
```

Vos commits vivent maintenant sur une branche et sont en sécurité.

**Si vous n'en voulez pas**, partez simplement : `git switch main`, et Git les oublie. Le reflog, lui, non, pendant quelques semaines.

**Et `git switch -`** revient à la branche précédente, comme le fait `cd -`. Notez qu'il faut que l'emplacement précédent *soit* une branche :

```console
git switch -

fatal: a branch is expected, got commit 'b90c24737a397bfa37da909d9b94e91a82d33f52'
hint: If you want to detach HEAD at the commit, try again with the --detach option.
```

Honnête et clair : il ne peut pas basculer vers un commit, parce que basculer est une opération de branche. Nommez votre branche, ou dites où vous voulez aller.

## « Mince, j'arrête, j'abandonne ? »

Excellent. Abandonner est une technique.

**Si vous êtes au milieu d'une opération**, chacune d'elles a une sortie de secours, et chacune vous remet exactement là où vous aviez commencé :

```console
git merge --abort
git rebase --abort
git cherry-pick --abort
git revert --abort
git am --abort
git bisect reset
```

(`git am` applique des patchs venant d'e-mails ; vous le rencontrerez si vous contribuez un jour à un projet à liste de diffusion.) Et si vous ne vous rappelez plus dans quelle opération vous êtes, `git status` vous le dit dès sa première ligne.

**Si vous avez dépassé ce stade** — trois rebases ratés, un conflit à moitié résolu, un arbre de travail que vous ne reconnaissez plus, et honnêtement aucune idée de l'état de quoi que ce soit — alors voici l'option nucléaire. Je tiens à être clair : c'est un geste légitime et professionnel, pas un échec :

```console
cd ..
git clone git@example.com:team/shop.git shop-fresh
cd shop-fresh
git switch -c my-feature
# recopier à la main les fichiers auxquels vous tenez
```

Clonez à neuf depuis le dépôt distant dans un nouveau répertoire. Recopiez vos fichiers avec un gestionnaire de fichiers. Committez-les en un seul commit propre. Poussez. Supprimez le répertoire cassé quand vous serez serein à ce sujet.

Vous perdez l'historique de votre branche locale, qui était de toute façon `wip`, `wip2` et `fix the wip`. Vous ne perdez rien qui compte, vous y passez dix minutes, et c'est réglé. Comparez cela avec l'heure que vous étiez sur le point de passer à excaver `.git/rebase-merge/` et à lire des sorties de `git fsck` pendant que vos collègues attendent.

Les ingénieurs chevronnés font ça. Ce n'est pas tricher. Le but est un logiciel qui marche, pas une démonstration de votre capacité à gagner une joute contre une machine à états à six heures du soir.

> :warning: Une chose à vérifier avant de supprimer l'ancien répertoire : lancez `git stash list` et `git log --oneline --all` dans le dépôt cassé, pour être certain que rien de ce que vous voulez ne s'y trouve encore. Et gardez le répertoire une journée. Les répertoires ne coûtent pas cher.

## Les deux habitudes qui rendent tout cela rare

Tout ce qui précède est un remède. Il n'y a que deux préventions, et elles sont toutes deux bon marché.

**Committez petit et souvent.** Un commit est un point de sauvegarde, et c'est l'opération la moins chère de Git — pas d'aller-retour serveur, pas de cérémonie. Si votre travail est committé, alors presque rien dans ce chapitre n'est une catastrophe : c'est un pointeur à ramener en arrière. Les gens qui perdent du travail avec Git sont, essentiellement sans exception, ceux qui ont quatre heures de changements non committés. Faites des commits moches sur votre propre branche toute la journée et nettoyez-les avec `rebase -i` avant que quiconque ne les voie. C'est à ça que ça sert.

Et le corollaire plus modeste : `git add` tôt. L'indexation écrit un **blob** dans `.git/objects`, ce qui veut dire que même un changement non committé devient retrouvable avec `git fsck`. C'est un point de sauvegarde sous le point de sauvegarde.

**Ne réécrivez jamais un historique partagé.** Toutes les catastrophes Git véritablement douloureuses, à plusieurs personnes et dévoreuses de journées, viennent de cette seule chose : `--amend`, `rebase`, `reset --hard` ou `push --force` sur une branche que d'autres utilisent. Votre propre branche : réécrivez librement, forcez le push avec `--force-with-lease`. `main` : jamais. Il n'y a pas de troisième cas.

C'est tout. Ces deux habitudes, plus le fait de savoir que `git reflog` existe, font la différence entre un Git effrayant et un Git qui est l'endroit le plus sûr où votre code puisse vivre.

Ce qui nous ramène à la promesse rassurante du début, et que j'espère que vous croyez maintenant : **Git ne perd presque jamais de données committées.** Il garde des objets dont il n'a plus besoin. Il journalise chaque déplacement de chaque référence. Il refuse les opérations destructrices contre un dépôt distant à moins que vous n'insistiez. L'écrasante majorité des « j'ai perdu mon travail » se révèle être « j'ai perdu la trace de mon travail », et le remède est une commande que vous connaissez déjà.

Si vous ne retenez qu'une chose de ce chapitre, retenez celle-ci : quand quelque chose tourne mal, avant toute autre chose, tapez `git reflog`.

## Récapitulatif : `git reflog`, `git revert`, `git bisect`, `git stash`, `git clean`

* **`git reflog`** est la commande la plus précieuse de ce chapitre. Chaque déplacement de référence est journalisé, donc `git reset --hard HEAD@{1}` annule ce que vous venez de faire. Aussi `git reflog <branche>`, `master@{5}`, `HEAD@{2.hours.ago}`, `git log -g`. Il est local, et les entrées expirent au bout de 30 à 90 jours.
* `git commit --amend` (`--no-edit`) corrige le dernier commit ou son message ; `git rebase -i` plus `reword` en corrige un plus ancien.
* **Committé au mauvais endroit ?** `git branch <nouveaunom>` d'abord, *puis* `git reset --hard HEAD~n`. Ou `git reset --soft HEAD~1`, changer de branche, et recommitter. Ou `git cherry-pick` sur la bonne branche et reset de la mauvaise.
* `git reset --soft` ne déplace que la branche ; `--mixed` (par défaut) remet aussi l'index ; `--hard` remet aussi l'arbre de travail, et c'est le seul qui détruise du travail non committé.
* **Commits perdus :** `git reflog`, puis `git fsck --lost-found` ou `git fsck --unreachable --no-reflogs`, puis `git stash list`. Les changements jamais ajoutés à l'index et jamais committés sont perdus définitivement — d'où l'intérêt de faire `git add` tôt : l'indexation est elle-même un point de sauvegarde.
* **Supprimé une branche ?** `git branch -D` affiche le SHA qu'il a supprimé. Sinon le reflog de `HEAD`, ou `git fsck --unreachable --no-reflogs`, puis `git branch <nom> <sha>`.
* **`git revert`** annule un commit poussé en en ajoutant un nouveau, de sorte que personne n'a à recloner et que l'historique reste honnête. `git revert -m 1 <fusion>` annule toute une fonctionnalité fusionnée.
* Après avoir annulé une fusion, refusionner cette branche ne fait rien (`Already up to date`) parce que Git se fonde sur l'ascendance, pas sur le contenu. Annulez l'annulation, ou rebasez le travail restant.
* `git restore --staged <fichier>` désindexe, index seulement, sûr. `git restore <fichier>` jette les changements de l'arbre de travail — destructeur, sans annulation. `git restore --staged --worktree <fichier>` fait les deux. `git reset HEAD <fichier>` est l'ancienne écriture du premier.
* `git diff` = arbre de travail vs index ; `git diff --cached` (`--staged`) = index vs **HEAD** ; `git diff HEAD` = tout.
* **Secrets :** faites d'abord tourner l'identifiant — réécrire l'historique ne dé-divulgue rien. `git filter-branch` est déprécié par le manuel de Git lui-même ; utilisez `git filter-repo` ou BFG, et rappelez-vous que tout le monde doit recloner. Prévenez avec `.gitignore`, `gitleaks`/`trufflehog` dans un hook de pre-commit, et le secret scanning et la push protection de votre hébergeur.
* **Ranger le WIP :** `git rebase -i`, `--autosquash` avec `git commit --fixup`, et scinder un commit avec `edit` + `git reset HEAD^` + `git add -p`.
* **`git bisect start` / `bad` / `good` / `reset`** fait une recherche dichotomique dans votre historique ; **`git bisect run ./check.sh`** le fait pour vous, sans surveillance. `git bisect skip` pour les commits intestables, `git bisect log` et `replay` pour sauvegarder et rejouer une session.
* **Repartir de zéro :** `git restore .`, puis `git clean -nd` pour regarder avant `git clean -fd` pour supprimer. `git clean` n'a pas d'annulation, et `-x` supprime aussi votre `.env` et votre `node_modules`. `git reset --hard` rembobine au dernier commit.
* **`git stash push -u -m '…'`**, puis `stash list` / `show -p` / `apply` / `pop` / `drop` / `branch`. Un stash n'est qu'un commit à deux ou trois parents. Pour travailler sur deux choses à la fois, un [worktree](../4-beyond-the-basics/1-git-worktree.md "Un seul dépôt, plusieurs répertoires de travail") est généralement mieux.
* **Detached head :** `git status` pour voir où vous êtes, `git switch -c <nom>` pour garder les commits, `git switch <branche>` pour les abandonner, `git switch -` pour revenir à la branche précédente.
* **Abandonner :** `git merge --abort`, `git rebase --abort`, `git cherry-pick --abort`, `git revert --abort`, `git am --abort`, `git bisect reset` — et, tout à fait légitimement, un `git clone` tout frais dans un nouveau répertoire avec vos fichiers recopiés à la main.
* **Les deux habitudes :** committez petit et souvent, et ne réécrivez jamais un historique partagé.
