---
title: Implement an efficient collaborative workflow
url: "/docs/git-workflow/"
weight: 15
---

# Politeness obliges: Implement an efficient collaborative workflow

At the end of [Collaborate with Git](1-collaborate-with-git.md "Collaborate with Git") we made a promise, and we should keep it. We said:

> This is the first time in this course where we are not going to tell you the whole truth. Although this is one of the commands you are going to be using very often, building an actual, detailed understanding of what Git merge does is **complicated**.

We are going to pay that debt now. In P2C1 we merged two branches, Git said **Fast-forward**, and we hand-waved. It turns out that a fast-forward is the one case where `git merge` does almost nothing at all. Everything interesting was hiding behind that word.

So this chapter has two halves. The first is social: what you owe the people who share a repository with you. The second is mechanical: what `merge`, `rebase`, `amend` and conflict resolution actually do to the objects in `.git`. The two halves are the same subject. Every mechanism we look at exists because somebody, somewhere, has to read your history and understand what you did.

> :information_source: All the output in this chapter comes from a real repository built with pinned dates, so the hashes stay consistent from one section to the next. The **SHA**s on your machine will be different. That is normal and expected — the shapes are what matter.

## Politeness obliges

A branch that only you use is your private notebook. Scribble in it, tear pages out, rewrite the first chapter after you have written the last one. Nobody cares, and nobody should.

A branch that other people use is shared property. The moment a colleague has run `git pull` and based work on a commit of yours, that commit stops being yours. It is a fact about the world now. You may add to it. You may not un-happen it.

This gives us the one rule from which most of this chapter follows:

> :warning: Never rewrite history that exists outside your own repository.

And it gives us a second, softer one. Your commit history is a message. It is a message to the colleague who reviews your work this afternoon, to the person who bisects a production bug in eight months, and — most often — to *you*, next Tuesday, having entirely forgotten why you touched that file. Writing that message carefully is not ceremony. It is the cheapest documentation you will ever produce, because you are already typing it.

## Plow and oxen: pull before push

There is an old rule for working a field with a team of oxen: you do not push the plow before the oxen have moved. In Git terms:

```console
git pull
# run your tests
git push
```

You pull first because the remote may have moved since you last looked, and Git will refuse to push if it has:

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

This is Git being a good citizen on your behalf: it will not let you make the remote branch forget a commit. The mechanics of `fetch`, `pull`, tracking branches and `--force-with-lease` belong to [Retrieve and send code](3-git-clone-pull-remote.md "Retrieve and send code"); here we only care about the habit. Pull, run the tests, then push. In that order, every time.

> :warning: "Pull, then push" is not the same as "pull, then push blindly". A `git pull` that merges somebody else's work into yours can produce code that compiles and is nevertheless wrong: their function rename plus your new call site equals a broken build that neither of you wrote. Run the tests *after* the pull, not before.

## Why don't we push on `master`?

There is no technical reason. `git push origin master` works. Git has no notion of an important branch; `master` and `main` are pointers exactly like every other branch, as we saw in [Playing with our revisions](../1-understanding-git/7-play-with-git-revisions.md "Playing with our revisions").

The reasons are social and operational.

* **Review.** If your change lands on the main branch directly, nobody read it. Not because your colleagues are lazy, but because you gave them no moment at which to read it.
* **The main branch is a promise.** In most teams it means "this is what we deploy", or at least "this is green". Anything that lands on it without passing the tests breaks that promise for everyone at once. See [A little structure please](4-git-repo-structure.md "A little structure please") for the stable-master and unstable-master schools.
* **Bisectability.** A main branch made of reviewed, tested, self-contained commits can be bisected. We will use `git bisect` in [Keep a clean history, recover from mistakes](6-git-cleanup.md "Keep a clean history, recover from mistakes"), and you will want that property.

Hosting platforms turn these customs into rules. The vocabulary differs slightly but the mechanisms are the same everywhere (GitHub, GitLab, Forgejo, Codeberg, Bitbucket):

* **Branch protection rules** — the server refuses a direct push, or a force-push, or a deletion of the protected branch.
* **Required reviews** — the change cannot be integrated until N people have approved it.
* **Required status checks** — the change cannot be integrated until the test suite has passed on it. This is where [Continuous integration with Git](../5-automation/2-git-ci.md "Continuous integration with Git") plugs in.
* **`CODEOWNERS`** — a file in the repository mapping paths to people or teams, so that touching `db/migrations/` automatically requests review from whoever owns the database.

And now the honest counterpoint, because this course does not sell you dogma: plenty of excellent teams push to the main branch all day long. If you are alone on a project, the ceremony of a pull request to yourself buys you nothing. And trunk-based development — everybody committing small changes straight to `main`, many times a day, behind feature flags, protected by a fast and trustworthy test suite — is a real, respected, high-performing way to work. It is not "no process"; it is process moved from review-before-merge to tests-plus-flags.

What is *not* fine is pushing unreviewed, untested work to a branch other people deploy from, and then going to lunch.

## The "pull request" the "merge request" and their friends.

Git itself has no concept of a pull request. This is worth saying out loud, because so much of daily Git life happens inside one.

What Git has is `git request-pull`, a command that generates a plain-text message saying "please merge my branch, here is where it is, here is a summary of what is in it". That was the original workflow of the Linux kernel: you emailed a maintainer, they fetched and merged. GitHub's contribution was to put that message in a web page with a comment thread, a diff viewer and a big green button. GitLab calls the same object a **merge request** — which is arguably the better name, since what you are asking for is a merge.

So a pull request is three things stacked together:

1. A branch, in some repository, that a server can fetch.
2. A conversation attached to it.
3. A button that runs one of `git merge`, `git merge --squash`, or `git rebase` on the server.

