---
title: Un peu de structure SVP
slug: "git-repo-structure"
weight: 14
---
# Un peu de structure SVP

Git vous laissera tout faire. Des branches appelées `x`, `x2`, `x2-final`, `x2-final-VRAIMENT` ; quarante mégaoctets de `node_modules` dans l'historique ; une version identifiée par « le commit que Sophie a poussé jeudi ». Rien dans l'outil ne l'empêche, et pour un projet du week-end il n'arrive rien de fâcheux.

Puis deux personnes arrivent, et puis une chaîne de déploiement, et soudain tous ces choix portent la charge. Ce chapitre parle des conventions qui poussent par-dessus Git : comment nommer les choses, comment marquer les versions, quoi garder hors du dépôt, et comment façonner ses branches. Rien de tout cela n'est imposé par Git. Tout cela fait la différence entre un dépôt dans lequel on peut travailler et un dépôt que l'on redoute.

## Les écoles de la branche principale

Il y a tout d'abord deux écoles intéressantes que vous avez intérêt à connaître : **Stable master** et **Unstable master**. Certains (comme votre serviteur) aiment l'idée que la branche principale représente la « prod », l'état stable de la production, et nous rendons même synonymes l'idée d'intégrer des changements sur cette branche et celle de mettre ces changements en production. Nous n'intégrons donc sur **master** que ce qui a été complètement testé, complètement validé. On demande à **master** d'être toujours au vert. Cela veut aussi dire que d'habitude toute nouvelle fonctionnalité sera basée sur cet état. Cela simplifie énormément de choses.

D'autres, au contraire, préfèrent cette branche comme la pointe la plus instable, où l'on intègre pêle-mêle tout ce qui s'est passé récemment. Ceux-là, chaque fois qu'ils veulent mettre quelque chose en production, vont « tagguer » une « release », lui donner un nom qui ne bougera plus. Nous verrons les **tags** plus bas.

> :information_source:
> **`master` ou `main` ?** Tout au long de ce cours nous disons `master`, parce que c'est toujours ce que `git init` vous donne sauf indication contraire, et parce que c'est le nom qu'a notre dépôt d'exemple depuis la partie 1. Mais GitHub, GitLab et la plupart des nouveaux projets depuis 2020 utilisent `main`, et vous devez vous attendre à rencontrer les deux pour le reste de votre carrière. Ce sont des noms de branches ordinaires — rien dans Git ne traite l'un ou l'autre spécialement — c'est donc purement une question de lettres. Pour que vos propres dépôts correspondent à votre hébergeur : `git config --global init.defaultBranch main`. Tout ce chapitre s'applique au mot que vous aurez choisi.

## La structure hiérarchique des branches

Comme nous l'avons déjà noté, une **branche** est un pointeur vers un **commit** ; en gros, cela nous donne un nom pour un commit. Et un commit a un **parent**. Les équipes parlent donc de leurs branches comme si elles aussi étaient rangées en hiérarchie, et elles les dessinent ainsi. Il existe de nombreuses façons de les organiser : parfois toutes plates (tout descend de master), parfois avec une structuration très stricte et une nomenclature précise pour les noms de branches.

Acceptons cette image un instant — c'est ainsi que les gens pensent et parlent — puis, dans la section suivante, démontons-la.

Dans la forme suivante par exemple :

```
- master
    -staging
        -correct_redirect
        -shopping_cart_spelling
    -development
        -add_top_banner
        -add_contextual_filter
```

On a la branche principale, **master**, réputée stable et en production. Une branche **staging** contient le code qui sera déployé sur mon environnement de qualification. Cette branche commence toujours par être synchronisée avec le master. Puis, si nous découvrons une anomalie sur la version de production, nous créons une nouvelle branche sous ce **staging** et nous y apportons les changements nécessaires. Quand ils sont prêts, et qu'ils auront passé tous nos tests… on pourra les réintégrer sur la branche **staging**. Puis, si tout va bien, on va les réintégrer à master et mettre ces changements en production.

Les nouvelles fonctionnalités, par contre, sont développées sur des branches à part, qui vont représenter le déploiement prochain. Si entre-temps **master** a bougé à cause de nos correctifs, nous avons toujours le loisir de réimporter ceux-là sur nos branches de développement (en anglais on utilise le terme **backport**), mais c'est alors toujours une action très explicite. C'est important, car parfois nos branches de développement peuvent diverger pas mal de notre **master**, si par exemple nous avons fait une importante refactorisation ; les correctifs de la « prod » ne vont pas toujours être applicables tels quels.

Ce qui est surtout important à noter, c'est que la structure de vos branches a tout intérêt à représenter votre méthode de travail, vos cycles de développement et de déploiement. Dans le premier exemple, les noms que nous avons donnés à nos branches sont descriptifs, comme `correct_redirect`.

Dans l'exemple suivant, nous représentons une structure de branches où la hiérarchie est plate, mais où les noms sont plus structurés. Les correctifs sont préfixés par « hotfix » ou « feature », et les noms des branches représentent un numéro de ticket dans notre système de suivi de tâches.

```
- master
    -hotfix/pf-223
    -hotfix/pf-578
    -feature/pf-431
    -feature/pf-563
```

Mais assez de théorie.

## La belle arborescence (structure de branches)

Allons regarder, parce qu'il y a un petit mais important mensonge dans les schémas ci-dessus, et il vaut mieux le dissiper avant d'aller plus loin.

Dépôt tout frais, un commit, et nous créons quelques branches aux noms qui ont l'air structurés :

```console
git branch feature/login
git branch feature/logout
git branch fix/pf-223
git branch chore/bump-deps
```

Maintenant le geste habituel :

```console
tree .git/refs/heads
```
```console
.git/refs/heads
├── chore
│   └── bump-deps
├── feature
│   ├── login
│   └── logout
├── fix
│   └── pf-223
└── master

4 directories, 5 files
```

La voilà. Notre belle arborescence est *réelle* — mais c'est une arborescence de **répertoires sur votre disque**, créée parce qu'un nom de **ref** est un chemin de fichier et que `/` est un séparateur de chemin. Rien de plus. `feature/login` est le fichier `.git/refs/heads/feature/login`, contenant quarante caractères hexadécimaux, exactement comme `master` est le fichier `.git/refs/heads/master`.

