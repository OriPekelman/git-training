---
title: Playing with our revisions
url: "/docs/play-with-git-revisions/"
weight: 7
---
# Playing with our revisions

Now we have learned how to create versions of our code. Did you change a file? We type `git commit -am'Added some CSS styles for header'`. Here is a new revision just created.

## View list of revisions: `git log`

We can now type `git log`; this very useful command lists all the changes in order, the most recent first.

```console
commit 2937bccec42553482636326d6d60c5dcd1fe938d (HEAD -> master)
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:25:44 2026 +0100

    Rename files to media

commit f2c06df5e0a310f2f4689f9d0dc3edfddf237d4c
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:22:10 2026 +0100

    Remove license file

commit f0bb8a21c920246672cf67119d2fc42ba8e5bb18
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:17:22 2026 +0100

    Add .gitkeep so files will be added to the repository

commit 5ab2caec01348fa809286b406298889992680ed0
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:15:42 2026 +0100

    Adding a license file

commit 46079d29e5c812f3141e2e5a2522c6a5871d2255
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:10:30 2026 +0100

    Add the list of commands we learned today.

commit d2eafda3f0b5660fd33b0db429d2f5e447c4cd28
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:06:51 2026 +0100

    Added readme.md
```

Here we have a nice list of everything that happened, all six commits we have made since the beginning. And if we look closely there is nothing there that should surprise us... **commit** and its **sha** then the author and finally the date and our commit message. Only one thing got added there, in the first line: **(HEAD -> master)**. We'll explain that a bit below. For now let's continue...

> :information_source:
> `git log` pipes its output through a pager (usually `less`), so on a long history you scroll with the arrow keys or the space bar and quit with `q`. If that surprised you the first time, you are in excellent company.

What if we modify `readme.md` to reflect what we just learned? You can open your favorite text editor and edit `readme.md`; I will still use the command line to add the line.

```console
printf '\n5. `git log` view all revisions\n' >> readme.md
```

The `>>` (rather than `>`) appends instead of overwriting — a distinction worth getting right the first time rather than the second.

And again we will add a small commit:

```console
git commit -am'added git log command'
```

Cool. It will continue to work. Now if I type `git log` again I will see at the top of the list my new commit:

```console
commit 230e18f7b7070cd33c94e7a2a8aaa532473007af (HEAD -> master)
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:31:09 2026 +0100

    added git log command
```

So now we've already done a lot of stuff in our little Git repository. We work on a single branch: **master**. Each time we added a **commit**, our **index** was updated. And **HEAD**, this pointer to our work area, was pointing to the most recent **commit**.

![Moving Head](/images/moving_head/moving_head.gif "HEAD advancing with each new commit")

<!-- TODO: this animation was recorded on an older run of the scenario; its hashes and the order of two commits do not match the walkthrough above. Re-record it against the current scenario. -->

(That little animation was recorded on an earlier run of this same walkthrough, so its hashes are not the ones you see above. Watch the highlighted line move, not the digits.)

## Change Tracking

So we learned how to create a Git repository with `git init` then add files to it with `git add` and commit them with `git commit`.

We understood how to save successive changes: Each time I make a set of consistent changes.

> :information_source:
> For example if I'm working on the shopping cart of my e-commerce site, maybe I changed the template and adjusted the CSS, which together do one piece of work that makes sense... I'll do something like `git add views/shopping_cart.html public/styles/shopping_cart.css` then `git commit -m'Add pretty red button to shopping cart ticket #654'`.

Later I might even go back in time and see the state of things before I made this change.

But how do you see what has changed?

## `git diff` to see what changed

So back to our repository: remember our last change was to add a line to `readme.md`. The `git log` command gives us the list of changes, doesn't it? The penultimate commit is **2937bcc** and we can now see what has changed since then.

The command:

```console
git diff 2937bcc
```
Will tell us something like:
```console
diff --git a/readme.md b/readme.md
index 0c7e166..8457b88 100644
--- a/readme.md
+++ b/readme.md
@@ -6,3 +6,5 @@ Today we learned the following Git commands:
 2. `git status` - find out the status of the working directory relative to the git repository
 3. `git add` - add files to the git index to prepare for a commit
 4. `git commit -m"{commit message}"` - save a milestone in the git repository
+
+5. `git log` view all revisions
```

Basically it gives us the result of the `diff` command to calculate the difference between two files. Here we can see that we have added a line break and then a line of text.

