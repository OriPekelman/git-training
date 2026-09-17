---
title: Installation et configuration de Git
slug: "git-install"
weight: 51
---
# Installation et configuration de Git

Comme nous l'avons indiqué, il y a bien des manières d'utiliser Git — par le web, avec un client graphique, depuis un IDE — mais ce cours se concentre sur son usage à la ligne de commande, avec la version « officielle ». Tout ce dont vous avez besoin commence ici : https://git-scm.com/downloads

> :information_source:
> **La ligne de commande.** Si vous n'êtes pas à l'aise avec un terminal, faites un rapide détour par https://tutorial.djangogirls.org/fr/intro_to_command_line/ — vous allez voir, on y prend goût rapidement. Et retenez que « terminal », « émulateur de terminal », « console », « ligne de commande » et « invite de commandes » désignent tous la même petite fenêtre dans laquelle on tape des choses avant d'appuyer sur entrée.

Télécharger un installeur fonctionne. Mais chaque système d'exploitation a sa manière préférée d'installer des logiciels, et la raison de la préférer n'est pas la pureté : c'est que le gestionnaire de paquets *met aussi à jour* la chose. Un Git installé en double-cliquant sur un installeur en 2023 est un Git de 2023.

## Installer Git

### Linux

Sur un système Debian ou Ubuntu :

```console
sudo apt update
sudo apt install git
```

Sur Fedora, RHEL, Rocky, Alma :

```console
sudo dnf install git
```

Sur Arch et ses dérivés :

```console
sudo pacman -S git
```

Sur Alpine (et donc dans un très grand nombre de conteneurs) :

```console
apk add git
```

