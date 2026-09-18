---
title: Mettre en œuvre un workflow collaboratif efficace
slug: "git-workflow"
weight: 15
---

# Politesse oblige : mettre en œuvre un workflow collaboratif efficace

À la fin de [Collaborer grâce à Git](1-collaborate-with-git.md "Collaborer grâce à Git"), nous avons fait une promesse, et nous devrions la tenir. Nous avions dit :

> C'est la première fois dans ce cours que nous n'allons pas vous dire toute la vérité. Bien que ce soit l'une des commandes que vous allez utiliser très souvent, se construire une compréhension réelle et détaillée de ce que fait `git merge` est véritablement **compliqué**.

Nous allons payer cette dette maintenant. Dans le chapitre sur la collaboration, nous avons fusionné deux branches, Git a dit **Fast-forward**, et nous sommes passés vite. Il se trouve qu'un fast-forward est précisément le cas où `git merge` ne fait presque rien du tout. Tout ce qui est intéressant se cachait derrière ce mot.

Ce chapitre a donc deux moitiés. La première est sociale : ce que vous devez aux gens qui partagent un dépôt avec vous. La seconde est mécanique : ce que `merge`, `rebase`, `amend` et la résolution de conflits font réellement aux objets dans `.git`. Les deux moitiés sont le même sujet. Chaque mécanisme que nous regardons existe parce que quelqu'un, quelque part, doit lire votre historique et comprendre ce que vous avez fait.

> :information_source: Toutes les sorties de ce chapitre viennent d'un vrai dépôt construit avec des dates figées, pour que les hashes restent cohérents d'une section à l'autre. Les **SHA**s sur votre machine seront différents. C'est normal et attendu — ce sont les formes qui comptent.

## Politesse oblige

Une branche que vous seul utilisez est votre carnet privé. Griffonnez dedans, arrachez des pages, réécrivez le premier chapitre après avoir écrit le dernier. Personne ne s'en soucie, et personne ne devrait.

Une branche que d'autres utilisent est une propriété partagée. Au moment où un collègue a lancé `git pull` et a basé du travail sur l'un de vos commits, ce commit cesse d'être le vôtre. C'est désormais un fait du monde. Vous pouvez y ajouter. Vous ne pouvez pas le faire ne-pas-avoir-eu-lieu.

Cela nous donne la règle unique dont découle la majeure partie de ce chapitre :

> :warning: Ne réécrivez jamais un historique qui existe en dehors de votre propre dépôt.

Et cela nous en donne une deuxième, plus douce. Votre historique de commits est un message. C'est un message au collègue qui relit votre travail cet après-midi, à la personne qui bissectera un bug de production dans huit mois, et — le plus souvent — à *vous-même*, mardi prochain, ayant entièrement oublié pourquoi vous aviez touché à ce fichier. Écrire ce message avec soin n'est pas une cérémonie. C'est la documentation la moins chère que vous produirez jamais, parce que vous êtes déjà en train de la taper.

## La charrue et les bœufs : tirer avant de pousser

Il y a une vieille règle pour travailler un champ avec un attelage de bœufs : on ne pousse pas la charrue avant que les bœufs n'aient avancé. En termes Git :

```console
git pull
# lancer vos tests
git push
```

Vous tirez d'abord parce que le dépôt distant a pu bouger depuis votre dernier regard, et Git refusera de pousser si c'est le cas :

```console
git push

To /srv/git/shop.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '/srv/git/shop.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

C'est Git qui se comporte en bon citoyen pour votre compte : il ne vous laissera pas faire oublier un commit à la branche distante. La mécanique de `fetch`, `pull`, des branches de suivi et de `--force-with-lease` appartient à [Récupérer et envoyer du code](3-git-clone-pull-remote.md "Récupérer et envoyer du code") ; ici, seule l'habitude nous intéresse. Tirer, lancer les tests, puis pousser. Dans cet ordre, à chaque fois.

> :warning: « Tirer, puis pousser » n'est pas la même chose que « tirer, puis pousser à l'aveugle ». Un `git pull` qui fusionne le travail de quelqu'un d'autre dans le vôtre peut produire du code qui compile et qui est néanmoins faux : leur renommage de fonction plus votre nouveau site d'appel égale un build cassé que ni l'un ni l'autre n'a écrit. Lancez les tests *après* le pull, pas avant.

## Pourquoi ne pousse-t-on pas sur `master` ?

Il n'y a aucune raison technique. `git push origin master` fonctionne. Git n'a aucune notion de branche importante ; `master` et `main` sont des pointeurs exactement comme toutes les autres branches, comme nous l'avons vu dans [Jouer avec nos révisions](../1-understanding-git/7-play-with-git-revisions.md "Jouer avec nos révisions").

Les raisons sont sociales et opérationnelles.

* **La relecture.** Si votre changement atterrit directement sur la branche principale, personne ne l'a lu. Non pas parce que vos collègues sont paresseux, mais parce que vous ne leur avez donné aucun moment pour le lire.
* **La branche principale est une promesse.** Dans la plupart des équipes, elle signifie « c'est ce que nous déployons », ou au moins « c'est au vert ». Tout ce qui y atterrit sans passer les tests brise cette promesse pour tout le monde d'un coup. Voir [Un peu de structure SVP](4-git-repo-structure.md "Un peu de structure SVP") pour les écoles du master stable et du master instable.
* **La bissectabilité.** Une branche principale faite de commits relus, testés et autonomes peut être bissectée. Nous utiliserons `git bisect` dans [Garder un historique propre, se remettre de ses erreurs](6-git-cleanup.md "Garder un historique propre, se remettre de ses erreurs"), et vous voudrez cette propriété.

Les plateformes d'hébergement transforment ces coutumes en règles. Le vocabulaire diffère légèrement mais les mécanismes sont les mêmes partout (GitHub, GitLab, Forgejo, Codeberg, Bitbucket) :

* **Les règles de protection de branche** — le serveur refuse un push direct, ou un push forcé, ou la suppression de la branche protégée.
* **Les relectures obligatoires** — le changement ne peut pas être intégré tant que N personnes ne l'ont pas approuvé.
* **Les vérifications d'état obligatoires** — le changement ne peut pas être intégré tant que la suite de tests n'est pas passée dessus. C'est là que [L'intégration continue avec Git](../5-automation/2-git-ci.md "L'intégration continue avec Git") se branche.
* **`CODEOWNERS`** — un fichier du dépôt qui associe des chemins à des personnes ou à des équipes, de sorte que toucher à `db/migrations/` demande automatiquement une relecture à qui possède la base de données.

Et maintenant l'honnête contrepoint, parce que ce cours ne vous vend pas de dogme : bon nombre d'excellentes équipes poussent sur la branche principale toute la journée. Si vous êtes seul sur un projet, la cérémonie d'une pull request adressée à vous-même ne vous apporte rien. Et le développement sur le tronc — tout le monde committant de petits changements directement sur `main`, plusieurs fois par jour, derrière des feature flags, protégé par une suite de tests rapide et digne de confiance — est une manière de travailler réelle, respectée et très performante. Ce n'est pas « pas de processus » ; c'est le processus déplacé de la relecture-avant-fusion vers les tests-plus-les-drapeaux.

Ce qui n'est *pas* acceptable, c'est de pousser du travail non relu et non testé sur une branche depuis laquelle d'autres déploient, puis d'aller déjeuner.

## La « pull request », la « merge request » et leurs amies

Git lui-même n'a aucune notion de pull request. Cela vaut la peine d'être dit à voix haute, parce qu'une si grande partie de la vie quotidienne avec Git se déroule à l'intérieur d'une pull request.

Ce que Git a, c'est `git request-pull`, une commande qui génère un message en texte brut disant « merci de fusionner ma branche, voici où elle est, voici un résumé de ce qu'elle contient ». C'était le workflow originel du noyau Linux : vous envoyiez un e-mail à un mainteneur, il récupérait et fusionnait. La contribution de GitHub a été de mettre ce message dans une page web avec un fil de commentaires, un visualiseur de diff et un gros bouton vert. GitLab appelle le même objet une **merge request** — ce qui est sans doute le meilleur nom, puisque ce que vous demandez est une fusion.

Une pull request est donc trois choses empilées :

1. Une branche, dans un dépôt quelconque, qu'un serveur peut récupérer.
2. Une conversation qui y est attachée.
3. Un bouton qui exécute sur le serveur l'un de `git merge`, `git merge --squash`, ou `git rebase`.

Le point 3 est celui que les gens oublient, et c'est la raison pour laquelle le reste de ce chapitre compte. Ce menu déroulant innocent à côté du bouton vert — *Create a merge commit* / *Squash and merge* / *Rebase and merge* — choisit laquelle de trois choses assez différentes arrive à votre historique. Découvrons lesquelles.

## Les fusions non fast-forward : ce que `git merge` fait réellement

Construisons un petit dépôt pour y travailler. Deux commits sur `master`, puis une branche avec deux commits à elle.

```console
git init shop && cd shop
echo '# My shop' > readme.md
git add readme.md && git commit -m'Add the readme'
mkdir -p lib views public
echo 'function total(cart) { return sum(cart); }' > lib/shopping_cart.js
git add lib && git commit -m'Initial shopping cart code'
git switch -c banner
echo '<div class="banner">Winter sale</div>' > views/banner.html
git add views && git commit -m'Add the top banner markup'
echo '.banner { background: crimson }' > public/banner.css
git add public && git commit -m'Style the top banner'
git switch master
```

```console
git log --graph --oneline --all --decorate

