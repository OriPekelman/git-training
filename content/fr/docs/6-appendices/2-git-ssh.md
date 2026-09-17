---
title: Configurer Git avec une clé SSH
slug: "git-ssh"
weight: 52
---
# Configurer Git avec une clé SSH

> :information_source:
> La plupart des serveurs Git vous authentifient à l'aide d'une clé publique SSH. SSH est un protocole qui nous permet de nous connecter à des machines distantes de manière sécurisée. Pour l'utiliser il faut se créer une « identité » composée de deux fichiers, l'un public, l'autre privé. Le privé, il faut vraiment bien le protéger — c'est un peu comme votre mot de passe, sauf que contrairement à un mot de passe il ne quitte jamais votre ordinateur. Si vous voulez la version longue, le guide de GitHub est bon : https://docs.github.com/fr/authentication/connecting-to-github-with-ssh

SSH n'est pas strictement requis pour utiliser Git. Mais sans lui vous allez vite vous sentir limité, et on a déjà, potentiellement, un tout petit peu souffert pour installer Git. Souffrons encore un peu. Comme ça après, c'est un long fleuve tranquille.

## En avez-vous déjà une ?

Par défaut, les clés SSH d'un utilisateur vivent dans le répertoire `~/.ssh`. Allons voir :

```console
ls -la ~/.ssh
```

```console
total 16
drwx------ 6 oripekelman staff 192 Jul 29 23:41 .
drwxr-xr-x 3 oripekelman staff  96 Jul 29 23:41 ..
-rw------- 1 oripekelman staff  28 Jul 29 23:41 config
-rw------- 1 oripekelman staff 411 Jul 29 23:41 id_ed25519
-rw-r--r-- 1 oripekelman staff  97 Jul 29 23:41 id_ed25519.pub
-rw-r--r-- 1 oripekelman staff  92 Jul 29 23:41 known_hosts
```

> :information_source:
> Il faut bien `ls -la`, et pas `ls -a`. Le `-a` montre les entrées cachées ; c'est le `-l` qui vous donne le format long avec les permissions, et c'est tout l'intérêt ici. Nous voulons voir la colonne de gauche.

Ce que vous cherchez, c'est une paire : un fichier sans extension, et le même nom suivi de `.pub`. Le `.pub` est votre clé **publique**, l'autre est votre clé **privée**. Les machines plus anciennes auront `id_rsa` et `id_rsa.pub` ; une machine neuve n'aura rien du tout, ou pas de répertoire `~/.ssh`.

Lisez la colonne des permissions, parce qu'elles comptent plus que les débutants ne le pensent :

* `drwx------` sur le répertoire lui-même — mode `700`. Vous seul pouvez ne serait-ce qu'en lister le contenu.
* `-rw-------` sur `id_ed25519` — mode `600`. Vous seul pouvez le lire. Ce n'est pas décoratif ; SSH l'impose.
* `-rw-r--r--` sur `id_ed25519.pub` — mode `644`. Tout le monde peut le lire. C'est très bien. C'est ce que « publique » veut dire.

> :warning:
> Si la clé privée est lisible par quelqu'un d'autre, SSH refusera de l'utiliser. Pas de l'avertir — de refuser. Voici exactement à quoi cela ressemble quand une clé s'est retrouvée en mode `644`, ce qui est le résultat habituel d'une copie sur une clé USB puis d'un retour, ou d'un dézippage :
>
> ```console
> @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
> @         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
> @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
> Permissions 0644 for '/Users/oripekelman/.ssh/id_ed25519' are too open.
> It is required that your private key files are NOT accessible by others.
> This private key will be ignored.
> ```
>
> La correction tient en une ligne :
>
> ```console
> chmod 700 ~/.ssh
> chmod 600 ~/.ssh/id_ed25519
> ```
>
> La dernière ligne de cet avertissement — `This private key will be ignored` — est la raison pour laquelle le symptôme que vous constatez réellement est `Permission denied (publickey)`. SSH n'a pas échoué à vous authentifier ; il n'a jamais essayé.

## Créer sa paire de clés

Si vous n'avez pas de clé, ou si vous avez une vieille `id_rsa` et en voulez une moderne, lancez `ssh-keygen`. Il est fourni avec SSH sous Linux et macOS, et livré avec Git for Windows.

```console
ssh-keygen -t ed25519 -C "you@example.com"
```

```console
Generating public/private ed25519 key pair.
Enter file in which to save the key (/Users/oripekelman/.ssh/id_ed25519):
Enter passphrase for "/Users/oripekelman/.ssh/id_ed25519" (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/oripekelman/.ssh/id_ed25519
Your public key has been saved in /Users/oripekelman/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E you@example.com
The key's randomart image is:
+--[ED25519 256]--+
|          . o=O.o|
|           + OoE.|
|          o o.O o|
|           o o.o.|
|        S .   ..=|
|         .   + *O|
|            .+=+X|
|             .O=o|
|            .=*+o|
+----[SHA256]-----+
```

Trois questions. La première demande où l'enregistrer — appuyez sur entrée, gardez le défaut. Les deux suivantes demandent une phrase de passe, deux fois ; nous y revenons dans un instant.

