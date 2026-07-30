---
title: Travailler avec des dépôts distants
slug: "git-remote"
weight: 12
---
# Travailler avec des dépôts distants

Tout ce que nous avons fait jusqu'ici s'est passé sur notre propre disque. Nous avons créé des **blob**s, des **tree**s et des **commit**s, nous avons déplacé **HEAD**, nous avons fait des branches et fusionné l'une dans l'autre — et pas un seul octet n'a quitté notre machine.

Cela vaut la peine de s'y arrêter, parce que c'est ce qui rend Git différent des systèmes de gestion de versions qui l'ont précédé. Git n'a pas besoin d'un serveur pour fonctionner. Un dépôt est complet. L'historique est *le nôtre*.

Mais nous voulons bien travailler avec d'autres. Ou avec nous-mêmes sur une autre machine. Ou simplement avoir une copie quelque part qui survivra à un café renversé. Il nous faut donc apprendre à notre dépôt l'existence d'un ailleurs.

Cet ailleurs s'appelle un **remote**, un dépôt distant.

## Qu'est-ce qu'un `remote` ?

Voici tout le secret, et c'est une déception : un **remote** est un *nom pour une URL*, écrit dans un fichier texte.

C'est tout. Pas de démon, pas de session, pas de magie. Prouvons-le. Nous revoilà dans notre projet :

```console
cd ~/projects/my_first_git_project
```

Regardons le fichier de configuration de notre dépôt, qui vit dans le répertoire `.git` que nous explorons depuis le début :

```console
cat .git/config
```

```console
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
```

> :information_source:
> Sous Linux, vous verrez deux lignes de moins : `ignorecase` et `precomposeunicode` sont là parce que macOS a un système de fichiers qui a des opinions sur les majuscules et les caractères accentués. Nous reviendrons sur `ignorecase` quand nous parlerons des noms de branches, parce que cela peut vraiment vous faire mal.

Maintenant, il nous faut quelque chose qui serve de dépôt distant. Et voici la première bonne nouvelle de ce chapitre : **un répertoire sur votre propre disque est un dépôt distant parfaitement valable**. Nous n'avons besoin d'aucun compte nulle part, d'aucun réseau, d'aucune clé. Nous utiliserons cette astuce pendant tout le chapitre, parce qu'elle vous permet de suivre et d'*expérimenter* — casser des choses, en supprimer, tout recommencer — sans demander la permission à personne.

Nous allons créer proprement le côté « serveur » dans un instant. Pour le moment, contentons-nous de le déclarer :

```console
git remote add origin ~/projects/my_first_git_project.git
```

Git ne dit absolument rien, ce qui, comme nous l'avons appris, est la manière qu'a Git de dire « très bien ». Regardons de nouveau notre fichier de configuration. La section `[core]` est inchangée ; en bas, trois nouvelles lignes :

```console
cat .git/config
```

```console
{..}
[remote "origin"]
	url = /Users/oripekelman/projects/my_first_git_project.git
	fetch = +refs/heads/*:refs/remotes/origin/*
```

Un en-tête de section, une URL, et une ligne très cryptique. Prenons-les une à une.

`[remote "origin"]` — nous avons créé un dépôt distant et nous l'avons appelé `origin`. Le nom est de notre choix.

`url = /Users/oripekelman/projects/my_first_git_project.git` — l'adresse. Notez que le shell a développé notre `~` en chemin réel avant même que Git ne le voie ; le vôtre affichera votre propre répertoire personnel.

Et puis cette troisième ligne, qui est la raison d'être de ce chapitre.

### Le **refspec**, ou : les dix minutes les plus utiles de votre carrière Git

```console
	fetch = +refs/heads/*:refs/remotes/origin/*
```

Ceci est un **refspec**. C'est une correspondance. Il dit : *quand tu récupères depuis ce dépôt distant, prends les références qu'il a et écris-les ici*.

Lisez-le comme trois parties séparées par un deux-points, plus un signe en tête :

* `+` — « force ». Écrase la destination même si la nouvelle valeur n'est pas un descendant de l'ancienne. Les références de suivi distant sont un cache, donc nous voulons toujours la dernière vérité, même si la vérité s'est déplacée de côté.
* `refs/heads/*` — la **source**. Ce motif est évalué *sur le dépôt distant*. `refs/heads/`, c'est là que vivent les branches — rappelez-vous `.git/refs/heads/master` du chapitre sur les branches. Donc : « toutes leurs branches ».
* `refs/remotes/origin/*` — la **destination**, évaluée *localement*. Donc : « écris chacune sous `refs/remotes/origin/`, en gardant son nom ».

Ainsi, la branche appelée `master` sur le serveur devient, localement, une référence appelée `refs/remotes/origin/master`. Que nous écrivons habituellement `origin/master`.

C'est tout. Chaque fois que vous voyez quelque chose comme `origin/main`, vous regardez un fichier local dont le chemin a été calculé par cette unique ligne de configuration.

