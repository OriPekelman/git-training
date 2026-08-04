---
title: Les clients Git graphiques
slug: "git-guis"
weight: 23
---
# Les clients Git graphiques

Ce cours a passé deux parties entières à insister sur la ligne de commande, vous pourriez donc vous attendre à ce que ce chapitre soit un paragraphe à contrecœur et un haussement d'épaules. Ce n'est pas le cas. Un bon client Git graphique est un instrument véritablement utile, et refuser d'en utiliser un par machisme de terminal est une manière de se compliquer la vie sans raison.

Soyons précis sur les raisons pour lesquelles cela aide, parce que « c'est plus facile » n'est pas la raison.

## Là où une interface graphique est honnêtement meilleure

**Parce que l'historique est un graphe, et qu'une image d'un graphe vaut mieux qu'une description.** Nous dessinons le graphe des **commit**s avec `git log --oneline --graph --decorate --all` depuis la partie 2, et ça marche — mais l'art ASCII a un plafond rigide. Montrez-lui huit branches actives, deux ou trois fusions qui se sont croisées, et un rebase qui en a déplacé la moitié, et vous obtenez un mur de caractères `|` et `\` sur lequel vos yeux glissent. Un vrai dessin, avec des couloirs, des couleurs et de la place pour respirer, vous dit en une seconde ce que le terminal met une minute à épeler. Quand vous essayez de comprendre « comment ces deux branches ont-elles fini comme ça », cette seconde compte.

**Parce qu'indexer par section, et surtout par ligne, est un travail de souris.** `git add -p` est une commande merveilleuse et vous devriez la connaître. Mais c'est un questionnaire : Git vous montre une **section**, demande `Stage this hunk [y,n,q,a,d,s,e,?]?`, et si vous en voulez la moitié, vous finissez en mode `e` à éditer un diff à la main, ce qui est un petit acte de violence. Dans une interface graphique, vous cliquez sur les trois lignes que vous voulez, elles deviennent vertes, terminé. Découper une zone de travail en désordre en trois **commit**s propres — ce que vous devriez faire bien plus souvent que vous ne le faites — passe de la corvée au plaisir.

**Parce que l'archéologie est plus rapide quand on peut cliquer.** « Qui a écrit cette ligne » → « qu'est-ce que ce commit a changé d'autre » → « à quoi ressemblait ce fichier avant » → « montre-moi le diff par rapport au point de branchement » est une chaîne de quatre questions, et dans une interface graphique chaque maillon est un clic. Dans le terminal, chaque maillon est une commande avec des arguments qu'il faut se rappeler, et au troisième vous avez perdu le fil de ce que vous cherchiez vraiment.

Rien de tout cela n'est une concession. Ce sont trois vraies forces et elles concernent toutes la *lecture* du dépôt.

## Pourquoi nous vous avons quand même enseigné la ligne de commande

Parce que toute interface graphique est une façade avec pertes par-dessus les mêmes commandes, et que la perte n'est pas répartie uniformément.

La correspondance est quasi parfaite pour les choses faciles. Committer, indexer, changer de branche, récupérer, pousser — le bouton fait ce que fait la commande, et vous ne perdez rien. La correspondance s'amincit exactement là où Git devient intéressant : le rebase, le cherry-pick, les sous-modules, les worktrees, tout ce qui implique `--force-with-lease`, tout ce où il faut savoir précisément quelle référence a bougé.

Et puis il y a le moment qui tranche le débat. **Vous finirez dans un état cassé au milieu d'un rebase.** Pas peut-être — vous y finirez, tout le monde y finit, nous y avons consacré un chapitre entier. Et quand cela arrivera, vous regarderez une boîte de dialogue qui dit que quelque chose s'est mal passé et qui vous propose deux boutons, dont aucun n'est « dis-moi dans quel état est réellement le dépôt ». La personne qui sait taper `git status`, `git rebase --abort` et `git reflog` s'en sort en quinze secondes. Celle qui ne le sait pas est bloquée, et son geste suivant est généralement de supprimer le clone et de recommencer — ce qui est la manière dont des semaines de travail se perdent, en 2026, dans un outil graphique.

