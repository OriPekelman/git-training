---
title: Les gros fichiers, ou comment Git rencontre ses limites
slug: "git-lfs"
weight: 34
---
# Les gros fichiers, ou comment Git rencontre ses limites

Tôt ou tard, quelqu'un vous tend un dépôt contenant une vidéo de 400 Mo, ou un graphiste vous demande
où mettre les fichiers `.psd`, ou vous rejoignez une équipe d'apprentissage automatique et découvrez
que leur « petit » dépôt met quarante minutes à se cloner.

Ce chapitre porte là-dessus. Et nous le ferons dans l'ordre qui enseigne réellement quelque chose :
**d'abord** nous montrons, à partir du modèle d'objets que vous connaissez déjà, *pourquoi* Git est
mauvais avec les gros fichiers. **Ensuite** nous présentons Git LFS pour ce qu'il est vraiment — un
contournement astucieux boulonné sur le flanc de Git, avec de vrais coûts.

Si vous ne lisez qu'une phrase de ce chapitre : le meilleur remède à un problème de gros fichier est
en général de ne pas commiter le gros fichier.

> :information_source:
> Tout ce qui est mesuré ici l'a été pour de vrai, avec Git 2.51 et git-lfs 3.7.0. Vos chiffres
> différeront à la dernière décimale, pas dans leur forme. Mes dépôts de brouillon ont
> `init.defaultBranch = main`, et c'est pourquoi la sortie dit `main`.

## Pourquoi Git peine

### Chaque version de chaque fichier est stockée en entier

Souvenez-vous d'[Au cœur du dépôt, au cœur du commit](../1-understanding-git/5-inside-git.md "Au cœur du dépôt, au cœur du commit") :
un **commit** pointe vers un **arbre**, un **arbre** liste des **blobs**, et un **blob** est *le
contenu entier d'une version d'un fichier*. Git ne stocke pas de diffs. Il stocke des instantanés.

Alors faisons l'expérience cruelle. Un fichier de 20 Mio de bruit purement aléatoire, commité cinq
fois, regénéré de zéro à chaque fois — ce qui est exactement ce qui se passe quand on réentraîne un
modèle ou qu'on réexporte une vidéo.

```console
git init big-and-random && cd big-and-random
for i in 1 2 3 4 5; do
  head -c 20971520 /dev/urandom > model.bin
  git add model.bin && git commit -q -m "model v$i"
  echo "after commit $i: $(du -sh .git | cut -f1)"
done

after commit 1:  20M
after commit 2:  40M
after commit 3:  60M
after commit 4:  80M
after commit 5: 100M
```

Parfaitement, déprimantement linéaire. Maintenant interrogeons Git lui-même, avec la commande qui
donne la comptabilité honnête de la taille d'un dépôt :

```console
git count-objects -vH

count: 15
size: 100.08 MiB
in-pack: 0
packs: 0
size-pack: 0 bytes
```

Quinze objets épars — cinq blobs, cinq arbres, cinq commits — pour 100 Mio. Et maintenant la partie
où les gens espèrent être sauvés :

```console
git gc
git count-objects -vH

count: 0
size: 0 bytes
in-pack: 15
packs: 1
size-pack: 100.03 MiB
```

L'empaquetage nous a économisé cinquante kilooctets. L'arbre de travail fait 20 Mio. Le dépôt fait
100 Mio. Pour toujours.

### Mais soyons justes : la compression par delta n'est pas inutile

Je mentirais en m'arrêtant là. Le format **packfile** stocke *bel et bien* les objets comme des
deltas contre des objets similaires, et cela fonctionne aussi sur des données binaires — c'est un
delta au niveau de l'octet, pas de la ligne. Regardez ce qui se passe quand le fichier est réellement
*constitué pour l'essentiel des mêmes octets* : un fichier de 20 Mio dont 4 Kio sont rapiécés au
milieu à chaque fois.

```console
head -c 20971520 /dev/urandom > data.bin
git add data.bin && git commit -q -m "data v1"
for i in 2 3 4 5; do
  dd if=/dev/urandom of=data.bin bs=4096 seek=$((i*100)) count=1 conv=notrunc status=none
  git add data.bin && git commit -q -m "data v$i"
done

git count-objects -vH | grep size:
size: 100.08 MiB            # épars : cinq copies complètes

git gc && git count-objects -vH | grep size-pack
size-pack: 20.03 MiB        # empaqueté : une copie plus quatre deltas minuscules
```

100 Mio d'objets épars s'effondrent à **20,03 Mio**. La compression par delta a magnifiquement fait
son travail. La vraie règle n'est donc pas « Git est mauvais avec les binaires » :

