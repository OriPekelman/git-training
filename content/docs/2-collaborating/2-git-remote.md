---
title: Working with remote repositories
url: "/docs/git-remote/"
weight: 12
---
# Working with remote repositories

Everything we have done so far happened on our own disk. We created **blob**s, **tree**s and **commit**s, we moved **HEAD** around, we made branches and merged one into another — and not a single byte left our machine.

That is worth pausing on, because it is the thing that makes Git different from the version control systems that came before it. Git does not need a server to work. A repository is complete. The history is *ours*.

But we do want to work with others. Or with ourselves on another machine. Or simply to have a copy somewhere that survives a coffee spill. So we need to teach our repository about somewhere else.

That somewhere else is called a **remote**.

## What is a `remote`?

Here is the whole secret, and it is a disappointment: a **remote** is a *name for a URL*, written down in a text file.

That's it. No daemon, no session, no magic. Let's prove it. We are back in our project:

```console
cd ~/projects/my_first_git_project
```

Let's look at the configuration file of our repository, which lives in the `.git` directory we have been exploring since the beginning:

```console
cat .git/config
```

```console
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
	ignorecase = true
	precomposeunicode = true
```

> :information_source:
> On Linux you will see two lines fewer: `ignorecase` and `precomposeunicode` are there because macOS has a filesystem with opinions about capital letters and accented characters. We'll come back to `ignorecase` when we talk about branch names, because it can genuinely hurt you.

Now, we need something to be a remote. And here is the first good news of this chapter: **a directory on your own disk is a perfectly good remote**. We do not need an account anywhere, we do not need a network, we do not need a key. We will use this trick for the whole chapter, because it means you can follow along and *experiment* — break things, delete things, start over — without asking anyone's permission.

We are going to create the "server" side properly in a moment. For now let's just declare it:

```console
git remote add origin ~/projects/my_first_git_project.git
```

Git says nothing at all, which as we have learned is Git's way of saying "fine". Let's look at our config file again. The `[core]` section is unchanged; at the bottom, three new lines:

```console
cat .git/config
```

```console
{..}
[remote "origin"]
	url = /Users/oripekelman/projects/my_first_git_project.git
	fetch = +refs/heads/*:refs/remotes/origin/*
```

A section header, a URL, and one very cryptic line. Let's take them one at a time.

`[remote "origin"]` — we have created a remote and we called it `origin`. The name is ours to choose.

`url = /Users/oripekelman/projects/my_first_git_project.git` — the address. Note that the shell expanded our `~` into the real path before Git ever saw it; yours will show your own home directory.

And then that third line, which is the reason this chapter exists.

### The **refspec**, or: the most useful ten minutes of your Git career

```console
	fetch = +refs/heads/*:refs/remotes/origin/*
```

This is a **refspec**. It is a mapping. It says: *when you fetch from this remote, take the references it has and write them here*.

Read it as three parts separated by a colon and a leading sign:

* `+` — "force". Overwrite the destination even if the new value is not a descendant of the old one. Remote-tracking refs are a cache, so we always want the latest truth, even if the truth moved sideways.
* `refs/heads/*` — the **source**. This pattern is evaluated *on the remote*. `refs/heads/` is where branches live — remember `.git/refs/heads/master` from the branches chapter. So: "all of their branches".
* `refs/remotes/origin/*` — the **destination**, evaluated *locally*. So: "write each one under `refs/remotes/origin/`, keeping its name".

So the branch called `master` on the server becomes, locally, a reference called `refs/remotes/origin/master`. Which we usually write `origin/master`.

That is the whole of it. Every time you see something like `origin/main`, you are looking at a local file whose path was computed by that one line of config.

> :information_source:
> **Refspec**s show up everywhere once you can see them: in `git fetch`, in `git push`, in `git ls-remote`, in the config of every CI system you will ever debug. Almost every confusing thing about remotes turns out to be a refspec you didn't know was there. We will use them again, deliberately, in the next chapter.

### Looking at our remotes

Three commands, in increasing order of chattiness. Bare `git remote` prints just the names, one per line — `origin`. Add `-v` for "verbose" and you get the URLs:

```console
git remote -v
```
```console
origin	/Users/oripekelman/projects/my_first_git_project.git (fetch)
origin	/Users/oripekelman/projects/my_first_git_project.git (push)
```

Two lines, because a remote can have a different URL for reading and for writing. Ours are the same, which is the normal case.

