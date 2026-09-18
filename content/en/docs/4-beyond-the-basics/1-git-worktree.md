---
title: One repository, many working trees
slug: "git-worktree"
weight: 31
---
# One repository, many working trees

Here is a situation you have already lived through.

You are three hours into a feature branch. Half the files are edited, some of them are staged and some are not, there is a `TODO half done` in a file you have not even named properly yet. Nothing compiles. And then production catches fire, and you need to look at `main` **right now**.

Or a gentler version: your test suite takes eleven minutes, you have just launched it, and you would quite like to review a colleague's pull request while it runs — without killing the run.

Or: you want to `git bisect` to find which of the last two hundred commits broke the login page. Bisecting means checking out twenty different commits, one after another, and your work-in-progress is very much in the way.

Up to now this course has given you two answers to all three, and both of them are bad.

## The two bad answers

**`git stash`.** We met it in [Collaborate with Git](../2-collaborating/1-collaborate-with-git.md "Collaborate with Git"). It works. It is also opaque: a stack of unnamed entries called `stash@{0}`, `stash@{1}`, `stash@{2}`, which after two days you can no longer tell apart. Pop the wrong one, or pop it onto the wrong branch, and you have a mess to untangle. And it forces you to keep switching one working directory back and forth — every switch touching files, invalidating your build cache, restarting your file watcher.

**A second `git clone`.** This also works, and people do it constantly. But now you have two object databases holding the same objects twice, two sets of remotes, two sets of branches that drift apart, two `.git/config` files, two sets of hooks. Commit something in clone A and clone B cannot see it until you push it somewhere. That last one turns out to matter enormously, and we will come back to it in [Worktrees and agents](2-git-worktree-agents.md "Worktrees and agents").

There is a third answer, `git worktree`. It is the right one, it has existed since Git 2.5 — released in **July 2015** — and almost nobody uses it.

## The mental model, first

Before we type anything, let's get the idea straight, because everything else follows from it.

A Git repository is two things bolted together.

1. **The history.** The object database (`.git/objects`: your **blob**s, **tree**s, **commit**s and **tag**s) plus the refs that name entry points into it (`.git/refs`, `packed-refs`). This is the part that matters. This is what you would cry about losing.
2. **One checkout.** A single **commit**, expanded into real files you can open in an editor, plus an **index** (`.git/index`) describing what is staged.

Part 1 of this course taught you exactly this. And now look at it again: there is no reason at all why there should be only *one* of (2).

A **worktree** is an additional checkout — its own directory of files, its own **HEAD**, its own **index** — backed by the *same* object database and the *same* refs.

One history. Many desks.

> :information_source:
> Vocabulary. The directory Git created when you ran `git init` or `git clone` is the **main worktree**. Anything you add later is a **linked worktree**. Git treats them almost identically; we will point out the handful of places where "almost" matters.

## Let's build one

A tiny repository to play in, so the output below is something you can reproduce — three commits, then the half-finished feature from the first paragraph:

```console
git init -b main shop
cd shop
printf '# Shop\n\nA tiny shop.\n' > readme.md
git add readme.md && git commit -m'Add readme'
mkdir -p lib views
printf 'function cart() { return []; }\n' > lib/cart.js
git add lib/cart.js && git commit -m'Add an empty shopping cart'
printf '<html><body>cart</body></html>\n' > views/cart.html
git add views/cart.html && git commit -m'Add the cart template'

git init --bare ../shop-origin.git          # a stand-in for a forge
git remote add origin ../shop-origin.git
git push -u origin main

git switch -c cart-discounts
printf 'function discount(p) { return p * 0.9; }\n' >> lib/cart.js
printf 'TODO half done\n' > lib/coupon.js
git add lib/coupon.js
```

```console
git status --short

 M lib/cart.js
A  lib/coupon.js
```

A dirty working tree, a partially staged **index**. Exactly the state you never want to be in when production burns.

> :information_source:
> In the output below I have shortened the absolute paths to `/home/ori/code/...`. Git always prints worktree paths in full, so yours will say wherever you actually are. Your **SHA**s will differ from mine too — they depend on the timestamps in your commits.

### `git worktree add`

```console
git worktree add ../feature-x

Preparing worktree (new branch 'feature-x')
HEAD is now at 4a188a9 Add the cart template
```