* 36e6c8f (banner) Style the top banner
* eca5ea6 Add the top banner markup
* 62fe185 (HEAD -> master) Initial shopping cart code
* bbfd9f5 Add the readme
```

### La base de fusion

Voici l'idée la plus utile de ce chapitre, et presque personne ne l'apprend.

Quand Git fusionne deux branches, il ne les compare **pas** l'une à l'autre. Il trouve leur ancêtre commun le plus récent — la **base de fusion**, le *merge base* — et compare chaque branche à *celui-là*. Puis il combine les deux ensembles de changements.

C'est cela que veut dire « fusion à trois points » : trois entrées, la base et les deux côtés.

Lancez-la :

```console
git merge-base master banner

62fe1853d2a7aec2d7975bae70fa6dcd6711c33b
```

Comparez-la avec le sommet de `master` :

```console
git rev-parse master

62fe1853d2a7aec2d7975bae70fa6dcd6711c33b
```

Le même commit. La base de fusion *est* le sommet de la branche sur laquelle nous nous tenons. `banner` est simplement `master` plus deux commits ; les historiques n'ont pas divergé du tout.

C'est aussi pourquoi « le même changement fait deux fois dans deux branches » produit un conflit tandis que « un changement d'un côté et rien de l'autre » n'en produit pas : c'est la base qui dit à Git quel côté a réellement bougé. Sans base, Git devrait deviner. Avec une base, il peut savoir.

### Fast-forward : rien n'est créé, une référence se déplace

Parce que la base de fusion est le sommet de `master`, Git n'a rien à combiner. Tout ce qui est sur `master` est déjà un ancêtre de `banner`. Il prend donc le raccourci :

```console
git merge banner

Updating 62fe185..36e6c8f
Fast-forward
 public/banner.css | 1 +
 views/banner.html | 1 +
 2 files changed, 2 insertions(+)
 create mode 100644 public/banner.css
 create mode 100644 views/banner.html
```

Regardez ce qui est arrivé au graphe :

```console
git log --graph --oneline --all --decorate

* 36e6c8f (HEAD -> master, banner) Style the top banner
* eca5ea6 Add the top banner markup
* 62fe185 Initial shopping cart code
* bbfd9f5 Add the readme
```

Aucun nouveau commit. Pas un seul nouvel objet dans `.git/objects`. `master` et `banner` nomment maintenant le même commit, `36e6c8f`, exactement comme nous l'avions vu. Tout ce que Git a fait, c'est écrire quarante caractères dans `.git/refs/heads/master`. C'est tout ce qu'est un **fast-forward** : un pointeur avance le long d'une ligne qui existait déjà.

Vous pouvez prouver qu'il n'y a pas de commit de fusion en regardant l'objet :

```console
git cat-file -p HEAD

tree 90e3af950a6f74e6246508c7d231744e530be0e0
parent eca5ea6741808f64f3ed42d45d3a8f7c12028574
author Ori Pekelman <ori+git-training@pekelman.com> 1770108000 +0100
committer Ori Pekelman <ori+git-training@pekelman.com> 1770108000 +0100

Style the top banner
```

Un seul `parent`. C'est juste le dernier commit de la branche de fonctionnalité, coiffé d'un nouveau chapeau.

### `--no-ff` : rendre la fusion visible exprès

Défaisons cela et faisons-le autrement. Le **reflog** sait toujours où `master` se trouvait :

```console
git reset --hard master@{1}

HEAD is now at 62fe185 Initial shopping cart code
```

```console
git merge --no-ff banner -m "Merge branch 'banner'"

Merge made by the 'ort' strategy.
 public/banner.css | 1 +
 views/banner.html | 1 +
 2 files changed, 2 insertions(+)
 create mode 100644 public/banner.css
 create mode 100644 views/banner.html
```

Les mêmes fichiers, un historique entièrement différent :

```console
git log --graph --oneline --all --decorate

*   e10823d (HEAD -> master) Merge branch 'banner'
|\
| * 36e6c8f (banner) Style the top banner
| * eca5ea6 Add the top banner markup
|/
* 62fe185 Initial shopping cart code
* bbfd9f5 Add the readme
```

`--no-ff` dit à Git : même si tu *pouvais* te contenter de déplacer le pointeur, crée quand même un commit de fusion. Beaucoup d'équipes configurent cela pour leur branche principale, pour deux bonnes raisons :

1. **Le commit de fusion enregistre qu'une fonctionnalité a atterri comme une unité.** Six mois plus tard, `git log --first-parent master` se lit comme une liste de fonctionnalités plutôt que comme une liste de frappes au clavier.
2. **Cela rend la fonctionnalité annulable en un seul geste.** Ce qui nous amène à la suite.

### Un commit de fusion est un commit avec deux parents. C'est tout.

Dans [Au cœur du dépôt, au cœur du commit](../1-understanding-git/5-inside-git.md "Au cœur du dépôt, au cœur du commit"), nous avions mentionné, presque en passant, qu'un commit « identifie principalement un **tree** particulier plus ses **commit**s parents ». Voici le pluriel :

```console
git cat-file -p HEAD

tree 90e3af950a6f74e6246508c7d231744e530be0e0
parent 62fe1853d2a7aec2d7975bae70fa6dcd6711c33b
parent 36e6c8f267b889a0ee9dba55e15eb61276f69721
author Ori Pekelman <ori+git-training@pekelman.com> 1770109200 +0100
committer Ori Pekelman <ori+git-training@pekelman.com> 1770109200 +0100

Merge branch 'banner'
```

Deux lignes `parent`. C'est là toute la différence entre un commit de fusion et n'importe quel autre commit. Il n'y a pas d'« objet fusion » dans Git, pas d'enregistrement spécial de ce qui a été combiné, pas de résolution de conflit stockée. Un commit de fusion est un commit normal qui se trouve avoir deux ancêtres, pointant vers un **tree** qui contient le résultat combiné.

Tout le reste — les arcs dans `git log --graph`, « cette branche est fusionnée », `git revert -m 1` — c'est Git qui *déduit* des faits à partir de ces deux pointeurs.

L'ordre des parents compte, et il n'est pas arbitraire. Le **premier parent** est là où vous vous teniez quand vous avez tapé `git merge` (ici, `master`). Le second parent est ce que vous avez fusionné. `git show` les met sur la ligne `Merge:` :

```console
git show --stat HEAD

commit e10823db3ff81d11ec97e2dc8c49d53c2a4a8869
Merge: 62fe185 36e6c8f
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Tue Feb 3 10:00:00 2026 +0100

    Merge branch 'banner'

 public/banner.css | 1 +
```

Ce qui nous permet d'annuler toute la fonctionnalité en un commit. Vous devez dire à `git revert` quel parent compte comme « la ligne principale », et pour une fusion dans votre branche principale, c'est toujours le parent 1 :

```console
git revert -m 1 HEAD

[master a9dff07] Revert "Merge branch 'banner'"
 2 files changed, 2 deletions(-)
 delete mode 100644 public/banner.css
 delete mode 100644 views/banner.html
```

Les deux fichiers ont disparu, en un seul nouveau commit, sans qu'aucun historique n'ait été réécrit. Il y a un piège célèbre qui attend de l'autre côté de cette opération ; nous le désamorçons dans [le chapitre suivant](6-git-cleanup.md "Garder un historique propre, se remettre de ses erreurs").

Gardons la fusion et laissons tomber le revert : `git reset --hard HEAD~1`.

### `--ff-only`, et une fusion véritablement divergente

Jusqu'ici, nos branches n'avaient jamais divergé. Faisons-les diverger pour de bon. À partir du commit de fusion, nous créons deux branches qui touchent toutes deux à `lib/shopping_cart.js`, plus un commit sur `master` qui touche à tout autre chose :

```console
git switch -c vat
# éditer lib/shopping_cart.js  ->  return sum(cart) * 1.2;
git commit -am'Add VAT to the cart total'

git switch -c coupons master
echo 'function coupon(code) { ... }' > lib/coupons.js
git add lib && git commit -m'Add coupon code lookup'
# éditer lib/shopping_cart.js  ->  return sum(cart) - coupon(cart.code);
git commit -am'Apply coupon discount to cart total'

git switch master
echo 'Shipping is free above 50 euros.' > docs.txt
git add docs.txt && git commit -m'Document the free shipping threshold'
```

```console
git log --graph --oneline --all --decorate

* 12a1acf (HEAD -> master) Document the free shipping threshold
| * 5915988 (coupons) Apply coupon discount to cart total
| * 2584a0d Add coupon code lookup
|/
| * cb3973d (vat) Add VAT to the cart total
|/
*   e10823d Merge branch 'banner'
|\
{..}
```

Maintenant la base de fusion est *en arrière* des deux sommets :

```console
git merge-base master coupons

