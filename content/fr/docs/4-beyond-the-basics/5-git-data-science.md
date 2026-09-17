---
title: Git pour les données et les modèles
slug: "git-data-science"
weight: 35
---
# Git pour les données et les modèles

Git a été conçu en 2005 pour versionner le noyau Linux : du texte, écrit par des humains, en lignes,
relu par d'autres humains. Un point de contrôle de 4 Go n'est rien de tout cela. Un fichier Parquet
non plus, et — comme nous le verrons, douloureusement — un carnet Jupyter non plus.

Et pourtant le monde de la donnée et de l'apprentissage automatique tourne sur Git, parce qu'il n'y a
rien d'autre qui fasse ce que fait Git. Ce chapitre porte sur la manière dont cela fonctionne
réellement en pratique : ce que la communauté a bâti par-dessus, ce qu'elle a bien fait, et les
endroits où l'on attend de vous que vous sachiez des choses que personne ne vous a dites.

Si vous êtes venu ici en tant que personne de la donnée à qui on a tendu Git en lui disant de se
débrouiller, bienvenue. Si vous êtes venu en tant que développeur qui vient de rejoindre une équipe
de gens de la donnée, bienvenue aussi — vous êtes sur le point de comprendre pourquoi leur dépôt
ressemble à ça.

## Ce qui est différent dans le travail sur les données et les modèles

Un projet logiciel normal est reproductible quand vous extrayez un commit. Un projet de données est
reproductible quand vous pouvez épingler **quatre** choses :

1. **Le code** — Git fait cela, magnifiquement. C'est le facile.
2. **Les données** — Git fait cela mal, pour toutes les raisons données dans
   [Les gros fichiers, ou comment Git rencontre ses limites](4-git-lfs.md "Les gros fichiers, ou comment Git rencontre ses limites").
3. **L'environnement** — les versions exactes des bibliothèques. Git peut contenir le fichier de
   verrouillage, mais seulement si vous en fabriquez un.
4. **La configuration et l'aléa** — les hyperparamètres, la graine aléatoire, l'ordre de brassage, le
   non-déterminisme du GPU.

Manquez-en une seule sur les quatre et « ça marchait hier » devient un mystère. Tout l'écosystème
d'outils que nous nous apprêtons à regarder existe parce que Git ne versionne nativement que la
première, et que tout le monde veut que le *commit* soit la chose qui épingle les quatre.

Alors gardez ceci en tête comme cible : **un commit devrait identifier une exécution, complètement.**
Tout ce qui suit est une technique pour s'en approcher.

## Les carnets Jupyter dans Git

Commençons par la douleur quotidienne, parce que c'est elle qui fait réellement détester Git aux
gens.

Un fichier `.ipynb` est du JSON. Il contient votre code, et il contient aussi chaque cellule de
sortie, chaque compteur d'exécution, et chaque image rendue sous forme de blob en base64. Laissez-moi
mesurer un carnet véritablement minuscule : trois cellules, un histogramme.

```console
wc -c analysis.ipynb
   17591 analysis.ipynb
```

Dix-sept kilooctets pour onze lignes de code. Où sont-ils passés ? En additionnant les entrées
`outputs[].data["image/png"]` : **15 360 octets, 87 % du fichier**, est un PNG encodé en base64 sur
une seule ligne énorme.

Maintenant regardez ce qui se passe quand je réexécute le carnet sans changer un seul caractère de
code :

```console
jupyter execute --inplace analysis.ipynb
git diff --stat

 analysis.ipynb | 28 ++++++++++++++--------------
 1 file changed, 14 insertions(+), 14 deletions(-)
```

Quatorze lignes modifiées. L'une de ces lignes fait quinze kilooctets de base64. Les autres sont
`execution_count` qui passe de 1 à 1, et des horodatages `iopub.execute_input`. Il ne s'est rien
passé, et Git a docilement enregistré un changement de quinze kilooctets.

Multipliez par deux personnes sur deux branches et vous avez un conflit de fusion à l'intérieur d'une
chaîne base64, ce qui est à peu près aussi amusant que cela en a l'air.

### Remède un : retirer les sorties avec un filtre clean

Vous savez déjà exactement comment cela fonctionne, depuis le chapitre sur LFS : un filtre `clean`
s'exécute au `git add` et peut réécrire le contenu sur son chemin vers la base de données d'objets.
`nbstripout` est ce filtre.

```console
pip install nbstripout      # ou : uv add --dev nbstripout
nbstripout --install
```

Et regardez ce qu'il a écrit dans `.git/config` :

```ini
[filter "nbstripout"]
	clean = "…/python3" -m nbstripout
	smudge = cat
	required = true
[diff "ipynb"]
	textconv = "…/python3" -m nbstripout -t
```

Un `clean` qui retire les sorties, un `smudge` qui est littéralement `cat` (il n'y a rien à remettre
— les sorties ont *disparu*, exprès), et un `textconv` pour que `git diff` compare des versions
nettoyées et ne vous montre que les vrais changements.