Read that first line carefully: **it created a branch**. With no other arguments, `git worktree add <path>` invents a new branch named after the last component of the path — here `feature-x` — starting from your current **HEAD**. That is a genuinely useful default, and also a small surprise the first time.

We now have a second directory next to `shop`, containing a full checkout, and our dirty `cart-discounts` work is completely untouched.

If you want to name the branch yourself, `-b` works exactly as it does for `git switch`:

```console
git worktree add ../hotfix -b hotfix/urgent

Preparing worktree (new branch 'hotfix/urgent')
HEAD is now at 4a188a9 Add the cart template
```

Give it a **commit**ish that is not a local branch and you get a **detached head**, which is precisely right for "I only want to look":

```console
git worktree add ../review origin/main
Preparing worktree (detached HEAD 4a188a9)
HEAD is now at 4a188a9 Add the cart template

git worktree add --detach ../inspect 5744dc5
Preparing worktree (detached HEAD 5744dc5)
HEAD is now at 5744dc5 Add an empty shopping cart
```

`--detach` is the explicit form: "no branch, thank you, just put commit `5744dc5` on disk".

One more pleasant default: name a branch that exists only on the **remote** and Git does the obvious thing.

```console
git worktree add ../rel release-1.0

Preparing worktree (new branch 'release-1.0')
branch 'release-1.0' set up to track 'origin/release-1.0'.
HEAD is now at 4a188a9 Add the cart template
```

A local branch, tracking `origin/release-1.0`. `--guess-remote` extends the trick to the directory name, so `git worktree add --guess-remote ../release-1.0` needs no branch argument at all.

### `git worktree list`

```console
git worktree list

/home/ori/code/shop       4a188a9 [cart-discounts]
/home/ori/code/feature-x  4a188a9 [feature-x]
/home/ori/code/hotfix     4a188a9 [hotfix/urgent]
/home/ori/code/inspect    5744dc5 (detached HEAD)
/home/ori/code/review     4a188a9 (detached HEAD)
```

Five desks, one history. The main worktree is always listed first.

And because you will eventually want to script this, there is a stable machine-readable form — records separated by blank lines, one `key value` per line:

```console
git worktree list --porcelain

worktree /home/ori/code/shop
HEAD 4a188a970657161edc4170d398922dedb34d0dfe
branch refs/heads/cart-discounts

worktree /home/ori/code/inspect
HEAD 5744dc5743e6c525869fd8f2231ab7635f7fac00
detached
```

We will parse this in the next chapter.

### There is only one repository

This is the part that makes worktrees worth learning. Walk into any of these directories and `git log`, `git branch` and `git tag` show you the *same* things, because there is one repository:

```console
cd ../feature-x
git branch -vv

+ cart-discounts 4a188a9 (/home/ori/code/shop) Add the cart template
* feature-x      4a188a9 Add the cart template
+ hotfix/urgent  4a188a9 (/home/ori/code/hotfix) Add the cart template
  main           4a188a9 [origin/main] Add the cart template
```

Look at that `+` in the first column, and the path in parentheses. `*` still means "checked out here". `+` means "checked out in *another* worktree, over there". `git branch` grew that notation for exactly this feature.

Even the **stash** is shared. Stash in `feature-x`:

```console
git stash push -m "from the feature-x worktree"
Saved working directory and index state On main: from the feature-x worktree
```

and list it from the main worktree:

```console
cd ../shop
git stash list
stash@{0}: On main: from the feature-x worktree
```

Which is either delightful or horrifying depending on what you expected. Keep it in mind; we will put it on a list in a moment.

## Opening the hood

Now the fun part. `cd` into the linked worktree and look at its `.git`:

```console
cd ../feature-x
file .git

.git: ASCII text
```

`.git` is **not a directory**. It is a small text file:

```console
cat .git

gitdir: /home/ori/code/shop/.git/worktrees/feature-x
```

That is the whole trick. One line, `gitdir:` followed by a path. This is the same **gitdir link** mechanism Git uses for submodules, and it says: "my administrative directory is over there."

So let's go over there.

```console
cd ../shop
tree -a .git/worktrees

.git/worktrees
├── feature-x
│   ├── commondir
│   ├── gitdir
│   ├── HEAD
│   ├── index
│   ├── logs
│   │   └── HEAD
│   ├── ORIG_HEAD
│   └── refs
└── hotfix
    └── ... the same eight entries
```

