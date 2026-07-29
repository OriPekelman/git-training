---
title: Retrieve and send code
url: "/docs/git-clone-pull-remote/"
weight: 13
---
# Retrieve and send code

We now know what a **remote** is: a name for a URL and a **refspec**, written in `.git/config`. We know that `origin/master` is a local cache and not the server. Time to actually move objects around.

Three commands do all the work: `git clone` to get a repository in the first place, `git fetch` to bring down what changed, `git push` to send up what we changed. `git pull` is a fourth that is really the second plus a merge, and we are going to be a little rude about it.

We will keep using a directory on our own disk as the remote, exactly as in the previous chapter. Everything shown here behaves identically against an SSH or HTTPS URL — the only difference is the URL and a few progress lines.

## Locally reproducing code stored elsewhere: `git clone`

```console
cd ~/projects
git clone ~/projects/my_first_git_project.git my_project_clone
```
```console
Cloning into 'my_project_clone'...
done.
```

Terse. Over a network you would also see a handful of progress lines — `remote: Enumerating objects`, `remote: Counting objects`, `Receiving objects`, `Resolving deltas` — which are Git and the server telling each other how much work is left. Locally there is nothing to enumerate, so: `done.`

Now, `clone` looks like one operation but it is five, and knowing which five explains every question you will ever have about it. In order:

1. **`git init`** a new repository in the target directory. If we don't give a directory name, Git derives one from the URL (`my_first_git_project`, dropping the `.git`).
2. **Add a remote called `origin`** pointing at the URL we gave. *This* is where the convention comes from — nothing more mystical than a default in `clone`.
3. **Fetch everything**: all objects reachable from all the remote's branches and tags, into `.git/objects`.
4. **Create the remote-tracking refs**, per the refspec: every `refs/heads/*` over there becomes a `refs/remotes/origin/*` here.
5. **Create one local branch** — matching whatever the remote's **HEAD** points at — set its **upstream**, and check it out into the working tree.

Every one of those five is visible. Step 1 and 5:

```console
cd my_project_clone
ls -a
```
```console
.  ..  .git  media  readme.md
```

Step 2 and the upstream from step 5:

```console
cat .git/config
```
```console
[core]
	{..}
[remote "origin"]
	url = /Users/oripekelman/projects/my_first_git_project.git
	fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
	remote = origin
	merge = refs/heads/master
```

Not one line of that is new to us. We wrote the identical thing by hand in the previous chapter with `git remote add` and `git push -u`. `clone` is a convenience wrapper, and now you could implement it yourself.

Step 4, and the answer to "where are my refs":

```console
tree .git/refs
cat .git/packed-refs
```
```console
.git/refs
├── heads
│   └── master
├── remotes
│   └── origin
│       └── HEAD
└── tags
```
```console
# pack-refs with: peeled fully-peeled sorted
973f21b9767b572145add7f9e4444a14529fc1fe refs/remotes/origin/master
1213fc5f325573870748535e5d457573a9c80b50 refs/remotes/origin/shopping_cart
```

Notice the asymmetry: `refs/heads/master` is a loose file, because Git wrote it last and hasn't tidied it, while the remote-tracking refs are already **packed**. Also notice `refs/remotes/origin/HEAD` — a note of which branch the server considers default, which is why `git branch -a` can say:

```console
git branch -a
```
```console
* master
  remotes/origin/HEAD -> origin/master
  remotes/origin/master
  remotes/origin/shopping_cart
```

And step 5's most important consequence, which surprises people:

```console
git branch -vv
```
```console
* master 973f21b [origin/master] Add readme.md and the media directory
```

**One** local branch. The server has two, we got remote-tracking refs for both, but Git only created a local branch for the default one. `shopping_cart` is not missing — `git checkout shopping_cart` will create a local branch tracking `origin/shopping_cart` on the spot, because Git notices that the name is unambiguous among your remotes. But until you ask, it stays a bookmark.