Point 3 is the one people forget, and it is the reason the rest of this chapter matters. That innocent dropdown next to the green button — *Create a merge commit* / *Squash and merge* / *Rebase and merge* — chooses which of three quite different things happens to your history. Let us find out what they are.

## Non Fast-Forward merges: what `git merge` actually does

Let us build a small repository to work in. Two commits on `master`, then a branch with two commits of its own.

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

### The merge base

Here is the single most useful idea in this chapter, and almost nobody is taught it.

When Git merges two branches it does **not** compare them to each other. It finds their most recent common ancestor — the **merge base** — and compares each branch to *that*. Then it combines the two sets of changes.

That is what "three-way merge" means: three inputs, the base and the two sides.

Run it:

```console
git merge-base master banner

62fe1853d2a7aec2d7975bae70fa6dcd6711c33b
```

Compare it with the tip of `master`:

```console
git rev-parse master

62fe1853d2a7aec2d7975bae70fa6dcd6711c33b
```

The same commit. The merge base *is* the tip of the branch we are standing on. `banner` is simply `master` plus two commits; the histories have not diverged at all.

This is also why "the same change made twice in two branches" produces a conflict while "a change on one side and nothing on the other" does not: the base is what tells Git which side actually moved. Without a base, Git would have to guess. With one, it can tell.

### Fast-forward: nothing is created, a ref moves

Because the merge base is the tip of `master`, Git has nothing to combine. Everything on `master` is already an ancestor of `banner`. So it takes the shortcut:

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

Look at what happened to the graph:

```console
git log --graph --oneline --all --decorate

* 36e6c8f (HEAD -> master, banner) Style the top banner
* eca5ea6 Add the top banner markup
* 62fe185 Initial shopping cart code
* bbfd9f5 Add the readme
```

No new commit. Not one new object in `.git/objects`. `master` and `banner` now name the same commit, `36e6c8f`, exactly as we saw in P2C1. All Git did was write forty characters into `.git/refs/heads/master`. That is the whole of a **fast-forward**: a pointer moves forward along a line that already existed.

You can prove there is no merge commit by looking at the object:

```console
git cat-file -p HEAD

tree 90e3af950a6f74e6246508c7d231744e530be0e0
parent eca5ea6741808f64f3ed42d45d3a8f7c12028574
author Ori Pekelman <ori@pekelman.com> 1770108000 +0100
committer Ori Pekelman <ori@pekelman.com> 1770108000 +0100

Style the top banner
```

One `parent`. It is just the last commit of the feature branch, wearing a new hat.

### `--no-ff`: making the merge visible on purpose

Let us undo that and do it differently. The **reflog** still knows where `master` used to be:

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

Same files, entirely different history:

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

`--no-ff` tells Git: even though you *could* just move the pointer, create a merge commit anyway. Many teams configure this for their main branch, for two good reasons:

1. **The merge commit records that a feature landed as a unit.** Six months later, `git log --first-parent master` reads as a list of features rather than a list of keystrokes.
2. **It makes the feature revertable in one move.** Which brings us to the next thing.

### A merge commit is a commit with two parents. That's all.

Back in [Inside the repository, inside the commit](../1-understanding-git/5-inside-git.md "Inside the repository, inside the commit") we mentioned, almost in passing, that a commit "primarily identifies a particular **tree** and one (or for that matter several) parent **commit**s". Here is the several:

```console
git cat-file -p HEAD

tree 90e3af950a6f74e6246508c7d231744e530be0e0
parent 62fe1853d2a7aec2d7975bae70fa6dcd6711c33b
parent 36e6c8f267b889a0ee9dba55e15eb61276f69721
author Ori Pekelman <ori@pekelman.com> 1770109200 +0100
committer Ori Pekelman <ori@pekelman.com> 1770109200 +0100

Merge branch 'banner'
```

Two `parent` lines. That is the entire difference between a merge commit and any other commit. There is no "merge object" in Git, no special record of what was combined, no stored conflict resolution. A merge commit is a normal commit that happens to have two ancestors, pointing at a **tree** that contains the combined result.

Everything else — the arcs in `git log --graph`, "this branch is merged", `git revert -m 1` — is Git *deriving* facts from those two pointers.

The order of the parents matters, and it is not arbitrary. The **first parent** is where you were standing when you typed `git merge` (here, `master`). The second parent is what you merged in. `git show` puts them on the `Merge:` line:

```console
git show --stat HEAD

commit e10823db3ff81d11ec97e2dc8c49d53c2a4a8869
Merge: 62fe185 36e6c8f
Author: Ori Pekelman <ori@pekelman.com>
Date:   Tue Feb 3 10:00:00 2026 +0100

    Merge branch 'banner'

 public/banner.css | 1 +
```

Which lets us undo the whole feature in one commit. You must tell `git revert` which parent counts as "the mainline", and for a merge into your main branch that is always parent 1:

```console
git revert -m 1 HEAD

[master a9dff07] Revert "Merge branch 'banner'"
 2 files changed, 2 deletions(-)
 delete mode 100644 public/banner.css
 delete mode 100644 views/banner.html
```

Both files are gone, in a single new commit, without any history being rewritten. There is a famous trap waiting on the other side of this operation; we defuse it in [the next chapter](6-git-cleanup.md "Keep a clean history, recover from mistakes").

Let us keep the merge and drop the revert: `git reset --hard HEAD~1`.

### `--ff-only`, and a genuinely diverged merge

So far our branches never diverged. Let us make them diverge properly. From the merge commit we create two branches that both touch `lib/shopping_cart.js`, plus one commit on `master` that touches something else entirely:

```console
git switch -c vat
# edit lib/shopping_cart.js  ->  return sum(cart) * 1.2;
git commit -am'Add VAT to the cart total'

git switch -c coupons master
echo 'function coupon(code) { ... }' > lib/coupons.js
git add lib && git commit -m'Add coupon code lookup'
# edit lib/shopping_cart.js  ->  return sum(cart) - coupon(cart.code);
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

Now the merge base is *behind* both tips:

```console
git merge-base master coupons

e10823db3ff81d11ec97e2dc8c49d53c2a4a8869
```

```console
git rev-parse master coupons

12a1acf243e7cb772888d7071eac1ca1bac8607c
59159881ed1a7b7aaa057c37f3b96639000d618a
```

Three different commits: a base and two tips. A fast-forward is now impossible, and if we insist on one, Git says so plainly:

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

`--ff-only` is a very useful flag precisely because it fails. Setting `git config --global pull.ff only` turns "`git pull` quietly invented a merge commit in my repository" into an error message, which is almost always what you wanted.

The real merge succeeds, because the two sides touched different files (`docs.txt` on one, `lib/coupons.js` and `lib/shopping_cart.js` on the other):

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

> :information_source: **ort** is the name of Git's merge engine ("Ostensibly Recursive's Twin"). It replaced the older `recursive` strategy as the default in Git 2.34; it is faster and much better at renames. You do not need to know more than that it is the thing doing the three-way merge for you.

### Reading a merged history

Once merge commits exist, `git log` has to choose how to flatten a graph into a list, and the choice matters.

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

Everything, interleaved. Now follow only first parents:

```console
git log --oneline --first-parent

f93b936 Merge branch 'coupons'
12a1acf Document the free shipping threshold
e10823d Merge branch 'banner'
62fe185 Initial shopping cart code
bbfd9f5 Add the readme
```

Five commits instead of nine, and every one of them is a state that `master` actually passed through. The work *inside* each feature has been folded away into its merge commit.

This is why CI systems and release-notes generators so often use `--first-parent`: it is the history of the branch itself rather than the history of everything that ever flowed into it. It is also the strongest argument for `--no-ff` merges — with fast-forwards, `--first-parent` has nothing to collapse.

`git log --graph` is the other half of the answer, and `git log --graph --oneline --decorate --all` is worth an alias. See [Making the command line yours](../3-tooling-ecosystem/1-git-tools.md "Making the command line yours").

### Octopus merges

`git merge` accepts more than one branch. The result is a commit with more than two parents, and Git calls the strategy **octopus**:

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
author Ori Pekelman <ori@pekelman.com> 1770800400 +0100
committer Ori Pekelman <ori@pekelman.com> 1770800400 +0100

Merge three features at once
```

Three parents. Which is a lovely thing to have seen once, and which you will essentially never need. Octopus merges cannot resolve conflicts at all — the moment two of the branches touch the same lines, the strategy gives up, with what is possibly the best error message in Git:

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

Indeed. Should not be doing an octopus. Merge your branches one at a time.

### Squash merge: the honest tradeoff

The third option behind that green button. Let us make a branch with the kind of history we all actually produce:

```console
git switch -c filters
# ... three commits later ...
git log --oneline filters -4

8e6eb53 oops forgot the return
d4dbb27 wip filters, take 2
b747d6e wip filters
931150f Merge branch 'vat'
```

Nobody needs those three commits. `--squash` takes the *result* of the branch, puts it in your working tree and index, and stops — without committing, and without recording any relationship to the branch:

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

Note "not updating HEAD". Git staged the changes and got out of the way. You commit them yourself, with a message that describes the feature rather than your struggle with it:

```console
git commit -m'Add the price filter'
```

And now look at the object:

```console
git cat-file -p HEAD

tree abda1ee73e79458a3d911e1970203b504b741880
parent 931150fa7798c7d9dd60177ec3d17de04e9978b2
author Ori Pekelman <ori@pekelman.com> 1770282000 +0100
committer Ori Pekelman <ori@pekelman.com> 1770282000 +0100

Add the price filter
```

**One** parent. This is the crucial consequence, and it is not a bug: after a squash merge, Git does not know that `filters` was ever merged. The branch's three commits are still sitting there, and there is no link of any kind between the new commit and the branch it came from.

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

Git is telling the truth. As far as it can tell, that branch's work has never been integrated.

Which leads to the real cost of squash merges, the one that bites teams: **repeated squash merges from a long-lived branch generate the same conflicts over and over.** Because `master` has no ancestry link to `filters`, the merge base between them stays stuck at the old fork point forever. Every subsequent merge re-proposes every change the branch ever made — including the ones already squashed into `master` — and Git has to ask you about all of them again.

So:

* Squash merging a short-lived feature branch that you delete immediately: excellent. Clean main branch history, no cost.
* Squash merging repeatedly from a long-lived branch or a fork you keep: painful, and getting more painful every time.

There is no right answer here, only a tradeoff you should make on purpose.

### `--abort` and `--continue`

Two commands to remember before we go anywhere near a conflict:

* `git merge --abort` — throw the whole merge away and put the working tree back exactly as it was. Always available while a merge is in progress. Always safe.
* `git merge --continue` — once you have resolved everything and `git add`-ed it, finish the merge commit. (`git commit` does the same thing; `--continue` is clearer about your intent and refuses if you have not finished.)

## Perfectly acceptable revisionism: what is `rebase`?

`merge` combines two histories. `rebase` rewrites one of them.

The name is exact. It takes your commits and gives them a new **base**. For each commit on your branch, in order, Git computes the change that commit introduced and applies that change somewhere else, producing a **new commit**: new parent, new tree, new committer date, therefore new **SHA**. The originals are untouched, but nothing points at them any more.

Let us watch. A branch `search` with two commits, and one new commit on `master`:

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

Two things to notice, and please look at them properly:

1. **The graph is a straight line.** No fork, no merge commit. `search` now looks as though it had been started after `Expand the readme`, which is a lie — but a useful, readable one.
2. **The SHAs changed.** `d9a976f` became `63dee6d`; `d32e2ee` became `1c37e7f`. These are different objects. Same content, same messages, different commits.

The author date is preserved, the committer date is not — exactly the distinction we drew in P1C5 between **author** and **committer**:

```console
git log -2 --format='%h %ad | %cd | %s' --date=iso

1c37e7f 2026-02-06 09:30:00 +0100 | 2026-02-06 11:00:00 +0100 | Add the synonyms table
63dee6d 2026-02-06 09:00:00 +0100 | 2026-02-06 11:00:00 +0100 | Add the search entry point
```

And the old commits are still in `.git/objects`, unreferenced but perfectly readable, because the reflog is holding the door open:

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

There is the old branch, intact. `git reset --hard search@{1}` would put it back. Internalise this now: **a rebase is undoable** as long as you have the reflog. We come back to it in the next chapter.

### `git rebase --onto`

Plain `git rebase main` means "replay everything since the merge base onto `main`". Sometimes you want to replay a *different* range — most often when you have a branch stacked on another branch and the lower one is not going to land.

`git rebase --onto <newbase> <upstream> [<branch>]` reads as: take the commits that are in `<branch>` but not in `<upstream>`, and put them on `<newbase>`.

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

The two test commits were surgically lifted off `feature/checkout` and dropped onto `main`. This is also how you drop a commit from the middle of a branch: `git rebase --onto <commit>~1 <commit>`.

### `git rebase -i`: the good part

Interactive rebase is where rebase stops being plumbing and becomes an editing tool. `git rebase -i master` opens your editor on a to-do list:

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

You edit that list and Git executes it. Note the order: **oldest first**, the opposite of `git log`. The ones you will use constantly:

* `reword` — fix a commit message without touching the content.
* `squash` / `fixup` — melt a commit into the one above it. `squash` lets you combine the two messages; `fixup` throws the second one away, which is usually what you want for an "oh, and also fix the typo" commit.
* `drop` — delete a commit. (Deleting the line does the same thing; `drop` is easier to review.)
* `edit` — stop there and let you amend, split, or run something.
* `exec` — run a command after that commit. `git rebase -i --exec 'npm test' master` runs the test suite after every single commit of your branch, which is a wonderful way to discover that commit three does not build.

### `--autosquash`: fixups without the bookkeeping

Better than remembering to mark things `fixup` later: mark them when you make them.

```console
git commit --fixup 1c37e7f
```

This creates a commit whose message is literally `fixup! Add the synonyms table`:

```console
git log --oneline -3

e367775 fixup! Add the synonyms table
1c37e7f Add the synonyms table
63dee6d Add the search entry point
```

Now `git rebase -i --autosquash master` reads those prefixes and builds the to-do list for you, already reordered:

```console
pick 63dee6d # Add the search entry point
pick 1c37e7f # Add the synonyms table
fixup e367775 # fixup! Add the synonyms table
```

Save, and the fixup disappears into its target. There is also `git commit --squash <commit>` (same idea, keeps both messages) and `git commit --fixup=amend:<commit>` / `--fixup=reword:<commit>` for changing an older commit's content or message without the interactive step.

Turn it on permanently with `git config --global rebase.autosquash true`.

> :information_source: Tools like `git absorb` go one step further: they look at your unstaged changes, work out which commit in your branch each hunk belongs to, and generate all the `fixup!` commits for you. Nice once you are comfortable with what it is automating.

### When a rebase stops

A rebase applies commits one at a time, so it can stop in the middle. Three exits:

* `git rebase --continue` — I fixed it, carry on.
* `git rebase --skip` — drop this commit entirely and carry on. Useful when the change turns out to be upstream already.
* `git rebase --abort` — put everything back the way it was. Always available. Always safe.

Here is one stopping, and it contains a trap worth pointing at. We rebase `vat` onto a `master` that already contains the coupon change to the same line:

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

> :warning: During a rebase, **`HEAD` is the branch you are rebasing onto, not your branch.** "Ours" is `master`; "theirs" is your own commit. This inverts the meaning of `--ours` and `--theirs` relative to a merge, and it is a classic way to discard exactly the work you were trying to keep. Read the labels, not your assumptions.

Notice also what `git status` says during a rebase:

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

Git tells you exactly where you are and what your options are. Read it. It is right there.

### Stacked branches: `--update-refs`

If you work in stacks — branch B built on branch A, both open as pull requests — then rebasing B used to leave A pointing at the old, abandoned commits; since Git 2.38, `git rebase --update-refs` moves every branch that pointed into the rebased range along with it, and `git config --global rebase.updateRefs true` makes that the default.

### The Golden Rule of Rebasing

> :warning: **Never rebase commits that exist outside your own repository.**
>
> Rebase does not modify commits; it replaces them with new ones. If anybody else has the old ones — because you pushed them and they pulled — then after your rebase the two of you hold two parallel copies of the same work with different SHAs. Git cannot tell they are related. Their next `git pull` will merge both copies, every commit will appear twice, and the resulting mess is unpleasant to clean up and very easy to make worse.

Now the honest exception, because the rule as usually stated is stricter than practice.

"Outside your own repository" does not mean "pushed". It means "somebody else has it". Your own feature branch on the shared server, which only you commit to and which exists so that a pull request has something to point at — nobody has based work on that. Rebasing it and force-pushing is not merely acceptable, it is the ordinary daily workflow at a very large number of companies:

```console
git rebase main
# run the tests
git push --force-with-lease
```

Use `--force-with-lease`, never bare `--force`. It refuses the push if the remote branch has moved since you last fetched, which is precisely the "oh no, somebody else *was* working here" case. See [Retrieve and send code](3-git-clone-pull-remote.md "Retrieve and send code").

