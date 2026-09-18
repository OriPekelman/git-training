---
title: Keep a clean history, recover from mistakes
slug: "git-cleanup"
weight: 16
---
# Keep a clean history, recover from mistakes

This is the chapter to bookmark.

Everything so far has been about doing things on purpose. This one is about the other half of the working day: the moment your stomach drops, you stare at the terminal, and you think *oh no*.

Here is the good news, and it is bigger than you think: **Git almost never loses data that has been committed.** Not "rarely". Almost never. A commit is an immutable object in `.git/objects`, and Git does not delete objects when you stop pointing at them — it keeps them, for weeks, and it keeps a log of every ref you have ever moved. Nearly every disaster in this chapter is a *pointer* problem, and pointers can be pointed back.

So this chapter is organised the way panic actually arrives: as a sentence you say out loud. Symptom, then what actually happened, then what to do.

## First: do not panic, and do not close the terminal

Three habits, before any of the recipes.

**Run `git status`.** Every time. Git is unusually good at telling you where you are and what your options are — during a merge, during a rebase, during a cherry-pick, in a **detached head**. Most of this chapter's recipes are printed in `git status` output already. Read it before you type anything.

**Do not close the terminal.** Your scrollback contains **SHA**s that are about to become precious. When Git said `Deleted branch experiment (was 34d8133)`, it handed you the key to the door you just locked. Copy it somewhere.

**Prefer the commands that create over the commands that destroy.** `git revert` creates a commit; `git reset --hard` throws one away. `git branch` creates a name for free. When you are frightened, take the reversible option — and when in doubt, make a backup branch first. `git branch panic-backup` costs nothing and has saved everybody at least once.

## "Damn, I did something terribly wrong, please tell me Git has a magic time machine!?!?!"

It does, and it is called `git reflog`. We met it briefly in [Collaborate with Git](1-collaborate-with-git.md "Collaborate with Git"); here is what it is really for.

Every time a ref moves — every commit, checkout, merge, rebase, reset, amend — Git appends a line to a log under `.git/logs`. That log is not part of your history. It is a private diary of what *your* pointers did, in order.

```console
git reflog

03b7787 HEAD@{0}: reset: moving to HEAD~2
62ac72c HEAD@{1}: checkout: moving from master to sale-banner
525030a HEAD@{2}: reset: moving to HEAD~1
3645fbe HEAD@{3}: checkout: moving from sale-banner to master
62ac72c HEAD@{4}: cherry-pick: Fix the currency symbol
eab0f86 HEAD@{5}: checkout: moving from master to sale-banner
```

Read it top-down as "most recent first". `HEAD@{1}` means "where `HEAD` pointed one move ago". Which gives us the single most useful undo in Git:

```console
git reset --hard HEAD@{1}
```

"Put me back where I was before whatever I just did."

Other forms worth knowing:

* `git reflog <branch>` — the diary for one branch rather than for `HEAD`. `git reflog master`.
* `master@{1}`, `master@{5}` — where that branch pointed N moves ago.
* `HEAD@{2.hours.ago}`, `master@{yesterday}` — time-based, and yes, that syntax really works.
* `git log -g` — the same information in `git log` format, with dates and full messages.

> :information_source: Reflog entries expire: 90 days by default for reachable commits, 30 for unreachable ones (`gc.reflogExpire`, `gc.reflogExpireUnreachable`). After that a `git gc` may genuinely delete the objects. In practice that means you have weeks, not minutes. But the reflog is **local**: it does not exist in a fresh clone and it is never pushed. Somebody else's repository cannot rescue your reflog.

> :warning: The reflog only knows about things that were *committed* — or stashed. It has no idea what was in your editor.

## "Shit, I committed and immediately realized I needed to make a small change!"

**What happened:** nothing bad. You made a commit thirty seconds ago and nobody has seen it.

**What to do:** make the change, stage it, and fold it into the commit you just made.

```console
# fix the thing
git add lib/search.js
git commit --amend --no-edit
```

`--no-edit` keeps the existing message and skips your editor. As we saw in [the previous chapter](5-git-workflow.md "Implement an efficient collaborative workflow"), `--amend` does not modify the commit — it builds a new one and moves the branch to it, so the **SHA** changes. The old commit is still in the reflog.

The classic case is a forgotten file:

```console
git add lib/search.test.js
git commit --amend --no-edit
git show --stat --oneline HEAD

70f0200 Implement the search lookup
 lib/search.js      | 4 +++-
 lib/search.test.js | 1 +
 2 files changed, 4 insertions(+), 1 deletion(-)
```

> :warning: If you have already pushed that commit to a branch other people use, do not amend it. Make a second, honest commit instead. On your own pull-request branch: amend, then `git push --force-with-lease`.

## "Damn, I need to change the message on my last commit!"

```console
git commit --amend -m'Implement the search lookup'
```

Or `git commit --amend` with no `-m`, to open your editor on the existing message — nicer when you want to add a body.

**And if it is not the last commit?** Then it is an interactive rebase with one `reword`:

```console
git rebase -i HEAD~5
```

Change `pick` to `reword` (or just `r`) on the line you care about, save, and Git will stop and open your editor on that message before carrying on.

```console
pick 63dee6d # Add the search entry point
reword 1c37e7f # Add the synonyms table
```

Remember that this rewrites that commit *and every commit after it* — they all get new SHAs, because their parent changed. The Golden Rule of Rebasing applies: fine on your own branch, not on a shared one.

