---
title: Inside the repository, inside the commit
slug: "inside-git"
weight: 5
---
# Inside the repository, inside the commit

The **commit** is the most interesting object of Git, our main tool to build a history of our code, to name versions, to collaborate with others.

Each time we type the command `git commit` we create a new record, a new stage point.

## But what exactly is a **commit**?

To fully understand **commit** we need to take a small detour and encounter two other concepts. The **blob** which is the content of our files and the **tree** which are the successive tree structures of files.

To understand, let's embark on a new journey into the bowels of the beast. What is in our hidden `.git` directory now — and specifically, in its `objects` subdirectory?

```console
tree .git/objects
```

Which gives us:

```console
.git/objects
├── 0b
│   └── a5adce31cb9cf9951fed3075d7571a9db5bc32
├── 0c
│   └── 7e1663dd99931898dfa9e25dfd2aba94dbe9ad
├── 38
│   └── 36229b5ce7fd362c59974d286de92bf5191784
├── 46
│   └── 079d29e5c812f3141e2e5a2522c6a5871d2255
├── 5a
│   └── b2caec01348fa809286b406298889992680ed0
├── 83
│   └── 2e299281e32ed167f389f4b34501ec48b302c0
├── 89
│   └── 69130a4c5a09759ca1f60b161a8805edf26042
├── d2
│   └── eafda3f0b5660fd33b0db429d2f5e447c4cd28
├── f1
│   └── 2dd321865c1b55cd32d413e8ef51b6c4ee7741
├── info
└── pack

12 directories, 9 files
```

wow! lots of things. We only added two files, and yet there are 9 objects in the **objects** sub-directory. Interesting! Let's study.

> :information_source:
> As we warned in the previous chapter, the three commit hashes below are mine and yours will differ, because your name, your email and the second at which you committed all go into the commit. The **blob** hashes, on the other hand — the ones for `readme.md` and `LICENSE` — depend only on the file contents, so if you typed what we typed, they match.

Actually in **objects** Git will put _all_ things it will handle:
first our compressed "readme.md" (now we even have two versions of it) as well as our "LICENSE" — this type of object is called a **blob** (in English Binary Large Object).

## Blobs

A "**blob**" can represent a source code file, an image, anything. As we made a change to "readme.md" it will be represented twice. One for each version.

> :information_source:
> As we said the object's name is now something that represents its content. If we have 10 files that have the same content, Git will save them only once under a single name. To better read our **sha**s, often, instead of referencing the 40 characters, we will take the first 7. That's enough for us to properly identify them.. and it remains unique in almost all cases. So instead of talking about `0ba5adce31cb9cf9951fed3075d7571a9db5bc32` we will most often talk about `0ba5adc`.

So the filename... where did it go?

## **Tree**s and **Commit**s

In the same Git directory another type of object:

* **tree** type objects - these will contain our file names, and reference the **blob** type objects that will have the content of these files, as well as the rights attached to them.

Now the filenames of all these objects under `.git/objects` look the same (these are all things whose filename is a "hash"). Just looking at this list of files you can't tell them apart, but inside, the **commit**s, the **tree**s and the **blob**s have different formats.


## View objects with `git show`

`git show` is a very handy command, you give it a git object of any type and it shows the contents. Let's use it to discover the trees. We can use it to see our **blob**s, but also our **commit**s and our **tree**s.

### Inside the **tree** - our tree structure

Among our nine objects, the one called **8969130** is a tree structure, a "**tree**":

```console
git show 8969130
```

The result of the command is very simple:

```console
tree 8969130

LICENSE
readme.md
```

Here **8969130** is simply a list of files. We have two here. But we've gotten used to digging a little deeper... so we'll use a lower level command that will give us much more detail, `git ls-tree`:

```console
git ls-tree 8969130
```

And here is our much more detailed result:

```console
100644 blob 0ba5adce31cb9cf9951fed3075d7571a9db5bc32	LICENSE
100644 blob 0c7e1663dd99931898dfa9e25dfd2aba94dbe9ad	readme.md
```

The real content of the **tree** has not just the filenames but four fields:

```
{filemode} {type} {sha} {filename}
```

* **filemode** - this is the metadata about the file as it is on the filesystem. Here for example, *100644* represents a regular non-executable file. If we had *100755* it would have been a file with execute rights, *120000* would have been a symbolic link and *040000* a directory (if these terms are unfamiliar to you, look up "Unix file permissions" and `chmod`) but, let's move on, this is not very important for the moment. Note that Git stores far less than the filesystem does: it records only whether a file is executable, and nothing else — not the owner, not the group, not the full permission bits.
* **type** can be either **blob** or **tree**. So either a file or a subdirectory.
* **sha** -- you guessed it is the "hash" or filename of something that will show up in our `.git/objects`
* **filename**, ultimately, is our file (or directory) name