> :warning:
> Par défaut, `nbstripout --install` écrit ses motifs dans **`.git/info/attributes`**, qui est local
> et non partagé. Vos collègues n'obtiennent rien de tout cela. Utilisez
> `nbstripout --install --attributes .gitattributes` pour que la configuration soit commitée,
> exactement comme nous y avons insisté pour LFS :
> ```console
> *.ipynb filter=nbstripout
> *.zpln filter=nbstripout
> *.ipynb diff=ipynb
> ```
> (Le `filter` doit quand même être défini localement — `.gitattributes` dit *quel* filtre, jamais
> *ce qu'il fait*. Mettez l'étape d'installation dans le script de mise en place de votre projet.)

L'effet, mesuré :

```console
wc -c analysis.ipynb
   17620 analysis.ipynb
git cat-file -s $(git rev-parse HEAD:analysis.ipynb)
1120
git diff --stat            # ← rien. Pas une ligne.
```

Le fichier de travail fait 17,6 Ko, le blob que Git a stocké fait **1120 octets**, et après une
nouvelle exécution le diff est *vide* — le filtre clean a produit une sortie identique octet pour
octet, donc il n'y a véritablement rien à commiter. (`git status` peut brièvement afficher encore un
` M` ; c'est le cache de `stat` de Git qui est paresseux, et `git add` règle la question.)

### Remède deux : appairer avec jupytext

L'autre approche est plus radicale et, à mon avis, meilleure : décider que le carnet n'est pas
l'artefact. Le *script* l'est.

```console
jupytext --set-formats ipynb,py:percent analysis.ipynb
jupytext --sync analysis.ipynb
ls -l analysis.ipynb analysis.py

-rw-r--r--  1 you  staff  18277 analysis.ipynb
-rw-r--r--  1 you  staff    462 analysis.py
```

Dix-huit kilooctets contre quatre cent soixante-deux octets, et le `.py` est un vrai fichier Python
avec un petit en-tête YAML en commentaires et des marqueurs de cellules `# %%` :

```python
# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
# ---

# %%
rng = np.random.default_rng()
x = rng.normal(size=2000)
print("mean:", x.mean())
```

Commitez le `.py`, mettez le `.ipynb` dans le `.gitignore`. Désormais `git diff` est lisible,
`git blame` fonctionne, la revue de code fonctionne, et les fusions sont des fusions de texte
ordinaires. Éditer l'un ou l'autre côté et lancer `jupytext --sync` propage le changement.

### Remède trois : apprendre à Git à comparer des carnets

Si vous avez véritablement besoin des sorties dans le dépôt — et c'est parfois le cas, pour un
rapport qui doit montrer les chiffres à partir desquels il a été bâti — procurez-vous au moins un
outil qui comprend le format. `nbdime config-git --enable --global` enregistre de vrais pilotes et
les attributs correspondants :

```ini
[diff "jupyternotebook"]
	command = git-nbdiffdriver diff
[merge "jupyternotebook"]
	driver = git-nbmergedriver merge %O %A %B %L %P
```

Alors `git diff` montre des changements cellule par cellule plutôt que du JSON, `nbdiff-web` donne
une vue côte à côte, et `nbmerge` sait véritablement résoudre des conflits qui vivent dans des
cellules différentes.

### Et le remède ennuyeux qui compte le plus

Sortez le code du carnet. Un carnet est un merveilleux endroit où explorer et un terrible endroit où
garder une fonction dont trois carnets ont besoin. Mettez les fonctions dans `src/votreprojet/`,
faites-en un `import`, et laissez le carnet n'être que vingt lignes de récit. Vos diffs rétrécissent,
vos tests deviennent possibles, et le carnet cesse d'être la chose que tout le monde a peur de
toucher.

Mon avis, énoncé comme un avis : **retirez les sorties par défaut, ou appairez avec jupytext.**
Commiter des sorties devrait être une décision délibérée que vous pouvez défendre, pas quelque chose
qui vous arrive parce que personne n'a rien configuré.

## Les jeux de données

Maintenant la moitié la plus difficile. Voici les vraies options, avec des compromis honnêtes.

**Les petites données de référence directement dans Git.** Une table de correspondance de 200 Ko, un
fichier de fixtures, un CSV de codes pays. Mettez-le dans le dépôt. Cela se compare, cela se relit,
cela se fusionne. Ne sur-concevez pas cela. Ma ligne approximative est : du texte, sous un mégaoctet
ou deux, qui change rarement, et dont un humain voudrait lire le diff.

**Git LFS.** Couvert au chapitre précédent. Convient pour une poignée de binaires moyens qui changent
occasionnellement. Mauvais pour un jeu de données de milliers de fichiers, parce que chacun devient
un blob pointeur et un transfert séparé.

**DVC.** Conçu spécialement pour cela (et, depuis fin 2025, propriété des gens de lakeFS), et le
modèle vous sera familier :

```console
dvc init
dvc add data/train.bin
cat data/train.bin.dvc

outs:
- md5: 5caeac5adb0115b0c4c8b4289caf1be4
  size: 10485760
  hash: md5
  path: train.bin
```

Voilà un fichier pointeur. La même idée qu'un pointeur LFS, mais c'est un fichier suivi ordinaire
avec un nom ordinaire plutôt qu'un imposteur géré par un filtre, ce qui honnêtement le rend plus
facile à raisonner. DVC écrit aussi le vrai chemin dans un `.gitignore` pour vous :

```console
cat data/.gitignore
/train.bin
```

Les octets vont dans `.dvc/cache/files/md5/5c/aeac5adb0115b0c4c8b4289caf1be4` — adressé par contenu,
la même astuce que tout le reste de ce cours — et de là vers un dépôt distant :

```console
dvc remote add -d store s3://mon-bucket/dvcstore     # ou gs://, azure://, ssh://, ou un chemin
dvc push
```

Alors Git détient 44 Ko pour un jeu de données de 10 Mio, et un collègue fait
`git clone && dvc pull`. Le dépôt distant est *votre* stockage objet : pas de quota de fournisseur,
pas de bande passante comptée, pas de limites par fichier.

**git-annex.** Plus ancien, plus général, plus difficile. Pour « ce fichier vit sur ce NAS et aussi
sur ce disque USB et je veux que Git sache lequel », c'est l'outil qui fait cela.

**lakeFS, Delta Lake, Iceberg.** Une réponse complètement différente : ne versionnez pas les données
dans votre dépôt, versionnez-les *là où elles vivent*. lakeFS vous donne des branches, des commits et
des étiquettes façon Git par-dessus un stockage objet, adressés comme `lakefs://depot/ref/chemin`.
Delta Lake et Iceberg tiennent un journal de transactions d'instantanés immuables, de sorte que vous
pouvez lire une table telle qu'elle était (`VERSION AS OF` / `TIMESTAMP AS OF` chez Delta, un
identifiant d'instantané chez Iceberg). Si vos données sont une table d'entrepôt plutôt qu'un
fichier, c'est la bonne réponse et DVC est la mauvaise.

**Du stockage objet plus un manifeste commité.** L'option sous-estimée. Aucun nouvel outil :

```console
(cd data && shasum -a 256 *.bin) > data.sha256
echo 'data/' >> .gitignore
git add data.sha256 && git commit -m "Pin the dataset by content hash"
cat data.sha256

6a8d56768a17512034163d1f15daf49705de190e4a59ef39fd85891d3e014ec3  a.bin
91d64d2f072a6f16889ced835b0031251bea9db17fcad6e614a76d916c312c81  b.bin
```

Et tout son intérêt — après qu'un octet de `a.bin` a été corrompu :

```console
(cd data && shasum -a 256 -c ../data.sha256)
a.bin: FAILED
b.bin: OK
shasum: WARNING: 1 computed checksum did NOT match
```

Code de sortie 1, donc votre `make data` refuse de continuer. C'est quatre-vingt-quinze pour cent de
ce que n'importe lequel de ces outils vous apporte, pour quatre lignes de shell et aucune dépendance.

> :information_source:
> Quel que soit votre choix, l'invariant qui compte est le même : **le commit doit épingler un
> hachage de contenu immuable des données.** Pas une URL vers un chemin de bucket mutable, pas « le
> dernier export », pas une date. Un hachage. Si votre `git checkout` du commit de mars dernier peut
> obtenir silencieusement les données de mars de cette année, vous n'avez pas de reproductibilité,
> vous avez une coïncidence.

## Hugging Face

Maintenant la partie dans laquelle vit réellement le monde de l'apprentissage automatique, et une
jolie surprise vous y attend.

### Le Hub est littéralement du Git

Pas « façon Git ». Du Git. Chaque modèle, jeu de données et Space du Hub est un dépôt Git que vous
pouvez cloner avec le Git que vous avez déjà.

```console
git clone https://huggingface.co/hf-internal-testing/tiny-random-gpt2
cd tiny-random-gpt2
git log --oneline
71034c5 Update weights (#4)
```

Et la toute première chose à regarder, puisque nous y avons consacré un chapitre entier :

```console
cat .gitattributes

*.bin.* filter=lfs diff=lfs merge=lfs -text
*.bin filter=lfs diff=lfs merge=lfs -text
*.h5 filter=lfs diff=lfs merge=lfs -text
*.onnx filter=lfs diff=lfs merge=lfs -text
*.pt filter=lfs diff=lfs merge=lfs -text
*.pth filter=lfs diff=lfs merge=lfs -text
*tfevents* filter=lfs diff=lfs merge=lfs -text
```

Le Hub livre un `.gitattributes` LFS généreux dans chaque nouveau dépôt, et c'est pourquoi personne
sur Hugging Face ne commite jamais accidentellement un point de contrôle brut. (Ce dépôt-ci a quelques
années et liste `model.safetensors` par son nom ; les modèles plus récents utilisent
`*.safetensors`. La liste dérive — acceptez ce que le Hub vous donne.) Et la récompense :

```console
git count-objects -vH | grep size-pack
size-pack: 13.41 KiB
```

**Treize kilooctets**, contre 11,9 Mio posés dans `.git/lfs`. Voilà tout l'historique Git d'un dépôt
de modèle. Les poids sont des objets LFS, exactement comme nous les avons disséqués au chapitre
précédent :

```console
git show HEAD:model.safetensors
version https://git-lfs.github.com/spec/v1
oid sha256:8111d5afb0715dbf5a31396d31432cb56370ba23f6650a035ea0fc8a20b4e500
size 453864
```

Tout ce que vous avez appris sur les branches, les étiquettes, les commits et `git log` s'applique aux
modèles. Un modèle a un historique. Vous pouvez faire un `git diff` de son `config.json`. Vous pouvez
étiqueter une version. Les pull requests existent (le Hub les appelle des discussions, et elles vivent
sous `refs/pr/`). C'est véritablement l'une des meilleures décisions de conception de l'écosystème de
l'apprentissage automatique.

### L'authentification

```console
hf auth login       # ouvre un navigateur, ou collez un jeton depuis settings/tokens
hf auth whoami
hf auth list        # vous pouvez en stocker plusieurs et basculer avec hf auth switch
```

Tout lit aussi la variable d'environnement `HF_TOKEN`, ce qui est ce que vous voulez en intégration
continue. `HF_HOME` déplace tout le cache et le magasin de jetons — pratique pour les conteneurs, et
pour garder des expériences isolées.

> :warning:
> La commande `huggingface-cli` a été renommée en `hf`. Sur la version que j'ai ici
> (`huggingface_hub` 1.25.1), lancer l'ancien nom donne
> `Warning: huggingface-cli is deprecated and no longer works. Use hf instead.` — c'est un talon, pas
> un alias. Les installations 0.x plus anciennes ont encore un `huggingface-cli` fonctionnel. Une
> surface qui bouge vite : lancez `hf --help` plutôt que de faire confiance à un tutoriel, y compris
> le mien.

Pour un `git push` vers le Hub en https, le jeton est votre mot de passe, et `hf auth login` proposera
de l'installer comme assistant d'identifiants Git. SSH fonctionne aussi, avec une clé enregistrée dans
les réglages de votre Hub.

### `hf download` contre `git clone`, et pourquoi

Vous *pouvez* cloner un dépôt de modèle. En général vous ne devriez pas, et la raison mérite d'être
comprise plutôt que mémorisée.

Voici le même petit modèle récupéré des deux manières. D'abord le clone que nous avons fait plus haut,
en additionnant chaque fichier :

```console
  clone complet : 23,87 Mio
  .git :          11,94 Mio   (.git/objects : 0,01 Mio, .git/lfs : 11,90 Mio)
  arbre de travail :
    model.safetensors            0,43 Mio
    pytorch_model.bin            3,40 Mio
    tf_model.h5                  8,07 Mio
    {…configs et fichiers de tokenizer…}
```

Puis `hf download`, en ne demandant que ce dont un programme PyTorch a réellement besoin :

```console
hf download hf-internal-testing/tiny-random-gpt2 \
  --include "*.safetensors" "config.json" "tokenizer*" --revision 71034c5

hf cache list
id                                          size    refs
model/hf-internal-testing/tiny-random-gpt2  472.4K  ['71034c5']
```

23,87 Mio contre 472 Kio. Cinquante fois. Et les raisons sont toutes mécaniques :

* **`git clone` prend tout le dépôt.** Ce modèle livre des poids PyTorch *et* TensorFlow *et*
  safetensors — trois copies des mêmes paramètres. Vous en vouliez une.
  `--include`/`allow_patterns` en récupère une.
* **Deux copies sur le disque.** Un clone laisse les octets dans `.git/lfs` *et* dans l'arbre de
  travail. 11,9 Mio chacun.
* **Pas de partage entre projets.** Dix projets utilisant le même modèle de base, cela fait dix
  clones. Le cache du Hub est un magasin unique, partagé et adressé par contenu.
* **Les transferts sont meilleurs.** Reprenables, parallèles, découpés en morceaux, et conscients de
  Xet (voir plus bas). `git-lfs` convient ; ceci vaut mieux.

L'API Python fait la même chose :

```python
from huggingface_hub import snapshot_download

path = snapshot_download(
    repo_id="hf-internal-testing/tiny-random-gpt2",
    revision="71034c5d8bde858ff824298bdedc65515b97d2b9",   # épinglez-la !
    allow_patterns=["*.safetensors", "config.json", "tokenizer*"],
)
```

`hf_hub_download` en fait un seul fichier. Les deux renvoient un chemin dans le cache, donc rien n'est
copié. (`hf cache list` est l'orthographe de la 1.x ; en 0.x c'est `hf cache scan`. Il y a aussi
`hf cache rm` et `hf cache prune`, dont vous voudrez la première fois que votre
`~/.cache/huggingface` atteindra cinquante gigaoctets. Cela arrivera.)

### Le cache, et un joli détail

```console
$HF_HOME/hub/models--hf-internal-testing--tiny-random-gpt2/
├── blobs/
│   ├── 4ff64fe5192d88c0b5dbfc578c775c0ce05dd7d0
│   └── 8111d5afb0715dbf5a31396d31432cb56370ba23f6650a035ea0fc8a20b4e500
├── refs/
│   └── 71034c5
└── snapshots/
    └── 71034c5d8bde858ff824298bdedc65515b97d2b9/
        ├── config.json        -> ../../blobs/4ff64fe5192d88c0b5…
        └── model.safetensors  -> ../../blobs/8111d5afb0715dbf5a…
```

`blobs/` contient le contenu, `snapshots/<révision>/` contient un répertoire de **liens symboliques**
aux noms humains. Deux révisions qui partagent un fichier partagent un blob. Si cette structure vous
semble familière, c'est normal — c'est `.git/objects` plus un arbre, reconstruit dans un autre
langage.

Regardez maintenant attentivement ces deux noms de blobs. L'un fait 40 caractères hexadécimaux,
l'autre 64. Vérifions le court contre le clone :

```console
git rev-parse HEAD:config.json
4ff64fe5192d88c0b5dbfc578c775c0ce05dd7d0
```

Voilà l'identifiant de **blob** SHA-1 propre à Git. Et celui de 64 caractères est l'`oid sha256:` de
LFS issu du pointeur que nous avons affiché plus haut. Le cache du Hub nomme donc les petits fichiers
par leur *hachage de blob Git* et les gros fichiers par leur *hachage LFS*, parce que ce sont les
identifiants que le Hub sert déjà comme ETags. Personne ne documente cela clairement ; cela tombe
directement du modèle d'objets que vous avez appris en partie 1.

> :warning:
> Les liens symboliques sont toute l'histoire de l'efficacité ici, donc sur les systèmes de fichiers
> qui n'en ont pas (certaines configurations Windows, certains montages de volumes Docker),
> `huggingface_hub` se rabat sur la copie et vous prévient.
> `HF_HUB_DISABLE_SYMLINKS_WARNING=1` fait taire l'avertissement ; cela ne vous rend pas le disque.

### Épinglez la révision, toujours

```python
AutoModel.from_pretrained("some-org/some-model", revision="a1b2c3d")
```

`main` est une cible mouvante. Les auteurs de modèles poussent en force, requantifient, « corrigent le
tokenizer », et vos chiffres d'évaluation changent trois semaines plus tard sans raison que vous
puissiez trouver. Un **SHA** de commit est immuable ; une étiquette l'est presque. Épinglez le SHA
dans tout ce que vous voudrez expliquer plus tard, et enregistrez-le dans les métadonnées de
l'exécution.

C'est l'habitude à plus forte valeur de tout ce chapitre. Elle ne coûte rien et elle épargne des
après-midi entiers.

### De LFS à Xet

LFS déduplique des fichiers entiers : changez un octet dans un point de contrôle de 5 Go et vous
téléversez 5 Go, parce que le SHA-256 a changé et que c'est la seule unité que LFS connaisse.

**Xet** est le remplaçant de Hugging Face, et l'idée est véritablement bonne. Au lieu de hacher le
fichier, il le découpe en morceaux à des frontières choisies par le *contenu* lui-même — un hachage
glissant sur une fenêtre coulissante, et on coupe là où le hachage tombe sur un motif. Cela s'appelle
le **découpage défini par le contenu**, et sa propriété magique est qu'insérer des octets au début
d'un fichier ne décale pas toutes les frontières suivantes : les morceaux après l'insertion sont
identiques à ce qu'ils étaient. Comparez avec des blocs de taille fixe, où insérer un octet change
tous les blocs.

Les morceaux sont ensuite hachés, dédupliqués globalement, et regroupés en blocs plus grands pour le
transfert. Conséquences :

* Un affinage qui perturbe une fraction des poids téléverse une fraction des octets.
* Deux quantifications du même modèle partagent ce qu'elles partagent, automatiquement.
* Tous ceux qui téléchargent le même modèle de base tapent dans le même cache de morceaux.

Vous pouvez voir les deux mondes coexister dans les métadonnées mêmes du Hub. Interroger l'API
`paths-info` sur un fichier renvoie :

```json
{
  "oid": "cdebb9016e0099550c661ad5d7b4b0db174d2da7",
  "size": 453864,
  "lfs": { "oid": "8111d5afb…", "size": 453864, "pointerSize": 131 },
  "xetHash": "f8accece953fd366d4ce30597b97acc1ccedc3c785187a5ef6ecb4a8e1755122"
}
```

Un oid de blob Git, un oid LFS *et* un hachage Xet pour le même fichier. Voilà la migration rendue
visible : le pointeur visible par Git reste un pointeur LFS, de sorte qu'un `git clone` ordinaire
continue de fonctionner, pendant que les transferts fondés sur `hf` passent par Xet. Sur ma machine,
`hf-xet` est arrivé automatiquement comme dépendance de `huggingface_hub`, et les téléchargements ont
créé un cache de morceaux `$HF_HOME/xet/` — donc pour les chemins Python et CLI, Xet est simplement
actif.

Il existe aussi une extension Git `git-xet` qui se branche sur LFS comme agent de transfert
personnalisé si vous voulez qu'un `git push` ordinaire passe par Xet. Tout ce domaine bouge vite :
traitez l'état du déploiement comme quelque chose à vérifier, pas à mémoriser.

### Pousser un modèle ou un jeu de données

```console
hf repos create my-cool-model --type model          # ou --type dataset / --type space
hf upload my-cool-model ./out .                     # dossier -> racine du dépôt, un commit
hf upload my-cool-model ./out/model.safetensors     # ou un seul fichier
```

Depuis Python, `create_repo()` et `upload_folder()`, ou la méthode `push_to_hub()` que
`transformers`, `datasets` et compagnie posent sur leurs objets. Sous le capot, ce sont des commits
du Hub — les mêmes commits que `git log` vous montre.

Ce qui a sa place dans le dépôt :

* `config.json`, `tokenizer.json`, `preprocessor_config.json` — les petits fichiers texte qui rendent
  les poids utilisables. Ils se comparent bien. Lisez leurs diffs.
* Les poids, en `.safetensors`.
* `.gitattributes` — acceptez celui que le Hub vous donne.
* `README.md` **avec un en-tête YAML** : c'est la fiche du modèle, et l'en-tête est une métadonnée
  structurée que le Hub indexe. Un vrai exemple :

```yaml
---
language: en
tags:
- exbert
license: apache-2.0
datasets:
- bookcorpus
- wikipedia
---
```

D'autres clés courantes sont `library_name`, `pipeline_tag`, `base_model`, `metrics`, et pour les
jeux de données `configs` et `dataset_info`. Remplissez-les : c'est ainsi qu'on trouve votre travail,
et `license` en particulier n'est pas une politesse optionnelle.

Ce qui n'y a pas sa place : les journaux d'entraînement, les points de contrôle de chaque époque,
votre `.env`, le jeu de données brut si le jeu de données a son propre dépôt, et onze quantifications
que personne n'a demandées.

Les dépôts peuvent être **privés**, ou **à accès conditionné** (métadonnées publiques, accès sur
demande ou après acceptation de conditions) — utile pour des données sous licence.

Et les Spaces : un Space est un dépôt Git qui **se redéploie quand vous poussez dessus.** Ce n'est pas
une métaphore du GitOps, c'est du GitOps — l'état déployé est une fonction d'un commit. À lire à côté
de [GitOps](../5-automation/1-git-ops.md "GitOps").

### Les deux choses qui vont réellement vous faire mal

> :warning:
> **Ne commitez jamais un jeton.** Pas dans une cellule de carnet, pas dans `config.py`, pas dans la
> sortie `.ipynb` où vous l'avez affiché pour déboguer (rappelez-vous, les sorties sont commitées à
> moins que vous ne les ayez retirées). Une fois poussé, il est dans l'historique pour toujours et le
> faire tourner est le seul vrai remède. Utilisez `HF_TOKEN`, utilisez les secrets des Spaces,
> utilisez le magasin de secrets de votre intégration continue. Un hook de pre-commit qui cherche
> `hf_[A-Za-z0-9]{34}` coûte cinq minutes.