> :information_source:
> Les **refspec**s apparaissent partout dès qu'on sait les voir : dans `git fetch`, dans `git push`, dans `git ls-remote`, dans la configuration de tous les systèmes de CI que vous déboguerez un jour. Presque toutes les choses déroutantes à propos des dépôts distants se révèlent être un refspec dont vous ignoriez l'existence. Nous nous en resservirons, délibérément, au chapitre suivant.

### Regarder nos dépôts distants

Trois commandes, par ordre croissant de bavardage. `git remote` tout court affiche seulement les noms, un par ligne — `origin`. Ajoutez `-v` pour « verbose » et vous obtenez les URL :

```console
git remote -v
```
```console
origin	/Users/oripekelman/projects/my_first_git_project.git (fetch)
origin	/Users/oripekelman/projects/my_first_git_project.git (push)
```

Deux lignes, parce qu'un dépôt distant peut avoir une URL différente pour la lecture et pour l'écriture. Les nôtres sont identiques, ce qui est le cas normal.

Et puis l'intéressante, celle qui *parle* réellement au dépôt distant pour savoir ce qu'il contient (cette sortie vient d'un peu plus loin dans le chapitre, une fois que nous aurons poussé quelque chose — pour l'instant le dépôt distant n'existe même pas) :

```console
git remote show origin
```
```console
* remote origin
  Fetch URL: /Users/oripekelman/projects/my_first_git_project.git
  Push  URL: /Users/oripekelman/projects/my_first_git_project.git
  HEAD branch: master
  Remote branches:
    master        tracked
    shopping_cart tracked
  Local branch configured for 'git pull':
    master merges with remote master
  Local refs configured for 'git push':
    master        pushes to master        (up to date)
    shopping_cart pushes to shopping_cart (up to date)
```

Si vous voulez la vérité brute, sans fioritures, de ce que contient un dépôt distant, il existe une commande de plus bas niveau, et c'est un merveilleux outil de débogage :

```console
git ls-remote origin
```
```console
69dd359f129c6211173f3ac934c17b461d27d187	HEAD
69dd359f129c6211173f3ac934c17b461d27d187	refs/heads/master
1213fc5f325573870748535e5d457573a9c80b50	refs/heads/shopping_cart
75fff39cacc4f49bc16fe5d3d798cdeb393ed8a5	refs/tags/v1.0
a47856e41c9e5f275068920884c735276b97f1f6	refs/tags/v1.0^{}
```

Des références et les **SHA**s vers lesquels elles pointent. Rien d'autre. C'est ce que le serveur nous dirait si nous le lui demandions poliment. Quand quelqu'un dit « mais si, c'est poussé, je te jure », c'est la commande qui tranche le débat.

### Gérer les dépôts distants

Le reste de la famille `git remote` ne fait qu'éditer ce bloc de configuration pour vous.

```console
git remote rename upstream mirror
git remote set-url mirror git@github.com:you/my_first_git_project.git
git remote remove mirror
```

`rename` n'est pas purement cosmétique : il renomme aussi toutes les références de suivi distant, déplaçant `refs/remotes/upstream/*` vers `refs/remotes/mirror/*`, et il réécrit le refspec en conséquence. `set-url` ne change que l'URL — utile quand un projet change d'hébergeur, ou quand vous décidez de passer de HTTPS à SSH. `remove` supprime la section de configuration *et* toutes les références de suivi distant qui lui appartenaient.

Vous pourriez faire les trois en éditant `.git/config` dans votre éditeur de texte, et rien de fâcheux n'arriverait. Parfois c'est véritablement le plus rapide. Mais `git remote` nettoie les références pour vous, alors préférez-le.

### `origin` est une convention, pas un mot-clé

Je veux être très clair là-dessus, parce que cela déroute les gens pendant des années : **il n'y a rien de spécial dans le nom `origin`.**

Il n'est pas réservé. Il n'est pas privilégié. Git ne le traite pas différemment d'un dépôt distant appelé `bob`. C'est simplement le nom que `git clone` utilise par défaut, et donc le nom que tout le monde a. Vous pourriez le renommer `maison` cet après-midi et tout continuerait à fonctionner, tant que vous taperiez `maison` là où vous tapiez `origin`.

Et vous n'êtes pas limité à un seul. Avoir plusieurs dépôts distants est tout à fait normal, et le cas classique est la contribution au projet de quelqu'un d'autre :

* `origin` — *votre* copie du projet, celle sur laquelle vous pouvez écrire.
* `upstream` — le projet original, que vous pouvez lire mais pas écrire.

Construisons-le pour de vrai, parce que cela prend dix secondes avec des répertoires. Faisons comme si `theproject.git` appartenait à quelqu'un de célèbre, que `my-fork.git` était notre copie, et que `work` était l'endroit où nous tapons :

```console
cd ~/projects/work
git remote add upstream ~/projects/theproject.git
git fetch upstream
```
```console
From /Users/oripekelman/projects/theproject
 * [new branch]      master     -> upstream/master
```

Et maintenant, regardez ce qui s'est passé sous le capot :

```console
tree .git/refs
```
```console
.git/refs
├── heads
│   └── master
├── remotes
│   ├── origin
│   │   └── HEAD
│   └── upstream
│       ├── HEAD
│       └── master
└── tags
```

Deux espaces de noms, côte à côte, un répertoire chacun — parce que chaque dépôt distant a apporté son propre refspec, et que `git remote add upstream` a écrit `fetch = +refs/heads/*:refs/remotes/upstream/*` dans la configuration. Même motif, destination différente.

Maintenant, `git diff master upstream/master` est une phrase que vous pouvez prononcer. C'est là toute l'astuce de la contribution à l'open source, et nous n'avons pas quitté le disque local.

## Comment Git parle à un dépôt distant : les transports

L'URL dit à Git non seulement *où*, mais aussi *comment*. Il y a quatre familles et vous en rencontrerez trois.

**Un chemin de système de fichiers.** `/Users/oripekelman/projects/my_first_git_project.git`, ou `~/projects/whatever.git`, ou `../other-repo`. Git se contente de lire et d'écrire des fichiers. Cela fonctionne aussi sur un lecteur réseau monté. C'est aussi, et c'est le point sur lequel j'insiste, la manière idéale d'*apprendre*, parce qu'il n'y a aucune authentification à rater et que vous pouvez regarder des deux côtés.

Il existe une variante, `file:///Users/oripekelman/projects/my_first_git_project.git`, qui ressemble à la même chose mais ne l'est pas : avec un chemin nu, Git prend des raccourcis (il ira jusqu'à faire des liens durs sur les fichiers d'objets au lieu de les copier), tandis qu'avec `file://` il fait comme s'il s'agissait d'un vrai transport réseau et parle le protocole complet. Nous aurons besoin de cette distinction au chapitre suivant.

**SSH.** La forme complète est `ssh://git@example.com/~you/project.git`, mais presque personne ne l'écrit. Ce que tout le monde écrit, c'est le raccourci à la manière de scp :

```console
git@github.com:you/project.git
```

Notez le **deux-points** entre l'hôte et le chemin — c'est ce qui dit à Git qu'il s'agit de SSH et non d'un chemin de système de fichiers au nom bizarre. L'authentification se fait par paire de clés, et une fois que ça marche, vous n'y pensez plus jamais. La mise en place est un chapitre à part entière : [Configurer Git avec une clé SSH](../6-appendices/2-git-ssh.md "Configurer Git avec une clé SSH").

**HTTPS.** `https://github.com/you/project.git`. Sa grande vertu est qu'il passe absolument tous les pare-feux et proxys d'entreprise de la terre, parce qu'il ressemble à du trafic web, ce qu'il est. Son coût, ce sont les identifiants : un nom d'utilisateur et un **token**.

> :warning:
> Pas un mot de passe. Un token. GitHub a cessé d'accepter les mots de passe de compte pour les opérations Git en août 2021, et les autres grands hébergeurs ont suivi. Si vous tapez votre mot de passe de connexion dans une invite Git HTTPS en 2026, cela échouera, et le message d'erreur ne rendra pas nécessairement la raison évidente. Nous regarderons les messages exacts au [chapitre suivant](3-git-clone-pull-remote.md "Récupérer et envoyer du code").

**Et `git://`.** L'ancien protocole natif de Git, port 9418. Il est rapide, il est anonyme, il n'a ni chiffrement ni authentification d'aucune sorte, ce qui signifie que n'importe qui entre vous et le serveur peut discrètement modifier le code que vous téléchargez. GitHub l'a définitivement coupé le 15 mars 2022 et vous devriez considérer toute URL `git://` que vous trouvez dans un vieux README comme un bug. Mentionné ici uniquement pour que vous le reconnaissiez.

**HTTPS ou SSH, alors ?** Honnêtement : SSH si vous le pouvez, HTTPS si le réseau ne vous le permet pas. SSH est plus agréable une fois configuré et n'expire jamais. HTTPS a besoin d'un token et d'un **credential helper** pour que vous ne le colliez pas quarante fois par jour. Les deux sont sûrs. Aucun des deux choix n'est définitif — souvenez-vous de `git remote set-url`.

## Un dépôt sans répertoire de travail : le dépôt **bare**

Nous avons déclaré un dépôt distant pointant vers `~/projects/my_first_git_project.git`, et ce répertoire n'existe pas encore. Créons-le, et pendant que nous y sommes, posons une question évidente que presque personne ne pose : *que stocke réellement un serveur Git ?*

```console
cd ~/projects
git init --bare my_first_git_project.git
```
```console
Initialized empty Git repository in /Users/oripekelman/projects/my_first_git_project.git/
```

Notez le mot **bare**, et notez qu'il n'y a pas de « empty Git repository in .../.git/ » — pas de `.git` du tout. Faisons ce que nous faisons toujours :

```console
tree my_first_git_project.git
```
```console
my_first_git_project.git
├── HEAD
├── config
├── description
├── hooks
│   ├── applypatch-msg.sample
│   {..}
│   └── update.sample
├── info
│   └── exclude
├── objects
│   ├── info
│   └── pack
└── refs
    ├── heads
    └── tags
```

Regardez cette liste et reconnaissez-la. `HEAD`. `config`. `objects`. `refs/heads`. `refs/tags`. C'est *exactement* le contenu du répertoire `.git` que nous disséquons depuis la partie 1 — sauf qu'il n'est pas caché à l'intérieur d'un projet : il *est* le projet. Il n'y a pas de `readme.md`, pas de `media/`, aucune copie de travail de quoi que ce soit.

Voilà ce que « bare » veut dire. Un dépôt avec la base de données mais sans **worktree**. Et c'est ce que détient chaque serveur Git de la planète : un gros tas de **blob**s, de **tree**s et de **commit**s, plus quelques références qui pointent dedans.

Le fichier de configuration le dit à voix haute :

```console
cat my_first_git_project.git/config
```
```console
[core]
	repositoryformatversion = 0
	filemode = true
	bare = true
	ignorecase = true
	precomposeunicode = true
```

`bare = true`. Un booléen. Et :

```console
cat my_first_git_project.git/HEAD
```
```console
ref: refs/heads/master
```

Même un dépôt bare a un **HEAD**. Non pas pour lui dire « où tu es » — personne n'est nulle part, il n'y a pas d'arbre de travail — mais pour dire aux *clones* quelle branche extraire. C'est précisément le réglage que les services d'hébergement exposent sous le nom de « branche par défaut ».

> :information_source:
> Le suffixe `.git` sur le nom de répertoire d'un dépôt bare est une convention, pas une règle. Il existe pour qu'un humain faisant un `ls` sur un serveur puisse distinguer les dépôts des répertoires ordinaires. Suivez-la ; tout le monde le fait.

### Pourquoi ne puis-je pas simplement pousser vers un dépôt normal ?

Question raisonnable. Notre projet *est* un dépôt. Pourquoi un collègue ne peut-il pas pousser directement dedans ?

Essayons. Deux petits dépôts, `workrepo` (un normal, avec un arbre de travail, positionné sur `master`) et `copy` (un clone de celui-ci). Nous faisons un commit dans `copy` et nous poussons :

```console
git push origin master
```
```console
remote: error: refusing to update checked out branch: refs/heads/master
remote: error: By default, updating the current branch in a non-bare repository
remote: is denied, because it will make the index and work tree inconsistent
remote: with what you pushed, and will require 'git reset --hard' to match
remote: the work tree to HEAD.
remote:
remote: You can set the 'receive.denyCurrentBranch' configuration variable
remote: to 'ignore' or 'warn' in the remote repository to allow pushing into
remote: its current branch; however, this is not recommended unless you
remote: arranged to update its work tree to match what you pushed in some
remote: other way.
{..}
To /Users/oripekelman/projects/workrepo
 ! [remote rejected] master -> master (branch is currently checked out)
error: failed to push some refs to '/Users/oripekelman/projects/workrepo'
```

Git nous a écrit une dissertation, et elle est bonne. Le préfixe `remote:` signifie que ces lignes ont été imprimées par Git *de l'autre côté* et relayées jusqu'à nous — notre premier aperçu du fait qu'un push est une conversation entre deux Git.

Le raisonnement : si le push réussissait, `refs/heads/master` là-bas pointerait vers un nouveau **commit**, mais l'**index** et l'arbre de travail contiendraient toujours les anciens fichiers. Quelqu'un qui taperait `git status` dans ce répertoire s'entendrait dire qu'il a supprimé la moitié du projet. Git refuse de mettre un dépôt dans cet état dans le dos de son propriétaire.

C'est la vraie raison d'être des dépôts bare. Personne n'y travaille, donc il n'y a rien à rendre incohérent.

Envoyons enfin notre travail là-bas. Nous reviendrons correctement sur `push` au [chapitre suivant](3-git-clone-pull-remote.md "Récupérer et envoyer du code") ; pour le moment, il nous faut simplement quelque chose de l'autre côté à regarder.

```console
git push -u origin master
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 * [new branch]      master -> master
branch 'master' set up to track 'origin/master'.
```

## Comprendre les branches locales et les branches distantes

Nous arrivons à la plus grande source de confusion de Git, et nous allons y aller doucement, parce que bien comprendre maintenant fait gagner des années.

Il y a **trois choses différentes** qu'un débutant entend comme une seule :

1. `master` — une branche locale. Un fichier, `.git/refs/heads/master`, contenant un **SHA**. Le vôtre. Vous le déplacez en committant.
2. `origin/master` — une *référence de suivi distant*. Également un fichier local, `.git/refs/remotes/origin/master`, contenant également un SHA. C'est le **pense-bête de Git sur ce que le serveur a dit la dernière fois qu'on s'est parlé**. Vous ne le déplacez pas à la main ; `fetch` et `push` le déplacent pour vous.
3. La branche appelée `master` *sur le serveur*. Qui est là-bas, dans le dépôt bare, et que vous ne pouvez pas voir d'ici du tout sans aller le demander.

Le numéro 2 n'est pas le numéro 3. Le numéro 2 est un *cache* du numéro 3, et un cache peut être périmé. Tout le reste découle de là.

Regardons les trois. Après notre push :

```console
tree .git/refs
```
```console
.git/refs
├── heads
│   ├── homepage
│   ├── master
│   ├── shopping_cart
│   └── shopping_cart_template
├── remotes
│   └── origin
│       └── master
└── tags
```

Quatre branches locales. Une référence de suivi distant, parce que nous n'avons poussé qu'une seule branche. Et :

```console
cat .git/refs/heads/master
cat .git/refs/remotes/origin/master
```
```console
973f21b9767b572145add7f9e4444a14529fc1fe
973f21b9767b572145add7f9e4444a14529fc1fe
```

Deux fichiers, même contenu. Ce qui est exactement ce à quoi nous nous attendons une seconde après un push réussi : notre branche et notre idée de leur branche sont d'accord.

> :information_source:
> Les vôtres afficheront des SHA différents — ils dépendent de votre contenu, de votre nom et de la seconde exacte à laquelle vous avez committé. Ce qui compte, c'est de savoir si les deux fichiers correspondent l'un à l'autre.

### Où sont passées mes références ? `packed-refs`

Parfois, vous allez chercher `.git/refs/remotes/origin/master` et il n'est pas là. Dans un *clone tout frais* de notre projet, `tree .git/refs` montre `refs/heads/master` et `refs/remotes/origin/HEAD` — et rien d'autre. Où est `origin/master` ? `git branch -a` jure qu'il existe. C'est vrai :

```console
cat .git/packed-refs
```
```console
# pack-refs with: peeled fully-peeled sorted
973f21b9767b572145add7f9e4444a14529fc1fe refs/remotes/origin/master
1213fc5f325573870748535e5d457573a9c80b50 refs/remotes/origin/shopping_cart
```

Des milliers de minuscules fichiers d'une ligne sont une manière coûteuse de stocker des références, alors de temps en temps (et toujours à la fin d'un clone), Git les écrase en un seul fichier texte, `.git/packed-refs`. Exactement la même idée que les fichiers **pack** qui compressent les objets. Une référence peut vivre à l'un ou l'autre endroit ; un fichier isolé l'emporte sur l'entrée empaquetée. `git pack-refs` le fait à la demande, et `git gc` le fait en faisant le ménage.

