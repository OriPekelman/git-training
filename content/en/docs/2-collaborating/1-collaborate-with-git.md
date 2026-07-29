---
title: Collaborate with Git
slug: "collaborate-with-git"
weight: 11
---
# Collaborate with Git

We learned how to save our work by creating a Git repository. Then how to track file and directory changes. We even know how to go back in history, see what has changed.

We worked on a single branch of our code (the one created by default, **master**), and moreover it quickly became a bit of a mess, but we also learned to go back to the past to do clean .

But when we are going to work with others or even alone this is not the right method. Quite often the work of the computer scientist is exploratory. We set off on a track. We try something; It does not work. We debug. Or we discover that we can do better, cleaner. And we don't want to spend our lives rewriting the history of the repository, or leaving every little bit of exploration forever.

Life is Beautiful. Git is really made for that. As I told you at the very beginning, Git allows us to work on several versions of its code at the same time. Good practice is never to work directly on **master**. And obviously never rewrite the past of **master** (or any other branch that we have shared with others).

## Collaborate with yourself. Branches and their structures.

Whenever we are going to start working on a new feature or fixing a bug, we have every interest in creating a new branch. This will be our exploratory workspace where we will make our successive changes. When we are happy with our changes we could simply reintegrate it into the "main trunk".

How to create a branch?

### Create branches

The `git checkout` command that we have already seen allows us not only to get on another commit.. but also to create a new branch.

```console
git checkout -b my_new_feature
```

This creates a new branch starting from the commit our **HEAD** points to, and switches to it. Git tells us so:

```console
Switched to a new branch 'my_new_feature'
```

> :information_source:
> Since Git 2.23 there is a second, clearer way to say the same thing: `git switch -c my_new_feature`. As we mentioned in the previous chapter, `git checkout` was split into `git switch` (move between branches) and `git restore` (put files back), precisely because doing both jobs with one command was a famous source of accidents. We keep using `checkout` in this course because it is what you will see in every existing tutorial, every Stack Overflow answer and every colleague's terminal — but `switch` is the better habit.

But we like to understand what's going on under the hood.. don't we. Let's take a look at our `.git` directory.

```
.
...
├── HEAD
...
├── logs
│ ├── HEAD
│ └── refs
│ └── heads
│ ├── master
│ └── my_new_feature
...
└── refs
    ├── heads
    │ ├── master
    │ └── my_new_feature
    └── tags
```

Our HEAD has changed. If we look inside with a `cat .git/HEAD` it says: `ref: refs/heads/my_new_feature`, before it said `ref: refs/heads/master`.... and that is is a shortcut, a link, a pointer to another small file that just appeared.

Under `.git/refs/heads` appears `my_new_feature`. A look inside: `cat refs/heads/my_new_feature` tells us `120539df2817da4656c85af54061b06e15ae4b38`. So "HEAD" lets us know the "current commit". When it contains a reference like `refs/heads/my_new_feature` it means we are on top of a branch called `my_new_feature`.

When our **HEAD** contains a **hash** then we are in this "detached head" situation that we have already seen, when it contains the reference of a branch... it will move with the top of this branch. So if we now add a **commit** on the `my_new_feature` branch, our **HEAD** will remain synchronized with it and it will point to our new **commit**.

> :warning: we are allowed to put a lot of stuff in branch names. But I very strongly suggest you stick to alpha numeric with always lowercase characters with `-`, `_`, `/` and `.` as extra characters at most. We have already noted that one of the advantages of Git is that it can be integrated into a lot of automation. The more baroque you are in your choice of names, the more likely you are to have something break. You can use unicode. You can use Emojis. But it's a bad idea.

## Jump from branch to branch `git checkout {branch_name}`

Nothing simpler `git checkout master` will allow us to return to our main branch. Then `git checkout my_new_feature` and hop back to our new branch.

## But if I made changes, then changed branches, what happens?

You can only be in one of two states. Either we have already made **commits**, or not.

### We made a commit before changing branches

If we made a change, and we applied it by doing a **commit** before changing branch: we arrive on the new branch and our work area is updated (we will not see this therefore change).

### We didn't commit before changing branches

If we made a change but didn't apply it with a commit:

1. Either no other changes have been made to the same files.. and then Git will update the work area for what hasn't changed. Our modifications are still going to be there.
2. Either on both branches there have been changes to the same files (so we made a **commit** in the other branch on one of the files) that we have touched and Git will complain. It will tell us "Hey! if you want to change branches you must first either do a `git commit` or a `git stash`".

> :information_source:
> We won't see everything right away; But be aware that `git stash` is a very useful command. Sometimes we're in the middle of work, we haven't committed anything yet. And we want to go see what's happening on another branch. `git stash` allows us to save the current state of our work area and clean it up. It's kind of like the `git reset` we've seen before.. except that this command doesn't destroy anything. It places our changes in a buffer zone (much like the "clipboard"). We can now look elsewhere, even make commits to other branches... then come back to ours, do a little `git stash pop` our work area will again have the changes that were running. We can imagine it as a "temporary commit".


## How do we track our branch changes? `git reflog`