And then the interesting one, which actually *talks* to the remote to find out what it has (this output is from a little later in the chapter, once we have pushed something — right now the remote does not even exist yet):

```console
git remote show origin
```
```console
* remote origin
  Fetch URL: /Users/oripekelman/projects/my_first_git_project.git
  Push  URL: /Users/oripekelman/projects/my_first_git_project.git
  HEAD branch: master
  Remote branches:
    master        tracked
    shopping_cart tracked
  Local branch configured for 'git pull':
    master merges with remote master
  Local refs configured for 'git push':
    master        pushes to master        (up to date)
    shopping_cart pushes to shopping_cart (up to date)
```

If you want the raw, unadorned truth of what a remote holds, there is a lower-level command, and it is a wonderful debugging tool:

```console
git ls-remote origin
```
```console
69dd359f129c6211173f3ac934c17b461d27d187	HEAD
69dd359f129c6211173f3ac934c17b461d27d187	refs/heads/master
1213fc5f325573870748535e5d457573a9c80b50	refs/heads/shopping_cart
75fff39cacc4f49bc16fe5d3d798cdeb393ed8a5	refs/tags/v1.0
a47856e41c9e5f275068920884c735276b97f1f6	refs/tags/v1.0^{}
```

References and the **SHA**s they point at. Nothing else. This is what the server would tell us if we asked politely. When someone says "but it *is* pushed, I swear", this is the command that settles the argument.

### Managing remotes

The rest of the `git remote` family just edits that config block for you.

```console
git remote rename upstream mirror
git remote set-url mirror git@github.com:you/my_first_git_project.git
git remote remove mirror
```

`rename` is not purely cosmetic: it also renames all the remote-tracking references, moving `refs/remotes/upstream/*` to `refs/remotes/mirror/*`, and it rewrites the refspec to match. `set-url` changes only the URL — useful when a project moves host, or when you decide to switch from HTTPS to SSH. `remove` deletes the config section *and* all the remote-tracking refs that belonged to it.

You could do all three by editing `.git/config` in your text editor, and nothing bad would happen. Sometimes that is genuinely the fastest way. But `git remote` cleans up the refs for you, so prefer it.

### `origin` is a convention, not a keyword

I want to be very clear about this, because it confuses people for years: **there is nothing special about the name `origin`.**

It is not reserved. It is not privileged. Git does not treat it differently from a remote called `bob`. It is simply the name that `git clone` uses by default, and therefore the name everybody has. You could rename it to `home` this afternoon and everything would keep working, as long as you typed `home` where you used to type `origin`.

And you are not limited to one. Having several remotes is completely normal, and the classic case is contributing to somebody else's project:

* `origin` — *your* copy of the project, the one you can write to.
* `upstream` — the original project, which you can read but not write.

Let's actually build that, because it takes ten seconds with directories. We'll pretend `theproject.git` belongs to somebody famous, `my-fork.git` is our copy of it, and `work` is where we type:

```console
cd ~/projects/work
git remote add upstream ~/projects/theproject.git
git fetch upstream
```
```console
From /Users/oripekelman/projects/theproject
 * [new branch]      master     -> upstream/master
```

And now look at what happened under the hood:

```console
tree .git/refs
```
```console
.git/refs
├── heads
│   └── master
├── remotes
│   ├── origin
│   │   └── HEAD
│   └── upstream
│       ├── HEAD
│       └── master
└── tags
```

Two namespaces, side by side, one directory each — because each remote brought its own refspec, and `git remote add upstream` wrote `fetch = +refs/heads/*:refs/remotes/upstream/*` into the config. Same pattern, different destination.

Now `git diff master upstream/master` is a sentence you can say. That is the whole trick of contributing to open source, and we have not left the local disk.

## How Git talks to a remote: the transports

The URL tells Git not only *where* but *how*. There are four families and you will meet three of them.

**A filesystem path.** `/Users/oripekelman/projects/my_first_git_project.git`, or `~/projects/whatever.git`, or `../other-repo`. Git just reads and writes files. This works on a mounted network drive too. It is also, and this is the point I keep making, the ideal way to *learn*, because there is no authentication to get wrong and you can look at both sides.

There is a variant, `file:///Users/oripekelman/projects/my_first_git_project.git`, which looks like the same thing but is not: with a plain path Git takes shortcuts (it will even hard-link object files instead of copying them), whereas with `file://` it pretends to be a real network transport and speaks the full protocol. We will need that distinction in the next chapter.

