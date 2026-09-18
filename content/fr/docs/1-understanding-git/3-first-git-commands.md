---
title: Premiers pas, premières commandes Git
slug: "first-git-commands"
weight: 3
---
# Premiers pas, premières commandes Git

Voilà, maintenant vous devez avoir un tout petit peu de contexte. Comme on vous l'a dit, Git est un logiciel ; il faudrait donc l'installer pour l'utiliser. Mais on est sympas et nous avons promis que tout allait être simple. Donc pour le moment vous pouvez faire tous vos exercices sans rien installer, mais à un moment ou un autre, il faudra s'armer de courage. Les plus hardis sont invités d'ores et déjà à visiter le chapitre [Installation et configuration de Git](../6-appendices/1-git-install.md "Installation et configuration de Git").

Dans ce premier chapitre pratique, nous allons couvrir un terrain immense :

* Nous allons dire à Git qui on est.
* On va se créer un tout premier dépôt Git.
* Nous allons apporter notre premier changement et nous allons l'enregistrer.
* Nous allons tout de suite regarder comment Git est fait à l'intérieur (de manière superficielle).
* Nous pousserons un peu plus loin notre compréhension du « commit » : de quoi il est fait, et pourquoi c'est une chose bien plaisante et bien puissante.

## Un minimum de configuration

> :warning:
> Si vous n'êtes pas à l'aise avec un terminal, je vous invite à faire un passage rapide sur : https://tutorial.djangogirls.org/fr/intro_to_command_line/ ; vous allez voir, on y prend goût rapidement. Notez aussi que les termes « terminal », « émulateur de terminal », « console », « ligne de commande » et « invite de commandes » sont tous parfaitement équivalents. C'est la petite fenêtre dans laquelle on tape des commandes, on appuie sur la touche « entrée » et on voit s'imprimer des caractères à l'écran.

Git n'aura besoin que d'un tout petit bout d'information pour nous aider à démarrer : il faut lui dire qui on est.

À la ligne de commande :

```console
git config --global user.name "Ori Pekelman"
git config --global user.email "ori+git-training@pekelman.com"
```

Mettez-y votre propre nom et votre propre adresse e-mail, bien sûr. Tout au long de ce cours, les sorties d'exemple afficheront les miennes, parce que c'est ce que ma machine imprime réellement.

Comme nous l'avons dit : Git nous permet de collaborer, de savoir qui a fait quel changement, quand et pourquoi. Cette partie va lui permettre de garder l'information du « qui » sans devoir essayer de la deviner.

> :information_source:
> Sur chaque machine, cette action ne doit être faite qu'une seule fois : l'information est enregistrée dans un fichier de configuration, `~/.gitconfig`. Le petit tilde `~` que vous voyez là représente le dossier personnel de l'utilisateur courant ; dans mon cas, ça va être `/Users/oripekelman/`.

## Initialiser votre premier dépôt git : `git init`

Nous allons dès maintenant effectuer quelque chose de remarquable : on va créer notre premier dépôt Git. Et comme moi je n'aime pas trop la magie noire, on va tout de suite tenter de comprendre ce qu'on a fait. D'ici quelques minutes vous allez acquérir quelques connaissances rares et épatantes, et vous pourrez aller faire le fier avec vos amis.

Sur mon ordinateur, je range mes projets dans mon dossier utilisateur sous `projects`. C'est important de bien ranger les choses. On va créer un répertoire à l'intérieur pour notre premier projet, que l'on va nommer « my_first_git_project ».

> :warning:
> Notez que, même si ce cours est en français et que je suis très attaché à notre langue, les choses techniques (comme les noms de fichiers) seront nommées en anglais. Ceci évite le franglais et le français sans accents. Cela nous permet aussi, souvent, de collaborer plus facilement avec d'autres.

Ouvrez votre émulateur de terminal.

On va taper la commande :
```console
mkdir -p ~/projects/my_first_git_project
```

> :information_source:
> `mkdir` est une commande pour créer des répertoires (nous considérons ici que les utilisateurs sous Windows auront suivi le guide d'installation noté plus haut et opté pour le _Windows Subsystem for Linux_). Et on va créer le sous-répertoire `projects/my_first_git_project`. L'option `-p` nous assure que la commande va réussir même si `projects` n'existait pas.

On va changer le répertoire courant pour atteindre le dossier créé au-dessus, tapez donc :

```console
cd ~/projects/my_first_git_project
```

Nous avons un répertoire bien beau, bien neuf, bien propre. Ceci sera notre **répertoire de travail** — retenez le terme anglais, **working directory**.

Git, comme on vous l'a dit, est un logiciel. Pour l'utiliser, on tape à la ligne de commande `git` puis des sous-commandes (qui vont assez souvent avoir elles-mêmes des arguments et des options). Mais notre première commande est simple :

```console
git init
```

Si la vie est belle et que vous avez correctement installé git, la réponse devrait être :

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
hint:
hint: Disable this message with "git config set advice.defaultBranchName false"
Initialized empty Git repository in /Users/oripekelman/projects/my_first_git_project/.git/
```

La ligne qui compte est la dernière : « Dépôt Git vide initialisé dans /Users/oripekelman/projects/my_first_git_project/.git/ ». Toutes les lignes `hint:` au-dessus sont Git qui bavarde à propos du nom de la toute première branche qu'il vient de créer pour nous ; nous y reviendrons, ainsi qu'à ce qu'est une branche, dans [Jouer avec nos révisions](7-play-with-git-revisions.md "Jouer avec nos révisions"). Si vous avez déjà configuré `init.defaultBranch`, vous ne verrez pas ce conseil du tout.

> :information_source:
> Si, dans le répertoire, on tape la commande `ls` pour lister les fichiers, il va nous dire qu'il n'y a absolument rien. En effet, sur des systèmes comme Linux et macOS, les fichiers et répertoires dont le nom commence par un `.` sont cachés. Vous pouvez taper `ls -a` ; vous devriez le voir.

Expliquons ce qui vient de se passer : la commande `git init` a créé dans notre **répertoire de travail** un sous-répertoire caché nommé `.git`. Celui-ci va contenir toutes les informations dont Git aura besoin pour nous aider à sauvegarder notre travail, à suivre les versions et à collaborer avec d'autres.
