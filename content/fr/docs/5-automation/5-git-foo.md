---
title: Briller en société et épater les amis avec le Gitfoo
slug: "git-foo"
weight: 45
---
# Briller en société et épater les amis avec le Gitfoo

Voici notre fourre-tout. Ce qui suit, ce sont une quarantaine de petites astuces, chacune une
question que vous finirez par poser à voix haute suivie de la commande qui y répond — à l'origine
une série « Git Daily » en français, une astuce par jour, ce qui explique qu'elle soit délibérément
plus sèche que le reste de ce cours. Pas de théorie ici, pas de coup d'œil sous le capot : piochez
dedans, volez quelque chose, revenez un autre jour.

Elles ne sont dans aucun ordre particulier, donc ne les lisez pas d'une traite. Chacune se termine
par la page `git help` à lire si vous voulez toute l'histoire, ce qui est l'habitude à voler
au-dessus de toutes les autres. Et il n'y a pas de récapitulatif à la fin de ce chapitre, parce que
le chapitre *est* un récapitulatif.

Les dernières astuces sont de nous : la série d'origine est antérieure à des commandes que nous ne
voudrions pas vous faire manquer.

## Ne commiter qu'une partie de mes modifications

J'ai fait plusieurs modifications dans un fichier et je ne veux en commiter que certaines :

    git add -p

Pour chaque fichier modifié de votre arbre de travail, Git vous propose chaque section à son tour,
et vous répondez si elle part dans la zone d'index.

Plus d'informations ?

    git help add

## Savoir qui a commité sur un projet

    git shortlog -n -s

Renverra la liste des auteurs triés par leur nombre de commits.

    git help shortlog

## Supprimer les branches distantes qui n'existent plus

    git fetch -p origin

Récupérera les objets depuis origin et supprimera les branches distantes qui n'existent plus. Vous
aurez un `git branch -a` correct.

    git help fetch

## Tout jeter et revenir à un commit

    git reset --hard SHA1

Vous mettra dans l'état du commit passé en paramètre. Tout ce que vous aviez modifié est perdu pour
de bon — et tout ce que vous aviez *commité* reste retrouvable dans le `reflog` pendant quelques
semaines, donc vous n'êtes pas tout à fait aussi condamné que vous le croyez (voir l'astuce sur le
reflog plus bas).

Si vous avez déjà poussé les commits en question, c'est une mauvaise pratique.

    git help reset

## Mettre la configuration de mon système sous Git

    git init /etc

Initialisera un dépôt git dans `/etc`. Même idée pour ce bout de code qui ne sera jamais réutilisé :
`git init && git add . && git commit`.

> :warning:
> Faites cela à `/etc` en connaissance de cause. Il faut être root, donc le dépôt appartiendra à
> root — et `/etc` contient `shadow`, des clés privées et d'autres choses qui ne doivent jamais
> quitter la machine. Écrivez un `.gitignore` *avant* le premier `git add`, et si jamais vous
> poussez ce dépôt quelque part, vous venez de publier vos secrets.

    git help init

## Savoir sur quelles branches se trouve un commit

    git branch --contains SHA1

Vous listerez les branches en question.

    git help branch

## Annuler mon dernier commit

    git reset --soft HEAD^

Votre dernier commit est annulé et ses modifications sont de retour dans votre zone d'index, prêtes
à être commitées à nouveau — ce qui est à peu près ce que `git commit --amend` fait pour vous en une
seule étape.

    git help reset

## Ajouter ma propre commande git

Je veux ajouter une commande `chuck` qui répond `norris` (ahah).

    $ cat > /usr/local/bin/git-chuck <<'EOF'
    #!/bin/sh
    echo 'norris'
    EOF
    $ chmod +x /usr/local/bin/git-chuck
    $ git chuck

Cela crée un exécutable `git-chuck` qui répond simplement `norris`. Git exécute n'importe quel
exécutable nommé `git-xxx` trouvé dans votre `PATH` quand vous tapez `git xxx`. C'est ainsi que
fonctionnent :

* git-pulls : https://github.com/schacon/git-pulls
* git-pair : https://github.com/chrisk/git-pair