> :information_source:
> Git fabrique de bons deltas quand les versions successives **partagent de longues plages d'octets
> identiques**, et de très mauvais quand un petit changement logique perturbe tout le fichier. Lequel
> des deux se produit est décidé par le *format de fichier*, pas par Git.

### C'est le format qui vous tue

Voici l'expérience qui fait bien le point. La même information et le même minuscule changement — une
ligne réécrite près du haut d'un CSV de 13 Mo — commitée cinq fois. Une fois en CSV brut, une fois en
`gzip -9` de ce même CSV exact.

| dépôt | charge utile | objets épars | après `git gc` |
|---|---|---|---|
| CSV brut | 13,6 Mo | 27,83 Mio | **4,79 Mio** |
| CSV gzippé | 5,0 Mo | 23,55 Mio | **23,54 Mio** |

Lisez ce tableau deux fois. Les *plus petits* fichiers ont produit le *plus gros* dépôt. Parce que la
sortie de gzip est un long flux codé par entropie, changer l'octet 100 change tous les octets qui
suivent, et le chercheur de deltas de Git n'a plus rien à quoi se raccrocher. Cinq versions, cinq
copies complètes.

C'est précisément la situation d'un JPEG réenregistré, d'un `.zip`, d'un `.docx` (qui est un zip),
d'un fichier Parquet, d'un point de contrôle `.safetensors` issu d'un nouvel entraînement. Les octets
ne ressemblent en rien à leur prédécesseur alors même que le contenu a à peine bougé.

### Parce que Git est distribué, tout le monde paie

C'est ce qui fait des gros fichiers un problème *social* plutôt que personnel. `git clone` ne
récupère pas l'état courant ; il récupère **tout l'historique**, parce que c'est ce que veut dire être
distribué. Un actif de 200 Mo modifié cinquante fois, c'est un clone de 10 Go pour chaque collègue,
sur chaque portable, dans chaque travail d'intégration continue, pour toujours. Notre dépôt de
100 Mio se clone en 120,1 Mio sur disque pour un fichier de travail de 20 Mio.

Et voici le fait le plus cruel : **vous ne pouvez pas corriger cela en supprimant le fichier.**
L'historique est immuable. `git rm` ajoute un commit dans lequel le fichier est absent ; les cinquante
vieux blobs restent exactement où ils étaient. Retirer un gros fichier arrête l'hémorragie, cela ne
guérit pas la plaie. Le seul remède est de réécrire l'historique, ce qui veut dire que tout le monde
reclone — voir
[Garder un historique propre, se remettre de ses erreurs](../2-collaborating/6-git-cleanup.md "Garder un historique propre, se remettre de ses erreurs").

### Le diff et la fusion cessent de vouloir dire quoi que ce soit

```console
git merge alice

warning: Cannot merge binary files: asset.bin (HEAD vs. alice)
Auto-merging asset.bin
CONFLICT (content): Merge conflict in asset.bin
Automatic merge failed; fix conflicts and then commit the result.
```

Et toute votre boîte à outils de résolution de conflits se réduit désormais à ces deux commandes :

```console
git checkout --ours asset.bin      # garder le mien, jeter la journée de travail d'Alice
git checkout --theirs asset.bin    # garder celui d'Alice, jeter le mien
```

Il n'y a pas de troisième option. C'est *pourquoi* les équipes qui vivent d'actifs binaires finissent
par vouloir du verrouillage de fichiers, que nous abordons plus bas.

### Et les humiliations plus petites

* `git status` devient lent sur d'énormes arbres, parce que Git appelle `stat` sur chaque chemin
  suivi. `core.fsmonitor` et `core.untrackedCache` aident beaucoup ; `scalar` (dans Git depuis la
  2.38) les active pour vous, avec le clone partiel et l'entretien en arrière-plan.