Le `-C` n'est qu'un commentaire, stocké dans le fichier de clé publique. Mettez-y votre courriel, parce que ce commentaire est ce que vous verrez dans la liste des clés sur GitHub dans deux ans, quand vous essaierez de vous rappeler à quel portable appartient une clé. `"you@example.com — portable du boulot"` est encore mieux.

Le résultat, ce sont deux fichiers et une chose qui vaut d'être comprise : cette ligne `SHA256:F7Ft0e...` est l'**empreinte** de la clé, un hachage de la clé publique. C'est ainsi que des humains comparent des clés sans lire 68 caractères de base64. Vous pouvez la redemander à tout moment :

```console
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
```

```console
256 SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E you@example.com (ED25519)
```

Et la clé publique elle-même tient sur une ligne de texte :

```console
cat ~/.ssh/id_ed25519.pub
```

```console
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHRDpUquRUZV8YB+JS7Smjvv2ewxGIkeoyu8eIpWUq5 you@example.com
```

### Pourquoi `ed25519`, et quid des autres types

L'ancienne version de ce chapitre disait `ssh-keygen -o`, ce qui vous donnait une clé RSA. Ce conseil a vieilli. Voici l'état actuel du monde.

**Ed25519 est ce que vous voulez.** C'est un schéma de signature à courbe elliptique avec un unique jeu de paramètres fixé et bien choisi, ce qui veut dire qu'il n'y a rien à rater : pas de taille de clé à choisir, pas de « est-ce que 2048 suffit encore ». Les clés sont minuscules — une courte ligne — signer et vérifier sont rapides, et GitHub comme GitLab la recommandent. La documentation de GitLab la qualifie de « plus sûre et plus performante que RSA ».

**L'option `-o` est obsolète.** Elle voulait dire « écrire la clé privée dans le format propre à OpenSSH plutôt que dans l'ancien format PEM ». Depuis OpenSSH 7.8, sorti en 2018, c'est le défaut pour tous les types de clés — et c'était *déjà toujours* le cas pour les clés Ed25519, qui n'ont pas d'autre format. `-o` est désormais littéralement sans effet dans le code source et n'est même plus documentée. Laissez-la tomber.

**RSA est acceptable, en 4096 bits, si quelque chose d'ancien l'exige.**

```console
ssh-keygen -t rsa -b 4096 -C "you@example.com"
```

Il existe encore des boîtiers et de vieux serveurs Git d'entreprise qui ne parlent pas Ed25519. Si vous vous adressez à l'un d'eux, voilà le repli, et GitHub comme GitLab recommandent 4096 bits dans ce cas. Ne générez pas de clé RSA de 1024 ou 2048 bits en 2026. Et notez que GitHub impose aux clés RSA créées depuis novembre 2021 d'utiliser des signatures SHA-2, et a cessé d'accepter entièrement l'ancien algorithme de signature SHA-1 `ssh-rsa` le 15 mars 2022 — une clé RSA venue d'une vieille machine peut tout simplement cesser de fonctionner.

**DSA est mort.** Pas déprécié — parti. OpenSSH l'a désactivé par défaut en 2015, désactivé à la compilation en 9.8, et le code a été retiré entièrement dans OpenSSH 10.0 en avril 2025. GitHub a cessé d'accepter de nouvelles clés DSA le 15 mars 2022. Si vous en demandez une aujourd'hui :

```console
ssh-keygen -t dsa -f ~/.ssh/id_dsa
```

```console
unknown key type dsa
```

Si vous trouvez un `id_dsa` dans votre `~/.ssh`, c'est un fossile. Générez une clé Ed25519 et supprimez-le.

> :information_source:
> **L'option la plus solide, en une phrase :** si vous avez une clé de sécurité matérielle (une YubiKey, ou un téléphone qui sait en tenir lieu), `ssh-keygen -t ed25519-sk` crée une clé adossée à FIDO2 dont la moitié privée ne peut physiquement pas être copiée hors de l'appareil, et qui exige que vous le touchiez pour vous authentifier. GitHub et GitLab acceptent tous deux `ed25519-sk` (et `ecdsa-sk` si votre appareil est plus ancien). Il faut OpenSSH 8.2 ou plus récent des deux côtés. C'est la meilleure réponse à « et si on me volait mon portable ».

## La phrase de passe, et comment cesser de la taper

`ssh-keygen` propose de chiffrer la clé privée avec une phrase de passe. Vous devriez dire oui.

Le raisonnement est simple. Sans phrase de passe, le fichier `~/.ssh/id_ed25519` *est* votre justificatif d'identité : quiconque en obtient une copie peut pousser en votre nom, et copier un fichier est la chose la plus facile du monde. Avec une phrase de passe, il lui faut le fichier *et* la phrase.

L'objection évidente est que vous ne voulez pas taper une phrase de passe quarante fois par jour. Vous n'aurez pas à le faire. C'est à cela que sert `ssh-agent` : un petit programme qui garde la clé déchiffrée en mémoire, de sorte que vous tapez la phrase une fois par session.

