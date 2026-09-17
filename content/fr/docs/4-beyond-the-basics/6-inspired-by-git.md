---
title: Ce que Git a inspiré
slug: "inspired-by-git"
weight: 36
---
# Ce que Git a inspiré

Nous avons passé beaucoup de temps dans la salle des machines. Nous avons ouvert `.git/objects` à
mains nues, nous avons suivi un **commit** vers un **arbre** vers un **blob**, nous avons vu une
**branche** se révéler être une chaîne de quarante caractères dans un fichier. Nous avons appris
qu'un nom, dans Git, est dérivé du contenu qu'il nomme, et que cette seule astuce achète d'un coup
l'intégrité, la déduplication et la comparaison bon marché.

Voici la récompense de ce travail : l'idée s'est échappée.

Le modèle de données de Git s'est révélé être une idée *générale*, et au cours des vingt dernières
années il est sorti de la gestion de version pour entrer dans des bases de données, des gestionnaires
de paquets, des registres de conteneurs, des caches de construction, des autorités de certification
et des éditeurs de texte collaboratifs. Dès que vous savez lire un **DAG de Merkle**, vous savez lire
les documents de conception d'une douzaine de systèmes qui n'ont rien à voir avec du code source, et
vous en reconnaîtrez le mobilier.

Voilà ce qu'est ce chapitre : une visite guidée du mobilier.

## Ce que Git a réellement inventé (et ce qu'il n'a pas inventé)

Soyons d'abord honnêtes, parce qu'un chapitre comme celui-ci peut facilement tourner à
l'hagiographie.

Git n'a pas inventé l'adressage par contenu. Ralph Merkle a décrit les arbres de hachage à la fin des
années 1970. Le **Venti** de Plan 9 était un magasin de blocs adressé par contenu — des blocs nommés
par le hachage de leurs octets — des années avant que Git n'existe. Et **Monotone** utilisait déjà des
hachages cryptographiques pour nommer des révisions quand Linus est parti chercher un remplaçant à
BitKeeper en avril 2005 ; son fameux message à la liste du noyau disait aux gens de ne pas se fatiguer
à lui parler de Subversion et d'aller plutôt « commencer à se documenter sur "monotone" ».

Git n'a pas non plus inventé la gestion de version distribuée. Monotone, Darcs, GNU Arch et Mercurial
étaient tous en vol au même moment.

Ce que Git a réussi, c'est la *combinaison*, et la combinaison est véritablement une réussite de
conception :

* un **DAG de Merkle d'instantanés immuables** — pas des diffs, pas des jeux de changements, des
  arbres entiers, chacun nommé par son hachage ;
* par-dessus, des **pointeurs mutables bon marché** — références, branches, étiquettes, **HEAD** —
  qui sont les seules choses du système autorisées à changer ;
* une conception où **la réplication est le cas normal**, pas un ajout, de sorte qu'aucune copie n'est
  privilégiée et qu'un `git clone` n'est que « donne-moi les objets que je n'ai pas » ;
* et une implémentation assez rapide pour que les gens supportent l'interface.

Cette dernière proposition travaille beaucoup. Laissez-moi dire la chose légèrement inconfortable : le
modèle de données de Git est magnifique, et l'interface en ligne de commande de Git est un accident
historique. `git checkout` qui fait cinq métiers sans rapport, l'index qui suinte dans un message
d'erreur sur trois, `--force-with-lease` — ce sont des tissus cicatriciels, pas de la conception.

Les systèmes de ce chapitre en sont, à de rarissimes exceptions près, la preuve exacte. Ils ont gardé
le modèle et jeté l'interface.

> :information_source:
> Quatre mots que nous réutiliserons sans cesse ci-dessous. L'**adressage par contenu** : le nom est
> un hachage du contenu. Le **journal immuable** : les objets ne sont jamais modifiés, seulement
> ajoutés. Les **pointeurs mutables** : de petites références nommées dans ce journal. Le **partage
> structurel** : deux versions qui s'accordent pour l'essentiel partagent physiquement les parties sur
> lesquelles elles s'accordent. Gardez ces quatre-là en main et le reste du chapitre est facile.

## Les bases de données qui ont emprunté le modèle

### Dolt

**Dolt** est l'expression la plus pure du « prenons le modèle de Git et emmenons-le ailleurs ». C'est
une base de données SQL — compatible avec le protocole réseau de MySQL, de sorte que les clients et
pilotes MySQL ordinaires s'y connectent sans savoir que quoi que ce soit sorte de l'ordinaire — dont
le stockage *est* un graphe de commits.

Vous ne commitez pas des fichiers. Vous commitez des lignes.

```console
dolt sql -q "update employees set salary = salary * 1.1 where team = 'infra'"
dolt diff
dolt commit -am "Annual raise for the infra team"
dolt checkout -b experiment
dolt merge main
```

Et parce que c'est une base de données, la gestion de version est interrogeable. `dolt_log` et
`dolt_diff` sont des tables système, donc « qui a changé cette ligne et pourquoi » est un `SELECT`,
pas un projet d'archéologie :

```console
dolt sql -q "select * from dolt_log limit 5"
dolt sql -q "select * from dolt_diff_employees where to_commit = 'HEAD'"
```