e10823db3ff81d11ec97e2dc8c49d53c2a4a8869
```

```console
git rev-parse master coupons

12a1acf243e7cb772888d7071eac1ca1bac8607c
59159881ed1a7b7aaa057c37f3b96639000d618a
```

Trois commits différents : une base et deux sommets. Un fast-forward est maintenant impossible, et si nous en exigeons un, Git le dit franchement :

```console
git merge --ff-only coupons

hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
```

`--ff-only` est un drapeau très utile précisément parce qu'il échoue. Régler `git config --global pull.ff only` transforme « `git pull` a discrètement inventé un commit de fusion dans mon dépôt » en un message d'erreur, ce qui est presque toujours ce que vous vouliez.

La vraie fusion réussit, parce que les deux côtés ont touché des fichiers différents (`docs.txt` d'un côté, `lib/coupons.js` et `lib/shopping_cart.js` de l'autre) :

```console
git merge coupons

Merge made by the 'ort' strategy.
 lib/coupons.js       | 3 +++
 lib/shopping_cart.js | 2 +-
 2 files changed, 4 insertions(+), 1 deletion(-)
 create mode 100644 lib/coupons.js
```

```console
git log --graph --oneline --all --decorate

*   f93b936 (HEAD -> master) Merge branch 'coupons'
|\
| * 5915988 (coupons) Apply coupon discount to cart total
| * 2584a0d Add coupon code lookup
* | 12a1acf Document the free shipping threshold
|/
| * cb3973d (vat) Add VAT to the cart total
|/
*   e10823d Merge branch 'banner'
{..}
```

> :information_source: **ort** est le nom du moteur de fusion de Git (« Ostensibly Recursive's Twin »). Il a remplacé l'ancienne stratégie `recursive` comme valeur par défaut dans Git 2.34 ; il est plus rapide et bien meilleur sur les renommages. Vous n'avez pas besoin d'en savoir plus que ceci : c'est lui qui fait la fusion à trois points pour vous.

### Lire un historique fusionné

Dès que des commits de fusion existent, `git log` doit choisir comment aplatir un graphe en une liste, et le choix compte.

```console
git log --oneline

f93b936 Merge branch 'coupons'
12a1acf Document the free shipping threshold
5915988 Apply coupon discount to cart total
2584a0d Add coupon code lookup
e10823d Merge branch 'banner'
36e6c8f Style the top banner
eca5ea6 Add the top banner markup
62fe185 Initial shopping cart code
bbfd9f5 Add the readme
```

Tout, entrelacé. Maintenant, ne suivons que les premiers parents :

```console
git log --oneline --first-parent

f93b936 Merge branch 'coupons'
12a1acf Document the free shipping threshold
e10823d Merge branch 'banner'
62fe185 Initial shopping cart code
bbfd9f5 Add the readme
```

Cinq commits au lieu de neuf, et chacun d'eux est un état par lequel `master` est réellement passé. Le travail *à l'intérieur* de chaque fonctionnalité a été replié dans son commit de fusion.

C'est pourquoi les systèmes de CI et les générateurs de notes de version utilisent si souvent `--first-parent` : c'est l'historique de la branche elle-même plutôt que l'historique de tout ce qui y a jamais coulé. C'est aussi le plus fort argument en faveur des fusions `--no-ff` — avec des fast-forwards, `--first-parent` n'a rien à replier.

`git log --graph` est l'autre moitié de la réponse, et `git log --graph --oneline --decorate --all` mérite un alias. Voir [Faire sienne la ligne de commande](../3-tooling-ecosystem/1-git-tools.md "Faire sienne la ligne de commande").

### Les fusions pieuvre

`git merge` accepte plus d'une branche. Le résultat est un commit avec plus de deux parents, et Git appelle la stratégie **octopus** :

```console
git merge feat-a feat-b feat-c -m 'Merge three features at once'

Fast-forwarding to: feat-a
Trying simple merge with feat-b
Trying simple merge with feat-c
Merge made by the 'octopus' strategy.
```

```console
git cat-file -p HEAD

tree 251bc909bb984807aa5fec53c3590582becb611c
parent 3cedfbc7eedef1ba231b245d9dd2defce24dc594
parent 03b4871a9c2f26fd0a81952e82688382e9e72153
parent 549222d148e85976eb2cb69a4f0e8256a3b7d87c
author Ori Pekelman <ori+git-training@pekelman.com> 1770800400 +0100
committer Ori Pekelman <ori+git-training@pekelman.com> 1770800400 +0100

Merge three features at once
```

Trois parents. Ce qui est une jolie chose à avoir vue une fois, et dont vous n'aurez essentiellement jamais besoin. Les fusions pieuvre ne peuvent pas résoudre de conflits du tout — au moment où deux des branches touchent les mêmes lignes, la stratégie abandonne, avec ce qui est peut-être le meilleur message d'erreur de Git :

```console
git merge feat-a feat-b feat-c

Fast-forwarding to: feat-a
Trying simple merge with feat-b
Simple merge did not work, trying automatic merge.
Auto-merging shared.txt
ERROR: content conflict in shared.txt
fatal: merge program failed
Automated merge did not work.
Should not be doing an octopus.
Merge with strategy octopus failed.
```

En effet. *Should not be doing an octopus.* Fusionnez vos branches une par une.

### La fusion écrasée : l'arbitrage honnête

La troisième option derrière ce bouton vert. Créons une branche avec le genre d'historique que nous produisons tous réellement :

```console
git switch -c filters
# ... trois commits plus tard ...
git log --oneline filters -4

8e6eb53 oops forgot the return
d4dbb27 wip filters, take 2
b747d6e wip filters
931150f Merge branch 'vat'
```

Personne n'a besoin de ces trois commits. `--squash` prend le *résultat* de la branche, le met dans votre arbre de travail et votre index, et s'arrête — sans committer, et sans enregistrer aucune relation avec la branche :

```console
git switch master
git merge --squash filters

Updating 931150f..8e6eb53
Fast-forward
Squash commit -- not updating HEAD
 lib/filters.js | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 lib/filters.js
```

```console
git status --short

A  lib/filters.js
```

Notez le « not updating HEAD ». Git a préparé les changements et s'est écarté. Vous les committez vous-même, avec un message qui décrit la fonctionnalité plutôt que votre lutte avec elle :

```console
git commit -m'Add the price filter'
```

Et maintenant regardez l'objet :

```console
git cat-file -p HEAD

tree abda1ee73e79458a3d911e1970203b504b741880
parent 931150fa7798c7d9dd60177ec3d17de04e9978b2
author Ori Pekelman <ori+git-training@pekelman.com> 1770282000 +0100
committer Ori Pekelman <ori+git-training@pekelman.com> 1770282000 +0100

Add the price filter
```

**Un seul** parent. C'est la conséquence cruciale, et ce n'est pas un bug : après une fusion écrasée, Git ne sait pas que `filters` a jamais été fusionnée. Les trois commits de la branche sont toujours là, et il n'y a aucun lien d'aucune sorte entre le nouveau commit et la branche dont il vient.

```console
git log --graph --oneline --decorate --all

* 450995f (HEAD -> master) Add the price filter
| * 8e6eb53 (filters) oops forgot the return
| * d4dbb27 wip filters, take 2
| * b747d6e wip filters
|/
*   931150f Merge branch 'vat'
{..}
```

```console
git branch --no-merged

  filters
```

```console
git branch -d filters

error: the branch 'filters' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D filters'
```

Git dit la vérité. Pour autant qu'il puisse en juger, le travail de cette branche n'a jamais été intégré.

Ce qui mène au vrai coût des fusions écrasées, celui qui mord les équipes : **des fusions écrasées répétées depuis une branche de longue durée génèrent les mêmes conflits encore et encore.** Parce que `master` n'a aucun lien d'ascendance vers `filters`, la base de fusion entre elles reste coincée à l'ancien point de bifurcation pour toujours. Chaque fusion ultérieure repropose chaque changement que la branche a jamais fait — y compris ceux déjà écrasés dans `master` — et Git doit vous interroger de nouveau sur tous.

Donc :

* Écraser la fusion d'une branche de fonctionnalité de courte durée que vous supprimez immédiatement : excellent. Historique propre sur la branche principale, aucun coût.
* Écraser la fusion à répétition depuis une branche de longue durée ou un fork que vous gardez : pénible, et de plus en plus pénible à chaque fois.

Il n'y a pas de bonne réponse ici, seulement un arbitrage que vous devriez faire exprès.

### `--abort` et `--continue`

Deux commandes à retenir avant d'approcher un conflit :

* `git merge --abort` — jeter toute la fusion et remettre l'arbre de travail exactement comme il était. Toujours disponible pendant qu'une fusion est en cours. Toujours sûr.
* `git merge --continue` — une fois que vous avez tout résolu et fait `git add`, terminer le commit de fusion. (`git commit` fait la même chose ; `--continue` est plus clair sur votre intention et refuse si vous n'avez pas fini.)

## Un révisionnisme parfaitement acceptable : qu'est-ce que le `rebase` ?

`merge` combine deux historiques. `rebase` en réécrit un.

Le nom est exact. Il prend vos commits et leur donne une nouvelle **base**. Pour chaque commit de votre branche, dans l'ordre, Git calcule le changement que ce commit a introduit et applique ce changement ailleurs, produisant un **nouveau commit** : nouveau parent, nouvel arbre, nouvelle date de committeur, donc nouveau **SHA**. Les originaux ne sont pas touchés, mais plus rien ne pointe vers eux.

Regardons. Une branche `search` avec deux commits, et un nouveau commit sur `master` :

```console
git log --graph --oneline --decorate -4 master search

