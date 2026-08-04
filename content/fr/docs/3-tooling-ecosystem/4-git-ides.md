---
title: Les éditeurs, les IDE et le navigateur de fichiers
slug: "git-ides"
weight: 24
---
# Les éditeurs, les IDE et le navigateur de fichiers

Le chapitre précédent portait sur les clients Git dédiés — des programmes dont Git est tout le métier. Celui-ci porte sur l'intégration Git de l'outil dans lequel vous passez réellement votre journée. Et cette distinction compte plus qu'il n'y paraît, parce que l'intégration de votre éditeur a un avantage qu'aucun client autonome ne pourra jamais avoir : **il sait déjà quelle ligne vous êtes en train de regarder.**

C'est là tout l'argument. « Qui a changé cette ligne, et pourquoi » est la question la plus courante que quiconque pose à un système de gestion de versions, et votre éditeur est le seul outil qui puisse y répondre sans que vous ayez d'abord à lui dire où regarder.

## Visual Studio Code

Très probablement l'outil qu'utilise le plus grand nombre de lecteurs de ce chapitre, alors soyons concrets.

Le support de Git est intégré, ce n'est pas une extension. La vue **Source Control** liste les fichiers modifiés, et cliquer sur l'un d'eux ouvre un diff côte à côte plutôt que de simplement vous montrer le fichier. Vous indexez depuis là — et vous pouvez indexer une seule **section** ou un intervalle de lignes sélectionné depuis la vue de diff, ce qui est le `git add -p` dont nous parlions au dernier chapitre, à la souris. Il y a une boîte pour le message de commit, et les contrôles de synchronisation/push/pull vivent dans la barre d'état.

Deux choses intégrées méritent d'être nommées spécifiquement :

**L'éditeur de fusion à trois voies.** Quand une fusion entre en conflit, VS Code peut vous montrer trois panneaux — « Incoming », « Current » et le Résultat que vous construisez — au lieu de vous larguer dans un fichier plein de marqueurs `<<<<<<<`. Vu la confusion que ces marqueurs causent les dix premières fois qu'on les rencontre, c'est véritablement précieux, et c'est le seul cas où je pense qu'un outil graphique est *franchement meilleur* que le texte brut. On ne vous protège de rien ; vous voyez les trois mêmes versions que voit Git, disposées pour qu'un humain puisse les comparer.

**Timeline.** Dans la barre latérale de l'explorateur, une chronologie par fichier qui mélange l'historique Git et les sauvegardes locales du fichier. Très pratique pour « ce fichier marchait il y a une heure » — y compris dans les cas où le changement n'a jamais été committé du tout.

Les extensions que les gens installent réellement :

* **GitLens.** La grosse. Le **blame** en ligne au bout de la ligne où se trouve votre curseur — auteur, date, message de commit, là, directement — plus des infobulles riches, une vue de l'historique du fichier, un graphe de commits, et une navigation « ouvrir le commit de cette ligne ». Si vous n'installez qu'une extension Git, c'est celle-là. C'est aussi la manière la plus rapide de développer le réflexe de *demander* qui a écrit une ligne, parce que la réponse est déjà à l'écran.
* **Git Graph.** Dessine le graphe des **commit**s, correctement, dans un onglet. Fait ce que le chapitre précédent disait qu'une interface graphique sert à faire, sans quitter l'éditeur.
* **GitHub Pull Requests.** Relisez les pull requests dans l'éditeur : extraire une branche de PR, lire le diff avec le code environnant disponible, laisser des commentaires en ligne, approuver. Relire du code dans un navigateur, c'est le relire sans pouvoir sauter à une définition, ce qui est une mauvaise manière de relire du code. Ceci le corrige.

> :information_source:
> Tous les forks de VS Code — Cursor, Windsurf, VSCodium et compagnie — héritent de toute cette pile, parce qu'ils sont VS Code en dessous. La vue Source Control, l'éditeur de fusion et l'écosystème d'extensions sont tous là. Si vous êtes passé à l'un des forks orientés IA, rien de cette section ne change.

## JetBrains : IntelliJ IDEA, PyCharm, WebStorm, GoLand, Rider

Franchement, et je ne pense pas que ce soit controversé : **c'est la meilleure intégration Git de tous les IDE.** Si vous travaillez déjà dans un IDE JetBrains, vous n'avez probablement pas besoin d'un client Git séparé du tout.

Ce qui justifie cette affirmation :

**Local History.** Commençons par là, parce que c'est la fonctionnalité qui a sauvé le plus de gens, et que ce **n'est pas Git**. L'IDE tient son propre enregistrement horodaté de chaque changement de chaque fichier — éditions, refactorisations, suppressions, déplacements de fichiers — indépendamment du fait que vous ayez jamais committé, indexé, ou même enregistré délibérément. Clic droit sur un fichier (ou un répertoire, ou le projet) et vous obtenez « Local History → Show History », avec des diffs et une restauration en un clic.