* `git gc` et `git repack` peuvent réclamer beaucoup de mémoire, parce que la recherche de deltas
  garde des objets en RAM. Les boutons sont `pack.windowMemory` et `core.bigFileThreshold` (512 Mio
  par défaut — au-dessus, Git cesse même d'essayer de faire des deltas).
* Les forges refusent. Sur GitHub, les fichiers de plus de **50 Mio** méritent un avertissement, ceux
  de plus de **100 Mio** sont **bloqués purement et simplement**, et le formulaire de téléversement
  web s'arrête à **25 Mio**. Sa recommandation est de rester sous 1 Go par dépôt idéalement, sous
  5 Go « fortement recommandé » — pendant que sa page *Repository limits* énonce un plafond de 10 Go
  et une limite de push de 2 Go, en Mo plutôt qu'en Mio. Deux pages GitHub, deux jeux d'unités :
  consultez la documentation actuelle plutôt que de faire confiance à la mémoire de quiconque, y
  compris la mienne. GitLab.com plafonne les push à 5 Gio et les dépôts du niveau gratuit à 10 Go.

### Découvrir ce que vous avez déjà

Avant d'aller plus loin : cette ligne unique vous dit la vérité sur n'importe quel dépôt dont vous
héritez. Elle parcourt tous les objets atteignables depuis toutes les références et trie les blobs par
taille.

```console
git rev-list --objects --all \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
  | awk '$1=="blob" {printf "%.1f MiB  %s  %s\n", $3/1048576, substr($2,1,10), $4}' \
  | sort -rn | head -20

20.0 MiB  e54bc46278  model.bin
20.0 MiB  c81cf4b0df  model.bin
20.0 MiB  afcff9ef22  model.bin
```

Remplacez `%(objectsize)` par `%(objectsize:disk)` pour voir ce que chacun coûte *après* empaquetage,
qui est le chiffre qui compte vraiment.

## Ce qu'il faut faire avant de se saisir de LFS

Neuf problèmes de gros fichiers sur dix ne sont pas des problèmes de gros fichiers. Ce sont des
problèmes de discipline.

**Ne commitez pas d'artefacts générés.** `dist/`, `node_modules/`, `target/`, `*.o`, le PDF compilé,
la vidéo exportée, `__pycache__`. Si une commande peut le produire à partir de choses déjà dans le
dépôt, le dépôt ne devrait pas le contenir. Mettez-le dans le `.gitignore` et passez à autre chose.
Cette seule règle résout la plupart des cas.

**Commitez une URL et une somme de contrôle plutôt que les octets.** Un fichier de trois lignes est
une parfaitement bonne représentation d'un jeu de données de 4 Go :

```yaml
url: https://storage.example.com/datasets/imagenet-subset-2026-03.tar.zst
sha256: 4a7d1ed414474e4033ac29ccb8653d9b1a0e7d1e1e0a9f5a0e2b3c4d5e6f7a8b
size: 4183928832
```

Votre cible `make data` le télécharge, vérifie le hachage, et refuse de continuer s'il ne correspond
pas. Le commit épingle un **hachage de contenu immuable**, qui est la seule propriété qui compte
vraiment pour la reproductibilité. Plus là-dessus dans
[Git pour les données et les modèles](5-git-data-science.md "Git pour les données et les modèles") —
c'est gravement sous-estimé.

**Le clone partiel plus le sparse-checkout, pour les gros arbres de *sources*.** Voilà la réponse
moderne et véritablement bonne, et elle vit dans Git lui-même. Vous avez rencontré `--filter` parmi
les autres options de clone ; voici ce qu'il fait à notre monstre de 100 Mio :

```console
git clone --filter=blob:none --no-checkout file:///path/to/big-and-random partial
git -C partial count-objects -vH | grep size-pack

size-pack: 2.28 KiB
```

Deux kilooctets et quart. Nous avons récupéré tous les commits et tous les arbres et *aucun contenu
de fichier*. Puis :

```console
git -C partial checkout main
git -C partial count-objects -vH | grep size-pack

size-pack: 20.01 MiB
```

Git a paresseusement récupéré exactement l'unique blob dont l'extraction avait besoin. 20 Mio au lieu
de 100 Mio, et cela passe à l'échelle comme vous le voulez : un coût proportionnel à ce que vous
regardez, pas à ce qui a jamais existé. Ajoutez `git sparse-checkout set src/ docs/` et vous ne
récupérez même pas le reste de l'arbre. (Le serveur doit l'autoriser :
`uploadpack.allowFilter = true`. Toutes les grandes forges le font.)

**Des clones superficiels pour l'intégration continue.** `git clone --depth 1` a donné 20,01 Mio pour
le même dépôt. L'intégration continue n'a presque jamais besoin de l'historique. Souvenez-vous
simplement qu'un clone superficiel est estropié — pas de `git log` utile, pas de `git describe`, pas
de base de fusion — alors utilisez-le pour les travaux de construction, pas pour les travaux de mise
en production.

## Git LFS, mécaniquement

Bien. Vous avez fait le travail de discipline et vous avez véritablement besoin d'actifs binaires
versionnés de 300 Mo dans le dépôt. C'est là que LFS gagne son salaire.

L'idée en une phrase : **garder un minuscule fichier texte dans Git, garder les vrais octets
ailleurs, et les échanger automatiquement à l'entrée et à la sortie de l'arbre de travail.**

### L'installer écrit des filtres dans votre configuration

