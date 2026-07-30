---
title: Sauvegardons notre travail !
slug: "save-work-with-git"
weight: 4
---
# Sauvegardons notre travail !

Nous avons pris le parti de tout faire très, mais très lentement, en vous expliquant chaque étape du chemin. Mais on vous a aussi promis de la simplicité. Donc… imaginons qu'on ait un projet qui n'est pas encore sous contrôle de Git (appelons-le `my_existing_project`) et qui contient nos fichiers de code source. Comment les mettre sous contrôle Git simplement et rapidement ?

Rien de plus simple :
```console
cd ~/projects/my_existing_project
git init
git add .
git commit -m'First commit'
```
1. On change le répertoire courant dans notre projet.
2. On initialise le dépôt avec `git init`
3. `git add` dit à git d'ajouter tous les fichiers du répertoire courant, y compris ceux qui sont dans des sous-répertoires (avec le `.` après la commande).
4. Puis on **commit** avec un message.

Mais nous avons promis du détail, donc revenons à notre projet initial, qui est simplement un dépôt Git vide, et tentons de comprendre plus en profondeur ce qui s'est passé. Donc si vous êtes parti ailleurs, revenons à :

```console
cd ~/projects/my_first_git_project
```
## Suivre les modifications d'un fichier : `git add`

Nous allons maintenant créer un premier fichier. Vous pouvez utiliser votre éditeur de texte favori. Ici, je ne vais même pas utiliser un éditeur : je vais créer directement le fichier et son contenu en utilisant la commande `printf`, qui affiche du texte que je vais rediriger (en utilisant `>`) vers un fichier que l'on va nommer `readme.md`.

```console
printf '# My first Git project\n' > readme.md
```

> :information_source:
> Vous verrez très souvent `echo "..."` utilisé à la place. Nous employons délibérément `printf`, parce que `printf` se comporte de la même manière partout : `echo "a\nb"` transforme ce `\n` en un véritable retour à la ligne dans zsh et dash, mais affiche littéralement les deux caractères `\n` dans bash. Un cours écrit avec `echo` donnerait des fichiers différents à des lecteurs différents. `printf` interprète toujours les échappements — et ce `\n` final est ce qui donne à notre fichier son retour à la ligne de fin.

> :information_source:
> Le fichier que nous venons de créer est un fichier texte dans un format appelé _Markdown_. Le « # » à son début indique que cette ligne est un titre. Vous pouvez en apprendre plus sur https://www.markdownguide.org/getting-started/. C'est une très bonne pratique de toujours créer un fichier nommé `readme.md` à la racine de son dépôt Git, qui va décrire le contenu du dépôt. On va y revenir.

On va tout de suite apprendre une deuxième commande Git. Elle non plus n'a pas besoin d'argument (mais elle peut en prendre, bien entendu) :

```console
git status
```
qui va répondre :

```console
On branch master

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	readme.md

nothing added to commit but untracked files present (use "git add" to track)
```

`git status`, commande fort utile, nous permet à tout moment de savoir, comme son nom l'indique, quel est le statut de notre travail avec Git. Avec le temps, nous allons apprendre à comprendre ses retours, mais pour le moment attardons-nous sur ces trois lignes :

```console
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	readme.md
```

Git est donc déjà au courant que l'on a créé un fichier. Mais il nous dit : « dans votre répertoire de travail, il y a un fichier que je ne connais pas vraiment. Si vous voulez que j'en suive l'évolution, il faut me le dire ». Dans sa grande gentillesse, il nous indique même le chemin à suivre : `git add <file>..`. Retenez les termes anglais : **tracked** (suivi) et **untracked** (non suivi).

Faisons ce qu'il nous dit. On va expliquer juste après.

```console
git add readme.md
```

S'il n'y a pas d'erreur, Git ne va rien nous dire. Mais il a bien fait quelque chose.

## Le répertoire de travail

