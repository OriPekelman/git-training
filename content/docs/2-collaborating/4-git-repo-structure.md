---
title: A little structure please
url: "/docs/git-repo-structure/"
weight: 14
---
# A little structure please

Git will let you do anything. Branches called `x`, `x2`, `x2-final`, `x2-final-REAL`; forty megabytes of `node_modules` in the history; a release identified by "the commit Sophie pushed on Thursday". Nothing in the tool prevents it, and for a weekend project nothing bad happens.

Then two people join, and then a deploy pipeline, and suddenly all of those choices are load-bearing. This chapter is about the conventions that grow on top of Git: what to call things, how to mark releases, what to keep out of the repository, and how to shape your branches. None of it is enforced by Git. All of it is the difference between a repository you can work in and one you dread.

## Schools of thought over the main branch

First of all, there are two interesting schools that you should know about **Stable master** and **Unstable master**. Some (like me) like the idea that the main branch represents the "prod", the stable state of production and we even make synonymous the idea of ​​integrating changes on this branch and putting these changes into production. So we only integrate on **master** what has been completely tested, completely validated. We ask **master** to always be green. This also means that usually any new functionality will be based on this state. This simplifies a lot of things.

Others, on the contrary, prefer this branch as the most unstable point where everything that has happened recently is integrated pell-mell. Those people, each time they want to put something in production, will "tag" a "release", give it a name that will no longer move. We will see the **tags** below.

> :information_source:
> **`master` or `main`?** Throughout this course we say `master`, because that is still what `git init` gives you unless you tell it otherwise, and it is what our example repository has been called since Part 1. But GitHub, GitLab and most new projects since 2020 use `main`, and you should expect to meet both for the rest of your career. They are ordinary branch names — nothing in Git treats either one specially — so this is purely a question of what the letters spell. To make your own repositories match your host: `git config --global init.defaultBranch main`. Everything in this chapter applies to whichever word you picked.

## The hierarchical branch structure

As we already noted a **branch** is a pointer to a **commit**, basically it gives us a name for a commit. And a commit has a **parent**. So teams talk about their branches as though they too were arranged in a hierarchy, and they draw them that way. There are many ways to organize them: sometimes completely flat (everything descends from master), sometimes with very strict structuring and a precise nomenclature for branch names.

Let's go along with that picture for a moment — it is how people think and speak — and then, in the next section, take it apart.

In the following form for example:

```
- Master
    -staging
        -correct_redirect
        -shopping_cart_spelling
    -development
        -add_top_banner
        -add_contextual_filter
```

We have the main branch, **master** deemed stable, and in production. A **staging** branch has code that will be deployed to my staging environment. This branch always starts by being synchronized with the master. Then if we discover an anomaly on the production version, we create a new branch under this **staging** we will make the necessary changes. When they are ready, and they will have passed all our tests... we can reintegrate them on the **staging** branch. Then if all goes well we will reintegrate them into master and put these changes into production.

The new functionalities on the other hand are developed on separate branches, which will represent the next deployment. If in the meantime **master** has moved because of our patches, we always have the option of re-importing (in English we use the term **backport**) those on our development branches, but then it's always a very explicit action. This is important because sometimes our development branches can diverge quite a bit from our **master**, if for example we have done a lot of refactoring; Patches from the "prod" will not always be applicable as is.

What is especially important to note is that the structure of your branches has every interest in representing your working method, your development and deployment cycles. In the first example the names we gave to our branches are descriptive like `correct_redirect`.

In the following example we represent a structure of branches where the hierarchy is flat, but the names are more structured. Hotfixes are prefixed with "hotfix" or "feature" and branch names represent a ticket number in our task tracking system.

```
- Master
    -hotfix/pf-223
    -hotfix/pf-578
    -feature/pf-431
    -feature/pf-563
```

But enough theory.

## The beautiful tree structure (structure of branches)

Let's go and look, because there is a small but important lie in those diagrams above, and it is worth clearing up before we go any further.

Fresh repository, one commit, and we make a few branches with names that look structured:

```console
git branch feature/login
git branch feature/logout
git branch fix/pf-223
git branch chore/bump-deps
```

Now the usual move:

```console
tree .git/refs/heads
```
```console
.git/refs/heads
├── chore
│   └── bump-deps
├── feature
│   ├── login
│   └── logout
├── fix
│   └── pf-223
└── master

4 directories, 5 files
```

There it is. Our beautiful tree structure is *real* — but it is a tree of **directories on your disk**, created because a **ref** name is a file path and `/` is a path separator. Nothing more. `feature/login` is the file `.git/refs/heads/feature/login`, containing forty hex characters, exactly like `master` is the file `.git/refs/heads/master`.

