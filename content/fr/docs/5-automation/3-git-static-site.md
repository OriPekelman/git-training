---
title: Déployer un site statique tout simple
slug: "git-static-site"
weight: 43
---
# Déployer un site statique tout simple

Tout au début de ce cours, dans
[Git et son écosystème](../1-understanding-git/2-git-ecosystem.md "Git et son écosystème"), je vous
ai promis que nous allions « déployer un projet sur un vrai serveur, sans les mains ». Voici le
chapitre où nous le faisons. À la fin, vous taperez `git push` et un site web changera.

Nous allons déployer un **site statique** — un tas de HTML, de CSS, d'images et peut-être un
fichier JavaScript — et c'est un choix délibéré, pas une simplification dont nous aurions honte. Un
site statique est le premier déploiement parfait parce que le produit de sa construction, ce sont
*juste des fichiers*. Pas de processus à redémarrer, pas de base de données à migrer, pas de pool
de connexions à vider. Chaque mécanisme est visible et chaque étape est compréhensible, ce qui veut
dire que nous pouvons construire le tout nous-mêmes à partir de pièces Git que nous possédons
déjà, *et ensuite* regarder les services hébergés en comprenant exactement ce qu'ils font pour
nous.

## Le déploiement à partir des premiers principes : un dépôt nu sur un serveur

Voici toute l'idée. Nous mettons un dépôt **nu** sur un serveur. Nous l'ajoutons comme **dépôt
distant**. Quand nous poussons dessus, un **hook** se réveille, extrait les fichiers, construit le
site et pointe le serveur web sur le résultat.

C'est un système de déploiement complet, et cela fait une vingtaine de lignes de shell.

### Le dépôt nu

Sur le serveur, par SSH :

```console
mkdir -p /srv/mysite/releases
cd /srv/mysite
git init --bare site.git
```

Un dépôt **nu** est un dépôt sans répertoire de travail — juste le contenu de `.git`, au premier
niveau. C'est ce que vous voulez sur un serveur : personne n'y édite de fichiers, donc un arbre de
travail ne serait qu'une chose de plus à désynchroniser. `git init --bare` est la manière dont tous
les hébergeurs Git du monde stockent votre code.

Sur notre portable, ajoutons-le comme dépôt distant et poussons :

```console
git remote add production ssh://you@example.com/srv/mysite/site.git
git push production main
```

Cela fonctionne déjà — le dépôt reçoit nos commits. Il n'en *fait* simplement encore rien.

### Le hook

Les hooks sont les scripts que Git exécute à des moments particuliers ; nous les avons rencontrés
dans [Faire sienne la ligne de commande](../3-tooling-ecosystem/1-git-tools.md "Faire sienne la ligne de commande").
Du côté de la réception, il y en a trois qui comptent, et choisir le bon compte :

* `pre-receive` s'exécute **une fois**, avant que quoi que ce soit ne soit écrit, pour tout le push.
  Sortir avec un code non nul rejette le push *entier*. C'est là qu'on impose une politique.
* `update` s'exécute **une fois par référence**, et peut rejeter des références individuelles.
* `post-receive` s'exécute **une fois**, après que toutes les références ont été mises à jour, et
  ne peut rien rejeter. C'est là qu'on déploie.

Nous voulons `post-receive`, pas `post-update`, pour une raison : `post-receive` reçoit sur son
entrée standard les anciens et les nouveaux **SHA** de chaque référence mise à jour, tandis que
`post-update` ne reçoit qu'une liste de noms de références en arguments. Nous voulons savoir *ce
qui* a bougé et *d'où*, donc nous prenons celui qui nous le dit.

Créez `/srv/mysite/site.git/hooks/post-receive` :