Donc : pour voir une référence, préférez demander à Git plutôt qu'au système de fichiers. `git rev-parse origin/master` vous donne le SHA où qu'il soit stocké. `git show-ref` liste le tout.

### Voir les branches, locales et distantes

```console
git branch -a
```
```console
  homepage
* master
  shopping_cart
  shopping_cart_template
  remotes/origin/master
  remotes/origin/shopping_cart
```

`-a`, c'est « all » : les branches locales *et* les références de suivi distant. Celles qui ont `remotes/` devant sont le groupe 2 de notre liste ci-dessus. Vous ne pouvez pas les extraire et committer dessus — enfin, vous pouvez les extraire, mais vous atterrissez dans l'état de **detached head** que nous avons rencontré en partie 1, parce que ce ne sont pas des branches, ce sont des marque-pages.

Mieux encore, `-vv`, qui est `-v` deux fois et montre la relation de suivi :

```console
git branch -vv
```
```console
  homepage               973f21b Add readme.md and the media directory
* master                 973f21b [origin/master] Add readme.md and the media directory
  shopping_cart          1213fc5 Implement shopping cart template
  shopping_cart_template 1213fc5 Implement shopping cart template
```

Seul `master` a `[origin/master]` à côté de lui. Ce crochet, c'est la relation **upstream**, et c'est le troisième bloc apparu dans notre configuration quand nous avons poussé avec `-u` :