```console
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

```console
Identity added: /Users/oripekelman/.ssh/id_ed25519 (you@example.com)
```

Et pour voir ce que l'agent détient actuellement :

```console
ssh-add -l
```

```console
256 SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E you@example.com (ED25519)
```

Sur la plupart des bureaux Linux, un agent tourne déjà quand vous ouvrez votre session, donc la ligne `eval` est inutile et `ssh-add` suffit.

**Sur macOS vous pouvez faire mieux**, parce que le trousseau du système sait garder la phrase de passe pour vous d'un redémarrage à l'autre :

```console
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Et ensuite vous n'y pensez plus jamais, si vous écrivez le tout une bonne fois dans `~/.ssh/config` :

```
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

* `AddKeysToAgent yes` — quand une clé est utilisée, l'ajouter automatiquement à l'agent. Taper la phrase de passe au premier usage, pas à chaque usage.
* `UseKeychain yes` — macOS uniquement : chercher la phrase de passe dans le trousseau, et l'y ranger.
* `IdentityFile` — quelle clé proposer.

> :warning:
> `UseKeychain` et `--apple-use-keychain` sont des ajouts d'Apple, pas des éléments d'OpenSSH amont. Deux conséquences. D'abord, sous Linux, un `UseKeychain yes` dans votre configuration est une erreur, donc gardez-le dans le bloc macOS si vous partagez vos dotfiles entre machines. Ensuite, si vous avez installé OpenSSH depuis Homebrew ou MacPorts et qu'il arrive en premier dans votre `PATH`, vous obtiendrez `ssh-add: illegal option -- apple-use-keychain` — c'est que vous exécutez le `ssh-add` non-Apple. Avant macOS Monterey ces options s'écrivaient `-K` et `-A` ; vous les verrez dans les tutoriels plus anciens.

`~/.ssh/config` est un simple fichier texte que vous créez vous-même s'il n'existe pas. SSH exige que personne d'autre que vous ne puisse y écrire, donc `chmod 600 ~/.ssh/config` et n'y pensez plus. Nous allons y revenir sans cesse, parce que c'est là que tout problème SSH finit par se résoudre.

## Donner la clé publique au serveur

La paire de clés existe. Il faut maintenant que le serveur connaisse la moitié publique.

### GitHub

Rendez-vous sur https://github.com/settings/keys, cliquez sur **New SSH key**, donnez-lui un titre qui voudra dire quelque chose plus tard (« MacBook Air, 2026 »), laissez le type sur **Authentication key**, et collez le contenu de `~/.ssh/id_ed25519.pub`.

Collez la ligne entière, y compris le préfixe `ssh-ed25519 ` et le commentaire final. Copiez-la avec `pbcopy < ~/.ssh/id_ed25519.pub` sous macOS, `xclip -sel clip < ~/.ssh/id_ed25519.pub` sous Linux, ou `clip < ~/.ssh/id_ed25519.pub` dans Git Bash — n'importe quoi plutôt que de la sélectionner à la main dans un terminal, où vous perdrez un caractère ou gagnerez un retour à la ligne.

> :warning:
> **Jamais, oh jamais.** La clé privée — `id_ed25519`, celle sans `.pub` — ne doit jamais quitter votre ordinateur. Ne la collez pas dans un formulaire web. Ne l'envoyez pas par courriel. Ne la commitez pas. Ne la mettez pas dans un Dockerfile. Ne la sauvegardez même pas : une clé perdue vous coûte cinq minutes à regénérer et à renvoyer, alors qu'une clé fuitée vous coûte votre compte. Seul le fichier `.pub` s'envoie quelque part, jamais l'autre. Si vous avez le moindre doute sur le fichier que vous vous apprêtez à coller, faites-en un `head -1` : une clé publique commence par `ssh-ed25519` et tient sur une ligne, une clé privée commence par `-----BEGIN OPENSSH PRIVATE KEY-----`.

### GitLab

La même chose sur https://gitlab.com/-/user_settings/ssh_keys → **Add new key**. GitLab vous laisse en plus donner une date d'expiration à une clé et choisir son usage — « Authentication », « Signing », ou les deux.

### N'importe quel autre serveur Git

Les forges n'ont rien de magique. Sur un serveur ordinaire où vous pouvez vous connecter, l'authentification SSH veut dire une seule chose : votre clé publique est une ligne dans le fichier `~/.ssh/authorized_keys` du compte sous lequel vous voulez vous connecter.

```console
ssh-copy-id -i ~/.ssh/id_ed25519.pub git@monserveur.example.com
```

`ssh-copy-id` ajoute la clé pour vous, en créant `~/.ssh` avec les bonnes permissions si besoin. S'il n'est pas disponible, faites-le à la main :

```console
cat ~/.ssh/id_ed25519.pub | ssh git@monserveur.example.com 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