Les branches peuvent être adressées comme si c'étaient des bases distinctes, ce qui veut dire qu'un
environnement de prévisualisation peut être un nom de branche dans une chaîne de connexion.
**DoltHub** est la forge hébergée — le GitHub de ce monde, avec pull requests sur des données.

> :information_source:
> Dolt n'est pas un fork de MySQL et ne contient aucun code MySQL ; la compatibilité est
> réimplémentée. La même équipe livre **Doltgres** (le frère à la sauce Postgres, en bêta jusqu'en
> 2026 avec une 1.0 annoncée pour août 2026) et **DoltLite** (un remplaçant versionné de SQLite,
> embarquable). À la mi-2026, Dolt 2.0 est la version majeure courante, qui a ajouté le ramasse-miettes
> automatique et la compression du magasin d'objets — un problème que vous reconnaîtrez, parce que
> c'est `git gc`.

### Pourquoi les blobs de Git n'auraient pas marché : les arbres prolly

Voici l'idée la plus profonde de ce chapitre, et elle mérite qu'on ralentisse.

Supposez que vous fassiez naïvement du Git-pour-bases-de-données : stocker chaque table comme un gros
**blob** et bâtir un DAG de Merkle de ces blobs. Vous obtiendriez l'historique, et vous obtiendriez
l'intégrité. Vous obtiendriez aussi deux catastrophes.

D'abord, **les diffs coûteraient la taille de la table**. Changez une ligne dans une table de dix
millions de lignes et le hachage du blob change, donc la seule manière de savoir *ce qui* a changé est
de lire les deux versions de bout en bout. Git s'en tire parce que les fichiers source sont petits et
qu'il y en a beaucoup ; une table est un unique fichier énorme.

Ensuite, **vous n'auriez aucune recherche indexée**. Un `WHERE id = 42` dans un blob veut dire un
balayage.

Le remède classique au second problème est un **arbre B**, ce qu'utilisent toutes les bases SQL. Mais
un arbre B *dépend de son histoire* : sa forme interne dépend de l'ordre d'arrivée des écritures. Deux
arbres B contenant des données identiques peuvent avoir des structures internes complètement
différentes, donc ils ne peuvent ni partager du stockage ni être comparés à bon marché. Exactement les
deux propriétés dont nous avons besoin.

Un **arbre prolly** — « arbre B probabiliste », aussi décrit comme un arbre B adressé par contenu —
règle les deux d'un coup. C'est un arbre B dont les frontières de nœuds sont choisies par un hachage
glissant du contenu plutôt que par l'ordre d'insertion, et dont les nœuds sont nommés par le hachage
de leur contenu. Deux conséquences en découlent :

* **Il est indépendant de l'histoire.** Le même ensemble de lignes produit toujours le même arbre, et
  donc le même hachage racine, quel que soit l'ordre d'insertion. Ainsi les sous-arbres identiques
  entre deux versions sont littéralement le même nœud, partagé — du partage structurel, exactement
  comme Git partage un objet **arbre** inchangé entre deux commits.
* **Le diff coûte la taille de la différence, pas la taille des données.** Pour comparer deux
  versions, on parcourt les deux racines ; partout où les hachages des enfants sont égaux, on
  s'arrête, parce qu'un hachage égal veut dire un sous-arbre égal. Changer une ligne touche une
  feuille et les O(log n) nœuds au-dessus d'elle. Tout le reste se compare égal à la première
  vérification de hachage.

Et parce que c'est toujours un arbre B en dessous, les balayages de plages ordonnées et les recherches
indexées fonctionnent toujours à une vitesse d'arbre B, à peu près.

Voilà toute l'astuce : **l'adressage par contenu vous donne le diff bon marché, la forme d'arbre B
vous donne la requête, et l'indépendance vis-à-vis de l'histoire est ce qui permet aux deux de
coexister.** La documentation de Dolt situe le diff en O(d) où d est la taille du changement, contre
O(n) pour un arbre B.

> :information_source:
> Les arbres prolly n'ont pas été inventés par l'équipe de Dolt. Ils viennent de **Noms**, une
> « base de données versionnée, forkable et synchronisable » antérieure, due en grande partie aux
> mêmes gens. Noms lui-même est mort — le dépôt est archivé depuis 2021 — mais ses idées de stockage
> sont vivantes à l'intérieur de Dolt, et la documentation de Dolt le crédite explicitement. Un joli
> rappel que dans ce domaine les idées survivent aux produits.

### Où Dolt se situe réellement

Dolt publie ses propres chiffres sysbench et, depuis Dolt 2.0, prétend se situer dans le même quartier
que MySQL sur ce banc d'essai. Prenez cela pour ce que c'est : un banc d'essai synthétique
mono-branche, exécuté par l'éditeur.

Soyez réaliste. Chaque lecture doit traverser un arbre adressé par contenu, le moteur est jeune, et
l'écosystème opérationnel autour de lui — les topologies de réplication, les dix ans de folklore de
réglage, les gens qu'on peut embaucher et qui le connaissent déjà — n'a rien à voir avec celui de
Postgres ou de MySQL. Personne ne devrait déplacer une charge OLTP à fortes écritures dessus parce
qu'un chapitre d'un cours sur Git avait l'air enthousiaste.

