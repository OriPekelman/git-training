---
title: Git, bien démarrer !
type: docs
---
# Git, de l'intérieur

Bonjour et bienvenue.

Ce cours commence par un constat très simple : si vous voulez avoir un métier dans l'informatique, peu importe lequel, connaître Git n'est pas optionnel. Git est utilisé partout.

Ce ne sont pas les tutoriels Git qui manquent, ceux qui vous donnent six commandes et vous souhaitent bonne chance. Celui-ci n'en fait pas partie. Ici nous faisons quelque chose d'un peu inhabituel et, je vous le promets, bien plus utile : **chaque fois que vous tapez une commande, nous ouvrons le capot et nous regardons ce qu'elle a fait.** Vous allez créer un commit, puis vous allez aller le lire — le vrai fichier, dans le vrai répertoire, avec ses vrais quarante caractères de hash. Vous allez découvrir qu'une branche est un fichier texte qui contient une ligne. Vous allez retrouver votre propre travail supprimé, tranquillement posé dans la base d'objets, qui vous attend.

Ça coûte un petit peu plus d'effort dans la première heure. C'est rentabilisé à peu près pour toujours, parce que l'alternative consiste à apprendre des incantations par cœur et à paniquer le jour où l'une d'elles échoue.

> :information_source:
> Ce cours suppose que vous savez ouvrir un terminal et que vous acceptez d'y taper des choses. Il ne suppose rien sur votre connaissance de la gestion de versions, ni de la programmation système. Si un terminal vous intimide, [cette introduction en douceur](https://tutorial.djangogirls.org/fr/intro_to_command_line/) représente quinze minutes bien investies ; revenez ensuite.

## Comment lire ce cours

Les parties 1 et 2 constituent le cours proprement dit, et elles sont faites pour être lues dans l'ordre, les mains sur le clavier. Tout ce qui suit, à partir de la partie 3, relève plutôt de la référence : allez y piocher quand vous en avez besoin.

Si vous n'avez jamais utilisé Git du tout, commencez par le début et ne sautez pas [Au cœur du dépôt, au cœur du commit](docs/1-understanding-git/5-inside-git.md) — c'est le chapitre sur lequel tout le reste du cours s'appuie.

Si vous utilisez déjà Git tous les jours et que vous voulez les parties que vous ne connaissez probablement pas : [Un seul dépôt, plusieurs répertoires de travail](docs/4-beyond-the-basics/1-git-worktree.md), [Détourner git notes pour le plaisir et pour le profit](docs/4-beyond-the-basics/3-git-notes.md), et [Les choses inspirées par Git](docs/4-beyond-the-basics/6-inspired-by-git.md).

## Table des matières

<!-- BEGIN GENERATED TOC (utilities/gen_toc.py) -->

### Partie 1 — Comprendre Git

Ce qu'est Git, et ce qui se passe réellement dans `.git` quand vous sauvegardez votre travail.

1. [Git, c'est quoi ?](docs/1-understanding-git/1-what-is-git.md)
1. [Git et son écosystème](docs/1-understanding-git/2-git-ecosystem.md)
1. [Premiers pas, premières commandes Git](docs/1-understanding-git/3-first-git-commands.md)
1. [Sauvegardons notre travail !](docs/1-understanding-git/4-save-work-with-git.md)
1. [Au cœur du dépôt, au cœur du commit](docs/1-understanding-git/5-inside-git.md)
1. [On sait sauvegarder… mais comment modifier ? supprimer ? annuler ?](docs/1-understanding-git/6-modify-delete-files-with-git.md)
1. [Jouer avec nos révisions](docs/1-understanding-git/7-play-with-git-revisions.md)

### Partie 2 — Collaborer

Les branches, les dépôts distants, les fusions, les conflits, et comment s'en sortir quand ça tourne mal.

1. [Collaborer grâce à Git](docs/2-collaborating/1-collaborate-with-git.md)
1. [Travailler avec des dépôts distants](docs/2-collaborating/2-git-remote.md)
1. [Récupérer et envoyer du code](docs/2-collaborating/3-git-clone-pull-remote.md)
1. [Un peu de structure SVP](docs/2-collaborating/4-git-repo-structure.md)
1. [Mettre en œuvre un workflow collaboratif efficace](docs/2-collaborating/5-git-workflow.md)
1. [Garder un historique propre, se remettre de ses erreurs](docs/2-collaborating/6-git-cleanup.md)

<!-- END GENERATED TOC -->

## À propos

Écrit par Ori Pekelman. Les exemples ne sont pas décoratifs : ils sont régénérés avec le Git installé par `utilities/scenario.sh`, si bien que ce que vous lisez est ce que la commande affiche réellement. Si vous trouvez une erreur, c'est un bug — signalez-le.
