---
title: Le déploiement continu
slug: "git-cd"
weight: 44
---
# Le déploiement continu

Au [chapitre précédent](3-git-static-site.md "Déployer un site statique tout simple"), nous avons
déployé un site en poussant sur une branche, et tout le mécanisme tenait dans un script shell. Les
vraies applications ne sont guère plus difficiles — mais elles nous obligent à être précis sur le
*quand* une version sort, sur *ce qui* exactement sort, et sur ce que nous faisons quand cela
tourne mal.

Ces trois questions ont des réponses Git, et c'est pourquoi ce chapitre a sa place dans un cours
sur Git.

## Trois mots que les gens emploient indifféremment, et qu'il ne faudrait pas

L'**intégration continue** porte sur la ligne principale : chaque changement est fusionné souvent
et la ligne principale est toujours au vert. C'était
[l'avant-dernier chapitre](2-git-ci.md "L'intégration continue avec Git").

La **livraison continue** veut dire que chaque commit vert est *publiable*. L'artefact est
construit, signé, testé et posé dans un registre ; le pipeline jusqu'à la production est automatisé
et répété. La dernière étape est une décision humaine — quelqu'un clique, ou pousse une étiquette.

Le **déploiement continu** veut dire que cette dernière étape a disparu. Commit vert, donc publié.
Pas de bouton.

La distinction n'est pas de la pédanterie, parce que c'est dans l'écart entre les deux que vivent
réellement les organisations. La livraison continue est un accomplissement d'ingénierie : vous
pouvez expédier à tout moment. Le déploiement continu en est un d'organisation : vous avez décidé
que vous *le ferez*. Quantité d'excellentes équipes s'arrêtent délibérément à la livraison, parce
que leurs clients sont des hôpitaux ou des banques et qu'une mise en production est un événement
planifié et annoncé.

Mon avis, puisque ce cours donne des avis : atteignez d'abord la *livraison* continue, toujours.
C'est tout bénéfice — la capacité d'expédier en cinq minutes est exactement ce que vous voulez
pendant un incident, que vous l'exerciez toutes les heures ou non. Retirer ensuite le bouton est
une décision commerciale, pas technique.

## Déclencher une mise en production depuis Git

### Déployer au push sur une branche

Le déclencheur le plus simple, et celui que nous avons déjà construit : quelque chose surveille une
branche, et chaque commit qui y atterrit est déployé. Parfait pour les environnements de
préproduction et pour les sites statiques.

### Déployer sur étiquette

L'autre déclencheur, et le meilleur pour tout ce que voit un client :

```console
git tag -a v1.2.3 -m 'Release 1.2.3'
git push --follow-tags
```

L'intégration continue écoute `refs/tags/v*` et prend le relais. Chez GitHub Actions :

```yaml
on:
  push:
    tags: ['v*.*.*']
```

Voici l'opinion, et elle est tranchée : **les étiquettes sont le bon déclencheur pour tout ce que
voit un client**, parce qu'une étiquette est une décision délibérée, nommée et immuable, tandis que
la pointe d'une branche n'est que ce qui a atterri en dernier. « Version 1.2.3 » est une phrase
qu'un humain a choisi de prononcer. « La pointe actuelle de `main` » est un accident d'ordre de
fusion que personne n'a validé. Quand on vous demande à 2 h du matin ce qu'il y a en production,
`v1.2.3` est une réponse ; « ce qui était sur main vers six heures » n'en est pas une.

> :information_source:
> `git push --follow-tags` pousse vos commits plus les étiquettes **annotées** qui y mènent — et
> délibérément pas les étiquettes légères. Voilà une bonne raison de plus d'utiliser `git tag -a` :
> les étiquettes annotées sont des objets dotés d'un auteur, d'une date et d'un message (et
> peuvent être signées avec `-s`), et ce sont elles qui voyagent. J'ai testé ceci en écrivant le
> chapitre : une étiquette légère `git tag lw-1` est silencieusement laissée en arrière par
> `--follow-tags`, ce qui est exactement le genre de chose qui gâche un après-midi.

### Branches d'environnement, promotion par étiquette, ou promotion de l'artefact

Trois formes, par ordre croissant de ma préférence.