Le point idéal, ce sont **les données que des humains curatent, relisent et doivent auditer** :
données de référence, tables de prix, configuration, taxonomies, jeux d'entraînement d'apprentissage
automatique, jeux de données publics. Partout où vous avez déjà voulu demander « qui a changé cette
ligne, quand, et qu'a dit le relecteur », Dolt répond à une vraie question à laquelle une base
ordinaire répond mal.

### Les voisins

Dès qu'on voit le motif, on le trouve partout dans le monde de la donnée, et chacun a emprunté un
morceau précis :

* **TerminusDB** — la même idée pour une base de documents-graphe / graphe de connaissances :
  brancher, comparer, fusionner et voyager dans le temps sur des documents structurés plutôt que sur
  des tables, avec des changements stockés comme des couches de deltas immuables. Une note d'état
  s'impose : l'intendance du projet libre est passée en 2025 à une société appelée DFRNT et il sort
  toujours des versions (12.0.4 en février 2026), mais ce projet a changé de mains et de direction
  produit plus d'une fois, alors vérifiez sa santé avant de bâtir dessus.
* **lakeFS** — du branchement, du commit et de la fusion façon Git par-dessus du stockage objet (S3
  et compagnie). L'idée empruntée est celle que vous connaissez déjà des **arbres de travail** : une
  branche est un *pointeur*, donc brancher un pétaoctet est une opération de métadonnées qui ne copie
  aucun objet. Des branches en O(1) sur un lac de données. Activement développé, et Treeverse — la
  société derrière — a racheté le projet DVC fin 2025.
* **Apache Iceberg** et **Delta Lake** — la même intuition, arrivée du côté des entrepôts de données
  plutôt que de Git. Une table est un journal immuable de fichiers de métadonnées pointant vers des
  fichiers de données immuables, donc le « voyage dans le temps » n'est que la lecture d'un pointeur
  de métadonnées plus ancien. Iceberg a des références nommées (étiquettes et branches) sur ses
  instantanés ; **Project Nessie** va plus loin et vous donne des branches et des commits à l'échelle
  du catalogue, transversaux aux tables, ce qui est ce qui ressemble le plus à un véritable dépôt dans
  cet écosystème.
* **Neon** et **PlanetScale** — le motif « branchez votre base pour chaque environnement de
  prévisualisation ». Neon (Postgres sans serveur, racheté par Databricks en 2025) fait du branchement
  de stockage en copie-sur-écriture ; PlanetScale branche des schémas et les fusionne avec des
  *deploy requests*, qui sont des pull requests pour du DDL. Ni l'un ni l'autre n'est un DAG de
  Merkle, et cela vaut la peine d'être précis : ce qu'ils ont emprunté n'est pas le modèle de
  stockage mais le modèle *social* — des copies isolées bon marché plus une étape de relecture avant
  la fusion.

Renvois : c'est le même territoire que
[Les arbres de travail](1-git-worktree.md "Les arbres de travail") et
[Git pour les données et les modèles](5-git-data-science.md "Git pour les données et les modèles"),
vus de l'autre côté.

## Les systèmes de gestion de version qui ont appris de Git et sont passés à autre chose

Un cours sur Git devrait être honnête là-dessus : Git n'est pas le dernier mot, et les successeurs
intéressants ne sont pas des jouets.

### Jujutsu

**Jujutsu** — la commande est `jj` — est celui qu'il faut réellement essayer. Il est écrit en Rust, il
est développé au grand jour sur `jj-vcs/jj`, et en juillet 2026 il en est à la version 0.43. Notez le
zéro de tête ; nous y venons dans un instant.

Le fait pratique décisif : **jj utilise un dépôt Git comme stockage dorsal.** Vous pouvez lancer
`jj git init` dans un dépôt que vous avez déjà, ou faire un `jj git clone` d'une URL, travailler dans
`jj`, et pousser vers le même dépôt distant GitHub ou Forgejo que tout le monde. Vos collègues ne le
découvrent jamais. Pas de migration, pas de conversion, pas d'engagement.

Trois choix de conception, chacun étant une réponse directe à quelque chose qui vous a déjà agacé dans
ce cours :

**La copie de travail est elle-même un commit.** Pas indexée, pas remisée — un vrai commit, que `jj`
amende automatiquement chaque fois que vous touchez un fichier. Il n'y a pas d'**index**, pas de zone
d'**indexation**, et rien de tel qu'un arbre sale. Tous ces états de `git status` que nous avons passé
un chapitre à démêler s'effondrent en « ce commit est celui que vous éditez ». Commiter n'est pas
« enregistre mon travail », c'est « commence à en décrire un nouveau ».

**Chaque opération est enregistrée dans un journal d'opérations.** `jj op log` vous montre chaque
mutation du dépôt — pas seulement les commits, mais les rebases, les déplacements de marque-pages, les
récupérations, tout — et `jj undo` en annule n'importe laquelle.

```console
jj op log
jj undo
```

Réfléchissez à ce que cela veut dire. `git reflog` ne vous dit que vers quoi pointaient les
références, et seulement pour des références ; se remettre d'un mauvais rebase est un travail de
reconstruction manuelle. Dans `jj`, c'est *tout l'état du dépôt* qui est une chose versionnée et
l'annulation tient en un mot. C'est la fonctionnalité qui convertit les gens le plus sûrement.