Which means Git does not think `feature/login` is "inside" `feature` in any meaningful sense. There is no parent branch, no child branch, no hierarchy of branches anywhere in Git's data model. `git branch` doesn't have a `--parent` option because there is nothing for it to report.

So what makes the diagrams above true? The **commit graph**. `feature/login` descends from `master` because the commit it points at has, somewhere up its chain of parents, the commit `master` points at. That is the only structure there is, and you can ask about it directly:

```console
git log --oneline --graph --all
git branch --contains 9056566
git branch --merged master
git branch --no-merged master
```

The names are for *humans* — and for the tools humans write. Which is the actual payoff, because Git gives you pattern matching over ref names:

```console
git branch --list 'feature/*'
```
```console
  feature/login
  feature/logout
```

And the lower-level command that every script and every prompt-in-your-shell is built on:

```console
git for-each-ref --format='%(refname) %(objectname:short)' refs/heads
```
```console
refs/heads/chore/bump-deps 20a274e
refs/heads/feature/login 20a274e
refs/heads/feature/logout 20a274e
{..}
```

That is what your CI configuration means when it says `only: - /^release\/.*$/`. It is matching strings. Which is exactly why the strings deserve some thought.

## Branch names

So, conventions. These are mine, they are widely shared, and every single one of them exists because somebody's automation broke.

**Use lowercase, digits, and `-` `_` `/` `.` as separators. Nothing else.** That's it. That is the whole rule, and it is the same warning we gave in the branches chapter, now with reasons attached.

**Prefix by intent.** A flat namespace of forty branch names is unreadable; a prefixed one sorts itself:

```
feature/    a new capability
fix/        a bug fix on the current line of development
hotfix/     an urgent fix going straight to production
chore/      dependency bumps, config, tooling — no behaviour change
release/    a branch that exists to stabilise and ship a version
```

**Put the ticket id in the name.** `feature/pf-431-guest-checkout` is better than either `feature/pf-431` (opaque in `git branch`) or `feature/guest-checkout` (impossible to link back to the discussion). Many hosts will connect the branch to the issue automatically if the id is in the name, and future-you reading `git log --graph` in eight months will be grateful.

**Keep them short-lived.** The best branch name is one nobody has to read for very long.

### The one real constraint: `/` makes directories

We just saw that `feature/login` is a file inside a directory called `feature`. Which has a consequence that trips up everybody exactly once:

```console
git branch feature
```
```console
fatal: cannot lock ref 'refs/heads/feature': 'refs/heads/feature/login' exists; cannot create 'refs/heads/feature'
```

You cannot have a branch `feature` *and* a branch `feature/login`, because a file cannot also be a directory. It works in the other direction too:

```console
git branch experiment
git branch experiment/one
```
```console
fatal: cannot lock ref 'refs/heads/experiment/one': 'refs/heads/experiment' exists; cannot create 'refs/heads/experiment/one'
```

Not a bug, not arbitrary: it is a filesystem talking. And it is a good argument for picking a prefix scheme and sticking to it — either everything is `feature/something`, or nothing is. Half-and-half is how you collide.

### What not to do

**Spaces.** Git won't even let you:

```console
git branch 'my feature'
```
```console
fatal: 'my feature' is not a valid branch name
hint: See `man git check-ref-format`
hint: Disable this message with "git config set advice.refSyntax false"
```

**`HEAD`**, and a few other reserved shapes:

```console
git branch HEAD
```
```console
fatal: 'HEAD' is not a valid branch name
```

**Unicode and emoji.** Git allows them. Your terminal will render them, more or less. Your CI's shell script will not quote them, your Windows colleague's checkout will produce a filename their antivirus dislikes, and the log line in the deploy output will be mojibake. It is a bad idea, and the fact that it works is not an argument.

**Uppercase — especially on macOS and Windows.** This one deserves a demonstration, because it is genuinely sneaky. Our repository already has a `fix/` directory, from `fix/pf-223`. Watch:

```console
git branch Fix/PF-999
tree .git/refs/heads
```
```console
.git/refs/heads
├── chore
│   └── bump-deps
├── feature
│   ├── login
│   └── logout
├── fix
│   ├── pf-223
│   └── PF-999
└── master
```

Read that carefully. We asked for `Fix/PF-999`. We got `fix/PF-999`. The filesystem is case-insensitive, so when Git went to create the directory `Fix` it found `fix` already there and used it. Git will now tell us:

```console
git branch --list 'fix/*'
```
```console
  fix/PF-999
  fix/pf-223
```
```console
git branch --list 'Fix/*'
```

— and that one prints nothing at all. The branch we asked for does not exist under the name we typed. What gets pushed is `fix/PF-999`. On a colleague's Linux machine, where `Fix` and `fix` are two different directories, this is where a confusing hour begins. Lowercase everything and the problem cannot occur.

**Names that look like a SHA.** Git allows this too, and it is a trap of your own making:

```console
git branch 1213fc5
```

No error. Now `git checkout 1213fc5` is ambiguous between a branch and a commit — Git will pick the branch and be silently unhelpful. Don't.

### `git check-ref-format`, the rule book

If you are writing a script that accepts a branch name from a human, or you simply want to know what is legal, Git exposes the validator:

```console
git check-ref-format --branch 'my feature'
```
```console
fatal: 'my feature' is not a valid branch name
```

Exit status is what matters — zero for valid, non-zero for invalid — so it drops straight into a shell `if`. The full-ref form takes the whole path:

```console
git check-ref-format 'refs/heads/feature/login'   # ok
git check-ref-format 'refs/heads/feature..login'  # rejected
git check-ref-format 'refs/heads/fix.lock'        # rejected
git check-ref-format 'refs/heads/what?'           # rejected
```

`..` is out because it is Git's own range syntax. A name ending in `.lock` is out because that is how Git locks refs while updating them. `?`, `*`, `[`, `~`, `^`, `:`, backslash, spaces, control characters — all out, all for reasons you can guess. `man git-check-ref-format` has the complete list and is one of the few Git man pages that is short.

## Tags

Part 1 never introduced **tags**, and it is time, because the whole "unstable master" school above depends on them, and because they are the nicest small thing in Git.

A **tag** is a name for a commit that is *not supposed to move*. A branch name is a bookmark that follows you as you work; a tag is a nail in the wall. `v1.0` should mean the same commit in five years as it does today, in your repository and in everybody else's.

And there are two kinds, which look identical in daily use and are completely different objects.

### Lightweight tags

```console
git tag v0.9-wip
```

Git says nothing. Let's look:

```console
tree .git/refs/tags
cat .git/refs/tags/v0.9-wip
```
```console
.git/refs/tags
└── v0.9-wip

1 directory, 1 file
```
```console
a47856e41c9e5f275068920884c735276b97f1f6
```

A file containing a **SHA**. Exactly like a branch, in a different directory. And when we ask Git what kind of object that name refers to:

```console
git cat-file -t v0.9-wip
```
```console
commit
```

A commit. The tag *is* the reference; there is no tag object at all. Nothing was added to `.git/objects`. A lightweight tag carries no message, no author, no date, no signature — it is a private bookmark, and that is the right way to think about it.

### Annotated tags

```console
git tag -a v1.0 -m'First release: readme, license and a homepage stub'
cat .git/refs/tags/v1.0
```
```console
75fff39cacc4f49bc16fe5d3d798cdeb393ed8a5
```

Now hold on. Our commit was `a47856e`. What is `75fff39`?

```console
git cat-file -t v1.0
```
```console
tag
```

A fourth kind of object! We have known **blob**, **tree** and **commit** since Part 1; here is the last one. And like the others, we can just read it:

```console
git cat-file -p v1.0
```
```console
object a47856e41c9e5f275068920884c735276b97f1f6
type commit
tag v1.0
tagger Ori Pekelman <ori@pekelman.com> 1770285600 +0100

First release: readme, license and a homepage stub
```

Look how familiar that shape is. It is laid out exactly like the **commit** we dissected in Part 1: a few `key value` lines, a blank line, then a message. `object` is what it points at, `type` is what kind of thing that is, `tag` is the name, `tagger` is who and when — a name, an email and a Unix **timestamp** with a timezone, same format as `author` and `committer`.

So an annotated tag is a real object, stored in `.git/objects` like everything else, with its own SHA, and the reference in `refs/tags/` points at *it* rather than at the commit. It can be signed, with GPG (`git tag -s`) or since Git 2.34 with an SSH key, which is how release artifacts get cryptographically attributed to a human.

> :information_source:
> This is where the `^{}` in `git ls-remote` output from the remotes chapter comes from:
> ```console
> 75fff39cacc4f49bc16fe5d3d798cdeb393ed8a5	refs/tags/v1.0
> a47856e41c9e5f275068920884c735276b97f1f6	refs/tags/v1.0^{}
> ```
> Two lines for one tag: the tag object, and — `^{}` meaning "peel this until you reach a non-tag" — the commit it ultimately points at.

**Be opinionated about this: use annotated tags for anything you publish.** A release deserves to record who made it, when, and why. Lightweight tags are fine as personal scratch marks ("`before-the-big-refactor`"), and there is no shame in that, but they should not be the thing your deploy pipeline builds from.

### Working with tags

```console
git tag
```
```console
v0.9-wip
v1.0
```

Filter with a pattern — indispensable once a project has three hundred of them:

```console
git tag -l 'v1.*'
```
```console
v1.0
```

Add `-n` to see the messages (for a lightweight tag, Git shows the commit subject instead, since there is no message of its own):

```console
git tag -n
```
```console
v0.9-wip        Add an empty homepage template
v1.0            First release: readme, license and a homepage stub
```