Here we see how everything is back in place... with our **blob**s and our **tree**s we can recreate trees with the right file names, stored where they are supposed to be and with very specific content.

> :information_source:
> The astute reader will have noticed that we have lost something to which we are accustomed: the date of creation and modification of these files. We find dates on levels of **commits**

### Subdirectories

So each **tree** allows us to reconstruct a state of a directory with files that have known contents. Now let's try to create a subdirectory, we have already encountered the `mkdir` command:

```console
mkdir files
```
and then our old friend showing us the status of our work area:

```console
git status
```

```console
On branch master
nothing to commit, working tree clean
```

> :warning:
> What? Nothing? What betrayal?! We have created a new directory but Git does not tell us anything — it says the working tree is *clean*. Indeed Git does not know how to track empty directories. This is normal when you think about it. In Git a **tree** is something that represents a list of files each with a particular content; if there is no content, what would it point to?

### Empty subdirectories

The usual practice for keeping an empty directory is to create a small empty file inside it, conventionally called `.gitkeep`, and commit that.

> :warning:
> `.gitkeep` is *pure convention*. It is not a Git feature, Git has never heard of it, and there is nothing in Git's source code that mentions it. Contrast with `.gitignore`, which Git really does read and act on. You could name the file `.keep`, `.placeholder` or `please-do-not-delete-me.txt` and it would work identically — the only thing that matters is that the directory contains *a* tracked file. `.gitkeep` is simply the name everyone settled on, so use it and other people will understand what you meant.

```console
touch files/.gitkeep
git add files/.gitkeep
git commit -m'Add .gitkeep so files will be added to the repository'
```

```console
[master f0bb8a2] Add .gitkeep so files will be added to the repository
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 files/.gitkeep
```

In our `.git/objects` we will therefore have 4 new objects appear.