```console
git lfs version
git-lfs/3.7.0 (GitHub; darwin arm64; go 1.24.4)

git lfs install
Git LFS initialized.
```

Qu'est-ce que cela a *fait*, au juste ? Cela a édité votre `.gitconfig` global :

```ini
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
```

Voilà tout le mécanisme, et c'est un mécanisme que Git avait déjà. Pas de magie nulle part. Si vous
préférez ne pas toucher à votre configuration globale, `git lfs install --local` écrit le même bloc
dans le `.git/config` d'un dépôt ; il y a aussi `--worktree`, `--system` et `--skip-smudge`.

Cela dépose aussi quatre hooks dans `.git/hooks` : `pre-push`, `post-checkout`, `post-commit`,
`post-merge`. Chacun fait trois lignes qui vérifient que `git-lfs` est dans votre `PATH` puis
l'appellent. Rien que vous n'auriez pu écrire vous-même.

### Le suivi écrit `.gitattributes`

```console
git lfs track "*.bin"
Tracking "*.bin"

cat .gitattributes
*.bin filter=lfs diff=lfs merge=lfs -text
```

Nous avons rencontré `.gitattributes` dans
[Un peu de structure SVP](../2-collaborating/4-git-repo-structure.md "Un peu de structure SVP").
Quatre attributs, chacun faisant un travail :

* `filter=lfs` — exécuter la paire clean/smudge définie plus haut. C'est celui qui porte tout.
* `diff=lfs` — utiliser le pilote de diff de LFS, pour que `git diff` affiche l'oid et la taille du
  pointeur au lieu de vomir 300 Mo de binaire dans votre terminal.
* `merge=lfs` — utiliser le pilote de fusion de LFS. Lequel, soyons clairs, ne sait toujours pas
  fusionner deux JPEG. Il échoue simplement poliment.
* `-text` — ne jamais faire de conversion de fin de ligne sur ces octets. Une « correction » CRLF
  appliquée à un binaire est une corruption de données.

> :warning:
> `.gitattributes` **doit être commité**. S'il n'est pas dans le dépôt, le Git de vos collègues n'a
> aucune idée que ces chemins sont spéciaux et ils commiteront des blobs de 300 Mo droit dans
> l'historique. Le suivi est aussi par motif et ne s'applique qu'aux fichiers ajoutés *après*
> l'existence du motif — les fichiers déjà dans l'historique ne sont pas convertis rétroactivement.
> Cela demande `migrate`, à la fin de ce chapitre.

### Le fichier pointeur est toute l'astuce

Commitons un vrai fichier de 20 Mio et regardons sous le capot.

```console
head -c 20971520 /dev/urandom > weights.bin
git add weights.bin
git lfs status

On branch main

Objects to be committed:

	weights.bin (LFS: a45b7e8)
```

```console
git commit -m "Add weights.bin (20 MiB)"
git show HEAD:weights.bin

version https://git-lfs.github.com/spec/v1
oid sha256:a45b7e8d31e52c3ec69393e8c939a00b7a6731fad511a587a2b6659195cccb8f
size 20971520
```

*Voilà* ce que Git a stocké. Trois lignes de texte. Confirmons-le avec les outils les plus bas
niveau dont nous disposons :

```console
git cat-file -t $(git rev-parse HEAD:weights.bin)
blob
git cat-file -s $(git rev-parse HEAD:weights.bin)
133

git count-objects -vH | head -2
count: 9
size: 36.00 KiB
```

Un **blob** de 133 octets, et trente-six kilooctets pour *toute* la base de données d'objets — ce
petit dépôt a aussi un readme et trois commits — là où l'actif fait 20 Mio. Le format du pointeur est
spécifié : `version` toujours en premier, les clés restantes triées par ordre alphabétique, un
`{clé} {valeur}` par ligne, le tout sous les 1024 octets. Il existe exactement un encodage valide
d'un pointeur donné, et c'est ce qui permet à `git add` d'être déterministe.

L'`oid` est un SHA-256 du contenu, et c'est le lien d'intégrité : Git garantit le pointeur, le
pointeur garantit les octets. Mais notez bien — les octets ne sont **pas** dans le packfile et ne
font **pas** partie du graphe d'objets que `git fsck` vérifie. Votre dépôt peut être parfaitement
intact pendant que les données réelles se sont évaporées.

### Clean et smudge : vous auriez pu construire ceci