**Les branches d'environnement.** `main` déploie en préproduction, et une branche `production`
déploie en production ; promouvoir consiste à fusionner ou à faire avancer `main` dans
`production`. C'est facile à comprendre et facile à voir (`git log production..main` est
littéralement « ce qui attend de partir en ligne »). Son défaut est que les deux branches peuvent
réellement diverger, et vous avez alors un conflit de fusion entre vous et une mise en production.

**La promotion par étiquette.** Une seule branche, et les mises en production sont des étiquettes.
`v1.2.3` déploie en préproduction ; `v1.2.3-prod`, ou une GitHub Release marquée comme non
préliminaire, ou une approbation manuelle sur la même étiquette, part en production. Moins de
références mobiles, pas de divergence.

**Promouvoir l'artefact, ne pas le reconstruire.** Construire l'image de conteneur *une fois*,
depuis un commit, et promouvoir *cette image exacte* — par empreinte, `sha256:…`, pas par
étiquette — de la préproduction à la production. C'est celle qu'il faut viser.

Pourquoi ? Parce que reconstruire par environnement est un bogue de reproductibilité déguisé. Deux
constructions du même commit ne sont pas garanties d'être les mêmes octets : une image de base a
bougé, une dépendance transitive a publié un correctif, un miroir a servi un fichier différent, la
construction a tourné sur un runner avec une autre chaîne d'outils. Si la préproduction et la
production font tourner des *octets différents*, alors tester en préproduction a prouvé quelque
chose sur un programme qui n'est pas en production. Construisez une fois, testez cette chose,
expédiez cette chose.

## Estampiller la version dans l'artefact

Petite habitude, bénéfice énorme. Toute chose déployée devrait pouvoir vous dire de quel commit
elle est.

```console
$ git describe --tags --always --dirty
v1.1.0-1-g1b81782
```

Cette sortie, venue d'un vrai dépôt, se lit : un commit après l'étiquette `v1.1.0`, au commit
`1b81782` (le `g` est pour « git »). Ajoutez `--dirty` et une modification non commitée ajoute
`-dirty`, ce qui est la manière dont un script de construction vous dit qu'il construit quelque
chose qui n'existe nulle part dans l'historique :

```console
$ git describe --tags --always --dirty
v1.1.0-1-g1b81782-dirty
```

`--always` le fait se rabattre sur un SHA nu quand il n'y a pas d'étiquette du tout, si bien que la
commande n'échoue jamais dans un dépôt tout neuf.

Cuisez cette chaîne, plus le SHA complet du commit et l'heure de construction, dans l'artefact —
une variable `ldflags` en Go, un fichier `VERSION` dans l'image, un argument de construction, une
variable d'environnement — et exposez-la sur un point d'accès ennuyeux :

```console
$ curl -s https://example.com/version
{"version":"v1.1.0-1-g1b81782","commit":"1b81782f4c…","built":"2026-07-29T21:36:22Z"}
```

Pendant un incident, ce seul point d'accès fait s'effondrer toute une catégorie de confusion. « Le
correctif est-il déployé ? » cesse d'être une conversation et devient un `curl`. Et parce que le SHA
est dérivé du contenu, vous pouvez le passer à `git show` et voir *exactement* ce qui tourne, ce
qu'aucun numéro de version seul ne peut promettre.

> :warning:
> L'estampillage de version est la première victime du clone superficiel. Dans un travail
> `fetch-depth: 1` il n'y a pas d'étiquettes, donc `git describe --tags --always` affiche
> gaiement un SHA nu et sort avec un code zéro. Votre version est estampillée `1b81782` au lieu de
> `v1.1.0`, et personne ne le remarque avant que cela ne compte.

## Laisser les messages de commit piloter le numéro de version

Si vos messages de commit suivent une convention, une machine peut calculer la version pour vous.
La dominante est Conventional Commits : `feat: …`, `fix: …`, `chore: …`, et `feat!:` ou une ligne
`BREAKING CHANGE:` pour les changements incompatibles.

Le mécanisme est assez simple pour que vous puissiez l'écrire vous-même, et il mérite d'être compris
plutôt que traité comme de la magie. L'outil :