### Useful `clone` options

**`--branch <name>`** (or `-b`) checks out that branch instead of the default. It also works with a **tag**, in which case you land in a **detached head**, which is exactly right for "build this release".

```console
git clone --branch shopping_cart ~/projects/my_first_git_project.git cart
cd cart && git branch -vv
```
```console
* shopping_cart 1213fc5 [origin/shopping_cart] Implement shopping cart template
```

**`--single-branch`** goes further and narrows the refspec so you fetch only that one branch, forever, until you widen it again.

**`--depth <n>`** makes a *shallow* clone: only the last `n` commits, no ancestors. On a big project this is the difference between three hundred megabytes and three.

```console
git clone --depth 1 ~/projects/my_first_git_project.git shallow_plain
```
```console
Cloning into 'shallow_plain'...
warning: --depth is ignored in local clones; use file:// instead.
done.
```

There is the distinction from the last chapter, in the wild. A plain path is not a transport, so there is no protocol to be shallow over. Add the scheme and it works:

```console
git clone --depth 1 file://$HOME/projects/my_first_git_project.git shallow
cd shallow && git log --oneline
```
```console
5d22437 Expand the contribution guidelines
```

One commit. Where the second one should be, there is a lie:

```console
cat .git/shallow
```
```console
5d224378681f9bf3e68915ad9d3a486ba17bc3ab
```

That file lists commits Git should pretend have no parents. That's all a shallow clone is — a small text file telling Git where to stop walking.

Now the honest part, because shallow clones are handed out as advice far too casually. History is what Git is *for*, and you just threw it away:

* `git log` on a file stops at the boundary. Archaeology — "when did this line change, and why" — is gone.
* `git blame` works only within what you have. `git blame -C`, which follows content across file moves, has nothing to follow.
* `git describe` can't find a tag it doesn't have, so version strings in your build go weird.
* Merges and rebases across the boundary can fail, because Git cannot find a merge base.
* `git bisect` has nothing to bisect.

Which is why shallow clones belong in exactly one place: **CI**. A build agent wants the code, once, quickly, and then it is destroyed. It does not want to do archaeology. For your own working copy, clone the whole thing; you will want the history the first time something breaks.

If you shallow-cloned and now regret it:

```console
git fetch --unshallow
git log --oneline
```
```console
5d22437 Expand the contribution guidelines
1b47e8c Add contribution guidelines
2eaa6ce Add a TODO list
9056566 Add a license file
d0dcf58 Describe the project in the readme
973f21b Add readme.md and the media directory
```

The rest of the history arrives and `.git/shallow` goes away.

**`--filter=blob:none`** is the modern answer, and it is much better. It makes a *partial* clone: fetch all the commits and all the trees — the entire shape of history — but none of the file contents. Blobs are downloaded lazily, one by one, the moment some command actually needs one.

```console
git clone --filter=blob:none file://$HOME/projects/my_first_git_project.git partial
cat partial/.git/config
```
```console
[core]
	repositoryformatversion = 1
	{..}
[remote "origin"]
	url = file:///Users/oripekelman/projects/my_first_git_project.git
	fetch = +refs/heads/*:refs/remotes/origin/*
	promisor = true
	partialclonefilter = blob:none
```

`promisor = true` means "this remote has promised to give me the objects I am missing, whenever I ask". `git log` is fast and complete. `git blame` on one file downloads the blobs for that one file. Nothing is a lie, unlike a shallow clone; things are merely absent, and they arrive when needed. You do need to be online to touch old content.

The server has to agree to this, and if it doesn't, Git tells you and carries on:

```console
warning: filtering not recognized by server, ignoring
```

Combine it with **`--sparse`** and you have the real answer to "our monorepo is enormous": don't check out the whole tree either.

```console
git clone --filter=blob:none --sparse file://$HOME/projects/my_first_git_project.git sparse
cd sparse && ls
```
```console
CONTRIBUTING.md  LICENSE  readme.md  TODO
```