```sh
#!/bin/sh
set -eu

DEPLOY_BRANCH=main
SOURCE_DIR=/srv/mysite/source
RELEASES_DIR=/srv/mysite/releases
CURRENT=/srv/mysite/current

while read -r oldrev newrev refname; do

    if [ "$refname" != "refs/heads/$DEPLOY_BRANCH" ]; then
        echo "hook: $refname n'est pas la branche de déploiement, on ignore."
        continue
    fi

    echo "hook: déploiement de $DEPLOY_BRANCH ($oldrev -> $newrev)"

    mkdir -p "$SOURCE_DIR"
    git --work-tree="$SOURCE_DIR" checkout -f "$DEPLOY_BRANCH"

    release="$RELEASES_DIR/$(date -u +%Y%m%d%H%M%S)-$(git rev-parse --short "$newrev")"
    mkdir -p "$release"
    cp -R "$SOURCE_DIR"/. "$release"/
    ( cd "$release" && ./build.sh )

    ln -sfn "$release/public" "$CURRENT.new"
    mv -Tf "$CURRENT.new" "$CURRENT"

    echo "hook: on sert maintenant $release/public"

    ls -1 -t "$RELEASES_DIR" | tail -n +6 | while read -r old; do
        rm -rf "$RELEASES_DIR/$old"
    done
done
```

Puis, et c'est l'étape que tout le monde oublie :

```console
chmod +x /srv/mysite/site.git/hooks/post-receive
```

Parcourons-le ligne à ligne, parce que chaque ligne est là pour une raison.

`#!/bin/sh` et `set -eu` : du shell POSIX ordinaire, on sort à la moindre erreur, et on traite les
variables non définies comme des erreurs. Un script de déploiement qui continue après une étape
ratée est un script de déploiement qui sert un site à moitié construit.

`while read -r oldrev newrev refname; do` : **voilà l'interface.** Git alimente `post-receive` avec
une ligne par référence mise à jour sur son entrée standard, et chaque ligne comporte trois champs
séparés par des espaces : le SHA vers lequel la référence pointait avant, celui vers lequel elle
pointe maintenant, et le nom complet de la référence. Un seul push peut déplacer plusieurs
références, d'où la boucle. Une branche toute neuve arrive avec `oldrev` à quarante zéros ; une
branche supprimée arrive avec `newrev` à quarante zéros.

Le test sur `refname` : nous ne déployons que lorsque `refs/heads/main` bouge. Pousser une branche
thématique en production devrait être gratuit, pas catastrophique.

`git --work-tree="$SOURCE_DIR" checkout -f "$DEPLOY_BRANCH"` : l'astuce au cœur de tout ce
chapitre. Le dépôt est nu, il n'a donc pas d'arbre de travail — mais nous pouvons lui en *prêter*
un. `--work-tree` dit « mets les fichiers là », et `checkout -f` dit « fais correspondre ce
répertoire à cette branche, en jetant tout ce qui gêne ». Le hook s'exécute avec son répertoire
courant dans le dépôt nu et `GIT_DIR` déjà réglé dessus, donc nous n'avons pas besoin de
`--git-dir`.

> :information_source:
> Nous extrayons le *nom de la branche* plutôt que `$newrev`. Les deux fonctionnent, mais extraire
> un SHA brut met le dépôt en état de **tête détachée** et Git déverse tout son sympathique discours
> à ce sujet dans la sortie de votre push. Extraire la branche affiche un discret `Already on
> 'main'` à la place.

Le répertoire `release` : un horodatage plus le SHA court du commit que nous déployons. Désormais
chaque construction sur le serveur est étiquetée par le commit qui l'a produite, ce qui vaut une
fortune à 3 h du matin. Nous construisons *dans* ce répertoire plutôt que par-dessus le site en
ligne.

`ln -sfn` puis `mv -Tf` : la bascule, dont nous parlons plus bas.

Les trois dernières lignes gardent les cinq versions les plus récentes et suppriment le reste,
parce que les disques se remplissent.

### Ce que ça donne quand on pousse

Une vraie sortie, d'une vraie exécution de ce hook exact :