1. trouve l'étiquette de version la plus récente ;
2. lit tous les messages de commit depuis cette étiquette ;
3. les transforme en incrément — un `fix` est un correctif, un `feat` est une version mineure, un
   changement incompatible est une version majeure ;
4. écrit ou complète `CHANGELOG.md` à partir des sujets qu'il vient d'analyser ;
5. crée la nouvelle étiquette (et en général une GitHub Release), qui déclenche alors le
   déploiement que nous avons mis en place plus haut.

`semantic-release` fait cela de bout en bout à chaque push. `release-please` maintient plutôt une
« PR de version » permanente qui accumule le journal des changements, de sorte qu'un humain la
fusionne encore — un joli compromis entre l'automatisation et le consentement. `changesets` inverse
le tout : les contributeurs écrivent un petit fichier de changeset décrivant l'impact de leur
changement, ce qui convient aux monorepos publiant de nombreux paquets.

Et le compromis, honnêtement : cela met de la *structure lisible par une machine* dans des messages
de commit *humains*. Vous obtenez le versionnement et les journaux de changements gratuitement, et
vous payez en n'écrivant plus jamais un sujet de commit d'une voix naturelle — sans compter qu'un
titre de pull request écrasée décide désormais silencieusement de votre numéro de version. Que ce
soit un bon échange dépend de la valeur que vous accordez au journal des changements. Sur une
bibliothèque à des milliers d'utilisateurs : évidemment oui. Sur un service interne qui déploie
quarante fois par jour : probablement pas.

## Des journaux de changements tirés de l'historique

Même sans versionnement automatisé, votre historique est un journal des changements si vous le lui
demandez gentiment :

```console
$ git log --pretty='* %s (%h)' v1.0.0..v1.1.0
* feat: add the other thing (efacf84)
* fix: correct the thing (b37d565)
```

C'est une vraie sortie. `v1.0.0..v1.1.0` est la syntaxe de plage vue dans
[Jouer avec nos révisions](../1-understanding-git/7-play-with-git-revisions.md "Jouer avec nos révisions") ;
`%s` est le sujet et `%h` le SHA abrégé. Ajoutez `--no-merges` pour écarter les commits de fusion et
vous avez quelque chose que vous pouvez coller dans une note de version.