The `@@ -6,3 +6,5 @@` is the **hunk header** we met in [Inside the repository, inside the commit](5-inside-git.md "Inside the repository, inside the commit"): three lines starting at line 6 in the old file became five lines starting at line 6 in the new one. Note the commas — `-6,3` is "3 lines from line 6", not a decimal number. What follows the closing `@@` is just Git being helpful: the nearest enclosing heading, so you know where in the file you are.

> :information_source:
> Git, unlike other version control systems, does not keep a chain of changes... but real snapshots of each file. When we see the "diff", the difference between two states of a file, it calculates that on the fly. But as we noted above, Git knows how to be very smart and pack things well: the **pack** format is a remarkably clever and awfully optimal thing, and by the way it's one of the reasons why Git is so fast. This is an internal implementation detail that has no effect on your use of the tool, and therefore outside the scope of this course: we go as deep as necessary to understand what we are doing, precisely — but not deeper.

## `git diff --cached` to see what was added to the index

Once we have added things to the index, to our **staging**, `git diff` won't tell us anything. If you want to see changes that are ready to **commit**... `git diff --cached` is our friend.


## The differences with the last commit...

We've seen how to use `git diff` with the **SHA** of a revision, but Git also provides us with a nice syntax for talking in relative terms. For example `git diff HEAD~1` is a way of saying: give me the **diff** with the previous commit — the penultimate one. `git diff HEAD~2`, you will have guessed, shows us the difference with the one before that, two steps back. This is much handier than copying hashes around, and it is what you will type nine times out of ten.

## How do I know when a change has been introduced? `git blame`

Quite often when we read code we are not sure we understand everything. We see a line. And you wonder.. but why, why oh gods, did I do this? Git remembering everything can help us.

If `git diff` tells us the difference between two commits, and `git log` gives us the list of all the commits... `git blame` can tell us for a file at a specific **commit**, when and why each line has been added or modified.

```console
git blame readme.md
```

```console
^d2eafda (Ori Pekelman 2026-02-02 06:06:51 +0100  1) # My first Git project
46079d29 (Ori Pekelman 2026-02-02 06:10:30 +0100  2) 
46079d29 (Ori Pekelman 2026-02-02 06:10:30 +0100  3) Today we learned the following Git commands:
46079d29 (Ori Pekelman 2026-02-02 06:10:30 +0100  4) 
46079d29 (Ori Pekelman 2026-02-02 06:10:30 +0100  5) 1. `git init` - initialize a new git repository
46079d29 (Ori Pekelman 2026-02-02 06:10:30 +0100  6) 2. `git status` - find out the status of the working directory relative to the git repository
46079d29 (Ori Pekelman 2026-02-02 06:10:30 +0100  7) 3. `git add` - add files to the git index to prepare for a commit
46079d29 (Ori Pekelman 2026-02-02 06:10:30 +0100  8) 4. `git commit -m"{commit message}"` - save a milestone in the git repository
230e18f7 (Ori Pekelman 2026-02-02 06:31:09 +0100  9) 
230e18f7 (Ori Pekelman 2026-02-02 06:31:09 +0100 10) 5. `git log` view all revisions
```

Here we can see that the very first line was added in the initial commit (that is what the `^` marks: the line has been there since the beginning of history). Then we have two more commits. We can thus go back in time... and understand precisely the why and the how.

> :warning:
> Watch the case of the filename. Our file is `readme.md`, lowercase. `git blame README.md` will appear to work on macOS and Windows, because their filesystems are case-insensitive by default, and will fail on Linux — and on your colleague's CI. Git itself always cares about case. Type the name the way the file is named.

## `git show` to see the contents of the commit

We can now watch a particular commit with the `git show` command and see when the change was introduced.

```console
git show 230e18f
```

```console
commit 230e18f7b7070cd33c94e7a2a8aaa532473007af
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:31:09 2026 +0100

    added git log command

diff --git a/readme.md b/readme.md
index 0c7e166..8457b88 100644
--- a/readme.md
+++ b/readme.md
@@ -6,3 +6,5 @@ Today we learned the following Git commands:
 2. `git status` - find out the status of the working directory relative to the git repository
 3. `git add` - add files to the git index to prepare for a commit
 4. `git commit -m"{commit message}"` - save a milestone in the git repository
+
+5. `git log` view all revisions
```