```console
$ git push origin main
remote: hook: déploiement de main (cfc6b957e3b163124d2097192b6581832fb70509 -> b25b8e41f0d132ce25d8548cf5c7aff0458a9711)
remote: Already on 'main'
remote: hook: on sert maintenant /srv/mysite/releases/20260729213622-b25b8e4/public
To ssh://you@example.com/srv/mysite/site.git
   cfc6b95..b25b8e4  main -> main
```

Tout ce que le hook écrit sur sa sortie standard nous revient par le réseau, préfixé de
`remote:`. C'est notre journal de déploiement, et il est gratuit.

Et quand nous poussons une autre branche :

```console
remote: hook: refs/heads/topic n'est pas la branche de déploiement, on ignore.
```

### Refuser un push forcé sur la branche de déploiement

Notre branche de déploiement est désormais un morceau d'infrastructure de production, elle devrait
donc se comporter comme tel : elle ne devrait jamais aller que vers l'avant. Si quelqu'un pousse en
force un historique réécrit, notre répertoire `releases` devient une fiction.

`pre-receive` est le hook qui peut dire non. Créez `/srv/mysite/site.git/hooks/pre-receive` (et
faites-en un `chmod +x`) :

```sh
#!/bin/sh

DEPLOY_BRANCH=main

while read -r oldrev newrev refname; do
    [ "$refname" = "refs/heads/$DEPLOY_BRANCH" ] || continue

    # newrev est à zéro quand quelqu'un supprime la branche.
    if ! git rev-parse --quiet --verify "$newrev^{commit}" >/dev/null; then
        echo "Refus de supprimer $DEPLOY_BRANCH." >&2
        exit 1
    fi

    # oldrev est à zéro la toute première fois : rien à quoi comparer.
    git rev-parse --quiet --verify "$oldrev^{commit}" >/dev/null || continue

    # Une avance rapide, c'est quand l'ancienne pointe est un ancêtre de la nouvelle.
    if [ "$(git merge-base "$oldrev" "$newrev")" != "$oldrev" ]; then
        echo "Refus d'un push sans avance rapide sur $DEPLOY_BRANCH." >&2
        echo "La branche de déploiement ne va que vers l'avant." >&2
        exit 1
    fi
done
```

Le test du milieu est la définition d'une **avance rapide**, écrite noir sur blanc : un push est une
avance rapide exactement quand l'ancienne pointe est un ancêtre de la nouvelle, et `git merge-base`
est la manière de le demander. Essayez, et Git refuse le push, pour de vrai :

```console
$ git push --force production main
remote: Refus d'un push sans avance rapide sur main.
remote: La branche de déploiement ne va que vers l'avant.
To ssh://you@example.com/srv/mysite/site.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'ssh://you@example.com/srv/mysite/site.git'
```

### Presque zéro interruption : construire ailleurs, puis basculer un lien symbolique

Remarquez que nous ne construisons jamais dans le répertoire que sert le serveur web. Nous
construisons dans `releases/<horodatage>-<sha>/`, puis nous déplaçons un lien symbolique :

```console
ln -sfn "$release/public" /srv/mysite/current.new
mv -Tf /srv/mysite/current.new /srv/mysite/current
```

Pointez nginx sur `/srv/mysite/current` et il sert toujours un site *complet*. Sans la bascule, il
existe une fenêtre — une seconde, dix secondes, une minute pour un gros site Hugo — pendant
laquelle les visiteurs obtiennent la moitié d'un site web.

`ln -sfn` crée le nouveau lien sous un nom temporaire (le `-n` pour qu'il ne suive pas un lien
symbolique existant vers un répertoire), et `mv -T` remplace l'ancien lien par le nouveau en un
seul renommage, qui est atomique sur le système de fichiers.