> :information_source:
> Vous verrez beaucoup de tutoriels — dont une version plus ancienne de celui-ci — vous dire d'installer `git-all`. Ce n'est pas faux, mais ce n'est probablement pas ce que vous voulez. Sur Debian et Ubuntu, `git-all` est un métapaquet dont le seul travail est de tirer *tout* : `git-gui` et `gitk` (les outils graphiques), `git-svn` et `git-cvs` (des passerelles vers des systèmes de gestion de version que vous n'avez très probablement jamais utilisés), `git-email` (l'envoi de patchs par courriel), `git-mediawiki`, `gitweb`, et la documentation. Le `git-all` de Fedora est la même idée. Le paquet que vous voulez réellement s'appelle `git`, et il fait à peu près le dixième de la taille. Si vous découvrez plus tard que vous voulez `gitk`, installez `gitk`.

**Le Git de votre distribution est probablement plus ancien que ce cours.** Les distributions gèlent les versions des paquets quand elles gèlent une version, et Git sort une nouvelle version tous les trimestres environ. Ubuntu 24.04 LTS, par exemple, livre Git 2.43 — ce qui est très bien, mais ce n'est pas le Git sur lequel nous tapons.

Vérifiez ce que vous avez :

```console
git --version
```

```console
git version 2.51.0
```

Ce cours est écrit pour Git 2.51. Tout ce qui date de 2.40 et au-delà suivra sans surprise ; en dessous, vous commencez à perdre des commodités que nous mentionnons (`git switch` et `git restore` sont arrivés en 2.23, `push.autoSetupRemote` en 2.37, la signature de commits en SSH en 2.34). S'il vous faut quelque chose de plus récent que ce que propose votre distribution, par ordre croissant d'effort :

1. Sur Ubuntu, les mainteneurs de Git publient une archive de rétroportages : `sudo add-apt-repository ppa:git-core/ppa && sudo apt update && sudo apt install git`. Elle suit l'amont de près, même si elle peut avoir une version de retard pendant quelques semaines.
2. Fedora, Arch et Alpine sont déjà proches de l'amont ; il n'y a rien à faire.
3. Compiler depuis les sources. La compilation de Git est honnêtement l'une des plus agréables qui soient — clonez https://github.com/git/git, installez les en-têtes de développement que votre distribution nomme `libcurl`, `zlib`, `openssl` et `expat`, puis `make prefix=/usr/local all install`. Faites-le quand vous avez une raison, pas par principe.

### macOS

Trois options, de la plus petite à la plus agréable.

**Les outils en ligne de commande de Xcode.** Le vieux conseil était « installez Xcode », soit un IDE de quinze gigaoctets que vous n'aviez pas demandé. Vous n'en avez pas besoin. Vous avez besoin des outils en ligne de commande, qui font quelques centaines de mégaoctets :

```console
xcode-select --install
```

Une fenêtre apparaît, vous cliquez sur Installer, et vous obtenez `git`, `make`, un compilateur et le reste du mobilier de développement Unix. C'est aussi ce que macOS lui-même vous proposera la première fois que vous taperez `git` sur une machine neuve.

**Homebrew**, qui est le chemin que nous prendrions réellement :

```console
brew install git
```

Le Git de Homebrew suit l'amont, donc vous en obtenez un à jour et `brew upgrade` le maintient à jour.

**MacPorts**, si c'est votre monde : `sudo port install git`.

> :warning:
> **Apple livre un Git ancien, et c'est peut-être celui que vous utilisez.** La version d'Apple est très en retard sur l'amont — souvent de plusieurs années — et elle s'identifie obligeamment, ce qui permet de la reconnaître. Quelque chose de cet ordre, les chiffres exacts dépendant de votre version de macOS :
>
> ```console
> git --version
> git version 2.39.5 (Apple Git-154)
> ```
>
> Ce suffixe `(Apple Git-NNN)` est le signe. Si vous avez installé un Git plus récent et que vous le voyez encore, le problème est votre `PATH` : deux binaires `git` existent et le shell trouve le mauvais en premier.
>
> ```console
> which -a git
> ```
>
> ```console
> /opt/homebrew/bin/git
> /usr/bin/git
> ```
>
> La liste est dans l'ordre de recherche de votre shell. Ici le `git` de Homebrew gagne, ce qui est bien ce que nous voulons. Si `/usr/bin/git` arrive en premier, placez le répertoire de Homebrew plus tôt dans le `PATH`, dans votre `~/.zshrc` — sur Apple Silicon c'est `/opt/homebrew/bin`, sur les Mac Intel `/usr/local/bin`.

### Windows

Windows offre plus de choix que partout ailleurs, et fait rare, ils sont tous bons.

**winget**, qui est désormais livré avec Windows et constitue l'option de première classe :

```console
winget install -e --id Git.Git
```

**Chocolatey** (`choco install git`) et **Scoop** (`scoop install git`) fonctionnent tous les deux et suivent l'amont de près. Prenez celui que vous utilisez déjà.

Tous les trois installent la même chose : **Git for Windows**, qui est bien plus que le binaire `git`. Il apporte **Git Bash**, un petit environnement de shell façon Unix, et c'est là-dedans que la plupart des développeurs Windows utilisent réellement Git. Git Bash est franchement bon — il vous donne `ls`, `grep`, `ssh`, et un shell dans lequel les commandes de ce cours fonctionnent telles quelles.

> :information_source:
> **Notre recommandation pour ce cours reste WSL2** — le Windows Subsystem for Linux. Installez une distribution (`wsl --install -d Ubuntu`), puis suivez les instructions Linux ci-dessus et vous voilà dans un vrai Linux, où chaque commande de ce cours est exactement la commande que tape un lecteur sous Linux. Pas de traduction, pas de surprise.
>
> Le compromis honnête : **ne laissez pas Git traverser la frontière entre les systèmes de fichiers.** WSL2 voit vos disques Windows sous `/mnt/c`, et y travailler est *lent* — pas un peu lent, douloureusement lent, parce que chaque accès à un fichier passe d'un système d'exploitation à l'autre. La documentation de Microsoft elle-même dit de ranger les fichiers de vos projets dans le système de fichiers Linux (`/home/<vous>/projets`) plutôt que sous `/mnt/c`. Git touche des milliers de fichiers pour un seul `git status`, et c'est exactement le type de charge qui en souffre. Gardez vos dépôts à l'intérieur de WSL, et si vous voulez les éditer depuis un éditeur Windows, prenez-en un qui parle WSL (VS Code le fait, nativement).

Deux réglages propres à Windows causent plus de tracas que tout le reste réuni.

**Les fins de ligne.** Windows termine ses lignes par un retour chariot suivi d'un saut de ligne (`CRLF`) ; tout le reste du monde utilise le saut de ligne seul (`LF`). Si personne n'y pense, le même fichier finit commité dans les deux formes et chaque `git diff` affiche le fichier entier comme modifié. L'installeur vous proposera `core.autocrlf`, qui convertit à l'entrée et à la sortie du dépôt, globalement, sur votre machine.

Nous vous suggérons de ne *pas* compter là-dessus, et de placer plutôt un fichier `.gitattributes` à la racine du dépôt :

```
* text=auto
```

Pourquoi le fichier plutôt que le réglage ? Parce que `.gitattributes` est **commité**. C'est une propriété du projet, donc elle s'applique à toute personne qui le clone, y compris celles qui n'ont jamais rien configuré. `core.autocrlf` est une propriété de *votre machine*, donc elle vous protège vous et personne d'autre — et le contributeur suivant recasse le dépôt. La documentation de Git recommande l'attribut `text=auto` pour exactement cette raison. Si vous l'ajoutez à un dépôt qui a déjà des fins de ligne mélangées, `git add --renormalize .` corrige les fichiers existants en un seul commit.

**Les chemins longs.** Windows a une limite historique de 260 caractères sur les chemins, et certains projets (tout ce qui contient des `node_modules` profondément imbriqués, par exemple) trébucheront dessus avec une erreur `Filename too long`. Git for Windows sait la contourner :

```console
git config --global core.longpaths true
```

> :information_source:
> `core.longpaths` n'existe que dans Git for Windows — vous ne le trouverez pas dans la documentation amont de `git config`, et le régler sous Linux ou macOS ne fait rien. La documentation de Git for Windows prévient elle-même que l'Explorateur, `cmd.exe` et divers outils ne savent toujours pas gérer ces chemins ; l'activer fait donc marcher Git pendant que d'autres choses peuvent continuer à se plaindre.

### Vous l'avez peut-être déjà

Git est installé dans à peu près toutes les images d'intégration continue (les runners GitHub Actions, GitLab, CircleCI), dans toutes les images de conteneur de développement, et dans la plupart des images Docker de base qui ne sont pas délibérément minimales. Si vous vous demandez si une machine a Git et lequel :

```console
git --version
```

Si cela affiche une version, vous avez terminé. Si cela affiche `command not found`, revenez en haut de ce chapitre.

## Tester que l'installation est correcte

Ouvrez un terminal et tapez `git`, puis la touche entrée. Vous devriez voir apparaître un long texte d'aide plein de mots très anxiogènes. Respirez profondément. Vous pouvez ignorer tout ceci pour le moment.

```console
usage: git [-v | --version] [-h | --help] [-C <path>] [-c <name>=<value>]
           [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]
           [-p | --paginate | -P | --no-pager] [--no-replace-objects] [--no-lazy-fetch]
           [--no-optional-locks] [--no-advice] [--bare] [--git-dir=<path>]
           [--work-tree=<path>] [--namespace=<name>] [--config-env=<name>=<envvar>]
           <command> [<args>]

These are common Git commands used in various situations:

start a working area (see also: git help tutorial)
   clone      Clone a repository into a new directory
   init       Create an empty Git repository or reinitialize an existing one

work on the current change (see also: git help everyday)
   add        Add file contents to the index
   mv         Move or rename a file, a directory, or a symlink
   restore    Restore working tree files
   rm         Remove files from the working tree and from the index

examine the history and state (see also: git help revisions)
   bisect     Use binary search to find the commit that introduced a bug
   diff       Show changes between commits, commit and working tree, etc
   grep       Print lines matching a pattern
   log        Show commit logs
   show       Show various types of objects
   status     Show the working tree status

grow, mark and tweak your common history
   backfill   Download missing objects in a partial clone
   branch     List, create, or delete branches
   commit     Record changes to the repository
   merge      Join two or more development histories together
   rebase     Reapply commits on top of another base tip
   reset      Reset current HEAD to the specified state
   switch     Switch branches
   tag        Create, list, delete or verify a tag object signed with GPG

collaborate (see also: git help workflows)
   fetch      Download objects and refs from another repository
   pull       Fetch from and integrate with another repository or a local branch
   push       Update remote refs along with associated objects

'git help -a' and 'git help -g' list available subcommands and some
concept guides. See 'git help <command>' or 'git help <concept>'
to read about a specific subcommand or concept.
See 'git help git' for an overview of the system.
```

C'est Git 2.51 qui parle. Les versions plus anciennes affichent une liste plus courte — `restore`, `switch` et `backfill` sont des arrivées récentes — donc si la vôtre diffère légèrement, rien ne va mal.

Sur macOS, si les outils en ligne de commande ne sont pas installés, taper `git` fera au contraire apparaître une fenêtre qui propose de les installer. Dites oui. C'est fait.

## Configurer Git

Maintenant, et c'est important, il faut dire à Git qui vous êtes. Comme nous l'avons indiqué au tout début, Git va nous permettre de suivre qui a fait quoi, quand et pourquoi — et pour cela il a besoin qu'on lui dise le « qui ».

```console
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

> :warning:
> **Cette adresse de courriel entre dans chaque commit que vous faites, et elle est publique pour toujours.** Pas « visible sur une page web que vous pouvez retirer » — cuite dans l'objet commit, ce qui veut dire cuite dans son **SHA**, ce qui veut dire qu'elle voyage vers chaque clone du dépôt. Vous ne pouvez pas la changer après coup sans réécrire l'historique.
>
> Si vous préférez ne pas publier votre adresse personnelle, GitHub vous donnera un alias de la forme `1234567+votrenom@users.noreply.github.com` accompagné d'un réglage « Keep my email addresses private », et GitLab a l'équivalent. Mettez *celle-là* comme `user.email` et la forge saura toujours que les commits sont les vôtres. Voir [Créer et configurer son compte GitHub ou GitLab](3-github-gitlab.md "Créer et configurer son compte GitHub ou GitLab").

Puis quatre réglages qui vous épargneront de vraies contrariétés.

**Le nom de la première branche.** `git init` crée toujours une branche appelée `master`, et vous fait à chaque fois un petit sermon à ce sujet ; GitHub et GitLab prennent `main` par défaut. Choisissez, et cessez d'y penser :

```console
git config --global init.defaultBranch main
```

**Votre éditeur.** Git ouvre un éditeur dès que vous lancez `git commit` sans `-m`, pour `git rebase -i`, et pour les messages de fusion. Si rien n'est configuré il utilise `$EDITOR`, et si celui-ci n'est pas défini il utilise `vi`. Ce qui mène à la panique la plus courante de tout ce domaine :

> :information_source:
> **« J'ai lancé `git commit` et je suis pris au piège. »** Vous êtes dans vim. Rien n'est cassé. Pour en sortir : tapez votre message de commit, puis appuyez sur `Échap`, puis tapez `:wq` et entrée — c'est *écrire et quitter*, et votre commit est fait. Si vous préférez abandonner le commit, appuyez sur `Échap` et tapez `:q!` puis entrée — *quitter, jeter* — et Git vous dira `Aborting commit due to empty commit message.` Rien n'a été perdu, dans un cas comme dans l'autre.

Pour ne pas être dans vim la prochaine fois, choisissez autre chose :

```console
git config --global core.editor "nano"
```

ou, pour VS Code — et le `--wait` n'est pas optionnel, c'est lui qui fait que Git attend que vous fermiez l'onglet :

```console
git config --global core.editor "code --wait"
```

La même forme marche pour d'autres éditeurs : `"subl -n -w"`, `"zed --wait"`, `"micro"`. Et si vous *voulez* vim, `git config --global core.editor "vim"` en fait au moins un choix plutôt qu'un défaut.

**Ce que `git pull` devrait faire.** Par défaut `git pull` fusionne, et quand votre branche et celle du dépôt distant ont toutes les deux bougé, il fabrique un commit de fusion que vous n'avez pas demandé. Refuser cela est une bonne habitude :

```console
git config --global pull.ff only
```

Désormais `git pull` réussit silencieusement quand il peut simplement faire une **avance rapide**, et s'arrête pour vous le dire quand il ne peut pas — moment où vous décidez, délibérément, de fusionner ou de rebaser. Nous y revenons longuement dans [Récupérer et envoyer du code](../2-collaborating/3-git-clone-pull-remote.md "Récupérer et envoyer du code").

**Pousser une nouvelle branche.** Sans aide, le premier push d'une nouvelle branche donne ceci :

```console
fatal: The current branch feature has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin feature
```

À chaque fois, pour toujours. Depuis Git 2.37 vous pouvez simplement lui dire de faire la chose évidente :

```console
git config --global push.autoSetupRemote true
```

et `git push` sur une nouvelle branche répond :

```console
To /tmp/asr2/origin.git
 * [new branch]      feature -> feature
branch 'feature' set up to track 'origin/feature'.
```

> :information_source:
> Ce que nous avons réglé ici est le minimum pour que la suite de ce cours se comporte comme décrit. Il existe un ensemble de configuration plus long et plus tranché qui vaut le coup une fois que vous êtes à l'aise — des alias, un meilleur diff, une invite de shell qui affiche votre **branche** — et cela a sa place avec le reste de l'outillage, dans [Faire sienne la ligne de commande](../3-tooling-ecosystem/1-git-tools.md "Faire sienne la ligne de commande").

### Où vit la configuration

Chaque `--global` ci-dessus a écrit dans un fichier. Git en lit plusieurs, dans l'ordre, et les derniers l'emportent :

| Portée | Fichier | Se règle avec |
| --- | --- | --- |
| système | `/etc/gitconfig` | `git config --system` |
| utilisateur | `~/.gitconfig`, ou `~/.config/git/config` s'il existe | `git config --global` |
| dépôt | `.git/config` | `git config --local`, le défaut |
| arbre de travail | `.git/config.worktree` | `git config --worktree` |

Ce sont de simples fichiers texte au format INI. Vous avez le droit de les ouvrir dans un éditeur ; `git config --global --edit` le fait pour vous.

`--local` est le défaut, ce qui veut dire qu'à l'intérieur d'un dépôt un simple `git config user.email "..."` le règle **pour ce dépôt seulement**. C'est la manière la plus simple d'utiliser une identité différente pour un projet.

Et quand vous n'arrivez pas à déterminer d'où vient un réglage — ce qui arrive plus souvent qu'on ne le voudrait — demandez :

```console
git config list --show-origin
```

```console
file:/Users/oripekelman/.gitconfig	user.name=Ori Pekelman
file:/Users/oripekelman/.gitconfig	user.email=ori@pekelman.com
file:/Users/oripekelman/.gitconfig	init.defaultbranch=main
```

Ajoutez `--show-scope` et il vous dit en plus si chaque ligne est `system`, `global`, `local` ou `worktree`.

> :information_source:
> Depuis Git 2.46, `git config` a de véritables sous-commandes — `git config list`, `git config get user.email`, `git config set user.name "..."`, `git config unset`. Les anciennes formes en options (`git config --list`, `git config --get`) fonctionnent toujours partout et restent ce que le monde tape, mais elles sont formellement dépréciées. Nous utilisons les deux dans ce cours, délibérément, parce que vous rencontrerez les deux.

### Deux identités sur une machine : les inclusions conditionnelles

Voilà l'astuce véritablement utile. Vous avez un courriel professionnel et un personnel, et vous aimeriez que les commits faits dans `~/work/` portent l'identité professionnelle sans jamais avoir à y penser.

Git sait inclure un autre fichier de configuration *conditionnellement*, selon l'endroit où se trouve le dépôt. Dans `~/.gitconfig` :

```
[user]
	name = Ori Pekelman
	email = ori@pekelman.com
[init]
	defaultBranch = main
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work
```

Et dans `~/.gitconfig-work`, uniquement ce qui diffère :

```
[user]
	email = ori@example-corp.com
```

Remarquez la **barre oblique finale** de `gitdir:~/work/` — c'est elle qui fait que le motif correspond à tout ce qui se trouve sous le répertoire. Sans elle, vous ne visez qu'un seul chemin exact, en vous demandant pourquoi rien ne se passe.

Prouvons-le. Dans un dépôt situé sous `~/work/` :

```console
git config get user.email
```

```console
ori@example-corp.com
```

Et dans un dépôt situé ailleurs :

```console
git config get user.email
```

```console
ori@pekelman.com
```

Le mécanisme `includeIf` est arrivé dans Git 2.13 avec `gitdir:` ; la 2.23 a ajouté `onbranch:` (appliquer cette configuration tant qu'on est sur une branche correspondant à un motif) et la 2.36 `hasconfig:remote.*.url:` (l'appliquer dans tout dépôt dont le dépôt distant est *ce* serveur-là), ce qui convient encore mieux au partage pro/perso — cela suit le code plutôt que le répertoire.

## Prouver que le tout fonctionne

Une configuration que vous n'avez pas testée est une configuration que vous avez devinée. Deux minutes, un dépôt jetable, et nous savons que toute la chaîne d'outils fonctionne de bout en bout.

```console
cd /tmp
git init hello-git
cd hello-git
printf '# Hello, Git\n' > readme.md
git add readme.md
git commit -m"Mon premier commit"
```

Ce qui devrait répondre :

```console
Initialized empty Git repository in /tmp/hello-git/.git/
[main (root-commit) 71e50b1] Mon premier commit
 1 file changed, 1 insertion(+)
 create mode 100644 readme.md
```

Trois choses à remarquer, parce que chacune confirme un réglage.

* `Initialized empty Git repository` **sans le sermon `hint:`** au sujet des noms de branches veut dire que `init.defaultBranch` a pris effet.
* `[main (root-commit) ...]` dit `main`, pas `master` — la même confirmation, vue de l'autre côté.
* Git ne s'est pas plaint d'un `Author identity unknown` — donc `user.name` et `user.email` sont réglés. Votre `71e50b1` sera différent du mien, et c'est normal : le hachage d'un **commit** inclut votre nom, votre courriel et la seconde à laquelle vous l'avez fait.

Vérifiez l'identité qui a réellement été enregistrée :

```console
git log --pretty=fuller
```

```console
commit 71e50b1af89627c5065c45979d42a9c252a4c1e6
Author:     Ori Pekelman <ori@pekelman.com>
AuthorDate: Wed Jul 29 23:36:13 2026 +0200
Commit:     Ori Pekelman <ori@pekelman.com>
CommitDate: Wed Jul 29 23:36:13 2026 +0200

    Mon premier commit
```

Si cela dit ce que vous attendez, vous êtes installé et configuré. Supprimez le répertoire — `cd /tmp && rm -rf hello-git` — et allez faire la vraie chose dans [Premiers pas, premières commandes Git](../1-understanding-git/3-first-git-commands.md "Premiers pas, premières commandes Git").

L'autre moitié de la mise en place, nécessaire dès que vous voudrez pousser vers un serveur, se trouve dans [Configurer Git avec une clé SSH](2-git-ssh.md "Configurer Git avec une clé SSH").

## Récapitulatif `git --version` `git config`

* Préférez le gestionnaire de paquets de votre système d'exploitation à un installeur téléchargé, parce que le gestionnaire de paquets met aussi Git à jour.
* Linux : `apt install git`, `dnf install git`, `pacman -S git`, `apk add git`. Le paquet `git-all` est un métapaquet qui traîne avec lui l'interface graphique, la passerelle Subversion et les outils de courriel — c'est `git` tout court que vous voulez.
* macOS : `xcode-select --install` pour la petite chaîne d'outils d'Apple, ou `brew install git` pour un Git à jour. La version d'Apple est ancienne et s'identifie comme `(Apple Git-NNN)` ; `which -a git` vous dit laquelle votre `PATH` trouve en premier.
* Windows : `winget install -e --id Git.Git`, ou Chocolatey, ou Scoop — tous vous donnent Git for Windows et Git Bash. Pour ce cours, WSL2 est encore mieux, à condition de garder vos dépôts dans le système de fichiers Linux et non sous `/mnt/c`.
* Sous Windows, commitez `* text=auto` dans un `.gitattributes` plutôt que de compter sur `core.autocrlf`, parce que le fichier voyage avec le dépôt et le réglage non. Utilisez `core.longpaths true` quand la limite des 260 caractères de Windows vous mord.
* `git --version` est la manière de savoir ce qu'a une machine — y compris les runners d'intégration continue et les conteneurs de développement, qui ont presque toujours Git déjà installé.
* `git config --global user.name` et `user.email` sont obligatoires, et le courriel est public dans chaque commit, pour toujours.
* À régler une bonne fois : `init.defaultBranch main`, `core.editor`, `pull.ff only`, `push.autoSetupRemote true`.
* Si `git commit` vous largue dans vim : `Échap` puis `:wq` pour enregistrer, `Échap` puis `:q!` pour abandonner.
* La configuration est en couches — `/etc/gitconfig`, `~/.gitconfig`, `.git/config`, `.git/config.worktree` — et `git config list --show-origin` vous dit de quel fichier vient une valeur.
* `[includeIf "gitdir:~/work/"]` garde une identité professionnelle séparée d'une personnelle, automatiquement. Attention à la barre oblique finale.