> :information_source: the `git show` command is very useful, it can show us only the content of a **commit** but also of a **tree** or a **blob**

If you use the command with no arguments it will show you the very last commit. The one at the tip of your **master** branch. But without even doing `git log` Git gives us very useful shortcuts to talk about a commit without knowing its **SHA**.

 * `git show HEAD^` - the little hat allows us to reference the parent of our commit. So the previous commit.
 * `git show HEAD^^^` - we can add multiple. Here we will see the great-grandparent of our commit;
 * `git show HEAD~10` - but if we don't want to have ten little hats... the tilde `~` does the same thing but followed by a number. Here we will see what happened ten commits ago.

Let's imagine that we have taken a wrong turn. Or that we just want to know what happened in one of our commits. As we have already seen the `git log` command allows us to see the list of changes. Who did what when and why. And `git checkout` allows us to go and take a past commit and set our work area to the state of that commit.

## Getting to a past state with `git checkout`

Now imagine that we want to go back in time before we made this change.

Nothing could be simpler: in the log I will look at the **SHA**, the hash of the previous commit, and I can now type:

```console
git checkout 2937bcc
```

Its response is going to be a bit wordy, so let's ignore the middle for now and just look at the first and last line:

```console
Note: switching to '2937bcc'.
    # [blah blah blah blah Git tries to be super helpful]
HEAD is now at 2937bcc Rename files to media
```

We have returned to the past. If we type `cat readme.md` we will see our file as it was before we added point 5.

> :information_source: **`git checkout` does two completely different jobs, and that is a famous trap.**
> `git checkout <branch>` moves you to another branch. `git checkout -- <file>` throws away your uncommitted changes to a file. One is navigation, the other is destruction, and they are the same word — which is exactly why people have destroyed work they meant to keep.
> Since Git 2.23 the two jobs have their own commands. That is the whole reason for the split: `checkout` had accumulated two unrelated behaviours under one name, one of them harmless and one of them irreversible, and nothing in the command line told you which one you had asked for. Here they are separated:
> * `git switch master` — go to a branch.
> * `git switch -c new-feature` — create a branch and go to it (`-c` for *create*, where `checkout` used `-b`).
> * `git switch --detach 2937bcc` — go to a specific commit, deliberately detaching (see below).
> * `git restore readme.md` — discard uncommitted changes to a file.
> * `git restore --staged readme.md` — unstage a file, keeping the changes.
>
> We keep teaching `checkout` in this course, because `checkout` is what you will see in every tutorial, every Stack Overflow answer and every colleague's shell history for years to come, and because it still works exactly as described. But now you know the modern split — and, more importantly, you know *why* it exists.

And we can type `git log` again to see.

**Gee**! Indeed we are in the previous state and our last commit has completely disappeared. Is it a good time to panic? No. You should never panic.

The command:

```console
git log --branches
```

> :information_source:
> Git is a big beast: for each command there are sometimes dozens of different options. We will, of course, only see the main things.

So `git log --branches` will show us that we haven't lost anything. And in addition we will see some additional interesting information.

```console
commit 230e18f7b7070cd33c94e7a2a8aaa532473007af (master)
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:31:09 2026 +0100

    added git log command

commit 2937bccec42553482636326d6d60c5dcd1fe938d (HEAD)
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:25:44 2026 +0100

    Rename files to media

commit f2c06df5e0a310f2f4689f9d0dc3edfddf237d4c
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:22:10 2026 +0100

    Remove license file

commit f0bb8a21c920246672cf67119d2fc42ba8e5bb18
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:17:22 2026 +0100

    Add .gitkeep so files will be added to the repository

commit 5ab2caec01348fa809286b406298889992680ed0
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:15:42 2026 +0100

    Adding a license file

commit 46079d29e5c812f3141e2e5a2522c6a5871d2255
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:10:30 2026 +0100

    Add the list of commands we learned today.

commit d2eafda3f0b5660fd33b0db429d2f5e447c4cd28
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:06:51 2026 +0100

    Added readme.md
```

Indeed `git log` by default shows us the past of the point at which we are. Nothing has been lost. Here is the **log** which is the same thing.. except for one small detail: where at the top we had **(HEAD -> master)**, now **230e18f** is marked as **master** and **2937bcc** as **HEAD**. What is that about?

**HEAD** is a pointer to where we are now. We were on commit **230e18f** and now our work area is in the past, on **2937bcc**.