> :warning:
> `mv -T` appartient aux coreutils GNU, ce que vous avez sur un serveur Linux. Sur un hôte BSD ou
> macOS, `mv` n'a pas de `-T` et déplacera obligeamment votre nouveau lien *à l'intérieur* du
> répertoire que pointe l'ancien, ce qui fait dix minutes de débogage véritablement déroutantes.
> Testez votre bascule une fois, à la main, avant de lui faire confiance.

Ce motif « répertoire de versions plus un lien symbolique `current` » n'est pas de notre invention ;
c'est ce que [Capistrano](https://capistranorb.com/) a popularisé pour les déploiements Ruby au
milieu des années 2000, et c'est toujours la bonne forme. Son autre cadeau est le retour arrière :
la version précédente est toujours là, donc revenir est à un `ln -sfn` de distance — pas de
reconstruction, pas de réseau, instantané.

C'est tout. Un dépôt nu, deux hooks, un lien symbolique. Si vous comprenez cela, vous comprenez
tous les produits de déploiement du marché, parce qu'ils sont tous cela avec une plus jolie
interface.

## Maintenant, les options hébergées

Bien sûr, la plupart du temps, nous ne voulons pas administrer de serveur. Voici ce que font
réellement les options hébergées, et quel est le hic de chacune.

### GitHub Pages

De l'hébergement statique gratuit attaché à votre dépôt, avec deux modèles de publication.

Le modèle **branche** est l'ancien : ce qui se trouve sur la branche `gh-pages` (ou `main`, ou un
dossier `/docs`) est servi. Les outils de construction externes « déploient » en commitant le site
construit sur cette branche. Son charme est que le déploiement est un objet Git que vous pouvez
inspecter et annuler.

Le modèle **Actions** est l'actuel : un workflow construit le site et le téléverse comme artefact
Pages, et rien n'est commité nulle part. C'est ce que vous voulez pour un site Hugo, Astro ou Vite,
et nous en construisons un plus bas.

Les domaines personnalisés fonctionnent : réglez le domaine dans les paramètres du dépôt (ce qui
écrit un fichier `CNAME`), pointez un `CNAME` DNS sur `<utilisateur>.github.io`, et activez HTTPS.

> :warning:
> Le piège du `.nojekyll`. Lors d'une publication depuis une branche, GitHub Pages fait passer vos
> fichiers par Jekyll, et Jekyll ignore tout fichier et tout répertoire dont le nom commence par
> `_` ou `.`. Ainsi un site avec `_assets/app.css` — une sortie parfaitement normale pour beaucoup
> de générateurs — perd sa feuille de style, sans la moindre erreur nulle part. Le remède est un
> fichier vide nommé `.nojekyll` à la racine de la sortie publiée. La moitié des questions
> « pourquoi mon site est-il sans style sur GitHub Pages ? » d'Internet, c'est cela.

### GitLab Pages

Même idée, pilotée par un travail d'intégration continue dont l'artefact est un répertoire
`public/` :

```yaml
# .gitlab-ci.yml
pages:
  stage: deploy
  script:
    - hugo --minify
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Historiquement, le travail devait *s'appeler* `pages` ; les GitLab modernes laissent plutôt
n'importe quel travail y adhérer avec `pages: true`. Le mécanisme vaut d'être remarqué : le
déploiement *est* un artefact d'intégration continue. Rien de neuf n'a été inventé.

### Cloudflare Pages, Netlify, Vercel

Connectez un dépôt, et ils construisent et servent chaque push, sur un CDN mondial, avec des URL de
prévisualisation par branche et des niveaux gratuits généreux. Ils diffèrent par la saveur :
Cloudflare Pages est le plus proche du « statique pur plus des fonctions en périphérie », Netlify a
l'ensemble le plus fourni de greffons de construction et de gestion des redirections, Vercel est
tranché dans la direction de Next.js.

Le hic, dans les trois cas, est le même : la configuration de construction vit en partie dans leur
tableau de bord, et votre DNS comme votre facture appartiennent désormais à un fournisseur dont le
niveau gratuit est une décision commerciale. Gardez la construction reproductible en local —
`make build` — et déménager vous coûtera un après-midi au lieu d'un trimestre.

### Du simple stockage objet plus un CDN

La réponse ennuyeuse et durable : construire le site en intégration continue,
`aws s3 sync ./public s3://mon-bucket --delete`, et servir le bucket via CloudFront, ou
l'équivalent R2 via Cloudflare. Pas de plateforme, pas d'enfermement au-delà de la facture de
stockage, et un mécanisme si simple qu'il marchera encore dans dix ans. C'est ce que font réellement
un très grand nombre de gros sites.

