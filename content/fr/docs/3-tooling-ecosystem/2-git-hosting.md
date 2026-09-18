---
title: Héberger Git, et l'héberger soi-même
slug: "git-hosting"
weight: 22
---
# Héberger Git, et l'héberger soi-même

Commençons par la phrase qui rentabilise tout ce chapitre, parce qu'une fois que vous l'avez, le reste de l'industrie cesse d'être déroutant.

**Rien de ce qu'ajoute une forge n'est Git.**

Parcourir votre code dans un navigateur : pas Git. La revue de code avec des commentaires en ligne sur un diff : pas Git. Les tickets, les étiquettes, les jalons, les tableaux de projet : pas Git. Les pipelines de CI, les permissions, les équipes, le SSO, les branches protégées, les relecteurs obligatoires : pas Git. Les releases avec des binaires attachés, les registres de paquets, les registres de conteneurs, le scan de secrets, les alertes de dépendances : pas Git. Git ne vous donne exactement rien de tout cela et — c'est là le point important — il n'en a besoin d'aucun. Un **remote** est une URL qui parle le protocole Git. C'est tout le contrat. Tout le reste, ce que GitHub, GitLab, Forgejo ou Bitbucket posent par-dessus, c'est *leur* produit, inventé par eux, stocké dans *leur* base de données.

Et voici le corollaire, qui est la chose la plus utile que vous puissiez savoir sur les forges :

> :information_source:
> **Votre code est parfaitement portable. Vos tickets, vos pull requests et votre configuration de CI sont le véritable enfermement.**
>
> Chaque clone de votre dépôt est une copie complète de tout l'historique — c'est cela que « distribué » veut dire, et nous avons passé la partie 2 à le prouver. Déplacer votre code d'une forge à une autre est une seule commande, et nous la lancerons à la fin de ce chapitre. Déplacer cinq ans de fils de discussion, de conversations de relecture, d'étiquettes, de logs de CI et de notes de version est un projet de moissonnage d'API, et les déplacer *fidèlement* est généralement impossible, parce que la destination n'a pas les mêmes concepts.

Donc quand vous choisissez une forge, vous ne choisissez pas où vit Git. Vous choisissez à quel gestionnaire de tickets et à quelle CI vous allez être marié. Choisissez en conséquence.

## Les acteurs

Brièvement et équitablement, parce que ce cours n'est pas une publicité. Ce qui suit porte sur la *forme* — à quoi chacun sert — pas sur les tarifs ni sur des listes de fonctionnalités, qui changent plus vite qu'aucun livre ne peut suivre.

**GitHub.** Le choix par défaut, et la raison honnête est l'effet de réseau : c'est là que sont les gens, là que les bugs sont signalés, là où le contributeur de passage a déjà un compte. `Actions` est sa CI, profondément tissée dans le dépôt (un fichier YAML dans `.github/workflows/` et vous avez un pipeline). L'outil en ligne de commande `gh` est véritablement bon et rend les pull requests scriptables depuis votre terminal — voir [Faire sienne la ligne de commande](1-git-tools.md "Faire sienne la ligne de commande") pour la place qu'il occupe à côté du reste de votre outillage de terminal. Codespaces vous donne un environnement de développement dans un navigateur. Propriété de Microsoft.

**GitLab.** Celui que vous pouvez auto-héberger comme une option de premier ordre plutôt qu'après coup, et celui dont la CI *intégrée* est la plus forte — GitLab CI était là avant Actions et son modèle de pipeline reste, à mon goût, le plus cohérent des deux. L'argument, c'est toute la suite DevOps dans un seul produit : planifier, construire, tester, déployer, superviser. Que cela séduise dépend entièrement de votre envie d'avoir un seul fournisseur pour tout.

**Bitbucket.** Celui d'Atlassian. La raison d'être sur Bitbucket est presque toujours que votre organisation vit déjà dans Jira, et l'intégration Jira est le sujet.