## "Damn, I accidentally committed something to master that should have been on a brand new branch!"

**What happened:** you made two or three commits without switching branch first. Everybody does this. `master` is now two commits ahead of where it should be, and those commits are perfectly good — they are just in the wrong place.

**What to do:** name them, then rewind `master`. In that order.

```console
git log --oneline

eab0f86 Style the sale banner
03b7787 Add the sale banner
525030a Commit number 3
17b22a9 Commit number 2
a7300ee Commit number 1
```

```console
git branch sale-banner
git reset --hard HEAD~2

HEAD is now at 525030a Commit number 3
```

```console
git log --oneline --all --decorate --graph

* eab0f86 (sale-banner) Style the sale banner
* 03b7787 Add the sale banner
* 525030a (HEAD -> master) Commit number 3
* 17b22a9 Commit number 2
* a7300ee Commit number 1
```

Two commands, and it is worth understanding why they are in that order. `git branch sale-banner` creates a *second* name for the commit `HEAD` is on — it does not move you, it does not touch your files, it just writes a SHA into `.git/refs/heads/sale-banner`. Now two refs point at `eab0f86`. So when `git reset --hard HEAD~2` drags `master` backwards, the commits stay reachable through the other name and nothing is at risk.

Do it the other way round — reset first, then try to create the branch — and you are hunting through the reflog for the SHA. It will be there. But why put yourself through it?

The variant with `switch` does the same thing while taking you along for the ride:

```console
git switch -c sale-banner
git switch master
git reset --hard HEAD~2
```

> :information_source: `git reset --hard` is safe here *only because* your work is committed and named. Uncommitted changes in the working tree would be destroyed. If `git status` is not clean, `git stash` first.

## "Damn, I accidentally committed to the wrong branch!"

**What happened:** one commit landed on `master` and it belonged on `sale-banner`. Slightly different from the previous case, because the target branch already exists.

**What to do (option 1): copy it over, then rewind.**

```console
git log --oneline -1 master

3645fbe Fix the currency symbol
```

```console
git switch sale-banner
git cherry-pick master

[sale-banner 62ac72c] Fix the currency symbol
 1 file changed, 1 insertion(+)
 create mode 100644 hotfix.txt
```

`git cherry-pick <commit>` takes the change that commit introduced and applies it here as a new commit — essentially a one-commit rebase, with a new SHA (`3645fbe` became `62ac72c`). Then go and clean up the branch it should never have been on:

```console
git switch master
git reset --hard HEAD~1

HEAD is now at 525030a Commit number 3
```

```console
git log --graph --oneline --all --decorate

* 62ac72c (sale-banner) Fix the currency symbol
* eab0f86 Style the sale banner
* 03b7787 Add the sale banner
* 525030a (HEAD -> master) Commit number 3
{..}
```

**What to do (option 2): un-commit and re-commit.** If you have not switched branch yet, `--soft` is neater. It moves the branch pointer back but leaves the index and working tree exactly as they are, so the change is still staged and ready to go:

```console
git reset --soft HEAD~1
git status --short

A  w.txt
```

```console
git switch -c right-branch
git commit -m'Work that belongs elsewhere'
```

This is the third face of `git reset`, and now is a good moment to put all three side by side. [Playing with our revisions](../1-understanding-git/7-play-with-git-revisions.md "Playing with our revisions") showed you two of them:

| | branch pointer | index | working tree |
|---|---|---|---|
| `git reset --soft <c>` | moves | untouched | untouched |
| `git reset <c>` (`--mixed`, the default) | moves | reset to `<c>` | untouched |
| `git reset --hard <c>` | moves | reset to `<c>` | reset to `<c>` |

All three move the branch. They differ only in how much they take with them. `--soft` is the gentle one: "un-commit, keep everything staged". `--hard` is the only one that can destroy work you have not committed.

## "Shit, I did a `git reset --hard` and my work is gone!"

**What happened:** it depends entirely on one question. *Was it ever committed, or at least added to the index?*

**If it was committed:** it is fine. Really.

```console
git log --oneline -1

62ac72c Fix the currency symbol
```

```console
git reset --hard HEAD~2
git log --oneline -1

03b7787 Add the sale banner
```

```console
git reflog | head -3

03b7787 HEAD@{0}: reset: moving to HEAD~2
62ac72c HEAD@{1}: checkout: moving from master to sale-banner
525030a HEAD@{2}: reset: moving to HEAD~1
```

```console
git reset --hard HEAD@{1}

HEAD is now at 62ac72c Fix the currency symbol
```

Back. Total elapsed time: four seconds.

**If the reflog cannot help** — because you are in a fresh clone, or the reflog was expired by a `gc` — there is a second line of defence. Git's objects are still on disk even when no ref and no reflog mentions them:

```console
git reflog expire --expire=now --all      # simulating the worst case
git fsck --lost-found

dangling commit 37f0a8b9f4553ae6eca06efb066397884c16fc8d
```

```console
git log --oneline -1 37f0a8b

37f0a8b Three days of work
```

`git fsck --lost-found` writes what it finds into `.git/lost-found/` and prints it. `git fsck --unreachable --no-reflogs` is the more surgical version — and the `--no-reflogs` matters, because without it `fsck` treats reflog entries as roots and cheerfully reports that nothing is unreachable.

**And check the stash**, which people forget entirely. The stash is its own reflog (`refs/stash`), so a stash entry survives things that clobber your branches:

```console
git stash list

stash@{0}: On master: wip on a
```

```console
git stash show -p stash@{0}

diff --git a/a b/a
index 7898192..3199773 100644
--- a/a
+++ b/a
@@ -1 +1,2 @@
 a
+wip
```

Now the part where I am not going to be nice to you.

> :warning: **Changes that were never committed and never added to the index are gone. Completely. Forever.**
>
> `git reset --hard` overwrites the working tree from the index. Git never had a copy of what was in those files, so there is nothing to restore, and no command will bring it back. `git fsck` will not help; there is no object to find.
>
> The one crumb of hope: if you had run `git add` at any point — even minutes earlier, even without ever committing — Git wrote a **blob** for that version, and `git fsck --lost-found` may well find it. `git add` is not only about preparing a commit; it is a save point. That is a real reason to stage early and often.
>
> False hope is worse than bad news. If it was never staged and never committed, stop looking and start retyping. Some editors keep their own local history (JetBrains IDEs, VS Code's *Local History*, `vim`'s undo files) — that is a better place to look than Git.

## "Damn, I deleted a branch and it had two days of work on it!"

**What happened:** you deleted a *name*. The commits are untouched.

And Git, being kind, told you exactly which commit you have orphaned:

```console
git branch -D experiment

Deleted branch experiment (was 34d8133).
```

**What to do:** point a new name at it.

```console
git branch experiment 34d8133
```

Done. If you did not keep the SHA, the branch's own reflog went with it, but `HEAD`'s reflog remembers that you were there:

```console
git reflog | head -3

41796f0 HEAD@{0}: checkout: moving from experiment to main
34d8133 HEAD@{1}: commit: Two days of careful work
41796f0 HEAD@{2}: checkout: moving from main to experiment
```

And if even that is exhausted:

```console
git fsck --unreachable --no-reflogs

unreachable tree 259ba6c099bcee4e99d38a56970b0fa4db7041a5
unreachable commit 34d8133aa4ab96e591877833bccffba9e5977e11
unreachable blob b8f99f5be53f536f79ef622abaa77b9942a9e142
```

There is our commit. `git log --oneline 34d8133` to confirm it is the right one, then `git branch experiment 34d8133` to rescue it.

## "Shit, I need to undo a commit that I already pushed!"

**What happened:** the commit is out in the world. Other people have it. Which rules out every option that involves rewriting.

**What to do:** `git revert`. It computes the inverse of a commit and applies it as a *new* commit.

```console
git revert HEAD

[master 0179544] Revert "Change f on master"
 1 file changed, 1 insertion(+), 1 deletion(-)
```

```console
git log --oneline

0179544 Revert "Change f on master"
d82c967 Change f on master
710bcdb Initial commit
```

Both commits are in the history: the mistake, and the fix. Nothing has been rewritten, nobody has to force-push, nobody's clone breaks. Everyone can pull normally.

That last point is the whole argument. `git reset --hard HEAD~1` followed by a force-push would *also* remove the change, and it would also:

* break every colleague whose branch is based on that commit,
* be rejected outright by branch protection on any well-configured server,
* and quietly hide the fact that the bad change ever existed — which is exactly the information the next person debugging this needs.

`revert` keeps the history honest. Use it on anything shared, without hesitation.

> :information_source: A revert can conflict, like any other three-way merge — if the code has moved on since the commit you are reverting, Git has to work out how to un-apply it. `git revert --abort` and `git revert --continue` behave exactly like their `merge` counterparts. And you can always revert the revert: Git even names it for you, `Reapply "…"`.

## "Damn, I want to undo a whole merge!"

**What happened:** you merged a feature branch into `master`, pushed it, and now the feature turns out to be broken.

**What to do:** `git revert -m 1`. As we saw in the previous chapter, a merge commit has two parents, so `revert` has to be told which one is the mainline. For a merge into the branch you are on, that is always parent 1.

```console
git revert -m 1 5096af3

[master 42db35e] Revert "Merge branch 'banner'"
 2 files changed, 2 deletions(-)
 delete mode 100644 banner.css
 delete mode 100644 views_banner.html
```

```console
git log --graph --oneline

* 42db35e Revert "Merge branch 'banner'"
*   5096af3 Merge branch 'banner'
|\
| * 994a8ef Style the top banner
| * fd93999 Add the top banner markup
|/
* 8c85815 Add a
* b70b5a2 Initial commit
```

The feature's code is gone from the working tree; both the merge and its undoing are visible in the history. So far, so good.

And now the trap. It is a famous one, it catches everybody exactly once, and its failure mode is *silence*.

Two weeks later the branch is fixed, so you merge it again:

```console
git merge banner

Already up to date.
```

```console
ls

a.txt
```

"Already up to date" — and none of the feature's files are there.

**Why:** Git computes the merge base and sees that `994a8ef` is already an ancestor of `master`, because the first merge really did happen and is still in the history. Merging is defined in terms of *ancestry*, not content. From Git's point of view the branch **is** merged; the fact that a later commit deleted all its files is just an ordinary change on `master` which you presumably meant to make.

**What to do about it:** revert the revert.

```console
git revert 42db35e

[master 10f2155] Reapply "Merge branch 'banner'"
 2 files changed, 2 insertions(+)
 create mode 100644 banner.css
 create mode 100644 views_banner.html
```

```console
ls

a.txt
banner.css
views_banner.html
```

The files are back, and any new commits made on `banner` since then will now merge normally.