* f7451c5 (master) Expand the readme
| * d32e2ee (HEAD -> search) Add the synonyms table
| * d9a976f Add the search entry point
|/
* 450995f Add the price filter
```

```console
git merge-base master search

450995f9a29e9cae6688f410ceeff1ff9d194495
```

```console
git rebase master

Successfully rebased and updated refs/heads/search.
```

```console
git log --graph --oneline --decorate -4 master search

* 1c37e7f (HEAD -> search) Add the synonyms table
* 63dee6d Add the search entry point
* f7451c5 (master) Expand the readme
* 450995f Add the price filter
```

Deux choses à remarquer, et regardez-les bien :

1. **Le graphe est une ligne droite.** Pas de fourche, pas de commit de fusion. `search` a maintenant l'air d'avoir été commencée après `Expand the readme`, ce qui est un mensonge — mais un mensonge utile et lisible.
2. **Les SHAs ont changé.** `d9a976f` est devenu `63dee6d` ; `d32e2ee` est devenu `1c37e7f`. Ce sont des objets différents. Même contenu, mêmes messages, commits différents.

La date d'auteur est préservée, la date de committeur ne l'est pas — exactement la distinction que nous avions tracée entre **author** et **committer** :

```console
git log -2 --format='%h %ad | %cd | %s' --date=iso

1c37e7f 2026-02-06 09:30:00 +0100 | 2026-02-06 11:00:00 +0100 | Add the synonyms table
63dee6d 2026-02-06 09:00:00 +0100 | 2026-02-06 11:00:00 +0100 | Add the search entry point
```

Et les anciens commits sont toujours dans `.git/objects`, non référencés mais parfaitement lisibles, parce que le reflog tient la porte ouverte :

```console
git reflog -6

1c37e7f HEAD@{0}: rebase (finish): returning to refs/heads/search
1c37e7f HEAD@{1}: rebase (pick): Add the synonyms table
63dee6d HEAD@{2}: rebase (pick): Add the search entry point
f7451c5 HEAD@{3}: rebase (start): checkout master
d32e2ee HEAD@{4}: checkout: moving from master to search
f7451c5 HEAD@{5}: commit: Expand the readme
```

```console
git log --oneline search@{1}

d32e2ee Add the synonyms table
d9a976f Add the search entry point
450995f Add the price filter
```

Voilà l'ancienne branche, intacte. `git reset --hard search@{1}` la remettrait en place. Intériorisez ceci dès maintenant : **un rebase est annulable** tant que vous avez le reflog. Nous y revenons au chapitre suivant.

### `git rebase --onto`

Un simple `git rebase main` veut dire « rejoue tout depuis la base de fusion sur `main` ». Parfois vous voulez rejouer un *autre* intervalle — le plus souvent quand vous avez une branche empilée sur une autre et que celle du dessous ne va pas atterrir.

`git rebase --onto <nouvelle-base> <upstream> [<branche>]` se lit ainsi : prends les commits qui sont dans `<branche>` mais pas dans `<upstream>`, et pose-les sur `<nouvelle-base>`.

```console
git log --graph --oneline --all --decorate

* 4fc5e52 (main) Bump the dependency lockfile
| * 307dc83 (HEAD -> feature/checkout-tests) Add a second checkout test
| * cef7bbb Add checkout tests
| * 662e080 (feature/checkout) Add checkout skeleton
|/
* 993cd04 Initial commit
```

```console
git rebase --onto main feature/checkout

Successfully rebased and updated refs/heads/feature/checkout-tests.
```

```console
git log --graph --oneline --all --decorate

* 9aaef2d (HEAD -> feature/checkout-tests) Add a second checkout test
* 6574a45 Add checkout tests
* 4fc5e52 (main) Bump the dependency lockfile
| * 662e080 (feature/checkout) Add checkout skeleton
|/
* 993cd04 Initial commit
```

Les deux commits de tests ont été chirurgicalement soulevés de `feature/checkout` et déposés sur `main`. C'est aussi ainsi que l'on retire un commit du milieu d'une branche : `git rebase --onto <commit>~1 <commit>`.

### `git rebase -i` : la bonne partie

Le rebase interactif est le moment où le rebase cesse d'être de la plomberie pour devenir un outil d'édition. `git rebase -i master` ouvre votre éditeur sur une liste de tâches :

```console
pick 63dee6d # Add the search entry point
pick 1c37e7f # Add the synonyms table

# Rebase f7451c5..1c37e7f onto f7451c5 (2 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
#                    commit's log message, unless -C is used, in which case
#                    keep only this commit's message; -c is same as -C but
#                    opens the editor
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
{..}
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
```

Vous éditez cette liste et Git l'exécute. Notez l'ordre : **le plus ancien d'abord**, l'inverse de `git log`. Celles que vous utiliserez constamment :

* `reword` — corriger un message de commit sans toucher au contenu.
* `squash` / `fixup` — fondre un commit dans celui du dessus. `squash` vous laisse combiner les deux messages ; `fixup` jette le second, ce qui est généralement ce que vous voulez pour un commit du genre « ah oui, et corriger la coquille aussi ».
* `drop` — supprimer un commit. (Supprimer la ligne fait la même chose ; `drop` est plus facile à relire.)
* `edit` — s'arrêter là et vous laisser amender, scinder, ou lancer quelque chose.
* `exec` — lancer une commande après ce commit. `git rebase -i --exec 'npm test' master` lance la suite de tests après chaque commit de votre branche, ce qui est une merveilleuse façon de découvrir que le commit numéro trois ne compile pas.

### `--autosquash` : les fixups sans la comptabilité

Mieux que de penser à marquer des choses en `fixup` plus tard : marquez-les au moment où vous les faites.

```console
git commit --fixup 1c37e7f
```

Ceci crée un commit dont le message est littéralement `fixup! Add the synonyms table` :

```console
git log --oneline -3

e367775 fixup! Add the synonyms table
1c37e7f Add the synonyms table
63dee6d Add the search entry point
```

Maintenant `git rebase -i --autosquash master` lit ces préfixes et construit la liste de tâches pour vous, déjà réordonnée :

```console
pick 63dee6d # Add the search entry point
pick 1c37e7f # Add the synonyms table
fixup e367775 # fixup! Add the synonyms table
```

Enregistrez, et le fixup disparaît dans sa cible. Il y a aussi `git commit --squash <commit>` (même idée, garde les deux messages) et `git commit --fixup=amend:<commit>` / `--fixup=reword:<commit>` pour changer le contenu ou le message d'un commit plus ancien sans l'étape interactive.

Activez-le définitivement avec `git config --global rebase.autosquash true`.

> :information_source: Des outils comme `git absorb` vont un cran plus loin : ils regardent vos changements non indexés, déterminent à quel commit de votre branche chaque section appartient, et génèrent tous les commits `fixup!` pour vous. Agréable une fois que vous êtes à l'aise avec ce qu'il automatise.

### Quand un rebase s'arrête

Un rebase applique les commits un par un, il peut donc s'arrêter en chemin. Trois sorties :

* `git rebase --continue` — j'ai corrigé, continue.
* `git rebase --skip` — laisse tomber ce commit entièrement et continue. Utile quand le changement se trouve déjà en amont.
* `git rebase --abort` — remets tout comme c'était. Toujours disponible. Toujours sûr.

En voici un qui s'arrête, et il contient un piège qu'il vaut la peine de pointer du doigt. Nous rebasons `vat` sur un `master` qui contient déjà le changement des coupons sur la même ligne :

```console
git rebase master

Auto-merging lib/shopping_cart.js
CONFLICT (content): Merge conflict in lib/shopping_cart.js
error: could not apply cb3973d... Add VAT to the cart total
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
```

```console
cat lib/shopping_cart.js

function total(cart) {
<<<<<<< HEAD
  return sum(cart) - coupon(cart.code);
||||||| parent of cb3973d (Add VAT to the cart total)
  return sum(cart);
=======
  return sum(cart) * 1.2;
>>>>>>> cb3973d (Add VAT to the cart total)
}
```

> :warning: Pendant un rebase, **`HEAD` est la branche sur laquelle vous rebasez, pas la vôtre.** « Ours » (le nôtre) est `master` ; « theirs » (le leur) est votre propre commit. Cela inverse le sens de `--ours` et `--theirs` par rapport à une fusion, et c'est une manière classique de jeter précisément le travail que vous essayiez de garder. Lisez les étiquettes, pas vos suppositions.

Remarquez aussi ce que dit `git status` pendant un rebase :

```console
git status