Il y a une seconde raison, moins dramatique, et qui a récemment pris des dents : **la ligne de commande est l'interface que tout le reste pilote.** Votre pipeline de CI lance des commandes `git`. Votre hook de déploiement lance des commandes `git`. Votre framework de pre-commit lance des commandes `git`. Et votre agent de codage lance des commandes `git` — un agent n'a pas de mains pour votre souris, si bien que tout le vocabulaire qu'il utilise pour travailler sur votre dépôt est celui que vous avez appris en partie 1. Savoir ce que font ces commandes est désormais la différence entre superviser un agent et espérer.

> :information_source:
> La recommandation est donc les deux, avec une division du travail claire, et c'est la même que celle que ce cours fait à propos des éditeurs dans [Les éditeurs, les IDE et le navigateur de fichiers](4-git-ides.md "Les éditeurs, les IDE et le navigateur de fichiers") :
>
> * **L'interface graphique pour lire et pour indexer.** L'historique, le blame, les diffs, « qu'est-ce qui a changé et qui l'a fait », découper une zone de travail en désordre en commits propres.
> * **La ligne de commande pour tout ce qui réécrit.** Rebase, amend, reset, cherry-pick, push forcé, filtrage d'historique. Tout ce où vous voulez savoir *exactement* ce qui s'est exécuté.
>
> Ce n'est pas un compromis entre deux camps. C'est ce que font réellement la plupart des gens expérimentés.

## Le paysage

Ce qui suit porte sur ce à quoi chacun *sert*. Je ne vous dis délibérément pas ce que chacun coûte, s'il est gratuit, ni à quel point il est activement maintenu — ces choses changent, ceci est un livre, et un livre qui devine à leur sujet est pire qu'un livre qui se tait. Allez voir le site du projet lui-même ; cela vous prend trente secondes et ce sera juste.

**GitKraken.** Celui auquel les gens pensent quand ils disent « celui avec le graphe ». Multiplateforme, et l'historique visuel en est la pièce maîtresse — grand, clair, déplaçable. Fort pour transformer les fusions et les rebases en manipulation directe : faites glisser une branche sur une autre. Intégration profonde avec les forges hébergées, si bien que les tickets et les pull requests apparaissent dans le client.

**Fork.** macOS et Windows. Rapide, discret, et étonnamment complet pour un outil qui paraît si simple — rebase interactif, un bon résolveur de conflits, blame, sous-modules, et un diff d'images. C'est celui que je vois le plus souvent sur les machines de gens qui vivent *aussi* dans le terminal, ce qui est un signal parlant : il n'essaie pas de vous cacher Git.

**Sublime Merge.** Des auteurs de Sublime Text, et il en hérite la qualité importante : il est *rapide*, sur des dépôts où d'autres outils commencent à bouder. Son trait distinctif est celui qui me tient le plus à cœur — il vous montre la commande Git qu'il s'apprête à lancer, et il expose une palette de commandes plutôt que d'enterrer les opérations dans des menus. Il se lit comme un client Git écrit par des gens qui aiment Git.

**Tower.** macOS et Windows, et le plus « outil professionnel » du lot dans le ressenti : des déroulés soignés, une annulation pour un éventail surprenant d'opérations, un support minutieux des recoins délicats comme les sous-modules et les worktrees. Visant carrément les gens qui l'utilisent toute la journée.

**GitHub Desktop.** Délibérément limité, et c'est là tout l'intérêt — il ne tente pas d'exposer tout Git. Il couvre le clonage, les branches, le commit, le push, la pull request, et un déroulé de conflit bien fait, sur un workflow en forme de GitHub. Pour un débutant, ou pour un designer ou un rédacteur qui doit contribuer à un dépôt et n'a pas envie d'apprendre Git ce mois-ci, c'est une recommandation bienveillante. Pour quoi que ce soit de plus, vous en atteindrez vite les limites, et il ne vous aidera pas quand ce sera le cas.

**GitUp.** macOS. Intéressant pour une raison qu'aucun des autres ne partage : il est bâti sur la prémisse que le graphe devrait se mettre à jour *en direct* pendant que vous le manipulez, avec une véritable pile d'annulations, si bien que vous êtes encouragé à tripoter l'historique et à voir ce qui se passe. C'est ce qui se rapproche le plus d'un *bac à sable* Git, et cela en fait un excellent outil pédagogique pour exactement les opérations qui effraient les gens.