> :warning:
> Local History est un filet de sécurité pour le travail que vous n'avez *pas* encore committé — l'heure d'édition que vous étiez sur le point de perdre. Ce n'est pas de la gestion de versions : c'est local, ça expire, ce n'est pas partagé, et cela ne survit ni à une réinstallation de l'IDE ni au travail depuis une autre machine. Servez-vous-en pour vous remettre d'un accident, puis committez correctement. C'est un extincteur, pas une caserne de pompiers.

**La résolution de conflits.** L'outil de fusion à trois panneaux, mais avec la compréhension du langage propre à l'IDE dedans : il sait reconnaître et appliquer automatiquement les changements non conflictuels, mettre en évidence ceux qui se heurtent véritablement, et vous laisser éditer le résultat avec la complétion et la conscience syntaxique complètes. Résoudre un conflit dans un fichier que vous pouvez encore parcourir est une tout autre expérience que le résoudre dans un éditeur de texte.

**Shelve contre stash.** JetBrains propose les deux et la distinction mérite d'être apprise. `git stash` est le mécanisme propre à Git, que nous avons rencontré en partie 2 — il vit dans le dépôt et n'importe quel outil Git peut le voir. Une *étagère* (shelf) est propre à l'IDE : un patch enregistré, tenu hors de Git, que vous pouvez nommer, garder aussi longtemps que vous voulez, appliquer partiellement (fichier par fichier, ou section par section), et remettre à un collègue sous forme de fichier. Utilisez `stash` pour « garde ça cinq minutes » ; utilisez une étagère pour « garde cette expérience sous le coude pendant quinze jours pendant que je fais autre chose ».

**Annotate.** Clic droit dans la gouttière → Annotate with Git Blame, et chaque ligne se voit dotée d'un auteur et d'une révision. Cliquez sur l'une d'elles et vous êtes dans ce commit. C'est la même idée que GitLens et c'est intégré.

**Le rebase interactif depuis le log.** Dans la vue du log Git, sélectionnez un intervalle de commits et vous obtenez un rebase interactif graphique : glissez pour réordonner, marquez pour écraser, reformulez, supprimez. C'est la présentation la plus claire de `git rebase -i` que j'aie vue où que ce soit — ce qui ne veut pas dire que vous devriez apprendre l'opération ici en premier. Apprenez ce qu'elle fait depuis la ligne de commande, où vous pouvez voir la liste de tâches que Git construit réellement, et ensuite profitez de la jolie version.

## Neovim et Vim

**`vim-fugitive`.** Celui de Tim Pope, et la raison pour laquelle beaucoup d'utilisateurs de Vim n'ont jamais installé de client Git. Il fait de `:Git` une commande de premier ordre — `:Git blame` ouvre un panneau de blame défilant en synchronisation que vous pouvez parcourir, `:Git` tout seul ouvre un tampon de statut où vous indexez et désindexez d'une frappe, `:Gdiffsplit` met côte à côte les versions de l'index et de travail sous forme de deux tampons, si bien que vous pouvez *résoudre un conflit en éditant à travers les fenêtres*. Ce dernier point est l'astuce : cela transforme les opérations Git en manipulation de tampons, ce en quoi Vim est déjà le meilleur.

**`gitsigns.nvim`.** Des signes dans la gouttière pour les lignes ajoutées, changées et supprimées, plus les opérations que vous voulez sur elles, là, directement : indexer une section, réinitialiser une section, prévisualiser une section, sauter à la suivante, et le blame en ligne pour la ligne courante. C'est celui qui change vos habitudes quotidiennes, parce qu'indexer une seule section devient deux frappes.

**`diffview.nvim`.** Un véritable navigateur de diffs et d'historique de fichiers : relisez tous les changements d'une branche, ou l'historique d'un seul fichier, ou un conflit de fusion, dans une véritable disposition à trois voies.

**`neogit`.** Une tentative explicite d'apporter l'expérience Magit — voir juste en dessous — à Neovim. Un unique tampon de statut qui est aussi un système de menus, où vous appuyez sur des touches pour construire des commandes Git. Si le paragraphe qui suit vous séduit et que vous n'allez pas passer à Emacs, c'est votre voie.

## Emacs : Magit

Magit mérite son propre paragraphe, et pas par politesse.