The root files, no subdirectories. The rule set lives in a file, and it is short:

```console
cat .git/info/sparse-checkout
```
```console
/*
!/*/
```

"Everything at the top level, but none of the directories." Those two lines are Git's "cone mode", which just means the patterns are restricted to whole directories so Git can decide fast. Then you opt in to the parts you work on:

```console
git sparse-checkout add media
git sparse-checkout list
```
```console
media
```
```console
ls
```
```console
CONTRIBUTING.md  LICENSE  media  readme.md  TODO
```

`git sparse-checkout set lib views` replaces the list, `git sparse-checkout disable` turns it all off and checks everything out. Nothing is lost — this is a working-tree filter, the repository still has everything (or can promise to fetch it).

**`--recurse-submodules`** clones and initialises the project's submodules in one go. Without it you get empty directories where the submodules should be and a confusing afternoon. If you forgot: `git submodule update --init --recursive`.

**`--bare`** clones the database with no working tree — the shape we dissected in the previous chapter:

```console
git clone --bare ~/projects/my_first_git_project.git bare_copy.git
cat bare_copy.git/config
```
```console
[core]
	{..}
	bare = true
[remote "origin"]
	url = /Users/oripekelman/projects/my_first_git_project.git
```

Look closely at that `[remote "origin"]` block: **there is no fetch refspec**. So there are no remote-tracking refs; the branches came down straight into `refs/heads/`:

```console
cat bare_copy.git/packed-refs
```
```console
# pack-refs with: peeled fully-peeled sorted
5d224378681f9bf3e68915ad9d3a486ba17bc3ab refs/heads/master
1213fc5f325573870748535e5d457573a9c80b50 refs/heads/shopping_cart
```

Which is what you want for a server: its `master` is *its own* `master`, not a cache of somebody else's.

**`--mirror`** looks like the same thing and is not:

```console
git clone --mirror ~/projects/my_first_git_project.git mirror_copy.git
cat mirror_copy.git/config
```
```console
[core]
	{..}
	bare = true
[remote "origin"]
	url = /Users/oripekelman/projects/my_first_git_project.git
	tagOpt = --no-tags
	fetch = +refs/*:refs/*
	mirror = true
```

There is the refspec, and read it: `+refs/*:refs/*`. Not just branches — *everything*, mapped onto itself. Branches, tags, notes, remote-tracking refs of the original, the lot, at the same paths. Plus `mirror = true`, which makes `git push` push all of it back and delete anything the source has deleted.

So: `--bare` is "a server copy of the branches". `--mirror` is "an exact, self-updating replica". `--mirror` plus `git remote update` in a cron job is a two-line backup strategy for a Git host, and it is how you move a repository from one host to another without losing a tag.

> :warning:
> `git push --mirror`, or pushing from a mirror clone, will happily delete refs on the destination that the source doesn't have. That is the point of a mirror. It is also how people accidentally delete forty branches. Read the URL twice.

## Fetch changes made by others: `git fetch` and `git pull`

Somebody else has been working. In our little world, "somebody else" is the clone we just made; they committed and pushed. What do we do?

We do **not** start with `git pull`. We start with `git fetch`, and I want to explain why with real output rather than an assertion.

Right now our `git status` claims we are up to date, and — as we established in the previous chapter — that claim is about our *memory* of the server, not the server. So we go and ask:

```console
git fetch
```
```console
From /Users/oripekelman/projects/my_first_git_project
   973f21b..d0dcf58  master     -> origin/master
```

**That is everything `git fetch` did.** It downloaded objects into `.git/objects` and moved one remote-tracking ref from `973f21b` to `d0dcf58`. It did not touch `refs/heads/master`. It did not touch the **index**. It did not touch a single file in our working directory. If we had half-finished edits open in an editor, they are exactly as they were.