**SmartGit.** Multiplateforme, Linux compris, et celui qui va le plus loin du côté entreprise : plusieurs fournisseurs d'hébergement, une intégration profonde de la relecture, et un solide discours sur les « revues distribuées ». Dense, mais il y a beaucoup de choses dedans.

**Sourcetree.** Le client d'Atlassian, pour macOS et Windows. La raison de sa présence dans cette liste est qu'un très grand nombre d'équipes l'ont déjà parce qu'elles ont déjà Bitbucket et Jira, et l'intégration est tout l'argument.

### Ceux que vous avez déjà

Voici une jolie astuce. Demandez à votre Git quelles commandes graphiques il connaît :

```console
git help -a
```

Quelque part dans la sortie :

```console
   citool                  Graphical alternative to git-commit
   gitk                    The Git repository browser
   gui                     A portable graphical interface to Git
   instaweb                Instantly browse your working repository in gitweb
```

`gitk` est un navigateur d'historique, et `git gui` est un outil de commit avec indexation au niveau de la section et de la ligne. Ils sont écrits en Tcl/Tk, ils ont l'air de 1998, et ils font partie du projet Git lui-même — ce qui veut dire qu'ils n'ont pas de télémétrie, pas de compte, pas d'inscription, et aucune opinion sur la forge que vous utilisez. Et ils fonctionnent encore parfaitement bien. Un `gitk --all` la prochaine fois que vous êtes perdu dans un enchevêtrement de branches est un geste tout à fait raisonnable, et `git citool` est `git gui` en mode « fais juste un commit ».

> :warning:
> « Livré avec Git » dépend de la manière dont Git a été empaqueté pour vous. Sur ce Mac, Git vient de Homebrew, `git help -a` liste `gitk` — et `command -v gitk` ne trouve rien, parce que Homebrew sépare les outils Tcl/Tk dans une formule `git-gui` distincte. Les distributions Linux les empaquettent souvent séparément aussi (`gitk`, `git-gui`), tandis que Git for Windows les inclut. Si la commande manque, c'est une décision d'empaquetage, pas une installation cassée : installez le paquet `gitk` / `git-gui` de votre plateforme.

### Observer ce que votre interface graphique a réellement fait

Puisque ce cours est bâti sur le fait de regarder sous le capot, voici l'astuce qui rend honnête n'importe quel client graphique, qu'il le veuille ou non : **après qu'il a fait quelque chose que vous n'avez pas complètement compris, interrogez le reflog.**

Une branche a été rebasée sur `main` — et il n'importe véritablement pas que cela soit arrivé parce que quelqu'un a tapé `git rebase main` ou parce que quelqu'un a cliqué sur un bouton intitulé « Rebase onto main », parce que Git enregistre la même chose dans les deux cas. Ensuite :

```console
git reflog -8
```

```console
d0cb4bd HEAD@{0}: rebase (finish): returning to refs/heads/topic
d0cb4bd HEAD@{1}: rebase (pick): Add c
7f66bdf HEAD@{2}: rebase (pick): Add b
7dd54fb HEAD@{3}: rebase (start): checkout main
7d9b88e HEAD@{4}: commit: Add c
10e6bad HEAD@{5}: checkout: moving from main to topic
7dd54fb HEAD@{6}: commit: Second commit on main
4c3419c HEAD@{7}: checkout: moving from main to main
```

Lisez-le de bas en haut et toute l'opération est racontée : le rebase a commencé par extraire `main` à `7dd54fb`, a rejoué « Add b » puis « Add c » comme de *nouveaux* commits, et a finalement déplacé la branche `topic` à la fin du rejeu. Remarquez que `Add c` apparaît deux fois, à `HEAD@{4}` sous `7d9b88e` et à `HEAD@{1}` sous `d0cb4bd` — voilà ce qu'est un rebase : le même changement, un commit flambant neuf. Et l'original est toujours là, nommé, à une commande de distance.

Aucun client ne peut se cacher de cela, parce que le reflog est écrit par Git lui-même. Quoi qu'ait fait le bouton, voici ce qu'il a fait. Servez-vous-en chaque fois qu'une interface graphique vous surprend — c'est la leçon de Git la moins chère qui soit.

### Et dans le terminal

Si ce que vous vouliez vraiment était une interface plus agréable sans quitter le terminal du tout, c'est une vraie catégorie avec de vraies réponses — `lazygit` et `gitui` vous donnent des panneaux, une indexation au clavier et un graphe navigable dans une interface texte. Ils vivent dans [Faire sienne la ligne de commande](1-git-tools.md "Faire sienne la ligne de commande") avec le reste de la boîte à outils du terminal.