`git show` on an annotated tag shows the tag, then the commit, then the diff:

```console
git show v1.0
```
```console
tag v1.0
Tagger: Ori Pekelman <ori@pekelman.com>
Date:   Thu Feb 5 11:00:00 2026 +0100

First release: readme, license and a homepage stub

commit a47856e41c9e5f275068920884c735276b97f1f6
Author: Ori Pekelman <ori@pekelman.com>
Date:   Wed Feb 4 09:00:00 2026 +0100

    Add an empty homepage template

diff --git a/views/homepage.html b/views/homepage.html
new file mode 100644
{..}
```

Deleting locally:

```console
git tag -d v0.9-wip
```
```console
Deleted tag 'v0.9-wip' (was a47856e)
```

And a tag is a perfectly good thing to check out, or diff, or clone at — `git checkout v1.0` puts you in a **detached head** on that exact commit, which is precisely what you want when investigating "was this broken in 1.0?".

### `git describe`

A small command that solves a real problem: naming the commit you are on, in human terms.

```console
git describe
```
```console
v1.0-1-g69dd359
```

Read it as three parts: the most recent **annotated** tag reachable from here (`v1.0`), how many commits we are past it (`1`), and the abbreviated SHA of where we actually are (`g` for "git", then `69dd359`). On the tagged commit itself you just get the tag:

```console
git describe v1.0
```
```console
v1.0
```

This is where build systems get their version strings from. And note the emphasis on *annotated*: a repository with no tags at all says `fatal: No names found, cannot describe anything.`, while one with only lightweight tags says

```console
fatal: No annotated tags can describe '20a274e12b45c66e74942b44f159320d4b04d050'.
However, there were unannotated tags: try --tags.
```

which is Git telling you, politely, that you tagged your release wrong. `git describe --tags` will fall back to the lightweight ones if you insist.

### Pushing tags, and not moving them

We covered this in the previous chapter and it bears repeating because it surprises everyone: **`git push` does not push tags.** The refspec only covers `refs/heads/*`. You need `git push origin v1.0`, or `--follow-tags`, or `push.followTags = true`.

> :warning:
> **Never move or delete a published tag.** Git will let you: `git tag -f v1.0 <other-commit>` and a force-push will do it. But a tag's entire value is that it means one thing forever. Everybody who already fetched `v1.0` keeps the old one — Git does not update existing tags on fetch — so from that moment on `v1.0` means different commits on different machines, and the bug report you get will be unreproducible for reasons nobody can see. If you shipped the wrong commit as `v1.0`, ship `v1.0.1`. It costs nothing and it is the truth.

And **semantic versioning** in one sentence, since we are naming releases: `MAJOR.MINOR.PATCH`, where you bump PATCH for a bug fix, MINOR for a backwards-compatible addition, and MAJOR when you break somebody's code — the promise being that your users can read the number and know whether upgrading is safe (the full spec is at [semver.org](https://semver.org)).

## Clean up please .gitignore

Every project accumulates files that must not be committed: build output, dependencies, log files, editor droppings, `.DS_Store`, local configuration with credentials in it. Left alone, `git status` fills with noise, `git add .` becomes dangerous, and eventually somebody commits a 200MB build directory.

The fix is a file called `.gitignore`, which is one of the very few things in Git that people use for years without ever reading the rules. So let's read the rules.

### Pattern syntax

A `.gitignore` is a list of patterns, one per line, `#` for comments, blank lines ignored.

```console
cat .gitignore
```
```console
node_modules/
*.log
!logs/keep.log
build/
```

* **Plain glob.** `*.log` matches any file whose name ends in `.log`, at *any* depth. `*` does not cross `/`; `?` is one character; `[0-9]` is a class.
* **A trailing `/` means "directory only".** `build/` ignores the directory and everything in it, but would not match a *file* called `build`. Use it whenever you mean a directory — it is faster and more precise, because Git can stop descending.
* **A `/` anywhere else anchors the pattern** to the directory containing the `.gitignore`. So `/TODO.txt` matches only the one at the top level; plain `TODO.txt` matches at every depth. This is the rule people get wrong most often.
* **`**` crosses directories.** `doc/**/out.html` matches `doc/build/out.html` and `doc/a/b/out.html`. `**/config/` matches a `config` directory anywhere.
* **`!` negates**, re-including something an earlier pattern excluded. Order matters: the *last* matching pattern wins.

Rather than take my word for any of it, there is a command that shows you Git's actual decision and, crucially, *which line made it*:

```console
git check-ignore -v build/app logs/error.log logs/keep.log src/vendor/lib.js
```
```console
.gitignore:4:build/	build/app
.gitignore:2:*.log	logs/error.log
.gitignore:3:!logs/keep.log	logs/keep.log
```