> :warning: The consequence for the shape of your work: **once you have reverted a merge, that branch cannot simply be re-merged.** Either revert the revert, as above, keeping the branch's original commits — or abandon the branch and rebase its remaining work onto current `master` as new commits. Deciding which of the two *before* you start will save you an afternoon.

## "Shit, I need to un-stage a file!"

**What happened:** you typed `git add` a little too enthusiastically.

**What to do**, in modern Git:

```console
git restore --staged lib/secret_debug_hack.js
```

The old spelling, which you will still see everywhere and which does exactly the same thing:

```console
git reset HEAD lib/secret_debug_hack.js
```

`git restore` and `git switch` were introduced in Git 2.23 to split up the impossibly overloaded `git checkout`. Learn `restore`; recognise `reset HEAD`.

Now the part that trips people up. There are three different "undo my changes", and confusing them is how you lose work. Start with `log.txt` containing three lines in the last commit, a fourth line staged, and a fifth line in the file but not staged:

```console
git status --short

MM log.txt
```

**`git restore --staged log.txt`** — index only. Your file is untouched; the staging goes away.

```console
git restore --staged log.txt
git status --short

 M log.txt
```

The working tree still has everything you typed. Completely safe.

**`git restore log.txt`** — working tree only, taken from the index.

```console
git restore log.txt
git status --short

M  log.txt
```

The file now matches what was staged. **The unstaged line is gone, and it is not recoverable.** This is the destructive one.

**`git restore --staged --worktree log.txt`** — both, from `HEAD`.

```console
git restore --staged --worktree log.txt
git status --short
```

Clean. The file is back to the last commit; everything you had done to it is gone.

> :warning: `git restore <file>` and `git restore --staged --worktree <file>` overwrite your working tree with no reflog and no undo. There is no `git restore --abort`. When you are not certain, `git stash` instead — it is the same "make my working tree clean" operation, except reversible.

## "Shit, I tried to do a diff but nothing happened?!"

**What happened:** you staged the changes, and then asked the wrong question.

`git diff` with no arguments means *working tree versus index*. Once you have run `git add`, those two are identical, so there is nothing to show. Git is answering correctly; you asked about the wrong pair.

There are three pairs, and three commands:

```console
git diff              # working tree vs index  -> what is NOT staged
git diff --cached     # index vs HEAD          -> what IS staged
git diff HEAD         # working tree vs HEAD   -> everything, staged or not
```

With one line staged and another line only in the file:

```console
git diff

diff --git a/log.txt b/log.txt
index ae31c32..3ddc309 100644
--- a/log.txt
+++ b/log.txt
@@ -2,3 +2,4 @@ line 1
 line 2
 line 3
 staged change
+and an unstaged one
```

```console
git diff --cached

diff --git a/log.txt b/log.txt
index a92d664..ae31c32 100644
--- a/log.txt
+++ b/log.txt
@@ -1,3 +1,4 @@
 line 1
 line 2
 line 3
+staged change
```

```console
git diff HEAD

diff --git a/log.txt b/log.txt
index a92d664..3ddc309 100644
--- a/log.txt
+++ b/log.txt
@@ -1,3 +1,5 @@
 line 1
 line 2
 line 3
+staged change
+and an unstaged one
```

`--staged` is an alias for `--cached`: identical behaviour, friendlier name.

The same logic explains the other classic non-event. `git diff <branch>` compares your working tree to that branch's tip, while `git diff <branch>...HEAD` — three dots — compares against the **merge base**, which is almost always what you meant when you asked "what does my branch add?".

## "Oh no. I committed a huge file. Or worse, an API key."

Two problems that look the same and are not. Let us separate them immediately, because the important one is not the one about Git.

### If it is a secret

> :warning: **A pushed secret is a compromised secret. Rotate it. Now. Before you read the rest of this section.**
>
> Rewriting history does not un-leak anything. By the time you noticed, the credential may already exist in: every clone and fork anybody made, including ones you cannot see; your CI provider's build logs and caches; your hosting provider's own storage, where a "dangling" object stays reachable by URL for a long time and pull-request refs keep old commits alive even after you have force-pushed the branch; whatever scraper found your repository, and they are fast — public repositories are scanned for keys within *seconds* of a push; somebody's editor, somebody's shell history, a Slack paste.
>
> Revoke the key, issue a new one, and check the access logs for the old one. Cleaning the history is housekeeping you do afterwards, and it is optional. Rotating the credential is not.

Right. Now the housekeeping.

### Removing a file from all of history

If the file is only in a commit you have not pushed yet, this is easy: `git reset --soft HEAD~1`, unstage it, add it to `.gitignore`, commit again.

If it is deeper in the history, you have to rewrite every commit from that point forward. There is a command for this that you will find in every old Stack Overflow answer, and Git's own manual page now opens like this:

```console
git help filter-branch

WARNING
       git filter-branch has a plethora of pitfalls that can produce
       non-obvious manglings of the intended history rewrite (and can leave
       you with little time to investigate such problems since it has such
       abysmal performance). These safety and performance issues cannot be
       backward compatibly fixed and as such, its use is not recommended.
       Please use an alternative history filtering tool such as git
       filter-repo.
```

That is not my opinion, that is the manual shipping with Git 2.51. Do not use `git filter-branch`.

Use **`git-filter-repo`** (a single Python script, installable from your package manager or with `pip`), or **BFG Repo-Cleaner** (a JAR; faster on very large repositories, less flexible). Here is `filter-repo` doing the job:

```console
git log --oneline

fdd6136 Improve the app
6dae2b0 Add the env file
b2e54c6 Initial commit
```

```console
git filter-repo --invert-paths --path .env --force

Parsed 3 commits
New history written in 0.07 seconds; now repacking/cleaning...
Repacking your repo and cleaning out old unneeded objects
Completely finished after 0.23 seconds.
```

```console
git log --oneline

6c57530 Improve the app
b2e54c6 Initial commit
```

The `.env` file is gone from every commit, and the commit that consisted only of adding it has disappeared with it. Note the SHAs: `fdd6136` became `6c57530`. Every commit after the rewrite point is a different object.

Which is the real cost, and it is not small:

> :warning: A history rewrite changes every SHA from the rewrite point onwards. That means **everyone must re-clone.** Their existing clones share no history with the new one, so any `git pull` will try to merge two parallel copies of the entire project. Open pull requests will be confused or broken. Tags need re-pushing. `git filter-repo` deliberately removes your `origin` remote afterwards, to stop you force-pushing before you have thought about it.
>
> Announce it, pick a moment, and make sure everybody has pushed their work first.

### Prevention, which is much cheaper

* **`.gitignore` your secret files before you write them.** See [A little structure please](4-git-repo-structure.md "A little structure please"). `.env`, `*.pem`, `credentials.json`, `id_rsa`. Commit a `.env.example` with the keys and no values.
* **A pre-commit hook that scans for secrets.** `gitleaks` and `trufflehog` are the two well-known scanners; both run happily from a hook or in CI, and the `pre-commit` framework wires them up in a few lines.
* **Turn on your host's scanning.** GitHub's *secret scanning* alerts you when a known credential format lands in your repository, and *push protection* rejects the push before the secret ever exists on the server — which makes it the only mechanism in this section that actually prevents the leak rather than reporting it. GitLab has an equivalent. Both are free for public repositories. Turn them on.
* **For the huge-file problem specifically:** Git LFS, or simply not putting the 400MB video in the repository at all. Git stores every version of a binary in full; a repository that has accumulated a few of those is slow to clone forever.

## "Damn, I have twelve WIP commits and my colleague has to review this."

**What happened:** nothing wrong at all. This is how work actually gets done: `wip`, `wip2`, `actually fix it`, `revert that`, `ok now`. The mistake would be to inflict it on a reviewer.

**What to do:** `git rebase -i` against the branch you will merge into, and edit the to-do list into the story you wish you had written.

```console
git rebase -i main
```

* Reorder lines to group related work.
* `squash` or `fixup` the "oops" commits into the commit they fix.
* `reword` the messages that made sense at 2am.
* `drop` the commits that exist only to undo other commits.
* `git rebase -i --exec 'npm test' main` to check that every resulting commit actually builds.

If you have been marking your fixups as you go with `git commit --fixup <commit>` — see [the previous chapter](5-git-workflow.md "Implement an efficient collaborative workflow") — then `--autosquash` builds most of the to-do list for you.

### Splitting one commit into two

The one manoeuvre that looks like magic. You have a commit that fixes a bug *and* corrects an unrelated typo, and they should be two commits.

```console
git log --oneline

f30a4c5 Fix the cart and also a typo
e2ab2ee Initial commit
```

Start an interactive rebase and mark that commit `edit`:

```console
git rebase -i HEAD~1
```

```console
edit f30a4c5 # Fix the cart and also a typo
```

Git applies the commit and stops, leaving you standing on it:

```console
Stopped at f30a4c5...  Fix the cart and also a typo
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
```

Now un-commit it, keeping the changes in the working tree:

```console
git reset HEAD^
git status --short

 M a.txt
 M b.txt
```

The commit is gone; its content is not. Commit the pieces separately — and when the two halves live in the *same* file, `git add -p` walks you through the diff hunk by hunk asking "stage this one?", which is the tool that makes the whole technique work:

```console
git add a.txt
git commit -m'Fix the cart total'
git add b.txt
git commit -m'Fix a typo in the product page'
git rebase --continue

Successfully rebased and updated refs/heads/master.
```

```console
git log --oneline

4099c04 Fix a typo in the product page
bd3a26d Fix the cart total
e2ab2ee Initial commit
```

One commit became two, in the right order, in the middle of a branch.

## "Shit, something broke and I have no idea which commit did it."

**What happened:** it worked last week, it does not work now, and there are two hundred commits in between.

**What to do:** stop reading commits. Let Git binary-search them. `git bisect` is the most underused command in Git and it is genuinely magic.

Here is a repository where `./price.sh` should print `12` and prints `13`:

```console
git log --oneline

74604a1 Reorder the functions
8dd3203 Bump the version
0beff0b Add a second helper
de7a387 Update the developer docs
4c5fe6a Introduce the configurable tax rate
9d35fcf Tidy up the whitespace
18aa588 Refactor the rounding
ef6169b Add the currency symbol
a153a12 Document the price helper
92dfde8 Rename the price helper
46371db Add the price script
```

Tell Git one commit that is broken and one that was fine:

```console
git bisect start
git bisect bad
git bisect good 46371db

Bisecting: 4 revisions left to test after this (roughly 2 steps)
[9d35fcf070ec73c1683b9ab1f99a0bdf6c3a2940] Tidy up the whitespace
```

`git bisect bad` with no argument means "the commit I am on". Git has now checked out the middle of the range and is waiting. Test it, and tell it what you found:

```console
./price.sh

12
```

```console
git bisect good

Bisecting: 2 revisions left to test after this (roughly 1 step)
[de7a387111fa72a0e6daa3238b6042f3113c716e] Update the developer docs
```

```console
./price.sh

13
```

```console
git bisect bad

Bisecting: 0 revisions left to test after this (roughly 0 steps)
[4c5fe6a24048ed630e626aa791e899a5bba7fc08] Introduce the configurable tax rate
```

Ten commits, three tests. That is binary search: each answer halves the range, so a thousand commits cost you ten tests.

### `git bisect run`: the part that is actually magic

If you can express "is it broken?" as a script that exits 0 for good and non-zero for bad, you do not have to sit there at all.

```console
cat check.sh

#!/bin/sh
test "$(./price.sh)" = "12"
```

```console
git bisect start
git bisect bad
git bisect good 46371db
```

```console
git bisect run ./check.sh

running './check.sh'
Bisecting: 2 revisions left to test after this (roughly 1 step)
[de7a387111fa72a0e6daa3238b6042f3113c716e] Update the developer docs
running './check.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[4c5fe6a24048ed630e626aa791e899a5bba7fc08] Introduce the configurable tax rate
running './check.sh'
4c5fe6a24048ed630e626aa791e899a5bba7fc08 is the first bad commit
commit 4c5fe6a24048ed630e626aa791e899a5bba7fc08
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Tue Feb 17 14:00:00 2026 +0100

    Introduce the configurable tax rate

 notes.md | 1 +
 price.sh | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
bisect found first bad commit
```

You typed four lines and Git handed you the commit, the author, the date and the diff. On a real project this is usually something like `git bisect run npx jest path/to/failing.test.js` or `git bisect run pytest -x tests/test_thing.py`, left to churn while you make coffee.

Write the check script *first*, and make it as narrow as you can. A script that takes two seconds turns a twenty-commit bisect into a coffee break; one that runs the whole suite for eight minutes does not.

**When you are done, always:**

```console
git bisect reset

Previous HEAD position was 4c5fe6a Introduce the configurable tax rate
Switched to branch 'master'
```

That puts you back on the branch you started from. Forgetting it leaves you sitting in a **detached head** wondering why your editor is showing old code.

Two more:

* `git bisect skip` — this commit cannot be tested (it does not build, a dependency is broken). Git works around it.
* `git bisect log` — the transcript so far. Save it; `git bisect replay <file>` re-runs it, which is how you recover when you answered one wrong.

> :information_source: Bisect only works if the history is bisectable — that is, if most commits build and run. This is the practical, selfish argument for all the discipline in the previous chapter: small commits that each work, merged with `--no-ff` so that `git bisect start --first-parent` can walk features rather than keystrokes. A history of `wip` commits that do not compile cannot be bisected, and you will discover this on the day you most need it.

## "Damn, my working tree is a disaster and I want to start over."

**What happened:** half-finished edits in nine files, four experimental scripts, a directory of debug output. You want the state you had this morning.

**What to do:** three commands, in increasing order of violence.

**1. Throw away changes to tracked files:**

```console
git restore .
```

**2. Deal with untracked files** — and here you must be careful, because `git clean` is one of the very few Git commands that destroys data with no way back. Always look first, with `-n` (dry run):

```console
git clean -nd

Would remove oops.txt
Would remove scratch/
```

Read that list. Then, and only then:

```console
git clean -fd

Removing oops.txt
Removing scratch/
```

`-f` is force (Git refuses without it, on purpose), `-d` includes directories.

> :warning: **`git clean` has no reflog, no stash, no undo.** Untracked files were never in Git, so Git has no copy of them. `git clean -fd` deletes them the way `rm -rf` deletes them.
>
> And `-x` is worse. It also removes **ignored** files — which is to say your `.env`, your `node_modules/`, your `venv/`, your local database, your `.idea/` settings, whatever else `.gitignore` protects. `git clean -fdx` is a legitimate command; it is the correct way to get a truly pristine tree, and CI runners use it. But run `git clean -ndx` first, every single time, and read the list:

```console
git clean -ndx

Would remove .env
Would remove node_modules/
Would remove oops.txt
Would remove scratch/
```

That is your API keys and forty minutes of `npm install`. Worth ten seconds of reading.

**3. Rewind to the last commit entirely:**

```console
git reset --hard
```

With no argument it means `git reset --hard HEAD`: index and working tree back to the last commit. Combined with `git clean -fd`, that is the full reset button.

> :information_source: The safer habit, and the one I would suggest: instead of `git restore .` plus `git clean -fd`, use `git stash push -u -m 'the mess of 3 March'`. Your tree ends up just as clean, and everything is still there if it turns out that one of those nine files contained the good idea. Stashes are cheap; you can drop them next week.

## "Damn, I'm in the middle of something and I need to switch context right now."

**What happened:** production is on fire, or a colleague needs a review, and your working tree is half a feature.

**What to do:** `git stash`. We met it in [Collaborate with Git](1-collaborate-with-git.md "Collaborate with Git"); here is the full set.

```console
git stash push -u -m 'wip: VAT on the cart total'

Saved working directory and index state On master: wip: VAT on the cart total
```

Two flags that matter:

* **`-m <message>`.** Always. A stash list of six entries all saying `WIP on master: 51de6d1 Initial shopping cart code` is a puzzle you have set for yourself.
* **`-u`** (`--include-untracked`). Without it, brand-new files are *left behind in your working tree*, which is a very confusing way to discover that your "clean" tree is not clean. `-a` also includes ignored files, which you almost never want.

Then:

```console
git stash list

stash@{0}: On master: wip: VAT on the cart total
```

* `git stash show --stat` — what is in the top stash. Add `-p` for the patch, and `--include-untracked` to see the new files too; it does not show them by default, which surprises people.
* `git stash pop` — apply the top stash and delete it.
* `git stash apply` — apply it and *keep* it. Use this when you are not sure it will apply cleanly; you can always drop it afterwards.
* `git stash drop stash@{1}` — delete one. `git stash clear` deletes them all, and has no undo worth relying on.
* `git stash branch <name>` — the underrated one. It creates a branch from the commit the stash was made on, applies the stash there, and drops it. This is the right answer when a stash has gone stale and no longer applies to your current branch:

```console
git stash branch vat-experiment

Switched to a new branch 'vat-experiment'
On branch vat-experiment
Changes not staged for commit:
	modified:   cart.js

Untracked files:
	cart.test.js

Dropped refs/stash@{0} (84f5108c32f515a93f3dab9ee44f3f09019a0521)
```

And because we like looking under the hood: a stash is not a special data structure. It is a commit, on a ref called `refs/stash`, and with `-u` it has *three* parents.

```console
git cat-file -p stash@{0}

tree 31ee6cd9e70d9b4dc8cd2d087b525135c863c155
parent 51de6d1143332b4224d19af5d4fdce11f1b2878e
parent 615417a415e96155d1eb0025278b16786a9970ff
parent f8c0a1974c63e9d2d1a9f687c3dbe92f131dd14d
author Ori Pekelman <ori+git-training@pekelman.com> 1772532000 +0100
committer Ori Pekelman <ori+git-training@pekelman.com> 1772532000 +0100

On master: wip: VAT on the cart total
```

The commit you were on, a commit holding your index, and a commit holding your untracked files. Which is why a stash survives almost anything: it is an ordinary commit, with an ordinary reflog.

> :information_source: The stash is a stack, and it is easy to let it become a pile of things you will never look at again — six stashes deep, none of them labelled, all of them stale. If what you actually want is "work on two things at once", a **worktree** is nearly always the better answer: a second directory, checked out on a different branch, sharing the same `.git`. No stashing, no context switch, both things open at once. See [One repository, many working trees](../4-beyond-the-basics/1-git-worktree.md "One repository, many working trees").

## "Damn, I'm in 'detached HEAD' and I don't know where I am."

**What happened:** you checked out a commit, a tag, or a remote-tracking branch directly — or you are in the middle of a bisect or a rebase. **HEAD** contains a SHA instead of `ref: refs/heads/...`, exactly as we saw in [Playing with our revisions](../1-understanding-git/7-play-with-git-revisions.md "Playing with our revisions"). Commits you make here belong to no branch.

**What to do:** first, ask.

```console
git status

HEAD detached at 4c5fe6a
nothing to commit, working tree clean
```

Nothing has gone wrong. A **detached head** is a normal, useful state — it is how you look at the past.

**If you made commits here and want to keep them**, give them a name:

```console
git switch -c experiment

Switched to a new branch 'experiment'
```

```console
git log --oneline -2

b90c247 An experiment made in detached HEAD
4c5fe6a Introduce the configurable tax rate
```

Your commits now live on a branch and are safe.

**If you do not want them**, just leave: `git switch main`, and Git forgets about them. The reflog does not, for a few weeks.

**And `git switch -`** goes back to the previous branch, the way `cd -` does. Note that it needs the previous location to *be* a branch:

```console
git switch -

fatal: a branch is expected, got commit 'b90c24737a397bfa37da909d9b94e91a82d33f52'
hint: If you want to detach HEAD at the commit, try again with the --detach option.
```

Honest and clear: it cannot switch to a commit, because switching is a branch operation. Name your branch, or say where you want to go.

## "Shit, I'm not doing anymore, I give up?"

Excellent. Giving up is a technique.

**If you are in the middle of an operation**, every one of them has an escape hatch, and every one of them puts you back exactly where you started:

```console
git merge --abort
git rebase --abort
git cherry-pick --abort
git revert --abort
git am --abort
git bisect reset
```

(`git am` applies patches from email; you will meet it if you ever contribute to a mailing-list project.) And if you cannot remember which operation you are in, `git status` tells you on its first line.

**If you are past that** — three failed rebases, a half-resolved conflict, a working tree you no longer recognise, and honestly no idea what state anything is in — then here is the nuclear option. I want to be clear that it is a legitimate, professional move and not a failure:

```console
cd ..
git clone git@example.com:team/shop.git shop-fresh
cd shop-fresh
git switch -c my-feature
# copy the files you care about across by hand
```

Clone fresh from the remote into a new directory. Copy your files over with a file manager. Commit them in one clean commit. Push. Delete the broken directory when you feel calm about it.

You lose the history of your local branch, which was `wip`, `wip2` and `fix the wip` anyway. You lose nothing that matters, you spend ten minutes, and you are done. Compare that with the hour you were about to spend excavating `.git/rebase-merge/` and reading `git fsck` output while your colleagues wait.

Senior engineers do this. It is not cheating. The goal is working software, not a demonstration that you can out-argue a state machine at six in the evening.