`clean` s'exécute au `git add` : le fichier entre sur l'entrée standard, le pointeur sort sur la
sortie standard, les vrais octets sont rangés dans un magasin local. `smudge` s'exécute à
l'extraction : le pointeur entre, les vrais octets sortent. LFS n'a pas inventé cela ; il a
généralisé `filter.*.clean` / `filter.*.smudge`, que Git a depuis des années, et il a ajouté
`filter-process` — un protocole longue durée pour qu'un seul processus traite tout un `git add` au
lieu d'en bifurquer un par fichier.

Ne me croyez pas sur parole. Voici un Git LFS fonctionnel, en trente lignes. Le côté clean :

```console
#!/bin/sh
tmp=$(mktemp); cat > "$tmp"
oid=$(shasum -a 256 "$tmp" | cut -d' ' -f1)
mkdir -p "$STORE"; cp "$tmp" "$STORE/$oid"
printf 'poorman-lfs sha256:%s size:%s\n' "$oid" "$(wc -c < "$tmp" | tr -d ' ')"
rm -f "$tmp"
```

Le côté smudge relit cette unique ligne, retire le préfixe `sha256:` et fait un `cat` de
`$STORE/$oid`. Branchons-les :

```console
git config filter.poorman.clean  "STORE=$STORE $PWD/bin/poor-clean"
git config filter.poorman.smudge "STORE=$STORE $PWD/bin/poor-smudge"
git config filter.poorman.required true
echo '*.blob filter=poorman -text' > .gitattributes

head -c 5242880 /dev/urandom > big.blob
git add . && git commit -q -m "Poor man's LFS"
git show HEAD:big.blob
poorman-lfs sha256:67f6e2c80ab9f51e74ee476dd56c1bc5e169b751efff1f2d31a2c7bb315c6746 size:5242880

rm big.blob && git checkout -- big.blob && shasum -a 256 big.blob
67f6e2c80ab9f51e74ee476dd56c1bc5e169b751efff1f2d31a2c7bb315c6746  big.blob
```

Un blob de 97 octets pour un fichier de 5 Mio, et l'aller-retour est identique octet pour octet. Ce
que le vrai LFS ajoute, ce sont les ennuyeux et difficiles quatre-vingt-quinze pour cent : un
protocole de transfert, de l'authentification, de la concurrence, la reprise, le verrouillage,
`migrate`. Mais vous savez désormais que LFS n'est pas une modification de Git. C'est une
*application* de Git.

### Le cache local, et pourquoi vous avez maintenant trois copies

```console
find .git/lfs -type f
.git/lfs/objects/a4/5b/a45b7e8d31e52c3ec69393e8c939a00b7a6731fad511a587a2b6659195cccb8f

shasum -a 256 weights.bin
a45b7e8d31e52c3ec69393e8c939a00b7a6731fad511a587a2b6659195cccb8f  weights.bin
```

Adressé par contenu, éclaté selon les deux premiers puis les deux suivants chiffres hexadécimaux de
l'oid — la même astuce que `.git/objects`, un niveau plus profond. Et ce fichier en cache *est* la
donnée, donc sur le disque en ce moment :

```console
du -sh .git/objects .git/lfs weights.bin

 36K	.git/objects       # le pointeur de 133 octets, plus les arbres et les commits
 20M	.git/lfs           # le cache LFS
 20M	weights.bin        # l'arbre de travail
```

**Deux copies complètes plus un pointeur.** LFS ne rend pas les gros fichiers petits localement ; il
rend l'*historique* petit à distance. Budgétez votre disque en conséquence, et faites connaissance
avec `git lfs prune`.

### Le protocole de transfert, en résumé

Au `git push`, le hook `pre-push` lance `git lfs pre-push`, qui parle un protocole entièrement
distinct à un service entièrement distinct : une **API batch** HTTP (« voici quarante oids,
dites-moi lesquels vous manquent et où les mettre »), avec sa propre authentification, contre son
propre stockage. Le push de Git lui-même se déroule indépendamment, sur le transport que vous avez
configuré.

Une nuance que j'ai vérifiée : avec git-lfs 3.x, un simple dépôt nu sur un **chemin de système de
fichiers local** fonctionne, via l'adaptateur de transfert intégré `lfs-standalone-file`, qui se
contente de copier les objets dans `<nu>/lfs/objects/`.

```console
git init --bare bare-plain.git
git remote add origin /path/to/bare-plain.git
git push -u origin main

Uploading LFS objects: 100% (1/1), 0 B | 0 B/s, done.
 * [new branch]      main -> main
```

En **ssh ou https**, en revanche, le bout d'en face doit implémenter quelque chose : soit l'API batch
HTTP (GitHub, GitLab, Bitbucket, Gitea/Forgejo le font tous), soit le protocole `git-lfs-transfer`
purement SSH ajouté dans git-lfs 3.0, qui exige git-lfs installé côté serveur. Un dépôt nu servi par
un simple `git-receive-pack` en ssh ne fera pas l'affaire.

