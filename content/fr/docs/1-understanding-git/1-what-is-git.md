---
title: Git, c'est quoi ?
slug: "what-is-git"
weight: 1
---
# Git, c'est quoi ?

Bonjour et bienvenue. Ce cours commence par un constat très simple : si vous voulez avoir un métier dans l'informatique, peu importe lequel, connaître Git n'est pas optionnel ; Git est utilisé partout.

Tout d'abord, un mot sur le sujet, puis une petite explication sur le « pourquoi ».

Au plus haut niveau, on peut dire que Git est un logiciel qui permet de sauvegarder du code. C'est le standard absolu dans le domaine : la seule et unique manière de faire votre ctrl-s (ou cmd-s).

Vous pouvez apprendre le HTML et le CSS (pour créer des pages web), les langages de script comme Python, Ruby ou PHP (pour créer des applications web), le C ou le Rust (pour créer votre propre système d'exploitation)… Mais sans une maîtrise minimale de Git, vous n'avez pas vraiment appris à sauvegarder votre travail.

Évidemment, si tout ce qu'il savait faire, c'était de la sauvegarde, ça serait la fonction de sauvegarde la plus bizarre et la plus compliquée du monde, et vous seriez en droit de décider que finalement l'informatique est une affaire de fous.

En réalité, c'est quelque chose de bien plus puissant : Git vous permet de sauvegarder votre travail en gardant toutes les étapes intermédiaires de son élaboration. Imaginez un « ctrl-z » qui fonctionne à tout jamais, après avoir éteint sa machine… qui fonctionne même quand on passe à un autre ordinateur. C'est puissant, ça.

> On va y revenir… mais gardez en tête un premier mot technique : le « commit ». C'est l'enregistrement d'un état de votre code, d'une version, d'un changement unique.

Mais Git est bien sûr bien plus fort que ça : il nous permet non seulement d'avoir un historique complet des changements et le moyen de restaurer n'importe quel moment du passé… il nous permet aussi d'avoir de multiples options différentes du même travail, en même temps. Avoir deux, trois, mille pistes d'exploration, pouvoir basculer de l'une à l'autre, emprunter un bout d'idée d'ici, puis un bout de là-bas, et composer ainsi votre version principale.

> Deux autres mots techniques. D'abord la « branch », la branche : une version de votre travail, de votre code, qui peut vivre en même temps que d'autres versions. Puis « merge », la fusion : la possibilité d'apporter ou de « mélanger » dans une branche les modifications faites dans une autre.

Enfin — et c'est peut-être ce qu'il y a de plus merveilleux dans Git, la raison profonde pour laquelle vous devriez prendre ce cours au sérieux — Git ne permet pas seulement de sauvegarder votre propre travail, il vous donne aussi accès à celui des autres. Il vous permet non seulement d'avoir de multiples versions de votre code, mais aussi d'avoir de multiples personnes ayant chacune ses propres versions, ses propres pistes… et de constituer avec tout ça une seule version `main`.

> :information_source:
> Historiquement, cette branche s'appelait **master**. GitHub et GitLab la nomment désormais **main** dans les nouveaux dépôts, pour des raisons culturelles, et la plupart des projets démarrés ces dernières années font de même. Votre propre `git init`, en revanche, crée toujours **master** sauf si vous le configurez autrement — nous verrons comment dans [Jouer avec nos révisions](7-play-with-git-revisions.md "Jouer avec nos révisions").

Git permet une collaboration à une échelle sans précédent ; des milliers, voire des centaines de milliers de contributeurs qui travaillent ensemble pour créer une œuvre unique. Git est en effet ce qu'on appelle un « système de gestion de versions distribué ». En gros, vous pouvez sauvegarder votre travail en local, mais aussi pousser votre code vers un autre ordinateur qui aura alors sa propre copie indépendante du même projet.

> Derniers quatre mots techniques pour cette introduction : le **repository**, ou le **dépôt**, c'est l'entrepôt, le répertoire qui va contenir le code d'un projet ; puis le « remote », qui est l'adresse d'un dépôt distant (sur un serveur sur internet par exemple, comme GitHub) qui va contenir une copie distincte du même projet. **Push**, ou « pousser », nous permet d'envoyer notre code vers le **remote**. La commande **pull**, ou « tirer », nous permet à l'inverse de télécharger du code depuis un dépôt distant vers notre machine locale.

Au tout début, j'ai déclaré que la connaissance de Git n'est pas optionnelle, et voilà pourquoi : personne ne travaille dans son coin. Et la manière dont nous travaillons aujourd'hui ensemble dans le milieu informatique est totalement centrée autour de ce système qui nous permet de collaborer à l'élaboration de nos créations.

Git est jeune : il a été créé en 2005, il a donc aujourd'hui une vingtaine d'années. En deux décennies, il s'est imposé comme le système majeur de gestion de code source, LE standard. Il existait bien sûr des systèmes similaires avant lui (CVS, Subversion, Visual SourceSafe) ; ils ont largement disparu — SourceSafe n'est plus supporté par Microsoft depuis bien plus de dix ans, et CVS est une pièce de musée. Subversion survit encore dans quelques recoins, surtout là où de très gros fichiers binaires sont en jeu.

Certains systèmes non-Git sont encore réellement utilisés : Mercurial n'est jamais mort, et il tourne toujours dans quelques très grandes maisons — le **Sapling** de Meta est issu de cette lignée. Bazaar, en revanche, est bel et bien terminé. Et il se passe de vraies choses nouvelles : **Jujutsu** (`jj`) et **Pijul** sont les challengers modernes intéressants, et il est révélateur que Jujutsu sache utiliser un dépôt Git ordinaire comme espace de stockage, ce qui vous permet de l'essayer sur un vrai projet sans rien convertir. Nous revenons sur tout cela dans [Les choses inspirées par Git](../4-beyond-the-basics/6-inspired-by-git.md "Les choses inspirées par Git").

Et puis il y a les gens qui bricolent leurs propres petits systèmes (copier et renommer des répertoires de code en sauvegarde1, backup2, bk17, utiliser Dropbox, pourquoi pas un petit serveur FTP) mais ceux-là ne peuvent plus espérer trouver un emploi dans le domaine ni avancer dans leur carrière.