et bien d'autres.

## Voir les commits qui sont dans une branche et pas dans une autre

    git log origin/master --not origin/develop

Vous listerez les commits qui sont dans la branche master mais pas dans develop.

    git help log

## Récupérer un commit qui est sur une autre branche

    git cherry-pick SHA1

Récupérera le commit SHA1 et l'appliquera sur la branche courante. Attention, le commit parent n'est
pas le même, donc le SHA changera.

    git help cherry-pick

## Vérifier que je n'ajoute pas d'espaces en fin de ligne

Je veux vérifier que mes modifications n'ajoutent pas d'espaces en fin de ligne, ni d'espace avant
une tabulation.

    git diff --check

Affiche chaque erreur détectée et renvoie un code de sortie non nul :

    a.txt:2: trailing whitespace.
    +world

Plus d'informations ?

    git help diff

## Faire une archive de mon dépôt

    git archive --format tar -o backup.tar HEAD

Créera une archive tar `backup.tar` de HEAD. Deux options bonnes à connaître :

    git archive --format=tar.gz --prefix=monprojet-1.0/ -o monprojet-1.0.tar.gz v1.0

`--format=tar.gz` compresse pour vous, et `--prefix` met tout dans un répertoire à l'intérieur de
l'archive, ce à quoi les gens s'attendent quand ils dépaquettent une version.

    git help archive

## Voir les messages de commit avec le diff

    git log -p

Vous montrera une vue de log classique mais avec le diff juste en dessous.

    git help log

## Visualiser les changements d'une manière lisible pour de la prose

    git diff --color-words

Affichera les différences mot à mot plutôt que ligne à ligne.

    git help diff

## Chercher quelque chose dans mon dépôt

    git grep "plop"

Renverra toutes les lignes qui contiennent « plop ».

    git help grep

## Chercher le changement qui a ajouté ou supprimé quelque chose

    git log -S "plop"

Renverra toutes les révisions où le nombre d'occurrences de « plop » a changé. À utiliser avec
l'option `-p` en général.

    git help log

## Préparer mes patchs pour les envoyer par courriel

    git format-patch SHA1

Écrira les patchs dans des fichiers, pour les envoyer par courriel par exemple, ou simplement pour
les partager.

    git help format-patch

## Cesser de suivre un fichier sans le supprimer

    git rm --cached chemin/vers/fichier

Marquera le fichier pour suppression au prochain commit mais ne le retirera pas du système de
fichiers. Pratique si vous avez fait une bêtise :).

    git help rm

## Trouver le commit qui a introduit une régression

    git bisect start

Démarrera une session de chasse au bogue. Bisect vous place sur des commits précis, et vous marquez
chacun bon ou mauvais jusqu'à ce qu'il trouve le coupable.

Et si le test peut être scripté, ne le faites pas à la main — Git fera toute la recherche pour vous :

    git bisect start HEAD HEAD~40
    git bisect run ./test.sh

Le code de sortie 0 veut dire bon, tout le reste veut dire mauvais, et 125 veut dire « impossible de
tester celui-ci, saute-le ». Terminez par `git bisect reset`.

    git help bisect

## Optimiser un dépôt un peu gros

    git gc

Supprimera les objets perdus et compressera les révisions. Si votre dépôt est un peu gros, Git lance
`gc` automatiquement.

Un Git moderne sait aussi s'occuper de lui-même en arrière-plan :

    git maintenance start

enregistre le dépôt auprès du planificateur de votre système et lance les tâches d'entretien peu
coûteuses toutes les heures, de sorte que vous n'y pensez plus jamais.

    git help gc
    git help maintenance

## Voir ce que je m'apprête à commiter

    git diff --cached

Renvoie uniquement les différences de votre zone d'index. Excellente combinaison avec l'astuce
précédente :

    git diff --cached --check

Renverra les erreurs d'espaces en fin de ligne pour votre zone d'index.

Plus d'informations ?

    git help diff

## Avoir des alias pour mes commandes habituelles