### Les commandes à connaître

```console
git lfs ls-files [-l -s]   # quels chemins de HEAD sont gérés par LFS (oids complets, tailles)
git lfs status             # comme git status, mais conscient de LFS
git lfs env                # tous les réglages, résolus — à lire quand on est perdu
git lfs track              # lister les motifs actifs
git lfs untrack "*.psd"    # retirer un motif de .gitattributes
git lfs fetch [--all|--recent]   # télécharger des objets, sans extraction
git lfs pull               # fetch + extraction
git lfs checkout           # transformer les pointeurs de l'arbre de travail en vrais fichiers
git lfs prune              # supprimer les objets du cache local qui sont anciens et poussés
```

`git lfs prune` est ce dont vous vous saisissez quand le portable se remplit. Il est conservateur par
conception : il garde ce dont l'extraction courante a besoin, ce dont chaque remise a besoin, ce dont
les branches récentes ont besoin (`lfs.fetchrecentrefsdays`, 7 par défaut, plus
`lfs.pruneoffsetdays`, 3 par défaut) et — crucialement — tout ce qui n'a **pas encore été poussé**,
parce que pour ceux-là votre copie locale est la seule copie. Il ne consulte *pas* le reflog, donc
les objets atteignables seulement depuis des commits orphelins sont toujours supprimés. Lancez
`git lfs prune --dry-run --verbose` d'abord.

### Récupérer moins

C'est là que LFS devient véritablement bon, et c'est la récompense de toute cette plomberie.

```console
GIT_LFS_SKIP_SMUDGE=1 git clone https://example.com/assets.git
```

Le même clone, sans smudge : des fichiers pointeurs dans votre arbre de travail et pas un octet de
données d'actifs. Sur le dépôt migré que nous construisons plus bas, c'est la différence entre 40 Mio
et **196 Kio**. Puis `git lfs pull` quand et si vous voulez les données.
`git lfs install --skip-smudge` en fait le défaut partout.

```console
git config lfs.fetchexclude "raw/**,archive/**"
git config lfs.fetchinclude "models/current/**"
git config lfs.concurrenttransfers 16
```

Des filtres de chemins séparés par des virgules, très utiles en intégration continue où le travail a
besoin de trois fichiers sur quatre cents.

> :warning:
> LFS et le clone partiel `--filter=blob:none` sont deux réponses à la même question et ils ne se
> connaissent pas officiellement. Les combiner n'est pas documenté, et il existe un bogue ouvert de
> longue date où `git lfs prune` échoue purement et simplement dans un clone partiel
> (`Prune error: missing object`). Choisissez-en un.

### Le verrouillage, qui est la vraie raison pour laquelle les studios de jeu utilisent LFS

Si deux personnes ne peuvent pas fusionner un fichier, la seule règle praticable est que deux
personnes ne doivent pas l'éditer en même temps. LFS implémente des verrous indicatifs :

```console
git lfs track --lockable "*.psd"
cat .gitattributes
*.psd filter=lfs diff=lfs merge=lfs -text lockable
```

`lockable` rend le fichier **en lecture seule dans l'arbre de travail tant que vous ne l'avez pas
verrouillé** — une manière délicieusement physique de dire « demande d'abord ».

```console
git lfs lock game/levels/boss.umap
git lfs locks
git lfs unlock game/levels/boss.umap
```

Cela demande une prise en charge côté serveur, et là les forges diffèrent véritablement. GitLab
implémente l'API de verrouillage, tout comme Gitea, Forgejo et Codeberg. Bitbucket Cloud documente
qu'il ne le fait pas. GitHub ne l'implémente pas non plus — vous obtenez
`Remote 'origin' does not support the LFS locking API` — bien que GitHub le documente surtout par
omission, alors vérifiez avant de bâtir une méthode de travail là-dessus.

### Migrer un dépôt existant

Le suivi n'affecte que l'avenir. Pour réellement faire rétrécir un dépôt, il faut **réécrire
l'historique**, et `git lfs migrate` est l'outil. Regardez avant de sauter :

```console
git lfs migrate info --everything

Sorting commits: ..., done.
Examining commits: 100% (5/5), done.
*.bin	105 MB	5/5 files	100%
```

`--above=50mb` restreint le rapport aux fichiers individuellement gros et `--top=20` élargit la
liste. (En mode `import`, `--above` fonctionne aussi, mais il ne peut pas être combiné à `--include`
ou `--exclude` — c'est l'option « prends simplement tout ce qui est gros, quoi que ce soit ». ) Puis :