Where the rule is absolute: `main`, `master`, `develop`, release branches, any branch a colleague has pushed to, and any branch whose commits somebody has cherry-picked or built on. When in doubt, ask. It costs one message.

### Merge or rebase?

This argument has consumed more developer-hours than the code it was about. Here is a position rather than a war.

**Rebase your own work before it lands.** Your fifteen exploratory commits, three of which do not build, are not a contribution to the shared history — they are notes. Clean them up. `rebase -i` until the branch reads as a sequence of steps a colleague could review one at a time. This is politeness, and it is the actual argument for rebase: not linear history for its own sake, but *reviewable* history.

**Merge to integrate.** When two shared branches need to come together, merge them. The merge commit is a true statement about what happened; a rebase would be a false one, and it would rewrite commits other people have. Use `--no-ff` if you want features to remain visible as units.

**Never rewrite what others have built on.** Non-negotiable, per the Golden Rule.

Note that these are not in tension. "Rebase my branch, then merge it" is one coherent workflow, and it is what "Rebase and merge" or "Squash and merge" on a hosting platform is approximating. The religious war is mostly people defending different halves of the same sentence.

## git commit --amend

The smallest rewrite, and the one you will use most.

`git commit --amend` replaces the last commit with a new one built from the current index. New tree, or new message, or both — and therefore a new **SHA**. It is a one-commit rebase with a friendlier name.

You committed with a typo in the message:

```console
git log --oneline -1

0b690b2 Implment the search lookup
```

```console
git commit --amend -m'Implement the search lookup'
git log --oneline -1

4b0a2d0 Implement the search lookup
```

The hash changed: `0b690b2` → `4b0a2d0`. It is a different commit. `0b690b2` still exists in `.git/objects` but nothing points at it.

Or, far more common: you forgot a file.

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

`--no-edit` means "keep the message, do not open my editor". The test file is now part of the commit it belongs to, which is where a reviewer will look for it.

And the reflog has the whole trail, with `(amend)` markers so you can see what happened:

```console
git reflog -4

70f0200 HEAD@{0}: commit (amend): Implement the search lookup
4b0a2d0 HEAD@{1}: commit (amend): Implement the search lookup
0b690b2 HEAD@{2}: commit: Implment the search lookup
8955a02 HEAD@{3}: checkout: moving from master to search
```

> :warning: `--amend` is a rewrite, so the Golden Rule applies to it in full. Amending a commit you have already pushed to a shared branch means the branch has to be force-pushed, and everybody who pulled the old one gets a duplicate. On your own pull-request branch: fine, amend and `--force-with-lease`. On `main`: no.

## Conflict management

Time to break something on purpose. In our repository `master` has the coupon change and `vat` has the VAT change, both on the same line of `lib/shopping_cart.js`.

```console
git merge vat

Auto-merging lib/shopping_cart.js
CONFLICT (content): Merge conflict in lib/shopping_cart.js
Automatic merge failed; fix conflicts and then commit the result.
```

Note what Git did *not* do: it did not abort, and it did not pick a winner. It merged everything it could, left the rest for you, and stopped in a well-defined intermediate state. `git status` describes that state:

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

"Unmerged paths", "both modified". And for the list of just those files, in a form you can pipe into something else:

```console
git diff --diff-filter=U --name-only

lib/shopping_cart.js
```

### The markers

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

Three markers:

* `<<<<<<< HEAD` — everything until the next marker is **ours**: the branch we are on, `master`.
* `=======` — the divider.
* `>>>>>>> vat` — everything above it since the divider is **theirs**: what we are merging in.

That is all a conflict is. Git wrote both candidate versions into the file with labels on them. The file is now not valid JavaScript, on purpose, so that you cannot ship it by accident.

### `merge.conflictStyle = zdiff3`

The default markers are missing the most useful piece of information: what the line *used to be*. Without the base you cannot tell who changed what. Let us fix that permanently:

```console
git config --global merge.conflictStyle zdiff3
```

Abort and try again:

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

A fourth section, between `|||||||` and `=======`: **the merge base**. And now the conflict tells a story. The line started life as `return sum(cart);`. One side subtracted a coupon. The other multiplied by 1.2. Neither deleted the other's work — they each did one thing to a shared starting point, and the correct resolution is obviously *both*.

You could not have known that from the two-way markers. You would have had to guess, or go and read the two branches. This one config line is, honestly, the highest-value setting in this chapter.

> :information_source: The older `diff3` style does the same thing; `zdiff3` (Git 2.35+) additionally hoists lines that are common to all three versions out of the conflicted region, so the markers wrap only the part that genuinely disagrees. Use `zdiff3`.

### Under the hood: the index holds three versions

Here is the payoff for having spent Part 1 inside `.git`. We know the **index** as a flat list of staged files. During a conflict it is something more interesting: it can hold up to *three* entries for the same path, called stages.

```console
git ls-files -u

100644 353719e573b2c1fd0bcdc111025dc63d3c7e6419 1	lib/shopping_cart.js
100644 f08164fe0025e9d4904120efdcc6ada1ca45f21e 2	lib/shopping_cart.js
100644 6ac791d004dce05719c29157dc06c4745c2ea515 3	lib/shopping_cart.js
```

Three **blob**s, one path, and a number in the last column:

* **stage 1** — the merge base version.
* **stage 2** — ours (`HEAD`).
* **stage 3** — theirs.

And you can read each one directly, with the `:<stage>:<path>` syntax:

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

There is no magic anywhere. A conflict is a multi-stage index entry plus a file with markers in it. Every tool that helps you resolve conflicts — the three-pane merge tools, your editor's inline resolution buttons, `zdiff3` itself — is reading those three blobs. Now you can too, without any tool at all, which is exactly the moment where conflicts stop being frightening.