Dans `~/.gitconfig`, j'ajoute :

    [alias]
      st = status
      a = add
      ci = commit
      br = branch
      co = checkout
      cpk = cherry-pick
      d = diff

Ces alias sont immédiatement disponibles, sans avoir à recharger quoi que ce soit.

    git help config

## Avoir des couleurs partout

Dans `~/.gitconfig`, j'ajoute :

    [color]
      ui = auto
    [color "diff"]
      meta = yellow
      frag = cyan
      old = red
      new = green

Dans les diffs, les lignes supprimées seront en rouge et celles ajoutées en vert. (`ui = auto` est
le défaut depuis des années, donc vous n'avez besoin de cette section que si vous voulez changer les
couleurs elles-mêmes.)

## Écrire mes messages de commit dans mon éditeur préféré

Dans `~/.gitconfig`, j'ajoute :

    [core]
      editor = vim

Avec les messages de commit, n'hésitez pas à vous étendre sur plus d'une ligne si votre patch n'est
pas trivial, tout en gardant la première ligne sous les 50 caractères.

## Options utiles de la commande log

Quelques options de la commande `log`, pour enrichir vos alias :

    --date=relative
      pour des dates comme sur les réseaux sociaux (« il y a n heures »)
    --name-only
      pour afficher les noms des fichiers modifiés
    --no-merges
      est assez explicite
    --oneline
      n'affichera que le SHA-1 abrégé et le message de commit
    --patch
      ou -p pour afficher le patch du commit

## Formater les logs exactement comme je veux

    git log --pretty=format:'%Cred%h%Creset %s %Cgreen(%cr) %Cblue<%an>'

Avec :

    %C  pour changer la couleur
    %h  pour le SHA-1 abrégé
    %s  pour le sujet du commit
    %cr pour la date relative
    %an pour le nom de l'auteur

Plus d'informations sur le format pretty :

    git help log

## N'afficher que les commits d'une personne

    git log --author="John Smith"

Je peux aussi faire un alias pour n'afficher que mes propres commits, dans la section `[alias]` :

    mylog = !git log --author=`git config --get user.email`

Le point d'exclamation dit à Git d'exécuter la suite comme une commande shell plutôt que comme une
sous-commande `git`.

## Faire vérifier par Git les espaces en fin de ligne avant chaque commit

Je veux que Git vérifie que je n'ai pas laissé d'espaces en fin de ligne avant chaque commit, et
qu'il refuse le commit le cas échéant :

    mv .git/hooks/pre-commit.sample .git/hooks/pre-commit

Le hook d'exemple livré avec Git fait exactement cela, et refuse le commit :

    a:2: trailing whitespace.
    +bad

Plus d'informations sur les hooks :

    git help hooks

## Créer un dépôt à partir d'un sous-répertoire d'un autre

Par exemple pour créer un dépôt à partir du sous-répertoire `lib/captcha` :

    git filter-repo --subdirectory-filter lib/captcha

La réécriture ne garde que les fichiers et les commits qui ont touché `lib/captcha`, et
`lib/captcha` devient la racine du dépôt.

Vous pouvez aussi supprimer un fichier de tout votre historique :

    git filter-repo --invert-paths --path config/prod.yml

Réécrira chaque commit de sorte que `config/prod.yml` n'y ait jamais été.

> :warning:
> La version d'origine de cette astuce utilisait `git filter-branch`, et Git lui-même vous dit
> désormais de ne pas le faire : « These safety and performance issues cannot be backward
> compatibly fixed and as such, its use is not recommended. Please use an alternative history
> filtering tool such as git filter-repo. » `git filter-repo` est un programme séparé qu'on
> installe (`brew install git-filter-repo`, `apt install git-filter-repo`,
> `pip install git-filter-repo`), et il est plus rapide et bien plus difficile à mal employer.
> [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) est l'autre bonne option,
> surtout pour « supprimer tout blob de plus de dix mégaoctets ».

`filter-repo` exige un clone frais et vous le dira — *« this does not look like a fresh clone…
Please operate on a fresh clone instead »* — ce qui est le même conseil que donnait l'astuce
d'origine, à la main. Réécrire l'historique n'est pas annulable par la personne à qui vous envoyez
la réécriture.

    git filter-repo -h
    https://github.com/newren/git-filter-repo

