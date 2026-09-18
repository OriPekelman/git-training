---
title: Créer et configurer son compte GitHub ou GitLab
slug: "github-gitlab"
weight: 53
---
# Créer et configurer son compte GitHub ou GitLab

Git fonctionne parfaitement sans compte nulle part. Vous pouvez commiter pendant des années sur votre propre portable sans jamais parler à un serveur. Mais tôt ou tard vous voudrez une copie de votre travail ailleurs que sur votre portable, et vous voudrez que d'autres gens puissent le lire — et cela veut dire un compte chez un service d'hébergement.

Ce chapitre est la partie administrative ennuyeuse. Quinze minutes de clics, et on n'en parle plus jamais. Nous ferons GitHub et GitLab côte à côte, parce qu'ils vous demandent à peu de chose près les mêmes choses.

> :information_source:
> Si vous voulez savoir *lequel* choisir, et ce qui existe d'autre, c'est une vraie discussion et sa place est dans [Héberger Git, et l'héberger soi-même](../3-tooling-ecosystem/2-git-hosting.md "Héberger Git, et l'héberger soi-même"), pas ici. Pour l'instant : prenez l'un ou l'autre. Rien dans ce cours ne dépend de ce choix.

## Créer le compte

* **GitHub** : https://github.com/signup
* **GitLab** : https://gitlab.com/users/sign_up

Tous deux veulent une adresse de courriel, un mot de passe et un nom d'utilisateur.

> :warning:
> **Réfléchissez trente secondes au nom d'utilisateur.** Il entre dans l'URL de chaque dépôt que vous posséderez jamais — `github.com/<utilisateur>/<projet>` —, dans chaque commande de clonage que quiconque lancera contre votre code, et dans l'adresse `noreply` que le service vous fabrique. Les deux services vous laisseront renommer un compte, et tous deux vous préviendront que les liens vers l'ancien nom casseront. Renommer est réellement pénible. `xX_dark_coder_1997_Xx` semblait bien sur le moment ; il va figurer sur votre CV.

Ensuite relevez votre courrier et cliquez sur le lien de vérification. Aucun des deux services ne vous laissera faire grand-chose tant que l'adresse n'est pas vérifiée — sur GitLab, un compte non vérifié ne peut même pas pousser.

## Activez tout de suite l'authentification à deux facteurs

Faites-le avant toute autre chose, tant que vous en avez encore la patience.

Votre compte d'hébergement Git est, pour la plupart des développeurs, le compte dont la perte fait le plus de dégâts. Ce n'est pas seulement votre code : c'est votre nom sur des commits, vos paquets publiés, vos clés de déploiement, et — si vous vous en servez comme fournisseur d'identité — tout un tas d'autres comptes.

Les deux services sont passés de « s'il vous plaît » à « vous devez » :

* **GitHub** exige l'authentification à deux facteurs depuis mars 2023 pour tout utilisateur qui *contribue du code* — les critères incluent la publication d'une application ou d'une action, la création d'une version, le fait d'être propriétaire d'une organisation, ou de contribuer à un dépôt que GitHub juge important. Le déploiement s'est fait par cohortes, chacune avec une fenêtre d'inscription de 45 jours, et l'échéance de la dernière cohorte était le 19 janvier 2024. Ce n'est pas (à l'heure où nous écrivons) exigé de chaque compte, mais si vous suivez ce cours vous êtes en route vers le groupe concerné. Activez-la.
* **GitLab.com** a annoncé l'authentification multifacteur obligatoire en janvier 2026, avec une application à partir du 27 avril 2026 et un déploiement par cohortes tout au long de l'année. Cela concerne toute connexion ou requête d'API faite avec un nom d'utilisateur et un mot de passe. Git par SSH et Git par HTTPS avec un jeton ne sont pas concernés.

  > :information_source:
  > Contenu évolutif : Le calendrier d'application de l'authentification multifacteur de GitLab évolue. Consultez [la documentation actuelle de GitLab](https://docs.gitlab.com/ee/user/profile/account/two_factor_authentication.html) pour les dernières dates.

Vous avez le choix du second facteur. Dans l'ordre approximatif de notre préférence :

1. **Une clé d'accès ou une clé de sécurité matérielle** (une YubiKey, ou la clé d'accès que votre téléphone ou votre portable propose déjà). Résistante à l'hameçonnage, parce que la clé vérifie *quel site* pose la question. Sur GitHub, une clé d'accès peut remplacer entièrement le mot de passe.
2. **Une application TOTP** — les six chiffres qui changent toutes les trente secondes. N'importe laquelle fera l'affaire. C'est le défaut raisonnable, et cela marche hors ligne.
3. **Le SMS**, que GitHub prend en charge mais déconseille activement : l'échange de carte SIM est une attaque réelle, la livraison n'est pas fiable, et ce n'est pas disponible partout. À utiliser en dernier recours, pas en premier choix.

> :warning:
> **Conservez les codes de récupération.** Quand vous activez la double authentification, GitHub vous remet une liste de seize codes de récupération à usage unique, dans un fichier appelé `github-recovery-codes.txt`. Téléchargez-le. Mettez-le dans votre gestionnaire de mots de passe, ou imprimez-le et rangez-le dans un tiroir. Si vous perdez votre second facteur *et* vos codes de récupération, le support de GitHub ne peut pas vous rendre votre compte — ils le disent explicitement. Ce n'est pas une menace, c'est de l'arithmétique : si le support pouvait restaurer l'accès, quiconque se ferait passer pour vous de manière convaincante le pourrait aussi.

## Hygiène du profil, brièvement

Deux choses valent cinq minutes.

**Le courriel de vos commits est public.** Chaque commit que vous poussez porte l'adresse issue de votre `user.email` — voir [Installation et configuration de Git](1-git-install.md "Installation et configuration de Git") — et quiconque clone le dépôt l'a pour toujours. Si vous préférez ne pas publier votre adresse personnelle, GitHub vous donne un alias `noreply` de la forme `ID+UTILISATEUR@users.noreply.github.com` (les comptes antérieurs à juillet 2017 ont l'ancienne forme `UTILISATEUR@users.noreply.github.com`), et un réglage « Keep my email addresses private » qui fait que les commits faits depuis le web l'utilisent. Réglez ensuite cette adresse localement :

```console
git config --global user.email "1234567+votrenom@users.noreply.github.com"
```

GitHub vous attribuera toujours les commits, parce qu'il sait que l'alias vous appartient.

**Vos dépôts publics constituent un portfolio, que vous l'ayez voulu ou non.** En tant que personne qui lit beaucoup de code de candidats : la première chose que je regarde n'est pas le dépôt le plus astucieux, ce sont les messages de commit de ce que vous avez touché en dernier. Ce n'est pas une raison d'être paranoïaque — c'est une raison d'écrire le message de commit.

## Ajouter sa clé SSH

Générez la clé et comprenez ce qu'elle est dans [Configurer Git avec une clé SSH](2-git-ssh.md "Configurer Git avec une clé SSH") ; nous ne le répéterons pas ici. Où va la clé publique :

* **GitHub** : https://github.com/settings/keys → *New SSH key*
* **GitLab** : https://gitlab.com/-/user_settings/ssh_keys → *Add new key*

Une subtilité vaut d'être connue, parce qu'elle déroute la première fois. Les deux services distinguent une clé servant à **authentifier** (prouver que c'est bien vous qui poussez) d'une clé servant à **signer** (prouver qu'un commit est vraiment de vous). Ils s'y prennent différemment :

* GitHub vous demande de choisir un *type* au téléversement — « Authentication key » ou « Signing key » — et si vous voulez utiliser une seule clé pour les deux, **vous téléversez deux fois la même clé publique**, une fois par type. Cela surprend tout le monde.
* GitLab laisse une seule entrée de clé porter l'usage « Authentication & Signing », donc un téléversement suffit.

La signature de commits elle-même est dans [Configurer Git avec une clé SSH](2-git-ssh.md "Configurer Git avec une clé SSH").

## Les jetons d'accès personnels

Un jeton est une longue chaîne aléatoire qui tient lieu de mot de passe quand quelque chose doit parler au service en HTTPS — un script, un travail d'intégration continue, un outil. GitHub a cessé d'accepter les mots de passe de compte pour les opérations Git le 13 août 2021, donc si vous poussez en HTTPS, c'est un jeton que vous tapez réellement.

GitHub en a deux sortes :

* **Les jetons à granularité fine** — limités à des dépôts précis et à des permissions précises, disponibles pour tous depuis mars 2025. L'expiration par défaut est de 30 jours ; le maximum est de 366 jours (ou pas d'expiration, si la politique l'autorise).
* **Les jetons classiques** — une liste plate de portées grossières (`repo` donne accès à *tous* vos dépôts, publics et privés). Pas formellement dépréciés, encore nécessaires pour quelques fonctionnalités, mais GitHub recommande les jetons à granularité fine là où ils fonctionnent et a annoncé son intention de finir par désactiver les classiques.

L'équivalent GitLab vit sous *Access tokens* dans les réglages de votre utilisateur, avec sa propre liste de portées (`read_repository`, `write_repository`, `api`, …) et une date d'expiration obligatoire.

Trois règles :

1. **Restreignez la portée.** Un jeton qui n'a besoin de lire qu'un seul dépôt devrait pouvoir lire un seul dépôt. Le mode de défaillance d'un jeton trop large n'est pas « quelqu'un lit mon code », c'est « quelqu'un pousse sur tout ».
2. **Mettez une expiration.** Un jeton qui expire est une fuite avec une date limite.
3. **Ne mettez jamais un jeton dans un fichier à l'intérieur du dépôt.** Ni dans `config.py`, ni dans `.env`, ni « temporairement ». Les jetons vont dans un assistant d'identifiants ou dans une variable d'environnement — voir la section HTTPS de [Configurer Git avec une clé SSH](2-git-ssh.md "Configurer Git avec une clé SSH"). Les deux services analysent les push publics à la recherche de ce qui ressemble à leurs propres jetons et les révoquent, ce qui est gentil de leur part, mais n'en faites pas leur travail.

## Votre premier dépôt, relié à celui de la partie 1

Dans l'interface web, créez un dépôt. Appelez-le `my_first_git_project`, pour correspondre à celui que nous avons construit dans [Premiers pas, premières commandes Git](../1-understanding-git/3-first-git-commands.md "Premiers pas, premières commandes Git").

> :warning:
> **Ne cochez pas « Add a README » (ni « Initialize repository with a README » chez GitLab).** Nous avons déjà des commits en local, et un README créé sur le serveur est un commit que nous n'avons pas. C'est l'échec de premier push le plus fréquent, et nous le montrons plus bas. Créez le dépôt complètement vide.

La forge vous montre alors les deux lignes dont vous avez besoin. Depuis l'intérieur de votre dépôt local :

```console
cd ~/projects/my_first_git_project
git remote add origin git@github.com:votrenom/my_first_git_project.git
git branch -M main
git push -u origin main
```

Ce qui répond :

```console
To github.com:votrenom/my_first_git_project.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

Voilà. Votre travail est à deux endroits. Ce que `remote`, `push` et `-u` veulent vraiment dire est le sujet de [Récupérer et envoyer du code](../2-collaborating/3-git-clone-pull-remote.md "Récupérer et envoyer du code").

### Les quatre manières dont ce premier push tourne mal

**« src refspec main does not match any »**

```console
error: src refspec main does not match any
error: failed to push some refs to 'github.com:votrenom/my_first_git_project.git'
```

Vous avez demandé à Git de pousser une **branche** appelée `main` et vous n'en avez pas — parce que `git init` crée toujours `master` sauf si vous lui avez dit autre chose, tandis que GitHub et GitLab nomment leur branche par défaut `main`. Vérifiez avec `git branch --show-current`. Renommez avec `git branch -M main` et poussez à nouveau. Puis réglez `init.defaultBranch` pour que cela n'arrive plus jamais.

C'est aussi ce que vous obtenez si vous n'avez fait *aucun commit* : une branche vide n'est pas une branche.

**« Updates were rejected because the remote contains work that you do not have locally »**

```console
To github.com:votrenom/my_first_git_project.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to 'github.com:votrenom/my_first_git_project.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

C'est le README qu'on vous avait dit de ne pas cocher. Le serveur a un commit ; vous avez un commit ; ni l'un ni l'autre n'est l'ancêtre de l'autre. Faites passer le leur sous le vôtre :

```console
git pull --rebase origin main
git push -u origin main
```

Le `--rebase` rejoue vos commits par-dessus les leurs, et contrairement à une fusion il ne s'offusque pas que les deux historiques soient sans lien. Et si vous préférez ne pas y penser du tout, et que le dépôt côté serveur ne contient rien qui vous importe, supprimez-le dans l'interface web et recommencez avec un dépôt vide.

**« Repository not found »** (GitHub) ou **« The project you were looking for could not be found »** (GitLab)

Celui-ci vous ment. GitHub renvoie délibérément le même message pour « ce dépôt n'existe pas » et pour « ce dépôt existe et vous n'avez pas le droit de le voir », parce que vous dire lequel révélerait l'existence de dépôts privés. La liste de contrôle est donc :

* L'orthographe du propriétaire et du nom du dépôt est-elle exacte ? Casse comprise.
* Êtes-vous le compte que vous croyez ? `ssh -T git@github.com` vous dira sous quel utilisateur votre clé vous authentifie.
* Si c'est le dépôt de quelqu'un d'autre — avez-vous le droit d'y pousser, ou êtes-vous censé le forker ?

**« Permission denied (publickey) »**

Votre clé n'est jamais entrée. Tout ce diagnostic vit dans [Configurer Git avec une clé SSH](2-git-ssh.md "Configurer Git avec une clé SSH").

## La demi-douzaine de réglages qui comptent dès le premier jour

**Privé ou public.** Vous pouvez basculer dans un sens comme dans l'autre plus tard, mais comprenez ce que « plus tard » veut dire :

> :warning:
> Rendre public un dépôt privé expose **tout son historique**, pas son état actuel. Chaque commit, chaque branche, chaque fichier que vous avez un jour commité puis supprimé. Les identifiants que vous avez commités la première semaine et retirés la deuxième sont dans l'historique, et passer en public les publie. Supprimer un fichier ne le retire pas de Git — c'est tout l'intérêt de Git. Si un dépôt a un jour contenu un secret, traitez « rendre public » comme « publier ce secret », et changez-le d'abord.

**Le nom de la branche par défaut.** Les deux services prennent `main` par défaut pour les nouveaux dépôts, et tous deux vous laissent changer ce défaut pour votre compte. Alignez-le sur ce que vous avez mis dans `init.defaultBranch` en local et vous vous épargnez la danse `master`/`main` à chaque fois.

**La protection de la branche `main`, même seul.** Cela sonne comme du cérémonial pour un projet solo, et c'est l'assurance la moins chère que vous achèterez jamais : une règle qui interdit le push forcé sur `main` fait que l'après-midi où vous taperez un `git push --force` de travers vous coûtera un juron au lieu d'un week-end. Sur GitHub c'est *Settings → Branches* (ou les plus récents *Rulesets*) ; sur GitLab, *Settings → Repository → Protected branches*. Cochez « do not allow force pushes » et arrêtez-vous là. Exiger des pull requests quand on est le seul développeur, c'est là que cela cesse d'en valoir la peine.

**Un README.** Pas pour les autres. Pour vous, dans dix-huit mois, quand vous aurez oublié comment lancer votre propre projet.

**Une licence — et celle-ci compte vraiment.**

> :warning:
> Un dépôt sans fichier de licence est **« tous droits réservés »** par défaut. Pas dans le domaine public, pas « faites-en ce que vous voulez ». Le droit d'auteur est automatique ; mettre du code sur Internet n'accorde à personne la permission de l'utiliser. Donc si vous *voulez* que les gens puissent utiliser votre code, il faut le dire, dans un fichier, exprès. Les deux services proposent un sélecteur de licence à la création ; https://choosealicense.com/ vous guidera dans le choix en quatre-vingt-dix secondes environ. MIT si vous voulez « faites-en ce que vous voulez, gardez juste mon nom dessus ». GPL si vous voulez que les modifications reviennent.

**Un `.gitignore`.** Les deux forges proposent des modèles par langage à la création (`Python`, `Node`, `Go`…) tirés de https://github.com/github/gitignore, et ce sont de bons points de départ. À quoi sert `.gitignore`, et comment écrire le vôtre, c'est dans [Un peu de structure SVP](../2-collaborating/4-git-repo-structure.md "Un peu de structure SVP").

## GitHub ou GitLab ?

Honnêtement : pour apprendre Git, cela n'a pas d'importance, et vous finirez de toute façon avec des comptes sur les deux, parce que les projets des autres vivent sur les deux.

GitHub est là où se trouve le monde du logiciel libre, ce qui en fait là où se trouve l'effet de réseau. GitLab livre davantage de la machinerie environnante dans la boîte et est bien plus agréable à auto-héberger. Tous deux sont d'excellents serveurs Git, ce qui est la seule partie dont ce cours traite.

Et ils ne sont pas les deux seuls. **Codeberg** (qui fait tourner Forgejo) est une alternative associative, **Forgejo** et **Gitea** sont faciles à auto-héberger, et un dépôt nu accessible par SSH sur n'importe quelle machine que vous contrôlez est déjà un serveur Git parfaitement réel — c'est le sujet d'[Héberger Git, et l'héberger soi-même](../3-tooling-ecosystem/2-git-hosting.md "Héberger Git, et l'héberger soi-même"). Votre historique est à vous : quel que soit votre choix, `git clone` vous le ressort en entier.

## Tout faire depuis le terminal : `gh` et `glab`

Si vous préférez ne pas cliquer, les deux services ont un client officiel en ligne de commande — `gh` pour GitHub, `glab` pour GitLab. Installez-les depuis votre gestionnaire de paquets — `brew install gh`, ou le paquet de votre distribution, ou winget sous Windows.

```console
gh auth login
```

Il vous guide à travers une connexion par navigateur, range le jeton dans le stockage d'identifiants du système, et propose de mettre en place votre clé SSH et de configurer Git pour vous. Cela remplace la plus grande partie de ce chapitre.

Ensuite, depuis l'intérieur du dépôt local fabriqué en partie 1 :

```console
gh repo create my_first_git_project --private --source=. --push
```

Cela crée le dépôt sur GitHub, l'ajoute comme `origin`, et pousse — toute la section « premier dépôt » en une ligne. `gh repo create` sans arguments est interactif et proposera aussi des modèles `--gitignore` et `--license`. `gh auth setup-git` configure `gh` comme assistant d'identifiants de Git pour que les push en HTTPS cessent de demander quoi que ce soit.

`glab auth login` et `glab repo create` font le même travail sur GitLab.

> :information_source:
> Ces CLI sont aussi la manière raisonnable de scripter quoi que ce soit contre une forge — ouvrir des pull requests, lister des tickets, télécharger des journaux d'intégration continue — sans bricoler des appels d'API à la main. Plus sur l'outillage environnant dans [Faire sienne la ligne de commande](../3-tooling-ecosystem/1-git-tools.md "Faire sienne la ligne de commande").

## Récapitulatif `git remote add` `git push -u`

* Un compte chez un service d'hébergement n'est pas nécessaire pour utiliser Git, mais c'est ainsi que vous sortez une copie de votre travail de votre portable et que vous la mettez sous les yeux des autres.
* Votre **nom d'utilisateur** finit dans l'URL de chaque dépôt que vous possédez. Choisissez-le délibérément.
* Activez tout de suite l'**authentification à deux facteurs** — GitHub l'exige des contributeurs de code depuis mars 2023, GitLab.com a commencé à imposer l'authentification multifacteur pour les connexions par mot de passe en avril 2026 — et conservez les codes de récupération ailleurs que sur le portable.
* Le courriel de vos commits est **public pour toujours**. L'alias `ID+UTILISATEUR@users.noreply.github.com` de GitHub existe si vous préférez que ce ne soit pas le vrai.
* Les forges distinguent les clés d'**authentification** des clés de **signature** ; GitHub veut que la même clé soit téléversée deux fois si vous l'utilisez pour les deux.
* Les **jetons d'accès personnels** tiennent lieu de mot de passe en HTTPS (les mots de passe ont cessé de fonctionner sur GitHub en août 2021). Limitez leur portée, donnez-leur une expiration, et n'en commitez jamais un.
* `git remote add origin <url>` nomme un **dépôt distant** ; `git push -u origin main` envoie une **branche** et retient où elle est allée.
* Les échecs classiques du premier push sont `src refspec main does not match any` (votre branche s'appelle `master`), un refus pour non-avance-rapide (la forge a créé un README), et `Repository not found` (en général des droits, pas un dépôt manquant).
* Un dépôt **sans licence est tous droits réservés**. Si vous voulez que votre code soit utilisé, dites-le dans un fichier.
* Rendre public un dépôt privé expose **tout son historique**, pas seulement son contenu actuel.
* `gh auth login` et `gh repo create --source=. --push` font l'essentiel de ce chapitre depuis la ligne de commande.