Ce qui veut dire que Git ne pense pas que `feature/login` soit « à l'intérieur » de `feature` en un sens quelconque. Il n'y a pas de branche parente, pas de branche enfant, aucune hiérarchie de branches nulle part dans le modèle de données de Git. `git branch` n'a pas d'option `--parent` parce qu'il n'y a rien à rapporter.

Alors qu'est-ce qui rend vrais les schémas ci-dessus ? Le **graphe des commits**. `feature/login` descend de `master` parce que le commit vers lequel elle pointe a, quelque part dans sa chaîne de parents, le commit vers lequel pointe `master`. C'est la seule structure qui existe, et vous pouvez l'interroger directement :

```console
git log --oneline --graph --all
git branch --contains 9056566
git branch --merged master
git branch --no-merged master
```

Les noms sont pour les *humains* — et pour les outils que les humains écrivent. Ce qui est le vrai bénéfice, parce que Git vous donne de la correspondance de motifs sur les noms de références :

```console
git branch --list 'feature/*'
```
```console
  feature/login
  feature/logout
```

Et la commande de plus bas niveau sur laquelle sont construits tous les scripts et toutes les invites de shell :

```console
git for-each-ref --format='%(refname) %(objectname:short)' refs/heads
```
```console
refs/heads/chore/bump-deps 20a274e
refs/heads/feature/login 20a274e
refs/heads/feature/logout 20a274e
{..}
```

C'est cela que veut dire votre configuration de CI quand elle écrit `only: - /^release\/.*$/`. Elle fait correspondre des chaînes de caractères. Ce qui est précisément pourquoi ces chaînes méritent qu'on y réfléchisse.

## Les noms de branches

Donc, des conventions. Ce sont les miennes, elles sont largement partagées, et chacune d'entre elles existe parce que l'automatisation de quelqu'un a cassé.

**Utilisez des minuscules, des chiffres, et `-` `_` `/` `.` comme séparateurs. Rien d'autre.** C'est tout. C'est toute la règle, et c'est le même avertissement que nous avons donné au chapitre sur les branches, désormais accompagné de ses raisons.

**Préfixez par intention.** Un espace de noms plat de quarante branches est illisible ; un espace préfixé se range tout seul :

```
feature/    une nouvelle capacité
fix/        une correction de bogue sur la ligne de développement courante
hotfix/     une correction urgente qui part directement en production
chore/      montées de version, configuration, outillage — aucun changement de comportement
release/    une branche qui existe pour stabiliser et livrer une version
```

**Mettez l'identifiant de ticket dans le nom.** `feature/pf-431-guest-checkout` est meilleur que `feature/pf-431` (opaque dans `git branch`) comme que `feature/guest-checkout` (impossible à relier à la discussion). Beaucoup d'hébergeurs relieront automatiquement la branche au ticket si l'identifiant est dans le nom, et le vous-du-futur qui lira `git log --graph` dans huit mois vous en sera reconnaissant.

**Gardez-les de courte durée de vie.** Le meilleur nom de branche est celui que personne n'a à lire très longtemps.

### La seule vraie contrainte : `/` fabrique des répertoires

Nous venons de voir que `feature/login` est un fichier dans un répertoire appelé `feature`. Ce qui a une conséquence qui fait trébucher tout le monde exactement une fois :

```console
git branch feature
```
```console
fatal: cannot lock ref 'refs/heads/feature': 'refs/heads/feature/login' exists; cannot create 'refs/heads/feature'
```

Vous ne pouvez pas avoir une branche `feature` *et* une branche `feature/login`, parce qu'un fichier ne peut pas être aussi un répertoire. Cela marche aussi dans l'autre sens :

```console
git branch experiment
git branch experiment/one
```
```console
fatal: cannot lock ref 'refs/heads/experiment/one': 'refs/heads/experiment' exists; cannot create 'refs/heads/experiment/one'
```

Ce n'est ni un bug ni de l'arbitraire : c'est un système de fichiers qui parle. Et c'est un bon argument pour choisir un schéma de préfixes et s'y tenir — soit tout est `feature/quelque-chose`, soit rien ne l'est. C'est le mi-figue mi-raisin qui provoque les collisions.

### Ce qu'il ne faut pas faire

**Les espaces.** Git ne vous laissera même pas faire :

```console
git branch 'my feature'
```
```console
fatal: 'my feature' is not a valid branch name
hint: See `man git check-ref-format`
hint: Disable this message with "git config set advice.refSyntax false"
```

**`HEAD`**, et quelques autres formes réservées :

```console
git branch HEAD
```
```console
fatal: 'HEAD' is not a valid branch name
```

**L'unicode et les emojis.** Git les autorise. Votre terminal les affichera, plus ou moins. Le script shell de votre CI ne les protégera pas par des guillemets, l'extraction de votre collègue sous Windows produira un nom de fichier que son antivirus n'aimera pas, et la ligne de log dans la sortie de déploiement sera du mojibake. C'est une mauvaise idée, et le fait que cela fonctionne n'est pas un argument.

**Les majuscules — surtout sous macOS et Windows.** Celle-ci mérite une démonstration, parce qu'elle est véritablement sournoise. Notre dépôt a déjà un répertoire `fix/`, à cause de `fix/pf-223`. Regardez :

```console
git branch Fix/PF-999
tree .git/refs/heads
```
```console
.git/refs/heads
├── chore
│   └── bump-deps
├── feature
│   ├── login
│   └── logout
├── fix
│   ├── pf-223
│   └── PF-999
└── master
```

Lisez cela attentivement. Nous avons demandé `Fix/PF-999`. Nous avons obtenu `fix/PF-999`. Le système de fichiers est insensible à la casse, donc quand Git est allé créer le répertoire `Fix`, il a trouvé `fix` déjà là et l'a utilisé. Git va maintenant nous dire :

```console
git branch --list 'fix/*'
```
```console
  fix/PF-999
  fix/pf-223
```
```console
git branch --list 'Fix/*'
```

— et celle-là n'affiche rien du tout. La branche que nous avons demandée n'existe pas sous le nom que nous avons tapé. Ce qui est poussé, c'est `fix/PF-999`. Sur la machine Linux d'un collègue, où `Fix` et `fix` sont deux répertoires différents, c'est là que commence une heure de confusion. Mettez tout en minuscules et le problème ne peut pas survenir.

**Les noms qui ressemblent à un SHA.** Git l'autorise aussi, et c'est un piège que vous vous tendez à vous-même :