```console
git lfs migrate import --everything --include="*.bin"

Sorting commits: ..., done.
Rewriting commits: 100% (5/5), done.
Updating refs: ..., done.
Checkout: ..., done.
```

`--everything` veut dire « toutes les références locales et distantes » — c'est l'option que vous
voulez. Il n'existe rien de tel que `--include-ref=--all` ; `--include-ref` prend un nom de référence
à la fois, comme dans `--include-ref=refs/heads/main`. Également utiles : `--exclude`, `--fixup`
(déduire les motifs d'un `.gitattributes` existant), `--object-map` (un CSV des identifiants de
commits anciens→nouveaux, inestimable pour rattraper les gestionnaires de tickets) et `--no-rewrite`,
qui convertit des fichiers dans un *nouveau* commit sans toucher du tout à l'historique.

> :warning:
> `migrate import` réécrit chaque commit. Chaque **SHA** change. C'est la règle « ne jamais réécrire
> un historique partagé » avec le volume poussé à fond : coordonnez-le, annoncez-le, faites recloner
> tout le monde. `migrate export` va dans l'autre sens — des pointeurs vers de vrais blobs — et c'est
> tout autant une réécriture.

Et maintenant la partie honnête, que personne ne vous dit. Immédiatement après la migration :

```console
git count-objects -vH | grep size-pack
size-pack: 100.04 MiB
```

Rien n'a rétréci ! Les anciens blobs sont toujours atteignables depuis le reflog. Il faut finir le
travail :

```console
git reflog expire --expire-unreachable=now --all
git gc --prune=now
git count-objects -vH | grep size-pack

size-pack: 3.28 KiB
```

*Voilà* qui est mieux. De 100,03 Mio de packfile à **3,28 Kio**. `.git/objects` fait 20 Ko.
`.git/lfs` détient toujours 100 Mio, parce que c'est votre cache local de vos propres données — mais
un clone tout neuf du résultat poussé fait 40 Mio avec extraction, et 196 Kio avec
`GIT_LFS_SKIP_SMUDGE=1`.

## Les réserves, sans détour

Adoptez LFS en sachant tout cela, plutôt que de le découvrir au quatrième mois.

**Ce n'est pas Git.** Programme distinct, protocole distinct, stockage distinct, authentification
distincte. Ce qui veut dire que la belle propriété sur laquelle vous vous êtes appuyé pendant tout ce
cours — qu'un clone est une copie complète et indépendante — a disparu. `git clone --mirror` ne vous
sauvegarde plus ; il vous faut aussi `git lfs fetch --all`. Votre plan de reprise après sinistre vient
de gagner une seconde pièce mobile.

**Cela coûte de l'argent, au compteur.** GitHub a remplacé ses anciens forfaits de données prépayés
par une facturation au compteur : le stockage en Gio-mois, la bande passante par Gio téléchargé,
facturés au *propriétaire du dépôt* plutôt qu'à qui clone. Les allocations incluses sont, à l'heure
où nous écrivons, de l'ordre de 10 Gio de chaque sur Free/Pro et de 250 Gio sur Team/Enterprise
Cloud, avec des maxima par fichier de 2 Go (Free/Pro) à 5 Go (Enterprise Cloud). Ces chiffres
bougent — consultez la page de facturation actuelle. Notez le mode de défaillance : sans moyen de
paiement enregistré, dépasser l'allocation **bloque LFS pour le reste du mois**, et plus personne ne
peut cloner.

**L'adopter sur un dépôt existant ne fait rien rétrécir** tant que vous ne réécrivez pas
l'historique, comme nous venons de le mesurer. Et **quitter** LFS est aussi une réécriture.

**Les contributeurs sans git-lfs reçoivent du n'importe quoi.** Un vrai clone depuis une machine sans
git-lfs configuré :

```console
ls -l model.bin
-rw-r--r--  1 you  staff  133 Jul 29 23:25 model.bin

cat model.bin
version https://git-lfs.github.com/spec/v1
oid sha256:bd0f1a2c80693bd366e78e7f64fc54b86712d1b79c53b397f3d1027232c38249
size 20971520
```

Leur construction échoue alors avec quelque chose de spectaculairement inutile comme « invalid PNG
header ». Chaque archive « Download ZIP » d'une forge a le même problème, et chaque runner
d'intégration continue dont l'image a oublié git-lfs aussi. Mettez une vérification dans votre script
de construction.

**Les forks et les pull requests interagissent mal**, particulièrement sur GitHub, où la bande
passante LFS est facturée au propriétaire du dépôt et où les forks n'héritent pas proprement des
objets LFS. Les contributions issues de forks qui touchent des chemins LFS sont un ticket de support
récurrent.