An object for the **commit** (we'll see that right after...), a new **tree** which represents our root, which has changed:

```console
git ls-tree 3216264

100644 blob 0ba5adce31cb9cf9951fed3075d7571a9db5bc32	LICENSE
040000 tree d564d0bc3dd917926892c55e3706cc116d5b165e	files
100644 blob 0c7e1663dd99931898dfa9e25dfd2aba94dbe9ad	readme.md
```

A second **tree** (mister *d564d0*) which will simply contain:

```console
git ls-tree d564d0

100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391	.gitkeep
```

Then friend *e69de29* which is our empty file named `.gitkeep`.

> :information_source:
> We told you that it is the content of the file that determines the name of the object, and nothing else. And here we have an empty file. Do the exercise: search the web for `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391` and you will find it everywhere. Lots of different files, in lots of different projects, completely empty, with different names — and all of them the same single object. `e69de29` is the most popular blob in the history of Git.

Let's summarize:

If we follow the first **tree-id** we saw, **8969130**, it will give us:
```console
.
├── LICENSE
└── readme.md
```
But following the second **tree**, the **3216264**, will take us to:

```console
.
├── LICENSE
├── files
│   └── .gitkeep
└── readme.md
```

### Closing the loop with the **commit**

The last type of object that we will find in `.git/objects/` are the **commit**s.

Objects of type **commit** - that's a central element! the **commit** is this trace of our changes. A commit primarily identifies a particular **tree** plus its parent **commit**s: exactly one in the ordinary case, none at all for the very first commit of a repository (which is why Git called it a `root-commit` when we made it), and two or more for a merge.

The commit allows us to build the relationships between the **tree**s, save the changes.

As a reminder, in this lesson we have already used the `git commit` command four times:

1. When we added `readme.md` (__commit d2eafda__)
2. When we modified `readme.md` to add the command list we learned (__commit 46079d2__)
3. When we added `LICENSE` (__commit 5ab2cae__)
4. then when we added `files/.gitkeep` (__commit f0bb8a2__)

We will study the second one, **46079d2**. To see the raw object, exactly as Git stores it, there is a plumbing command:

```console
git cat-file -p 46079d2
```

And its content looks like this:

```console
tree 832e299281e32ed167f389f4b34501ec48b302c0
parent d2eafda3f0b5660fd33b0db429d2f5e447c4cd28
author Ori Pekelman <ori@pekelman.com> 1770009030 +0100
committer Ori Pekelman <ori@pekelman.com> 1770009030 +0100

Add the list of commands we learned today.
```
So the structure is:

* tree {tree_sha} is the reference, the **sha**, the **tree-id** which represents our tree
* parent {parents} is the parent commit, we'll come back to that
* author {author_name} <{author_email}> {author_date_seconds} {author_date_timezone} is the author of the code with his name and email and a **timestamp**, the time when the code will have been created
* committer {committer_name} <{committer_email}> {committer_date_seconds} {committer_date_timezone} this is the person who committed the code, who is not always the author... then the time when the commit was made (Note that usually **author** and **committer** are the same person)
* {commit message} - the message, the one we added with the `-m'...'` flag that contains the "why" of the change.

> :information_source:
> Here the author and committer timestamps are identical, because we authored and committed in the same breath. They differ when someone else's patch gets applied to your repository, or when a commit is rebased: the authorship (and its date) is preserved, the committer line records who put it here and when. This is also exactly why your commit-ids differ from mine even for byte-identical files — your name, your email and your timestamps are part of what gets hashed.

So we understood: the commit is a reference to a **tree-id** (and we have already seen it allows us to reconstruct a workspace... a tree structure with files with specific content) this reference contains some additional information: who made the changes, when, why ... and ... the "commit parent". The parent commit is therefore the previous state of our tree. So each **commit** can also be called a "revision". When we go, later, to see the list of **commits** we will see the list of all the revisions made to our repository.

But usually we will never look at the internal structures of Git but use commands which, in addition, give us more information. So let's look at the second **commit** with the `git show` command:

```console
git show 46079d2
```

```console
commit 46079d29e5c812f3141e2e5a2522c6a5871d2255
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Feb 2 06:10:30 2026 +0100

    Add the list of commands we learned today.

diff --git a/readme.md b/readme.md
index 3836229..0c7e166 100644
--- a/readme.md
+++ b/readme.md
@@ -1 +1,8 @@
 # My first Git project
+
+Today we learned the following Git commands:
+
+1. `git init` - initialize a new git repository
+2. `git status` - find out the status of the working directory relative to the git repository
+3. `git add` - add files to the git index to prepare for a commit
+4. `git commit -m"{commit message}"` - save a milestone in the git repository
```

So there we no longer see the **tree** which is basically an internal detail but only the information related to our change, let's see line by line:

1. commit - the commit id, its **sha**, the **commit-id**
2. Author: - who made the change
3. Date: - when the change was made
4. The commit message
5. The diff. The difference between the readme.md file when it had the `3836229` sha and then when it had the `0c7e166` sha.

> :information_source:
> That `@@ -1 +1,8 @@` line is called a **hunk header** and it is worth being able to read: on the left, the region of the *old* file (starting at line 1, one line long — when the length is 1 Git omits it); on the right, the region of the *new* file (starting at line 1, eight lines long). Note the comma: `+1,8` means "8 lines starting at line 1". Then one context line with a leading space, and seven added lines with a leading `+`. Deleted lines would carry a leading `-`.

If the **tree** helped us a lot to understand the internal structure of Git, it is indeed an internal thing. In our day-to-day work, it is almost exclusively with **commits** that we will interact.

> :information_source: Git does not save the differences between the two files, but actually the content of each version, separately. This difference, this **diff** that we see is calculated dynamically when we use the `git show` command.

> :information_source:
> We simplified the story a little bit, if you look at a real Git repository with lots of files and lots of **commits** you won't see an object for each file. Indeed Git will from time to time clean up and compress a little further (the keyword is **pack**). But this is outside the scope of this course.

## Summary **blob**, **commit** and **tree**

* **blob** - the blob is the content of a work area file that has been added to the index - it contains the actual contents of the file in a compressed form, its name consisting of 40 characters (**SHA**) which is a signature of its content. A blob knows nothing about its own filename.
* **tree** - contains the list of files (therefore 40-character blob identifiers)... with their names and their executable bit. We can also in the list refer to another **tree** by its **tree-id** which will give us a sub-directory.
* **commit** - is saving a state, committing; from a **commit** we can rebuild our work area with a specific **tree**. It contains information about who made the change and why. It also points at its parent commit or commits.

![Great Image](https://jwiegley.github.io/git-from-the-bottom-up/images/commits.png)
<!-- TODO: Great image we should re-execute it!-->

All the magic of git will unfold from this simple concept of **commit**. Git will allow us to make our changes each time we save states. Then he will allow us to jump from one to the other. To compare two states .. even to make mixtures of them.

But that's in the next chapters...