interactive rebase in progress; onto f93b936
Last command done (1 command done):
   pick cb3973d # Add VAT to the cart total
No commands remaining.
You are currently rebasing branch 'vat' on 'f93b936'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)
```

Git vous dit exactement où vous êtes et quelles sont vos options. Lisez-le. C'est écrit là.

### Les branches empilées : `--update-refs`

Si vous travaillez en piles — la branche B construite sur la branche A, les deux ouvertes en pull requests — alors rebaser B laissait autrefois A pointant vers les anciens commits abandonnés ; depuis Git 2.38, `git rebase --update-refs` déplace avec lui chaque branche qui pointait dans l'intervalle rebasé, et `git config --global rebase.updateRefs true` en fait la valeur par défaut.

### La règle d'or du rebase

> :warning: **Ne rebasez jamais des commits qui existent en dehors de votre propre dépôt.**
>
> Le rebase ne modifie pas les commits ; il les remplace par de nouveaux. Si quelqu'un d'autre a les anciens — parce que vous les avez poussés et qu'il les a tirés — alors après votre rebase, vous détenez tous les deux deux copies parallèles du même travail avec des SHAs différents. Git ne peut pas savoir qu'elles sont liées. Son prochain `git pull` fusionnera les deux copies, chaque commit apparaîtra deux fois, et le désordre qui en résulte est désagréable à nettoyer et très facile à aggraver.

Maintenant l'exception honnête, parce que la règle telle qu'on l'énonce d'habitude est plus stricte que la pratique.

« En dehors de votre propre dépôt » ne veut pas dire « poussé ». Cela veut dire « quelqu'un d'autre l'a ». Votre propre branche de fonctionnalité sur le serveur partagé, sur laquelle vous seul committez et qui existe pour qu'une pull request ait quelque chose vers quoi pointer — personne n'a basé de travail là-dessus. La rebaser et forcer le push n'est pas seulement acceptable, c'est le workflow quotidien ordinaire dans un très grand nombre d'entreprises :

```console
git rebase main
# lancer les tests
git push --force-with-lease
```

Utilisez `--force-with-lease`, jamais `--force` tout court. Il refuse le push si la branche distante a bougé depuis votre dernier fetch, ce qui est précisément le cas « oh non, quelqu'un d'autre *travaillait* ici ». Voir [Récupérer et envoyer du code](3-git-clone-pull-remote.md "Récupérer et envoyer du code").

Là où la règle est absolue : `main`, `master`, `develop`, les branches de release, toute branche sur laquelle un collègue a poussé, et toute branche dont quelqu'un a cherry-piqué ou repris les commits. En cas de doute, demandez. Cela coûte un message.

### Fusionner ou rebaser ?

Cette dispute a consommé plus d'heures de développeur que le code dont il était question. Voici une position plutôt qu'une guerre.

**Rebasez votre propre travail avant qu'il n'atterrisse.** Vos quinze commits exploratoires, dont trois ne compilent pas, ne sont pas une contribution à l'historique partagé — ce sont des notes. Nettoyez-les. `rebase -i` jusqu'à ce que la branche se lise comme une séquence d'étapes qu'un collègue pourrait relire une par une. C'est de la politesse, et c'est le véritable argument en faveur du rebase : non pas un historique linéaire pour lui-même, mais un historique *relisible*.

**Fusionnez pour intégrer.** Quand deux branches partagées doivent se rejoindre, fusionnez-les. Le commit de fusion est une affirmation vraie sur ce qui s'est passé ; un rebase en serait une fausse, et il réécrirait des commits que d'autres possèdent. Utilisez `--no-ff` si vous voulez que les fonctionnalités restent visibles comme des unités.

**Ne réécrivez jamais ce sur quoi d'autres ont bâti.** Non négociable, en vertu de la règle d'or.

Notez que ces positions ne sont pas en tension. « Rebaser ma branche, puis la fusionner » est un workflow cohérent, et c'est ce que « Rebase and merge » ou « Squash and merge » sur une plateforme d'hébergement approxime. La guerre de religion, ce sont surtout des gens qui défendent des moitiés différentes de la même phrase.

## `git commit --amend`

La plus petite des réécritures, et celle que vous utiliserez le plus.

`git commit --amend` remplace le dernier commit par un nouveau, construit à partir de l'index courant. Nouvel arbre, ou nouveau message, ou les deux — et donc un nouveau **SHA**. C'est un rebase d'un seul commit sous un nom plus sympathique.

Vous avez committé avec une coquille dans le message :

```console
git log --oneline -1

0b690b2 Implment the search lookup
```

```console
git commit --amend -m'Implement the search lookup'
git log --oneline -1

4b0a2d0 Implement the search lookup
```

Le hash a changé : `0b690b2` → `4b0a2d0`. C'est un commit différent. `0b690b2` existe toujours dans `.git/objects` mais plus rien ne pointe vers lui.

Ou, bien plus courant : vous avez oublié un fichier.

```console
git add lib/search.test.js
git status --short

A  lib/search.test.js
```

```console
git commit --amend --no-edit
git show --stat --oneline HEAD

70f0200 Implement the search lookup
 lib/search.js      | 4 +++-
 lib/search.test.js | 1 +
 2 files changed, 4 insertions(+), 1 deletion(-)
```

`--no-edit` veut dire « garde le message, n'ouvre pas mon éditeur ». Le fichier de test fait maintenant partie du commit auquel il appartient, ce qui est là où un relecteur ira le chercher.

Et le reflog a toute la trace, avec des marqueurs `(amend)` pour que vous puissiez voir ce qui s'est passé :

```console
git reflog -4

70f0200 HEAD@{0}: commit (amend): Implement the search lookup
4b0a2d0 HEAD@{1}: commit (amend): Implement the search lookup
0b690b2 HEAD@{2}: commit: Implment the search lookup
8955a02 HEAD@{3}: checkout: moving from master to search
```

> :warning: `--amend` est une réécriture, la règle d'or s'y applique donc pleinement. Amender un commit que vous avez déjà poussé sur une branche partagée signifie qu'il faudra forcer le push de la branche, et tous ceux qui avaient tiré l'ancien obtiennent un doublon. Sur votre propre branche de pull request : très bien, amendez et `--force-with-lease`. Sur `main` : non.

## La gestion des conflits

Le moment de casser quelque chose exprès. Dans notre dépôt, `master` a le changement des coupons et `vat` a le changement de TVA, tous deux sur la même ligne de `lib/shopping_cart.js`.

```console
git merge vat

Auto-merging lib/shopping_cart.js
CONFLICT (content): Merge conflict in lib/shopping_cart.js
Automatic merge failed; fix conflicts and then commit the result.
```

Notez ce que Git n'a *pas* fait : il n'a pas abandonné, et il n'a pas désigné de gagnant. Il a fusionné tout ce qu'il pouvait, a laissé le reste pour vous, et s'est arrêté dans un état intermédiaire bien défini. `git status` décrit cet état :

```console
git status

On branch master
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   lib/shopping_cart.js

no changes added to commit (use "git add" and/or "git commit -a")
```

« Unmerged paths », « both modified ». Et pour la liste de ces seuls fichiers, sous une forme que vous pouvez brancher sur autre chose :

```console
git diff --diff-filter=U --name-only

lib/shopping_cart.js
```

### Les marqueurs

```console
cat lib/shopping_cart.js

function total(cart) {
<<<<<<< HEAD
  return sum(cart) - coupon(cart.code);
=======
  return sum(cart) * 1.2;
>>>>>>> vat
}
```

Trois marqueurs :

* `<<<<<<< HEAD` — tout jusqu'au marqueur suivant est **le nôtre** : la branche sur laquelle nous sommes, `master`.
* `=======` — le séparateur.
* `>>>>>>> vat` — tout ce qui est au-dessus depuis le séparateur est **le leur** : ce que nous fusionnons.

C'est tout ce qu'est un conflit. Git a écrit les deux versions candidates dans le fichier avec des étiquettes dessus. Le fichier n'est maintenant plus du JavaScript valide, exprès, pour que vous ne puissiez pas le livrer par accident.

### `merge.conflictStyle = zdiff3`

Il manque aux marqueurs par défaut l'information la plus utile : ce que la ligne *était*. Sans la base, vous ne pouvez pas dire qui a changé quoi. Corrigeons cela définitivement :

```console
git config --global merge.conflictStyle zdiff3
```

Abandonnons et recommençons :

```console
git merge --abort
git merge vat
cat lib/shopping_cart.js

