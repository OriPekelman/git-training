---
title: Let's save our work!
slug: "save-work-with-git"
weight: 4
---
# Let's save our work!

We have chosen to do everything very, but very slowly by explaining each step of the way to you. But you were also promised simplicity. So.. let's imagine we have a project, not yet under Git control (let's call it `my_existing_project`) that contains our source code files. How to get them under Git control simply and quickly?

Nothing's easier:
```console
cd ~/projects/my_existing_project
git init
git add .
git commit -m'First commit'
```
1. We change the current directory in our project.
2. We initialize the repository with `git init`
3. `git add` tells git to add all files in the current directory, including those in subdirectories (with the `.` after the command).
4. Then we **commit** with a message.

But, we promised detail, so let's go back to our original project which is just an empty Git repository and try to understand more in depth what happened. So if you've gone elsewhere let's go back to:

```console
cd ~/projects/my_first_git_project
```
## Track changes to a file: `git add`

We are now going to create a first file. You can use your favorite text editor. Here, I will not even use an editor and directly create the file and its contents using the `printf` command, which prints text that I will redirect (using `>`) into a file that we will name `readme.md`.

```console
printf '# My first Git project\n' > readme.md
```

> :information_source:
> You will very often see `echo "..."` used for this instead. We deliberately use `printf`, because `printf` behaves the same way everywhere: `echo "a\nb"` turns that `\n` into a real newline in zsh and dash, but prints the two characters `\n` literally in bash. A course written with `echo` would give different readers different files. `printf` always interprets the escapes — and that trailing `\n` is what gives our file its final newline.

> :information_source:
> The file we just created is a text file in a format called _Markdown_. The "#" at its beginning indicates that this line is a title. You can learn more at https://www.markdownguide.org/getting-started/. It is a very good practice to always create a file named `readme.md` at the root of your Git repository which will describe the contents of the repository. We will come back to it.

We will immediately learn a second Git command. It doesn't need an argument either (but it can take some, of course):

```console
git status
```
which will answer:

```console
On branch master

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	readme.md

nothing added to commit but untracked files present (use "git add" to track)
```

`git status`, a very useful command, allows us to know at any time, as its name indicates, what is the status of our work with Git. Over time, we will learn to understand its feedback, but for now let's focus on these three lines:

```console
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	readme.md
```

Git is therefore already aware that a file has been created. But it tells us "in your working directory, there is a file that I don't really know. If you want me to follow its evolution, you have to tell me to do so". In its great kindness it even tells us the path to follow: `git add <file>..`. 

Let's do what it tells us. We will explain right afterwards.

```console
git add readme.md
```

If there is no error, Git won't tell us anything. But it did actually do something.

## The working directory

This command does not save the file yet. It just tells Git "from now on, you need to track this file and its changes, then save its current state somewhere so I can save that state." Later, when we have made our first `commit`, it is this state that will be taken into account.

**Staging** is the action of preparing something for its next stage. In our case adding a file to the index prepares the commit. The term comes from logistics. In English we will also often use it as a verb to prepare a file to be saved, we say "to stage a file" which is equivalent to "to add a file to the index".

> :information_source:
> We can imagine working with Git as passing our files between three areas:
> 1. The work area, our current directory, the working directory: its content is what we see in the file browser. This is where we edit our files.
> 2. the staging area - the index otherwise known as **staging**, the files as they are prepared to be saved, saved in a specific version (or revision). Here we have "snapshots" of our files.
> 3. The commit area - the committed work, where things are saved for posterity - things that can also be shared with others and sent to others.

{{< mermaid >}}
graph LR
  W["Working directory<br/>the files you edit"]
  I["Index<br/>the next commit,<br/>being assembled"]
  R["Repository<br/>.git, committed<br/>for posterity"]

  W -->|"git add"| I
  I -->|"git commit"| R
  R -->|"git checkout"| W
{{< /mermaid >}}

Notice that the arrows go round. Nothing is ever taken *out* of the repository by
committing; `git checkout` copies a saved state back into the working directory,
which is why the last chapter of this part can put your deleted work back.

## Looking inside `.git`

But let's first understand what happened in more detail. We're gonna take a peek into the monster's innards. What we're about to see isn't necessary for everyday use of Git, but typing commands without understanding what they do will get you stuck fairly quickly. So a little pain now for a lot of glory later. What's in the `.git` directory?

Let's happily type a nice command:

```console
tree -C .git
```

> :information_source:
> The `tree` command is a bit like `ls` but it shows us the structure of the directories and the files they contain, we added the `-C` option so that the rendering is colored, showing us the difference between files and directories. It might not be installed on your system; in which case an `ls -lRa` (we recognize here the `ls -la`, the `R` is for Recursive) may suffice.