### Ce que fait vraiment « connectez votre dépôt et ça se déploie au push »

Maintenant que nous en avons construit un à la main, la magie s'évapore. Quand vous connectez un
dépôt à un service hébergé, celui-ci :

1. enregistre un **webhook** sur votre dépôt ;
2. reçoit, à chaque push, le triplet `<before>`, `<after>` et référence — les trois mêmes valeurs
   que notre hook `post-receive` lisait sur son entrée standard ;
3. clone le dépôt (en général superficiellement) à ce SHA ;
4. exécute votre commande de construction dans un conteneur ;
5. téléverse le répertoire de sortie vers un CDN et bascule un pointeur.

Les étapes 1 et 2 sont notre hook. L'étape 5 est notre lien symbolique. Il n'y a rien d'autre dans
la boîte.

## Les déploiements de prévisualisation

La seule chose véritablement nouvelle qu'ont apportée les services hébergés, et elle est de taille :
une URL par branche, ou par pull request.

Le mécanisme est exactement ce que vous devineriez maintenant. Construire *toutes* les branches, pas
seulement la branche de déploiement ; publier chaque construction sous son propre nom d'hôte
(`my-feature--mysite.pages.dev`, `deploy-preview-42--mysite.netlify.app`) ; router par nom d'hôte ;
et ramasser les miettes quand la branche est supprimée. Un commentaire avec le lien est publié sur
la pull request.

Cela a changé la revue de code en mieux, et je ne le dis pas à la légère. Relire un changement
d'interface en lisant un diff relève de la devinette. Le relire en cliquant sur un lien et en *le
regardant*, sur une vraie URL que vous pouvez envoyer à une graphiste qui n'a jamais utilisé Git,
est une autre activité. C'est l'argument le plus fort en faveur des options hébergées, et c'est la
raison pour laquelle je ne me battrais pas contre une équipe qui en choisit une.

Vous pouvez construire vos prévisualisations vous-même — notre hook `post-receive` pourrait extraire
chaque branche dans `/srv/mysite/previews/<branche>/` et laisser nginx faire correspondre
`<branche>.preview.example.com` dessus, ce qui fait peut-être quinze lignes de plus — mais vous
ferez aussi les certificats, le nettoyage et les quotas. C'est le point où payer quelqu'un devient
rationnel.

## Concrètement : ce site-ci

Le cours que vous lisez est un site Hugo dans un dépôt Git : un `hugo.toml`, les chapitres sous
`content/docs/`, un thème embarqué, et un `Makefile` dont la cible `make build` est l'unique
commande qui construit le tout. Voici un workflow qui le construit et le publie sur GitHub Pages,
en suivant la structure que recommande la documentation de Hugo elle-même :

```yaml
# .github/workflows/pages.yml
name: Deploy Hugo site to Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write            # autorisé à publier un déploiement Pages
  id-token: write         # jeton OIDC prouvant que c'est ce workflow qui l'a fait

concurrency:
  group: pages
  cancel-in-progress: false   # ne jamais annuler un déploiement à mi-chemin

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      HUGO_VERSION: 0.164.0   # on épingle le générateur, exactement comme une action
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0          # Hugo lit les dates git pour .Lastmod
          # ajoutez "submodules: recursive" si votre thème est un sous-module
          # plutôt qu'embarqué dans le dépôt

      - id: pages
        uses: actions/configure-pages@v6

      - name: Install Hugo
        run: |
          curl -sSL -o hugo.deb \
            "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb"
          sudo dpkg -i hugo.deb

      - name: Build
        # `make build` en local, la même commande ici — voir le chapitre précédent
        run: hugo --gc --minify --baseURL "${{ steps.pages.outputs.base_url }}"

      - uses: actions/upload-pages-artifact@v5
        with:
          path: ./public

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
    steps:
      - id: deployment
        uses: actions/deploy-pages@v5
```