C'est sans doute la meilleure interface pour Git que quiconque ait construite, sous quelque forme que ce soit. La conception est un tampon de statut qui est simultanément un affichage et une surface de contrôle : tout ce qui concerne l'état actuel du dépôt est montré sous forme de sections repliables — fichiers non suivis, changements non indexés, changements indexés, commits non poussés, stashes — et chacune d'elles est actionnable là où elle se trouve. Mettez le curseur sur une section et appuyez sur `s` pour l'indexer. Sur une ligne dans une section, avec une région sélectionnée, `s` indexe *ces lignes-là*. `c c` committe. `b b` change de branche. `r i` démarre un rebase interactif, présenté comme un menu de ce que vous pouvez faire ensuite.

Ce qui le rend différent de toutes les autres interfaces Git, c'est la découvrabilité. Appuyez sur une touche de préfixe et Magit vous montre un menu — les commandes disponibles, leurs options, et ce que chaque option veut dire — de sorte que vous apprenez le véritable vocabulaire de Git en utilisant l'interface, plutôt qu'à sa place. Les options que vous basculez dans le menu correspondent à de vraies options de ligne de commande. Rien n'est caché.

C'est pourquoi ce qui suit est vrai, et pourquoi je le mentionne dans un cours bâti sur la ligne de commande : **certaines personnes apprennent véritablement Git par Magit**, et elles finissent par le comprendre mieux que la moyenne, pas moins bien. C'est la seule interface graphique que je qualifierais de *pédagogique*. Si vous utilisez déjà Emacs, utilisez Magit. Si vous n'utilisez pas Emacs, c'est l'un des deux ou trois arguments que les gens donnent réellement pour s'y mettre.

## Zed et Helix

**Zed** a un support de Git intégré et documenté : un panneau Git montrant l'arbre de travail et la zone d'indexation, une vue de diff à l'échelle du projet où vous indexez ou désindexez des sections individuelles, l'historique par fichier, la création et le changement de branche, le stash, les worktrees, fetch/push/pull avec sélection du dépôt distant, une vue de résolution des conflits de fusion, et des permaliens cliquables vers GitHub, GitLab, Bitbucket, sourcehut et Codeberg. Il rédigera aussi un message de commit avec un LLM si vous le lui demandez — ce qui, comme toutes les offres de ce genre, convient pour les commits ennuyeux et ne remplace pas le fait de dire *pourquoi* sur ceux qui comptent.

**Helix** est un éditeur modal de la lignée de Vim, avec une philosophie délibérément différente au sujet des greffons et des fonctions intégrées. Plutôt que de figer une cible mouvante dans un livre, allez lire sa propre documentation pour savoir ce que couvre aujourd'hui son support de Git — elle est courte, et elle sera exacte.

## Windows, et le navigateur de fichiers

Windows mérite sa propre section parce que le point d'intégration y est différent : c'est le gestionnaire de fichiers.

**TortoiseGit** met Git dans le shell de l'Explorateur Windows. Des icônes en surimpression sur les icônes de fichiers et de dossiers vous disent d'un coup d'œil ce qui est modifié, indexé, ignoré ou propre ; un clic droit sur n'importe quoi vous donne un menu contextuel d'opérations Git ; et il y a de vraies boîtes de dialogue pour le commit, le log, le diff, le blame et la fusion. Pour les gens qui pensent leur projet en termes de dossiers plutôt que de dépôt — et pour les nombreux rôles d'une entreprise qui ne sont pas des développeurs à plein temps — c'est une véritable bonne porte d'entrée. Notez que c'est une intégration à l'Explorateur, pas un greffon d'éditeur, elle se compose donc avec tout ce que vous utilisez par ailleurs. (Son ancêtre TortoiseSVN faisait le même travail pour Subversion, ce qui explique que le nom semble venir d'une autre époque ; c'est le cas.)

**Git for Windows** est le paquet qui vous donne `git` lui-même, plus **Git Bash** — un shell basé sur msys2 qui fait que chaque commande de ce cours fonctionne, sans modification, sous Windows. Il amène aussi `gitk` et `git gui` avec lui, et installe le gestionnaire d'identifiants qui gère l'authentification auprès des forges.

**WSL2** est ce que je recommanderais aujourd'hui à un développeur Windows, et la raison n'est pas idéologique : c'est qu'essentiellement chaque outil, hook, script et configuration de CI du monde Git est écrit en supposant un shell Unix, et que sous WSL2 vous en avez simplement un. Les fins de ligne, les bits de permission, les hooks shell et les lignes `#!` cessent tous d'être des cas particuliers.

> :warning:
> Il y a un vrai piège avec WSL2 et c'est une falaise de performance : gardez vos dépôts *à l'intérieur* du système de fichiers Linux, pas sur les lecteurs Windows montés sous `/mnt/c/`. Traverser cette frontière à chaque opération de fichier rend les opérations Git dramatiquement plus lentes sur tout dépôt de taille réelle. [Installation et configuration de Git](../6-appendices/1-git-install.md "Installation et configuration de Git") couvre cela, ainsi que la question de `core.autocrlf` que tout le monde rencontre sous Windows dès sa première semaine.