File, line number, the pattern itself, then the path. Note that `src/vendor/lib.js` produced no line at all — it is not ignored, so there is nothing to report. **`git check-ignore -v` is the single most useful command in this section.** Every "why is Git ignoring my file" or "why is Git *not* ignoring my file" question is one invocation away from an answer.

Here is that anchoring and `**` behaviour, checked rather than asserted — in a separate little repository, so the line numbers stay easy to follow:

```console
cat .gitignore
```
```console
/TODO.txt
doc/**/out.html
**/config/
```
```console
git check-ignore -v TODO.txt a/TODO.txt doc/build/out.html a/b/config/x.json tools/doc/notes.txt
```
```console
.gitignore:1:/TODO.txt	TODO.txt
.gitignore:2:doc/**/out.html	doc/build/out.html
.gitignore:3:**/config/	a/b/config/x.json
```

The top-level `TODO.txt` is ignored; `a/TODO.txt` is not, because of the leading slash. `tools/doc/notes.txt` is not, because `doc/**` is anchored to the top.

### The negation rule that has no workaround

This one is worth committing to memory, because it looks like a bug. We add a fifth line to the `.gitignore` we've been using, trying to make one exception:

```console
cat .gitignore
```
```console
node_modules/
*.log
!logs/keep.log
build/
!build/app
```
```console
git check-ignore -v build/app
```
```console
.gitignore:4:build/	build/app
```

Still ignored, despite the `!`. **You cannot re-include a file if one of its parent directories is excluded.** The reason is performance: when Git sees `build/` excluded it stops descending into it entirely, so it never even looks at `build/app` and never gets a chance to apply the negation.

Line 4 wins, and line 5 never even gets consulted. The fix is to exclude the *contents* rather than the directory — one character:

```console
cat .gitignore
```
```console
node_modules/
*.log
!logs/keep.log
build/*
!build/app
```
```console
git check-ignore -v build/app
```
```console
.gitignore:5:!build/app	build/app
```

`build/*` excludes the children individually, so Git does descend, and the negation gets its turn. Whenever a `!` mysteriously does nothing, look upward for an excluded directory.

### Where the rules live, and who wins

There are four places, and they are ranked, from **highest precedence to lowest**. Within one rank, the last matching pattern wins; across ranks, the higher rank simply beats the lower one.

1. **Command-line patterns**, for the few commands that take them. Nothing outranks these.
2. **`.gitignore` files in the tree** — and among those, *the deepest one wins*, overriding its parents for its own subtree:

```console
cat docs/.gitignore
```
```console
!*.log
```
```console
git check-ignore -v docs/build.log
```
```console
docs/.gitignore:1:!*.log	docs/build.log
```

The top-level `.gitignore` says `*.log`; `docs/.gitignore` overrules it for that subtree. This is how you keep a project-wide rule and one local exception.

3. **`.git/info/exclude`** — same syntax, but it lives in `.git` and is therefore *not committed*. This is the right place for things that are your business alone: your scratch directory, the file where you keep local notes.

```console
git check-ignore -v scratch/notes
```
```console
.git/info/exclude:7:scratch/	scratch/notes
```

(Line 7 because `git init` puts six lines of explanatory comment in that file for you. We met it in Part 1, in the very first `tree -C .git`, and never found out what it was for. Now we know.)

4. **`core.excludesFile`** — a global list for your whole machine, and the *weakest* of the four, so any project can override it:

```console
git config --global core.excludesFile ~/.gitignore_global
```
```console
git check-ignore -v src/main.py.swp
```
```console
/Users/oripekelman/.gitignore_global:1:*.swp	src/main.py.swp
```

The ranking is easy to remember once you see the logic in it: the closer a rule is to the thing it is talking about, the more it is trusted. A pattern you typed on the command line beats a file in the directory, which beats a file about the repository, which beats a file about your laptop.

> :information_source:
> A rule of etiquette worth adopting: **your editor's droppings do not belong in the project's `.gitignore`.** `.DS_Store`, `*.swp`, `.idea/`, `.vscode/` — those are facts about *your* machine, and putting them in the shared file means every project you touch grows a section for every tool anyone on the team has ever used. Put them in your global excludes file once, and never think about them again. The project's `.gitignore` should describe *the project*: its build output, its dependency directories, its generated files.

### The single most important fact about `.gitignore`

Here it is, and it accounts for the majority of `.gitignore` confusion in the world:

**`.gitignore` only affects files that Git is not already tracking.**

Once a file has been committed, adding it to `.gitignore` does absolutely nothing. Watch. We commit a file we shouldn't have — `.env`, with a password in it, as one does — then add `.env` as a sixth line in `.gitignore`, then change the file:

```console
git status --short
```
```console
 M .env
 M .gitignore
?? build/
?? logs/
?? src/vendor/
```