function total(cart) {
<<<<<<< HEAD
  return sum(cart) - coupon(cart.code);
||||||| e10823d
  return sum(cart);
=======
  return sum(cart) * 1.2;
>>>>>>> vat
}
```

Une quatrième section, entre `|||||||` et `=======` : **la base de fusion**. Et maintenant le conflit raconte une histoire. La ligne a commencé sa vie comme `return sum(cart);`. Un côté a soustrait un coupon. L'autre a multiplié par 1,2. Ni l'un ni l'autre n'a supprimé le travail de l'autre — chacun a fait une chose à un point de départ commun, et la résolution correcte est manifestement *les deux*.

Vous n'auriez pas pu savoir cela avec les marqueurs à deux voies. Il aurait fallu deviner, ou aller lire les deux branches. Cette unique ligne de configuration est, honnêtement, le réglage le plus rentable de ce chapitre.

> :information_source: L'ancien style `diff3` fait la même chose ; `zdiff3` (Git 2.35+) sort en plus de la région conflictuelle les lignes communes aux trois versions, si bien que les marqueurs n'enveloppent que la partie qui est véritablement en désaccord. Utilisez `zdiff3`.

### Sous le capot : l'index contient trois versions

Voici le dividende d'avoir passé la partie 1 à l'intérieur de `.git`. Nous connaissons l'**index** comme une liste plate de fichiers indexés. Pendant un conflit, c'est quelque chose de plus intéressant : il peut contenir jusqu'à *trois* entrées pour le même chemin, appelées des stages.

```console
git ls-files -u

100644 353719e573b2c1fd0bcdc111025dc63d3c7e6419 1	lib/shopping_cart.js
100644 f08164fe0025e9d4904120efdcc6ada1ca45f21e 2	lib/shopping_cart.js
100644 6ac791d004dce05719c29157dc06c4745c2ea515 3	lib/shopping_cart.js
```

Trois **blob**s, un chemin, et un numéro dans la dernière colonne :

* **stage 1** — la version de la base de fusion.
* **stage 2** — la nôtre (`HEAD`).
* **stage 3** — la leur.

Et vous pouvez lire chacune directement, avec la syntaxe `:<stage>:<chemin>` :

```console
git show :1:lib/shopping_cart.js

function total(cart) {
  return sum(cart);
}
```

```console
git show :2:lib/shopping_cart.js

function total(cart) {
  return sum(cart) - coupon(cart.code);
}
```

```console
git show :3:lib/shopping_cart.js

function total(cart) {
  return sum(cart) * 1.2;
}
```

Il n'y a de magie nulle part. Un conflit, c'est une entrée d'index à plusieurs stages plus un fichier avec des marqueurs dedans. Chaque outil qui vous aide à résoudre des conflits — les outils de fusion à trois panneaux, les boutons de résolution en ligne de votre éditeur, `zdiff3` lui-même — lit ces trois blobs. Maintenant vous aussi, sans aucun outil, ce qui est exactement le moment où les conflits cessent de faire peur.

> :information_source: `:0:<chemin>` est le stage normal, résolu. C'est pourquoi `git show :0:readme.md` — ou son écriture habituelle, `git show :readme.md` — vous montre la version indexée d'un fichier. Même mécanisme.

### Résoudre

Le déroulé, et il est court :

1. **Éditez le fichier.** Retirez les marqueurs. Produisez le code que vous voulez réellement.
2. **`git add <fichier>`.** Ceci écrase les trois stages en une seule entrée de stage 0 : c'est ainsi que vous dites « résolu ».
3. **`git commit`**, ou `git merge --continue`.

```console
git add lib/shopping_cart.js
git status --short

M  lib/shopping_cart.js
```

```console
git ls-files -u
```

Rien. Les stages ont disparu, donc le conflit a disparu.

```console
git merge --continue

[master 931150f] Merge branch 'vat'
```

Quelques aides pour l'étape 1 :

* `git checkout --ours <fichier>` / `git checkout --theirs <fichier>` — remplacer tout le fichier par un côté. Acceptable pour un fichier généré ou un fichier de verrouillage de dépendances ; un signal d'alarme sur du code source.
* `git checkout -m <fichier>` — remettre les marqueurs de conflit si vous avez massacré le fichier. Véritablement utile et quasi inconnu.
* `git show :1:<fichier> > <fichier>` — mettre un stage particulier dans l'arbre de travail ; `:1` est la base, qui est parfois l'endroit le plus propre d'où repartir. (`git checkout-index --stage=1 -f -- <fichier>` fait la même chose.)
* `git mergetool` — lancer un outil de fusion graphique à trois panneaux, configuré avec `merge.tool`. Meld, Beyond Compare, `vimdiff`, votre IDE. Vaut la peine d'être configuré une fois ; voir [Les éditeurs, les IDE et le navigateur de fichiers](../3-tooling-ecosystem/4-git-ides.md "Les éditeurs, les IDE et le navigateur de fichiers").
* `git diff` sans argument pendant un conflit montre un **diff combiné** — la différence par rapport aux *deux* parents à la fois, ce qui est une manière compacte de ne voir que les lignes encore en litige.

### `-X ours` / `-X theirs`, et leur cousine dangereuse

`-X` passe une option à la stratégie de fusion : « quand tu tombes sur une section conflictuelle, préfère ce côté-ci plutôt que de me demander ».

```console
git merge -X ours vat

Auto-merging lib/shopping_cart.js
Merge made by the 'ort' strategy.
```

```console
cat lib/shopping_cart.js

function total(cart) {
  return sum(cart) - coupon(cart.code);
}
```

Le changement de TVA a perdu, silencieusement. Avec `-X theirs`, c'est le changement des coupons qui perd. Surtout, `-X` ne décide que des sections *conflictuelles* — tout ce que les deux côtés ont fait sans se heurter est toujours fusionné normalement. Si `vat` avait aussi ajouté un nouveau fichier, `-X ours` l'aurait gardé.

`--strategy=ours` est un instrument complètement différent, bien plus brutal :

```console
git merge --strategy=ours vat

Merge made by the 'ours' strategy.
```

Ceci crée un commit de fusion à deux parents dont l'arbre est *identique au nôtre*. Rien de l'autre branche ne traverse — ni les sections conflictuelles, ni les non conflictuelles, ni les nouveaux fichiers. Ce que cela accomplit, c'est d'enregistrer dans le graphe « cette branche a été traitée », de sorte que `git branch --merged` la liste et que les fusions futures la sautent.

C'est occasionnellement ce que vous voulez (une branche abandonnée dont vous voulez que Git cesse de vous la proposer). Ce n'est jamais ce que vous voulez si vous pensiez que cela signifiait `-X ours`.

### Le même conflit, encore et encore : `rerere`

Une branche de longue durée, rebasée quotidiennement sur un `main` mouvant ? Vous résoudrez le même conflit tous les jours. Git peut le mémoriser.

```console
git config --global rerere.enabled true
```

**rerere** signifie « reuse recorded resolution », réutiliser une résolution enregistrée. Avec l'option activée, le premier conflit ressemble à ceci :

```console
git merge vat

Auto-merging lib/shopping_cart.js
CONFLICT (content): Merge conflict in lib/shopping_cart.js
Recorded preimage for 'lib/shopping_cart.js'
Automatic merge failed; fix conflicts and then commit the result.
```

Vous résolvez et committez, et Git dit :

```console
Recorded resolution for 'lib/shopping_cart.js'.
```

Maintenant jetez la fusion et refaites-la, comme le ferait un rebase :

```console
git reset --hard HEAD~1
git merge vat

Auto-merging lib/shopping_cart.js
CONFLICT (content): Merge conflict in lib/shopping_cart.js
Resolved 'lib/shopping_cart.js' using previous resolution.
Automatic merge failed; fix conflicts and then commit the result.
```

```console
cat lib/shopping_cart.js

function total(cart) {
  return (sum(cart) - coupon(cart.code)) * 1.2;
}
```

Votre résolution, rejouée. Les résolutions enregistrées vivent dans `.git/rr-cache`, indexées par la forme du conflit plutôt que par commit, ce qui explique qu'elles survivent à un rebase qui jette et recrée chacun des commits impliqués.

Notez que le fichier est corrigé mais que le chemin est toujours non fusionné (`git status --short` montre `UU`) : rerere remplit la réponse, vous devez toujours faire `git add`. C'est délibéré — vous avez l'occasion de vérifier que la résolution rejouée a toujours du sens.

Activez ceci. Il n'y a pas d'inconvénient digne d'être mentionné, et le jour où vous rebaserez une branche vieille de deux semaines, vous serez content.

### Le piège

Il y a une manière de résoudre les conflits qui produit du logiciel cassé de façon fiable, et tout le monde l'a faite un vendredi à 18 h :

> :warning: Résoudre un conflit en supprimant un côté sans le lire n'est pas de la résolution de conflit. C'est annuler silencieusement le travail d'un collègue.
>
> Un conflit veut dire que deux personnes ont changé les mêmes lignes pour deux raisons différentes. Les deux raisons s'appliquent probablement encore. Un `git checkout --theirs` sur un fichier source, ou garder aveuglément `HEAD`, en jette une — et, c'est là le côté vicieux, les tests passeront peut-être quand même, parce que la fonctionnalité que vous venez de supprimer a emporté ses propres tests avec elle, ou n'en a jamais eu.

Les habitudes qui l'évitent : activez `zdiff3` pour voir ce qu'était la ligne avant que l'un ou l'autre côté n'y touche ; utilisez `git log -p --merge` pour lire les commits des deux côtés qui ont touché au fichier en conflit ; et quand vous ne pouvez véritablement pas deviner ce que l'autre côté essayait de faire, allez le lui demander. `git blame` vous dira à qui demander, ce qui est notre prochain sujet.

## Qui a fait quoi ? De l'archéologie avec `git blame`

`git blame` est une commande mal nommée. Personne de sensé ne s'en sert pour attribuer une faute ; nous nous en servons pour comprendre une ligne de code que nous n'avons pas écrite, et très souvent pour découvrir qu'elle a été écrite pour une bonne raison à laquelle nous n'avions pas pensé. Appelez cela de l'archéologie et cela devient un outil différent.

[Jouer avec nos révisions](../1-understanding-git/7-play-with-git-revisions.md "Jouer avec nos révisions") a présenté la forme de base. Voici la version dont vous avez réellement besoin dans un dépôt qui a de l'histoire.

Notre `lib/shopping_cart.js` est passé entre plusieurs mains, puis quelqu'un a passé un formateur sur toute la base de code :

```console
git log --oneline -4