If we now do `git checkout master` the **HEAD** pointer will once again position itself on our very last commit, the one with the message "added git log command". We can check it with `git log` or `git log --branches` (which there, therefore, will do precisely the same thing).

But it's weird, we learned to do `git checkout {sha}` and now instead of putting lots of weird characters we write in full **master**.

So what is **master**? **master** is a branch. As we already told you in the introduction, with Git we can work not only on revisions as a single time arrow... but on multiple different versions, at the same time. **master** is, as its name suggests, the master version, the top of the tree. A bit later we'll show you how to create more branches, how to use `git checkout` to jump from one to another; for now let's stick with one trunk.

> :information_source:
> In other version management systems, such as the venerable CVS or SVN, this master branch was indeed called "Trunk" which gives the image of this main branch of which all the others come out. For Git, it's a simplification, it's so powerful and malleable that this concept is reductive ... but here we go, we're not going to complicate our lives too much right now. So imagine **master** as the main trunk.

### `master` or `main`?

Remember that chatty message Git printed way back when we ran `git init`? Here it is again, in full:

```console
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint:
hint: 	git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint: 	git branch -m <name>
```

There is nothing magic about the name `master`. It is a branch like any other; Git only treats it specially in the sense that `git init` picks it as the name of the first one. Around 2020 the industry moved to `main` instead, for cultural reasons, and today GitHub and GitLab both create new repositories with `main`. Git itself has not changed its default — partly because changing it would break an enormous number of scripts — but it now nags you until you make a choice.

Make the choice:

```console
git config --global init.defaultBranch main
```

From then on, every repository *you* create starts on `main`, the hint goes away, and you are aligned with what the hosting services do. Existing repositories are unaffected; to rename the branch in one of them, `git branch -m master main` (and if it has a remote, you will need to tell the remote too — we come back to that when we talk about collaboration).

We keep saying `master` for the rest of this course, because that is what our example repository actually has. If you configured `main`, read every `master` below as `main`; nothing else changes.

As with **HEAD** a branch is simply a pointer to a **commit**. And often the **HEAD** points to the top of the branch we are on. As we are on the **master** branch, **HEAD** points to the "top" of it. Our latest commit.

We like to look under the hoods don't we? let's look at a few other data structures inside our dear `.git` to be sure we understand.

Make sure you have done `git checkout master` and we can try the following commands

```console
cat .git/HEAD
```
Who will take us out:

```console
ref: refs/heads/master
```
So this is a reference, pointing to `refs/heads/master` -- that stuff is also a file under `.git`. We can follow the trace and type:

```console
cat .git/refs/heads/master
```

And it will respond to us with the **SHA**, the **commit-id** of our very last commit:

```console
230e18f7b7070cd33c94e7a2a8aaa532473007af
```

Forty-one bytes in a plain text file. That is all a branch is.

> :information_source:
> On a repository with a lot of branches and tags, you may find `.git/refs/heads` almost empty and a file called `.git/packed-refs` instead. Git periodically packs its references into that single file to avoid keeping thousands of tiny ones. Same information, denser storage. The command `git rev-parse master` gives you the answer either way, and is what you should use in a script.

Earlier when we did `git checkout 2937bcc`, Git gave a big message that we chose to ignore. Let's read it now:

```console
Note: switching to '2937bcc'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 2937bcc Rename files to media
```

That's what it's telling us: hey, you've chosen to do a `checkout` not on the top of a branch, but on a specific **commit**. **HEAD**, the head, the pointer of the current state, is now "detached" from its branch — the famous **detached head**.

Note that Git's own advice here talks about `git switch`, not `git checkout`. Git nudges you toward the new commands even when you used the old one.

> :information_source: we can do `git checkout {the-name-of-a-branch}` because the branch is just a pointer to a **commit**, so `git checkout master` takes us back to the top of our tree, to our last **commit**.


## Did we really go wrong? Start clean with `git reset`

We were able to go back already in the past with `git checkout` which put our work area in the state of a previous commit. But then we were in this kind of weird state. The **detached head**, or HEAD, was no longer pointing to the top of our branch. If we wanted to we could go back in time so that we could go on again.

Let's imagine for example that all this dithering around the name of our `media` directory is messing up our history, that it brings no value to the future reader of our code. Or the fact that we added the LICENSE file just to remove it later?

Our current history — this time with a compact one-line-per-commit format, which is how you will usually want to look at it:

```console
git log --graph --pretty=format:'%h - (%ad) %s - %an%d' --date=short
```

```console
* 230e18f - (2026-02-02) added git log command - Ori Pekelman (HEAD -> master)
* 2937bcc - (2026-02-02) Rename files to media - Ori Pekelman
* f2c06df - (2026-02-02) Remove license file - Ori Pekelman
* f0bb8a2 - (2026-02-02) Add .gitkeep so files will be added to the repository - Ori Pekelman
* 5ab2cae - (2026-02-02) Adding a license file - Ori Pekelman
* 46079d2 - (2026-02-02) Add the list of commands we learned today. - Ori Pekelman
* d2eafda - (2026-02-02) Added readme.md - Ori Pekelman
```

Make sure you are back on the branch (`git checkout master`) before what follows. Then:

```console
git reset 46079d2
```

This resets **HEAD** to that commit, and — unlike `git checkout` — it drags the branch **master** back with it. But our work area is left exactly as it is. Git tells us as much:

```console
Unstaged changes after reset:
M	readme.md
```

and a `git status` will tell us:

```console
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   readme.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	media/

no changes added to commit (use "git add" and/or "git commit -a")
```

Everything we actually *wanted* is still on disk: the readme with its five items, and the `media` directory. The four commits in between are what we threw away. We can now create new **commit**s, clean:

```console
git add readme.md
git commit -m'Add git log to the list of commands we learned'
git add media
git commit -m'Add media directory with .gitkeep'
```

Now our history is much cleaner:

```console
* f8aeebe - (2026-02-02) Add media directory with .gitkeep - Ori Pekelman (HEAD -> master)
* 94e2c27 - (2026-02-02) Add git log to the list of commands we learned - Ori Pekelman
* 46079d2 - (2026-02-02) Add the list of commands we learned today. - Ori Pekelman
* d2eafda - (2026-02-02) Added readme.md - Ori Pekelman
```

Notice that the two oldest commits kept their hashes — `d2eafda` and `46079d2` are untouched, we never rewrote them — while everything after the reset point is brand new. A commit-id depends on its parent, so rewriting history necessarily gives every descendant a new identity. Remember that; it is the whole reason the warning below matters.

In this case we wanted to roll back to a previous state while keeping the changes we made. But what if we really want to get rid of our last few commits? We can do a hard reset with `git reset --hard`.

Thus `git reset --hard d2eafda` will bring us back to our initial state, with a single `readme.md` file which will have a single line of content. Sometimes it's nice to get rid of the weight of the past.

> :warning:
> `git reset --hard` is one of the very few Git commands that genuinely destroys work: any change in your working directory that you had not committed is gone, with no `git` command that will bring it back. Committed work is recoverable for a while — `git reflog` remembers where **HEAD** has been, so `git reset --hard` to a commit-id you find there undoes the damage — but uncommitted work is not in Git at all, and so Git cannot help you. Commit before you experiment.

> :warning: We're going to talk about collaboration further on, but let's note something right away. When we work alone, on a repository of our own, on a branch of our own, rewriting the past is pleasant and useful. But when we start working with others we won't have the same luxury: the commits your colleagues have already pulled must keep their identity, and as we just saw, a reset gives every descendant commit a new one. The past is the past. We have other Git commands that allow us to undo things while keeping a common history, like `git revert`, which we will see later.

## Summary view of playing with history

* `git log` allows us to see the list of **commit**s in the past, the list of revisions
* `git diff` allows us to see the changes introduced in a **commit**
* `git blame` allows us to inspect a file and see which line was modified by which **commit**
* `git show` allows us to inspect a **commit**, but also a **tree** or a **blob**
* **master** is a branch of our code, the one `git init` creates; `git config --global init.defaultBranch main` makes new repositories start on **main** instead, which is what GitHub and GitLab do
* **detached head** is the situation where our **HEAD** pointer is not pointing to the last commit of a branch
* `git checkout {commit}` moves the **HEAD** pointer to a specific **commit** and resets our working directory to the state it had at the time of that commit
* `git switch` and `git restore` (Git 2.23+) split `git checkout`'s two jobs in two: `git switch` changes branch or commit, `git restore` puts files back
* `git reset {commit}` moves **HEAD** like `git checkout` does, but also drags the tip of our **branch** back to that commit, keeping the changes in our working directory
* `git reset --hard {commit}` does the same while throwing away all our uncommitted changes in the working directory