This is why `git fetch` is the safest command in Git after `git status`. It cannot lose work, it cannot cause a conflict, it cannot surprise you. Run it whenever you feel like knowing things.

Now that the facts are local, we can *look* before we leap:

```console
git status
```
```console
On branch master
Your branch is behind 'origin/master' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
```

```console
git log --oneline HEAD..origin/master
```
```console
d0dcf58 Describe the project in the readme
```

```console
git diff HEAD origin/master
```
```console
diff --git a/readme.md b/readme.md
index 3836229..94190ef 100644
--- a/readme.md
+++ b/readme.md
@@ -1 +1,3 @@
 # My first Git project
+
+A project about learning Git.
```

Which commits are coming, and what they will do to my files. *Before* they do it. `git log --stat HEAD..origin/master` if you'd rather see the file list than the diff.

And only then do we integrate. Since our branch has no commits of its own, this is the **fast-forward** we met in Part 1 — Git just moves the reference:

```console
git merge
```
```console
Updating 973f21b..d0dcf58
Fast-forward
 readme.md | 2 ++
 1 file changed, 1 insertion(+)
```

A bare `git merge` with no argument merges the configured upstream, which is what we want.

### So what is `git pull`?

`git pull` is `git fetch` followed by `git merge`. Or `git fetch` followed by `git rebase`, if you configured it that way. Which one you get depends on config you may not remember setting.

```console
git pull
```
```console
From /Users/oripekelman/projects/my_first_git_project
   69dd359..d07371b  master     -> origin/master
Updating 69dd359..d07371b
Fast-forward
 TODO | 1 +
 1 file changed, 1 insertion(+)
```

You can see the seam: the first two lines are the fetch, the last three are the merge.

Here is my opinion, stated as an opinion. **`git pull` is a convenience that hides which of two very different operations you just performed.** In the easy case — you have no local commits, the remote moved ahead — it fast-forwards and nothing can go wrong, and typing `git pull` is fine. In the interesting case — you have commits, they have commits — it performs either a merge (making a merge commit, keeping both histories) or a rebase (rewriting your commits on top of theirs). Those produce different history, and one of them rewrites commits you already made.

You should know which one is happening. `fetch`, then look, then choose, costs you five seconds and buys you a repository you understand. And on a day when something has gone strange, it is the difference between a puzzle and a panic.

### Divergent branches: the warning Git added on purpose

Let's make it interesting. We commit locally; meanwhile somebody else pushes. Both branches have moved. Now:

```console
git pull
```
```console
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint:
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
```

Git refuses to guess. This landed in Git 2.27 (2020) and it is one of the best changes the project ever made, because for fifteen years the default was a silent merge and the result was millions of accidental "Merge branch 'master' of ..." commits in histories everywhere.

The three answers:

* **`pull.ff only`** — only ever fast-forward. If the histories have diverged, do nothing and say so. This is the setting I recommend, and here is why: it never surprises you, and it turns an ambiguous situation into an explicit decision.
* **`pull.rebase true`** — replay my commits on top of theirs. Linear history, no merge commits. Very pleasant, and it rewrites your local commits, which is fine as long as they are local.
* **`pull.rebase false`** — merge. The historical default.

So, once, on your machine:

```console
git config --global pull.ff only
```

Now a diverged pull says this instead:

```console
git pull
```
```console
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

Nothing has happened to your repository, and Git has handed you the two commands to choose from. Which is what we wanted: a decision, not a default.

The choice itself, in two sentences: **merge** keeps a true record of what happened, including the fact that two lines of work existed in parallel, at the cost of a lumpier history; **rebase** produces a clean straight line that is easier to read and to bisect, at the cost of pretending events happened in an order they didn't, and of rewriting commits. The real discussion, including when rebasing is actively dangerous, is in [Implement an efficient collaborative workflow](5-git-workflow.md "Implement an efficient collaborative workflow").

Here we just take the linear one, for the pleasure of seeing it work:

```console
git pull --rebase
```
```console
Rebasing (1/1)Successfully rebased and updated refs/heads/master.
```

### Pull before push

Which gives us the habit, and it is the shortest rule in this course:

**Fetch before you push. Every time.**

Not because Git will let you break something — it won't, as we are about to see, it will refuse. But because a rejected push at the wrong moment (you're in a hurry, it's Friday, the release is waiting) is how people reach for `--force`. Two seconds of `git fetch` at the start removes the whole situation.

It is also simple politeness: integrating their work into yours, in your own repository, where a conflict is your problem to solve calmly, is nicer than making them integrate around you. More on the etiquette of this in [Implement an efficient collaborative workflow](5-git-workflow.md "Implement an efficient collaborative workflow").

## Push your code

```console
git push
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
   d0dcf58..2eaa6ce  master -> master
```

Read the last line right to left: the branch `master` here became the branch `master` there, which moved from `d0dcf58` to `2eaa6ce`.

### It's refspecs all the way down

`git push origin master` is shorthand. The full form is:

```console
git push origin refs/heads/master:refs/heads/master
```
```console
Everything up-to-date
```

Same command. Source on the left of the colon, destination on the right, exactly as in the `fetch` line in `.git/config`. "Take my `refs/heads/master` and make your `refs/heads/master` equal to it."

Once you see that, three things that look like arbitrary syntax become obvious:

* `git push origin my_local_name:their_different_name` pushes a branch under a different name. Occasionally very useful.
* `git push origin HEAD:refs/heads/master` pushes whatever you have checked out to their `master`, whether or not your branch is called that.
* And the famous one, which we'll get to in a moment: `git push origin :master` has an *empty source*. "Make your `master` equal to nothing." Which is to say, delete it.

A bare `git push` with no arguments uses `push.default`, whose value since Git 2.0 is `simple`: push the current branch to its configured upstream, and refuse if the upstream has a different name. That last clause is a safety feature — it exists so that you cannot accidentally push your `hotfix` onto their `master` because of a stale bit of config. Leave it alone.

If a branch has no upstream at all, Git stops and tells you exactly what to type:

```console
git push
```
```console
fatal: The current branch typo-fix has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin typo-fix

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.
```

So: `git push -u origin typo-fix` the first time (`-u` being `--set-upstream`), and plain `git push` after that:

```console
git push -u origin homepage
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 * [new branch]      homepage -> homepage
branch 'homepage' set up to track 'origin/homepage'.
```

Two things happened: a new branch appeared over there, and a `[branch "homepage"]` section appeared in our `.git/config`.

And if, like me, you find typing `-u` on every new branch tiresome, Git 2.37 added the hint above:

```console
git config --global push.autoSetupRemote true
```

Now a plain `git push` on a fresh branch does the sensible thing:

```console
git push
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 * [new branch]      typo-fix -> typo-fix
branch 'typo-fix' set up to track 'origin/typo-fix'.
```

### Deleting a remote branch

The modern spelling, which reads like English:

```console
git push origin --delete homepage
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 - [deleted]         homepage
```

And the older spelling, which you will meet in scripts and on Stack Overflow, and which does exactly the same thing:

```console
git push origin :homepage
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 - [deleted]         homepage
```

Nothing to memorise. It is a refspec with an empty source. Push *nothing* to `homepage`. Once you can read refspecs, the colon form stops being a magic incantation and becomes the more logical of the two.

> :information_source:
> Deleting the branch on the server does not delete your local branch, and vice versa. They are different things — that's the whole lesson of the previous chapter. `git branch -d homepage` handles the local one. Deleting the remote branch *does* remove your `origin/homepage` remote-tracking ref, and leaves other people's showing `[origin/homepage: gone]` until they `git fetch --prune`.

### Tags are not pushed. Really.

This one catches everybody exactly once, usually on release day. Let's watch it happen. We have an annotated tag `v1.0` sitting on a commit, we make another commit, and we push:

```console
git push
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
   a47856e..69dd359  master -> master