daa5545 Run prettier over the whole codebase
5146306 Add shipping cost and the cart label
f7451c5 Expand the readme
450995f Add the price filter
```

```console
git blame lib/shopping_cart.js

62fe1853 (Ori Pekelman 2026-02-02 07:00:00 +0100  1) function total(cart) {
daa55453 (Lea Prettier 2026-02-08 14:00:00 +0100  2)   return (sum(cart) - coupon(cart.code)) * 1.2;
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100  3) }
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100  4)
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100  5) function shipping(cart) {
daa55453 (Lea Prettier 2026-02-08 14:00:00 +0100  6)   return total(cart) > 50 ? 0 : 4.9;
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100  7) }
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100  8)
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100  9) function label(cart) {
daa55453 (Lea Prettier 2026-02-08 14:00:00 +0100 10)   return 'Total: ' + total(cart);
62fe1853 (Ori Pekelman 2026-02-02 07:00:00 +0100 11) }
```

Inutile. Toutes les lignes intéressantes appartiennent désormais à « Run prettier over the whole codebase », ce qui ne nous dit précisément rien sur la raison pour laquelle le multiplicateur de TVA vaut 1,2.

### `-w` et `--ignore-rev` : survivre à un reformatage

La première chose à essayer est `-w`, qui ignore les changements purement d'espacement :

```console
git blame -w lib/shopping_cart.js

62fe1853 (Ori Pekelman 2026-02-02 07:00:00 +0100  1) function total(cart) {
daa55453 (Lea Prettier 2026-02-08 14:00:00 +0100  2)   return (sum(cart) - coupon(cart.code)) * 1.2;
{..}
```

Toujours Lea. Parce que ce reformatage n'a pas seulement changé les espaces — il a aussi ajouté des points-virgules, transformé `4.90` en `4.9` et les guillemets doubles en simples. `-w` ne peut rien y faire.

`--ignore-rev` le peut. Il dit à blame de regarder *à travers* un commit et d'attribuer les lignes à qui les a touchées avant lui :

```console
git blame --ignore-rev daa5545 lib/shopping_cart.js

62fe1853 (Ori Pekelman 2026-02-02 07:00:00 +0100  1) function total(cart) {
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100  2)   return (sum(cart) - coupon(cart.code)) * 1.2;
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100  3) }
{..}
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100  6)   return total(cart) > 50 ? 0 : 4.9;
{..}
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100 10)   return 'Total: ' + total(cart);
62fe1853 (Ori Pekelman 2026-02-02 07:00:00 +0100 11) }
```

Le commit du formateur est devenu invisible et la véritable histoire est de retour.

Personne ne veut taper ce hash à chaque fois, et personne ne devrait avoir à le faire. Mettez les hashes de vos commits de formatage dans un fichier, committez le fichier, et pointez Git dessus :

```console
git rev-parse daa5545 > .git-blame-ignore-revs
git add .git-blame-ignore-revs
git commit -m'Ignore the prettier commit in git blame'
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

À partir de maintenant, un simple `git blame` fait ce qu'il faut :

```console
git blame -L 1,3 lib/shopping_cart.js

62fe1853 (Ori Pekelman 2026-02-02 07:00:00 +0100 1) function total(cart) {
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100 2)   return (sum(cart) - coupon(cart.code)) * 1.2;
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100 3) }
```

Je vais être catégorique sur ce point, parce que c'est véritablement utile et que presque personne ne le sait. Si votre projet a un jour passé un formateur, un linter avec `--fix`, ou un renommage de masse sur la base de code, et que vous n'avez pas créé de `.git-blame-ignore-revs`, alors vous avez inutilement détruit l'utilité de `git blame` pour tous les fichiers concernés. Cela coûte trois lignes. GitHub et GitLab honorent tous deux ce fichier dans leurs vues blame web également. Faites-le aujourd'hui.

### Le reste des options utiles

* `-L 10,20 <fichier>` — seulement ces lignes. `-L :nomDeFonction <fichier>` fonctionne aussi et ne blame que cette fonction. Une fois que vous connaissez `-L`, `git blame` devient utilisable sur un fichier de trois mille lignes.
* `-C` — détecter les lignes **copiées ou déplacées depuis un autre fichier** dans le même commit. Répétez-le (`-C -C`, `-C -C -C`) pour chercher plus dur et plus large.
* `-M` — détecter les lignes déplacées *à l'intérieur* du même fichier, pour que réordonner des fonctions ne réinitialise pas leur historique.
* `<révision> -- <fichier>` — blamer le fichier tel qu'il était à un moment du passé. C'est ainsi qu'on enquête sur une ligne qui a depuis été supprimée.
* `-w` — ignorer les espaces. `--ignore-rev` / `blame.ignoreRevsFile` — comme ci-dessus.

`-C` est celle qui surprend les gens. Quelqu'un déplace une fonction vers un nouveau module, et un blame ordinaire dit que le tout a un jour :

```console
git log --oneline -2

cbc6be5 Move formatMoney into lib/money.js
b50f221 Add the money formatting helper
```

```console
git blame lib/money.js

cbc6be58 (Ori Pekelman 2026-02-10 09:00:00 +0100 1) function formatMoney(amount, currency) {
cbc6be58 (Ori Pekelman 2026-02-10 09:00:00 +0100 2)   const rounded = Math.round(amount * 100) / 100;
cbc6be58 (Ori Pekelman 2026-02-10 09:00:00 +0100 3)   const symbol = currency === 'EUR' ? '€' : '$';
cbc6be58 (Ori Pekelman 2026-02-10 09:00:00 +0100 4)   return symbol + rounded.toFixed(2);
cbc6be58 (Ori Pekelman 2026-02-10 09:00:00 +0100 5) }
```

Avec `-C`, Git suit le bloc à travers le déplacement — et imprime même d'où il vient :

```console
git blame -C lib/money.js

b50f2215 lib/shopping_cart.js (Ori Pekelman 2026-02-09 09:00:00 +0100 1) function formatMoney(amount, currency) {
b50f2215 lib/shopping_cart.js (Ori Pekelman 2026-02-09 09:00:00 +0100 2)   const rounded = Math.round(amount * 100) / 100;
b50f2215 lib/shopping_cart.js (Ori Pekelman 2026-02-09 09:00:00 +0100 3)   const symbol = currency === 'EUR' ? '€' : '$';
b50f2215 lib/shopping_cart.js (Ori Pekelman 2026-02-09 09:00:00 +0100 4)   return symbol + rounded.toFixed(2);
b50f2215 lib/shopping_cart.js (Ori Pekelman 2026-02-09 09:00:00 +0100 5) }
```

La deuxième colonne est le fichier dans lequel les lignes vivaient à l'époque. Ça, c'est de la vraie archéologie.

### Le pic à glace : quand la ligne a disparu

`git blame` ne peut vous parler que des lignes qui existent encore. Très souvent, la question est l'inverse : *il y avait un appel à `legacyCheckout()` par ici — où est-il passé ?*

C'est le *pickaxe*, le pic à glace de `git log`.

```console
git log --oneline -S'4.90'

daa5545 Run prettier over the whole codebase
5146306 Add shipping cost and the cart label
```

`-S<chaîne>` trouve les commits où le **nombre d'occurrences** de cette chaîne a changé — c'est-à-dire les commits qui l'ont ajoutée ou retirée. Deux commits : celui qui a introduit `4.90` et celui qui l'a transformé en `4.9`. Ajoutez `-p` et vous voyez les diffs.

`-G<regex>` est la cousine plus lâche : tout commit dont le diff contient une ligne correspondant au motif, même si le compte n'a pas changé.

```console
git log --oneline -G'coupon'

daa5545 Run prettier over the whole codebase
5146306 Add shipping cost and the cart label
5915988 Apply coupon discount to cart total
2584a0d Add coupon code lookup
```

Règles empiriques : `-S` pour trouver où quelque chose est apparu ou a disparu ; `-G` pour trouver tous les commits qui ont touché au sujet. Les deux acceptent `-- <chemin>` pour restreindre la recherche. `git log -S` sur un nom de fonction est fréquemment la manière la plus rapide de comprendre un morceau de code dans un dépôt inconnu, et il est sous-utilisé surtout parce que les gens ne dépassent jamais `git log --oneline`.

## Votre historique est un message : écrire des commits