**Les conflits sont des objets de première classe stockés dans les commits.** Dans Git, un conflit est
un état cassé de votre arbre de travail que vous devez résoudre *tout de suite* avant que quoi que ce
soit d'autre puisse arriver — et c'est pourquoi un `git rebase` interrompu est une expérience si
misérable. Dans `jj`, un conflit est une donnée enregistrée *dans le commit*. Un rebase de vingt
commits ne s'arrête jamais à mi-parcours ; il se termine, et certains des commits obtenus sont marqués
comme contenant des conflits, que vous résolvez quand vous voulez, dans l'ordre que vous voulez.

> :warning:
> État honnête à la mi-2026. `jj` se dit encore expérimental, et la version 0.43 veut dire ce qu'elle
> dit : le projet a annoncé qu'il y aurait des changements de méthode de travail et des changements de
> format sur disque incompatibles avant la 1.0. La compatibilité Git est la partie stable et beaucoup
> de gens l'utilisent quotidiennement, mais : les hooks Git ne sont pas pris en charge,
> `.gitattributes` est ignoré, les sous-modules ne sont pas visibles dans la copie de travail, et les
> clones partiels ou superficiels et Git LFS ne fonctionnent pas. Préparez-vous aussi au vocabulaire :
> ce que Git appelle une branche, `jj` l'appelle un **marque-page**, emprunté à Mercurial.

### Pijul et la théorie des patchs

**Pijul** s'attaque à la chose la plus profonde de la liste : la fusion elle-même.

La fusion à trois points de Git est une *heuristique sur des instantanés*. Étant donné deux commits et
une base de fusion, elle devine. C'est une bonne devinette, et elle n'est pas associative — fusionner
A puis B peut donner un résultat différent de fusionner B puis A, et il existe des cas construits où
Git produit silencieusement un entrelacement faux sans signaler le moindre conflit.

Le modèle de Pijul est une **algèbre commutative de patchs**. Les changements sont des objets dotés
d'une véritable structure mathématique, les changements indépendants commutent, et les fusions sont
donc associatives : l'ordre dans lequel vous fusionnez ne change ni le résultat ni l'identifiant
obtenu. C'est une garantie véritablement plus forte que ce qu'offre Git, et cela rend largement inutile
le nettoyage d'historique façon rebase, parce qu'appliquer un changement dans un ordre différent n'est
pas une réécriture, c'est juste une application.

Son ancêtre est **Darcs**, qui avait eu la même idée en premier et s'était fait une réputation de
« fusion exponentielle » — des cas pathologiques où l'algorithme de fusion prenait pratiquement
l'éternité. Toute la prétention d'ingénierie de Pijul est une théorie saine qui tourne aussi vite.

Ne le survendez pas et ne laissez personne vous le vendre. En 2026 Pijul en est à une 1.0 bêta, il est
activement développé, il s'héberge sur sa propre forge (le Nest), et son écosystème est minuscule. Il
est sur cette liste parce que la théorie est belle et parce que c'est le seul projet ici qui accepte de
dire que la fusion de Git est *approximativement* juste plutôt que juste.

### Sapling

**Sapling** est le client de Meta, publié en logiciel libre en 2022 et toujours activement développé.
Filiation : Mercurial, pas Git — il est né d'années de rustines de Meta sur `hg` — mais il parle Git,
il clone depuis GitHub, et sa ligne de commande `sl` est l'interface préférée de beaucoup de gens dans
tout cet espace.

L'idée qu'il a empruntée, puis brisée : Git suppose que `clone` veut dire « télécharger tout ». À la
taille du dépôt de Meta, cette hypothèse est tout simplement fausse, alors Sapling récupère
paresseusement — un clone tire les branches principales, et les données de commits, d'arbres et de
fichiers arrivent à la demande, à mesure que vous les réclamez.

Soyons justes sur le contexte, cependant. Git a ressenti la même pression et y a répondu : clone
partiel, extraction creuse, index creux, `scalar`. Sapling existe parce que les réponses de Git sont
arrivées tard, pas parce que Git n'en avait pas.

### Fossil, qui n'est pas d'accord exprès

**Fossil** est sur cette liste précisément parce qu'il n'est *pas* inspiré de Git. C'est le système de
gestion de version de D. Richard Hipp — l'auteur de SQLite — et c'est un argumentaire délibéré contre
plusieurs des choix de Git.

Tout le dépôt est un **unique fichier SQLite**, que vous sauvegardez en le copiant. Il embarque le
wiki, les tickets, le forum, le chat et les notes techniques *dans le dépôt*, de sorte que l'histoire
du projet et la conversation du projet se répliquent ensemble au lieu que l'une vive dans Git et
l'autre dans le compte SaaS de quelqu'un. Et il refuse par principe de réécrire l'historique : il n'y
a pas de `rebase`, et la documentation de Fossil contient un long essai bien argumenté intitulé
« Rebase Considered Harmful » dont le point central est qu'un rebase est une fusion qui oublie
délibérément l'un de ses parents.

Vous n'êtes pas obligé d'être d'accord — ce cours vous a enseigné le rebase et vous a dit quand
l'utiliser. Mais l'argument est bon, il est fait en public, et Fossil est vivant (la 2.28.0 est sortie
en mars 2026). Lire les raisons soigneuses de quelqu'un pour rejeter un outil que vous utilisez vaut
bien une heure.

