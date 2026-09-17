---
title: GitOps
slug: "git-ops"
weight: 41
---
# GitOps

Nous avons passé quatre parties de ce cours à apprendre ce qu'est réellement Git : une base de
données adressée par le contenu, faite de **commits**, d'**arbres** et de **blobs**, avec
quelques références mobiles qui pointent dedans. Nous savons maintenant créer des branches,
fusionner, rebaser, pousser, étiqueter et nous rattraper. Cette dernière partie porte sur ce qui
se passe quand on pointe tout cela vers des *machines* plutôt que vers des collègues.

Et la première idée dont nous avons besoin est celle qui porte un nom marketing : le **GitOps**.

## L'idée, en une phrase

Le dépôt Git contient l'*état désiré* d'un système, et un agent automatisé fait continuellement
en sorte que la réalité lui ressemble.

C'est tout. Lisez-la deux fois, parce que tout le reste de ce chapitre en découle.

Remarquez ce qui n'est *pas* dans cette phrase. Il n'y a pas de « et ensuite quelqu'un lance le
script de déploiement ». Il n'y a pas d'humain dans la boucle au moment du changement. Le travail
de l'humain est de modifier le dépôt — le travail de l'agent est de le remarquer, et de
converger. Si la réalité s'écarte du dépôt, l'agent la ramène.

## Les quatre principes