```console
git branch 1213fc5
```

Pas d'erreur. Maintenant `git checkout 1213fc5` est ambigu entre une branche et un commit — Git choisira la branche et sera silencieusement peu serviable. Ne le faites pas.

### `git check-ref-format`, le règlement

Si vous écrivez un script qui accepte un nom de branche venant d'un humain, ou si vous voulez simplement savoir ce qui est légal, Git expose le validateur :

```console
git check-ref-format --branch 'my feature'
```
```console
fatal: 'my feature' is not a valid branch name
```

C'est le code de retour qui compte — zéro si valide, non nul sinon — donc il s'insère directement dans un `if` de shell. La forme « référence complète » prend tout le chemin :

```console
git check-ref-format 'refs/heads/feature/login'   # ok
git check-ref-format 'refs/heads/feature..login'  # rejeté
git check-ref-format 'refs/heads/fix.lock'        # rejeté
git check-ref-format 'refs/heads/what?'           # rejeté
```

`..` est exclu parce que c'est la syntaxe d'intervalle propre à Git. Un nom se terminant par `.lock` est exclu parce que c'est ainsi que Git verrouille les références pendant qu'il les met à jour. `?`, `*`, `[`, `~`, `^`, `:`, l'antislash, les espaces, les caractères de contrôle — tous exclus, tous pour des raisons que vous pouvez deviner. `man git-check-ref-format` a la liste complète et c'est une des rares pages de manuel Git qui soit courte.

## Les tags

La partie 1 n'a jamais présenté les **tags**, ou étiquettes, et il est temps, parce que toute l'école « unstable master » ci-dessus en dépend, et parce que c'est la plus jolie petite chose de Git.

Un **tag** est un nom pour un commit qui n'est *pas censé bouger*. Un nom de branche est un marque-page qui vous suit pendant que vous travaillez ; un tag est un clou dans le mur. `v1.0` devrait désigner le même commit dans cinq ans qu'aujourd'hui, dans votre dépôt et dans celui de tout le monde.

Et il y en a deux sortes, qui semblent identiques à l'usage quotidien et qui sont des objets complètement différents.

### Les tags légers

```console
git tag v0.9-wip
```

Git ne dit rien. Regardons :

```console
tree .git/refs/tags
cat .git/refs/tags/v0.9-wip
```
```console
.git/refs/tags
└── v0.9-wip

1 directory, 1 file
```
```console
a47856e41c9e5f275068920884c735276b97f1f6
```

Un fichier contenant un **SHA**. Exactement comme une branche, dans un répertoire différent. Et quand nous demandons à Git quel type d'objet ce nom désigne :

```console
git cat-file -t v0.9-wip
```
```console
commit
```

Un commit. Le tag *est* la référence ; il n'y a aucun objet tag. Rien n'a été ajouté à `.git/objects`. Un tag léger ne porte ni message, ni auteur, ni date, ni signature — c'est un marque-page privé, et c'est la bonne façon d'y penser.

### Les tags annotés

```console
git tag -a v1.0 -m'First release: readme, license and a homepage stub'
cat .git/refs/tags/v1.0
```
```console
75fff39cacc4f49bc16fe5d3d798cdeb393ed8a5
```

Attendez un instant. Notre commit était `a47856e`. Qu'est-ce que `75fff39` ?

```console
git cat-file -t v1.0
```
```console
tag
```

Un quatrième type d'objet ! Nous connaissons **blob**, **tree** et **commit** depuis la partie 1 ; voici le dernier. Et comme les autres, nous pouvons simplement le lire :

```console
git cat-file -p v1.0
```
```console
object a47856e41c9e5f275068920884c735276b97f1f6
type commit
tag v1.0
tagger Ori Pekelman <ori+git-training@pekelman.com> 1770285600 +0100

First release: readme, license and a homepage stub
```

Voyez comme cette forme est familière. Elle est disposée exactement comme le **commit** que nous avons disséqué en partie 1 : quelques lignes `clé valeur`, une ligne vide, puis un message. `object` est ce vers quoi il pointe, `type` est le genre de chose que c'est, `tag` est le nom, `tagger` est qui et quand — un nom, un e-mail et un **timestamp** Unix avec un fuseau horaire, même format que `author` et `committer`.

Un tag annoté est donc un véritable objet, stocké dans `.git/objects` comme tout le reste, avec son propre SHA, et la référence dans `refs/tags/` pointe vers *lui* plutôt que vers le commit. Il peut être signé, avec GPG (`git tag -s`) ou, depuis Git 2.34, avec une clé SSH, ce qui est la manière dont les artefacts de version se voient attribués cryptographiquement à un humain.

> :information_source:
> C'est de là que vient le `^{}` dans la sortie de `git ls-remote` du chapitre sur les dépôts distants :
> ```console
> 75fff39cacc4f49bc16fe5d3d798cdeb393ed8a5	refs/tags/v1.0
> a47856e41c9e5f275068920884c735276b97f1f6	refs/tags/v1.0^{}
> ```
> Deux lignes pour un tag : l'objet tag, et — `^{}` signifiant « pèle ceci jusqu'à atteindre un non-tag » — le commit vers lequel il pointe en fin de compte.

**Ayez une opinion là-dessus : utilisez des tags annotés pour tout ce que vous publiez.** Une version mérite d'enregistrer qui l'a faite, quand et pourquoi. Les tags légers conviennent très bien comme marques personnelles de brouillon (« `avant-la-grosse-refactorisation` »), et il n'y a pas de honte à cela, mais ils ne devraient pas être ce à partir de quoi votre chaîne de déploiement construit.

### Travailler avec les tags

```console
git tag
```
```console
v0.9-wip
v1.0
```

Filtrez avec un motif — indispensable dès qu'un projet en a trois cents :

```console
git tag -l 'v1.*'
```
```console
v1.0
```

Ajoutez `-n` pour voir les messages (pour un tag léger, Git montre le sujet du commit à la place, puisqu'il n'a pas de message propre) :

```console
git tag -n
```
```console
v0.9-wip        Add an empty homepage template
v1.0            First release: readme, license and a homepage stub
```

`git show` sur un tag annoté montre le tag, puis le commit, puis le diff :