### Mercurial, équitablement

**Mercurial** est né à quelques semaines de Git en 2005, en résolvant le même problème, et de l'avis
de la plupart des gens avec une ligne de commande plus propre et plus cohérente. Il a perdu sur des
effets de réseau, pas sur ses mérites — GitHub est arrivé à Git.

Il n'est pas mort. Mercurial 7.2.1 est sorti en avril 2026, le projet a donné une conférence au FOSDEM
2026 intitulée à peu près « vingt ans et ça continue », et il reste sérieusement utilisé à certains
endroits. Il a aussi perdu son irréductible le plus visible : Mozilla a déplacé la source de vérité de
Firefox de Mercurial vers Git en 2025.

### Et Git ne cesse de reprendre

La concurrence a été bonne pour tout le monde, et il serait malhonnête de présenter Git comme
statique. Le clone partiel et l'extraction creuse répondent au problème d'échelle de Sapling. L'index
creux a rendu rapides les extractions énormes. `git rebase --update-refs` répond à la méthode de
travail en branches empilées autour de laquelle `jj` et Sapling sont bâtis. Le fichier `commit-graph`
a rendu le parcours de l'historique bon marché. Et **reftable**, un nouveau dorsal de références
introduit dans Git 2.45, mûri jusqu'à la 2.51 et destiné à devenir le format par défaut des nouveaux
dépôts dans Git 3.0, corrige enfin la conception « une branche est un fichier dans un répertoire » que
nous avons regardée de nos propres yeux dans
[Jouer avec nos révisions](../1-understanding-git/7-play-with-git-revisions.md "Jouer avec nos révisions").

## Le DAG de Merkle hors de la gestion de version

Maintenant la partie amusante : la même primitive, résolvant des problèmes qui n'ont rien à voir avec
du code source.

### Nix et Guix : l'adressage par contenu pour les constructions

**Nix** et **Guix** appliquent l'idée aux *constructions*. Chaque paquet vit à un chemin comme :

```console
/nix/store/9pmvd4xn1kb0lbz3q0z7iv1hrp4z8g6j-hello-2.12.1
```

Ce hachage n'est pas décoratif. C'est l'identité du paquet, et — pour un paquet Nix normal — il est
dérivé d'un hachage de *toutes les entrées de la construction* : la source, le compilateur, les
options, les dépendances, transitivement. Changez une entrée et vous obtenez un chemin différent. Deux
constructions aux mêmes entrées sont le même chemin et peuvent être partagées.

C'est la règle de Git — « le nom est dérivé du contenu » — déplacée du contenu des fichiers vers les
graphes de construction. Et cela achète les mêmes choses : la déduplication, un cache qui ne peut
jamais être périmé (une entrée périmée aurait un nom différent), et le retour arrière atomique, parce
qu'une « génération » Nix est un ensemble de pointeurs dans un magasin immuable, si bien que revenir
en arrière sur tout votre système consiste à repointer un lien symbolique. Un pointeur mutable dans un
journal immuable. Nous avons déjà vu cela.

> :information_source:
> Une précision, puisque nous avons été soigneux avec ce mot : les chemins standard du magasin Nix
> sont adressés par leurs *entrées*, pas par leur contenu — le hachage est celui de la recette, pas
> des octets de sortie. Des sorties véritablement adressées par contenu existent dans Nix mais sont
> encore derrière une option expérimentale (`ca-derivations`). La différence compte pour les
> arguments de reproductibilité et presque pas du tout pour l'analogie.

### Docker et les images OCI

Ouvrez le manifeste d'une image de conteneur et vous trouverez quelque chose d'extrêmement familier :
une liste de couches, chacune nommée par une empreinte, plus un **blob** de configuration, également
nommé par une empreinte. Le manifeste lui-même a une empreinte. C'est un arbre de Merkle, et
`docker pull` est un `git fetch` — « envoie-moi les objets qui me manquent, par hachage ». Le partage
de couches entre images est du partage structurel, exactement comme Git partage un objet **arbre**
entre deux commits.

Et voici où le monde OCI est *pire* que Git, d'une manière qui, désormais, vous équipe pour être
agacé : **les étiquettes sont mutables**. `ubuntu:latest` aujourd'hui et `ubuntu:latest` demain sont
des images différentes portant le même nom. C'est l'anti-**SHA**.

C'est pourquoi les déploiements sérieux épinglent par empreinte :

```console
docker pull ubuntu@sha256:<empreinte>
```

C'est précisément la leçon que vous avez déjà apprise sur les branches contre les
**identifiants de commit**. Une étiquette ou un nom de branche vous dit *où quelqu'un pointe en ce
moment* ; seul le hachage vous dit *ce que vous obtenez*. Tout pipeline d'intégration continue mature
finit par redécouvrir cela à la dure.

### IPFS, et BitTorrent avant lui