## Réécrire mon historique pour écraser, jeter et renommer des commits

    git rebase -i SHA1

SHA1 étant le commit de départ, celui que vous ne voulez *pas* modifier. Tout ce qui est au-dessus
peut être réécrit. Git ouvre votre `$EDITOR` et vous demande ce que vous voulez faire de chaque
commit : le garder, le fondre dans le précédent, le jeter.

    pick 379ab2a Move all presence as pid.
    pick 42bab02 Update timeout module to use the new presence api.
    pick d1da4b4 No more indexes for uce_presence_mongodb.
    pick 94835c2 No more indexes for uce_presence_mnesia.
    pick 0a481e9 Optimize uce_paginate.
    pick 09b4224 Connected user as pid.

Sur l'exemple précédent, vous pouvez modifier le tampon ainsi :

    pick 379ab2a Move all presence as pid.
    squash 42bab02 Update timeout module to use the new presence api.
    squash d1da4b4 No more indexes for uce_presence_mongodb.
    squash 94835c2 No more indexes for uce_presence_mnesia.
    reword 09b4224 Connected user as pid.

Ce qui va se passer :

* 42bab02, d1da4b4 et 94835c2 seront fondus dans 379ab2a. Git proposera aussi de réécrire le
  message de commit.
* Vous pourrez réécrire le message de commit de 09b4224.
* Le commit 0a481e9 ayant été supprimé du tampon, il sera aussi supprimé de l'historique.

    git help rebase

## Connaître tous les commits depuis hier

    git log --since yesterday

Un petit bonus aujourd'hui :

    git log HEAD^

Listera les commits depuis l'avant-dernier commit.

    git log HEAD~4..

Listera les quatre derniers commits. Équivalent à :

    git log HEAD~4..HEAD

Plus d'informations :

    git help revisions

## Modifier mon dernier commit

J'ai mis un mauvais message de commit, ou j'ai oublié un fichier.

    git commit --amend

Modifie le message du dernier commit. Il peut aussi y ajouter ce qui se trouve dans votre zone
d'index :

    git add monfichier.erl && git commit --amend

Fondra la modification de `monfichier.erl` dans le commit précédent.

Cette commande réécrit l'historique : vous ne devriez PAS faire cela si vous avez déjà poussé.

## Résoudre le même conflit une bonne fois pour toutes

Vous avez des conflits récurrents lors des fusions et vous voulez les régler une bonne fois pour
toutes.

La première chose à faire est d'activer la variable `rerere.enabled` :

    git config --global rerere.enabled true

Ensuite ? Vous laissez Git faire. Il enregistre les conflits et leurs résolutions, et rejoue votre
résolution automatiquement la prochaine fois qu'il voit le même conflit.

Au prochain `git pull --rebase` ou `git merge`, pas besoin de réappliquer le même patch.

Si vous avez enregistré une mauvaise résolution, `git rerere forget <chemin>` la jette.

Et pourquoi ce nom ? C'est l'abréviation de *Reuse Recorded Resolution*.

    git help rerere

    https://git-scm.com/book/en/v2/Git-Tools-Rerere

## Greffer l'historique d'un dépôt sur un autre

    git replace SHA1 SHA2

`git replace` dit à Git « chaque fois que tu lirais l'objet SHA1, lis SHA2 à la place ». Rien n'est
réécrit : le remplacement vit dans `refs/replace/`, et `git --no-replace-objects log` vous remontre
la vérité non fardée.

L'usage classique est la jonction de deux historiques. Vous gardez un dépôt court et rapide, et vous
greffez l'historique ancien sur son commit racine uniquement pour ceux qui le veulent. C'est ce qui
a été fait pour le dépôt Erlang/OTP, qui dépasse les 300 Mo :
https://github.com/erlang/otp/wiki/Extending-the-history-of-Erlang-OTP.