```console
git show v1.0
```
```console
tag v1.0
Tagger: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Thu Feb 5 11:00:00 2026 +0100

First release: readme, license and a homepage stub

commit a47856e41c9e5f275068920884c735276b97f1f6
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Wed Feb 4 09:00:00 2026 +0100

    Add an empty homepage template

diff --git a/views/homepage.html b/views/homepage.html
new file mode 100644
{..}
```

Supprimer localement :

```console
git tag -d v0.9-wip
```
```console
Deleted tag 'v0.9-wip' (was a47856e)
```

Et un tag est une chose parfaitement valable à extraire, à comparer, ou à cloner — `git checkout v1.0` vous met en **detached head** sur ce commit exact, ce qui est précisément ce que vous voulez quand vous enquêtez sur « est-ce que c'était cassé en 1.0 ? ».

### `git describe`

Une petite commande qui résout un vrai problème : nommer le commit sur lequel vous êtes, en termes humains.

```console
git describe
```
```console
v1.0-1-g69dd359
```

Lisez-la en trois parties : le tag **annoté** le plus récent atteignable d'ici (`v1.0`), de combien de commits nous l'avons dépassé (`1`), et le SHA abrégé de là où nous sommes réellement (`g` pour « git », puis `69dd359`). Sur le commit taggué lui-même, vous obtenez juste le tag :

```console
git describe v1.0
```
```console
v1.0
```

C'est de là que les systèmes de build tirent leurs chaînes de version. Et notez l'insistance sur *annoté* : un dépôt sans aucun tag dit `fatal: No names found, cannot describe anything.`, tandis qu'un dépôt qui n'a que des tags légers dit

```console
fatal: No annotated tags can describe '20a274e12b45c66e74942b44f159320d4b04d050'.
However, there were unannotated tags: try --tags.
```

ce qui est Git qui vous dit, poliment, que vous avez mal taggué votre version. `git describe --tags` se rabattra sur les tags légers si vous insistez.

### Pousser les tags, et ne pas les déplacer

Nous avons couvert cela au chapitre précédent et il vaut la peine de le répéter parce que cela surprend tout le monde : **`git push` ne pousse pas les tags.** Le refspec ne couvre que `refs/heads/*`. Il vous faut `git push origin v1.0`, ou `--follow-tags`, ou `push.followTags = true`.

> :warning:
> **Ne déplacez et ne supprimez jamais un tag publié.** Git vous laissera faire : `git tag -f v1.0 <autre-commit>` et un push forcé le feront. Mais toute la valeur d'un tag est qu'il signifie une seule chose pour toujours. Tous ceux qui ont déjà récupéré `v1.0` gardent l'ancien — Git ne met pas à jour les tags existants lors d'un fetch — donc à partir de ce moment, `v1.0` désigne des commits différents sur des machines différentes, et le rapport de bug que vous recevrez sera irreproductible pour des raisons que personne ne peut voir. Si vous avez livré le mauvais commit en `v1.0`, livrez `v1.0.1`. Cela ne coûte rien et c'est la vérité.