` M .env` — modified, tracked, reported, and the next `git commit -a` will happily include it. Meanwhile:

```console
git check-ignore -v .env
```

Nothing at all, and the exit status is 1. `check-ignore` skips tracked paths by default, which is itself the clue. Force it to answer anyway:

```console
git check-ignore -v --no-index .env
```
```console
.gitignore:6:.env	.env
```

"Your pattern is correct and it does match — but this file is in the **index**, so the pattern is irrelevant." Which is exactly the situation, stated precisely.

The fix is to remove it from the index while leaving it on disk, which is what `--cached` means:

```console
git rm --cached .env
```
```console
rm '.env'
```
```console
git status --short
```
```console
D  .env
 M .gitignore
?? build/
?? logs/
?? src/vendor/
```

`D` in the first column: staged for deletion from the repository. The file is still sitting in your working directory — `--cached` touched only the index. Commit that, and from then on the ignore rule applies:

```console
git commit -am'Stop tracking the environment file'
git status --short
```
```console
?? build/
?? logs/
?? src/vendor/
```

`.env` is gone from the output. Ignored at last.

> :warning:
> `git rm --cached` **deletes the file from the next commit**. Anyone who pulls will find it disappearing from their working directory. For `.env`-style files that everyone has their own copy of, that is exactly right — commit a `.env.example` instead. But announce it, or your colleague's afternoon becomes a mystery.

### Two more commands you will want

To see what is being hidden from you:

```console
git status --short --ignored
```
```console
?? logs/
?? src/vendor/
!! build/
!! logs/error.log
```

`!!` marks the ignored entries. Excellent for the moment you suspect your build is using a file that was never committed.

And to override the rules once, deliberately:

```console
git add logs/error.log
```
```console
The following paths are ignored by one of your .gitignore files:
logs/error.log
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
```

Git refuses and tells you the escape hatch:

```console
git add -f logs/error.log
```

Sometimes legitimate — a single generated file that genuinely must be committed inside an otherwise-ignored directory. Usually a sign your patterns need fixing.