Cette commande ne sauvegarde pas encore le fichier. Elle dit simplement à Git : « à partir de maintenant, tu dois suivre ce fichier et ses modifications, puis enregistrer son état actuel quelque part pour que je puisse sauvegarder cet état ». Plus tard, quand on aura fait notre premier `commit`, c'est cet état qui sera pris en compte.

Retenez le terme anglais : le **staging**, c'est l'action de préparer quelque chose pour sa prochaine étape. Dans notre cas, ajouter un fichier à l'index prépare le commit. Le terme vient de la logistique ; en français on dirait « aire de rassemblement » ou « zone de transit », là où les troupes se préparent, ou la partie de l'entrepôt où l'on met les paquets avant leur acheminement. En anglais on l'utilise aussi souvent comme un verbe : « to stage a file », qui est équivalent à « to add a file to the index ».

> :information_source:
> Nous pouvons donc imaginer le travail avec Git comme le passage de nos fichiers entre trois zones :
> 1. La zone de travail, notre répertoire courant, le répertoire de travail : son contenu est ce que l'on voit dans le navigateur de fichiers. C'est là que nous modifions nos fichiers.
> 2. La zone de transit — l'index, autrement appelé **staging** : les fichiers tels qu'ils sont préparés pour être sauvegardés, enregistrés dans une version (ou révision) spécifique. On a là des « instantanés » de nos fichiers.
> 3. La zone de commit — le travail validé, là où les choses sont enregistrées pour la postérité : des choses que l'on peut donc aussi partager avec d'autres, envoyer vers d'autres.

{{< mermaid >}}
graph LR
  W["Répertoire de travail<br/>les fichiers que vous éditez"]
  I["Index<br/>le prochain commit,<br/>en cours d'assemblage"]
  R["Dépôt<br/>.git, validé<br/>pour la postérité"]

  W -->|"git add"| I
  I -->|"git commit"| R
  R -->|"git checkout"| W
{{< /mermaid >}}

Remarquez que les flèches font le tour. Rien n'est jamais *sorti* du dépôt par le fait de committer ; `git checkout` recopie un état sauvegardé dans le répertoire de travail, et c'est pour cela que le dernier chapitre de cette partie pourra remettre en place votre travail supprimé.

## Regarder à l'intérieur de `.git`

Mais comprenons d'abord ce qui s'est passé, plus en détail. On va jeter un coup d'œil dans les entrailles du monstre. Ce que l'on va voir n'est pas nécessaire pour l'utilisation courante de Git, mais taper des commandes sans comprendre ce qu'elles font va assez rapidement vous bloquer. Donc, un peu de souffrance maintenant pour beaucoup de gloire plus loin. Qu'est-ce qu'on trouve dans le répertoire `.git` ?

Tapons joyeusement une jolie commande :

```console
tree -C .git
```

> :information_source:
> La commande `tree` est un peu comme `ls`, mais elle nous montre la structure des répertoires et des fichiers qu'ils contiennent ; nous avons ajouté l'option `-C` pour que le rendu soit colorié, nous montrant la différence entre fichiers et répertoires. Elle pourrait ne pas être installée sur votre système ; dans ce cas un `ls -lRa` (on reconnaît ici le `ls -la`, le `R` est pour Récursif) peut suffire.

```console
.git
├── config
├── description
├── HEAD
├── hooks
│   ├── applypatch-msg.sample
│   ├── commit-msg.sample
│   ├── fsmonitor-watchman.sample
│   ├── post-update.sample
│   ├── pre-applypatch.sample
│   ├── pre-commit.sample
│   ├── pre-merge-commit.sample
│   ├── pre-push.sample
│   ├── pre-rebase.sample
│   ├── pre-receive.sample
│   ├── prepare-commit-msg.sample
│   ├── push-to-checkout.sample
│   ├── sendemail-validate.sample
│   └── update.sample
├── index
├── info
│   └── exclude
├── objects
│   ├── 38
│   │   └── 36229b5ce7fd362c59974d286de92bf5191784
│   ├── info
│   └── pack
└── refs
    ├── heads
    └── tags

10 directories, 20 files
```