> :information_source: `:0:<path>` is the normal, resolved stage. That is why `git show :0:readme.md` — or its usual spelling, `git show :readme.md` — shows you the staged version of a file. Same mechanism.

### Resolving

The workflow, and it is short:

1. **Edit the file.** Remove the markers. Produce the code you actually want.
2. **`git add <file>`.** This collapses the three stages into one stage-0 entry: it is how you say "resolved".
3. **`git commit`**, or `git merge --continue`.

```console
git add lib/shopping_cart.js
git status --short

M  lib/shopping_cart.js
```

```console
git ls-files -u
```

Nothing. The stages are gone, so the conflict is gone.

```console
git merge --continue

[master 931150f] Merge branch 'vat'
```

Some helpers for step 1:

* `git checkout --ours <file>` / `git checkout --theirs <file>` — replace the whole file with one side. Fine for a generated file or a lockfile; a red flag on source code.
* `git checkout -m <file>` — put the conflict markers back if you mangled the file. Genuinely useful and almost unknown.
* `git show :1:<file> > <file>` — put a specific stage into the working tree; `:1` is the base, which is sometimes the cleanest place to restart from. (`git checkout-index --stage=1 -f -- <file>` does the same thing.)
* `git mergetool` — launch a three-pane graphical merge tool, configured with `merge.tool`. Meld, Beyond Compare, `vimdiff`, your IDE. Worth setting up once; see [Git With IDEs](../3-tooling-ecosystem/4-git-ides.md "Git With IDEs").
* `git diff` with no arguments during a conflict shows a **combined diff** — the difference against *both* parents at once, which is a compact way to see only the lines still in dispute.

### `-X ours` / `-X theirs`, and their dangerous cousin

`-X` passes an option to the merge strategy: "when you hit a conflicting hunk, prefer this side instead of asking me".

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

The VAT change lost, silently. With `-X theirs` the coupon change loses instead. Crucially, `-X` decides only the *conflicting* hunks — everything the two sides did that did not collide is still merged normally. If `vat` had also added a new file, `-X ours` would keep it.

`--strategy=ours` is a completely different, much blunter instrument:

```console
git merge --strategy=ours vat

Merge made by the 'ours' strategy.
```

This creates a merge commit with two parents whose tree is *identical to ours*. Nothing from the other branch comes across — not the conflicting hunks, not the non-conflicting ones, not the new files. What it accomplishes is recording, in the graph, "this branch has been dealt with", so that `git branch --merged` lists it and future merges skip it.

That is occasionally what you want (an abandoned branch you want Git to stop offering you). It is never what you want if you thought it meant `-X ours`.

### The same conflict, again and again: `rerere`

Long-lived branch, rebased daily onto a moving `main`? You will resolve the same conflict every day. Git can memorise it.

```console
git config --global rerere.enabled true
```

**rerere** stands for "reuse recorded resolution". With it on, the first conflict looks like this:

```console
git merge vat

Auto-merging lib/shopping_cart.js
CONFLICT (content): Merge conflict in lib/shopping_cart.js
Recorded preimage for 'lib/shopping_cart.js'
Automatic merge failed; fix conflicts and then commit the result.
```

You resolve and commit, and Git says:

```console
Recorded resolution for 'lib/shopping_cart.js'.
```

Now throw the merge away and do it again, as a rebase would:

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

Your resolution, replayed. The recorded resolutions live in `.git/rr-cache`, keyed by the shape of the conflict rather than by commit, which is why they survive a rebase discarding and re-creating every commit involved.

Note that the file is fixed but the path is still unmerged (`git status --short` shows `UU`): rerere fills in the answer, you still have to `git add` it. That is deliberate — you get a chance to check that the replayed resolution still makes sense.

Turn this on. There is no downside worth mentioning, and the day you rebase a two-week-old branch you will be glad.

### The trap

There is one way of resolving conflicts that produces broken software reliably, and everybody has done it at 6pm on a Friday:

> :warning: Resolving a conflict by deleting one side without reading it is not conflict resolution. It is silently reverting a colleague's work.
>
> A conflict means two people changed the same lines for two different reasons. Both reasons probably still apply. `git checkout --theirs` on a source file, or blindly keeping `HEAD`, throws one of them away — and, this is the vicious part, the tests may well still pass, because the feature you just deleted took its own tests with it, or never had any.

The habits that prevent it: turn on `zdiff3` so you can see what the line was before either side touched it; use `git log -p --merge` to read the commits from both sides that touched the conflicted file; and when you genuinely cannot tell what the other side was trying to do, go and ask them. `git blame` will tell you who to ask, which is our next subject.

## Who did what? Archaeology with `git blame`

`git blame` is a badly named command. Nobody sensible uses it to assign fault; we use it to understand a line of code we did not write, and very often to discover that it was written for a good reason we had not thought of. Call it archaeology and it becomes a different tool.

[Playing with our revisions](../1-understanding-git/7-play-with-git-revisions.md "Playing with our revisions") introduced the basic form. Here is the version you actually need in a repository with history.

Our `lib/shopping_cart.js` has been through several hands, and then somebody ran a formatter over the whole codebase:

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

Useless. Every interesting line now belongs to "Run prettier over the whole codebase", which tells us precisely nothing about why the VAT multiplier is 1.2.

### `-w` and `--ignore-rev`: surviving a reformat

The first thing to try is `-w`, which ignores whitespace-only changes:

```console
git blame -w lib/shopping_cart.js

62fe1853 (Ori Pekelman 2026-02-02 07:00:00 +0100  1) function total(cart) {
daa55453 (Lea Prettier 2026-02-08 14:00:00 +0100  2)   return (sum(cart) - coupon(cart.code)) * 1.2;
{..}
```