**Codeberg.** Géré par une association à but non lucratif (Codeberg e.V.) pour les logiciels libres et open source. Il fait tourner Forgejo. Si vous voulez une forge confortable et familière qui n'appartient aux actionnaires de personne, c'est l'endroit évident où regarder.

**Gitea** et **Forgejo.** Gitea a commencé comme un fork de **Gogs** — que l'ancienne version de ce chapitre recommandait, et que le monde a largement dépassé. Gitea est un binaire Go unique qui vous donne une forge complète : interface web, tickets, pull requests, CI, paquets. En 2022, la marque et le nom de domaine du projet Gitea ont été transférés à une société commerciale nouvellement créée, Gitea Ltd. Une partie de la communauté a contesté ce changement de gouvernance et a forké le code sous le nom de **Forgejo**, désormais développé sous l'égide de Codeberg e.V. Les deux sont vivants, les deux sont excellents, et les différences tiennent davantage à qui les dirige qu'à ce qu'ils savent faire. C'est toute l'histoire, et elle ne vaut la peine d'être connue que parce que vous verrez les deux noms et vous vous poserez la question.

**sourcehut** (`sr.ht`). Délibérément minimal, natif pour les listes de diffusion, et il fonctionne sans JavaScript. Les contributions arrivent sous forme de patchs par e-mail — `git send-email`, comme le noyau Linux l'a toujours fait. Cela semble archaïque jusqu'à ce que vous l'ayez utilisé un moment, et alors on a l'impression que quelqu'un a retiré beaucoup de bruit. Si le workflow par e-mail vous intéresse, c'est le meilleur endroit pour le rencontrer.

**Radicle.** Pair-à-pair. Il n'y a pas de serveur : les dépôts, et les tickets et patchs qui y sont attachés, se propagent entre pairs. C'est la seule entrée de cette liste qui tente de répondre à « et si la forge elle-même était distribuée, comme Git l'est ? » Jeune, et intéressant exactement pour cette raison.

**Azure DevOps** et **AWS CodeCommit.** L'hébergement Git propre aux fournisseurs de cloud. La raison d'en utiliser un est que votre organisation est déjà entièrement à l'intérieur de ce cloud et veut une seule facture et un seul fournisseur d'identité. Presque aucun projet open source n'y vit.

> :warning:
> Les forges des fournisseurs sont celles qui ont le plus de chances de changer de statut sous vos pieds : nouvelle tarification, absorption dans un autre produit, ou fermeture aux nouvelles inscriptions. Avant de bâtir le workflow d'une entreprise sur une forge hébergée quelconque — et surtout sur la forge annexe d'un fournisseur de cloud — allez lire vous-même sa documentation et sa page de tarifs actuelles. Tout ce qu'un livre vous dit sur la disponibilité d'un service commercial est périmé au moment où vous le lisez.

## La juridiction, et les forges européennes

Voici un critère de choix qui n'existait quasiment pas quand la première version de ce cours a été
écrite, et qui revient aujourd'hui dans la plupart des conversations d'achat : **où, juridiquement et
physiquement, le code se trouve-t-il ?**

Trois choses ont fait passer cela de l'hypothèse à une question avec une ligne budgétaire. Le
**RGPD** a donné à « où cette donnée est-elle traitée, et sous quel droit » un sens juridique précis
et un mécanisme de sanction. La **consolidation** a concentré le terrain — GitHub est à Microsoft,
Bitbucket à Atlassian — si bien que « prenez un autre fournisseur » a cessé d'être une vraie
couverture. Et le **moissonnage de données d'entraînement** a transformé « qui peut lire mon code »
d'une question philosophique en une question opérationnelle, qui est le même souci que la phrase, à
la fin de ce chapitre, sur le modèle dans lequel vos sources finissent.

Soyez précis sur ce qu'une forge européenne vous achète et ne vous achète pas, parce que le marketing
est épais sur ce sujet. Elle vous donne une juridiction, en général un **DPA** — un accord de
traitement des données, le contrat qui dit réellement ce que l'opérateur a le droit de faire de vos
données — et un opérateur qui n'est pas structurellement tenu de remettre des choses à un
gouvernement étranger. Elle ne vous donne pas une meilleure disponibilité, un meilleur produit, ni
l'immunité contre un rachat. C'est un choix de gouvernance, exactement comme l'auto-hébergement, et il
devrait être défendu sur ce terrain-là.