> :information_source:
> Cette liste de fichiers `hooks/*.sample` grandit et rétrécit d'une version de Git à l'autre (ici c'est Git 2.51) ; si la vôtre est un peu différente, il n'y a rien d'anormal. Les **hooks** sont des scripts que Git peut exécuter automatiquement à certains moments — nous ne les utiliserons pas dans ce cours, et tant qu'ils se terminent par `.sample`, Git les ignore complètement.

Nous allons pour le moment ignorer le reste et nous attarder uniquement sur une partie :

```console
.git
├── index
├── objects
│   ├── 38
│   │   └── 36229b5ce7fd362c59974d286de92bf5191784
```

On a ici un fichier très important, `index`. Et une structure de répertoires de la forme : `objects/<deux lettres>/<nom-de-fichier-de-38-lettres>`.

L'**index**, le fichier `.git/index`, c'est la zone de **staging**. C'est un fichier binaire qui contient une entrée par chemin qui composera notre prochain **commit** : le chemin, son mode de fichier, et le hash du contenu qui a été mis en attente pour lui (plus un cache d'informations du système de fichiers pour que Git puisse déterminer rapidement si un fichier a changé sur le disque). C'est une liste de courses pour le prochain commit — pas une base de données de notre historique.

La base de données, c'est `.git/objects`. C'est là que vit le contenu réel : le contenu des fichiers que nous avons ajoutés à l'index, et plus tard les **commit**s et les **tree**s eux-mêmes. Notre `readme.md` a été mis dans une forme compressée dans `objects/38/36229b5ce7fd362c59974d286de92bf5191784`.

> :information_source:
> Ce nom de fichier bizarre n'est pas aléatoire, c'est un **SHA**. Git a utilisé ce que l'on nomme « une fonction de hachage » basée sur le contenu du fichier. En gros, une fonction de hachage nous permet de prendre un contenu, peu importe sa taille, et de produire en sortie une chaîne de caractères de taille fixe (dans notre cas 40 caractères ; ici les deux premiers caractères sont utilisés pour le nom du répertoire et 38 pour le nom du fichier).
> Changer un seul caractère dans le contenu change complètement la chaîne générée. On parle alors d'un « adressage par le contenu ». Quand le contenu change, le nom de fichier (d'où « adresse ») change.
> Et partout dans Git, ou presque, nos identifiants vont prendre cette forme. On va parler de **commit**, de **commit-id**, de **tree** et de **tree-id**, de **blob**s, et tout cela prendra toujours une forme comme celle-ci : `3836229b5ce7fd362c59974d286de92bf5191784`. Pour rendre la chose un tout petit peu plus lisible, le plus souvent on ne va pas utiliser les 40 caractères mais uniquement les 7 premiers. Ainsi, pour parler de `3836229b5ce7fd362c59974d286de92bf5191784`, on parlera plutôt de `3836229`, mais ça identifie bien la même chose.

> :information_source:
> **Votre `readme.md` devrait vraiment être `3836229...` lui aussi.** Un **blob** est haché à partir de son contenu et de rien d'autre, donc si vous avez tapé le même `printf`, vous avez obtenu les mêmes 40 caractères. Mais à partir de la section suivante, quand nous commencerons à vous montrer des hashes de **commit**, les vôtres *seront* différents de ceux imprimés ici — et ce n'est pas une erreur. Un commit contient votre nom, votre adresse e-mail et la seconde exacte à laquelle vous l'avez fait ; deux personnes ne peuvent donc pas produire le même commit-id pour le « même » commit. Lisez les hashes de ce cours comme des illustrations : la forme est réelle, les chiffres sont les miens.

> :information_source:
> La fonction de hachage est **SHA-1**, et c'est toujours celle par défaut. Deux notes de bas de page valent la peine d'être connues. D'abord, depuis Git 2.13, le SHA-1 qu'utilise Git est une version *durcie* : elle détecte l'attaque par collision connue sur SHA-1 et refuse l'objet plutôt que de se laisser tromper. Ensuite, depuis Git 2.29, vous pouvez créer un dépôt dont les noms d'objets sont en SHA-256, avec `git init --object-format=sha256`. L'interopérabilité entre les deux sortes de dépôts est encore incomplète, si bien qu'en pratique quasiment tous les dépôts que vous toucherez un jour — y compris tous les dépôts sur GitHub ou GitLab — sont en SHA-1. Nous dirons « 40 caractères » et nous voudrons dire SHA-1 pour le reste de ce cours.