Et le **versionnage sémantique** en une phrase, puisque nous nommons des versions : `MAJEUR.MINEUR.CORRECTIF`, où l'on incrémente CORRECTIF pour une correction de bogue, MINEUR pour un ajout rétrocompatible, et MAJEUR quand on casse le code de quelqu'un — la promesse étant que vos utilisateurs peuvent lire le numéro et savoir si la mise à jour est sans risque (la spécification complète est sur [semver.org](https://semver.org)).

## Un peu de propreté SVP : `.gitignore`

Tout projet accumule des fichiers qui ne doivent pas être committés : sortie de compilation, dépendances, fichiers de log, déjections d'éditeur, `.DS_Store`, configuration locale avec des identifiants dedans. Laissé à lui-même, `git status` se remplit de bruit, `git add .` devient dangereux, et finalement quelqu'un committe un répertoire de build de 200 Mo.

La solution est un fichier appelé `.gitignore`, qui est l'une des très rares choses dans Git que les gens utilisent pendant des années sans jamais en lire les règles. Alors lisons les règles.

### La syntaxe des motifs

Un `.gitignore` est une liste de motifs, un par ligne, `#` pour les commentaires, lignes vides ignorées.

```console
cat .gitignore
```
```console
node_modules/
*.log
!logs/keep.log
build/
```

* **Glob simple.** `*.log` correspond à tout fichier dont le nom se termine par `.log`, à *n'importe quelle* profondeur. `*` ne traverse pas `/` ; `?` est un caractère ; `[0-9]` est une classe.
* **Un `/` final signifie « répertoire seulement ».** `build/` ignore le répertoire et tout ce qu'il contient, mais ne correspondrait pas à un *fichier* appelé `build`. Utilisez-le chaque fois que vous voulez dire un répertoire — c'est plus rapide et plus précis, parce que Git peut arrêter de descendre.
* **Un `/` ailleurs ancre le motif** au répertoire contenant le `.gitignore`. Ainsi `/TODO.txt` ne correspond qu'à celui du premier niveau ; `TODO.txt` tout court correspond à toutes les profondeurs. C'est la règle que les gens se trompent le plus souvent.
* **`**` traverse les répertoires.** `doc/**/out.html` correspond à `doc/build/out.html` et à `doc/a/b/out.html`. `**/config/` correspond à un répertoire `config` n'importe où.
* **`!` nie**, en réincluant quelque chose qu'un motif antérieur avait exclu. L'ordre compte : c'est le *dernier* motif correspondant qui gagne.

Plutôt que de me croire sur parole, il existe une commande qui vous montre la décision réelle de Git et, surtout, *quelle ligne l'a prise* :

```console
git check-ignore -v build/app logs/error.log logs/keep.log src/vendor/lib.js
```
```console
.gitignore:4:build/	build/app
.gitignore:2:*.log	logs/error.log
.gitignore:3:!logs/keep.log	logs/keep.log
```

Fichier, numéro de ligne, le motif lui-même, puis le chemin. Notez que `src/vendor/lib.js` n'a produit aucune ligne du tout — il n'est pas ignoré, il n'y a donc rien à rapporter. **`git check-ignore -v` est la commande la plus utile de cette section.** Toute question « pourquoi Git ignore-t-il mon fichier » ou « pourquoi Git n'ignore-t-il *pas* mon fichier » est à une invocation de sa réponse.

Voici ce comportement d'ancrage et de `**`, vérifié plutôt qu'affirmé — dans un petit dépôt séparé, pour que les numéros de ligne restent faciles à suivre :

```console
cat .gitignore
```
```console
/TODO.txt
doc/**/out.html
**/config/
```
```console
git check-ignore -v TODO.txt a/TODO.txt doc/build/out.html a/b/config/x.json tools/doc/notes.txt
```
```console
.gitignore:1:/TODO.txt	TODO.txt
.gitignore:2:doc/**/out.html	doc/build/out.html
.gitignore:3:**/config/	a/b/config/x.json
```

Le `TODO.txt` du premier niveau est ignoré ; `a/TODO.txt` ne l'est pas, à cause du slash initial. `tools/doc/notes.txt` ne l'est pas, parce que `doc/**` est ancré au sommet.

### La règle de négation qui n'a pas de contournement

Celle-ci vaut la peine d'être mémorisée, parce qu'elle ressemble à un bug. Nous ajoutons une cinquième ligne au `.gitignore` que nous utilisions, en essayant de faire une exception :

```console
cat .gitignore
```
```console
node_modules/
*.log
!logs/keep.log
build/
!build/app
```
```console
git check-ignore -v build/app
```
```console
.gitignore:4:build/	build/app
```

Toujours ignoré, malgré le `!`. **Vous ne pouvez pas réinclure un fichier si l'un de ses répertoires parents est exclu.** La raison est la performance : quand Git voit `build/` exclu, il arrête complètement d'y descendre, il ne regarde donc jamais `build/app` et n'a jamais l'occasion d'appliquer la négation.

La ligne 4 gagne, et la ligne 5 n'est même jamais consultée. La solution est d'exclure le *contenu* plutôt que le répertoire — un caractère :

```console
cat .gitignore
```
```console
node_modules/
*.log
!logs/keep.log
build/*
!build/app
```
```console
git check-ignore -v build/app
```
```console
.gitignore:5:!build/app	build/app
```

`build/*` exclut les enfants individuellement, donc Git descend bien, et la négation a son tour. Chaque fois qu'un `!` ne fait mystérieusement rien, cherchez vers le haut un répertoire exclu.

### Où vivent les règles, et qui gagne

Il y a quatre endroits, et ils sont classés, de la **précédence la plus forte à la plus faible**. À l'intérieur d'un rang, le dernier motif correspondant gagne ; entre les rangs, le rang supérieur bat simplement l'inférieur.

1. **Les motifs en ligne de commande**, pour les quelques commandes qui en prennent. Rien ne les surpasse.
2. **Les fichiers `.gitignore` de l'arbre** — et parmi ceux-là, *le plus profond gagne*, en surchargeant ses parents pour son propre sous-arbre :

```console
cat docs/.gitignore
```
```console
!*.log
```
```console
git check-ignore -v docs/build.log
```
```console
docs/.gitignore:1:!*.log	docs/build.log
```

Le `.gitignore` du premier niveau dit `*.log` ; `docs/.gitignore` le surcharge pour ce sous-arbre. C'est ainsi que l'on garde une règle valable pour tout le projet et une exception locale.

3. **`.git/info/exclude`** — même syntaxe, mais il vit dans `.git` et n'est donc *pas committé*. C'est le bon endroit pour les choses qui ne regardent que vous : votre répertoire de brouillons, le fichier où vous gardez des notes locales.

```console
git check-ignore -v scratch/notes
```
```console
.git/info/exclude:7:scratch/	scratch/notes
```

(Ligne 7 parce que `git init` met six lignes de commentaire explicatif dans ce fichier pour vous. Nous l'avons rencontré en partie 1, dans le tout premier `tree -C .git`, et nous n'avions jamais découvert à quoi il servait. Maintenant nous le savons.)

4. **`core.excludesFile`** — une liste globale pour toute votre machine, et la plus *faible* des quatre, de sorte que n'importe quel projet peut la surcharger :

```console
git config --global core.excludesFile ~/.gitignore_global
```
```console
git check-ignore -v src/main.py.swp
```
```console
/Users/oripekelman/.gitignore_global:1:*.swp	src/main.py.swp
```

Le classement est facile à retenir dès qu'on en voit la logique : plus une règle est proche de la chose dont elle parle, plus on lui fait confiance. Un motif que vous avez tapé en ligne de commande bat un fichier dans le répertoire, qui bat un fichier au sujet du dépôt, qui bat un fichier au sujet de votre portable.

> :information_source:
> Une règle de savoir-vivre à adopter : **les déjections de votre éditeur n'ont pas leur place dans le `.gitignore` du projet.** `.DS_Store`, `*.swp`, `.idea/`, `.vscode/` — ce sont des faits concernant *votre* machine, et les mettre dans le fichier partagé fait que chaque projet que vous touchez se voit pousser une section pour chaque outil que quiconque dans l'équipe a un jour utilisé. Mettez-les une fois dans votre fichier d'exclusions global, et n'y pensez plus jamais. Le `.gitignore` du projet devrait décrire *le projet* : sa sortie de compilation, ses répertoires de dépendances, ses fichiers générés.

### Le fait le plus important à propos de `.gitignore`

Le voici, et il explique la majorité de la confusion autour de `.gitignore` dans le monde :

**`.gitignore` n'affecte que les fichiers que Git ne suit pas déjà.**

Une fois qu'un fichier a été committé, l'ajouter à `.gitignore` ne fait absolument rien. Regardez. Nous committons un fichier que nous n'aurions pas dû — `.env`, avec un mot de passe dedans, comme cela arrive — puis nous ajoutons `.env` comme sixième ligne du `.gitignore`, puis nous modifions le fichier :

```console
git status --short
```
```console
 M .env
 M .gitignore
?? build/
?? logs/
?? src/vendor/
```

` M .env` — modifié, suivi, rapporté, et le prochain `git commit -a` l'inclura joyeusement. Pendant ce temps :

```console
git check-ignore -v .env
```

Rien du tout, et le code de retour est 1. `check-ignore` saute les chemins suivis par défaut, ce qui est en soi l'indice. Forcez-le à répondre quand même :

```console
git check-ignore -v --no-index .env
```
```console
.gitignore:6:.env	.env
```

« Votre motif est correct et il correspond bien — mais ce fichier est dans l'**index**, donc le motif n'a aucune importance. » Ce qui est exactement la situation, énoncée précisément.

La solution est de le retirer de l'index tout en le laissant sur le disque, ce que veut dire `--cached` :

```console
git rm --cached .env
```
```console
rm '.env'
```
```console
git status --short
```
```console
D  .env
 M .gitignore
?? build/
?? logs/
?? src/vendor/
```

`D` dans la première colonne : préparé pour suppression du dépôt. Le fichier est toujours dans votre répertoire de travail — `--cached` n'a touché que l'index. Committez cela, et à partir de là la règle d'exclusion s'applique :

```console
git commit -am'Stop tracking the environment file'
git status --short
```
```console
?? build/
?? logs/
?? src/vendor/
```

`.env` a disparu de la sortie. Ignoré, enfin.

> :warning:
> `git rm --cached` **supprime le fichier du prochain commit**. Quiconque fera un pull le verra disparaître de son répertoire de travail. Pour des fichiers du genre `.env`, dont chacun a sa propre copie, c'est exactement ce qu'il faut — committez plutôt un `.env.example`. Mais annoncez-le, ou l'après-midi de votre collègue devient un mystère.

### Deux autres commandes que vous voudrez

Pour voir ce qui vous est caché :

```console
git status --short --ignored
```
```console
?? logs/
?? src/vendor/
!! build/
!! logs/error.log
```

`!!` marque les entrées ignorées. Excellent pour le moment où vous soupçonnez que votre build utilise un fichier qui n'a jamais été committé.

Et pour passer outre les règles une fois, délibérément :

```console
git add logs/error.log
```
```console
The following paths are ignored by one of your .gitignore files:
logs/error.log
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
```

Git refuse et vous indique la sortie de secours :

```console
git add -f logs/error.log
```

Parfois légitime — un unique fichier généré qui doit véritablement être committé à l'intérieur d'un répertoire par ailleurs ignoré. Généralement le signe que vos motifs ont besoin d'être corrigés.

Et n'écrivez pas le fichier à partir de rien : GitHub maintient une grande collection de modèles de `.gitignore` par langage et par chaîne d'outils sur [github.com/github/gitignore](https://github.com/github/gitignore), et chaque hébergeur les propose dans le formulaire « nouveau dépôt ». Partez de celui de votre pile technique — il listera une demi-douzaine de fichiers dont vous ignoriez que vos outils les créaient — puis ajoutez les spécificités de votre projet.

### L'autre fichier : `.gitattributes`

`.gitignore` dit quels fichiers Git ne doit pas regarder. **`.gitattributes`** dit comment Git doit *traiter* ceux qu'il regarde. Même idée — des motifs, un par ligne, committés avec le projet, le fichier le plus profond gagne — mais au lieu de « ignore ceci », vous positionnez des attributs nommés.

```console
cat .gitattributes
```
```console
* text=auto
*.sh text eol=lf
*.png binary
```

Et, comme toujours, vous pouvez demander à Git ce qu'il a conclu :

```console
git check-attr text eol diff -- run.sh logo.png notes.md
```
```console
run.sh: text: set
run.sh: eol: lf
run.sh: diff: unspecified
logo.png: text: unset
logo.png: eol: unspecified
logo.png: diff: unset
notes.md: text: auto
{..}
```

Ce à quoi les gens s'en servent réellement :

* **Les fins de ligne.** `* text=auto` dit à Git de stocker les fichiers texte en LF en interne et de les extraire dans la forme native de la plateforme. `eol=lf` force le LF à l'extraction aussi, ce qui est ce que vous voulez pour des scripts shell qu'un collègue sous Windows pourrait autrement committer en CRLF et rendre non exécutables. Si vous avez déjà vu un diff où absolument toutes les lignes ont changé, c'est ce fichier qui le corrige.
* **Marquer les binaires.** `*.png binary` est un raccourci pour « n'essaie pas de comparer ni de fusionner ceci, et ne touche pas à ses octets ». Cela évite à Git de produire un diff inutile et vous évite une fusion corrompue.
* **Indices de langage.** `*.min.js linguist-generated=true` dit au détecteur de langages de GitHub d'exclure un fichier des statistiques et de le replier dans les pull requests. Purement cosmétique, assez satisfaisant.
* **Pilotes de diff et de merge personnalisés.** `*.json diff=json`, ou un pilote de fusion qui sait combiner un changelog. Avancé, et occasionnellement exactement ce dont vous avez besoin.
* **Git LFS.** Le stockage des gros fichiers se configure entièrement par `.gitattributes` — `*.psd filter=lfs diff=lfs merge=lfs -text` — ce qui explique que lancer `git lfs track` modifie ce fichier. Cela a un chapitre à part entière : [Les gros fichiers, ou comment Git rencontre ses limites](../4-beyond-the-basics/4-git-lfs.md "Les gros fichiers, ou comment Git rencontre ses limites").

> :warning:
> **Mettre un secret dans `.gitignore` ne le protège pas, et ne l'a jamais protégé.** `.gitignore` empêche qu'un fichier soit *ajouté* ; il ne fait rien pour un fichier déjà committé. Et voici la partie que les gens sous-estiment : un secret qui a été committé **et poussé** est compromis, définitivement. Le supprimer dans un commit ultérieur le laisse dans l'historique. Réécrire l'historique le laisse dans tous les clones que quiconque a faits, dans les reflogs, dans les caches de votre hébergeur, et — si le dépôt a jamais été public — dans les archives des différents services qui scrutent les push publics en temps réel, et dans les données d'entraînement de tous les modèles depuis. La seule réponse correcte est de **faire tourner le secret** : le révoquer, en émettre un nouveau, et *ensuite* se soucier de nettoyer l'historique. Le nettoyage vaut la peine d'être fait, et [Garder un historique propre, se remettre de ses erreurs](6-git-cleanup.md "Garder un historique propre, se remettre de ses erreurs") montre comment. Ce n'est pas ce qui vous met en sécurité.

## La belle entente : Gitflow et ses amis

Nous avons des noms, nous avons des tags, nous avons un dépôt qui ne contient que les fichiers qui y ont leur place. Le dernier morceau de structure est l'accord : *quelles branches existent, ce qu'elles signifient, et comment le travail circule entre elles.*

Ces accords ont des noms, on s'y dispute avec plus d'ardeur qu'ils ne le méritent, et — c'est la partie qui vaut la peine d'être intériorisée — **ce ne sont tous que des conventions sur les noms de branches.** Aucun n'est une fonctionnalité de Git. Chacun d'eux est mis en œuvre avec les mêmes `git branch`, `git merge` et `git tag` que vous connaissez déjà.

### GitFlow

Vincent Driessen a publié *A successful Git branching model* en janvier 2010 et c'est devenu, pendant une dizaine d'années, la réponse. Il comporte :

* **`master`** — la production uniquement. Chaque commit dessus est une version, et porte un tag.
* **`develop`** — la branche d'intégration, où atterrissent les fonctionnalités terminées. L'école « unstable master », dotée de sa propre branche.
* **`feature/*`** — partir de `develop`, fusionner de retour dans `develop`.
* **`release/*`** — créée depuis `develop` quand vous décidez de livrer. On stabilise ici, pas de nouvelles fonctionnalités. Quand c'est prêt, fusionner dans `master` (et tagguer), et de retour dans `develop`.
* **`hotfix/*`** — créée depuis `master` pour les urgences de production. Fusionner dans `master` (et tagguer) *et* dans `develop`, pour que le correctif ne soit pas perdu.

C'est cohérent, c'est complet, et cela gère correctement les cas gênants, ce qui explique sa popularité. C'est aussi beaucoup de cérémonie : cinq types de branches, deux branches de longue durée à garder synchronisées, et chaque version impliquant quatre fusions.

Et son propre auteur le dit. Dans une note ajoutée à ce billet le 5 mars 2020, Driessen a écrit que git-flow avait été conçu pour des logiciels *explicitement versionnés* — ceux où l'on livre des versions et où l'on en supporte plusieurs en circulation à la fois — et il a ajouté :

> Si votre équipe pratique la livraison continue, je suggérerais d'adopter un workflow beaucoup plus simple (comme GitHub flow) plutôt que d'essayer de faire rentrer git-flow au chausse-pied dans votre équipe.

Ce qui est la phrase la plus utile de tout ce chapitre, et elle vient de la personne qui a le plus à perdre à la dire. **Utilisez GitFlow si vous livrez du logiciel versionné avec plusieurs versions supportées** — une bibliothèque, une application de bureau, tout ce qui est installé chez le client, où des clients font tourner 3.2 et 4.0 simultanément. Si vous déployez votre application web onze fois par jour, c'est de la machinerie que vous portez pour rien.

### GitHub Flow

La réaction, et radicalement plus simple. Il y a une seule branche de longue durée, `main`. Pour faire quoi que ce soit :

1. Créer une branche à partir de `main`.
2. Committer, pousser, ouvrir une pull request.
3. La faire relire, laisser tourner la CI.
4. Fusionner dans `main`.
5. Déployer `main`.

C'est tout le modèle. Pas de `develop`, pas de branches de release, pas de fusions en retour. Sa justesse dépend entièrement de deux choses : `main` doit toujours être déployable, et les branches doivent être de courte durée — des jours, pas des semaines. Si vous avez les deux, c'est très difficile à battre. Si vous n'avez pas de tests automatisés, « main est toujours déployable » est un vœu plutôt qu'une propriété, et ce modèle vous fera mal.

### GitLab Flow

GitHub Flow plus la reconnaissance du fait que la plupart des équipes ne déploient pas directement en production. On ajoute des **branches d'environnement** de longue durée en aval de `main` : `main` → `staging` → `production`. Le code ne circule que dans un sens, par fusion, si bien qu'une branche d'environnement est toujours un *préfixe* de l'historique de `main` et que « qu'y a-t-il en production » est une question qui a une réponse. Les correctifs urgents vont dans `main` et sont reportés par cherry-pick quand ils ne peuvent pas attendre.

C'est essentiellement le modèle décrit dans la prose du haut de ce chapitre, et c'est un juste milieu solide quand vous avez de vrais environnements et une cadence de livraison qui n'est pas continue.

### Le développement sur le tronc

L'extrémité opposée du spectre. Tout le monde committe sur `main` — soit directement, soit via des branches qui vivent des *heures*. Rien n'est de longue durée, donc rien ne diverge, donc l'intégration n'est jamais un événement. Le travail incomplet part en production, désactivé derrière un **feature flag**, et il est activé séparément du déploiement.

Ce dernier point est ce qui fait que cela fonctionne, et c'est un véritable arbitrage : vous avez déplacé la complexité hors de Git (où c'étaient des conflits de fusion) et dans votre application (où c'est de la configuration de drapeaux, et des drapeaux qu'il faut penser à retirer). Cela exige aussi des tests automatisés solides, parce qu'il n'y a pas de phase de stabilisation pendant laquelle découvrir les choses.

Il vaut la peine de savoir que ce n'est pas une position marginale. Le programme de recherche DORA — le travail d'enquête pluriannuel derrière *Accelerate* — a constamment trouvé que le développement sur le tronc, avec des branches de courte durée et des fusions au moins quotidiennes, faisait partie des pratiques corrélées à une haute performance de livraison logicielle. Non pas parce que les branches sont mauvaises, mais parce que c'est dans les branches de *longue durée* que la douleur d'intégration se compose.

### Les branches de release pour les produits à versions longues

Orthogonal à tout ce qui précède, et nécessaire si vous supportez d'anciennes versions : quand vous livrez la 2.4, vous gardez vivante une branche `release/2.4` (ou `2.4.x`). Les correctifs sont faits sur `main` et reportés par cherry-pick, ou faits sur la plus ancienne branche de release affectée et fusionnés vers l'avant. Chaque version corrective reçoit son propre tag. C'est ainsi que fonctionnent les branches *longterm* du noyau Linux, c'est ainsi que fonctionne PostgreSQL, c'est ainsi que fonctionne tout ce qui a une promesse de LTS, et il n'y a pas de manière plus simple de tenir une telle promesse.

### Alors, lequel ?

L'opinion de ce cours, et elle ne porte qu'en partie sur Git :

**La forme de vos branches devrait refléter votre cadence de livraison.** C'est là la vraie règle, et chaque modèle ci-dessus en est un cas particulier. Si vous livrez quand une branche de release est prête, il vous faut des branches de release. Si vous supportez quatre versions, il vous faut quatre branches de longue durée. Si vous déployez à chaque fusion, il vous faut une branche et une solide suite de tests.

Et ensuite : **si vous déployez en continu, le modèle le plus simple qui fonctionne est le bon.** La complexité d'un modèle de branchement n'est pas gratuite — elle se paie tous les jours, par chaque personne de l'équipe, en cérémonie et en erreurs. Les équipes adoptent GitFlow parce que c'est écrit noir sur blanc et que cela fait professionnel, puis passent un an à garder `develop` et `master` synchronisés pour un service qui a exactement une version en existence. Commencez avec une branche et des branches de fonctionnalité de courte durée. Ajoutez une branche `release/*` la première fois que vous avez réellement besoin de stabiliser quelque chose pendant que le travail continue. Ajoutez des branches d'environnement la première fois que vous avez réellement des environnements. N'ajoutez jamais un type de branche parce qu'un schéma en comportait un.

Ce qui nous ramène là où la prose de ce chapitre a commencé, et elle avait raison du premier coup : *la structure de vos branches a tout intérêt à représenter votre méthode de travail.* Votre méthode de travail d'abord. Les branches ensuite.

Et quoi que vous choisissiez, écrivez-le — dans le `readme.md`, ou dans un `CONTRIBUTING.md`. Un modèle de branchement qui vit dans la tête du développeur senior n'est pas une convention, c'est un bizutage.

## Récapitulatif : les noms, les tags, `.gitignore` et les modèles de branchement

* La hiérarchie des branches vit dans les **noms**, pas dans Git : `feature/login` est le fichier `.git/refs/heads/feature/login` et `/` est un séparateur de chemin. La seule structure réelle est le graphe des **commit**s — `git log --graph --all`, `git branch --contains`, `git branch --merged`. Les noms sont pour les humains et pour l'outillage : `git branch --list 'feature/*'`, `git for-each-ref refs/heads`.
* Nommage des branches : minuscules, chiffres, `-` `_` `/` `.` ; préfixer par intention (`feature/`, `fix/`, `hotfix/`, `chore/`, `release/`) ; inclure l'identifiant de ticket ; les garder de courte durée.
* Parce que `/` fabrique un répertoire, vous ne pouvez pas avoir à la fois `feature` et `feature/login` — *`cannot lock ref 'refs/heads/feature': 'refs/heads/feature/login' exists`*. Évitez les espaces et `HEAD` (Git refuse), l'unicode et les emojis (Git autorise, votre outillage non), les noms en forme de SHA, et les majuscules — sur un système de fichiers insensible à la casse, `Fix/PF-999` devient silencieusement `fix/PF-999`. `git check-ref-format --branch <nom>` est le validateur officiel.
* Un **tag** nomme un commit qui ne doit pas bouger. Un tag **léger** (`git tag v0.9`) n'est qu'une référence dans `refs/tags/`. Un tag **annoté** (`git tag -a v1.0 -m'...'`) crée un véritable **objet tag** dans `.git/objects` avec un tagger, une date, un message et une signature GPG/SSH optionnelle — lisez-le avec `git cat-file -p v1.0`. Utilisez des tags annotés pour tout ce que vous publiez.
* `git tag`, `git tag -l 'v1.*'`, `git tag -n`, `git show <tag>`, `git tag -d <tag>`, et `git describe` → `v1.0-1-g69dd359` (le tag annoté le plus proche, les commits depuis, le SHA abrégé). Les tags ne sont **pas** poussés par `git push` ; utilisez `git push origin v1.0` ou `--follow-tags`. **Ne déplacez et ne supprimez jamais un tag publié** — livrez `v1.0.1`. Numéros de version : `MAJEUR.MINEUR.CORRECTIF` — casser, ajouter, corriger.
* Motifs de `.gitignore` : glob (`*` ne traverse pas `/`), `/` final pour les répertoires seulement, un `/` ailleurs ancre au répertoire contenant, `**` traverse les répertoires, `!` nie et le dernier motif correspondant gagne. **Vous ne pouvez pas réinclure un fichier sous un répertoire exclu** — excluez `build/*`, pas `build/`.
* Précédence, de la plus forte à la plus faible : motifs en ligne de commande → fichiers `.gitignore`, le plus profond gagnant → `.git/info/exclude` (personnel, non committé) → `core.excludesFile` (global, et là où les déjections de votre éditeur ont leur place). Plus proche du fichier veut dire plus digne de confiance.
* **`.gitignore` n'affecte que les fichiers non suivis.** Ignorer un fichier déjà suivi ne fait rien ; `git rm --cached <fichier>` le retire de l'**index** en le laissant sur le disque, et *ensuite* la règle s'applique.
* `git check-ignore -v <chemin>` nomme le fichier, la ligne et le motif responsables — la réponse à toute question d'exclusion ; `--no-index` le fait répondre aussi pour les fichiers suivis. `git status --ignored` montre ce qui est caché (`!!`) ; `git add -f` passe outre une fois. Partez d'un modèle sur [github.com/github/gitignore](https://github.com/github/gitignore).
* `.gitattributes` est le fichier frère — comment Git *traite* les fichiers plutôt que s'il les voit : `* text=auto`, `eol=lf`, `*.png binary`, indices linguist, pilotes de diff et de merge personnalisés, et là où vit **Git LFS** ([Les gros fichiers](../4-beyond-the-basics/4-git-lfs.md "Les gros fichiers, ou comment Git rencontre ses limites")). `git check-attr` montre le résultat.
* Ignorer un secret ne protège rien. Un secret committé et poussé est compromis pour toujours : **faites-le tourner**, puis nettoyez l'historique ([Garder un historique propre, se remettre de ses erreurs](6-git-cleanup.md "Garder un historique propre, se remettre de ses erreurs")).
* Les modèles de branchement sont des conventions sur les noms de branches, pas des fonctionnalités de Git. **GitFlow** (`develop`, `release/*`, `hotfix/*`, `feature/*`) pour du logiciel explicitement versionné avec plusieurs versions supportées — son propre auteur le déconseille pour la livraison continue. **GitHub Flow** : une branche de longue durée, des branches de fonctionnalité courtes, déploiement depuis `main` ; exige que `main` soit toujours déployable. **GitLab Flow** ajoute des branches d'environnement. Le **développement sur le tronc** avec des feature flags est ce que la recherche DORA associe aux équipes les plus performantes.
* La règle derrière tous : la forme de vos branches devrait refléter votre cadence de livraison — et si vous déployez en continu, le modèle le plus simple qui fonctionne est le bon. Puis écrivez-le.