```console
.git
├── config
├── description
├── HEAD
├── hooks
│   ├── applypatch-msg.sample
│   ├── commit-msg.sample
│   ├── fsmonitor-watchman.sample
│   ├── post-update.sample
│   ├── pre-applypatch.sample
│   ├── pre-commit.sample
│   ├── pre-merge-commit.sample
│   ├── pre-push.sample
│   ├── pre-rebase.sample
│   ├── pre-receive.sample
│   ├── prepare-commit-msg.sample
│   ├── push-to-checkout.sample
│   ├── sendemail-validate.sample
│   └── update.sample
├── index
├── info
│   └── exclude
├── objects
│   ├── 38
│   │   └── 36229b5ce7fd362c59974d286de92bf5191784
│   ├── info
│   └── pack
└── refs
    ├── heads
    └── tags

10 directories, 20 files
```

> :information_source:
> That list of `hooks/*.sample` files grows and shrinks between Git versions (this is Git 2.51); if yours is a little different, nothing is wrong. **Hooks** are scripts Git can run automatically at certain moments — we are not going to use them in this course, and as long as they end in `.sample` Git ignores them entirely.

We'll ignore the rest for now and focus on just one part:

```console
.git
├── index
├── objects
│   ├── 38
│   │   └── 36229b5ce7fd362c59974d286de92bf5191784
```

Here we have a very important file, `index`. And a directory structure of the form: `objects/<two letters>/<38-letter-filename>`.

The **index**, the file `.git/index`, is the **staging** area. It is a binary file which holds one entry per path that will make up our next **commit**: the path, its file mode, and the hash of the content that has been staged for it (plus a cache of filesystem information so Git can tell quickly whether a file has changed on disk). It is a shopping list for the next commit — not a database of our history.

The database is `.git/objects`. That is where the actual content lives: the contents of the files we added to the index, and later the **commit**s and **tree**s themselves. Our `readme.md` has been put in a compressed form in `objects/38/36229b5ce7fd362c59974d286de92bf5191784`.

> :information_source:
> This weird file name is not random, it's a **SHA**. Git used what is called a "hash function" based on the contents of the file. Basically a hash function allows us to take content, no matter how small, and output a string of characters of fixed size (in our case 40 characters. Here the first two characters are used for the directory name and 38 for the file name).
> Changing a single character in the content completely changes the generated string. This is referred to as "addressing by content". When the content changes, the filename (hence "address") changes.
> And everywhere in Git, or almost, our identifiers will take this form. We are going to talk about **commit**, **commit-id**, **tree** and **tree-id**, **blob**s and all that will always take a form like this: `3836229b5ce7fd362c59974d286de92bf5191784`. To make the thing a little more readable most often we will not use the 40 characters but only the first 7. So to talk about `3836229b5ce7fd362c59974d286de92bf5191784` we will rather talk about `3836229`, but that actually identifies the same thing.

> :information_source:
> **Your `readme.md` really should be `3836229...` too.** A **blob** is hashed from its content and nothing else, so if you typed the same `printf` you got the same 40 characters. But from the next section onwards, when we start showing you **commit** hashes, yours *will* be different from the ones printed here — and that is not a mistake. A commit contains your name, your email address and the exact second at which you made it, so no two people can produce the same commit-id for the "same" commit. Read the hashes in this course as illustrations: the shape is real, the digits are mine.

> :information_source:
> The hash function is **SHA-1**, and that is still the default. Two footnotes worth knowing. First, since Git 2.13 the SHA-1 that Git uses is a *hardened* one: it detects the known SHA-1 collision attack and refuses the object rather than being fooled by it. Second, since Git 2.29 you can create a repository whose object names are SHA-256 instead, with `git init --object-format=sha256`. Interoperability between the two kinds of repository is still incomplete, so in practice essentially every repository you will ever touch — including every repository on GitHub or GitLab — is SHA-1. We will say 40 characters and mean SHA-1 for the rest of this course.

So where is the same file's content, from Git's point of view, at this moment? In three places, and it is worth being precise about them because it is exactly the thing beginners get wrong:

* In the **working directory** it is just bytes on disk. Git has not hashed them and does not watch them; it only looks when you ask it to.
* In the **index** there is one entry for `readme.md`, and it names the **blob** we staged — `3836229`.
* In the **commit** we are about to make, the **tree** will name the blob that got committed.

Those three can agree or disagree, and `git status` is the command that tells you which. (During a merge conflict, and only then, a single path can have up to three entries in the index at once — the "stages". We will meet them when we merge.)

> :warning:
> A lot of misunderstandings about Git come from misunderstanding this relationship between **staging** or preparing our **commit**, our save stage, and the **commit** itself. This is why we focus on it. So take the time to understand.