**SSH.** The full form is `ssh://git@example.com/~you/project.git`, but almost nobody writes it. What everybody writes is the scp-like shorthand:

```console
git@github.com:you/project.git
```

Note the **colon** between the host and the path — that is what tells Git this is SSH and not a filesystem path with a funny name. Authentication is by key pair, and once it works you never think about it again. Setting it up is a chapter of its own: [Configure Git with an SSH key](../6-appendices/2-git-ssh.md "Configure Git with an SSH key").

**HTTPS.** `https://github.com/you/project.git`. Its great virtue is that it goes through absolutely every corporate firewall and proxy on earth, because it looks like web traffic, which it is. Its cost is credentials: a username and a **token**.

> :warning:
> Not a password. A token. GitHub stopped accepting account passwords for Git operations in August 2021, and the other big hosts have followed. If you type your login password into an HTTPS Git prompt in 2026, it will fail, and the error message will not necessarily make it obvious why. We will look at the exact messages in the [next chapter](3-git-clone-pull-remote.md "Retrieve and send code").

**And `git://`.** The old Git-native protocol, port 9418. It is fast, it is anonymous, it has no encryption and no authentication whatsoever, which means anybody between you and the server can quietly change the code you are downloading. GitHub turned it off for good on 15 March 2022 and you should treat any `git://` URL you find in an old README as a bug. Mentioned here only so you recognise it.

**HTTPS or SSH, then?** Honestly: SSH if you can, HTTPS if the network won't let you. SSH is nicer once configured and never expires. HTTPS needs a token and a **credential helper** so you are not pasting it forty times a day. Both are secure. Neither choice is permanent — remember `git remote set-url`.

## A repository with no working tree: the **bare** repository

We declared a remote pointing at `~/projects/my_first_git_project.git`, and that directory does not exist yet. Let's create it, and while we do, ask an obvious question that most people never ask: *what does a Git server actually store?*

```console
cd ~/projects
git init --bare my_first_git_project.git
```
```console
Initialized empty Git repository in /Users/oripekelman/projects/my_first_git_project.git/
```

Note the word **bare**, and note there is no "empty Git repository in .../.git/" — no `.git` at all. Let's do what we always do:

```console
tree my_first_git_project.git
```
```console
my_first_git_project.git
├── HEAD
├── config
├── description
├── hooks
│   ├── applypatch-msg.sample
│   {..}
│   └── update.sample
├── info
│   └── exclude
├── objects
│   ├── info
│   └── pack
└── refs
    ├── heads
    └── tags
```

Look at that list and recognise it. `HEAD`. `config`. `objects`. `refs/heads`. `refs/tags`. It is *exactly* the contents of the `.git` directory we have been dissecting since Part 1 — except it is not hidden inside a project, it *is* the project. There is no `readme.md`, no `media/`, no working copy of anything.

That is what "bare" means. A repository with the database but no **worktree**. And it is what every Git server on the planet is holding: a big pile of **blob**s, **tree**s and **commit**s, plus some refs pointing into it.

The config file says so out loud:

```console
cat my_first_git_project.git/config
```
```console
[core]
	repositoryformatversion = 0
	filemode = true
	bare = true
	ignorecase = true
	precomposeunicode = true
```

`bare = true`. One boolean. And:

```console
cat my_first_git_project.git/HEAD
```
```console
ref: refs/heads/master
```

Even a bare repository has a **HEAD**. Not to tell it "where you are" — nobody is anywhere, there is no working tree — but to tell *clones* which branch to check out. This is precisely the setting that hosting services expose as "default branch".

> :information_source:
> The `.git` suffix on a bare repository's directory name is a convention, not a rule. It exists so that a human doing `ls` on a server can tell repositories from ordinary directories. Follow it; everybody does.

### Why can't I just push to a normal repository?

Reasonable question. Our project *is* a repository. Why can't a colleague push straight into it?

Let's try. Two little repositories, `workrepo` (a normal one, with a working tree, sitting on `master`) and `copy` (a clone of it). We make a commit in `copy` and push:

```console
git push origin master
```
```console
remote: error: refusing to update checked out branch: refs/heads/master
remote: error: By default, updating the current branch in a non-bare repository
remote: is denied, because it will make the index and work tree inconsistent
remote: with what you pushed, and will require 'git reset --hard' to match
remote: the work tree to HEAD.
remote:
remote: You can set the 'receive.denyCurrentBranch' configuration variable
remote: to 'ignore' or 'warn' in the remote repository to allow pushing into
remote: its current branch; however, this is not recommended unless you
remote: arranged to update its work tree to match what you pushed in some
remote: other way.
{..}
To /Users/oripekelman/projects/workrepo
 ! [remote rejected] master -> master (branch is currently checked out)
error: failed to push some refs to '/Users/oripekelman/projects/workrepo'
```

Git wrote us an essay, and it is a good one. The `remote:` prefix means those lines were printed by Git *on the other side* and relayed to us — our first glimpse of the fact that a push is a conversation between two Gits.

The reasoning: if the push succeeded, `refs/heads/master` over there would point at a new **commit**, but the **index** and the working tree would still hold the old files. Someone typing `git status` in that directory would be told that they had deleted half the project. Git refuses to put a repository in that state behind its owner's back.

Which is the real reason bare repositories exist. Nobody works in them, so there is nothing to make inconsistent.

Now let's finally send our work over. We'll come back to `push` properly in the [next chapter](3-git-clone-pull-remote.md "Retrieve and send code"); for the moment we just need something on the other side to look at.

```console
git push -u origin master
```
```console
To /Users/oripekelman/projects/my_first_git_project.git
 * [new branch]      master -> master
branch 'master' set up to track 'origin/master'.
```

## Understanding local branches and remote branches

We have arrived at the single biggest source of confusion in Git, and we are going to take it slowly, because getting it right now saves years.

There are **three different things** that a beginner hears as one thing:

1. `master` — a local branch. A file, `.git/refs/heads/master`, containing a **SHA**. Yours. You move it by committing.
2. `origin/master` — a *remote-tracking reference*. Also a local file, `.git/refs/remotes/origin/master`, also containing a SHA. It is Git's **note-to-self about what the server said last time we spoke**. You do not move it by hand; `fetch` and `push` move it for you.
3. The branch called `master` *on the server*. Which is over there, in the bare repository, and which you cannot see from here at all without going and asking.

Number 2 is not number 3. Number 2 is a *cache* of number 3, and a cache can be out of date. Everything else follows from that.

Let's look at all three. After our push:

```console
tree .git/refs
```
```console
.git/refs
├── heads
│   ├── homepage
│   ├── master
│   ├── shopping_cart
│   └── shopping_cart_template
├── remotes
│   └── origin
│       └── master
└── tags
```

Four local branches. One remote-tracking ref, because we only pushed one branch. And:

```console
cat .git/refs/heads/master
cat .git/refs/remotes/origin/master
```
```console
973f21b9767b572145add7f9e4444a14529fc1fe
973f21b9767b572145add7f9e4444a14529fc1fe
```

Two files, same content. Which is exactly what we expect one second after a successful push: our branch and our idea of their branch agree.

> :information_source:
> Yours will show different SHAs — they depend on your content, your name and the exact second you committed. What matters is whether the two files match each other.

### Where did my refs go? `packed-refs`

Sometimes you go looking for `.git/refs/remotes/origin/master` and it is not there. In a *fresh clone* of our project, `tree .git/refs` shows `refs/heads/master` and `refs/remotes/origin/HEAD` — and nothing else. Where is `origin/master`? `git branch -a` swears it exists. It does:

```console
cat .git/packed-refs
```
```console
# pack-refs with: peeled fully-peeled sorted
973f21b9767b572145add7f9e4444a14529fc1fe refs/remotes/origin/master
1213fc5f325573870748535e5d457573a9c80b50 refs/remotes/origin/shopping_cart
```

Thousands of tiny one-line files is a wasteful way to store references, so from time to time (and always at the end of a clone) Git squashes them into one text file, `.git/packed-refs`. Exactly the same idea as the **pack** files that compress objects. A reference can live in either place; a loose file wins over the packed entry. `git pack-refs` does it on demand, and `git gc` does it while tidying.

So: to see a ref, prefer asking Git rather than the filesystem. `git rev-parse origin/master` gives you the SHA wherever it happens to be stored. `git show-ref` lists the lot.

### Seeing branches, local and remote

```console
git branch -a
```
```console
  homepage
* master
  shopping_cart
  shopping_cart_template
  remotes/origin/master
  remotes/origin/shopping_cart
```

