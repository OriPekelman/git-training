---
title: Git et son écosystème
slug: "git-ecosystem"
weight: 2
---

# Git et son écosystème

Pour pouvoir faire toutes ces merveilles, Git a dû atteindre un certain niveau de complexité. On pourrait passer des années à apprendre et à maîtriser ses particularités. Git a beaucoup de couches et il existe énormément de manières de l'utiliser : la majorité de ses utilisateurs vont utiliser la ligne de commande (et nous allons vous encourager dans cette voie), mais d'autres l'utilisent avec les nombreux logiciels graphiques (GUI, pour Graphical User Interface) qui existent, par l'intégration aux environnements de développement intégrés (IDE), ou même simplement en utilisant leur navigateur web à travers l'un des nombreux systèmes d'hébergement de code source sur le web (d'abord GitHub, la référence majeure dont nous allons encore parler, mais aussi GitLab, Bitbucket, Codeberg ou un Forgejo que vous hébergez vous-même).

Il s'est aussi développé autour de Git un écosystème d'une incroyable richesse. Tout s'intègre aujourd'hui avec Git. Avec une seule commande, vous pouvez pousser votre code vers un premier système qui va en mesurer la qualité de manière automatique, puis vers d'autres permettant d'en faire la relecture et la validation, qui le passeront à leur tour à un système faisant des tests automatisés… vers un autre encore qui va le déployer, sans intervention humaine, sur des serveurs de test et jusqu'à la glorieuse production.

Je suis sûr qu'après tout ça, vous êtes totalement convaincu qu'il _faut_ apprendre Git, mais peut-être que maintenant vous hésitez, découragé par l'apparente complexité de tout ceci.

Courage ! Dans ce cours, on ne va pas explorer tout ce que Git a à nous proposer : s'il est toujours possible de se compliquer la vie avec cette puissante bête, nous pouvons aussi apprendre à l'utiliser de manière simple, robuste et productive.

Avec seulement quelques commandes et quelques concepts qu'on a déjà évoqués (le **commit**, la **branche**, le **remote**, **push**, **pull** et **merge**), nous allons non seulement réussir rapidement à travailler et à collaborer en équipe… nous allons carrément finir par déployer un vrai site web sur un vrai serveur, sans les mains, en ne faisant rien de plus qu'un `git push`. Et nous allons construire ce déploiement nous-mêmes, à partir d'un dépôt nu et d'un hook de vingt lignes, pour qu'aucune partie n'en soit magique.

Il y a une autre chose qu'il vaut la peine de vous dire tout de suite, parce que c'est ce qui distingue ce cours de la plupart des autres.

Nous allons regarder à l'intérieur. Constamment. Chaque fois que vous taperez une commande, nous ouvrirons `.git` et nous lirons ce qui a changé — les vrais fichiers, les vrais noms de quarante caractères. Vous verrez qu'un **commit** est constitué de quelques lignes de texte que vous pouvez afficher avec un `cat`. Vous verrez qu'une **branche** est un fichier qui contient une ligne. Vous retrouverez votre propre travail supprimé, tranquillement posé dans la base d'objets.

Ça coûte un petit peu plus d'effort dans la première heure que d'apprendre six commandes par cœur. Ça en vaut la peine, et voici la raison honnête : l'interface de Git est un accident historique, pleine de commandes qui font plusieurs choses sans rapport entre elles et de messages d'erreur qui présupposent que vous connaissez déjà la réponse. Si vous n'avez que des incantations mémorisées, la première fois que l'une d'elles échoue vous êtes bloqué et effrayé. Si vous comprenez la poignée d'idées qui se trouvent en dessous — l'adressage par contenu, un graphe immuable d'instantanés, et quelques pointeurs déplaçables vers ce graphe — alors les incantations deviennent évidentes, les messages d'erreur deviennent lisibles, et vous pouvez raisonner pour vous sortir d'un ennui que vous n'avez jamais rencontré auparavant.

Cette compréhension est aussi la partie qui ne périme pas. Les commandes ont changé en vingt ans et changeront encore ; `git switch` n'existait pas quand ce cours a été écrit pour la première fois. Le modèle d'objets, lui, n'a pas changé du tout.

Assez parlé, c'est parti !