Alors, où se trouve le contenu de ce même fichier, du point de vue de Git, à cet instant ? À trois endroits, et il vaut la peine d'être précis à leur sujet, parce que c'est exactement la chose que les débutants comprennent de travers :

* Dans le **répertoire de travail**, ce sont juste des octets sur le disque. Git ne les a pas hachés et ne les surveille pas ; il ne regarde que lorsque vous le lui demandez.
* Dans l'**index**, il y a une entrée pour `readme.md`, et elle nomme le **blob** que nous avons mis en attente — `3836229`.
* Dans le **commit** que nous allons faire, le **tree** nommera le blob qui a été validé.

Ces trois-là peuvent être d'accord ou en désaccord, et `git status` est la commande qui vous dit lequel. (Pendant un conflit de fusion, et seulement alors, un seul chemin peut avoir jusqu'à trois entrées à la fois dans l'index — les « stages ». Nous les rencontrerons quand nous fusionnerons.)

> :warning:
> Beaucoup de malentendus sur Git viennent d'une mécompréhension de cette relation entre le **staging**, le fait de préparer notre **commit**, notre sauvegarde d'étape, et le **commit** lui-même. C'est pour cela que nous nous y attardons. Donc prenez le temps de comprendre.

En tout cas, nous sommes prêts ! Enfin. Nous avons créé un fichier et nous l'avons ajouté à l'index.

Si nous lançons `git status` à nouveau, il nous dira :
```console
On branch master

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
	new file:   readme.md

```

Ça y est, Git est prêt pour nous.

## Sauvegarder un point d'étape : `git commit`

Dans le terminal, tapons :

```console
git commit -m"Added readme.md"
```

Normalement Git nous répondra avec :

```console
[master (root-commit) d2eafda] Added readme.md
 1 file changed, 1 insertion(+)
 create mode 100644 readme.md
```

Voilà. C'est fait ! Nous avons sauvegardé un point d'étape. Vous pouvez taper `git status`.

Notre **commit**. À tout jamais, à partir de maintenant, dans la vie de notre projet, nous pourrons revenir dans le passé, savoir quel était le contenu du fichier à ce moment-là, et nous saurons aussi qui a fait quel changement… et **pourquoi**.

> :information_source:
> Nous avons vu que, quand nous avons tapé la commande `git add`, elle a créé le fichier dans une forme comprimée dans son répertoire `.git/objects/` et lui a donné un nom basé sur le contenu. Donc on a perdu le nom du fichier ! N'ayez pas peur. Dans `.git/objects`, on a deux autres types d'objets qui vont nous permettre de retrouver notre nom de fichier : `tree` et `commit`.

Analysons juste un peu ce que l'on a fait… et puis rentrons dans le détail de ce que Git, lui, a fait. En effet, la commande `commit`, comme la commande `add`, ne change pas seulement l'index : elle crée aussi de nouveaux objets dans `.git/objects`.

Donc `git commit`, c'est la commande qui sauvegarde, et là on voit pour la première fois une option qui vaut la peine d'être bien apprise : le `-m`. Elle indique le **message de commit** : l'intention de notre changement. C'est incroyablement utile quand on travaille seul (« mais pourquoi grands dieux ai-je fait cela ! ah… oui… ») mais c'est encore plus important quand on travaille avec d'autres.

Le message lui-même n'est pas optionnel. Si vous omettez `-m`, Git ouvre votre éditeur de texte et attend que vous en tapiez un — et si vous enregistrez un message vide, il annule le commit et rien n'est enregistré. Git ne vous laissera pas sauvegarder du travail anonyme.