One directory per linked worktree, and inside each one, a handful of files you already know by name. Let's read them.

```console
cat .git/worktrees/feature-x/HEAD

ref: refs/heads/feature-x
```

There it is. A per-worktree **HEAD**, in exactly the format we dissected in [Playing with our revisions](../1-understanding-git/7-play-with-git-revisions.md "Playing with our revisions") — `ref: refs/heads/<branch>` when attached, a bare **SHA** when detached. All that time we spent staring at `.git/HEAD` was for this moment.

```console
cat .git/worktrees/feature-x/commondir

../..
```

`commondir` is the pointer back. Relative to `.git/worktrees/feature-x`, `../..` is `.git` — the shared part. That is how Git, having followed the `gitdir:` link into a per-worktree directory, finds its way back to the objects and refs.

```console
cat .git/worktrees/feature-x/gitdir

/home/ori/code/feature-x/.git
```

And `gitdir` is the *reverse* link: the path of the `.git` file that points here. The two files are a back-and-forth pair, and when one of them goes stale — because you moved a directory — things break in a way we will fix with `git worktree repair` below.

`index` is that worktree's own **index**, the staging area. `ORIG_HEAD` is its own "where I was before the last big move". And `logs/HEAD` is a reflog in exactly the format we read in [Collaborate with Git](../2-collaborating/1-collaborate-with-git.md "Collaborate with Git") — meaning **each worktree has its own HEAD reflog**, so `git reflog` in `feature-x` tells you what happened *in feature-x* and nothing else. The branch reflogs, `logs/refs/heads/*`, stay in the shared `.git` and are visible from everywhere.

### The one table you should remember

Every worktree bug you will ever hit comes from getting this wrong, so here it is explicitly.

**Per-worktree** (each worktree has its own):