Le mot a été forgé en 2017 chez Weaveworks — le billet d'Alexis Richardson *GitOps — Operations by
Pull Request* est le récit des origines — et il a ensuite reçu une définition propre et neutre de
tout éditeur par le projet [OpenGitOps](https://opengitops.dev/), qui vit dans le GitOps Working
Group du TAG App Delivery de la CNCF. Les principes GitOps actuels sont en version 1.0.0, et ils
se lisent ainsi :

1. **Déclaratif** — « Un système géré par GitOps doit avoir son état désiré exprimé de manière
   déclarative. »
2. **Versionné et immuable** — « L'état désiré est stocké d'une manière qui impose l'immuabilité,
   le versionnement, et qui conserve un historique complet des versions. »
3. **Tiré automatiquement** — « Des agents logiciels tirent automatiquement les déclarations
   d'état désiré depuis la source. »
4. **Réconcilié en continu** — « Des agents logiciels observent continuellement l'état réel du
   système et tentent d'y appliquer l'état désiré. »

> :information_source:
> Remarquez que les principes ne prononcent jamais le mot « Git ». Ils disent « une manière qui
> impose l'immuabilité, le versionnement, et qui conserve un historique complet des versions » —
> ce qui est une description de Git écrite par des gens qui ne voulaient pas le nommer. En
> pratique, tout le monde utilise Git.

## Pourquoi Git, dans le vocabulaire que nous avons déjà

Voici la version honnête de l'argumentaire, dans les mots de ce cours.

Un **commit** est un enregistrement immuable de *qui* a changé l'état désiré, *quand*, et — si le
message de commit vaut quelque chose — *pourquoi*. Il peut être signé, donc nous pouvons aussi le
prouver. Une **étiquette** nomme une version. Un revert est un retour en arrière. Une pull request
est un processus de gestion du changement, avec relecture et approbation, que nous avons déjà et
que nous savons déjà utiliser.

C'est une remarquablement bonne histoire d'audit pour un système de production, et nous l'avons
eue gratuitement, parce que nous allions utiliser Git de toute façon.

Alors soyons un peu irrévérencieux : le GitOps est surtout un renommage de « gardez votre
configuration sous gestion de version et automatisez l'application ». Les administrateurs système
en font des variantes depuis trente ans. Rien dans les quatre principes n'aurait surpris quiconque
faisait tourner Puppet en 2010.

Mais le renommage a été *utile*, et je le dis en étant allergique aux renommages. Il a rendu
explicites deux choses qui relevaient auparavant de l'accident :

* le modèle **pull** — la machine va chercher sa propre configuration, plutôt qu'un serveur de
  build qui tend le bras pour la pousser ;
* la **boucle de réconciliation** — l'application n'est pas un événement qui a eu lieu une fois
  mardi, c'est une boucle qui tourne indéfiniment.

Ces deux idées valaient un nom.

## Push contre pull

Dans un déploiement en **push**, le système d'intégration continue détient les identifiants de la
production et y enfourne le nouvel état : `kubectl apply`, `ssh prod 'systemctl restart …'`,
`aws s3 sync`, `terraform apply`.

Dans un déploiement en **pull**, quelque chose *à l'intérieur* de la production surveille le dépôt
et applique ce qu'il y trouve. Rien à l'extérieur n'a besoin d'une clé de l'intérieur.

L'argument de sécurité est le plus fort, et il vaut d'être énoncé sans détour. Dans le modèle
push, votre runner d'intégration continue est une machine qui peut déployer en production, qui
exécute du code venu de toutes les branches que chacun pousse, qui exécute des greffons tiers
téléchargés à l'exécution, et dont la moitié de l'entreprise peut lire les journaux. C'est la
cible la plus appétissante de votre infrastructure. Dans le modèle pull, il n'y a aucun
identifiant de production dans l'intégration continue : quelque chose dans le cluster a un accès
en lecture à un dépôt Git, et c'est là toute la relation de confiance.

Le sens de la flèche est ce qui compte. Des lectures sortantes depuis la production sont bien plus
faciles à défendre que des écritures entrantes vers la production.

> :information_source:
> Le push n'est pas diabolique, et nous allons passer les trois prochains chapitres à pousser
> joyeusement. Pour un petit projet, une clé de déploiement et un webhook font parfaitement
> l'affaire. Mais quand quelqu'un demande « pourquoi ferais-je tourner un agent au lieu d'appeler
> simplement `kubectl apply` depuis l'intégration continue ? », la réponse est le paragraphe
> ci-dessus.

## La dérive, et ce que « réconcilié en continu » nous apporte

Trois heures du matin. Le site est à terre. Quelqu'un lance `kubectl edit deployment/api` et
augmente la limite de mémoire. Le site revient. Tout le monde retourne se coucher.

Le dépôt dit maintenant une chose et la production en dit une autre. C'est la **dérive**, et tout
système qui n'applique sa configuration que lorsqu'un humain le lui demande dérivera,
silencieusement, pour toujours. Six semaines plus tard, quelqu'un déploie un changement sans
rapport, la limite de mémoire revient à ce que le dépôt a toujours dit, le site retombe, et
personne ne comprend pourquoi.

Une boucle de réconciliation bouche ce trou. Toutes les quelques minutes, l'agent compare l'état
désiré à l'état réel, puis fait l'une de ces deux choses :

* **Auto-guérison** : le remettre en place. La modification de 3 h du matin est défaite en quelques
  minutes, ce qui est brutal mais au moins honnête — le dépôt est la vérité, et si vous voulez
  changer la limite de mémoire, vous changez le dépôt.
* **Alerte** : signaler la divergence et ne pas y toucher.

Les deux sont légitimes ; Argo CD, par exemple, vous laisse choisir par application. Mon avis :
activez l'auto-guérison partout où vous le pouvez, parce qu'un système qui tolère la dérive est un
système qui vous ment. Et faites en sorte que le chemin d'urgence soit un commit d'une ligne plutôt
qu'un `kubectl edit`, pour que personne ne soit puni d'avoir fait la bonne chose à 3 h du matin.

## Les outils qui font réellement cela

**Kubernetes.** [Argo CD](https://argo-cd.readthedocs.io/) et [Flux](https://fluxcd.io/) sont les
deux implémentations adultes — toutes deux projets diplômés de la CNCF, Flux en novembre 2022 et
Argo une semaine plus tard, en décembre 2022. Toutes deux tournent *à l'intérieur* du cluster,
surveillent un ou plusieurs dépôts Git, et réconcilient des manifestes. Argo CD met en avant une
interface et un modèle « voici votre application, voici son état de synchronisation » ; Flux met
en avant un ensemble de contrôleurs composables et pas d'interface digne de ce nom. Prenez l'un ou
l'autre. Ne faites pas tourner les deux.

**L'infrastructure.** Terraform, ou son fork [OpenTofu](https://opentofu.org/), avec le plan
publié sur la pull request. [Atlantis](https://www.runatlantis.io/) est la manière auto-hébergée
classique de faire cela : il commente le `plan` sur la PR et lance l'`apply` quand un relecteur
répond en commentaire. Terraform Cloud et ses concurrents vendent la même forme en tant que
service. Sachez que celui-ci n'est *pas* une véritable boucle de réconciliation à moins de faire
aussi tourner une détection de dérive à intervalles réguliers — un Terraform ordinaire ne converge
que lorsqu'on le lui demande.

**Ansible**, tiré plutôt que poussé : `ansible-pull` clone un dépôt sur l'hôte géré et y exécute un
playbook, depuis cron. Ancien, sans glamour, et exactement les quatre principes.

**Nix et NixOS.** Voilà l'histoire GitOps la plus sous-estimée. Toute la configuration d'une
machine NixOS — paquets, services, noyau, utilisateurs — est une expression déclarative, et
`nixos-rebuild switch --flake github:vous/config#monhote` réconcilie la machine avec le flake à ce
commit, `flake.lock` épinglant chaque entrée à un hachage exact. Déclaratif, versionné, immuable,
tiré. Le modèle de Nix est un cousin de celui de Git — voir
[Ce que Git a inspiré](../4-beyond-the-basics/6-inspired-by-git.md "Ce que Git a inspiré") — et si
vous avez déjà eu envie de faire un `git revert` sur un système d'exploitation, c'est ainsi qu'on
s'y prend.

**Les opérateurs Kubernetes** en général sont des boucles de réconciliation. Le GitOps est ce
qu'on obtient quand l'entrée de la boucle se trouve vivre dans un dépôt.

### Du GitOps pour un seul petit serveur

Vous n'avez pas besoin d'un cluster. Voici une installation GitOps complète et honnête pour une
seule machine, que vous pourriez construire cet après-midi.

D'abord un script de réconciliation qui ne fait strictement rien à moins que la branche amont
n'ait réellement bougé :

```sh
#!/bin/sh
# /usr/local/bin/reconcile
set -eu

cd /srv/myapp
git fetch --quiet origin

if [ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ]; then
    exit 0                     # déjà dans l'état désiré, rien à faire
fi

git merge --ff-only '@{u}'     # refuser tout ce qui n'est pas une avance rapide
make deploy
```

> :information_source:
> `@{u}` veut dire « l'amont de la branche courante » — en général `origin/main`. Bon à savoir :
> `git rev-parse --abbrev-ref '@{u}'` vous dit quel est le vôtre. Et `--ff-only` est à lui seul
> tout le modèle de sécurité ici : si l'historique a été réécrit en amont, la réconciliation
> *échoue* au lieu de faire silencieusement quelque chose de créatif sur une machine de
> production.

Puis un minuteur `systemd` pour le lancer toutes les cinq minutes :

```ini
# /etc/systemd/system/reconcile.service
[Unit]
Description=Reconcile /srv/myapp with its Git repository

[Service]
Type=oneshot
ExecStart=/usr/local/bin/reconcile
```

```ini
# /etc/systemd/system/reconcile.timer
[Unit]
Description=Reconcile every five minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

`systemctl enable --now reconcile.timer`, et c'est fini. Voilà un déploiement en mode pull,
réconcilié en continu, avec une piste d'audit complète, en une vingtaine de lignes, sans aucun
identifiant de production stocké ailleurs que sur la machine. Quiconque vous dit que le GitOps
exige Kubernetes a quelque chose à vous vendre.

## Comment disposer les dépôts

C'est là que les équipes se disputent, alors voici les choix et ce que chacun coûte.

**Un dépôt ou deux ?** Les sources de l'application dans un dépôt, la configuration de déploiement
dans un autre : c'est la recommandation dominante, et la raison en est délicieusement concrète. Si
l'intégration continue construit une image puis commite la nouvelle étiquette d'image dans le
*même* dépôt que celui qui l'a déclenchée, ce commit déclenche l'intégration continue, qui
construit une image, qui commite une étiquette… félicitations, nous avons construit une machine
qui transforme l'électricité en rien.

Deux issues, et en général on veut les deux :

* Mettre `[skip ci]` dans le message du commit automatisé. GitHub Actions honore `[skip ci]`,
  `[ci skip]`, `[no ci]`, `[skip actions]` et `[actions skip]` — mais seulement pour les
  événements `push` et `pull_request`, pas pour `pull_request_target`. GitLab honore `[skip ci]`
  également.
* Utiliser des filtres de chemins, pour qu'un changement sous `deploy/` ne déclenche jamais le
  travail de construction en premier lieu.

Séparer les dépôts rend la boucle structurellement impossible plutôt que simplement déconseillée,
et c'est pourquoi les gens le font.

**Un dépôt par environnement, ou un répertoire par environnement ?** Un répertoire par
environnement (`envs/staging/`, `envs/production/`) est plus facile à diffuser et plus facile à
promouvoir : une promotion est un commit qui copie un numéro de version d'un répertoire à l'autre,
et vous pouvez *voir* en quoi la préproduction et la production diffèrent avec un seul `git diff`.
Un dépôt par environnement offre un contrôle d'accès plus strict — seuls les responsables de
version peuvent pousser sur le dépôt de production — au prix de ne jamais être tout à fait sûr de
ce qui distingue les deux. Commencez par des répertoires.

**Et le même manifeste pour trois environnements ?** Ne le collez pas trois fois. Utilisez des
surcouches : une base Kustomize plus des correctifs par environnement, ou une chart Helm plus
trois fichiers `values`. La règle empirique est que la *différence* entre environnements devrait
être un petit fichier lisible, et que tout le reste devrait être partagé.

## Les secrets, la partie inconfortable

Vous ne pouvez pas commiter de secrets en clair, et le GitOps veut tout dans le dépôt. Cette
tension est réelle, et quiconque l'escamote n'est pas franc avec vous. Quatre réponses honnêtes :

* **Sealed Secrets** — vous chiffrez une valeur avec la clé publique d'un contrôleur qui tourne
  dans le cluster ; le `SealedSecret` obtenu peut être commité sans danger, et seul ce cluster-là
  peut le déchiffrer. Simple, et lié à un cluster par construction.
* **SOPS avec age ou un KMS de fournisseur** — ne chiffre que les *valeurs* d'un fichier YAML, en
  laissant les clés et la structure lisibles, de sorte qu'un `git diff` vous dit encore quelque
  chose. Le déchiffrement a lieu au moment de l'application ; Flux l'intègre directement.
* **External Secrets Operator** — ne commiter qu'une *référence* : « le mot de passe de la base de
  données vit à ce chemin dans Vault ». L'opérateur va chercher la vraie valeur et matérialise le
  secret dans le cluster. Le secret ne touche jamais Git. C'est le modèle qui passe le mieux à
  l'échelle entre plusieurs équipes.
* **git-crypt** — chiffrement de fichiers transparent au niveau de Git, piloté par
  `.gitattributes`. Charmant, simple, et il ne résout pas la rotation des clés.

> :warning:
> Un secret commité une fois est commité pour toujours. Réécrire l'historique ne dé-envoie pas les
> fetches que votre collègue, votre cache d'intégration continue et trois forks ont déjà faits. Si
> un identifiant vivant atterrit dans un dépôt, la *première* action est toujours de faire tourner
> l'identifiant ; nettoyer l'historique arrive loin en second — voir
> [Garder un historique propre, se remettre de ses erreurs](../2-collaborating/6-git-cleanup.md "Garder un historique propre, se remettre de ses erreurs").
> L'attraper avant qu'il n'atterrisse, c'est à cela que sert l'analyse de secrets en intégration
> continue, et nous la mettrons en place dans
> [L'intégration continue avec Git](2-git-ci.md "L'intégration continue avec Git").

## Ce que le GitOps fait mal

J'aime le GitOps. Ce n'est pourtant pas une théorie du tout, et voici où il grince.

**Les opérations ordonnées en plusieurs étapes.** La réconciliation décrit un point fixe, pas une
procédure. « Vider ces nœuds, migrer ces données, puis basculer ce drapeau » est une *séquence*, et
exprimer des séquences dans une boucle déclarative va de l'inconfortable (vagues de
synchronisation, hooks, phases) au franchement ridicule.

**L'état.** Les manifestes sont peu coûteux à faire converger parce qu'ils ne contiennent pas de
données. Les bases de données, si. Une migration de schéma n'est pas un état désiré qu'on peut
réappliquer de manière idempotente dans les deux sens.

**Le bris de glace.** Pendant un incident, la différence entre `kubectl edit` et « ouvrir une PR,
obtenir une approbation, attendre l'intervalle de synchronisation » se mesure en minutes
d'indisponibilité. Toute boutique GitOps mature a un chemin d'urgence ; les bonnes le rendent
*bruyant* — journalisé, alerté, et réconcilié dès que le commit correspondant arrive.

**Et `git revert` ressemble davantage à un retour arrière qu'il ne l'est vraiment.** Revenir sur le
commit qui a changé une étiquette d'image ramène véritablement l'ancien conteneur. Cela ne
dé-migre pas la base de données, ne dé-envoie pas les courriels, et ne dé-débite pas les cartes
bancaires. Revenir sur un manifeste annule la *configuration*, pas les *conséquences*. Nous y
reviendrons dans [Le déploiement continu](4-git-cd.md "Le déploiement continu"), parce que c'est la
chose la plus survendue de tout ce domaine.

## Récapitulatif `git rev-parse '@{u}'` `git merge --ff-only`

* **GitOps** : le dépôt Git est la source unique de vérité de l'état désiré, et un agent réconcilie
  continuellement la réalité vers lui.
* Les quatre **principes GitOps** (OpenGitOps v1.0.0) sont : déclaratif, versionné et immuable,
  tiré automatiquement, réconcilié en continu. Le terme vient de Weaveworks, en 2017.
* Git fournit la piste d'audit gratuitement : un **commit** enregistre qui a changé l'état désiré,
  quand et pourquoi ; une **étiquette** nomme une version ; un revert est un retour arrière ; une
  pull request est une gestion du changement.
* Le déploiement en **push** donne au système d'intégration continue les identifiants de
  production. Le déploiement en **pull** non. C'est l'argument le plus fort en faveur du modèle
  pull.
* La **dérive** est ce qui arrive quand la configuration n'est appliquée qu'à la demande. La
  réconciliation continue la guérit d'elle-même ou alerte dessus.
* Les outils : **Argo CD** et **Flux** sur Kubernetes, **Terraform/OpenTofu** avec **Atlantis**
  pour l'infrastructure, `ansible-pull`, **NixOS** depuis un flake — et un minuteur `systemd` qui
  lance `git fetch` puis `make deploy` sur un petit serveur, ce qui est une véritable installation
  GitOps.
* `git rev-parse '@{u}'` nomme l'amont de la branche courante ; `git merge --ff-only` est le
  cliquet qui fait qu'un pull automatisé refuse un historique réécrit.
* Séparez le dépôt de l'application du dépôt de configuration pour que l'intégration continue ne
  puisse pas se redéclencher elle-même ; si vous ne pouvez pas, utilisez `[skip ci]` et des
  filtres de chemins.
* Les secrets n'entrent jamais en clair : **Sealed Secrets**, **SOPS**, **External Secrets
  Operator** ou **git-crypt** — et on fait d'abord tourner l'identifiant, on nettoie l'historique
  ensuite.
* Le GitOps est faible sur les migrations ordonnées, sur les changements avec état et sur les
  urgences, et un revert annule la configuration plutôt que les conséquences.