Nous avons passé ce chapitre sur des outils pour lire l'historique. Chacun d'eux est limité par la qualité avec laquelle l'historique a été écrit. Donc, brièvement mais avec conviction.

La forme, qui est une convention aussi vieille que Git lui-même :

```console
Cache the cart total for the session

Recomputing the total on every render was costing us 40ms per keystroke on the
quantity input. The cart cannot change between renders, so caching it in the
session is safe.

Refs: #431
Signed-off-by: Ori Pekelman <ori+git-training@pekelman.com>
Co-authored-by: Lea Prettier <lea@example.com>
```

* **Une ligne de sujet de moins d'une cinquantaine de caractères, à l'impératif.** « Add the coupon table », pas « Added the coupon table » ni « adding some coupon stuff ». À l'impératif parce que vous complétez la phrase « appliquer ce commit va… », ce qui est exactement ce que disent `git revert`, `git cherry-pick` et `git merge` quand ils génèrent des messages pour vous. Courte parce que `git log --oneline`, `git shortlog`, `git rebase -i` et toutes les interfaces web la tronquent.
* **Une ligne vide.** Pas optionnelle. Git traite le premier paragraphe comme le sujet ; sans la ligne vide, tout votre message devient un énorme sujet.
* **Un corps qui explique le *pourquoi*.** Le diff dit déjà ce qui a changé, parfaitement, pour toujours. Il ne peut pas dire ce que vous cherchiez à accomplir, ce que vous avez essayé d'abord, ni quelle contrainte a rendu la solution moche nécessaire. C'est la seule information du commit qui ne peut pas être retrouvée à partir du code, c'est donc la seule information que le corps nous doit. Passez à la ligne vers 72 caractères.
* **Des références aux tickets.** `Refs: #431`, `Fixes #431`, `Closes #431`. La plupart des hébergeurs les transforment en liens, et certains ferment le ticket pour vous quand le commit atterrit.
* **Des trailers.** Des lignes `Clé: valeur` à la fin du message. `Co-authored-by:` est compris par GitHub et GitLab et donne crédit à un binôme. `Signed-off-by:` — ajouté par `git commit -s` — est la signature du Developer Certificate of Origin, une déclaration attestant que vous avez le droit de contribuer ce code. Beaucoup de projets (le noyau Linux, Docker, quantité de dépôts d'entreprise) l'exigent, et leur CI rejettera un commit qui n'en a pas. Ajoutez-en d'arbitraires avec `--trailer "Clé: valeur"`, et relisez-les avec `git log --format='%(trailers:key=Co-authored-by)'`.

Voici ce commit, en tant qu'objet :

```console
git commit -s --trailer "Co-authored-by: Lea Prettier <lea@example.com>" \
  -m 'Cache the cart total for the session' \
  -m 'Recomputing the total on every render was costing us 40ms per keystroke on the quantity input. The cart cannot change between renders, so caching it in the session is safe.' \
  -m 'Refs: #431'
git cat-file -p HEAD

tree ab69b4abf3bb84d4e268bd42d84e4a9a5e242bd3
author Ori Pekelman <ori+git-training@pekelman.com> 1771833600 +0100
committer Ori Pekelman <ori+git-training@pekelman.com> 1771833600 +0100

Cache the cart total for the session

Recomputing the total on every render was costing us 40ms per keystroke on the quantity input. The cart cannot change between renders, so caching it in the session is safe.

Refs: #431
Signed-off-by: Ori Pekelman <ori+git-training@pekelman.com>
Co-authored-by: Lea Prettier <lea@example.com>
```

Rien que du texte dans un objet commit, exactement comme nous l'avons vu en partie 1. Tout l'outillage du monde est bâti sur la discipline d'y mettre le bon texte.

> :information_source: **Conventional Commits** est une convention largement utilisée qui préfixe le sujet par un type : `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, plus `BREAKING CHANGE:` dans le corps. Son intérêt est qu'une machine peut la lire — des outils dérivent automatiquement les numéros de version et les changelogs à partir des préfixes. Si votre projet publie souvent, elle est rentable. Sinon, c'est de la cérémonie. Adoptez-la pour l'automatisation, pas pour l'esthétique, et dans les deux cas écrivez une vraie ligne de sujet après le préfixe.

En tant que quelqu'un qui lit beaucoup de dépôts écrits par d'autres : un projet dont le `git log` se lit comme de la prose est un projet dont je fais davantage confiance au code avant même d'en avoir lu une ligne. Cette corrélation n'est pas un accident.

## Récapitulatif : `git merge`, `git rebase`, `git commit --amend`, `git blame`

* **La base de fusion** — l'ancêtre commun le plus récent de deux branches, `git merge-base A B`. Git fusionne en comparant chaque côté à la base, pas l'un à l'autre : une **fusion à trois points**.
* **Le fast-forward** — possible uniquement quand la base de fusion est le sommet de la branche sur laquelle vous êtes. Aucun objet n'est créé ; une référence se déplace. `git merge --ff-only` échoue quand un fast-forward est impossible ; `git merge --no-ff` crée quand même un commit de fusion.
* Un **commit de fusion** n'est qu'un commit avec deux lignes `parent` — voyez-le avec `git cat-file -p`. Le premier parent est là où vous vous teniez. `git log --first-parent` ne suit que cette ligne, qui est l'historique de la branche elle-même ; la CI et les outils de changelog la veulent généralement.
* `git revert -m 1 <fusion>` annule toute une fonctionnalité fusionnée en un nouveau commit honnête.
* `git merge A B C` produit une fusion **pieuvre** à plusieurs parents. Rare, et incapable de résoudre des conflits.
* `git merge --squash` met le résultat de la branche dans votre index comme un seul commit à un seul parent. L'historique propre de la branche est jeté et Git ne sait plus qu'elle a été fusionnée — d'où `git branch --no-merged` qui la liste encore, et des fusions écrasées répétées depuis une branche de longue durée qui reproposent d'anciens conflits pour toujours.
* `git merge --abort` défait une fusion en cours ; `git merge --continue` la termine.
* `git rebase <base>` rejoue chacun de vos commits sur une nouvelle base sous forme de **nouveaux commits aux nouveaux SHAs**. Les anciens commits survivent, non référencés, retrouvables par le reflog. `git rebase --onto` rejoue un intervalle choisi. `git rebase -i` vous donne `pick` / `reword` / `squash` / `fixup` / `drop` / `edit` / `exec`.
* `git commit --fixup <commit>` plus `git rebase -i --autosquash` fond les fixups dans leurs cibles automatiquement. `git rebase --update-refs` (2.38+) entraîne les branches empilées avec le rebase.
* `git rebase --continue` / `--skip` / `--abort` quand un rebase s'arrête. Pendant un rebase, `HEAD` est l'upstream, donc « ours » et « theirs » sont inversés par rapport à une fusion.
* **La règle d'or du rebase** : ne rebasez jamais des commits qui existent en dehors de votre propre dépôt. L'exception honnête est votre propre branche de pull request, que vous pouvez rebaser et pousser avec `--force-with-lease`.
* `git commit --amend` remplace le dernier commit — nouveau SHA. `--no-edit` garde le message. Parfait pour un fichier oublié ; dangereux sur une branche partagée.
* Les **conflits** mettent des marqueurs dans le fichier et jusqu'à trois stages dans l'index. `git ls-files -u` les liste ; `git show :1:<fichier>`, `:2:`, `:3:` sont la base, le nôtre, le leur. `git add` les écrase en « résolu ».
* `merge.conflictStyle = zdiff3` ajoute la base de fusion aux marqueurs de conflit. Activez-le.
* `git checkout --ours/--theirs <fichier>`, `git checkout -m <fichier>`, `git show :1:<fichier>`, `git mergetool`, `git diff --diff-filter=U` vous aident à résoudre.
* `-X ours` / `-X theirs` ne décident que des sections conflictuelles ; `--strategy=ours` écarte entièrement l'autre branche tout en l'enregistrant comme fusionnée.
* `rerere.enabled = true` enregistre vos résolutions de conflits et les rejoue la prochaine fois que le même conflit apparaît.
* `git blame` est de l'archéologie, pas de la recherche de coupable : `-L`, `-w`, `-C`, `-M`, `<rév> -- <fichier>`, et surtout `--ignore-rev` avec `blame.ignoreRevsFile` pour survivre aux reformatages de masse.
* `git log -S<chaîne>` et `git log -G<regex>` — le pic à glace — trouvent les commits qui ont ajouté ou retiré quelque chose, l'outil qu'il faut quand la ligne n'existe plus.
* Un message de commit, c'est un sujet à l'impératif de moins de ~50 caractères, une ligne vide, puis un corps qui explique *pourquoi*. Des trailers comme `Co-authored-by:` et `Signed-off-by:` (`git commit -s`) sont des métadonnées lisibles par une machine. Conventional Commits vaut la peine d'être adopté si vous en automatisez les publications.

Tout ce chapitre a porté sur la manière de bien faire les choses. Le suivant porte sur l'autre moitié du métier : [Garder un historique propre, se remettre de ses erreurs](6-git-cleanup.md "Garder un historique propre, se remettre de ses erreurs").