> :warning: One thing to check before you delete the old directory: run `git stash list` and `git log --oneline --all` in the broken repository, so that you are certain nothing you want is still in there. And keep the directory around for a day. Directories are cheap.

## The two habits that make all of this rare

Everything above is a cure. There are only two preventions, and they are both cheap.

**Commit small and often.** A commit is a save point, and it is the cheapest operation in Git — no server round-trip, no ceremony. If your work is committed, then almost nothing in this chapter is a disaster: it is a pointer to move back. The people who lose work in Git are, essentially without exception, the people with four hours of uncommitted changes. Make ugly commits on your own branch all day and clean them up with `rebase -i` before anyone sees them. That is what it is for.

And the smaller corollary: `git add` early. Staging writes a **blob** into `.git/objects`, which means even an uncommitted change becomes findable with `git fsck`. It is a save point below the save point.

**Never rewrite shared history.** Every genuinely painful, multi-person, day-consuming Git disaster comes from this one thing: `--amend`, `rebase`, `reset --hard` or `push --force` on a branch other people are using. Your own branch: rewrite freely, force-push with `--force-with-lease`. `main`: never. There is no third case.

That is it. Those two habits, plus knowing that `git reflog` exists, are the difference between Git being frightening and Git being the safest place your code can live.

Which brings us back to the reassurance I promised at the top, and which I hope you now believe: **Git almost never loses committed data.** It keeps objects it no longer needs. It logs every move of every ref. It refuses destructive operations against a remote unless you insist. The overwhelming majority of "I lost my work" turns out to be "I lost track of my work", and the cure is a command you already know.

If you take one thing from this chapter, take this: when something goes wrong, before anything else, type `git reflog`.

## Summary `git reflog` `git revert` `git bisect` `git stash` `git clean`

* **`git reflog`** is the single most valuable command in this chapter. Every ref movement is logged, so `git reset --hard HEAD@{1}` undoes whatever you just did. Also `git reflog <branch>`, `master@{5}`, `HEAD@{2.hours.ago}`, `git log -g`. It is local, and entries expire after 30–90 days.
* `git commit --amend` (`--no-edit`) fixes the last commit or its message; `git rebase -i` plus `reword` fixes an older one.
* **Committed to the wrong place?** `git branch <newname>` first, *then* `git reset --hard HEAD~n`. Or `git reset --soft HEAD~1`, switch, and re-commit. Or `git cherry-pick` onto the right branch and reset the wrong one.
* `git reset --soft` moves the branch only; `--mixed` (the default) also resets the index; `--hard` also resets the working tree, and is the only one that destroys uncommitted work.
* **Lost commits:** `git reflog`, then `git fsck --lost-found` or `git fsck --unreachable --no-reflogs`, then `git stash list`. Changes that were never added to the index and never committed are gone for good — which is why you should `git add` early: staging is itself a save point.
* **Deleted a branch?** `git branch -D` prints the SHA it deleted. Otherwise `HEAD`'s reflog, or `git fsck --unreachable --no-reflogs`, then `git branch <name> <sha>`.
* **`git revert`** undoes a pushed commit by adding a new one, so nobody has to re-clone and the history stays honest. `git revert -m 1 <merge>` undoes a whole merged feature.
* After reverting a merge, re-merging that branch does nothing (`Already up to date`) because Git goes by ancestry, not content. Revert the revert, or rebase the remaining work.
* `git restore --staged <file>` un-stages, index only, safe. `git restore <file>` discards working-tree changes — destructive, no undo. `git restore --staged --worktree <file>` does both. `git reset HEAD <file>` is the old spelling of the first.
* `git diff` = working tree vs index; `git diff --cached` (`--staged`) = index vs **HEAD**; `git diff HEAD` = everything.
* **Secrets:** rotate the credential first — rewriting history does not un-leak it. `git filter-branch` is deprecated by Git's own manual; use `git filter-repo` or BFG, and remember that everyone must re-clone. Prevent with `.gitignore`, `gitleaks`/`trufflehog` in a pre-commit hook, and your host's secret scanning and push protection.
* **Tidying WIP:** `git rebase -i`, `--autosquash` with `git commit --fixup`, and splitting a commit with `edit` + `git reset HEAD^` + `git add -p`.
* **`git bisect start` / `bad` / `good` / `reset`** binary-searches your history; **`git bisect run ./check.sh`** does it for you, unattended. `git bisect skip` for untestable commits, `git bisect log` and `replay` to save and redo a session.
* **Starting over:** `git restore .`, then `git clean -nd` to look before `git clean -fd` to delete. `git clean` has no undo, and `-x` also deletes your `.env` and your `node_modules`. `git reset --hard` rewinds to the last commit.
* **`git stash push -u -m '…'`**, then `stash list` / `show -p` / `apply` / `pop` / `drop` / `branch`. A stash is just a commit with two or three parents. For working on two things at once, a [worktree](../4-beyond-the-basics/1-git-worktree.md "One repository, many working trees") is usually better.
* **Detached head:** `git status` to see where you are, `git switch -c <name>` to keep the commits, `git switch <branch>` to abandon them, `git switch -` to go back to the previous branch.
* **Giving up:** `git merge --abort`, `git rebase --abort`, `git cherry-pick --abort`, `git revert --abort`, `git am --abort`, `git bisect reset` — and, entirely legitimately, a fresh `git clone` into a new directory with your files copied across by hand.
* **The two habits:** commit small and often, and never rewrite shared history.