`-a` is "all", meaning local branches *and* remote-tracking refs. The ones with `remotes/` in front are group 2 from our list above. You cannot check them out and commit on them — well, you can check them out, but you land in the **detached head** state we met in Part 1, because they are not branches, they are bookmarks.

Better still, `-vv`, which is `-v` twice and shows the tracking relationship:

```console
git branch -vv
```
```console
  homepage               973f21b Add readme.md and the media directory
* master                 973f21b [origin/master] Add readme.md and the media directory
  shopping_cart          1213fc5 Implement shopping cart template
  shopping_cart_template 1213fc5 Implement shopping cart template
```

Only `master` has `[origin/master]` next to it. That bracket is the **upstream** relationship, and it is the third block that appeared in our config when we pushed with `-u`:

```console
[branch "master"]
	remote = origin
	merge = refs/heads/master
```

"For the local branch `master`: the remote is `origin`, and the branch to integrate from is `refs/heads/master`." That is what lets you type a bare `git pull` and `git push` and have Git know what you meant.

You can set it after the fact, without pushing:

```console
git checkout shopping_cart
git branch --set-upstream-to=origin/shopping_cart
```
```console
branch 'shopping_cart' set up to track 'origin/shopping_cart'.
```

Or the way everybody actually does it, the first time they push a branch: `git push -u origin my_branch`. The `-u` is short for `--set-upstream`.

### "Your branch is ahead of 'origin/master' by 2 commits"

Now we can read the most-read sentence in Git. Let's earn it. We make two commits and ask:

```console
git status
```
```console
On branch master
Your branch is ahead of 'origin/master' by 2 commits.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
```

What Git did to produce that line: it took the SHA in `.git/refs/heads/master`, took the SHA in `.git/refs/remotes/origin/master`, walked the parent links of each, and counted. Two commits reachable from ours that are not reachable from theirs; zero the other way. That is all "ahead by 2" means. You can see the actual commits:

```console
git log --oneline origin/master..HEAD
```
```console
2eaa6ce Add a TODO list
9056566 Add a license file
```

> :information_source:
> The `A..B` syntax means "commits reachable from B but not from A". It is the single most useful piece of Git notation nobody teaches beginners. `origin/master..HEAD` is "what I have that they don't" — what a push would send. `HEAD..origin/master` is "what they have that I don't" — what a pull would bring.

Now for the part that matters. **That count was computed entirely on your machine, from two local files, without touching the network.** Which means it can be a lie.

Watch. Somebody else pushes a commit to the server. We know nothing about it. We ask Git how we are doing:

```console
git status
```
```console
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
```

Confidently wrong. We are not up to date with the server; we are up to date with our *memory* of the server. Now we ask the server:

```console
git fetch
```
```console
From /Users/oripekelman/projects/my_first_git_project
   973f21b..d0dcf58  master     -> origin/master
```

There it is: our remote-tracking ref moved from `973f21b` to `d0dcf58`. Nothing else changed — not our branch, not our files. And now:

```console
git status
```
```console
On branch master
Your branch is behind 'origin/master' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
```

Same command, same repository, same working tree, opposite answer. The only thing that changed is that we went and asked.

> :warning:
> Whenever `git status` tells you something about `origin/anything` and you have not fetched recently, treat it as a rumour. `git status` never goes to the network — by design, so that it stays instant. `git fetch` is what makes it true.

### Branches that no longer exist

The cache goes stale in the other direction too. Somebody deletes a branch on the server; our `refs/remotes/origin/` still has an entry for it. `git remote show origin` will call it out:

```console
  Remote branches:
    master                                     tracked
    refs/remotes/origin/shopping_cart_template stale (use 'git remote prune' to remove)
    shopping_cart                              tracked
```

And the fix, which you can also spell `git remote prune origin`:

```console
git fetch --prune
```
```console
From /Users/oripekelman/projects/my_first_git_project
 - [deleted]         (none)     -> origin/shopping_cart_template
```

`(none)` on the left of the arrow: there is no such thing on the remote any more, so the local copy goes. If you like, `git config --global fetch.prune true` makes every fetch tidy up after itself, and I would recommend it.

You will also see `[origin/homepage: gone]` in `git branch -vv` output: a local branch whose upstream has been deleted, usually because its pull request was merged and the host cleaned up. That is your signal that the local branch is finished too.