```console
[branch "master"]
	remote = origin
	merge = refs/heads/master
```

« Pour la branche locale `master` : le dépôt distant est `origin`, et la branche à intégrer est `refs/heads/master` ». C'est ce qui vous permet de taper un simple `git pull` et `git push` et que Git sache ce que vous vouliez dire.

Vous pouvez l'établir après coup, sans pousser :

```console
git checkout shopping_cart
git branch --set-upstream-to=origin/shopping_cart
```
```console
branch 'shopping_cart' set up to track 'origin/shopping_cart'.
```

Ou de la manière dont tout le monde le fait réellement, la première fois qu'on pousse une branche : `git push -u origin my_branch`. Le `-u` est l'abréviation de `--set-upstream`.

### « Your branch is ahead of 'origin/master' by 2 commits »

Nous pouvons maintenant lire la phrase la plus lue de Git. Méritons-la. Nous faisons deux commits et nous demandons :

```console
git status
```
```console
On branch master
Your branch is ahead of 'origin/master' by 2 commits.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
```

Ce que Git a fait pour produire cette ligne : il a pris le SHA dans `.git/refs/heads/master`, pris le SHA dans `.git/refs/remotes/origin/master`, parcouru les liens de parenté de chacun, et compté. Deux commits atteignables depuis le nôtre qui ne sont pas atteignables depuis le leur ; zéro dans l'autre sens. C'est tout ce que « ahead by 2 » veut dire. Vous pouvez voir les commits en question :