Notez le `>>`. On ajoute, on n'écrase pas — un `>` supprimerait toutes les autres clés utilisées par ce compte, y compris possiblement la vôtre depuis une autre machine. Cette unique ligne dans `authorized_keys` est tout ce qu'un serveur Git auto-hébergé attend de vous ; voir [Héberger Git, et l'héberger soi-même](../3-tooling-ecosystem/2-git-hosting.md "Héberger Git, et l'héberger soi-même").

## Le tester

Ne découvrez pas que votre clé ne fonctionne pas au milieu de votre premier push. Demandez directement :

```console
ssh -T git@github.com
```

```console
Hi yourname! You've successfully authenticated, but GitHub does not provide shell access.
```

Ce message est un succès, alors même qu'il se lit comme un refus. GitHub vous dit que la clé a fonctionné et qu'il n'y a pas de shell en face — il n'y a que Git. Le `-T` veut dire « ne demande pas de terminal », et c'est pourquoi vous obtenez une ligne plutôt qu'une erreur au sujet des pseudo-terminaux.

Pour GitLab :

```console
ssh -T git@gitlab.com
```

```console
Welcome to GitLab, @yourname!
```

### La question de la première connexion

La toute première fois que vous parlez à un hôte, SSH ne le connaît pas et vous demande :

```console
The authenticity of host 'github.com (140.82.121.4)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Tout le monde tape `yes`. Faisons légèrement mieux, parce que cette invite est le seul moment où vous pouvez réellement détecter quelqu'un qui se fait passer pour GitHub.

L'**empreinte** est un hachage de la clé publique du serveur lui-même — sa clé d'hôte. SSH vous demande : « la machine qui répond à cette adresse m'a montré cette clé ; est-ce bien la machine que vous vouliez ? » Il ne peut pas répondre à votre place la première fois. Il le pourra ensuite, parce qu'il écrit la réponse dans `~/.ssh/known_hosts` et compare à chaque connexion suivante.

Alors comparez-la à ce que le service publie. Les empreintes de GitHub sont sur https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints et, à l'heure où nous écrivons, valent :

| Type | Empreinte |
| --- | --- |
| Ed25519 | `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU` |
| ECDSA | `SHA256:p2QAMXNIC1TJYWeIOttrVc98/R1BUFWu3/LiyKgUfQM` |
| RSA | `SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s` |

GitLab.com publie les siennes sur https://docs.gitlab.com/user/gitlab_com/ — celle en Ed25519 est `SHA256:eUXGGm1YGsMAS7vkcx6JOJdOGHPem5gQp4taiCfCLB8`. Consultez la page en direct plutôt que de faire confiance à un tableau dans un cours, parce que celles-ci changent. Remarquez aussi que l'invite accepte l'empreinte elle-même à la place de `yes` : collez-la et SSH ne continuera que si elle correspond.

### Quand la clé d'hôte change

Tôt ou tard vous verrez ceci, et c'est conçu pour vous faire peur :

```console
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:VMZ3w9UoUE/XAQ3xAWmnC63MOBWzHZzqhSPyKg9nG2I.
Please contact your system administrator.
Add correct host key in /Users/oripekelman/.ssh/known_hosts to get rid of this message.
Offending ED25519 key in /Users/oripekelman/.ssh/known_hosts:1
Host key for github.com has changed and you have requested strict checking.
Host key verification failed.
```

Cela veut dire ce que cela dit : la clé stockée dans `known_hosts` n'est pas celle que le serveur vient de présenter. En général l'explication ennuyeuse est la bonne — le serveur a été reconstruit, ou vous atteignez une autre machine derrière le même nom. Parfois non.

C'est arrivé à GitHub lui-même. Le **24 mars 2023**, GitHub a remplacé sa clé d'hôte RSA, parce que la clé privée RSA avait été brièvement exposée dans un dépôt public. Leurs clés d'hôte Ed25519 et ECDSA n'étaient pas concernées. Des millions de gens ont vu exactement le bloc ci-dessus, et la bonne réaction était de vérifier la nouvelle empreinte face à la liste publiée par GitHub, puis de retirer l'entrée périmée.

C'est la correction. N'éditez pas `known_hosts` à la main ; il y a une commande :

```console
ssh-keygen -R github.com
```

```console
# Host github.com found: line 1
/Users/oripekelman/.ssh/known_hosts updated.
Original contents retained as /Users/oripekelman/.ssh/known_hosts.old
```

Puis reconnectez-vous et répondez à nouveau à l'invite de première connexion — **en vérifiant l'empreinte cette fois**, ce qui est tout l'intérêt. Pour regarder une entrée sans la retirer, `ssh-keygen -F github.com`.

> :warning:
> La mauvaise correction, que vous trouverez partout sur Internet, est `StrictHostKeyChecking no`. Cela désactive la seule protection qu'offre ce mécanisme, définitivement, pour tous les hôtes. Si vous vous surprenez à y songer, c'est que vous avez décidé que vous vous fichez de parler ou non à GitHub. Vous ne vous en fichez pas.

## Quand ça ne marche pas

### Lire ce que SSH fait réellement : `ssh -vT`

La commande de débogage la plus utile de tout ce chapitre :

```console
ssh -vT git@github.com
```

Le `-v` fait parler SSH. C'est un mur de texte, mais seules quelques lignes vous intéressent. Voici la partie intéressante d'une exécution réelle contre un serveur qui refusait tout :

```console
debug1: Will attempt key: work ED25519 SHA256:vC2t2ZA3kGLEJ0CwMrjK4KOxfIn0xBUkwaV4qsmlfzk agent
debug1: Will attempt key: you@example.com ED25519 SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E agent
debug1: Will attempt key: /Users/oripekelman/.ssh/id_rsa RSA SHA256:cF77DnrCT1YmJ9tJ3bDvT68SLrNakRAO+NXiOHex/UM
debug1: Will attempt key: /Users/oripekelman/.ssh/id_ecdsa
debug1: Offering public key: work ED25519 SHA256:vC2t2ZA3kGLEJ0CwMrjK4KOxfIn0xBUkwaV4qsmlfzk agent
debug1: Authentications that can continue: publickey,password,keyboard-interactive
debug1: Offering public key: you@example.com ED25519 SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E agent
debug1: Authentications that can continue: publickey,password,keyboard-interactive
```

Lisez-le ainsi :

* **`Will attempt key:`** — la liste des identités que SSH a trouvées, dans l'agent et dans `~/.ssh`. Si votre clé n'est pas dans cette liste, le problème est en amont du serveur : mauvais nom de fichier, mauvaises permissions, pas ajoutée à l'agent.
* **`Offering public key:`** — il a réellement envoyé celle-là au serveur.
* **`Authentications that can continue:`** apparaissant *après* une proposition veut dire que le serveur a dit non à cette clé.
* **`Server accepts key:`** suivi de `Authentication succeeded (publickey)`, voilà à quoi ressemble le succès.

Comparez l'empreinte de la ligne que SSH propose avec celle affichée à côté de la clé dans la page de réglages de GitHub. Si elles ne correspondent pas, c'est que vous avez téléversé une clé différente de celle que vous utilisez — ce qui est, honnêtement, la cause la plus fréquente de l'erreur suivante.

### `Permission denied (publickey)`

```console
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

La liste de contrôle, dans l'ordre qui trouve le problème le plus vite :

1. **La clé est-elle téléversée, et est-ce bien *cette* clé ?** Comparez les empreintes : `ssh-keygen -lf ~/.ssh/id_ed25519.pub` face à la liste de la page de réglages.
2. **Les permissions sont-elles bonnes ?** `ls -la ~/.ssh`. Une clé privée en `644` est silencieusement ignorée — voir l'avertissement en haut de ce chapitre.
3. **SSH la propose-t-il seulement ?** `ssh -vT git@github.com`, et cherchez votre empreinte dans les lignes `Offering public key`.
4. **L'agent détient-il une clé périmée ?** `ssh-add -l`. S'il n'affiche rien d'utile, `ssh-add ~/.ssh/id_ed25519`.
5. **Le nom d'utilisateur est-il bien `git` ?** Pour toutes les forges l'utilisateur SSH est `git`, pas le nom de votre compte. `ssh -T votrenom@github.com` échouera quelle que soit votre clé.
6. **Proposez-vous trop de clés ?** Voir juste en dessous.
7. **Est-ce en réalité un problème de droits sur le dépôt** plutôt que sur la clé ? Si `ssh -T git@github.com` vous salue par votre nom, votre clé va bien et le problème est que vous n'avez pas le droit de pousser sur ce dépôt-là.

### Trop de clés

SSH propose ses identités l'une après l'autre, et les serveurs abandonnent après une poignée d'échecs — vous obtenez `Too many authentication failures` ou un simple `Permission denied` alors même que la bonne clé était dans la liste, juste trop bas. Dans la sortie `-v` ci-dessus, il y a six candidates avant même de commencer.

Le remède est de dire à SSH d'utiliser exactement la clé que vous nommez et rien d'autre :

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

`IdentitiesOnly yes` est la ligne importante : sans elle, `IdentityFile` *ajoute* à la liste au lieu de la remplacer, et les clés de l'agent sont toujours proposées en premier. Avec elle, une seule clé est proposée :

```console
debug1: Offering public key: /Users/oripekelman/.ssh/id_ed25519 ED25519 SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E explicit agent
```

### Deux comptes sur le même hôte

Voilà un besoin réel et courant : un compte GitHub personnel et un compte professionnel. Les deux vivent sur `github.com`, et une clé ne peut appartenir qu'à un seul compte, donc il faut dire à SSH lequel utiliser selon le dépôt.

L'astuce est d'inventer des noms d'hôtes. Dans `~/.ssh/config` :

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
```

`github-work` n'est pas un vrai nom d'hôte — c'est une étiquette. `HostName github.com` est l'endroit où il se connecte réellement. Les deux entrées atteignent donc le même serveur avec des clés différentes.

Ensuite l'URL du **dépôt distant** d'un projet professionnel utilise l'alias :

```console
git remote set-url origin git@github-work:workorg/project.git
```

```console
git remote -v
```

```console
origin	git@github-work:workorg/project.git (fetch)
origin	git@github-work:workorg/project.git (push)
```

Et quand vous clonez, clonez via l'alias : `git clone git@github-work:workorg/project.git`. Testez l'un ou l'autre avec `ssh -T git@github-work`, qui vous saluera sous le compte auquel appartient cette clé.

> :information_source:
> Associez cela aux inclusions conditionnelles d'[Installation et configuration de Git](1-git-install.md "Installation et configuration de Git") et le tout devient automatique : `~/work/` obtient le courriel professionnel dans les commits, et `github-work` obtient la clé professionnelle pour les push. Deux réglages, et vous cessez de commiter sur le dépôt de votre employeur sous votre adresse personnelle.

### Le port 22 est bloqué

Quantité de réseaux d'entreprise, d'hôtels et de réseaux invités d'université autorisent le HTTP et le HTTPS sortants et rien d'autre. Le port 22 de SSH est simplement jeté, votre `git push` reste suspendu et finit par dire `Connection timed out`.

GitHub fait tourner un point d'accès SSH sur le port 443, que tous les pare-feux laissent passer parce que cela ressemble à du trafic HTTPS. Dans `~/.ssh/config` :

```
Host github.com
  HostName ssh.github.com
  Port 443
  User git
```

Notez qu'il s'agit d'un *nom d'hôte différent*, `ssh.github.com`, et non de `github.com` sur un autre port. Testez avec `ssh -T git@github.com` comme d'habitude ; on vous demandera d'accepter une clé d'hôte pour ce nouveau nom, donc vérifiez à nouveau l'empreinte face à la liste publiée.

GitLab.com propose la même chose sur `altssh.gitlab.com`, port 443. Pour un serveur auto-hébergé, demandez à qui l'administre.

Si même cela est bloqué, le HTTPS est votre réponse, et c'est la suite.

## HTTPS : l'autre voie d'entrée

SSH n'est pas obligatoire. Toutes les forges servent aussi Git en HTTPS, et dans certaines situations le HTTPS est tout simplement le meilleur choix.

**Préférez le HTTPS quand** vous êtes sur un réseau verrouillé, sur une machine qui n'est pas la vôtre, ou dans une intégration continue éphémère où un jeton de courte durée est plus facile à gérer — et plus sûr — qu'une clé de déploiement.

**Préférez SSH quand** c'est votre propre machine et que vous poussez toute la journée. Pas de jeton à faire tourner, pas d'assistant d'identifiants à configurer, et une clé protégée par phrase de passe dans un agent est un justificatif véritablement solide.

La seule chose qui ne marche *pas*, c'est votre mot de passe :

> :warning:
> **GitHub a cessé d'accepter les mots de passe de compte pour les opérations Git le 13 août 2021.** Si vous tapez votre mot de passe GitHub à une invite `Password for 'https://github.com':`, cela échouera, et le message d'erreur ne sera pas très explicite sur la raison. Ce qui va dans ce champ, c'est un **jeton d'accès personnel**. GitLab, c'est pareil : avec l'authentification multifacteur activée, Git en HTTPS demande un jeton, pas votre mot de passe.

### Les assistants d'identifiants

Taper un jeton de quarante caractères à chaque push n'est pas une méthode de travail. Un assistant d'identifiants le range dans le trousseau de votre système d'exploitation et le donne à Git automatiquement.

```console
git config --global credential.helper osxkeychain
```

Cela, c'est macOS. Ailleurs :

* **Windows** — Git Credential Manager est livré avec Git for Windows et il est en général déjà configuré. Sinon : `git config --global credential.helper manager`.
* **Linux** — l'assistant `libsecret` parle à GNOME Keyring ou KWallet. Sur Debian et Ubuntu il est livré sous forme de source et doit être compilé une fois ; regardez dans `/usr/share/doc/git/contrib/credential/libsecret`. D'autres distributions l'empaquettent directement.
* **Partout, temporairement** — `git config --global credential.helper 'cache --timeout=3600'` garde le jeton en mémoire pendant une heure et ne l'écrit jamais sur disque. La documentation de Git déconseille celui-ci pour des jetons de longue durée.
* **`store`** écrit le jeton dans `~/.git-credentials` **en clair**. C'est mieux que rien sur une machine sans écran ; ce n'est pas bien.

Au premier push, Git demande votre nom d'utilisateur et votre jeton, et l'assistant s'en souvient.

### Ou laissez faire `gh`

Si vous avez installé le CLI de GitHub, toute cette danse tient en une commande :

```console
gh auth login
```

Il ouvre un navigateur, vous authentifie, range le jeton dans le stockage d'identifiants du système, propose de configurer Git pour l'utiliser, et ira même jusqu'à générer et téléverser une clé SSH si vous choisissez SSH plutôt que HTTPS. `gh auth setup-git` configure `gh` comme assistant d'identifiants de Git tout seul si vous avez déjà un jeton. Le `glab auth login` de GitLab en est l'équivalent.

Pour en savoir plus sur les jetons — classiques ou à granularité fine, portées, expiration — voir [Créer et configurer son compte GitHub ou GitLab](3-github-gitlab.md "Créer et configurer son compte GitHub ou GitLab").

## Signer ses commits

Maintenant que nous avons une clé, il y a une deuxième chose à laquelle elle est bonne, et sa place est ici parce qu'elle répare quelque chose dont vous n'aviez peut-être pas remarqué que c'était cassé.

### L'auteur d'un commit non signé est une affirmation, pas un fait

Deux commandes. Dans un dépôt jetable :

```console
printf 'hello\n' > a.txt
git add a.txt
git -c user.name="Linus Torvalds" -c user.email="torvalds@linux-foundation.org" commit -m"Definitely written by me"
git log --pretty=fuller
```

```console
commit 3c2f0489a55d67840b96e6af1a195b77350b9bb6
Author:     Linus Torvalds <torvalds@linux-foundation.org>
AuthorDate: Wed Jul 29 23:32:03 2026 +0200
Commit:     Linus Torvalds <torvalds@linux-foundation.org>
CommitDate: Wed Jul 29 23:32:03 2026 +0200

    Definitely written by me
```

Voilà. Le champ `Author` d'un **commit** est une chaîne de caractères que vous tapez. Git ne la vérifie jamais, parce que Git n'a aucun moyen de le faire : c'est un système distribué sans notion centrale de qui vous êtes. Chaque `git log` que vous avez lu, chaque « qui a écrit cette ligne » d'un `git blame`, repose sur le fait que chacun a rempli son propre nom honnêtement.

D'habitude cela ne pose pas de problème. Cela cesse d'être sans conséquence quand le commit est une dépendance que vous vous apprêtez à exécuter, ou une étiquette de version, ou une pièce dans l'analyse d'un incident.

Une signature corrige cela. Elle attache une preuve cryptographique que le détenteur d'une clé privée donnée a produit exactement ce commit — l'arbre, les parents, le message, la ligne d'auteur, tout.

### La signature SSH : la voie moderne et facile

Depuis Git 2.34, vous pouvez signer avec la clé SSH que vous avez déjà. Pas de nouvel outillage, pas de serveurs de clés.

```console
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

> :information_source:
> Oui, `gpg.format` et `commit.gpgsign` sont bien les noms de ces réglages alors même qu'il n'y a pas l'ombre d'un GPG. Ces réglages précèdent la signature SSH et Git les a gardés pour la compatibilité. Et notez qu'ici `user.signingkey` pointe vers le fichier de clé **publique** — Git le passe à `ssh-keygen`, qui trouve la moitié privée ou interroge l'agent.

Pour *vérifier* des signatures, Git a besoin de savoir à quelles clés faire confiance. C'est un fichier qui associe des identités à des clés publiques, dans le même format que le fichier `allowed_signers` de SSH :

```
ori@pekelman.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHRDpUquRUZV8YB+JS7Smjvv2ewxGIkeoyu8eIpWUq5
```

```console
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

Maintenant commitez, et regardez :

```console
git commit -m"Un commit signé"
git log --show-signature -1
```

```console
commit d5416dd130411ebcff88f0c3ce79f8882f3b89b3
Good "git" signature for ori@pekelman.com with ED25519 key SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E
Author: Ori Pekelman <ori@pekelman.com>
Date:   Wed Jul 29 23:32:12 2026 +0200

    Un commit signé
```

Ou interrogez un commit en particulier — celui-ci sort avec un code non nul si la signature est mauvaise, ce qui le rend utilisable dans un script :

```console
git verify-commit HEAD
```

```console
Good "git" signature for ori@pekelman.com with ED25519 key SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E
```

Et pour voir l'état de toute une plage d'un coup d'œil, `%G?` dans un format d'affichage écrit une lettre par commit :

```console
git log --format='%h %G? %aN'
```

```console
d5416dd G Ori Pekelman
3c2f048 N Linus Torvalds
```

`G` pour une bonne signature, `N` pour aucune. Il y a six autres lettres — `B` mauvaise, `U` bonne mais de validité inconnue, `X` expirée, `Y` clé expirée, `R` clé révoquée, `E` impossible à vérifier — et elles valent d'être connues, parce que `E` (le plus souvent « je n'ai pas la clé de cette personne ») a l'air alarmant et ne veut presque rien dire.

### Les étiquettes signées

Tout ce qui précède s'applique aux **étiquettes**, et pour elles cela compte davantage, parce qu'une étiquette est la manière de dire « voici la version 1.0 » et que ce sont les versions que les gens installent.

```console
git tag -s v1.0 -m"Version 1.0"
git tag -v v1.0
```

```console
Good "git" signature for ori@pekelman.com with ED25519 key SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E
object d5416dd130411ebcff88f0c3ce79f8882f3b89b3
type commit
tag v1.0
tagger Ori Pekelman <ori@pekelman.com> 1785360732 +0200

Version 1.0
```

Le `-s` signe ; le moteur qu'il utilise est celui qu'indique `gpg.format`, donc l'ayant réglé à `ssh` plus haut nous obtenons une signature SSH. Ce que sont les étiquettes et pourquoi les étiquettes annotées valent mieux que les légères, c'est dans [Un peu de structure SVP](../2-collaborating/4-git-repo-structure.md "Un peu de structure SVP").

### Le dire à la forge

Pour que GitHub ou GitLab affiche vos commits comme « Verified », il faut que la clé publique soit enregistrée comme clé de **signature**.

* **GitHub** distingue les clés d'authentification des clés de signature au moment du téléversement. Si vous voulez qu'une seule clé fasse les deux métiers, **vous téléversez deux fois la même clé publique**, une fois par type. Tout le monde se fait avoir. GitHub prend en charge la vérification des signatures SSH depuis août 2022.
* **GitLab** laisse une seule entrée de clé porter l'usage « Authentication & Signing », donc un seul téléversement suffit. Il prend en charge la vérification des signatures SSH depuis GitLab 15.7/15.8.

Dans les deux cas, le courriel du commit doit être une adresse dont la forge sait qu'elle est la vôtre, sinon elle affichera la signature comme non vérifiée alors même que les mathématiques sont justes.

### GPG, la voie traditionnelle

Le mécanisme plus ancien, c'est OpenPGP, et c'est encore ce qu'utilisent beaucoup de projets libres. La forme est la même :

```console
gpg --full-generate-key
gpg --list-secret-keys --keyid-format=long
git config --global user.signingkey <L_ID_DE_LA_CLE>
git config --global commit.gpgsign true
```

en laissant `gpg.format` à sa valeur par défaut `openpgp`, puis vous exportez la clé publique (`gpg --armor --export <ID_DE_LA_CLE>`) et vous la collez dans la page des clés GPG de la forge. GPG vous donne des choses que la signature SSH n'a pas — une toile de confiance, l'expiration et la révocation des clés, des signatures que d'autres outils comprennent déjà. Il vous donne aussi GPG, dont l'administration est réputée désagréable. Si rien d'extérieur ne vous oblige à l'utiliser, utilisez la signature SSH.

### Ce qu'une signature prouve, et ce qu'elle ne prouve pas

Soyons lucides là-dessus, parce que les pastilles « Verified » invitent à la surinterprétation.

Une signature valide prouve que **celui qui contrôlait cette clé privée a produit exactement ces octets-là**. C'est véritablement utile : cela rend les commits infalsifiables et non modifiables en transit.

Elle ne prouve pas :

* **que la clé appartient à la personne que vous croyez.** C'est le problème de la confiance, et les signatures ne le résolvent pas — elles le déplacent dans `allowed_signers`, ou dans le système de comptes de la forge, ou dans la toile de confiance de GPG.
* **que le code est bon, ni sûr.** Un commit signé peut ajouter une porte dérobée. La signature dit qui, pas quoi.
* **que l'auteur l'a écrit.** Elle dit que le signataire l'a signé. Quiconque dispose de votre portable déverrouillé est votre signataire.
* **quoi que ce soit, si personne ne vérifie.** Une signature non vérifiée est un ornement. La valeur apparaît quand quelque chose — un travail d'intégration continue, un processus de publication, un relecteur — exécute réellement `git verify-commit` et échoue quand cela ne passe pas.

C'est pourquoi la recommandation honnête est modeste : activez `commit.gpgsign` parce que cela ne vous coûte rien une fois configuré, et signez vos étiquettes parce que les versions le méritent.

## Récapitulatif `ssh-keygen` `ssh-add` `git verify-commit`

* Une paire de clés SSH, ce sont deux fichiers dans `~/.ssh` : une clé **privée** qui ne quitte jamais votre machine, et une clé publique `.pub` que vous distribuez librement.
* `ssh-keygen -t ed25519 -C "you@example.com"` est la commande. Ed25519 est la recommandation actuelle ; RSA en 4096 bits est le repli pour les vieux serveurs ; DSA a été retiré d'OpenSSH en version 10.0 et n'est pas une option. La vieille option `-o` est sans effet depuis OpenSSH 7.8.
* `ed25519-sk` met la clé privée dans un jeton matériel qui ne peut pas être copié.
* Les permissions sont imposées, pas indicatives : `700` sur `~/.ssh`, `600` sur la clé privée, `644` sur la publique. Une clé privée trop ouverte est *ignorée*, et cela se manifeste par un `Permission denied (publickey)`.
* Utilisez une phrase de passe, puis `ssh-agent` et `ssh-add` pour ne la taper qu'une fois — `ssh-add --apple-use-keychain` plus `UseKeychain yes` sous macOS pour ne la taper jamais.
* `ssh -T git@github.com` teste la clé. `ssh -vT` vous montre quelles clés ont été proposées et lesquelles le serveur a refusées.
* Une **empreinte** d'hôte est vérifiable : GitHub et GitLab publient les leurs. `REMOTE HOST IDENTIFICATION HAS CHANGED` veut dire que la clé stockée diffère de celle présentée ; effacez-la avec `ssh-keygen -R <hôte>` et vérifiez la nouvelle. GitHub lui-même a fait tourner sa clé d'hôte RSA le 24 mars 2023.
* `~/.ssh/config` résout la plupart des problèmes : `IdentitiesOnly yes` quand trop de clés sont proposées, des alias `Host` pour deux comptes sur une même forge, `HostName ssh.github.com` avec `Port 443` quand un pare-feu bloque le port 22.
* Le HTTPS est une alternative légitime. Les mots de passe ont cessé de fonctionner sur GitHub en août 2021 — utilisez un **jeton d'accès personnel** avec un assistant d'identifiants (`osxkeychain`, `manager`, `libsecret`), ou `gh auth login`.
* L'`Author` d'un commit non signé est une chaîne autoproclamée que n'importe qui peut régler. La signature de commit est ce qui en fait un fait.
* `gpg.format ssh` plus `user.signingkey` et `commit.gpgsign true` signe les commits avec la clé SSH que vous avez déjà (Git 2.34+). `git log --show-signature`, `git verify-commit` et `%G?` les vérifient ; `git tag -s` signe les étiquettes.
* Une signature prouve qui a produit les octets. Elle ne dit rien de la qualité du code, et rien du tout si personne ne vérifie.