The **Reflog** is a mechanism to log when branch tips are updated. And the `reflog` command allows you to manage the information stored there. Basically every time our **HEAD** changes, every time we add a **commit** to a branch and therefore this branch points to a new commit, Git saves these changes.

> :warning: you're going to get tangled up more than once learning Git...especially when you start using more advanced commands. Whenever you are lost... remember: a `git reflog` will often explain what happened.

In our case `git reflog` will give us the full history of everything we've done so far:

```console
f8aeebe HEAD@{0}: commit: Add media directory with .gitkeep
94e2c27 HEAD@{1}: commit: Add git log to the list of commands we learned
46079d2 HEAD@{2}: reset: moving to 46079d29e5c812f3141e2e5a2522c6a5871d2255
230e18f HEAD@{3}: checkout: moving from 2937bccec42553482636326d6d60c5dcd1fe938d to master
2937bcc HEAD@{4}: checkout: moving from master to 2937bccec42553482636326d6d60c5dcd1fe938d
230e18f HEAD@{5}: commit: added git log command
2937bcc HEAD@{6}: commit: Rename files to media
f2c06df HEAD@{7}: commit: Remove license file
f0bb8a2 HEAD@{8}: commit: Add .gitkeep so files will be added to the repository
5ab2cae HEAD@{9}: commit: Adding a license file
46079d2 HEAD@{10}: commit: Add the list of commands we learned today.
d2eafda HEAD@{11}: commit (initial): Added readme.md
```

Read it from the bottom up and you have an honest diary of the whole previous chapter, including the parts we tidied away: the seven commits, the excursion into a **detached head** at `HEAD@{4}` and the way back at `HEAD@{3}`, the `reset` at `HEAD@{2}` that threw five of those commits off the branch, and the two replacement commits we made afterwards.

Look carefully at `HEAD@{5}`: `230e18f`, "added git log command". That commit is not on any branch any more — we reset past it. It is not in `git log`. And it is still right there, named, one command away. **Nothing we did was silently lost.**

> :information_source:
> Every ref has its own reflog, not just **HEAD**. `git reflog show master` tells you the history of where the `master` branch pointer has been. The files are plain text under `.git/logs/` — go and `cat .git/logs/HEAD` if you don't believe us.
>
> The reflog is also the one part of Git that expires. By default unreachable entries are pruned after 30 days and reachable ones after 90 (`gc.reflogExpireUnreachable`, `gc.reflogExpire`). So the reflog is a superb safety net for last week's disaster and no help at all for last year's.

## Listing branches

Before going further, the command that tells us where we are:

```console
git branch -vv
```

```console
  master        f8aeebe Add media directory with .gitkeep
* shopping_cart f8aeebe Add media directory with .gitkeep
```

The `*` marks the branch we are on. `-vv` also shows the last commit of each branch and, once we have a remote, which remote branch it is tracking.

## The shape of branches

Here we should correct something, because the language people use about branches is misleading and it causes real confusion later.

You will constantly hear that branches are "hierarchical", that one branch is "under" another, that `master` is "the root". Set that aside. **A branch is a name for one commit, and nothing else.** There is no field in Git that records "this branch descends from that branch". Once you create a branch you can move it anywhere; the name remembers nothing about where it came from.

What *is* a graph — a directed acyclic graph, to be precise — is the history of **commit**s, because every commit points at its parents. That graph is real, and it is where "descends from" genuinely means something.

So when we draw a diagram like the one below, we are drawing two things at once: a set of branch names, and the commit graph they happen to point into. It is a useful picture. Just don't mistake the indentation for something Git stores.

Let's see an example scenario, let's imagine we are creating an ecommerce website, and we start working on the shopping cart. Then in a sub-branch we start working on its HTML template. This work is in progress, and in the meantime we want to come back to work on our homepage.

Start working on the `shopping_cart` branch, from `master`:

```console
git checkout master
git checkout -b shopping_cart
```

Clack... clack... clack, code... code... code... let's create the files and commit our changes, then branch again for the template:

```console
mkdir -p lib
touch lib/shopping_cart.js
git add lib
git commit -m 'Initial shopping cart code'
git checkout -b shopping_cart_template
```

> :warning:
> Careful with the `-a` shortcut here. `git commit -am '...'` only picks up files Git is already tracking. Our brand new `lib/shopping_cart.js` has never been added, so it is **untracked**, and `-a` will cheerfully ignore it — you would end up with an empty commit and a confusing error. New files always need an explicit `git add` first. This one catches everybody.

Clack... clack... clack, code... code... code... commit, then back to master to start on the homepage:

```console
mkdir -p views
touch views/shopping_cart.html
git add views
git commit -m 'Implement shopping cart template'
git checkout master
git checkout -b homepage
```

We started from `master`, branched `shopping_cart` off it, branched `shopping_cart_template` off *that*, then came back to `master` and branched `homepage`. Drawn as a family tree, our four branch names sit in the commit graph like this:

```
master
├── shopping_cart
│   └── shopping_cart_template
└── homepage
```

And here is the same thing as Git actually sees it — four names, each pointing at one commit:

```console
git branch -vv
```

```console
* homepage               f8aeebe Add media directory with .gitkeep
  master                 f8aeebe Add media directory with .gitkeep
  shopping_cart          57563d2 Initial shopping cart code
  shopping_cart_template 10913e8 Implement shopping cart template
```

Notice that `homepage` and `master` point at the *same* commit. We created the branch and have not committed to it yet, so there is genuinely nothing to distinguish them. A branch costs Git 41 bytes and no thought whatsoever.

That is the whole of it: a branch is a synonym for a **commit**, and committing on a branch means "move this name forward to the new commit". You can watch it happen by looking inside `.git/refs/heads/`.

## Apply changes from one branch to another. Git **merge**.

The Git `merge` command allows you to apply a change-set from one branch to another. 

So, you did the shopping cart logic in one branch `shopping_cart`, and the design in another, in our example `shopping_cart_template`. To have a functional shopping cart we will need both changes. So we are going to bring everything from the second branch to the first.

> :information_source:
> For simplicity we will imagine that in each set of commits you touched different files. We will see later what happens when the same files were changed in two different branches. To make sure we don't immediately get into trouble (and later, we will), let's first check that our work is actually committed. Our good friend `git status`.

```console
git checkout shopping_cart
git status
```

```console
On branch shopping_cart
nothing to commit, working tree clean
```

Now let's verify what this branch is pointing at. We have already seen the `git log` command; `git log -1` shows only the most recent **commit** of the current branch.

```console
commit 57563d230b3b552922e00c626159272cca683837
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:46:00 2026 +0100

    Initial shopping cart code
```

It is telling us our **HEAD** is pointing, as expected, at the reference of the `shopping_cart` branch, which currently sits at commit `57563d2`.

So, we are on the `shopping_cart` branch. If we issue the command `git merge shopping_cart_template`, Git will do some very intelligent things and apply all the changes we made in that second branch to this one.

Type the command and you should see:

```console
git merge shopping_cart_template
```

```console
Updating 57563d2..10913e8
Fast-forward
 views/shopping_cart.html | 8 ++++++++
 1 file changed, 8 insertions(+)
 create mode 100644 views/shopping_cart.html
```

Some very interesting things just happened. Let's figure them out. As we learned, **commit**s have parents and **branch**es are references to **commit**s. Git says it updated `57563d2` to `10913e8`. It also says it **Fast-forward**ed, which we will come back to in a second. And then it tells us what actually changed: it created `views/shopping_cart.html`, as expected. Our working area now has it (with `tree -C`):

```console
.
├── lib
│   └── shopping_cart.js
├── media
├── readme.md
└── views
    └── shopping_cart.html
```

And the graph makes the whole situation clear at a glance:

```console
git log --oneline --graph --decorate --all
```

```console
* 10913e8 (HEAD -> shopping_cart, shopping_cart_template) Implement shopping cart template
* 57563d2 Initial shopping cart code
* f8aeebe (master, homepage) Add media directory with .gitkeep
* 94e2c27 Add git log to the list of commands we learned
* 46079d2 Add the list of commands we learned today.
* d2eafda Added readme.md
```

Look carefully at three things. `shopping_cart` and `shopping_cart_template` now point at the *same* commit. **HEAD** points at `shopping_cart`. And the history is a single straight line — there is not a fork anywhere in that picture, because Git did not create one.

This was the simplest possible scenario. `shopping_cart_template` was **branch**ed out of `shopping_cart`, and nothing else happened on `shopping_cart` in the meantime, so the second branch's history already contained the first's entirely. Git therefore had no merging to do at all. It just moved a pointer: it set the **tip** of `shopping_cart` to the tip of `shopping_cart_template`. That is what a **fast-forward** is, and it is why no merge **commit** appears and why the graph stays flat.

> :warning:
> This is the first time in this course where we are not going to tell you the whole truth. Although `merge` is one of the commands you will use most often, building a real, detailed understanding of what it does is genuinely **complicated** — and a fast-forward is precisely the case where it does almost nothing. In [Implement an efficient collaborative workflow](5-git-workflow.md "Implement an efficient collaborative workflow") we pay this debt in full: the merge base, the three-way merge, real merge commits with two parents, and conflicts. For now, know that you have seen the easy case, and that it flattered Git considerably.

## Summary, branches

* **A branch is a name for one commit.** Nothing more. It records nothing about where it came from — the **commit** graph does that.
* `git branch -vv` lists the branches, marks the current one with `*`, and shows the commit each points at.
* `git checkout -b branch_name` creates a new branch at the **commit** our **HEAD** points to, and switches to it. The modern spelling is `git switch -c branch_name`.
* `git checkout branch_name` switches branches, updating **HEAD** and our working area. Modern spelling: `git switch branch_name`.
* `git stash` sets aside the uncommitted changes in our working area, leaving it clean; `git stash pop` brings them back.
* `git reflog` shows every move **HEAD** has made — the single most useful command for when you are lost.
* `git merge` brings the changes of one branch into another. When the target's history already contains ours, it does so by simply moving a pointer: a **fast-forward**.