```console
git log --oneline origin/master..HEAD
```
```console
2eaa6ce Add a TODO list
9056566 Add a license file
```

> :information_source:
> La syntaxe `A..B` signifie « les commits atteignables depuis B mais pas depuis A ». C'est la notation Git la plus utile que personne n'enseigne aux débutants. `origin/master..HEAD`, c'est « ce que j'ai et qu'ils n'ont pas » — ce qu'un push enverrait. `HEAD..origin/master`, c'est « ce qu'ils ont et que je n'ai pas » — ce qu'un pull rapporterait.

Et maintenant, la partie qui compte. **Ce décompte a été calculé entièrement sur votre machine, à partir de deux fichiers locaux, sans toucher au réseau.** Ce qui veut dire qu'il peut être un mensonge.

Regardez. Quelqu'un d'autre pousse un commit vers le serveur. Nous n'en savons rien. Nous demandons à Git comment nous allons :

```console
git status
```
```console
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
```

Faux avec assurance. Nous ne sommes pas à jour avec le serveur ; nous sommes à jour avec notre *souvenir* du serveur. Maintenant, demandons au serveur :

```console
git fetch
```
```console
From /Users/oripekelman/projects/my_first_git_project
   973f21b..d0dcf58  master     -> origin/master
```

Le voilà : notre référence de suivi distant est passée de `973f21b` à `d0dcf58`. Rien d'autre n'a changé — ni notre branche, ni nos fichiers. Et maintenant :