**IPFS** est l'adressage par contenu promu au rang de protocole réseau. Le contenu reçoit un **CID**,
et vous demandez le CID au réseau plutôt que de demander un chemin à un serveur particulier. Son
format de DAG (IPLD, et la disposition unixfs pour les fichiers) est assez proche des arbres-et-blobs
de Git pour en être troublant, et il existe un codec IPLD pour les objets Git (`go-ipld-git`, toujours
maintenu), de sorte que les objets Git peuvent être adressés nativement dans le graphe d'IPFS. C'est
un recoin de niche plutôt qu'une fonctionnalité grand public, mais le fait que cela *s'ajuste* vous
dit à quel point les deux modèles de données sont semblables.

La note honnête : l'adressage par contenu résout l'intégrité et la déduplication. Il ne résout pas la
**disponibilité** ni la **découverte** — un hachage vous dit ce que vous voulez, pas qui l'a, et si
personne ne l'a, le hachage n'est qu'une manière très fiable d'être déçu. Cet écart est la source de
l'essentiel des difficultés pratiques d'IPFS.

**BitTorrent** y était arrivé avant que Git ne sorte, et mérite une ligne pour la filiation : un
torrent est essentiellement une liste de hachages sur des morceaux de taille fixe, et c'est exactement
*pourquoi* les morceaux peuvent arriver dans n'importe quel ordre, de n'importe qui, par n'importe
quel chemin, et s'assembler quand même en le bon fichier. Vérifiez chaque morceau contre son hachage
et vous n'avez plus besoin de faire confiance à l'expéditeur. La même astuce, en 2001.

### Les journaux de transparence, les signatures, et pourquoi Git n'est pas une chaîne de blocs

La **Certificate Transparency** (RFC 6962, désormais RFC 9162) est un arbre de Merkle en ajout seul de
chaque certificat TLS qu'un journal a vu. Parce que c'est un arbre de Merkle, vous pouvez prouver à
bon marché qu'un certificat est *dans* le journal, et qu'une version plus récente du journal est un
sur-ensemble strict d'une plus ancienne — si bien qu'un journal qui essaie de montrer des choses
différentes à des gens différents se fait prendre. Les navigateurs exigent que les certificats soient
journalisés. Le Rekor de **Sigstore** fait la même chose pour les signatures logicielles ; les
attestations **in-toto** décrivent la provenance des constructions ; la base de sommes de contrôle des
modules de Go est encore la même structure, et c'est ce que `go.sum` vérifie réellement.

Puis il y a les **chaînes de blocs**, qui sont aussi des structures en ajout seul chaînées par
hachage, et c'est là que nous devrions dire quelque chose de net, parce que les gens le disent sans
cesse et que c'est faux :

**Git n'est pas une chaîne de blocs.** Il n'a ni mécanisme de consensus ni preuve de travail.
Quiconque a le droit de pousser peut réécrire l'historique et le pousser en force, et les hachages
seront parfaitement valides — ce seront simplement les hachages d'un *autre* historique. Ce que les
hachages de Git garantissent, c'est qu'**un historique donné n'a pas été silencieusement altéré** : si
vous tenez un **identifiant de commit** d'une source digne de confiance, tout ce qui en est
atteignable est épinglé. Ce qu'ils ne garantissent pas, c'est que ce soit *l'*historique, parce que
rien dans Git ne décide quel historique est canonique. C'est un fait social, stocké dans une référence
mutable sur un serveur que quelqu'un contrôle.

C'est exactement pourquoi les **commits signés et les étiquettes signées** existent. Une signature lie
un hachage précis à une clé précise, et une chaîne de commits signés veut dire « cette personne
affirme cet arbre exact et cette ascendance exacte ». Il vaut la peine d'être clair sur les limites :
une signature prouve qui a affirmé un commit, pas que le code est bon, pas que la branche que vous
avez récupérée est à jour, et pas que le signataire n'était pas compromis. C'est une déclaration forte
sur la *provenance* et rien de plus. La clé SSH que vous avez mise en place dans
[Configurer Git avec une clé SSH](../6-appendices/2-git-ssh.md "Configurer Git avec une clé SSH")
peut faire double emploi ici — un Git moderne sait signer avec des clés SSH, pas seulement avec GPG.

```console
git log --show-signature -1
git verify-commit HEAD
```

### Les CRDT et le logiciel local-first

Voici une question que tout utilisateur de Git finit par poser : pourquoi Git ne peut-il pas fusionner
mon document comme le fait Google Docs, en direct, sans conflits ?

Parce que la fusion de Git est **par lot** et **générale**. Elle s'exécute quand vous le demandez, sur
des octets arbitraires, et quand deux personnes ont édité les mêmes lignes elle n'a aucune idée du
sens voulu, alors elle s'arrête et demande à un humain. C'est le comportement correct pour du code
source.

Les **CRDT** — types de données répliqués sans conflit — obtiennent une fusion automatique et totale
en *contraignant les types de données*. Si votre texte est une séquence CRDT plutôt qu'un tableau
d'octets, les éditions concurrentes ont une combinaison définie et déterministe, toujours, sans humain
dans la boucle. **Automerge** et **Yjs** sont les deux que vous rencontrerez en pratique, et ils font
tourner l'essentiel du mouvement du logiciel « local-first » : des applications qui fonctionnent hors
ligne, se synchronisent de pair à pair, et ne vous montrent jamais de fenêtre de conflit.