> :information_source:
> Si Git vous largue un jour dans un éditeur que vous ne reconnaissez pas, c'est probablement `vi` : tapez `:q!` puis entrée pour en sortir sans committer. Vous pouvez choisir le vôtre avec `git config --global core.editor nano` (ou `code --wait`, ou ce que vous utilisez réellement). Cela surprend énormément de gens, exactement une fois.

> :warning:
> En tant que quelqu'un qui recrute pas mal de développeurs, sachez que quand je regarde le code des candidats, je regarde les messages de commit autant que je regarde le code lui-même.

## Sauvegarder un deuxième changement puis un troisième

On est sur une lancée, donc continuons ! Faisons un deuxième changement. Ouvrez notre `readme.md` avec votre éditeur de texte préféré et ajoutons par exemple :

```markdown
# My first Git project

Today we learned the following Git commands:

1. `git init` - initialize a new git repository
2. `git status` - find out the status of the working directory relative to the git repository
3. `git add` - add files to the git index to prepare for a commit
4. `git commit -m"{commit message}"` - save a milestone in the git repository
```

Après avoir sauvegardé le fichier, si nous tapons `git status` à nouveau, nous aurons un message un peu différent.

```console
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   readme.md

no changes added to commit (use "git add" and/or "git commit -a")
```

Super. Git est au courant que le fichier a été modifié… et il nous donne même des indications sur l'étape suivante. On y va !

De nouveau :

```console
git add readme.md
```

Puis :

```console
git commit -m"Add the list of commands we learned today."
```

Qui nous répond par :

```console
[master 46079d2] Add the list of commands we learned today.
 1 file changed, 7 insertions(+)
```

> :information_source:
> Astuce 1 : si cela vous fatigue de taper chaque fois `add` puis `commit`, on a un raccourci : `git commit -am"mon message de commit"`. L'option `-a` ajoutée ici dit **all**… Git va ajouter au commit tous les fichiers suivis dans l'index qui auront été modifiés. Par contre, si un fichier n'a pas encore été ajouté une première fois, il est **untracked**, et `-a` ne fera rien pour celui-là.
> Astuce 2 : si vous avez plein de fichiers dans le répertoire et que vous n'avez pas envie de les ajouter un par un, vous pouvez les ajouter tous d'un coup avec `git add .` — mais attention, souvent on a des fichiers qui traînent et que l'on ne veut pas forcément dans son dépôt. On verra ça plus tard.

Pour l'exercice, créons maintenant un deuxième fichier. Mettons dans notre dépôt un fichier de licence qui va expliquer aux gens qui pourront y avoir accès ce qu'ils peuvent faire, et ce qu'ils ne peuvent pas faire, avec. Celui-ci fait huit lignes, donc plutôt que de nous battre avec les guillemets et les échappements, nous allons utiliser un **heredoc** : tout ce qui se trouve entre `<<'EOF'` et le `EOF` de fermeture part dans le fichier, exactement tel qu'il est tapé.

```console
cat > LICENSE <<'EOF'
Git Example by Ori Pekelman

To the extent possible under law, the person who associated CC0 with
Git Example has waived all copyright and related or neighboring rights
to Git Example.

You should have received a copy of the CC0 legalcode along with this
work. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
EOF

git add LICENSE
git commit -m"Adding a license file"
```

Ce qui nous donne :

```console
[master 5ab2cae] Adding a license file
 1 file changed, 8 insertions(+)
 create mode 100644 LICENSE
```


## Récapitulatif : `git init`, `git add` et `git commit`

* `git init` — créer un nouveau dépôt Git, vide.
* `git add` — ajouter un fichier de notre zone de travail à l'index
* `git commit` — valider et sauvegarder les fichiers tels qu'ils ont été ajoutés à l'index
* `git status` — pour voir où on en est. Le fichier a-t-il été ajouté à l'index ? A-t-il été modifié depuis qu'il a été validé ?


Nous sommes maintenant les heureux propriétaires d'un dépôt Git avec deux fichiers et trois **commits**. Voyons comment cela se présente, à l'intérieur de Git. Au chapitre suivant !