At any rate, we are ready! Finally. We created a file and added it to the index.

If we run `git status` again, it will tell us:
```console
On branch master

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
	new file:   readme.md

```

that's it, Git is ready for us.

## Saving a milestone: `git commit`

In the terminal type:

```console
git commit -m"Added readme.md"
```

Normally Git will respond to us with:

```console
[master (root-commit) 0ab682b] Added readme.md
 1 file changed, 1 insertion(+)
 create mode 100644 readme.md
```

Here. It's done! We have saved a waypoint. You can type `git status`

Our **commit**. Forever from now on in the life of our project we will be able to go back in time, know what the content of the file was at that time, and we will also know who made what change... and **why**.

> :information_source:
> We saw, when we typed the `git add` command it created the file in a compressed form in its `.git/objects/` directory and gave it a name based on the contents. So we lost the file name! Do not be afraid. In `.git/objects` we have two other types of objects that will allow us to find our file name: `tree` and `commit`.

Let's analyze just a little what we did ... and then, let's go into the details of what Git did. Indeed the `commit` command like the `add` command not only changes the index but also creates new objects in `.git/objects`

So `git commit` is the command that saves, and here we see for the first time an option worth learning properly: `-m`. It gives the **commit message**: the intention of our change. It's incredibly useful when working alone ("but why the hell did I do that! ah.. yes..") but it's even more important when working with others.

The message itself is not optional. If you leave out `-m`, Git opens your text editor and waits for you to type one — and if you save an empty message, it aborts the commit and nothing is recorded. Git will not let you save anonymous work.

> :information_source:
> If Git ever drops you into an editor you don't recognise, it is probably `vi`: type `:q!` and press enter to get out without committing. You can pick your own with `git config --global core.editor nano` (or `code --wait`, or whatever you actually use). This surprises a great many people exactly once.

> :warning:
> As someone who recruits quite a few developers, know that when I look at candidate code, I'm looking at commit messages as much as I'm looking at the code itself.

## Save a second change then a third

We're on a roll so let's keep going! Let's make a second change. Open our "readme.md" with your favorite text editor and let's add for example:

```markdown
# My first Git project

Today we learned the following Git commands:

1. `git init` - initialize a new git repository
2. `git status` - find out the status of the working directory relative to the git repository
3. `git add` - add files to the git index to prepare for a commit
4. `git commit -m"{commit message}"` - save a milestone in the git repository
```

After saving the file, if we type `git status` again we will get a slightly different message.

```console
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   readme.md

no changes added to commit (use "git add" and/or "git commit -a")
```

Great. Git is aware that the file has been modified.. and it even gives us directions on the next step. Let's go!

Again:

```console
git add readme.md
```

Then:

```console
git commit -m"Add the list of commands we learned today."
```

Who answers us with:

```console
[master 72c4234] Add the list of commands we learned today.
 1 file changed, 7 insertions(+)
```

> :information_source:
> Tip 1: if you get tired of typing `add` then `commit` each time, we have a shortcut: `git commit -am"my commit message"`. The `-a` option added here says **all**... Git will append all files tracked in the index that have changed to the commit. On the other hand, if a file has not yet been added for the first time, it is **Untracked**, and `-a` will do nothing for that one.
> Tip 2: if you have a lot of files in the directory and you don't want to add them one by one, you can add them all at once with `git add .` but be careful, often we have files lying around that you don't necessarily want in your repository. We'll see that later.

For the exercise let's now create a second file. Let's put a license file in our repository that will explain to people who might have access to it what they can and cannot do with it. This one is eight lines long, so rather than fighting with quotes and escapes we'll use a **heredoc**: everything between `<<'EOF'` and the closing `EOF` goes into the file, exactly as typed.

```console
cat > LICENSE <<'EOF'
Git Example by Ori Pekelman

To the extent possible under law, the person who associated CC0 with
Git Example has waived all copyright and related or neighboring rights
to Git Example.

You should have received a copy of the CC0 legalcode along with this
work. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
EOF

git add LICENSE
git commit -m"Adding a license file"
```

Which gives us:

```console
[master cabdb6f] Adding a license file
 1 file changed, 8 insertions(+)
 create mode 100644 LICENSE
```


## `git init`, `git add` and `git commit` summary

* `git init` - create a new, empty Git repository.
* `git add` - add a file from our work area to the index
* `git commit` - commit and save the files as they were added to the index
* `git status` - to see where we are. Has the file been added to the index? Has it been modified since it was committed?


We are now the proud owners of a Git repository with two files, and three **commits**. Let's see how it looks, inside Git. To the next chapter!