## La séparation qui compte

Voici l'opinion pour laquelle ce chapitre existe, et c'est la même que celle à laquelle le chapitre précédent est arrivé par l'autre bout :

**Utilisez l'intégration de votre éditeur pour tout ce qui *lit* le dépôt. Utilisez la ligne de commande pour tout ce qui le *réécrit*.**

La lecture — blame, historique, diffs, indexation au niveau de la section, « à quoi ressemblait ce fichier à ce commit », chercher dans le log — est là où l'information supplémentaire de l'outil graphique est un profit pur. Il connaît la position de votre curseur, il peut afficher trois panneaux côte à côte, il peut mettre le nom d'un auteur au bout de la ligne, et cela ne vous coûte rien de vous tromper de clic. Lisez dans l'éditeur. Lisez beaucoup ; la plupart des gens ne lisent pas assez leur dépôt, et de loin.

La réécriture — rebase, amend, reset, cherry-pick, filtrage d'historique, push forcé — est là où vous devez savoir *exactement ce qui s'est exécuté*, parce que ce sont les opérations après lesquelles le dépôt n'est pas simplement le dépôt d'avant plus quelque chose. **HEAD** a bougé, des références ont bougé, des commits ont été remplacés par des commits différents aux **SHA**s différents, et les anciens ne sont plus atteignables que par le **reflog**. Quand cela dérape, votre capacité à récupérer dépend entièrement de votre capacité à dire ce qui s'est passé. « J'ai cliqué sur le bouton qui disait Rebase » n'est pas quelque chose à partir de quoi on peut raisonner. `git rebase --onto main feature~3 feature`, si.

Et remarquez que ce n'est pas une règle sur la confiance. C'est une règle sur la *réversibilité*. Lire est gratuit et les mauvaises lectures ne coûtent rien. La réécriture est là où réside le coût, c'est donc là que vous voulez les mains sur les vraies commandes.

Il y a une exception que je concède volontiers, et c'est l'éditeur de fusion. Quand un conflit survient, la vue à trois panneaux de VS Code ou de JetBrains est meilleure que le fichier rempli de marqueurs, et elle ne fait rien dans votre dos — les trois mêmes versions, disposées pour un humain. Prenez-la.

## Récapitulatif : les éditeurs et les IDE

* L'intégration Git de votre éditeur a un avantage qu'aucun client autonome n'a : il sait quelle ligne vous regardez, si bien que « qui a changé ceci et pourquoi » est toujours à un geste de distance.
* **VS Code** : vue Source Control intégrée, indexation au niveau de la section et de la ligne depuis le diff, l'éditeur de fusion à trois voies, et la Timeline (qui inclut les sauvegardes locales non committées). Les extensions qui comptent : **GitLens** (blame en ligne, historique, graphe), **Git Graph**, **GitHub Pull Requests** (relecture avec navigation dans le code). Les forks de VS Code héritent de tout cela.
* Les IDE **JetBrains** ont la meilleure intégration de leur catégorie : **Local History** (ce n'est pas Git — un filet de sécurité local qui expire et n'est pas partagé), un résolveur de conflits conscient du langage, le **shelve** à côté de `git stash`, **Annotate** pour le blame, et un rebase interactif graphique depuis la vue du log.
* **Vim/Neovim** : `vim-fugitive` (`:Git` comme interface de premier ordre, résolution de conflits à travers les tampons), `gitsigns.nvim` (signes dans la gouttière plus indexer/réinitialiser/prévisualiser une section), `diffview.nvim`, `neogit`.
* **Emacs : Magit** — un tampon de statut qui est aussi une surface de contrôle, avec des menus découvrables qui vous enseignent le véritable vocabulaire de Git. Certains apprennent Git par lui, et l'apprennent bien.
* **Zed** documente un panneau Git, une zone d'indexation, l'indexation par section, l'historique des fichiers, les branches, le stash, les worktrees, la résolution de conflits et les permaliens de forge. Pour **Helix**, lisez sa propre documentation.
* **Windows** : **TortoiseGit** pour l'intégration au shell de l'Explorateur et les icônes en surimpression, **Git for Windows** / **Git Bash** pour que les commandes Unix de ce cours fonctionnent telles quelles, et **WSL2** comme recommandation — mais gardez les dépôts dans le système de fichiers Linux, pas sous `/mnt/c/`.
* **La séparation : l'éditeur pour lire, la ligne de commande pour réécrire.** Lire est gratuit ; réécrire est là où il faut savoir exactement ce qui s'est exécuté. L'éditeur graphique de conflits de fusion est l'exception qui vaut la peine d'être prise.