```console
git status
```
```console
On branch master
Your branch is behind 'origin/master' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
```

Même commande, même dépôt, même arbre de travail, réponse opposée. La seule chose qui a changé, c'est que nous sommes allés demander.

> :warning:
> Chaque fois que `git status` vous dit quelque chose à propos de `origin/quelque-chose` et que vous n'avez pas fait de fetch récemment, traitez-le comme une rumeur. `git status` ne va jamais sur le réseau — par conception, pour rester instantané. C'est `git fetch` qui le rend vrai.

### Les branches qui n'existent plus

Le cache se périme aussi dans l'autre sens. Quelqu'un supprime une branche sur le serveur ; notre `refs/remotes/origin/` a toujours une entrée pour elle. `git remote show origin` le signalera :

```console
  Remote branches:
    master                                     tracked
    refs/remotes/origin/shopping_cart_template stale (use 'git remote prune' to remove)
    shopping_cart                              tracked
```

Et la solution, que vous pouvez aussi écrire `git remote prune origin` :

```console
git fetch --prune
```
```console
From /Users/oripekelman/projects/my_first_git_project
 - [deleted]         (none)     -> origin/shopping_cart_template
```

`(none)` à gauche de la flèche : il n'y a plus rien de tel sur le dépôt distant, donc la copie locale s'en va. Si vous voulez, `git config --global fetch.prune true` fait que chaque fetch range derrière lui, et je le recommanderais.

Vous verrez aussi `[origin/homepage: gone]` dans la sortie de `git branch -vv` : une branche locale dont l'upstream a été supprimé, généralement parce que sa pull request a été fusionnée et que l'hébergeur a fait le ménage. C'est le signal que la branche locale est terminée elle aussi.

## Comprendre la nature décentralisée. Les forks.

Maintenant la culture, qui est le véritable « aha » de ce chapitre.

Nous avons un dépôt bare dans `~/projects/my_first_git_project.git` et une copie de travail qui pousse dedans. Lequel est *le* dépôt ?

Aucun. Les deux sont complets. Chacun a tous les objets, tous les commits, tout l'historique jusqu'au premier. Si le bare brûle, n'importe quel clone peut le recréer en une commande. Si tous les clones brûlent, le bare va toujours bien. Il n'y a pas de copie maîtresse, pas d'autorité centrale, pas de nœud spécial. C'est cela que « distribué » veut dire, et ce n'est pas un mot de marketing — c'est une propriété de la structure de données. Des objets adressés par contenu et des pointeurs de parenté sont les mêmes partout, ou bien ce ne sont pas les mêmes objets.

Alors pourquoi tout le monde traite-t-il `origin` comme sacré ? **Une convention sociale.** Une équipe se met d'accord : « cette URL est l'endroit où vit la vérité, nous poussons tous là, la CI la surveille, les déploiements en partent ». Git n'impose rien de tout cela. C'est une habitude partagée, adossée à des permissions sur un serveur. Une habitude très utile ! Mais ne la prenez pas pour un fait technique, parce que le jour où vous en aurez besoin (le portable d'un collègue, une machine coupée du réseau, une panne de l'hébergeur), vous pourrez pousser vers et tirer depuis n'importe où.

### Les forks

Un **fork**, au sens GitHub/GitLab, est un clone. Ce n'est que cela : un `git clone` lancé sur un serveur qui ne vous appartient pas, de sorte que la copie se retrouve à côté de l'original avec votre nom dessus et une page web attachée.