### Les forges publiques

Nous en avons déjà rencontré deux dans [Les acteurs](#les-acteurs) : **Codeberg**, l'association
berlinoise à but non lucratif qui fait tourner Forgejo, et qui est le premier arrêt évident pour du
travail libre et open source ; et **sourcehut**, la forge minimale pilotée par courriel, opérée en
Europe et toujours bon marché — les formules payantes tournent autour de quelques euros par mois,
alors consultez la page actuelle plutôt que cette phrase.

Les autres qui méritent d'être connues par leur nom :

**Framagit.** Une instance GitLab publique tenue par **Framasoft**, association française qui a une
longue habitude de faire tourner des services libres comme alternative délibérée aux grandes
plateformes. Gratuite, hébergée en France, et populaire auprès des projets de civic-tech et du monde
associatif. Si vous voulez une interface GitLab familière sans être client de GitLab, c'est celle-là.

**GNU Savannah.** La forge de la Free Software Foundation, et de loin la plus ancienne de cette liste.
Elle est stricte : `savannah.gnu.org` est réservée aux paquets GNU officiels, et `savannah.nongnu.org`
aux autres projets qui sont des logiciels libres au sens de la FSF. L'interface est d'une autre
époque. Elle est sur cette liste parce qu'elle est véritablement durable — elle a survécu à la plupart
de ses contemporaines — et parce que cette rigueur est le propos, pas un oubli.

**Pushin.eu.** Une entrante plus récente, opérée par des Néerlandais (PCX IT), sur du matériel dédié
dans les centres de données de Scaleway à Paris, sans bascule vers les États-Unis, et qui prend
position explicitement contre l'entraînement d'IA sur le code hébergé. À l'heure où nous écrivons,
c'est une bêta sur invitation, avec une disponibilité générale visée pour 2027 et des tarifs annoncés
comme comparables à ceux de GitHub et GitLab. Traitez tout cela comme une intention déclarée plutôt
que comme un historique — ce qui est la manière honnête de décrire n'importe quelle forge qui n'est pas
encore sortie.

> :information_source:
> Contenu évolutif : Le statut et les tarifs de Pushin.eu peuvent changer lors de son passage de la bêta à la disponibilité générale. Vérifiez les informations actuelles avant de vous y fier.

**Codebahn.** Opérée par des Suédois, hébergée en France, payante, et bâtie sur Forgejo. Son facteur
différenciant est contractuel plutôt que technique : un DPA publié, qui est exactement le document que
réclamera un service juridique européen et que la plupart des forges gratuites ne peuvent pas fournir.

Vous verrez aussi **Tangled** et **Plain** dans des annuaires. Elles sont assez neuves pour que le
conseil utile soit simplement de vérifier si elles existent encore, et qui les finance, avant de
compter sur l'une ou l'autre.

Et pour la position du pas-d'opérateur-du-tout, **Radicle** est traitée dans
[Les acteurs](#les-acteurs) — c'est la seule entrée ici qui n'a aucun serveur susceptible de se
trouver dans une juridiction.

| Service | Ce que c'est | Opéré / hébergé | Coût |
| --- | --- | --- | --- |
| Codeberg | Forgejo, association | Allemagne | Gratuit |
| Framagit | GitLab, association | France | Gratuit |
| GNU Savannah | Forge de la FSF, logiciel libre uniquement | UE / États-Unis | Gratuit |
| sourcehut | Minimale, flux par courriel | Europe | Formules payantes modestes |
| Pushin.eu | Forge, axée souveraineté | Pays-Bas / Paris | Bêta ; payante ensuite |
| Codebahn | Forgejo, avec un DPA | Suède / France | Payante |
| Radicle | Pair-à-pair, sans opérateur | Nulle part en particulier | Gratuit |
| Forgejo, Gitea, Gogs, GitLab CE, OneDev | Logiciel que vous exploitez | Votre propre machine | Gratuit |

Une règle empirique, proposée comme telle : **Codeberg ou Framagit** pour un foyer public gratuit ;
**Codebahn ou Pushin.eu** s'il vous faut un opérateur payant et un DPA signé ; **Radicle** si vous ne
voulez aucun opérateur central ; **Forgejo sur votre propre VPS** — Hetzner, Scaleway, OVH — si vous
voulez tout sous votre contrôle. Ce dernier point est la section suivante, et il n'est pas gratuit au
sens où le tableau le laisse croire.

> :warning:
> Une bonne partie des textes qui classent ces services est publiée par des sites dont le métier *est*
> la souveraineté numérique européenne, et plusieurs des annuaires d'« alternatives européennes » sont
> des surfaces marketing plutôt que des comparatifs neutres. Lisez-les pour les faits vérifiables —
> quel moteur, quelle société opératrice, dans quel pays sont les serveurs, s'il existe un DPA, quel
> prix — et jetez les classements. Ces faits-là, vous pouvez les vérifier vous-même en dix minutes ;
> les classements, non.

> :information_source:
> Une chose ne change pas, quelle que soit la case cochée : **`git clone` continue de donner à chacun
> une copie complète de l'historique.** Le choix d'une forge est réversible comme presque aucune autre
> décision d'infrastructure, ce qui est une bonne raison de ne pas s'en tourmenter — et une excellente
> raison de garder la sortie répétée. C'est exactement ce que nous faisons dans
> [Migration et sortie](#migration-et-sortie).

## L'auto-hébergement

C'est la section qui rentabilise le chapitre, parce que vous pouvez tout faire, tout de suite, sur votre propre machine.

La raison d'auto-héberger n'est généralement pas l'argent. C'est la souveraineté : votre code source est sans doute la chose la plus précieuse que possède votre organisation, et il y a quelque chose à dire en faveur du fait qu'il vive quelque part que vous contrôlez. Les réseaux coupés d'internet, les industries réglementées et les individus paranoïaques finissent tous ici.

### Le serveur Git minimal viable : un dépôt bare et ssh

Le tout tient en une commande. Un dépôt **bare** est un dépôt sans zone de travail — juste les entrailles de `.git`, promues au rang de répertoire lui-même. Il existe pour qu'on pousse dedans.

Construisons-en un pour de vrai. Faites un répertoire de brouillon n'importe où et lancez :

```console
git init --bare project.git
```

Regardez à l'intérieur :

```console
ls -F project.git
```

```console
config
description
HEAD
hooks/
info/
objects/
refs/
```

Vous reconnaissez chacun d'eux ? Vous devriez — c'est exactement le répertoire `.git` que nous avons démonté en partie 1, la zone de travail en moins. `objects/` contient les **blob**s, les **tree**s et les **commit**s. `refs/` contient les **branch**es et les **tag**s. Il n'y a pas d'`index`, parce qu'il n'y a rien à indexer. Un dépôt bare a une ligne `bare = true` dans son `config` et c'est essentiellement la seule différence.

> :information_source:
> Le suffixe `.git` sur le nom du répertoire est une pure convention, et une bonne : il dit au prochain humain que ceci est un dépôt bare et non une extraction qu'il peut éditer.

Maintenant clonez-le, exactement comme vous cloneriez n'importe quoi :

```console
git clone project.git myproject
```

```console
Cloning into 'myproject'...
warning: You appear to have cloned an empty repository.
done.
```

Committez quelque chose et poussez-le :

```console
cd myproject
echo "# My project" > readme.md
git add readme.md
git commit -m "Initial commit"
```

```console
[main (root-commit) 4c3419c] Initial commit
 1 file changed, 1 insertion(+)
 create mode 100644 readme.md
```

```console
git push origin main
```

```console
To ../project.git
 * [new branch]      main -> main
```

Voilà un serveur Git. Pas une version jouet — un vrai, avec la même base d'objets, les mêmes références et le même protocole que tout ce vers quoi vous avez jamais poussé. Clonez-le encore une fois dans un second répertoire et vous avez deux développeurs qui partagent un dépôt.

La seule chose qui change quand le dépôt vit sur une autre machine, c'est l'URL. Mettez le dépôt bare dans `/srv/git/project.git` sur une machine où vous pouvez faire ssh, et :

```console
git clone you@git.example.com:/srv/git/project.git
```

Git lance `ssh you@git.example.com` et lui demande d'exécuter `git-upload-pack` à l'autre bout. C'est tout. C'est tout le « serveur ». Il n'y a pas de démon à installer, pas de port à ouvrir au-delà du port ssh que vous avez déjà, pas de base de données. Tous ceux qui peuvent se connecter en ssh et ont les permissions de système de fichiers sur ce répertoire peuvent pousser.

> :warning:
> Deux personnes qui poussent vers un dépôt *non bare*, c'est là que les débutants se font mal : la zone de travail du dépôt receveur ne se met pas à jour, elle finit donc en désaccord avec son propre **HEAD** et la prochaine personne à se connecter est très perplexe. Git refusera généralement d'emblée (`refusing to update checked out branch`). Les dépôts partagés sont bare. Toujours.

### Donner l'accès sans donner de comptes shell

La version naïve ci-dessus donne à chaque développeur un compte Unix. Vous ne voulez pas cela. La correction classique, qui est livrée avec Git lui-même, est `git-shell` — un shell de connexion qui ne permet rien d'autre que la poignée de commandes Git côté serveur :

```console
git shell --help
```

Le synopsis de sa propre page de manuel vous dit comment il est censé être utilisé : `chsh -s $(command -v git-shell) <user>`. Vous créez donc un utilisateur Unix, appelé conventionnellement `git`, vous réglez son shell sur `git-shell`, et ensuite les clés publiques ssh de tout le monde vont dans le `~/.ssh/authorized_keys` de cet unique utilisateur. Quiconque s'authentifie atterrit dans un shell qui sait pousser et récupérer et ne sait rien faire d'autre — essayez `ssh git@host` de manière interactive et on vous montre la porte.

Vous pouvez resserrer davantage avec les options que `authorized_keys` prend en charge :

```
command="/usr/bin/git-shell -c \"$SSH_ORIGINAL_COMMAND\"",no-port-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAA... alice
```

Le préfixe `command=` veut dire « quoi que cette clé demande, exécute *ceci* à la place ». Le transfert de ports et l'allocation de pty sont désactivés, la clé ne peut donc pas servir de tunnel.

> :warning:
> C'est un seul compte partagé, donc c'est tout ou rien : chaque clé de ce fichier peut pousser vers chaque dépôt, et supprimer chaque branche. Il n'existe aucune notion de « Alice peut pousser sur `main`, Bob non ». Pour une équipe de trois personnes qui se font confiance, très bien. Au-delà, vous voulez l'étape suivante.

### gitolite, pour un vrai contrôle d'accès

`gitolite` est la réponse classique : un unique programme Perl qui se place derrière ce même utilisateur `git` et consulte un fichier de configuration pour décider qui peut faire quoi. La partie élégante est que sa configuration *est un dépôt Git* — vous clonez `gitolite-admin`, éditez un fichier texte, ajoutez une clé publique, committez, poussez, et le serveur se reconfigure tout seul. Le contrôle d'accès comme donnée versionnée.

Les règles ressemblent à peu près à ceci :

```
repo project
    RW+     =   alice
    RW      =   bob
    R       =   @interns
```

`R` c'est lire, `RW` c'est pousser, `RW+` c'est pousser y compris les push forcés et les suppressions de branches qui réécrivent l'historique — et remarquez comme cela s'applique proprement à ce sur quoi nous avons insisté en partie 2 : on ne réécrit pas un historique partagé. Ici, vous pouvez simplement ne pas l'accorder. Les règles peuvent aussi être par branche, ce qui est la manière d'obtenir « personne ne force un push sur `main` » sans la moindre interface web.

Pas d'interface web, pas de tickets, pas de CI. Juste Git et des permissions, sur une machine, pour toujours. Il y a beaucoup à aimer là-dedans.

### Une forge complète : Gitea ou Forgejo

Quand vous voulez bel et bien l'interface web, les tickets, les pull requests et la CI, et que vous les voulez sur votre propre matériel, c'est ici qu'il faut aller. Les deux sont un binaire unique plus une base de données, et les deux sont véritablement confortables à exploiter — un petit VPS suffit pour une équipe.

La forme d'un `docker-compose.yml`, pour vous donner l'idée :

```yaml
services:
  forgejo:
    image: codeberg.org/forgejo/forgejo:VERSION
    restart: unless-stopped
    environment:
      - FORGEJO__database__DB_TYPE=sqlite3
    volumes:
      - ./data:/data
    ports:
      - "3000:3000"
      - "222:22"
```

Deux ports, parce qu'une forge est deux serveurs sous un seul manteau : HTTP pour les humains et les navigateurs, ssh pour `git push`. Un volume, qui contient les dépôts, la base de données et les téléversements — et qui est donc la chose que vous devez sauvegarder. Remplacez `VERSION` par un vrai tag publié plutôt que d'utiliser `latest`, mettez un reverse proxy devant pour le TLS, et lisez la documentation d'installation du projet lui-même avant de lui confier quoi que ce soit, parce que les détails de déploiement sont exactement le genre de chose qui se périme dans un livre.

### Ce à quoi vous venez de vous engager

Faire tourner une forge n'est pas difficile. En faire tourner une *bien*, pendant des années, est un métier. Honnêtement :

* **Les sauvegardes.** Pas optionnelles, et voyez l'avertissement ci-dessous.
* **Le TLS.** Des certificats, et leur renouvellement, pour toujours.
* **Le spam et les abus**, dès l'instant où vous autorisez l'inscription publique. Tout exploitant de forge publique a une anecdote.
* **Les mises à jour.** Les correctifs de sécurité arrivent au calendrier du projet amont, pas au vôtre, et les migrations de base de données font que vous ne pouvez pas sauter cinq versions.
* **La disponibilité.** Votre CI est maintenant votre problème à 3 h du matin. Le disque qui se remplit aussi.
* **La croissance du stockage.** Les dépôts ne font que grossir, et si quelqu'un active **LFS**, la base d'objets peut éclipser les dépôts eux-mêmes.

> :warning:
> **Un clone n'est pas une sauvegarde.** C'est l'erreur qui coûte leur semaine à des gens.
>
> Un `git clone` — même un clone miroir — copie le dépôt Git. Fidèlement et complètement, ce qui est exactement pourquoi cela ressemble à une sauvegarde. Mais il ne contient pas : les tickets, les pull requests et leurs fils de relecture, les wikis, les releases et leurs binaires téléversés, la configuration et l'historique de CI, les webhooks, les clés de déploiement, ni les données d'utilisateurs et de permissions. Rien de tout cela n'est dans Git. C'est dans la base de données de la forge.
>
> Les objets **LFS** ne sont pas non plus dans le clone à moins que vous ne les récupériez explicitement — voir [Les gros fichiers, ou comment Git rencontre ses limites](../4-beyond-the-basics/4-git-lfs.md "Les gros fichiers, ou comment Git rencontre ses limites"), qui est aussi là où l'on répond à « mon serveur gère-t-il LFS ? », parce que LFS a besoin de la coopération de l'autre bout et que tous les hébergeurs ne la fournissent pas.
>
> Une vraie sauvegarde d'une forge auto-hébergée est un instantané de son volume de données *et* un dump de sa base de données, restaurés quelque part de temps en temps pour prouver que cela fonctionne. Une sauvegarde non testée est une rumeur.

Et si ce que vous voulez vraiment n'est pas une forge mais un déploiement automatique quand vous poussez, c'est un hook `post-receive` sur exactement le genre de dépôt bare que nous venons de construire — douze lignes de shell. Nous en construisons un de bout en bout dans [Déployer un site statique simple](../5-automation/3-git-static-site.md "Déployer un site statique simple").

## Migration et sortie

Maintenant la promesse du début du chapitre, tenue. Déplacer le code, c'est deux commandes.

`git clone --mirror` fait un clone bare qui copie *toutes* les références exactement telles qu'elles sont sur la source — toutes les branches, tous les tags, toutes les notes — plutôt que seulement les branches que vous suivriez normalement :

```console
git clone --mirror project.git mig.git
```

```console
Cloning into bare repository 'mig.git'...
done.
```

```console
cd mig.git
git show-ref
```

```console
4c3419c10ae9e130fa0f6d1380bef47ae95dd36e refs/heads/main
10e6bad5e03f8df0045fcea75ec4359d57acbeca refs/heads/topic
0acd489d251b48c651986e90272114900a49e495 refs/tags/v1.0
```

Deux branches et un tag, tous présents. Maintenant pointez-le vers le nouveau domicile et repoussez l'image miroir :

```console
git remote set-url origin ../newhome.git
git push --mirror origin
```

```console
To ../newhome.git
 * [new branch]      main -> main
 * [new branch]      topic -> topic
 * [new tag]         v1.0 -> v1.0
```

Et à destination :

```console
git show-ref
```

```console
4c3419c10ae9e130fa0f6d1380bef47ae95dd36e refs/heads/main
10e6bad5e03f8df0045fcea75ec4359d57acbeca refs/heads/topic
0acd489d251b48c651986e90272114900a49e495 refs/tags/v1.0
```

Des **SHA**s identiques, parce que les objets sont adressés par contenu et que rien en eux ne dépend de l'endroit où ils sont stockés. Votre historique n'a pas tant « bougé » qu'il n'a été copié à l'octet près. Remplacez les deux chemins locaux par deux URL de forges et vous avez migré un dépôt d'un hébergeur à un autre. Dans la vraie vie, vous voudrez aussi vérifier la présence d'objets **LFS** sur la source (ils migrent séparément, avec `git lfs fetch --all` et `git lfs push --all`) et vous rappeler que `--mirror` côté push est destructeur à destination : il fait correspondre la cible à la source, en supprimant les références qui ne sont pas dans le miroir. Poussez vers un dépôt vide.

> :warning:
> `git push --mirror` supprimera joyeusement à destination des branches qui n'existent pas dans votre miroir. Ne le pointez jamais vers un dépôt que quelqu'un d'autre utilise.

Tout le reste passe par l'API. Les forges le savent et la plupart livrent des importateurs — GitLab, Gitea et Forgejo savent tous récupérer un dépôt *plus* ses tickets et pull requests depuis GitHub moyennant un token, et ils le font correctement. Attendez-vous à des pertes sur les bords : les fils de commentaires imbriqués, les réactions, les états de relecture, l'automatisation, et tout ce qui correspond à un concept que la destination n'a pas. Prévoyez du vrai temps pour cela, et faites-le une fois plutôt que deux.

## Sur la durabilité, et sur qui possède la copie

Une courte réflexion pour finir, pas un sermon.

L'auto-hébergement est généralement présenté comme une décision de coût. Ce n'en est pas une. C'est une décision de gouvernance : qui peut lire votre code, qui peut révoquer votre accès, qui peut changer les conditions, et dans le modèle de qui votre source finit. Ce sont des questions légitimes avec des réponses légitimes dans les deux sens — quantité d'organisations sérieuses sont sur GitHub exprès, parce qu'être là où sont les contributeurs vaut quelque chose de réel.

Mais une chose n'est pas affaire de goût : **« c'est sur GitHub » n'est pas une stratégie d'archivage.** Une société peut être rachetée, une politique peut changer, un compte peut être suspendu par erreur, un dépôt peut être supprimé par son propriétaire. Si un logiciel compte dans dix ans, il faut que quelque chose d'autre que son fournisseur en détienne une copie.

L'organisation qui fait réellement ce travail est [Software Heritage](https://www.softwareheritage.org/), qui moissonne et archive systématiquement et de manière permanente le code source public — historique des commits inclus — en tant que patrimoine culturel. C'est gratuit, ce n'est pas une forge, et si votre projet est public vous pouvez lui demander d'enregistrer votre dépôt dès aujourd'hui. Cela ne vous coûte rien et c'est ce que notre domaine a de plus proche d'une bibliothèque.

Et en attendant, remarquez que vous avez déjà les débuts d'une archive distribuée : le portable de chaque collègue détient une copie complète de l'historique. Git a été conçu par quelqu'un qui ne voulait pas de point de défaillance unique. Ce serait dommage d'en réintroduire un.

## Récapitulatif : hébergement et forges

* **Une forge n'est pas Git.** L'interface web, la revue de code, les tickets, la CI, les permissions, les releases et les registres sont le produit de l'hébergeur, pas une partie de Git.
* **Le code est portable ; les tickets, les pull requests et la configuration de CI sont l'enfermement.** Planifiez votre sortie avant d'en avoir besoin.
* Les acteurs, par forme : **GitHub** (effets de réseau, Actions, `gh`), **GitLab** (auto-hébergeable, CI intégrée), **Bitbucket** (Jira), **Codeberg** (à but non lucratif, fait tourner Forgejo), **Gitea**/**Forgejo** (forge auto-hébergée en un binaire ; forkée en 2022 pour cause de gouvernance), **sourcehut** (workflow e-mail/patch, minimal), **Radicle** (pair-à-pair), plus celles des fournisseurs de cloud.
* **La juridiction est désormais un critère de choix**, poussée par le RGPD, la consolidation des fournisseurs et le moissonnage de données d'entraînement. Les forges publiques européennes : **Codeberg** (Allemagne, gratuite), **Framagit** (France, gratuite, GitLab), **GNU Savannah** (FSF, logiciel libre uniquement), **sourcehut**, **Pushin.eu** (bêta) et **Codebahn** (payante, avec un **DPA** publié). Un opérateur européen vous achète une juridiction et un contrat — pas de la disponibilité, pas un meilleur produit, et pas l'immunité contre un rachat.
* Lisez les annuaires d'« alternatives européennes » pour les faits vérifiables — moteur, opérateur, pays, DPA, prix — et ignorez leurs classements, parce que la plupart vendent de la souveraineté pour vivre.
* `git init --bare` crée un dépôt sans zone de travail — la chose vers laquelle vous poussez. Un dépôt bare plus ssh *est* un serveur Git.
* Les dépôts partagés doivent être bare ; pousser vers une branche extraite casse la zone de travail receveuse.
* `git-shell` est un shell de connexion restreint qui n'autorise que les commandes Git côté serveur ; combinez-le avec un utilisateur `git` unique et des restrictions `command=` dans `authorized_keys`.
* `gitolite` ajoute un contrôle d'accès par dépôt et par branche, configuré via un dépôt Git vers lequel vous poussez.
* **Gitea**/**Forgejo** vous donnent une forge complète sur votre propre matériel ; un binaire unique, une base de données, et un volume que vous devez sauvegarder.
* L'auto-hébergement, c'est assumer les sauvegardes, le TLS, le spam, les mises à jour, la disponibilité et la croissance du stockage.
* **Un clone n'est pas une sauvegarde** : il ne contient ni tickets, ni pull requests, ni wikis, ni releases, ni configuration de CI, ni objets **LFS**.
* `git clone --mirror` puis `git push --mirror` déplace toutes les références et tous les objets d'un hébergeur à l'autre, octet pour octet. `--mirror` au push est destructeur à destination.
* Les objets **LFS** migrent séparément, et tout ce qui n'est pas Git passe par l'API ou l'importateur de la forge.
* Software Heritage, et non votre forge, est ce qui archive réellement le code source sur le long terme.