Still Lea. Because this reformat did not only change whitespace — it also added semicolons, turned `4.90` into `4.9` and double quotes into single quotes. `-w` cannot help.

`--ignore-rev` can. It tells blame to look *through* a commit and attribute the lines to whoever touched them before it:

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

The prettier commit has become invisible and the real history is back.

Nobody wants to type that hash every time, and nobody should have to. Put the hashes of your formatting commits in a file, commit the file, and point Git at it:

```console
git rev-parse daa5545 > .git-blame-ignore-revs
git add .git-blame-ignore-revs
git commit -m'Ignore the prettier commit in git blame'
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

From now on, plain `git blame` does the right thing:

```console
git blame -L 1,3 lib/shopping_cart.js

62fe1853 (Ori Pekelman 2026-02-02 07:00:00 +0100 1) function total(cart) {
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100 2)   return (sum(cart) - coupon(cart.code)) * 1.2;
51463068 (Ori Pekelman 2026-02-07 09:00:00 +0100 3) }
```

I am going to be emphatic about this one, because it is genuinely useful and almost nobody knows it. If your project has ever run a formatter, a linter with `--fix`, or a mass rename across the codebase, and you have not created a `.git-blame-ignore-revs`, then you have needlessly destroyed the usefulness of `git blame` for every file it touched. It costs three lines. GitHub and GitLab both honour the file in their web blame views as well. Do it today.

### The rest of the useful flags

* `-L 10,20 <file>` — only those lines. `-L :funcName <file>` also works and blames just that function. Once you know `-L`, `git blame` becomes usable on a three-thousand-line file.
* `-C` — detect lines **copied or moved from another file** in the same commit. Repeat it (`-C -C`, `-C -C -C`) to search harder and wider.
* `-M` — detect lines moved *within* the same file, so that reordering functions does not reset their history.
* `<revision> -- <file>` — blame the file as it was at some point in the past. This is how you investigate a line that has since been deleted.
* `-w` — ignore whitespace. `--ignore-rev` / `blame.ignoreRevsFile` — as above.

`-C` is the one that surprises people. Somebody moves a function to a new module, and plain blame says the whole thing is one day old:

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

With `-C`, Git tracks the block back across the move — and even prints where it came from:

```console
git blame -C lib/money.js

b50f2215 lib/shopping_cart.js (Ori Pekelman 2026-02-09 09:00:00 +0100 1) function formatMoney(amount, currency) {
b50f2215 lib/shopping_cart.js (Ori Pekelman 2026-02-09 09:00:00 +0100 2)   const rounded = Math.round(amount * 100) / 100;
b50f2215 lib/shopping_cart.js (Ori Pekelman 2026-02-09 09:00:00 +0100 3)   const symbol = currency === 'EUR' ? '€' : '$';
b50f2215 lib/shopping_cart.js (Ori Pekelman 2026-02-09 09:00:00 +0100 4)   return symbol + rounded.toFixed(2);
b50f2215 lib/shopping_cart.js (Ori Pekelman 2026-02-09 09:00:00 +0100 5) }
```

The second column is the file the lines lived in at the time. That is real archaeology.

### The pickaxe: when the line is gone

`git blame` can only tell you about lines that still exist. Very often the question is the opposite: *there used to be a call to `legacyCheckout()` around here — where did it go?*

That is `git log`'s pickaxe.

```console
git log --oneline -S'4.90'

daa5545 Run prettier over the whole codebase
5146306 Add shipping cost and the cart label
```

`-S<string>` finds commits where the **number of occurrences** of that string changed — that is, commits that added or removed it. Two commits: the one that introduced `4.90` and the one that turned it into `4.9`. Add `-p` and you see the diffs.

`-G<regex>` is the looser cousin: any commit whose diff contains a line matching the pattern, even if the count did not change.

```console
git log --oneline -G'coupon'

daa5545 Run prettier over the whole codebase
5146306 Add shipping cost and the cart label
5915988 Apply coupon discount to cart total
2584a0d Add coupon code lookup
```

Rules of thumb: `-S` to find where something appeared or vanished; `-G` to find every commit that touched the topic. Both accept `-- <path>` to narrow the search. `git log -S` on a function name is frequently the fastest way to understand a piece of code in an unfamiliar repository, and it is underused mainly because people never get past `git log --oneline`.

## Your history is a message: writing commits

We have spent this chapter on tools for reading history. Every one of them is limited by how well the history was written. So, briefly but with conviction.

The shape, which is a convention as old as Git itself:

```console
Cache the cart total for the session

Recomputing the total on every render was costing us 40ms per keystroke on the
quantity input. The cart cannot change between renders, so caching it in the
session is safe.

Refs: #431
Signed-off-by: Ori Pekelman <ori@pekelman.com>
Co-authored-by: Lea Prettier <lea@example.com>
```

* **A subject line under about 50 characters, in the imperative.** "Add the coupon table", not "Added the coupon table" or "adding some coupon stuff". Imperative because you are completing the sentence "applying this commit will…", which is exactly what `git revert`, `git cherry-pick` and `git merge` all say when they generate messages for you. Short because `git log --oneline`, `git shortlog`, `git rebase -i` and every web UI truncate it.
* **A blank line.** Not optional. Git treats the first paragraph as the subject; without the blank line your whole message becomes one enormous subject.
* **A body explaining *why*.** The diff already says what changed, perfectly, forever. It cannot say what you were trying to achieve, what you tried first, or which constraint made the ugly solution necessary. That is the only information in the commit which cannot be recovered from the code, so it is the only information the body owes us. Wrap it at around 72 characters.
* **References to issues.** `Refs: #431`, `Fixes #431`, `Closes #431`. Most hosts turn these into links, and some close the issue for you when the commit lands.
* **Trailers.** `Key: value` lines at the end of the message. `Co-authored-by:` is understood by GitHub and GitLab and gives credit to a pairing partner. `Signed-off-by:` — added by `git commit -s` — is the Developer Certificate of Origin sign-off, a statement that you have the right to contribute this code. Many projects (the Linux kernel, Docker, plenty of corporate repositories) require it, and their CI will reject a commit without it. Add arbitrary ones with `--trailer "Key: value"`, and read them back out with `git log --format='%(trailers:key=Co-authored-by)'`.