## Understand the decentralized nature. The Forks.

Now the culture, which is the real "aha" of this chapter.

We have a bare repository at `~/projects/my_first_git_project.git` and a working copy that pushes to it. Which one is *the* repository?

Neither. Both are complete. Each has every object, every commit, the whole history back to the first one. If the bare one burns down, any clone can recreate it in one command. If every clone burns down, the bare one is still fine. There is no master copy, no central authority, no special node. This is what "distributed" means, and it is not a marketing word — it is a property of the data structure. Content-addressed objects and parent pointers are the same everywhere or they are not the same object.

So why does everyone treat `origin` as sacred? **Social convention.** A team agrees "this URL is where the truth lives, we all push there, CI watches it, deploys come from it". Git enforces none of that. It is a shared habit, backed by permissions on a server. A very useful habit! But do not mistake it for a technical fact, because the day you need to (colleague's laptop, air-gapped machine, host outage) you can push to and pull from anywhere.

### Forks

A **fork**, in the GitHub/GitLab sense, is a clone. That is all it is: `git clone` run on a server you don't own, so that the copy sits next to the original with your name on it and a web page attached.

The web UI adds two genuinely valuable things: it *remembers* that your copy came from the original, and it gives you a button to propose your changes back. That is a pull request, and it lives in the [next chapter but one](5-git-workflow.md "Implement an efficient collaborative workflow").

But the shape of it is what we built by hand a few pages ago: `origin` is your fork, `upstream` is where you got it from, and you keep up to date by fetching from `upstream` and pushing to `origin`. If you understand that, you understand forks, and you will never again be mystified by "this branch is 47 commits behind upstream:main".

### The counterexample: the Linux kernel

It is worth knowing that the world's most famous Git repository does not work like GitHub at all — and Git was written for it.

Kernel contributions travel by **email**. You make your commits, you turn them into patch files, you mail them to a mailing list, humans review them by replying inline, and a maintainer applies them. No forks, no buttons, no accounts. Thousands of contributors, and it has been running like that for twenty years.

Git ships the tools for it, and they are ordinary commands:

```console
git format-patch master
```
```console
0001-Fix-a-typo-in-the-readme.patch
```

One file per commit, and the file is a real email:

```console
From 908187bd9d032029abff70dff03f5382f2d57253 Mon Sep 17 00:00:00 2001
From: Ori Pekelman <ori@pekelman.com>
Date: Sat, 7 Feb 2026 14:00:00 +0100
Subject: [PATCH] Fix a typo in the readme

---
 readme.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/readme.md b/readme.md
index 94190ef..b1169eb 100644
--- a/readme.md
+++ b/readme.md
@@ -1,3 +1,3 @@
 # My first Git project
 
-A project about learning Git.
+A project for learning Git.
-- 
2.51.0
```

Headers, subject, diff, and a signature giving the Git version. `git send-email` mails it; on the other side `git am` ("apply mailbox") turns it back into a commit with the original author and date preserved.

And if you would rather the maintainer *pulled* from you than applied a patch, `git request-pull <start> <url> <branch>` writes the request for you — a paragraph naming where your work begins, the URL and branch to fetch, a shortlog of the commits and a diffstat:

```console
git request-pull master ~/projects/my_first_git_project.git typo-fix
```
```console
The following changes since commit 69dd359f129c6211173f3ac934c17b461d27d187:

  Note the next steps (2026-02-05 11:30:00 +0100)

are available in the Git repository at:

  /Users/oripekelman/projects/my_first_git_project.git typo-fix
{..}
```

That is a pull request. The original one. The web version is this text with nicer typography and a comment thread.

I am not suggesting you switch your team to email. I am suggesting that the GitHub-shaped world is *one* workflow layered on top of Git, not Git itself — and that knowing this is what lets you tell which of your problems are Git problems and which are your host's.

## Where and how to host your git code?

Which brings us, finally and with the right amount of scepticism, to hosting.

First, the honest framing. Hosting a Git repository buys you almost nothing *Git-related*. Git is already done. What you are paying for (in money or in attention) is: a web interface for reading code, a code review tool, an issue tracker, CI runners, and access control. Those are real and valuable. They are also not Git, and each host does them differently, which is why so much "Git knowledge" turns out to be GitHub knowledge.

The main options, in 2026:

* **GitHub** — the default, and the network effect *is* the feature: if you want contributors, this is where they already have an account. Excellent CI (Actions), enormous ecosystem, owned by Microsoft.
* **GitLab** — the same job, plus you can run the whole thing on your own hardware, which matters enormously to some organisations. Integrated CI, and it was there first.
* **Codeberg / Forgejo**, and **Gitea** which Forgejo forked from — small, fast, pleasant, and cheap to self-host (Forgejo is a single binary and runs on the smallest VM you can rent). Codeberg is a non-profit running Forgejo for the community. If GitHub feels like too much machinery for a five-person project, look here.
* **sourcehut** (`sr.ht`) — deliberately minimal, no JavaScript, *mailing-list native*: built around the `format-patch` workflow we just looked at.
* **Bitbucket** — still very much around, especially alongside the rest of Atlassian's tools.

And the option people forget: **your own box**. You have already seen the whole trick. On a machine you can `ssh` into:

```console
ssh you@example.com
mkdir -p ~/repos/project.git
git init --bare ~/repos/project.git
exit
```

Then from your laptop:

```console
git remote add origin you@example.com:repos/project.git
git push -u origin master
```

That is a working Git server. No software installed, no ports opened, no configuration. SSH does the authentication, the filesystem does the storage, and you get every Git feature there is, because Git is all there is. What you don't get is a web page, a review tool or CI.

If you need to give several people access without handing out shell accounts, `gitolite` is a small, boring, well-tested tool that manages exactly that — one config file listing who may read and write which repositories. If you want the web page and the issues too, install Forgejo.

We are being brief here on purpose; there is a whole chapter on this: [Git hosting](../3-tooling-ecosystem/2-git-hosting.md "Git hosting").

> :information_source:
> Whatever you choose, keep the distinction we drew above in your head. Your repository is not "on GitHub". Your repository is on your disk, and there is *also* a copy on GitHub. This is not pedantry — it is the difference between "the site is down, we can't work" and "the site is down, we'll push later".

## Summary `git remote`, refspecs and remote-tracking branches

* A **remote** is a name for a URL plus a **refspec**, stored in `.git/config`. No state, no connection, nothing else.
* A refspec like `+refs/heads/*:refs/remotes/origin/*` maps refs on the remote (left of the colon) to refs here (right of it); `+` means "overwrite even if it isn't a fast-forward".
* `git remote add <name> <url>` declares one. `git remote`, `-v`, and `git remote show <name>` list them with increasing detail — the last one actually asks the server.
* `git remote rename` / `set-url` / `remove` edit that config block *and* fix up the remote-tracking refs.
* `git ls-remote <remote>` shows the raw refs a remote holds. The tie-breaker in every "but I pushed it" argument.
* `origin` is a convention, not a keyword. Several remotes are normal: `origin` for your fork, `upstream` for the original.
* Transports: a filesystem path (best for experimenting), `file://` (same place, real protocol), SSH `git@host:path` ([Configure Git with an SSH key](../6-appendices/2-git-ssh.md "Configure Git with an SSH key")), HTTPS (firewall-friendly, needs a token), and `git://` which is insecure and dead.
* `git init --bare` — the contents of `.git` promoted to be the whole directory, with no **worktree**. This is what a server holds, and why Git refuses to push into a non-bare repository's checked-out branch.
* Three different things: the local branch `master`; the remote-tracking ref `origin/master`, a *local cache* living in `.git/refs/remotes/` or `.git/packed-refs`; and the actual branch on the server.
* `git branch -a` lists local branches and remote-tracking refs; `git branch -vv` adds the **upstream** relationship. Set it with `git push -u origin foo` or `git branch --set-upstream-to=origin/foo`.
* "ahead of 'origin/master' by 2 commits" is counted locally from two ref files, and is only as fresh as your last `git fetch`. `git log --oneline origin/master..HEAD` shows which ones.
* `git fetch --prune` (or `fetch.prune = true`) drops remote-tracking refs for branches that no longer exist.
* Every clone is a complete repository; `origin` is privileged by social agreement alone. A fork is a clone with a web page. `git format-patch`, `git send-email`, `git am` and `git request-pull` are the original mailing-list workflow, still working, still building the kernel.
* Hosting buys you a web UI, code review, CI and an issue tracker — not Git. A bare repo plus `ssh` is a Git server. More in [Git hosting](../3-tooling-ecosystem/2-git-hosting.md "Git hosting").