Vous pouvez le tester en quelques commandes. Récupérez un autre dépôt dans le vôtre, puis remplacez
un de vos commits par un des leurs :

    $ git clone https://github.com/eventmachine/eventmachine.git
    $ cd eventmachine
    $ git remote add other https://github.com/nodejs/node.git
    $ git fetch other
    $ git replace d9a23e4779b3f555e63e4ff565ef0848a8bcabd4 61dfe5d2a9f613e3826997efa189ec8dd239aacf

Oui, c'est inutile. Mais regardez le `git log` : tout se comporte comme si les deux historiques
n'avaient jamais fait qu'un. `git replace -l` liste vos remplacements, et supprimer la référence
défait le tout.

    git help replace

    https://git-scm.com/book/en/v2/Git-Tools-Replace

## Découvrir ce que je viens bien de faire

Vous avez commité sur aucune branche du tout ? Vous avez lâché un `git reset --hard` que vous
regrettez ? Vous avez testé une réécriture d'historique sur un dépôt plein de patchs extrêmement
importants ?

    git reflog

Le reflog enregistre chaque changement apporté à vos branches et à HEAD. Vos commits, fusions et
pulls y sont tous. Un bon espion, et la chose qui vous sortira d'affaire.

Voici une sortie de reflog typique :

    d2bbd0e HEAD@{1}: commit: Run the bootstrap script when running bench.
    bd91916 HEAD@{2}: bd919164c72c38b88a85275ee5b9add7f7a8f382: updating HEAD
    2ce209e HEAD@{3}: pull origin master: Merge made by recursive.
    bd91916 HEAD@{4}: commit: Generate tsung scenario from a yml file.
    4cdc612 HEAD@{5}: checkout: moving from complex_metadata to develop
    44fb6fc HEAD@{6}: commit: Initial support of complex metadata in events.
    4cdc612 HEAD@{7}: checkout: moving from 4cdc61204e4ea5c6814c65c88e2ef19031c2cf6d to complex_metadata

Par exemple, pour récupérer un commit qui n'est sur aucune branche :

    git reflog          # trouver le bon commit, par ex. d2bbd0e
    git checkout master
    git cherry-pick d2bbd0e

Ou pour récupérer votre dépôt après une réécriture d'historique :

    git reflog
     129b276 HEAD@{0}: filter-repo: rewrite
     bbd8de8 HEAD@{1}: rebase -i (pick): Optimize uce_paginate.
    git reset --hard bbd8de8

Quelques sous-commandes sont disponibles, comme `expire` et `delete`.

    git help reflog

## Connaître les commits que je n'ai pas encore poussés

    git log origin/master..HEAD

Ne listera que les commits qui n'ont pas été poussés vers origin/master.

    git help log

## Récupérer le contenu d'un fichier à une révision précise

    git show SHA1:chemin/vers/fichier

Renverra le contenu de `chemin/vers/fichier` dans la révision SHA1. Pratique quand vous supprimez un
fichier par erreur :).

    git help show

## Mettre de côté les modifications de mon répertoire de travail

    git stash push -m "Ce que j'ai fait"

Toutes vos modifications sont remisées sous le nom « Ce que j'ai fait ». (L'ancienne forme était
`git stash save "Ce que j'ai fait"` ; `save` est déprécié au profit de `push`, qui accepte aussi une
liste de chemins pour ne remiser qu'une partie de votre travail.)

    git help stash

## Réappliquer les modifications que j'ai mises de côté

    git stash apply

Réappliquera la dernière modification remisée dans votre copie de travail.

    git stash pop

Fait la même chose qu'`apply` mais retire la modification de votre pile.

    git help stash

## Changer de branche et restaurer des fichiers sans checkout

`git checkout` fait deux métiers sans rapport, et c'est pourquoi il déroute tout le monde. Depuis
Git 2.23 il y a une commande pour chacun :

    git switch ma-branche         # au lieu de git checkout ma-branche
    git switch -c ma-branche      # au lieu de git checkout -b ma-branche
    git switch -                  # retour à la branche précédente, comme cd -
    git restore chemin/du/fichier # jeter mes modifications de ce fichier
    git restore --staged fichier  # le désindexer, garder la modification