Le compromis est précis et mérite d'être intériorisé : **les CRDT garantissent la convergence, pas la
correction.** Tout le monde se retrouve avec le même document ; personne ne promet que ce document ait
un sens. Deux personnes éditant la même signature de fonction convergeront vers quelque chose de
syntaxiquement valide et sémantiquement absurde. C'est le même marché que vous passez quand vous tapez
`-X theirs` sur une fusion — « prends-en juste une, je veux que ça se termine » — sauf qu'il est
passé systématiquement, à l'avance, pour chaque conflit.

Et les entrailles d'Automerge vous sembleront familières : un changement est identifié par le hachage
SHA-256 de ses octets, les changements référencent leurs prédécesseurs, et le résultat est un DAG de
changements chaîné par hachage que la documentation elle-même compare aux commits Git. Même l'évasion
hors du modèle de fusion de Git a gardé le modèle de stockage de Git.

### L'adressage par contenu comme cache de construction

**Unison** (le langage, pas le synchroniseur de fichiers) va le plus loin : une définition Unison est
identifiée par le hachage de son arbre syntaxique, et le code est stocké dans une base de données sous
ce hachage plutôt que dans des fichiers texte. Les noms ne sont que des métadonnées pointant vers des
hachages. Les conséquences sont stupéfiantes — renommer est instantané et ne peut rien casser, deux
versions d'une dépendance peuvent coexister parce que ce sont simplement des hachages différents, et
il n'y a pas de construction, parce qu'un artefact compilé indexé par le hachage de son entrée ne peut
jamais être périmé.

La même intuition, moins radicalement, est la façon dont fonctionnent **Bazel** et **Buck** : la clé
de cache d'une action est un hachage de ses entrées, de sa ligne de commande et de son environnement,
si bien qu'un cache partagé par toute une organisation d'ingénierie est sûr. L'invalidation de cache,
fameusement l'un des deux problèmes difficiles, cesse pour l'essentiel d'être un problème quand le nom
*est* le contenu.

### Git utilisé délibérément comme base de données

Enfin, les systèmes qui n'ont pas emprunté les idées de Git — ils ont emprunté Git.

* **git-bug** stocke les tickets comme des objets dans leurs propres références, de sorte que votre
  gestionnaire de bogues se clone, se branche et fonctionne hors ligne comme le code. Activement
  développé et étonnamment agréable.
* **Gerrit** garde tout son jeu de données de relecture dans le dépôt Git — NoteDb, avec les
  métadonnées de changements sous `refs/changes/*/meta` et les données de relecture dans des
  références de notes — ce qui est la même astuce que [git notes](3-git-notes.md "git notes"),
  industrialisée.
* **GitHub** et compagnie publient les pull requests comme des références sous `refs/pull/*`, et c'est
  pourquoi vous pouvez récupérer une PR à laquelle vous n'avez aucun autre accès.
* **Argo CD** et **Flux** traitent un dépôt Git comme l'état désiré d'un cluster et réconcilient
  continuellement la réalité avec lui — tout le sujet de [GitOps](../5-automation/1-git-ops.md "GitOps").
* **Radicle** bâtit une forge pair-à-pair par-dessus Git : dépôts, tickets et patchs se répliquent
  entre pairs sans serveur au milieu. Sa génération de protocole actuelle s'appelle Heartwood et en
  est à la 1.9.x à la mi-2026 — un vrai projet, quoique petit.
* **libgit2** et **gitoxide** sont des implémentations réutilisables de Git (en C et en Rust) qui
  existent pour que vous puissiez bâtir des choses comme celles ci-dessus sans passer par le shell et
  la commande `git`. `jj` utilise gitoxide pour son dorsal Git.

## Ce qu'il faut en retenir

Quatre leçons transférables, et elles valent plus que la liste des noms :

**Dérivez les noms du contenu et vous obtenez gratuitement l'intégrité, la déduplication et
l'invalidation de cache.** Pas « à bon marché » — gratuitement, comme effet de bord. Si le nom est le
hachage, un objet corrompu est détectable, un objet identique n'est stocké qu'une fois, et une entrée
de cache ne peut jamais être périmée, parce qu'une entrée modifiée porte un nom différent.

**Séparez un journal immuable de pointeurs mutables vers lui et vous obtenez gratuitement
l'historique, le branchement et le retour arrière.** Git, les générations Nix, une branche lakeFS, une
référence d'instantané Iceberg, une étiquette Docker : la même forme. Tout ce qui est intéressant est
immuable ; tout ce qui est mutable est minuscule.

**Le partage structurel rend bon marché le « copier le monde entier ».** C'est pourquoi une branche
coûte 41 octets, un **arbre de travail** ne coûte presque rien, un retour arrière Nix est instantané,
brancher un pétaoctet dans lakeFS est une écriture de métadonnées, et cent conteneurs partagent une
seule couche de base. Dès que les versions partagent physiquement leurs parties inchangées, le coût
d'une nouvelle version est la taille du changement.

**Le difficile n'est jamais le stockage. C'est la fusion.** Chaque système de ce chapitre a
essentiellement la même réponse de stockage et une réponse *différente* à « que se passe-t-il quand
deux personnes ont changé la même chose ». Git devine avec une fusion à trois points et demande à un
humain quand il n'y arrive pas. Dolt fusionne des lignes et détecte les violations de contraintes.
Pijul prouve que ses fusions commutent. `jj` stocke le conflit et vous laisse continuer. Les CRDT
convergent par construction et acceptent l'absurde. Fossil refuse de vous laisser faire comme si la
divergence n'avait jamais eu lieu. C'est dans cette question que vit la conception.