L'interface web ajoute deux choses véritablement précieuses : elle *se souvient* que votre copie vient de l'original, et elle vous donne un bouton pour proposer vos changements en retour. C'est une pull request, et elle vit dans [le chapitre d'après le suivant](5-git-workflow.md "Mettre en œuvre un workflow collaboratif efficace").

Mais sa forme est celle que nous avons construite à la main quelques pages plus haut : `origin` est votre fork, `upstream` est l'endroit d'où vous l'avez obtenu, et vous restez à jour en récupérant depuis `upstream` et en poussant vers `origin`. Si vous comprenez cela, vous comprenez les forks, et vous ne serez plus jamais mystifié par « this branch is 47 commits behind upstream:main ».

### Le contre-exemple : le noyau Linux

Il vaut la peine de savoir que le dépôt Git le plus célèbre du monde ne fonctionne pas du tout comme GitHub — et que Git a été écrit pour lui.

Les contributions au noyau voyagent par **e-mail**. Vous faites vos commits, vous les transformez en fichiers de patch, vous les envoyez à une liste de diffusion, des humains les relisent en répondant dans le texte, et un mainteneur les applique. Pas de forks, pas de boutons, pas de comptes. Des milliers de contributeurs, et cela tourne comme ça depuis vingt ans.

Git livre les outils pour cela, et ce sont des commandes ordinaires :

```console
git format-patch master
```
```console
0001-Fix-a-typo-in-the-readme.patch
```

Un fichier par commit, et le fichier est un véritable e-mail :

```console
From 908187bd9d032029abff70dff03f5382f2d57253 Mon Sep 17 00:00:00 2001
From: Ori Pekelman <ori@pekelman.com>
Date: Sat, 7 Feb 2026 14:00:00 +0100
Subject: [PATCH] Fix a typo in the readme

---
 readme.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/readme.md b/readme.md
index 94190ef..b1169eb 100644
--- a/readme.md
+++ b/readme.md
@@ -1,3 +1,3 @@
 # My first Git project
 
-A project about learning Git.
+A project for learning Git.
-- 
2.51.0
```

Des en-têtes, un sujet, un diff, et une signature donnant la version de Git. `git send-email` l'envoie ; de l'autre côté, `git am` (« apply mailbox ») le retransforme en commit, avec l'auteur et la date d'origine préservés.

Et si vous préférez que le mainteneur *tire* depuis chez vous plutôt qu'il n'applique un patch, `git request-pull <début> <url> <branche>` rédige la demande pour vous — un paragraphe nommant l'endroit où votre travail commence, l'URL et la branche à récupérer, un résumé des commits et un diffstat :

```console
git request-pull master ~/projects/my_first_git_project.git typo-fix
```
```console
The following changes since commit 69dd359f129c6211173f3ac934c17b461d27d187:

  Note the next steps (2026-02-05 11:30:00 +0100)

are available in the Git repository at:

  /Users/oripekelman/projects/my_first_git_project.git typo-fix
{..}
```

C'est cela, une pull request. L'originale. La version web, c'est ce texte avec une plus jolie typographie et un fil de commentaires.

Je ne suggère pas que vous fassiez passer votre équipe à l'e-mail. Je suggère que le monde en forme de GitHub est *un* workflow posé par-dessus Git, et non Git lui-même — et que le savoir est ce qui vous permet de distinguer lesquels de vos problèmes sont des problèmes Git et lesquels sont ceux de votre hébergeur.

## Où et comment héberger son code git ?

Ce qui nous amène, enfin et avec la bonne dose de scepticisme, à l'hébergement.

D'abord, le cadrage honnête. Héberger un dépôt Git ne vous apporte presque rien *du point de vue de Git*. Git est déjà fait. Ce que vous payez (en argent ou en attention), c'est : une interface web pour lire du code, un outil de revue de code, un gestionnaire de tickets, des exécuteurs de CI, et du contrôle d'accès. Ces choses sont réelles et précieuses. Elles ne sont pas Git non plus, et chaque hébergeur les fait différemment, ce qui explique pourquoi tant de « savoir Git » se révèle être du savoir GitHub.

Les principales options, en 2026 :

* **GitHub** — le choix par défaut, et l'effet de réseau *est* la fonctionnalité : si vous voulez des contributeurs, c'est là qu'ils ont déjà un compte. Excellente CI (Actions), écosystème énorme, propriété de Microsoft.
* **GitLab** — le même métier, plus la possibilité de faire tourner l'ensemble sur votre propre matériel, ce qui compte énormément pour certaines organisations. CI intégrée, et il était là le premier.
* **Codeberg / Forgejo**, et **Gitea** dont Forgejo est issu — petits, rapides, agréables, et peu coûteux à auto-héberger (Forgejo est un binaire unique et tourne sur la plus petite VM que vous puissiez louer). Codeberg est une association à but non lucratif qui fait tourner Forgejo pour la communauté. Si GitHub vous semble être trop de machinerie pour un projet à cinq personnes, regardez par ici.
* **sourcehut** (`sr.ht`) — délibérément minimal, sans JavaScript, *natif pour les listes de diffusion* : construit autour du workflow `format-patch` que nous venons de regarder.
* **Bitbucket** — toujours bien présent, surtout aux côtés du reste des outils d'Atlassian.