Trois remarques, parce que je préfère que vous compreniez ceci plutôt que de le coller.

`fetch-depth: 0` à nouveau. Hugo peut utiliser la date du commit Git de chaque page comme son
`Lastmod`, et dans un clone superficiel il n'y a pas de dates à utiliser — le piège du clone
superficiel de [L'intégration continue avec Git](2-git-ci.md "L'intégration continue avec Git"),
dans la nature.

`HUGO_VERSION` est épinglée, et elle devrait correspondre à la version avec laquelle vous
construisez en local. Un générateur épinglé, c'est la différence entre un site qui se construit à
l'identique dans trois ans et un site qui casse mystérieusement quand une image de runner change.
(Hugo 0.164.0 est la version courante à l'heure où nous écrivons ; le workflow officiel de Hugo
installe aussi Dart Sass, dont vous n'avez besoin que si votre thème utilise du SCSS.)

Les versions d'actions bougent. Les majeures `actions/*` ci-dessus — `checkout@v7`,
`configure-pages@v6`, `upload-pages-artifact@v5`, `deploy-pages@v5` — sont les versions courantes à
la mi-2026, et pour des actions publiées par GitHub lui-même une étiquette majeure est un compromis
raisonnable. Pour l'action de *quelqu'un d'autre*, épinglez le SHA du commit, pour la raison donnée
au chapitre précédent : les étiquettes bougent, les hachages non.

## Récapitulatif `git init --bare` `post-receive` `pre-receive` `git --work-tree`

* Un site statique est le premier déploiement idéal : le produit de la construction n'est que des
  fichiers, donc chaque étape du mécanisme est visible.
* `git init --bare` crée un dépôt sans arbre de travail — ce qu'utilise tout serveur.
* Un hook `post-receive` reçoit une ligne par référence mise à jour sur son entrée standard :
  `<oldrev> <newrev> <refname>`. Les nouvelles branches arrivent avec `oldrev` à zéro, les
  suppressions avec `newrev` à zéro.
* Préférez `post-receive` à `post-update` parce qu'il vous dit *quels* SHA ont bougé ; utilisez
  `pre-receive` quand vous voulez le pouvoir de dire non.
* `git --work-tree=<rép> checkout -f <branche>` prête un arbre de travail à un dépôt nu — l'astuce
  qui fait fonctionner le déploiement par push.
* Ne déployez que lorsque la branche de déploiement bouge, et rejetez les push sans avance rapide
  en comparant `git merge-base "$oldrev" "$newrev"` à `$oldrev`.
* Construisez dans un répertoire `releases/<horodatage>-<sha>/` tout neuf et basculez un lien
  symbolique `current` de manière atomique (`ln -sfn` + `mv -Tf`). Le retour arrière devient un
  changement de lien symbolique. C'est le motif Capistrano.
* Les options hébergées : **GitHub Pages** (branche ou Actions, attention au `.nojekyll`),
  **GitLab Pages** (un travail dont l'artefact est `public/`), **Cloudflare Pages**, **Netlify**,
  **Vercel**, ou du stockage objet plus un CDN avec `aws s3 sync` depuis l'intégration continue.
* « Connectez votre dépôt et ça se déploie » = un webhook, un clone, une construction, un
  téléversement, une bascule de pointeur.
* Les **déploiements de prévisualisation** — une URL par branche ou par pull request — sont la
  meilleure raison d'utiliser un service hébergé.