And do not write the thing from scratch: GitHub maintains a large collection of `.gitignore` templates per language and toolchain at [github.com/github/gitignore](https://github.com/github/gitignore), and every host offers them in the "new repository" form. Start from the one for your stack — it will list half a dozen files you did not know your tools created — then add your project's own specifics.

### The other file: `.gitattributes`

`.gitignore` says which files Git should not look at. **`.gitattributes`** says how Git should *treat* the ones it does. Same idea — patterns, one per line, committed with the project, deepest file wins — but instead of "ignore this" you set named attributes.

```console
cat .gitattributes
```
```console
* text=auto
*.sh text eol=lf
*.png binary
```

And, as ever, you can ask Git what it concluded:

```console
git check-attr text eol diff -- run.sh logo.png notes.md
```
```console
run.sh: text: set
run.sh: eol: lf
run.sh: diff: unspecified
logo.png: text: unset
logo.png: eol: unspecified
logo.png: diff: unset
notes.md: text: auto
{..}
```

What people actually use it for:

* **Line endings.** `* text=auto` tells Git to store text files with LF internally and check them out in the platform's native form. `eol=lf` forces LF on checkout too, which is what you want for shell scripts that a Windows colleague might otherwise commit with CRLF and make un-executable. If you have ever seen a diff where every single line changed, this is the file that fixes it.
* **Marking binaries.** `*.png binary` is shorthand for "don't try to diff or merge this and don't touch its bytes". Saves Git from producing a useless diff and saves you from a corrupted merge.
* **Language hints.** `*.min.js linguist-generated=true` tells GitHub's language detector to exclude a file from the statistics and collapse it in pull requests. Purely cosmetic, quite satisfying.
* **Custom diff and merge drivers.** `*.json diff=json`, or a merge driver that knows how to combine a changelog. Advanced, and occasionally exactly what you need.
* **Git LFS.** Large-file storage is configured entirely through `.gitattributes` — `*.psd filter=lfs diff=lfs merge=lfs -text` — which is why running `git lfs track` modifies this file. That has a chapter of its own: [Git LFS](../4-beyond-the-basics/4-git-lfs.md "Git LFS").

> :warning:
> **Putting a secret in `.gitignore` does not protect it, and it never did.** `.gitignore` prevents a file from being *added*; it does nothing about one that is already committed. And here is the part people underestimate: a secret that has been committed **and pushed** is compromised, permanently. Deleting it in a later commit leaves it in the history. Rewriting the history leaves it in every clone anybody made, in the reflogs, in your host's caches, and — if the repository was ever public — in the archives of the several services that scan public pushes in real time and in the training data of every model since. The only correct response is to **rotate the credential**: revoke it, issue a new one, and *then* worry about cleaning the history. Cleaning is worth doing, and [Keep a clean history, recover from mistakes](6-git-cleanup.md "Keep a clean history, recover from mistakes") shows how. It is not what makes you safe.

## The beautiful agreement, Gitflow and friends

We have names, we have tags, we have a repository with only the files that belong in it. The last piece of structure is the agreement: *which branches exist, what they mean, and how work flows between them.*

These have names, they get argued about with more heat than they deserve, and — this is the part worth internalising — **they are all just conventions about branch names.** Not one of them is a Git feature. Every one of them is implemented with the same `git branch`, `git merge` and `git tag` you already know.

### GitFlow

Vincent Driessen published *A successful Git branching model* in January 2010 and it became, for about a decade, the answer. It has:

* **`master`** — production only. Every commit on it is a release, and carries a tag.
* **`develop`** — the integration branch, where finished features land. The "unstable master" school, given its own branch.
* **`feature/*`** — branch from `develop`, merge back to `develop`.
* **`release/*`** — branched from `develop` when you decide to ship. Stabilise here, no new features. When it's ready, merge to `master` (and tag), and back into `develop`.
* **`hotfix/*`** — branched from `master` for production emergencies. Merge to `master` (and tag) *and* to `develop`, so the fix isn't lost.

It is coherent, it is complete, and it handles the awkward cases properly, which is why it was so popular. It is also a lot of ceremony: five branch types, two long-lived branches to keep in sync, and every release involving four merges.

And its own author says so. In a note added to that post on 5 March 2020, Driessen wrote that git-flow was designed for software that is *explicitly versioned* — where you ship releases and support several of them in the wild at once — and added:

> If your team is doing continuous delivery of software, I would suggest to adopt a much simpler workflow (like GitHub flow) instead of trying to shoehorn git-flow into your team.

Which is the most useful sentence in this entire chapter, and it comes from the person with the most to lose by saying it. **Use GitFlow if you ship versioned software with multiple supported releases** — a library, a desktop application, anything on-premise where customers run 3.2 and 4.0 simultaneously. If you deploy your web app eleven times a day, it is machinery you are carrying for nothing.

### GitHub Flow

The reaction, and radically simpler. There is one long-lived branch, `main`. To do anything:

1. Branch from `main`.
2. Commit, push, open a pull request.
3. Get it reviewed, let CI run.
4. Merge to `main`.
5. Deploy `main`.

That's the whole model. No `develop`, no release branches, no back-merges. Its correctness depends entirely on two things: `main` must always be deployable, and branches must be short-lived — days, not weeks. If you have both, this is very hard to beat. If you don't have automated tests, "main is always deployable" is a wish rather than a property, and this model will hurt you.

### GitLab Flow

GitHub Flow plus the acknowledgement that most teams do not deploy straight to production. Add long-lived **environment branches** downstream of `main`: `main` → `staging` → `production`. Code flows one way only, by merging, so an environment branch is always a *prefix* of `main`'s history and "what is in production" is a question with an answer. Hotfixes go into `main` and get cherry-picked forward when they can't wait.

This is essentially the model in the existing prose at the top of this chapter, and it is a sound middle ground when you have real environments and a release cadence that isn't continuous.

### Trunk-based development

The far end of the spectrum. Everybody commits to `main` — either directly, or through branches that live for *hours*. Nothing is long-lived, so nothing diverges, so integration is never an event. Incomplete work ships to production, turned off behind a **feature flag**, and is switched on separately from being deployed.

That last point is what makes it work, and it is a genuine trade: you have moved complexity out of Git (where it was merge conflicts) and into your application (where it is flag configuration, and flags you must remember to remove). It also demands strong automated tests, because there is no stabilisation phase in which to find things out.

It is worth knowing that this is not a fringe position. The DORA research programme — the multi-year survey work behind *Accelerate* — has consistently found trunk-based development, with short-lived branches and merges at least daily, to be among the practices that correlate with high software delivery performance. Not because branches are bad, but because *long-lived* branches are where integration pain compounds.

### Release branches for products with long-lived versions

Orthogonal to all of the above, and necessary if you support old versions: when you ship 2.4, you keep a branch `release/2.4` (or `2.4.x`) alive. Fixes are made on `main` and cherry-picked back, or made on the oldest affected release branch and merged forward. Each patch release gets its own tag. This is how the Linux kernel's longterm branches work, how PostgreSQL works, how anything with an LTS promise works, and there is no simpler way to keep a promise like that.

### So which one?

The course's opinion, and it is only partly about Git:

**The shape of your branches should mirror your release cadence.** That is the actual rule, and every model above is a special case of it. If you release when a release branch is ready, you need release branches. If you support four versions, you need four long-lived branches. If you deploy on every merge, you need one branch and a strong test suite.

And then: **if you deploy continuously, the simplest model that works is the right one.** Complexity in a branching model is not free — it is paid every day, by every person on the team, in ceremony and in mistakes. Teams adopt GitFlow because it is written down and looks professional, then spend a year keeping `develop` and `master` in sync for a service that has exactly one version in existence. Start with one branch and short-lived feature branches. Add a `release/*` branch the first time you actually need to stabilise something while work continues. Add environment branches the first time you actually have environments. Never add a branch type because a diagram had it.

Which brings us back to where the existing prose in this chapter started, and it was right the first time: *the structure of your branches has every interest in representing your working method.* Your working method first. Then the branches.

And whatever you choose, write it down — in the `readme.md`, or in `CONTRIBUTING.md`. A branching model that lives in the senior developer's head is not a convention, it's a hazing ritual.

## Summary: names, tags, `.gitignore` and branching models

* Branch hierarchy lives in the **names**, not in Git: `feature/login` is the file `.git/refs/heads/feature/login` and `/` is a path separator. The only real structure is the **commit** graph — `git log --graph --all`, `git branch --contains`, `git branch --merged`. The names are for humans and for tooling: `git branch --list 'feature/*'`, `git for-each-ref refs/heads`.
* Branch naming: lowercase, digits, `-` `_` `/` `.`; prefix by intent (`feature/`, `fix/`, `hotfix/`, `chore/`, `release/`); include the ticket id; keep them short-lived.
* Because `/` makes a directory, you cannot have both `feature` and `feature/login` — *`cannot lock ref 'refs/heads/feature': 'refs/heads/feature/login' exists`*. Avoid spaces and `HEAD` (Git refuses), unicode and emoji (Git allows, your tooling doesn't), SHA-shaped names, and uppercase — on a case-insensitive filesystem `Fix/PF-999` silently becomes `fix/PF-999`. `git check-ref-format --branch <name>` is the official validator.
* A **tag** names a commit that must not move. A **lightweight** tag (`git tag v0.9`) is only a ref in `refs/tags/`. An **annotated** tag (`git tag -a v1.0 -m'...'`) creates a real **tag object** in `.git/objects` with a tagger, date, message and optional GPG/SSH signature — read it with `git cat-file -p v1.0`. Use annotated tags for anything you publish.
* `git tag`, `git tag -l 'v1.*'`, `git tag -n`, `git show <tag>`, `git tag -d <tag>`, and `git describe` → `v1.0-1-g69dd359` (nearest annotated tag, commits since, abbreviated SHA). Tags are **not** pushed by `git push`; use `git push origin v1.0` or `--follow-tags`. **Never move or delete a published tag** — ship `v1.0.1`. Version numbers: `MAJOR.MINOR.PATCH` — break, add, fix.
* `.gitignore` patterns: glob (`*` does not cross `/`), trailing `/` for directories only, a `/` elsewhere anchors to the containing directory, `**` crosses directories, `!` negates and the last match wins. **You cannot re-include a file under an excluded directory** — exclude `build/*`, not `build/`.
* Precedence, strongest first: command-line patterns → `.gitignore` files with the deepest one winning → `.git/info/exclude` (personal, uncommitted) → `core.excludesFile` (global, and where your editor's droppings belong). Closer to the file means more trusted.
* **`.gitignore` only affects untracked files.** Ignoring an already-tracked file does nothing; `git rm --cached <file>` drops it from the **index** while leaving it on disk, and *then* the rule applies.
* `git check-ignore -v <path>` names the file, line and pattern responsible — the answer to every ignore question; `--no-index` makes it answer for tracked files too. `git status --ignored` shows what is hidden (`!!`); `git add -f` overrides once. Start from a template at [github.com/github/gitignore](https://github.com/github/gitignore).
* `.gitattributes` is the sibling file — how Git *treats* files rather than whether it sees them: `* text=auto`, `eol=lf`, `*.png binary`, linguist hints, custom diff and merge drivers, and where **Git LFS** lives ([Git LFS](../4-beyond-the-basics/4-git-lfs.md "Git LFS")). `git check-attr` shows the result.
* Ignoring a secret protects nothing. A committed, pushed secret is compromised forever: **rotate it**, then clean the history ([Keep a clean history, recover from mistakes](6-git-cleanup.md "Keep a clean history, recover from mistakes")).
* Branching models are conventions about branch names, not Git features. **GitFlow** (`develop`, `release/*`, `hotfix/*`, `feature/*`) for explicitly versioned software with several supported releases — its own author recommends against it for continuous delivery. **GitHub Flow**: one long-lived branch, short-lived feature branches, deploy from `main`; needs `main` always deployable. **GitLab Flow** adds environment branches. **Trunk-based development** with feature flags is what the DORA research associates with high performers.
* The rule behind all of them: the shape of your branches should mirror your release cadence — and if you deploy continuously, the simplest model that works is the right one. Then write it down.