## En choisir un

Cinq questions. La dernière est celle qui compte le plus.

1. **Montre-t-il le vrai graphe ?** Pas une ligne droite embellie — le véritable graphe des **commit**s, avec toutes les branches, les commits de fusion avec leurs deux parents visibles, et le travail non référencé que vous pouvez encore atteindre. Si un outil vous dessine un historique simplifié, il vous ment sur la chose même pour laquelle vous êtes venu à lui.
2. **Sait-il faire un rebase interactif ?** Réordonner, écraser, reformuler, supprimer, éditer. C'est le test décisif de la profondeur réelle de l'outil, parce que c'est l'opération où une façade superficielle ne peut pas faire semblant.
3. **Comprend-il les sous-modules, LFS et les worktrees ?** C'est là que les clients s'effondrent discrètement. Un outil qui ne connaît pas les **worktree**s vous montrera n'importe quoi le jour où vous en utiliserez un ; un outil qui ne connaît pas **LFS** committera joyeusement un beau gâchis de 400 Mo en forme de pointeur.
4. **Téléphone-t-il à la maison ?** Certains d'entre eux sont des comptes et des abonnements avec un client attaché. Cela peut vous convenir parfaitement. Décidez-en exprès plutôt que par accident, et vérifiez ce que dit la politique de votre employeur sur un outil qui a un accès en lecture à tout votre code source.
5. **Vous montre-t-il les commandes qu'il lance ?** C'est le vrai révélateur. Un client qui fait apparaître `git rebase --onto ...` avant de l'exécuter vous enseigne quelque chose chaque fois que vous l'utilisez, et au bout de six mois vous savez faire l'opération sans lui. Un client qui cache la commande vous garde dépendant de lui, pour toujours, et vous abandonne à l'instant où quelque chose tourne mal. Préférez l'honnête.

Cette cinquième question est aussi la raison pour laquelle une interface graphique n'est pas un raccourci qui permet de sauter ce cours. Les bonnes supposent que vous savez ce que sont un **commit**, une **référence** et l'**index** — ce qui, après plusieurs chapitres, est votre cas. C'est ce qui les rend puissantes entre vos mains et dangereuses entre celles d'un débutant.

## Récapitulatif : les clients graphiques

* Une interface graphique est véritablement meilleure pour trois choses : voir le graphe des **commit**s comme une image, indexer par **section** ou par ligne à la souris, et cliquer à travers l'archéologie du code.
* Toute interface graphique est une façade avec pertes par-dessus les mêmes commandes. La perte est maximale exactement là où Git est le plus intéressant : rebase, cherry-pick, sous-modules, worktrees, push forcé.
* Quand un rebase casse — et il cassera — il vous faut `git status`, `git rebase --abort` et `git reflog`. Aucune boîte de dialogue ne les remplace.
* La ligne de commande est aussi l'interface que pilotent la CI, les hooks et les agents de codage, ce n'est donc plus une connaissance optionnelle.
* Répartition recommandée : **l'interface graphique pour lire et indexer, la ligne de commande pour tout ce qui réécrit l'historique.**
* Le paysage par forme : **GitKraken** (le graphe, fusions par glisser-déposer), **Fork** (rapide et complet, ne cache pas Git), **Sublime Merge** (rapide, vous montre les commandes), **Tower** (minutieux, large annulation), **GitHub Desktop** (délibérément limité, bienveillant avec les débutants), **GitUp** (graphe en direct avec annulation, excellent pour apprendre), **SmartGit** (profondeur entreprise, Linux inclus), **Sourcetree** (Atlassian et Jira).
* `gitk`, `git gui` et `git citool` viennent du projet Git lui-même — à l'air vieillot, sans télémétrie, toujours utiles. Leur présence dépend de votre empaquetage.
* `lazygit` et `gitui` sont la réponse en terminal au même besoin — voir [Faire sienne la ligne de commande](1-git-tools.md "Faire sienne la ligne de commande").
* En choisir un : vrai graphe, rebase interactif, sous-modules/LFS/worktrees, télémétrie, et par-dessus tout **vous montre-t-il la commande qu'il lance**.