```

Push succeeded. So, what tags does the server have?

```console
git ls-remote --tags origin
```

Not a single line of output. No tags at all. Because look at the refspec again — `refs/heads/*` — and remember where tags live: `refs/tags/`. They were never in scope. A push sends branches. Tags are a separate errand:

```console
git push origin v1.0
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 * [new tag]         v1.0 -> v1.0
```

```console
git push --tags
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 * [new tag]         v0.9-wip -> v0.9-wip
```

`--tags` sends all of them, including the private scratch ones you never meant to publish. Better is `--follow-tags`, which sends only *annotated* tags that are reachable from the commits you are pushing:

```console
git push --follow-tags
```

That is almost always the behaviour you actually wanted, and `git config --global push.followTags true` makes it the default. Deleting a tag on the server is a refspec again: `git push origin --delete v0.9-wip`.

We have not properly introduced tags yet — that happens in [A little structure please](4-git-repo-structure.md "A little structure please"), along with why annotated ones are the ones that matter. For now: remember that `git push` does not send them.

## When the push is rejected

Good. Let's break it.

Somebody else pushed while we were working, and we push anyway:

```console
git push
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 ! [rejected]        master -> master (fetch first)
error: failed to push some refs to '/Users/oripekelman/projects/my_first_git_project.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

Is it a good time to panic? No. You should never panic. Nothing was lost, nothing was changed, on either side. Git looked at what we were asking for and declined.

Read the reason, because it is the whole thing: *the remote contains work that you do not have.* If Git had accepted our push, `refs/heads/master` on the server would now point at our commit — and their commit would no longer be reachable from any branch. It would still be sitting in `.git/objects` over there, technically, until garbage collection swept it up. From every practical point of view, we would have deleted a colleague's work by typing four characters.

So Git enforces one rule on pushes: **a push may only move a branch forward.** The new value must be a descendant of the old one. That is what "fast-forward" means, and a push that isn't one gets rejected.

Note the label: `(fetch first)`. Git is being precise. Our `origin/master` was stale, so Git couldn't even tell us what the shape of the problem was — go and look, it says. Let's do as we're told:

```console
git fetch
```
```console
From /Users/oripekelman/projects/my_first_git_project
   2eaa6ce..1b47e8c  master     -> origin/master
```
```console
git status
```
```console
On branch master
Your branch and 'origin/master' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
```

Now the picture is clear. One commit each, going different ways. And if we stubbornly push again, the label changes:

```console
git push
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 ! [rejected]        master -> master (non-fast-forward)
error: failed to push some refs to '/Users/oripekelman/projects/my_first_git_project.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

`(non-fast-forward)`: same refusal, but now Git has fresh information and can name the actual problem.

**The fix is to integrate, not to force.** Merge their commit into yours, or rebase yours on top of theirs, and then push. That is the normal, everyday, correct answer, and it is what the hint says.

### `--force` and `--force-with-lease`

Git will let you overrule it, two ways.

`git push --force` says: make the remote branch equal to mine, whatever that destroys. And it does exactly that.

`git push --force-with-lease` says something much more careful: make the remote branch equal to mine, **but only if the remote is still where I last saw it**. Git compares the server's current value against your remote-tracking ref — your "lease" — and if somebody has pushed since your last fetch, it refuses:

```console
git push --force-with-lease
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 ! [rejected]        master -> master (stale info)
error: failed to push some refs to '/Users/oripekelman/projects/my_first_git_project.git'
```

`(stale info)` — a third label, and a lovely one. It means "your information about my state is out of date, so I am not letting you overwrite anything based on it". Which is precisely the protection `--force` throws away.

The difference in practice: `--force` can destroy a commit that was pushed thirty seconds ago by somebody you have never met. `--force-with-lease` can only destroy commits you had already seen and accounted for. **If you must force, this is the one to use.** Some people alias it over `--force` so they cannot get it wrong, and that is a good idea.

> :warning:
> Force-pushing a shared branch is the one genuinely antisocial thing you can do with Git. Everyone who had the old commits now has a repository whose history disagrees with the server's; their next pull will do something baroque, and someone will spend an afternoon on it. `main`, `master`, `develop`, release branches, anything with more than one reader: **never**. Your own feature branch, that nobody else has checked out, after a rebase you meant to do: fine, and use `--force-with-lease`. If you have force-pushed something shared and want to undo it, [Keep a clean history, recover from mistakes](6-git-cleanup.md "Keep a clean history, recover from mistakes") is your chapter.

There is one other rejection worth recognising, and we produced it in the last chapter: `! [remote rejected] master -> master (branch is currently checked out)`, which means the other end is not a bare repository and Git is protecting its working tree.

## When Git won't let you in: authentication

Once you push to a real host instead of a directory, you will meet these. They are worth being able to read at a glance, because none of them says "your key is missing" in so many words.

**`Permission denied (publickey)`**

```console
git@github.com: Permission denied (publickey).
```

SSH. You reached the server — DNS worked, the port was open, the host answered — and it declined your keys. Either you have no key, or the key you have was never added to your account, or your SSH agent is offering a different one. Nothing to do with Git; test it directly:

```console
ssh -T git@github.com
```
```console
Hi OriPekelman! You've successfully authenticated, but GitHub does not provide shell access.
```

That is success. "Does not provide shell access" is not an error, it is GitHub being friendly. If instead you get `Permission denied (publickey)`, go to [Configure Git with an SSH key](../6-appendices/2-git-ssh.md "Configure Git with an SSH key") and start from the top.

**Password authentication is not supported**

```console
remote: Invalid username or token. Password authentication is not supported for Git operations.
fatal: Authentication failed for 'https://github.com/you/your-project.git/'
```

HTTPS to GitHub, with something that is not a valid token. Account passwords stopped working for Git in August 2021 — you may still find the older wording, "Support for password authentication was removed", quoted in blog posts and in your memory. Same cause, and the cure is the same: generate a personal access token (Settings → Developer settings → Personal access tokens) and use *that* where you were typing a password. Or switch the remote to SSH.

**HTTP Basic: Access denied**

```console
remote: HTTP Basic: Access denied. If a password was provided for Git authentication, the password was incorrect or you're required to use a token instead of a password. If a token was provided, it was either incorrect, expired, or improperly scoped.
fatal: Authentication failed for 'https://gitlab.com/you/your-project.git/'
```

GitLab's version of the same conversation, and note the useful extra word: **scoped**. GitLab tokens have scopes, and a token without `write_repository` will authenticate perfectly and then refuse to let you push. Expired is the other common one; tokens have end dates and they arrive quietly.

**`Repository not found` / `remote: Repository not found.`**

Looks like a typo, and sometimes is. But on GitHub a *private* repository you cannot see is reported as not existing, deliberately, so that nobody can enumerate private repositories. So this message means "no such repository, **or** you are not authenticated as someone allowed to see it". If you are certain of the URL, treat it as an authentication problem.

### Credential helpers, or: stop typing your token

Every HTTPS operation needs the token. You do not want to paste it forty times a day, and you *especially* do not want to put it in the URL where it lands in `.git/config` in plain text and gets copied into a screenshot.

A **credential helper** stores it in your operating system's keychain and hands it to Git on demand. One command, once:

```console
git config --global credential.helper osxkeychain
```

That is macOS, where the helper ships with Git. On Linux, `libsecret` (you may need to install `git-credential-libsecret`); on Windows, `manager`, which Git for Windows installs. The next time Git asks for your token, it asks once, and then never again.

And for GitHub specifically, the genuine path of least resistance:

```console
gh auth login
```

The `gh` command-line tool walks you through a browser login, then configures Git's credential helper for you and can upload an SSH key while it's at it. If you are on GitHub and fighting with authentication, stop fighting and run that.

> :information_source:
> There is a helper called `store`, which writes your token to `~/.git-credentials` in plain text. It works. Don't. And if you have already done it, that file is worth deleting and the token worth rotating.

## Summary `git clone` `git fetch` `git pull` `git push`

* `git clone` is five operations: `init`, add a remote called `origin`, fetch the objects, create the remote-tracking refs from the refspec, then create and check out **one** local branch tracking the remote's **HEAD**.
* `--branch <name>` starts you on another branch or a tag; `--single-branch` narrows the refspec to just that one; `--recurse-submodules` brings the submodules too.
* `--depth <n>` is a shallow clone, recorded in `.git/shallow`. It breaks `git log` archaeology, `git blame -C`, `git describe`, `git bisect` and some merges — fine for CI, bad for your working copy. `git fetch --unshallow` repairs it.
* `--filter=blob:none` is a partial clone: all the history, file contents fetched on demand (`promisor = true`). The modern answer to "the repo is too big". Add `--sparse` plus `git sparse-checkout add/set/disable` for a big *tree*.
* `--bare` is a server-shaped copy with **no fetch refspec**, so branches land in `refs/heads/`. `--mirror` is bare *plus* `fetch = +refs/*:refs/*` and `mirror = true` — an exact replica that pushes deletions back. Good for migrations, dangerous by design.
* `git fetch` downloads objects and updates remote-tracking refs. **It never touches your branches, your index or your working tree.**
* Look before integrating: `git log --oneline HEAD..origin/main`, `git log --stat`, `git diff HEAD origin/main`. `A..B` means "reachable from B but not from A".
* `git pull` = `git fetch` + `git merge` (or `+ git rebase`). It hides which of two very different things you did. Since Git 2.27 a divergent pull refuses to guess — *"fatal: Need to specify how to reconcile divergent branches."* Choose with `pull.rebase false` (merge), `pull.rebase true` (rebase), or `pull.ff only`, which is what we recommend. The merge-versus-rebase argument itself is in [Implement an efficient collaborative workflow](5-git-workflow.md "Implement an efficient collaborative workflow").
* `git push origin main` is shorthand for `git push origin refs/heads/main:refs/heads/main` — source colon destination, same as a fetch refspec. Which is why `git push origin :<branch>` deletes a branch, as does the clearer `git push origin --delete <branch>`.
* `git push -u origin <branch>` sets the **upstream** the first time; `push.autoSetupRemote = true` does it for you. `push.default = simple` (the default) pushes the current branch to its upstream and refuses if the names differ.
* **Tags are not pushed**, because the refspec only covers `refs/heads/*`. `git push origin v1.0` for one, `--tags` for all, `--follow-tags` (or `push.followTags = true`) for the annotated reachable ones — which is what you meant.
* A push may only move a branch **forward**: `! [rejected] ... (fetch first)` while your remote-tracking ref is stale, `(non-fast-forward)` once it isn't. Both mean the remote has commits you don't, and the fix is to fetch and integrate. `--force` overwrites regardless; `--force-with-lease` overwrites only if the remote is where you last saw it, otherwise `(stale info)`. If you must force, force with a lease — and never on a shared branch.
* Fetch before you push. Every time.
* `Permission denied (publickey)` — SSH key; test with `ssh -T git@github.com`. `Password authentication is not supported` / `HTTP Basic: Access denied` — you need a token, correctly scoped and unexpired. `Repository not found` may mean "not authorised".
* `git config --global credential.helper osxkeychain` (macOS) / `libsecret` (Linux) / `manager` (Windows) keeps the token in your keychain; `gh auth login` sets GitHub up for you. Never the `store` helper.