**`merge=lfs` ne fusionne pas.** Il ne le fera jamais. Deux modifications sur un binaire, cela reste
un tirage à pile ou face.

### Les alternatives qui valent d'être connues par leur nom

* **git-annex** — plus ancien que LFS, bien plus souple (de nombreux dorsaux, « ce fichier vit sur
  cette clé USB »), considérablement plus difficile à apprendre, et toujours activement maintenu. Si
  votre topologie de stockage est inhabituelle, regardez-le.
* **Xet** — un découpage en morceaux défini par le contenu, avec déduplication *en dessous* du niveau
  du fichier, de sorte que modifier une fraction d'un gros fichier ne téléverse qu'une fraction des
  octets. C'est désormais le stockage dorsal de Hugging Face, et `git-xet` existe comme agent de
  transfert personnalisé LFS pour parler au Hub. C'est une véritablement bonne idée et nous la
  traitons comme il faut dans
  [Git pour les données et les modèles](5-git-data-science.md "Git pour les données et les modèles").
* **Le clone partiel, le sparse-checkout et `scalar`** — la réponse pour un gros arbre de *sources*,
  ce qui est un problème différent d'un gros *binaire*. Le VFS for Git de Microsoft fut la première
  tentative ; Scalar l'a remplacé et est désormais livré dans Git.
* **Du stockage objet plus un manifeste commité** — pas de nouvel outillage, pas de nouveau
  protocole, pas de quota de fournisseur, et le commit épingle toujours un hachage immuable.
  Gravement sous-estimé.

## Récapitulatif `git lfs`

* Git stocke chaque version de chaque fichier comme un **blob** entier. La compression par delta du
  **packfile** aide énormément quand les versions partagent de longues plages d'octets et pas du tout
  dans le cas contraire — ce que décide le *format* du fichier, pas Git. Mesuré : cinq commits d'un
  CSV de 13 Mo s'empaquettent en 4,79 Mio ; les mêmes données gzippées, 23,54 Mio.
* `git clone` récupère tout l'historique, donc un gros fichier coûte à chaque collègue, pour
  toujours. Le supprimer plus tard n'aide pas ; seule la réécriture de l'historique aide.
* `git count-objects -vH` est la comptabilité honnête de la taille d'un dépôt, et
  `git rev-list --objects --all | git cat-file --batch-check=…` trouve les gros blobs tapis dans
  votre historique.
* Avant LFS : mettez les artefacts générés dans le `.gitignore`, commitez une URL plus une somme de
  contrôle, utilisez `--filter=blob:none` avec `git sparse-checkout` pour les gros arbres de sources
  (un clone de 2,28 Kio !), `--depth 1` pour l'intégration continue.
* `git lfs install` écrit un bloc `[filter "lfs"]` avec `clean`, `smudge`, `process` et `required`
  dans votre configuration, plus quatre hooks. `--local` le confine à un seul dépôt.
* `git lfs track "*.psd"` écrit `*.psd filter=lfs diff=lfs merge=lfs -text` dans `.gitattributes`,
  qui **doit être commité** et n'affecte que les fichiers ajoutés ensuite.
* Le **fichier pointeur** est un blob texte d'environ 130 octets contenant `version`,
  `oid sha256:…` et `size`. Les vrais octets vivent dans `.git/lfs/objects/` en local et sur un
  serveur LFS à distance.
* `clean` s'exécute au `git add`, `smudge` à l'extraction. Ce sont des filtres Git ordinaires — vous
  pouvez construire un LFS rudimentaire vous-même en trente lignes de shell.
* `git lfs ls-files`, `status`, `env`, `fetch`, `pull`, `checkout`, `prune`, `untrack`,
  `lock`/`unlock`/`locks`, `migrate info`/`import`/`export`. `GIT_LFS_SKIP_SMUDGE=1`,
  `--skip-smudge`, `lfs.fetchinclude`/`fetchexclude` et `lfs.concurrenttransfers` vous permettent de
  cloner un énorme dépôt à peu de frais.
* `git lfs migrate import --everything --include="*.bin"` **réécrit l'historique**, et il faut ensuite
  faire `git reflog expire --expire-unreachable=now --all && git gc --prune=now` ou rien ne rétrécit.
  Mesuré : 100,03 Mio → 3,28 Kio.
* LFS ne fait pas partie de Git : il exige une prise en charge côté serveur, il est compté et
  facturé, il casse le clone-comme-sauvegarde, et les contributeurs qui ne l'ont pas reçoivent des
  fichiers pointeurs et des erreurs déroutantes.