[`git-cliff`](https://git-cliff.org/) est la version polie de cette idée : un générateur de journal
des changements configurable qui lit les Conventional Commits dans votre historique et les regroupe
en sections. Il ne change rien à votre dépôt, ce qui le rend très facile à adopter et très facile à
abandonner.

## Le retour arrière, honnêtement

Deux choses différentes portent ce nom, et les confondre coûte de l'indisponibilité.

**Redéployer l'artefact précédent.** L'image de la dernière version est toujours dans le registre,
donc vous repointez la production sur cette empreinte. Quelques secondes. Pas de construction, pas
de tests à relancer, pas de risque d'embarquer quelque chose de neuf. C'est le retour arrière
*rapide*, et pendant un incident c'est le bon geste.

**Revenir sur le commit.** `git revert <sha>` crée un *nouveau* commit qui défait le changement, et
qui traverse la relecture, l'intégration continue et le déploiement comme n'importe quel autre
changement. Des minutes plutôt que des secondes — et c'est le retour arrière *auditable* :
l'historique enregistre que nous avons expédié le changement, puis que nous l'avons délibérément
repris, et la personne suivante qui déploie ne ressuscite pas le bogue par accident.

Les installations matures font les deux, dans cet ordre : basculer l'empreinte pour arrêter
l'hémorragie, puis revenir sur le commit pour que le dépôt cesse d'être en désaccord avec la
production. Si vous ne faites jamais que le premier, votre prochain déploiement republie le bogue.
Si vous ne faites jamais que le second, votre panne dure aussi longtemps que votre pipeline.

> :information_source:
> C'est aussi pourquoi `git revert` et non `git reset` sur une branche partagée : revenir ajoute de
> l'historique, réinitialiser le réécrit, et la branche depuis laquelle tout le monde déploie est le
> dernier endroit où l'on veut réécrire. Nous l'avons longuement argumenté dans
> [Garder un historique propre, se remettre de ses erreurs](../2-collaborating/6-git-cleanup.md "Garder un historique propre, se remettre de ses erreurs").

## Et puis les bases de données arrivent et gâchent tout

Tout ce qui précède suppose que déployer, c'est remplacer une chose sans état par une autre chose
sans état. Ajoutez une base de données et le modèle bien rangé se brise, parce qu'on ne peut pas
revenir sur une migration comme on revient sur un fichier.

Les pratiques qui survivent au contact de la réalité :

* **Des migrations qui ne vont que vers l'avant.** N'écrivez pas de migrations `down` que vous ne
  testez jamais — elles vous bercent de l'illusion que le retour arrière existe. Si une migration
  était fausse, le remède est une autre migration.
* **Étendre puis contracter** (aussi appelé changement parallèle). Pour renommer une colonne :
  ajouter la nouvelle colonne et écrire dans les deux (étendre) ; migrer les lecteurs ; remplir
  rétroactivement ; et seulement lors d'une version *ultérieure*, une fois qu'aucune version
  déployée ne lit plus l'ancienne colonne, la supprimer (contracter). Trois mises en production
  ennuyeuses au lieu d'une excitante, et à chaque instant entre les deux, l'ancien et le nouveau
  code fonctionnent — ce qui est précisément ce qui rend le retour arrière possible.
* **Séparer le changement de schéma du changement de code.** Un déploiement qui expédie les deux
  d'un coup ne peut être annulé que d'un bloc, c'est-à-dire pas du tout.

Et disons la chose honnête à voix haute : *« il n'y a qu'à revenir en arrière »* est un mensonge dès
qu'il y a de l'état. Revenir sur le commit qui a ajouté la migration ne dé-ajoute pas la colonne, ne
restaure pas les lignes que la migration a réécrites, et ne dé-envoie pas les douze mille courriels
que votre nouvelle fonctionnalité a expédiés avant que vous ne le remarquiez. Un revert restaure du
*code*. Rien ne restaure les *conséquences*.

## Les stratégies de déploiement, brièvement

* **Bleu/vert.** Deux environnements identiques ; on déploie sur celui qui dort, on le teste, on
  bascule le répartiteur de charge. Le retour arrière consiste à rebasculer. Coûteux (tout en
  double) et merveilleusement simple.
* **Progressif.** Remplacer les instances quelques-unes à la fois. Ce que fait Kubernetes par
  défaut. Peu coûteux ; exige que deux versions puissent coexister quelques minutes, ce qui nous
  ramène droit à étendre/contracter.
* **Canari.** Envoyer 1 % du trafic vers la nouvelle version, observer, puis 10 %, puis tout. Le
  meilleur attrapeur de bogues des trois, parce que ce sont vos vrais utilisateurs qui le testent
  et que seuls quelques-uns en souffrent.
* **Les drapeaux de fonctionnalité.** Expédier le code inerte, activer le comportement plus tard —
  pour les utilisateurs internes d'abord, puis pour un pourcentage, puis pour tout le monde.

Ce dernier mérite l'accent, parce que c'est celui qui a une conséquence Git : **les drapeaux de
fonctionnalité découplent le déploiement de la mise en production.** Avec un drapeau, fusionner dans
`main` ne veut plus dire « les clients voient ceci », donc il n'y a plus de raison de garder une
branche en vie pendant trois semaines en attendant qu'une fonctionnalité soit finie. C'est la pièce
manquante qui rend le développement sur tronc commun praticable, et c'est pourquoi la discussion sur
les modèles de branches dans
[Un peu de structure SVP](../2-collaborating/4-git-repo-structure.md "Un peu de structure SVP")
finit par être une discussion sur les drapeaux. Le coût est réel, cependant : chaque drapeau est une
bifurcation dans votre code et une explosion combinatoire de ce que « testé » veut dire. Les
drapeaux sont une dette avec un taux d'intérêt — supprimez-les dès que la fonctionnalité est
inconditionnelle.

## La livraison progressive et les portes d'observabilité

La conclusion naturelle du canari est de laisser la *supervision* décider. Le contrôleur de
déploiement déplace un peu de trafic, observe votre taux d'erreurs, vos percentiles de latence ou
votre vitesse de consommation de SLO pendant quelques minutes, et soit avance, soit revient en
arrière automatiquement. Argo Rollouts et Flagger font exactement cela pour Kubernetes, en pilotant
l'analyse à partir de requêtes Prometheus.

C'est une jolie idée et elle fonctionne, à une condition : vos métriques doivent être assez bonnes
pour qu'on parie une mise en production dessus. Si personne ne fait confiance au tableau de bord,
une porte automatisée n'est qu'un déploiement plus lent avec des étapes en plus.

## Où vivent les identifiants

Maintenant la question inconfortable. Pour déployer depuis l'intégration continue, le système
d'intégration continue a besoin du pouvoir de changer la production. Historiquement cela voulait
dire un secret de longue durée — une clé d'accès AWS, un `kubeconfig`, une clé SSH — collé dans les
variables d'intégration continue du dépôt, où il est resté trois ans, lisible par tous les
workflows, y compris celui qui exécute une action tierce venue d'un fork.

La réponse moderne est la **fédération OIDC**, et c'est une véritable amélioration plutôt qu'une
mode. La plateforme d'intégration continue joue le rôle de fournisseur d'identité OpenID Connect.
Votre workflow lui demande un jeton de courte durée, signé cryptographiquement, qui énonce des
faits vérifiables : ce jeton a été émis pour le dépôt `vous/votre-projet`, pour le workflow à
`refs/tags/v1.2.3`, dans l'environnement `production`. Le fournisseur de cloud est configuré pour
faire confiance à cet émetteur, pour vérifier ces affirmations, et pour rendre des identifiants qui
expirent dans une heure.

Ce que cela vous apporte :

* **Aucun secret de longue durée n'existe.** Il n'y a rien à voler dans vos variables d'intégration
  continue, et rien à faire tourner.
* **La confiance est limitée à une référence.** Vous pouvez n'autoriser le déploiement en
  production que depuis des étiquettes correspondant à `v*`, imposé par le fournisseur de cloud et
  non par votre YAML.
* **Chaque déploiement est attribuable** à un dépôt, un workflow et un commit, parce que ces faits
  sont à l'intérieur du jeton signé.

Chez GitHub Actions cela fait deux lignes de permissions et une étape :

```yaml
permissions:
  id-token: write     # autorisé à demander un jeton OIDC
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v6
    with:
      role-to-assume: arn:aws:iam::123456789012:role/deploy-production
      aws-region: eu-west-1
```

Remarquez comme cela découle directement de l'argument push contre pull du chapitre
[GitOps](1-git-ops.md "GitOps"). Nous ne pouvons pas faire disparaître l'identifiant de production
dans un modèle push — quelque chose à l'extérieur doit pouvoir tendre le bras vers l'intérieur —
mais nous *pouvons* le rendre de courte durée, étroitement limité et impossible à voler sur une
page de variables. C'est la meilleure réponse disponible pour un déploiement en push, et c'est
pourquoi l'argument de sécurité du camp GitOps, tout en restant vrai, est nettement moins
dramatique qu'en 2018.

## Un exemple travaillé : étiqueter, construire, estampiller, déployer

Tout le chapitre réuni. Pousser `v1.2.3` construit une image de conteneur, l'étiquette à la fois
avec la version *et* avec le SHA du commit, et la déploie **par empreinte**.

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags: ['v*.*.*']

permissions:
  contents: read
  packages: write     # pousser vers le registre de conteneurs de GitHub
  id-token: write     # OIDC, pour le travail de déploiement

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0        # il nous faut les étiquettes pour git describe

      - id: version
        run: echo "value=$(git describe --tags --always --dirty)" >> "$GITHUB_OUTPUT"

      - uses: docker/setup-buildx-action@v4

      - uses: docker/login-action@v4
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # Calcule les étiquettes d'image pour nous : le semver de l'étiquette git, plus le SHA.
      - id: meta
        uses: docker/metadata-action@v6
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=semver,pattern={{version}}
            type=sha,format=long

      - id: build
        uses: docker/build-push-action@v7
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          build-args: |
            GIT_SHA=${{ github.sha }}
            VERSION=${{ steps.version.outputs.value }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production     # une approbation obligatoire peut s'y accrocher
    steps:
      - uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: arn:aws:iam::123456789012:role/deploy-production
          aws-region: eu-west-1

      # Déployer les octets exacts qu'on vient de construire, par empreinte —
      # jamais par une étiquette mutable.
      - run: |
          ./deploy.sh "ghcr.io/${{ github.repository }}@${{ needs.build.outputs.digest }}"
```

Trois détails portent tout l'argument. `fetch-depth: 0`, sinon `git describe` ment. L'image est
étiquetée avec la version *et* le SHA long, de sorte que vous pouvez toujours remonter d'un
conteneur en cours d'exécution jusqu'à un commit. Et le travail de déploiement consomme
`needs.build.outputs.digest` — l'adresse de contenu immuable de l'image — plutôt que de re-résoudre
`:v1.2.3`, que quelqu'un pourrait écraser demain.

> :warning:
> Les versions d'actions bougent. Les majeures ci-dessus (`checkout@v7`, `setup-buildx-action@v4`,
> `login-action@v4`, `metadata-action@v6`, `build-push-action@v7`,
> `configure-aws-credentials@v6`) sont les versions courantes à la mi-2026 — vérifiez, et épinglez
> les actions tierces à un SHA de commit plutôt qu'à une étiquette, pour la raison donnée dans
> [L'intégration continue avec Git](2-git-ci.md "L'intégration continue avec Git").

## Et dans l'autre sens

Tout ce chapitre est du **push** : notre intégration continue tend le bras vers la production et la
modifie. Lisez-le à côté de [GitOps](1-git-ops.md "GitOps"), qui est le même travail fait à
l'envers — une étiquette atterrit, un agent à l'intérieur du cluster le remarque, et il tire le
changement. La mécanique Git est identique, et seuls le sens de la flèche, et donc l'identité de
qui détient les clés, diffèrent.

## Récapitulatif `git tag -a` `git push --follow-tags` `git describe` `git revert`

* La **livraison continue** veut dire que chaque commit vert est publiable ; le **déploiement
  continu** veut dire qu'il est effectivement publié. Atteignez d'abord la livraison — c'est tout
  bénéfice.
* Déployez au push sur une branche pour la préproduction ; déployez sur **étiquette** pour tout ce
  que voit un client, parce qu'une étiquette est une décision délibérée, nommée et immuable.
* `git tag -a v1.2.3 -m '…'` puis `git push --follow-tags` ; l'intégration continue se déclenche sur
  `refs/tags/v*`. `--follow-tags` ne pousse que les étiquettes annotées.
* Préférez **promouvoir l'artefact** (la même empreinte d'image à travers tous les environnements)
  aux branches d'environnement ou aux reconstructions par environnement. Reconstruire par
  environnement est un bogue de reproductibilité.
* Estampillez `git describe --tags --always --dirty` et le SHA complet du commit dans chaque
  artefact, et exposez-les sur `/version`. Les clones superficiels cassent cela silencieusement.
* Les Conventional Commits plus `semantic-release`, `release-please` ou `changesets` calculent
  l'incrément de version, le journal des changements et l'étiquette à partir des messages de commit
  depuis la dernière étiquette — au prix de sujets de commit lisibles par une machine.
* Des journaux de changements tirés de l'historique : `git log --pretty='* %s (%h)' v1.0.0..v1.1.0`,
  ou `git-cliff`.
* Le retour arrière : redéployer l'artefact précédent est le retour arrière *rapide*, `git revert`
  est le retour arrière *auditable*. Faites les deux, dans cet ordre.
* Les bases de données brisent le modèle : des migrations vers l'avant seulement, étendre/contracter,
  et ne croyez jamais qu'un revert défait les conséquences.
* Bleu/vert, progressif, canari, et les **drapeaux de fonctionnalité** — qui découplent le
  déploiement de la mise en production et rendent le développement sur tronc commun praticable.
* La livraison progressive laisse la supervision décider, avec un retour arrière automatique en cas
  de dépassement de SLO.
* Utilisez la **fédération OIDC** (`id-token: write`) plutôt que des identifiants cloud de longue
  durée dans les variables d'intégration continue.