Et l'option qu'on oublie : **votre propre machine**. Vous avez déjà vu toute l'astuce. Sur une machine où vous pouvez faire `ssh` :

```console
ssh you@example.com
mkdir -p ~/repos/project.git
git init --bare ~/repos/project.git
exit
```

Puis depuis votre portable :

```console
git remote add origin you@example.com:repos/project.git
git push -u origin master
```

Voilà un serveur Git qui fonctionne. Aucun logiciel installé, aucun port ouvert, aucune configuration. SSH fait l'authentification, le système de fichiers fait le stockage, et vous obtenez toutes les fonctionnalités de Git qui existent, parce que Git est tout ce qu'il y a. Ce que vous n'obtenez pas, c'est une page web, un outil de revue ou de la CI.

Si vous devez donner l'accès à plusieurs personnes sans distribuer des comptes shell, `gitolite` est un petit outil ennuyeux et bien éprouvé qui gère exactement cela — un fichier de configuration listant qui peut lire et écrire quels dépôts. Si vous voulez aussi la page web et les tickets, installez Forgejo.

Nous sommes brefs ici volontairement ; il y a un chapitre entier là-dessus : [Héberger Git, et l'héberger soi-même](../3-tooling-ecosystem/2-git-hosting.md "Héberger Git, et l'héberger soi-même").

> :information_source:
> Quel que soit votre choix, gardez en tête la distinction que nous avons tracée plus haut. Votre dépôt n'est pas « sur GitHub ». Votre dépôt est sur votre disque, et il y a *aussi* une copie sur GitHub. Ce n'est pas du pinaillage — c'est la différence entre « le site est en panne, on ne peut pas travailler » et « le site est en panne, on poussera plus tard ».

## Récapitulatif : `git remote`, les refspecs et les branches de suivi distant

* Un **remote** est un nom pour une URL plus un **refspec**, stockés dans `.git/config`. Pas d'état, pas de connexion, rien d'autre.
* Un refspec comme `+refs/heads/*:refs/remotes/origin/*` fait correspondre les références du dépôt distant (à gauche du deux-points) aux références d'ici (à droite) ; `+` veut dire « écrase même si ce n'est pas un fast-forward ».
* `git remote add <nom> <url>` en déclare un. `git remote`, `-v`, et `git remote show <nom>` les listent avec un détail croissant — la dernière interroge réellement le serveur.
* `git remote rename` / `set-url` / `remove` éditent ce bloc de configuration *et* remettent d'aplomb les références de suivi distant.
* `git ls-remote <remote>` montre les références brutes que détient un dépôt distant. L'arbitre de tous les débats « mais je te jure que je l'ai poussé ».
* `origin` est une convention, pas un mot-clé. Plusieurs dépôts distants, c'est normal : `origin` pour votre fork, `upstream` pour l'original.
* Transports : un chemin de système de fichiers (le meilleur pour expérimenter), `file://` (même endroit, vrai protocole), SSH `git@host:chemin` ([Configurer Git avec une clé SSH](../6-appendices/2-git-ssh.md "Configurer Git avec une clé SSH")), HTTPS (ami des pare-feux, nécessite un token), et `git://` qui est non sécurisé et mort.
* `git init --bare` — le contenu de `.git` promu au rang de répertoire entier, sans **worktree**. C'est ce que détient un serveur, et c'est pourquoi Git refuse de pousser dans la branche extraite d'un dépôt non bare.
* Trois choses différentes : la branche locale `master` ; la référence de suivi distant `origin/master`, un *cache local* vivant dans `.git/refs/remotes/` ou `.git/packed-refs` ; et la véritable branche sur le serveur.
* `git branch -a` liste les branches locales et les références de suivi distant ; `git branch -vv` ajoute la relation **upstream**. Établissez-la avec `git push -u origin foo` ou `git branch --set-upstream-to=origin/foo`.
* « ahead of 'origin/master' by 2 commits » est compté localement à partir de deux fichiers de références, et n'est frais que dans la mesure de votre dernier `git fetch`. `git log --oneline origin/master..HEAD` montre lesquels.
* `git fetch --prune` (ou `fetch.prune = true`) supprime les références de suivi distant des branches qui n'existent plus.
* Chaque clone est un dépôt complet ; `origin` n'est privilégié que par accord social. Un fork est un clone avec une page web. `git format-patch`, `git send-email`, `git am` et `git request-pull` sont le workflow originel par liste de diffusion, toujours fonctionnel, qui construit toujours le noyau.
* L'hébergement vous achète une interface web, de la revue de code, de la CI et un gestionnaire de tickets — pas Git. Un dépôt bare plus `ssh`, c'est un serveur Git. Plus de détails dans [Héberger Git, et l'héberger soi-même](../3-tooling-ecosystem/2-git-hosting.md "Héberger Git, et l'héberger soi-même").