Here is that commit, as an object:

```console
git commit -s --trailer "Co-authored-by: Lea Prettier <lea@example.com>" \
  -m 'Cache the cart total for the session' \
  -m 'Recomputing the total on every render was costing us 40ms per keystroke on the quantity input. The cart cannot change between renders, so caching it in the session is safe.' \
  -m 'Refs: #431'
git cat-file -p HEAD

tree ab69b4abf3bb84d4e268bd42d84e4a9a5e242bd3
author Ori Pekelman <ori@pekelman.com> 1771833600 +0100
committer Ori Pekelman <ori@pekelman.com> 1771833600 +0100

Cache the cart total for the session

Recomputing the total on every render was costing us 40ms per keystroke on the quantity input. The cart cannot change between renders, so caching it in the session is safe.

Refs: #431
Signed-off-by: Ori Pekelman <ori@pekelman.com>
Co-authored-by: Lea Prettier <lea@example.com>
```

Nothing but text in a commit object, exactly as we saw in P1C5. All the tooling in the world is built on the discipline of putting the right text there.

> :information_source: **Conventional Commits** is a widely used convention that prefixes the subject with a type: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, plus `BREAKING CHANGE:` in the body. Its point is that a machine can read it — tools derive version numbers and changelogs from the prefixes automatically. If your project releases often, it earns its keep. If it does not, it is ceremony. Adopt it for the automation, not for the aesthetics, and either way write a real subject line after the prefix.

As someone who reads a lot of other people's repositories: a project whose `git log` reads as prose is a project whose code I trust more before I have read any of it. That correlation is not an accident.

## Summary `git merge` `git rebase` `git commit --amend` `git blame`

* **merge base** — the most recent common ancestor of two branches, `git merge-base A B`. Git merges by comparing each side to the base, not to each other: a **three-way merge**.
* **fast-forward** — possible only when the merge base is the tip of the branch you are on. No object is created; a ref moves. `git merge --ff-only` fails when a fast-forward is impossible; `git merge --no-ff` creates a merge commit anyway.
* A **merge commit** is just a commit with two `parent` lines — see it with `git cat-file -p`. The first parent is where you were standing. `git log --first-parent` follows only that line, which is the history of the branch itself; CI and changelog tools usually want it.
* `git revert -m 1 <merge>` undoes a whole merged feature in one honest new commit.
* `git merge A B C` produces an **octopus** merge with several parents. Rare, and it cannot resolve conflicts.
* `git merge --squash` puts the branch's result in your index as one commit with a single parent. The branch's own history is discarded and Git no longer knows it was merged — hence `git branch --no-merged` still lists it, and repeated squash merges from a long-lived branch re-propose old conflicts forever.
* `git merge --abort` undoes a merge in progress; `git merge --continue` finishes it.
* `git rebase <base>` replays each of your commits onto a new base as **new commits with new SHAs**. The old commits survive, unreferenced, findable through the reflog. `git rebase --onto` replays a chosen range. `git rebase -i` gives you `pick` / `reword` / `squash` / `fixup` / `drop` / `edit` / `exec`.
* `git commit --fixup <commit>` plus `git rebase -i --autosquash` folds fixups into their targets automatically. `git rebase --update-refs` (2.38+) drags stacked branches along with the rebase.
* `git rebase --continue` / `--skip` / `--abort` when a rebase stops. During a rebase `HEAD` is the upstream, so "ours" and "theirs" are inverted relative to a merge.
* **The Golden Rule of Rebasing**: never rebase commits that exist outside your own repository. The honest exception is your own pull-request branch, which you may rebase and push with `--force-with-lease`.
* `git commit --amend` replaces the last commit — new SHA. `--no-edit` keeps the message. Perfect for a forgotten file; dangerous on a shared branch.
* **Conflicts** put markers in the file and up to three stages in the index. `git ls-files -u` lists them; `git show :1:<file>`, `:2:`, `:3:` are base, ours, theirs. `git add` collapses them to resolved.
* `merge.conflictStyle = zdiff3` adds the merge base to the conflict markers. Set it.
* `git checkout --ours/--theirs <file>`, `git checkout -m <file>`, `git show :1:<file>`, `git mergetool`, `git diff --diff-filter=U` help you resolve.
* `-X ours` / `-X theirs` decide only the conflicting hunks; `--strategy=ours` discards the other branch entirely while still recording it as merged.
* `rerere.enabled = true` records your conflict resolutions and replays them next time the same conflict appears.
* `git blame` is archaeology, not fault-finding: `-L`, `-w`, `-C`, `-M`, `<rev> -- <file>`, and above all `--ignore-rev` with `blame.ignoreRevsFile` to survive mass reformats.
* `git log -S<string>` and `git log -G<regex>` — the pickaxe — find the commits that added or removed something, which is the right tool when the line no longer exists.
* A commit message is an imperative subject under ~50 characters, a blank line, then a body explaining *why*. Trailers such as `Co-authored-by:` and `Signed-off-by:` (`git commit -s`) are machine-readable metadata. Conventional Commits is worth adopting if you automate releases from it.

Everything in this chapter has been about doing things well. The next one is about the other half of the job: [Keep a clean history, recover from mistakes](6-git-cleanup.md "Keep a clean history, recover from mistakes").