* `HEAD`
* the **index**
* the working tree files themselves
* `ORIG_HEAD`
* all in-progress operation state: `MERGE_HEAD`, `MERGE_MSG`, `AUTO_MERGE`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`, `BISECT_LOG`, `rebase-merge/`, `rebase-apply/`
* `logs/HEAD` — the **HEAD** reflog
* `refs/bisect/*`
* `info/sparse-checkout`
* `config.worktree`, if `extensions.worktreeConfig` is on (see below)

**Shared** (there is exactly one, for the whole repository):

* the object database — every **blob**, **tree**, **commit**, **tag**
* `refs/heads/*` — all branches
* `refs/tags/*`, `refs/remotes/*`, `packed-refs`
* branch reflogs, `logs/refs/*`
* `.git/config`
* `hooks/`
* `info/exclude`
* **`refs/stash`** — yes, the stash is shared
* the `worktrees/` metadata itself

You do not have to memorise it, because Git will tell you. There is a plumbing command whose entire job is answering "where does this actually live?". Ask it, from inside `feature-x`:

```console
for p in HEAD index ORIG_HEAD logs/HEAD refs/heads/main refs/stash objects config hooks; do
  printf '%-18s %s\n' "$p" "$(git rev-parse --git-path $p)"
done

HEAD               /home/ori/code/shop/.git/worktrees/feature-x/HEAD
index              /home/ori/code/shop/.git/worktrees/feature-x/index
ORIG_HEAD          /home/ori/code/shop/.git/worktrees/feature-x/ORIG_HEAD
logs/HEAD          /home/ori/code/shop/.git/worktrees/feature-x/logs/HEAD
refs/heads/main    /home/ori/code/shop/.git/refs/heads/main
refs/stash         /home/ori/code/shop/.git/refs/stash
objects            /home/ori/code/shop/.git/objects
config             /home/ori/code/shop/.git/config
hooks              /home/ori/code/shop/.git/hooks
```

Per-worktree paths land in `worktrees/feature-x/`, shared paths land in `.git/`. `--git-path` is the correct way for any script or hook to find a file under `.git`, and we are about to see what happens to scripts that do not use it.

### Three flavours of "the git directory"

In the main worktree, three questions get two boring answers — `git rev-parse --git-dir` and `--git-common-dir` both say `.git`, and `--show-toplevel` says `/home/ori/code/shop`. In a linked worktree they come apart:

```console
cd ../feature-x
git rev-parse --git-dir            # /home/ori/code/shop/.git/worktrees/feature-x
git rev-parse --git-common-dir     # /home/ori/code/shop/.git
git rev-parse --show-toplevel      # /home/ori/code/feature-x
```

* `--git-dir` — *my* administrative directory. Per-worktree things live here.
* `--git-common-dir` — the shared one. Objects, refs, config live here.
* `--show-toplevel` — the root of *my* files.

> :warning:
> This is the single most common real-world worktree bug, and it is not in Git — it is in everybody's shell scripts.
>
> ```console
> "$(git rev-parse --show-toplevel)/.git/hooks/pre-commit"
> ```
>
> In a linked worktree that path is a **file**, not a directory, so the script fails with something like `Not a directory`. Tools that write to `$(git rev-parse --show-toplevel)/.git/something` are broken inside worktrees. The fix is always the same: use `git rev-parse --git-path <name>` and let Git decide, or `--git-common-dir` when you specifically want the shared side.

### Hooks are shared, and they know it

Put this in `.git/hooks/pre-commit` in the main worktree:

```console
#!/bin/sh
echo "hook: pwd        = $(pwd)"
echo "hook: git-dir    = $(git rev-parse --git-dir)"
echo "hook: common-dir = $(git rev-parse --git-common-dir)"
```

Now commit in `feature-x`. There is no `hooks/` directory under `worktrees/feature-x`, and yet:

```console
hook: pwd        = /home/ori/code/feature-x
hook: git-dir    = /home/ori/code/shop/.git/worktrees/feature-x
hook: common-dir = /home/ori/code/shop/.git
```

The same hook file ran, with the working directory set to *this* worktree. Which is what you want — but it means a hook that hardcodes a path, caches something in the main worktree, or assumes it is alone, will misbehave once you have four worktrees. Hooks that write state should write it under `git rev-parse --git-path`.

### In-progress operations really are private

Let's start a merge in `feature-x` that we know will conflict, and see what appears in its administrative directory:

```console
cd ../feature-x
git merge hotfix/urgent
Auto-merging lib/cart.js
CONFLICT (content): Merge conflict in lib/cart.js
Automatic merge failed; fix conflicts and then commit the result.

ls -a ../shop/.git/worktrees/feature-x
AUTO_MERGE  COMMIT_EDITMSG  commondir  gitdir  HEAD
index  logs  MERGE_HEAD  MERGE_MODE  MERGE_MSG  ORIG_HEAD  refs
```

And meanwhile, in the main worktree, `git status` says `On branch cart-discounts` and not one word about a merge. `feature-x` is stuck mid-conflict and `shop` neither knows nor cares. The same is true of a rebase, a cherry-pick, a revert, and a bisect — each worktree can be in the middle of its own operation. Even the bisect refs are private:

```console
git worktree add --detach ../bisect main
cd ../bisect
git bisect start && git bisect bad main && git bisect good f4eae73
git for-each-ref 'refs/bisect/*'

4a188a9... commit	refs/bisect/bad
f4eae73... commit	refs/bisect/good-f4eae73ba6a117b58ad81c2a49a01bce351ea215
```

From the main worktree the same `git for-each-ref` prints nothing. A dedicated bisect worktree is one of the nicest uses of the whole feature: you get to bisect for half an hour without ever disturbing your actual work.

### Per-worktree configuration

Config is shared. Usually that is right — you want one set of remotes. Occasionally it is not: a different `user.email` for a client's repository, a different sparse-checkout, a different `core.editor`.

There is an opt-in for that. Try it cold and Git refuses, then relents:

```console
git config --worktree user.email bot@example.com
fatal: --worktree cannot be used with multiple working trees unless the config
extension worktreeConfig is enabled. Please read "CONFIGURATION FILE"
section in "git help worktree" for details

git config extensions.worktreeConfig true
git config --worktree user.email bot@example.com
```

Now each worktree can override. Set `agent-a@example.com` in `feature-x` and you get three different answers to `git config --get user.email`: `agent-a@example.com` there, `bot@example.com` in the main worktree, and — from `hotfix`, which set nothing — the value from your global config. `git config --list --show-origin` tells you which file won:

```console
file:/home/ori/.gitconfig	user.email=ori+git-training@pekelman.com
file:/home/ori/code/shop/.git/worktrees/feature-x/config.worktree	user.email=agent-a@example.com
```

The main worktree's overrides live in `.git/config.worktree`; a linked worktree's live in `.git/worktrees/<name>/config.worktree`.

> :information_source:
> You may find `extensions.worktreeConfig` already switched on without having done it yourself. `git sparse-checkout` inside a linked worktree enables it for you, because sparse-checkout settings are inherently per-worktree. If you see a `config.worktree` you did not create, that is usually why.

## Housekeeping

### `git worktree remove`

`git worktree remove ../review` is the polite way. Silence means success: the directory is gone and the administrative files with it. Note that the *branch* survives — removing a worktree is not deleting work.

It will protect you from yourself, and it will not let you shoot the one you are sitting on:

```console
git worktree remove ../inspect
fatal: '../inspect' contains modified or untracked files, use --force to delete it

git worktree remove .
fatal: '.' is a main working tree
```

`--force` does the first one anyway, and you lose those files for good.

### `git worktree prune`

Now the thing you will actually do, because you are a normal human being: delete the directory with `rm -rf` and forget.

```console
rm -rf ../feature-x
git worktree list

/home/ori/code/shop       4a188a9 [cart-discounts]
/home/ori/code/feature-x  4a188a9 [feature-x] prunable
/home/ori/code/hotfix     4a188a9 [hotfix/urgent]
```

Git noticed, and says `prunable`. `--porcelain` adds a line telling you why: `prunable gitdir file points to non-existent location`. The administrative directory is still sitting under `.git/worktrees`. Sweep it up:

```console
git worktree prune -v

Removing worktrees/feature-x: gitdir file points to non-existent location
```

`-n` is a dry run, `-v` verbose. `--expire <time>` only prunes entries older than a given age, which is handy in a cron job.

Stale worktree entries are mostly harmless, with one real consequence: as long as the entry exists, its `HEAD` and reflog keep objects reachable, so `git gc` cannot collect them. A repository full of forgotten worktrees never shrinks. We will come back to that in the next chapter, where forgotten worktrees are the norm.

### `git worktree lock` and `unlock`

Some worktrees live on removable media or a network mount. When the mount is absent, Git sees a missing directory and cheerfully offers to prune the metadata. `lock` says don't — and stores your reason, which it reads back to you when you try anyway:

```console
git worktree lock --reason "on a USB drive that is not always plugged in" ../hotfix
git worktree remove ../hotfix

fatal: cannot remove a locked working tree, lock reason: on a USB drive that is not always plugged in
use 'remove -f -f' to override or unlock first
```

`git worktree list` shows such a worktree as `locked`, and `git worktree unlock ../hotfix` releases it.

### `git worktree move`

```console
git worktree move ../feature-x ../feat-x
```

It moves the files *and* fixes both halves of the `gitdir:` link pair, which is exactly what `mv` does not do.

### `git worktree repair`

And now the command you will need on a Tuesday afternoon, because you moved a directory in Finder or with `mv` like a normal person.

Move a linked worktree by hand and the damage is subtle. From inside it, everything still works — its `.git` file points at a valid administrative directory. But the `gitdir` file in the *other* direction is now wrong, so the main repository has quietly written the worktree off:

```console
mv ../feat-x ../moved-by-hand
git worktree list

/home/ori/code/shop    4a188a9 [cart-discounts]
/home/ori/code/feat-x  4a188a9 [feature-x] prunable
```

`prunable` — meaning the next `git worktree prune` will throw away the metadata of a worktree that still exists. Run `repair` from inside the moved directory:

```console
cd ../moved-by-hand
git worktree repair

repair: gitdir incorrect: /home/ori/code/shop/.git/worktrees/feature-x/gitdir
```

The other direction is louder. Move the *main* repository and every linked worktree's `.git` file now points into thin air:

```console
mv shop shop-renamed
cd moved-by-hand
git status

fatal: not a git repository: /home/ori/code/shop/.git/worktrees/feature-x
```

Nothing is lost — it is one text file per worktree that is wrong. Run `repair` from the main repository, naming the worktrees:

```console
cd ../shop-renamed
git worktree repair ../moved-by-hand ../hotfix

repair: .git file broken: /home/ori/code/hotfix
repair: .git file broken: /home/ori/code/moved-by-hand
```

> :information_source:
> Rule of thumb: after moving *worktrees*, run `git worktree repair` from anywhere in the repository. After moving the *main repository*, run `git worktree repair <path>...` from the main repository, listing the worktrees. Or, of course, use `git worktree move` and never think about it.

## The rules, and the traps

### You cannot check out the same branch twice

```console
cd ../hotfix
git switch feature-x
fatal: 'feature-x' is already used by worktree at '/home/ori/code/feature-x'

git worktree add ../another feature-x
Preparing worktree (checking out 'feature-x')
fatal: 'feature-x' is already used by worktree at '/home/ori/code/feature-x'
```

This is not Git being fussy. Think about what a branch *is*: a ref that moves to your latest **commit**. Two worktrees on one branch means two working trees and two indexes with one shared answer to "what is committed here". Commit in one, and the other silently finds its **HEAD** has moved under its feet and its whole working tree now reads as a giant uncommitted diff. Git refuses because the situation has no sensible meaning.

There is an escape hatch:

```console
git worktree add --force ../another feature-x

Preparing worktree (checking out 'feature-x')
HEAD is now at 4a188a9 Add the cart template
```

You almost never want it. If what you actually want is "the same code in two places", detach: `git worktree add --detach ../another feature-x` gives you the same **commit** with no ref to fight over. That is safe, and it is the right answer for "run the tests against exactly this state".

### Branch deletion is blocked too

```console
git branch -d feature-x

error: cannot delete branch 'feature-x' used by worktree at '/home/ori/code/feature-x'
```

`-D` does not help — this is not about unmerged work, it is about the branch being in use. Remove the worktree first, then delete the branch. In that order, always. It bites people writing cleanup scripts, which is why the cleanup script in the next chapter does it in that order.

### Two smaller ones about paths

A non-empty existing directory is refused (an empty one is fine, Git will use it):

```console
git worktree add ../occupied -b occupied

Preparing worktree (new branch 'occupied')
fatal: '../occupied' already exists
```

And relative paths are resolved against *your shell*, not the repository root. From `lib/deep`, `git worktree add ../../../rel-test` lands three levels up from `lib/deep`. Obvious once said, and a reliable source of worktrees appearing in surprising places. In scripts, compute an absolute path.

### The untracked files are not there

This is the big one. The single biggest source of friction with worktrees, and the reason people try them once and go back to `git stash`.

A new worktree contains **exactly what is committed**. Nothing else. So it does not have:

* `.env`, `.env.local`, and every other secret-bearing file you correctly gitignored
* `node_modules/`, `vendor/`, `venv/`, `.venv/`
* `target/`, `build/`, `dist/`, `.next/`, `__pycache__/`
* your local SQLite file, your uploaded test fixtures, your `docker-compose.override.yml`
* every build cache that makes your project's second compile fast

So you `cd` into your shiny new worktree, run the tests, and everything explodes. That is not a bug, it is the definition of a clean checkout, and it is the same thing that would happen to a fresh `git clone`.

Three ways to deal with it, in increasing order of virtue.

**Symlink the shared bits.** For files that genuinely should be identical everywhere:

```console
ln -s ../shop/.env .env
```

Cheap, instant, and it means editing the secret once. Works badly for directories that tooling wants to write into.

**Share the caches, rebuild the rest.** Most language toolchains let you move the expensive part outside the worktree, which turns "rebuild everything" into "link everything":

* Rust: `export CARGO_TARGET_DIR=$HOME/.cache/cargo-target` — one shared build directory for every worktree. This one is transformative; without it every worktree pays a full cold build.
* Node: `pnpm` already keeps a global content-addressed store, so `pnpm install` in a new worktree is mostly hardlinks. With npm, `npm ci` per worktree and let the HTTP cache do the work.
* Python: `uv sync` per worktree with a shared `UV_CACHE_DIR`. Do *not* symlink a virtualenv between worktrees — the paths baked into its scripts will lie to you.
* C/C++: `ccache`, which is designed for exactly this.
* Docker Compose: set `COMPOSE_PROJECT_NAME` per worktree, or the second worktree will adopt the first one's containers.

**Write a bootstrap script.** Put a `setup-worktree.sh` in the repository that links what must be linked and installs what must be installed, and run it as the second command after `git worktree add`. `direnv` is a good companion here: a `.envrc` per worktree, loaded automatically when you `cd` in, exporting a per-worktree database name and port.

> :information_source:
> Here is the hidden benefit, and I mean it seriously. A project where creating a worktree is cheap is a project where onboarding a new developer is cheap, because they are the same problem: "given nothing but the committed source, get to a working state". If your worktrees are painful, your `README` is lying to somebody. Fixing one fixes the other.

### Big repositories: `--no-checkout` and sparse-checkout

If your repository is enormous, N full checkouts is not free. `--no-checkout` creates the worktree with the administrative files but leaves the files out:

```console
git worktree add --no-checkout ../empty -b sparse-experiment
ls -a ../empty

.  ..  .git
```

The index says the files should be there, so `git status` reports them all as deleted. Now narrow the checkout to the part you care about and populate only that:

```console
cd ../empty
git sparse-checkout init --cone
git sparse-checkout set lib
git checkout
ls

lib  readme.md
```

Only `lib` and the root files came out. Because `info/sparse-checkout` is per-worktree, each worktree can hold a different slice of a monorepo — which is a rather lovely thing to be able to do.

### Tooling costs money

The disk arithmetic is friendly. The history is shared, so N worktrees cost roughly **N × working tree**, not N × repository:

```console
du -sh .git ../feature-x

324K	/home/ori/code/shop/.git
 16K	/home/ori/code/feature-x
```

The RAM arithmetic is not friendly. Your editor will happily start a language server per worktree, and a `rust-analyzer` or a TypeScript server is not a small process. File watchers scale the same way. And some tools cache by absolute path, so opening the same file at two paths gives you two entries in the index and, occasionally, two conflicting opinions about it.

None of this is a reason not to use worktrees. It is a reason to close the ones you are finished with.

## The bare repository layout

`git worktree add` also works in a **bare** repository, and this has become a small movement. Instead of one checkout with worktrees hanging off it, you keep only the history in the middle and *every* branch is a worktree:

```console
git clone --bare git@example.com:you/shop.git shop.git
cd shop.git
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git fetch origin
git worktree add ../main main
git worktree add ../feature-y -b feature-y main
```

You end up with `shop.git` holding the history and a sibling directory per branch:

```console
git worktree list

/home/ori/bare/shop.git   (bare)
/home/ori/bare/feature-y  4a188a9 [feature-y]
/home/ori/bare/main       4a188a9 [main]
```

Why people like it: there is no privileged "real" checkout, so no temptation to work in it and no asymmetry to remember. `main` is a worktree like any other, and you delete it as casually as the rest. The bare repository is pure history — which, as we established at the top of this chapter, is the only part that matters.

> :warning:
> `git clone --bare` does *not* set up a fetch refspec, so a bare clone has no remote-tracking branches at all. That is why the `git config remote.origin.fetch` line above is not optional. Refspecs were covered in the remotes chapters; this is the one place you have to remember them by hand.

## So when is a worktree the right tool?

**vs `git stash`** — Worktrees win whenever the interruption lasts more than a minute or two. Nothing to remember, nothing to pop, and your original desk is exactly as you left it, build cache and all. Stash is still fine for "hold this for thirty seconds".

**vs a second clone** — Worktrees win nearly always. One object store, one set of remotes, one config, one set of hooks. And the decisive one: commits made in any worktree are *immediately* visible from every other, with no push and no fetch, because there is one refs directory. `git diff feature-x hotfix/urgent` just works. Separate clones cannot do that at all.

**vs `git switch`** — Switching is right when you are *moving on*. A worktree is right when you want both things *at once*: two branches open, two servers running, tests on one while you edit the other.

**And the honest note.** For a quick peek at one file, all of the above is overkill:

```console
git show main:readme.md
```

prints that file at that **commit** without touching anything. `git restore --source=main -- path/to/file` pulls one file across without changing branches. If your question is small, ask it with a small command.

## Recipes

### Add and `cd` in one go

`git worktree add` cannot change your shell's directory — no program can. A shell function can:

```console
wt() {
  local common root name start dir
  common=$(git rev-parse --path-format=absolute --git-common-dir) || return 1
  root=${common%/.git}                     # normal repo: strip the trailing /.git
  name=${1//\//-}                          # feature/foo -> feature-foo
  start=${2:-$(git rev-parse HEAD)}        # resolve HEAD *here*, before -C
  dir="${root%/*}/${root##*/}-$name"       # a sibling of the main worktree
  if git show-ref --verify --quiet "refs/heads/$1"; then
    git -C "$root" worktree add "$dir" "$1" || return 1
  else
    git -C "$root" worktree add "$dir" -b "$1" "$start" || return 1
  fi
  cd "$dir" || return 1
}
```

`wt bug/parser` from anywhere in the repository creates `../shop-bug-parser` on a new branch `bug/parser` and drops you in it. Works in bash and zsh. Note the `start=${2:-$(git rev-parse HEAD)}` — resolving **HEAD** *before* handing control to `git -C`, because `git -C "$root"` would resolve `HEAD` in the main worktree, not where you are standing.

### Test `main` while you work

```console
git worktree add --detach ../ci main
cd ../ci && ./run-tests.sh
```

`--detach`, so it does not claim the `main` branch and you can still merge into it from your main worktree.

### Review a pull request

Configure the refspec once — most forges publish PR heads under `refs/pull/*`:

```console
git config --add remote.origin.fetch '+refs/pull/*/head:refs/remotes/origin/pull/*'
git fetch origin

From ../shop-origin
 * [new ref]         refs/pull/7/head -> origin/pull/7
```

Then a disposable worktree per review:

```console
git worktree add ../pr-7 origin/pull/7

Preparing worktree (detached HEAD 4a188a9)
```

Read it, run it, `git worktree remove ../pr-7`. If you use a forge CLI (`gh`, `glab`, `tea`), run its checkout command *inside* a fresh worktree instead of in your working directory, and the same property holds: your own work is never disturbed.

### A permanently checked-out docs branch

If you publish from a `gh-pages`-style branch, stop switching to it:

```console
git worktree add ../shop-pages gh-pages
```

Build into `../shop-pages`, commit there, push. The branch is always ready and your source checkout never sees its files. Same trick for a bisect worktree, which we met above: `git worktree add --detach ../bisect main` and twenty checkouts, none of them yours.

## Summary `git worktree`

* A repository is a shared **history** (objects + refs) plus a checkout. Worktrees give you many checkouts over one history.
* `git worktree add <path>` creates a linked worktree, and a branch named after the directory. `-b <name>` names it yourself; a **commit**ish or `--detach` gives you a **detached head**; `--no-checkout` gives you the metadata without the files.
* `git worktree list` shows them all; `--porcelain` is the scriptable form and flags `prunable` entries.
* `git worktree remove` deletes one (refuses when dirty, `--force` insists); `git worktree prune` cleans up after `rm -rf`; `lock`/`unlock` protect worktrees on removable media; `move` relocates one safely; `repair` fixes the `gitdir:` links after you moved something by hand.
* In a linked worktree `.git` is a **file** containing `gitdir: <path>`, pointing at `.git/worktrees/<name>/`, which contains that worktree's own `HEAD`, `index`, `ORIG_HEAD`, `logs/HEAD`, in-progress operation state, and a `commondir` pointing back at the shared `.git`.
* Per-worktree: **HEAD**, **index**, files, `ORIG_HEAD`, merge/rebase/cherry-pick/bisect state, the **HEAD** reflog, `refs/bisect/*`, sparse-checkout, `config.worktree`. Shared: objects, all refs including branches, tags, remote-tracking refs and the **stash**, config, hooks, `info/exclude`.
* `git rev-parse --git-dir` is *this* worktree's admin directory; `--git-common-dir` is the shared one; `--show-toplevel` is *this* worktree's root. `git rev-parse --git-path <name>` resolves any file correctly. Scripts that assume `$(git rev-parse --show-toplevel)/.git` is a directory break inside worktrees.
* `extensions.worktreeConfig` plus `git config --worktree` gives per-worktree configuration in `config.worktree`.
* One branch cannot be checked out in two worktrees, and a branch in use cannot be deleted. Remove the worktree first, then the branch.
* New worktrees have no untracked files — no `.env`, no `node_modules`, no build cache. Symlinks, shared caches (`CARGO_TARGET_DIR`, `UV_CACHE_DIR`, `ccache`), `direnv` and a `setup-worktree.sh` are the fix.
* Disk cost is roughly N × working tree, not N × repository. RAM cost is N language servers, which is the real limit.

Everything in this chapter has been available since 2015 and is, by Git standards, thoroughly boring. What is not boring is what happens when the thing sitting at each of those desks is not you.

Which is [Worktrees and agents, parallel work at machine speed](2-git-worktree-agents.md "Worktrees and agents, parallel work at machine speed").