Vous comprenez maintenant assez bien la plomberie de Git pour lire les documents de conception de
n'importe lequel de ces projets — et vous y trouverez, page après page, que vous en connaissez déjà le
vocabulaire. Hachage. Objet immuable. Référence. Instantané. Base de fusion. Partage structurel. Allez
lire la page du moteur de stockage de Dolt, ou les documents de conception de jj, ou la spécification
des images OCI. Vous n'y êtes plus un touriste.

## Récapitulatif — les idées et les systèmes qui les ont empruntées

* L'**adressage par contenu** — le nom est un hachage du contenu. Antérieur à Git (Merkle, années
  1970 ; le Venti de Plan 9 ; Monotone, que Linus a crédité).
* **DAG de Merkle + références bon marché + réplication par défaut** — la véritable contribution de
  Git est la combinaison, pas une pièce isolée.
* **Dolt** — le graphe de commits de Git comme base SQL compatible MySQL ; `dolt_log` et `dolt_diff`
  comme tables système interrogeables ; les **arbres prolly** pour le partage structurel *et* les
  requêtes indexées *et* des diffs en O(changement). Frères et sœurs : Doltgres (Postgres, bêta),
  DoltLite (SQLite).
* **Noms** — là où les arbres prolly ont été inventés. Archivé depuis 2021 ; les idées ont survécu
  dans Dolt.
* **TerminusDB** — brancher/comparer/fusionner pour une base de documents-graphe. Vivant mais il a
  changé de mains ; vérifiez sa santé d'abord.
* **lakeFS** — brancher un pétaoctet en O(1) en ne copiant que des métadonnées. La même intuition
  qu'un **arbre de travail**.
* **Iceberg / Delta Lake / Nessie** — un journal de métadonnées immuable pointant vers des fichiers de
  données immuables ; le voyage dans le temps et le branchement arrivant du côté de l'entrepôt.
* **Neon / PlanetScale** — des copies de bases isolées et bon marché, plus une étape de relecture avant
  la fusion. Ils ont emprunté le modèle social, pas le modèle de stockage.
* **Jujutsu (`jj`)** — adossé à Git, donc adoptable dès aujourd'hui. La copie de travail *est* un
  commit (pas d'**index**), un journal d'opérations avec un `jj undo` universel, des conflits comme
  objets de première classe de sorte que les rebases ne s'arrêtent jamais à mi-parcours. Toujours
  pré-1.0 en 2026.
* **Pijul** — la fusion comme algèbre commutative de patchs, donc des fusions associatives. Le
  descendant de Darcs. Bêta, écosystème minuscule, théorie magnifique.
* **Sapling** — le client compatible Git de Meta, de la lignée Mercurial ; récupération paresseuse de
  l'historique pour des dépôts trop gros pour un `clone`-tout.
* **Fossil** — délibérément non-Git : un unique fichier SQLite, le wiki, les tickets et le forum dans
  le dépôt, pas de rebase par principe.
* **Mercurial** — le contemporain de Git, avec sans doute une meilleure interface, perdant sur des
  effets de réseau ; sort toujours des versions en 2026.
* **Git lui-même** — clone partiel, index creux, `--update-refs`, commit-graph, reftable. La
  concurrence nous a fait du bien.
* **Nix / Guix** — l'adressage par contenu (enfin, par entrées) pour les *constructions* ;
  `/nix/store/<hachage>-nom` est un magasin de blobs, et une génération est un pointeur mutable dans
  un magasin immuable.
* **Docker / OCI** — des couches et des manifestes nommés par empreinte ; `pull` est une récupération
  des objets manquants. Les étiquettes mutables sont l'anti-**SHA** — épinglez par empreinte.
* **IPFS** — l'adressage par contenu comme protocole réseau ; un format de DAG proche des
  arbres-et-blobs. Résout l'intégrité et la déduplication, pas la disponibilité ni la découverte.
* **BitTorrent** — une liste de hachages est la raison pour laquelle les morceaux peuvent arriver dans
  n'importe quel ordre, de n'importe qui. 2001.
* **Certificate Transparency / Sigstore / la base de sommes de contrôle de Go** — des journaux de
  Merkle en ajout seul pour détecter les altérations.
* **Les chaînes de blocs** — également chaînées par hachage, mais Git n'en est *pas* une : pas de
  consensus, pas de preuve de travail. Les hachages prouvent qu'un historique donné n'a pas été
  silencieusement altéré, pas qu'il soit *l'*historique. D'où les commits et les étiquettes signés.
* **Les CRDT (Automerge, Yjs)** — une fusion automatique et totale obtenue en contraignant les types
  de données. La convergence, pas la correction — le même marché que `-X theirs`.
* **Unison / Bazel / Buck** — l'adressage par contenu comme base du cache de construction. Quand le
  nom est le contenu, l'invalidation de cache cesse d'être un problème.
* **git-bug, le NoteDb de Gerrit, `refs/pull/*`, Argo CD, Flux, Radicle, libgit2, gitoxide** — Git
  utilisé délibérément comme base de données, ou réimplémenté pour que vous puissiez le faire.