`checkout` ne s'en va nulle part, et c'est toujours ce que tape la plus grande partie du monde. Mais
quand vous êtes sur le point de taper `git checkout -- quelque-chose`, la version au nom clair est
juste là.

    git help switch
    git help restore

## Pousser en force sans écraser un collègue

    git push --force-with-lease

Même idée que `--force`, sauf que Git vérifie d'abord que la branche distante est toujours là où
vous l'avez vue la dernière fois. Si quelqu'un a poussé pendant que vous rebasiez, le push est
refusé au lieu de supprimer discrètement son travail. Faites-en une habitude : `--force` c'est pour
quand vous y avez réfléchi, `--force-with-lease` c'est pour toutes les autres fois.

    git help push

## Travailler sur deux branches en même temps

    git worktree add ../hotfix main

Vous donne un second répertoire de travail, extrait sur une autre branche, partageant le même dépôt
— pas de second clone, pas de stash, pas d'interruption de ce que vous faisiez. Supprimez-le avec
`git worktree remove ../hotfix`. Voir
[Un dépôt, plusieurs arbres de travail](../4-beyond-the-basics/1-git-worktree.md "Un dépôt, plusieurs arbres de travail").

    git help worktree

## Comparer deux versions de la même branche

    git range-diff main..ma-feature@{1} main..ma-feature

Montre comment une série de commits a changé entre deux rebases : quels commits ont été ajoutés,
jetés, réordonnés, et en quoi chaque patch lui-même diffère.

    1:  34cb151 = 1:  34cb151 add a
    2:  66f725a ! 2:  ecb6096 add b

Le `=` veut dire que ce commit est inchangé, le `!` que le patch lui-même diffère, et le `<` ou le
`>` qu'un commit a été jeté ou ajouté. C'est l'outil du « qu'as-tu changé depuis ma dernière
relecture ? », et il n'y a rien d'autre de tel. (`ma-feature@{1}` est l'endroit où la branche
pointait avant votre dernière réécriture — le reflog, encore.)

    git help range-diff

## Corriger un commit au milieu d'une série

    git commit --fixup SHA1
    git rebase -i --autosquash SHA1~

La première commande fabrique un commit dont le sujet est `fixup! <le sujet de l'autre commit>`. La
seconde repère ces marqueurs, déplace chaque fixup à côté du commit auquel il appartient, et les
écrase, sans que vous ayez à réorganiser quoi que ce soit à la main. `--fixup :/quelques mots`
trouve même le commit cible en cherchant dans son message.

    git help commit

## Voir tout le graphe d'un coup

    git log --oneline --graph --all --decorate

Toutes les branches, toutes les étiquettes, sous forme de graphe ASCII, une ligne par commit. Ça
vaut un alias — c'est l'invocation de `git log` la plus utile qui soit, et c'est ainsi que vous
retrouvez la branche que vous aviez oubliée.

    git help log

## Savoir où je suis

    git rev-parse --show-toplevel     # la racine de l'arbre de travail
    git rev-parse --abbrev-ref HEAD   # le nom de la branche courante
    git rev-parse --short HEAD        # le commit courant, abrégé

`git rev-parse` est la commande de plomberie qui transforme un nom en réponse, et ces trois formes
finissent dans toutes les invites de shell et tous les scripts de déploiement jamais écrits.

    git help rev-parse

## Cacher un reformatage de masse à git blame

Vous avez passé un formateur sur tout le projet, et maintenant `git blame` dit que tout a été écrit
par vous mardi dernier. Mettez les commits fautifs dans un fichier, un SHA par ligne :

    git log --format=%H -1 > .git-blame-ignore-revs
    git blame --ignore-revs-file=.git-blame-ignore-revs unfichier.py

Mieux, commitez ce fichier et dites à Git de toujours l'utiliser :

    git config blame.ignoreRevsFile .git-blame-ignore-revs

Le blame saute désormais par-dessus le reformatage pour aller droit à qui a réellement écrit la
ligne. La vue blame de GitHub honore le même fichier, et le nom `.git-blame-ignore-revs` est une
convention qui mérite d'être respectée.

    git help blame