> :warning:
> **Les poids d'un modèle peuvent exécuter du code.** Un point de contrôle PyTorch `.bin` est un
> **pickle** Python, et le dépicklage exécute du code arbitraire, par conception. « Télécharger un
> modèle » et « exécuter le programme d'un inconnu » ont historiquement été le même acte. C'est un
> vrai problème de chaîne d'approvisionnement, pas un problème théorique — des modèles malveillants
> ont été trouvés sur des hubs publics.
>
> Les réponses, par ordre d'utilité. Préférez les **`.safetensors`** : une longueur de 8 octets, un
> en-tête JSON de formes et de décalages, puis des octets bruts — aucun chemin d'exécution de code, et
> cela se projette en mémoire, donc cela charge aussi plus vite. Gardez PyTorch à jour : `torch.load`
> prend `weights_only=True` par défaut depuis PyTorch 2.6 (seulement si vous ne passez pas
> `pickle_module`, et les versions plus anciennes ne le font pas). Et lisez les résultats d'analyse du
> Hub, qui sont réels et publics :
>
> ```json
> "pickleImportScan": {"status": "safe", "pickleImports": [
>   {"module": "collections", "name": "OrderedDict",       "safety": "innocuous"},
>   {"module": "torch",       "name": "ByteStorage",       "safety": "innocuous"},
>   {"module": "torch",       "name": "FloatStorage",      "safety": "innocuous"},
>   {"module": "torch._utils","name": "_rebuild_tensor_v2","safety": "innocuous"}]}
> ```
>
> Voilà une véritable sortie de l'API du Hub pour un `pytorch_model.bin`, produite en parcourant les
> opcodes du pickle sans les exécuter. Un pickle qui importe `os` ou `subprocess` n'est pas inoffensif,
> et le Hub le dira — à côté d'un scan antiviral et de deux analyseurs tiers.
>
> Mais ne confondez pas l'analyse avec la sûreté. Hugging Face le dit lui-même, et des chercheurs ont
> publié des points de contrôle fabriqués pour passer sous les analyseurs (flux d'opcodes cassés,
> formats d'archives inattendus). « Le pickle est analysé » est une atténuation. « Le format ne peut
> pas exécuter de code » est une propriété. Préférez la propriété.

## Le suivi d'expériences et les pipelines

### Les pipelines DVC : un make pour les données

`dvc.yaml` déclare des étapes avec des dépendances, des paramètres et des sorties. C'est `make` avec
du hachage de contenu plutôt que des horodatages, ce qui est exactement la différence qui compte.

```console
dvc stage add -n train -d train.py -d data/train.bin \
  -p train.seed,train.epochs -M metrics.json python train.py
cat dvc.yaml

stages:
  train:
    cmd: python train.py
    deps:
    - data/train.bin
    - train.py
    params:
    - train.epochs
    - train.seed
    metrics:
    - metrics.json:
        cache: false
```

Puis `dvc repro`. La sortie intéressante est `dvc.lock`, que vous commitez, et qui enregistre le
hachage de chaque entrée :

```yaml
stages:
  train:
    cmd: python train.py
    deps:
    - path: data/train.bin
      md5: 5caeac5adb0115b0c4c8b4289caf1be4
      size: 10485760
    - path: train.py
      md5: 56aeeb9b179df3ee66de5878110a5477
    params:
      params.yaml:
        train.epochs: 3
        train.seed: 42
```

Relancez-le et rien ne se passe :

```console
dvc repro
'data/train.bin.dvc' didn't change, skipping
Stage 'train' didn't change, skipping
Data and pipelines are up to date.
```

Passez `seed: 42` à `seed: 7` dans `params.yaml` et seule l'étape concernée se relance. Désormais le
commit qui contient `dvc.lock` épingle le code, les données *et* la configuration. Cela fait trois de
nos quatre.

### Enregistrez les exécutions ailleurs, indexées par le commit

MLflow, Weights & Biases, Aim, de simples fichiers JSON dans un bucket — l'outil compte beaucoup
moins que la discipline, qui est : **chaque exécution enregistre le commit dont elle provient.**

```console
printf '{"commit": "%s", "dirty": %s, "when": "%s"}\n' \
  "$(git rev-parse HEAD)" \
  "$([ -n "$(git status --porcelain)" ] && echo true || echo false)" \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

{"commit": "b4b269ae8f5eee76d16a414c3a8ef13ac22547d0", "dirty": true, "when": "2026-07-29T21:30:00Z"}
```

Notez le drapeau `dirty`, et prenez-le au sérieux. Une exécution issue d'un arbre sale n'est pas
reproductible, et le savoir six mois plus tard est la différence entre « nous pouvons reconstruire
ceci » et « nous ne pouvons pas ». Soit vous refusez de tourner sur un arbre sale, soit vous
l'enregistrez bruyamment.

> :information_source:
> `git describe --always --dirty` en est la version plus nette, mais sachez qu'il ne considère que
> les modifications **suivies** — un fichier non suivi que votre script d'entraînement importe
> joyeusement ne le fera pas dire `-dirty`. `git status --porcelain` voit aussi les fichiers non
> suivis, et c'est pourquoi je l'emploie ci-dessus.

Vous pouvez aussi attacher la provenance au commit lui-même avec
[git notes](3-git-notes.md "git notes") — une note sur le commit disant « exécution 4471, exactitude
0,913 » convient véritablement bien à cette fonctionnalité, avec toutes les réserves sur le fait que
les notes ne sont pas poussées par défaut.

## Épingler l'environnement

Section courte, parce qu'il n'y a qu'une règle : **le fichier de verrouillage fait partie des
sources.**

* Python : `uv.lock` (ce que j'utilise — `uv sync` est reproductible et rapide), `poetry.lock`,
  `requirements.txt` généré avec `--generate-hashes`, `conda-lock`. Commitez-les. Commitez celui
  depuis lequel votre intégration continue installe réellement.
* CUDA et les pilotes font aussi partie de l'environnement, et aucun fichier de verrouillage ne vous
  sauvera. Notez sur quoi vous avez tourné.
* Les conteneurs : épinglez par **empreinte**, pas par étiquette.
  `pytorch/pytorch:2.5.1-cuda12.1-cudnn9-runtime` peut être reconstruit sous vos pieds ;
  `pytorch/pytorch@sha256:…` non. La forme `@sha256:` est la seule référence immuable, et c'est la
  même idée qu'épingler une révision du Hub ou un hachage de jeu de données. À ce stade, vous devriez
  remarquer un motif.

## Un exemple travaillé, de bout en bout

Voici le tout assemblé en une forme que vous pouvez copier. Soyons clairs sur ce que c'est : chaque
*mécanisme* ci-dessous a été exécuté et mesuré pour ce chapitre — les filtres de carnet, les
`dvc add`/`repro`/`push` contre un dépôt distant local, l'estampille de provenance — mais je n'ai pas
lancé ce script exact de bout en bout, et les étapes marquées NON EXÉCUTÉ demandent un compte Hub et
un jeton. Donc pas de sortie inventée ici ; lisez-le comme la recette qu'il est.

```console
# 1. le dépôt : le code dans Git, l'environnement verrouillé, les carnets nettoyés
git init sentiment && cd sentiment
uv init --python 3.12 && uv add transformers safetensors && uv add --dev jupytext nbstripout
nbstripout --install --attributes .gitattributes
git add -A && git commit -m "Project skeleton, uv lock, notebook filters"

# 2. le jeu de données, épinglé par hachage et tenu hors de Git
dvc init && dvc remote add -d store s3://my-bucket/dvcstore
dvc add data/reviews.parquet
git add data/reviews.parquet.dvc data/.gitignore .dvc/config
git commit -m "Track reviews.parquet with DVC" && dvc push

# 3. le pipeline : code + données + paramètres, tous hachés dans dvc.lock
dvc stage add -n train -d src/sentiment/train.py -d data/reviews.parquet \
  -p train.seed,train.epochs -o out/model.safetensors -M metrics.json \
  python -m sentiment.train
dvc repro
git add dvc.yaml dvc.lock params.yaml metrics.json && git commit -m "Train stage"

# 4. estampiller l'exécution avec sa provenance (commit + drapeau dirty + métriques)
python -c 'import json,subprocess as sp; \
 h=sp.check_output(["git","rev-parse","HEAD"],text=True).strip(); \
 d=bool(sp.check_output(["git","status","--porcelain"],text=True).strip()); \
 json.dump({"commit":h,"dirty":d}|json.load(open("metrics.json")),open("out/run.json","w"))'

# 5. publier  (NON EXÉCUTÉ ICI — demande un jeton Hub)
hf auth login
hf repos create sentiment-distilbert --type model
hf upload sentiment-distilbert ./out .
hf repos tag create sentiment-distilbert v1.0
```

Et le côté consommateur, qui est la partie qui doit encore fonctionner dans un an :

```python
from huggingface_hub import snapshot_download

path = snapshot_download(
    "you/sentiment-distilbert",
    revision="v1.0",                       # ou mieux, le SHA du commit
    allow_patterns=["*.safetensors", "config.json", "tokenizer*"],
)
```

Quatre choses épinglées : le code par le commit Git, les données par le hachage DVC dans `dvc.lock`,
l'environnement par `uv.lock`, la configuration par `params.yaml` — lui-même haché dans `dvc.lock`.
Un commit, une exécution, une réponse.

## Récapitulatif, versionner données, modèles et carnets

* La reproductibilité exige d'épingler **quatre** choses : le code, les données, l'environnement, la
  configuration. Git fait nativement la première ; tout ce qui est ici sert à faire qu'un commit
  épingle les quatre.
* Un `.ipynb` est du JSON contenant des sorties et des images en base64 — mesuré : 87 % d'un carnet
  minuscule était un seul PNG, et le réexécuter sans changement de code a produit un diff de 15 Ko.
* `nbstripout --install --attributes .gitattributes` installe un **filtre clean** qui retire les
  sorties (fichier de travail de 17,6 Ko → blob de 1120 octets). Sans `--attributes`, il écrit dans
  `.git/info/attributes`, que vos collègues ne voient jamais.
  `jupytext --set-formats ipynb,py:percent` appaire un carnet avec un vrai `.py` (18 277 → 462
  octets) — commitez le `.py`, ignorez le `.ipynb`. `nbdime config-git --enable` donne de vrais
  pilotes de diff et de fusion pour les carnets.
* Les jeux de données : du petit texte directement dans Git ; LFS pour quelques binaires ; **DVC**
  (`dvc add` écrit un pointeur `.dvc`, `dvc push` envoie les octets vers votre propre stockage) ;
  git-annex pour les topologies exotiques ; lakeFS/Delta/Iceberg quand les données sont une table ;
  **du stockage objet plus un manifeste à sommes de contrôle** quand vous ne voulez aucune nouvelle
  dépendance. L'invariant : le commit doit épingler un hachage de contenu immuable.
* Le Hub de Hugging Face **est du Git**. `git clone https://huggingface.co/org/model` fonctionne, et
  tout l'historique d'un dépôt de modèle peut tenir en 13 Kio de packfile parce que les poids sont des
  objets LFS.
* `hf auth login`, `HF_TOKEN`, `HF_HOME`. `huggingface-cli` a été renommé en `hf`, et dans
  `huggingface_hub` 1.x l'ancien nom ne fonctionne plus du tout. Préférez
  `hf download` / `snapshot_download(allow_patterns=…)` à `git clone` : mesuré, 472 Kio contre
  23,87 Mio pour le même modèle, parce qu'un clone prend les poids de tous les frameworks et en garde
  deux copies.
* Le cache du Hub est adressé par contenu avec des instantanés en liens symboliques, et il nomme les
  petits fichiers par leur **SHA-1 de blob Git** et les gros par leur **SHA-256 LFS**.
* Passez toujours `revision=` — un **SHA** de commit ou une étiquette. `main` bouge.
* **Xet** remplace LFS par un découpage défini par le contenu et une déduplication au niveau du
  morceau, de sorte qu'un affinage ne téléverse que ce qui a changé. Les fichiers portent à la fois
  un `lfs.oid` et un `xetHash` pendant la migration.
* La publication : `hf repos create`, `hf upload`, `push_to_hub()`. Livrez `config.json`, les fichiers
  de tokenizer, les `.safetensors`, le `.gitattributes`, et un `README.md` avec un en-tête YAML. Les
  Spaces se redéploient au push, ce qui en fait un véritable exemple de GitOps.
* Ne commitez jamais un jeton. Préférez les `.safetensors` aux `.bin` fondés sur pickle, parce que le
  dépicklage exécute du code — et lisez, sans trop y faire confiance, les résultats de
  `pickleImportScan` du Hub.
* `dvc.yaml` + `dvc repro` + `dvc.lock` est un make-avec-hachages. Enregistrez chaque exécution avec
  `git rev-parse HEAD` **et** un drapeau d'arbre sale issu de `git status --porcelain`. Commitez votre
  fichier de verrouillage (`uv.lock`, `poetry.lock`, `conda-lock`), et épinglez les conteneurs par
  empreinte `@sha256:`, jamais par étiquette.
