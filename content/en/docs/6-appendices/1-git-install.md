---
title: Installing and configuring Git
slug: "git-install"
weight: 51
---
# Installing and configuring Git

As we said there are many ways to use Git — through the web, with a graphical client, from inside an IDE — but this course concentrates on its use at the command line, with the "official" version. Everything you need starts here: https://git-scm.com/downloads

> :information_source:
> **The command line.** If you are not comfortable with a terminal, take a quick detour through https://tutorial.djangogirls.org/en/intro_to_command_line/ — you will see, you get a taste for it quickly. And remember that "terminal", "terminal emulator", "console", "command line" and "command prompt" all mean the same small window in which you type things and press enter.

Downloading an installer works. But every operating system has a preferred way of installing software, and the reason to prefer it is not purity: it is that the package manager also *updates* the thing. A Git you installed by double-clicking an installer in 2023 is a Git from 2023.

## Install Git

### Linux

On a Debian or Ubuntu system:

```console
sudo apt update
sudo apt install git
```

On Fedora, RHEL, Rocky, Alma:

```console
sudo dnf install git
```

On Arch and its derivatives:

```console
sudo pacman -S git
```

On Alpine (and therefore inside a great many containers):

```console
apk add git
```

> :information_source:
> You will see a lot of tutorials — including an older version of this one — telling you to install `git-all`. That is not wrong, but it is probably not what you want. On Debian and Ubuntu `git-all` is a metapackage whose only job is to pull in *everything*: `git-gui` and `gitk` (the graphical tools), `git-svn` and `git-cvs` (bridges to version control systems you have most likely never used), `git-email` (sending patches by mail), `git-mediawiki`, `gitweb`, and the documentation. Fedora's `git-all` is the same idea. The package you actually want is `git`, and it is about a tenth of the size. If you later discover you want `gitk`, install `gitk`.

**Your distribution's Git is probably older than this course.** Distributions freeze package versions when they freeze a release, and Git ships a new version every quarter or so. Ubuntu 24.04 LTS, for instance, ships Git 2.43 — which is fine, but it is not the Git we are typing at.

Check what you have:

```console
git --version
```

```console
git version 2.51.0
```

This course is written against Git 2.51. Anything from 2.40 onwards will follow along without surprises; below that you start losing conveniences we mention (`git switch` and `git restore` landed in 2.23, `push.autoSetupRemote` in 2.37, SSH commit signing in 2.34). If you need something newer than your distribution offers, in escalating order of effort:

1. On Ubuntu, the Git maintainers publish a backports archive: `sudo add-apt-repository ppa:git-core/ppa && sudo apt update && sudo apt install git`. It tracks upstream closely, though it can lag by a release for a few weeks.
2. Fedora, Arch and Alpine are already close to upstream; there is nothing to do.
3. Build from source. Git's own build is honestly one of the more pleasant ones out there — clone https://github.com/git/git, install the development headers your distribution names `libcurl`, `zlib`, `openssl` and `expat`, and `make prefix=/usr/local all install`. Do this when you have a reason, not as a matter of course.

### macOS

Three options, from smallest to nicest.

**Xcode Command Line Tools.** The old advice was "install Xcode", which is a fifteen-gigabyte IDE you did not ask for. You do not need it. You need the command line tools, which are a few hundred megabytes:

```console
xcode-select --install
```

A dialog appears, you click Install, and you get `git`, `make`, a compiler and the rest of the Unix development furniture. This is also what macOS itself will offer you the first time you type `git` on a fresh machine.

**Homebrew**, which is the path we would actually take:

```console
brew install git
```

Homebrew's Git tracks upstream, so you get a current one and `brew upgrade` keeps it current.

**MacPorts**, if that is your world: `sudo port install git`.

> :warning:
> **Apple ships an old Git, and it may be the one you are using.** Apple's build lags upstream substantially — often by years — and helpfully identifies itself, so you can tell. Something along these lines, with the exact numbers depending on your macOS version:
>
> ```console
> git --version
> git version 2.39.5 (Apple Git-154)
> ```
>
> That `(Apple Git-NNN)` suffix is the tell. If you installed a newer Git and still see it, the problem is your `PATH`: two `git` binaries exist and the shell is finding the wrong one first.
>
> ```console
> which -a git
> ```
>
> ```console
> /opt/homebrew/bin/git
> /usr/bin/git
> ```
>
> The list is in the order your shell searches. Here Homebrew's `git` wins, which is what we want. If `/usr/bin/git` comes first, put Homebrew's directory earlier in `PATH` in your `~/.zshrc` — on Apple Silicon that is `/opt/homebrew/bin`, on Intel Macs `/usr/local/bin`.

### Windows

Windows has more choices than anywhere else, and unusually they are all fine.

**winget**, which ships with Windows now and is the first-class option:

```console
winget install -e --id Git.Git
```

**Chocolatey** (`choco install git`) and **Scoop** (`scoop install git`) both work and both track upstream closely. Pick whichever you already use.

All three install the same thing: **Git for Windows**, which is much more than the `git` binary. It brings **Git Bash**, a small Unix-like shell environment, and that is what most Windows developers actually use Git in. Git Bash is genuinely good — it gives you `ls`, `grep`, `ssh`, and a shell in which the commands in this course work as written.

> :information_source:
> **Our recommendation for this course remains WSL2** — the Windows Subsystem for Linux. Install a distribution (`wsl --install -d Ubuntu`), then follow the Linux instructions above and you are in a real Linux, where every command in this course is exactly the command a Linux reader types. No translation, no surprises.
>
> The honest tradeoff: **do not let Git cross the filesystem boundary.** WSL2 can see your Windows drives under `/mnt/c`, and working there is *slow* — not slightly slow, painfully slow, because every file access crosses between two operating systems. Microsoft's own documentation says to store your project files in the Linux filesystem (`/home/<you>/projects`) rather than under `/mnt/c`. Git touches thousands of files for a single `git status`, so this is exactly the workload that suffers. Keep your repositories inside WSL, and if you want to edit them from a Windows editor, use one that speaks WSL (VS Code does, natively).

Two Windows-only settings cause more grief than everything else combined.

**Line endings.** Windows ends lines with carriage-return-plus-newline (`CRLF`); everything else uses newline alone (`LF`). If nobody thinks about it, the same file gets committed both ways and every `git diff` shows the whole file as changed. The installer will offer you `core.autocrlf`, which converts on the way in and out of the repository, globally, on your machine.

We suggest you do *not* rely on that, and instead put a `.gitattributes` file at the root of the repository:

```
* text=auto
```

Why the file rather than the setting? Because `.gitattributes` is **committed**. It is a property of the project, so it applies to every person who clones it, including the ones who never configured anything. `core.autocrlf` is a property of *your machine*, so it protects you and nobody else — and the next contributor re-breaks the repository. Git's own documentation recommends the `text=auto` attribute for exactly this reason. If you add it to a repository that already has mixed endings, `git add --renormalize .` fixes the existing files in one commit.

**Long paths.** Windows has a historical 260-character limit on paths, and some projects (anything with deeply nested `node_modules`, for example) will trip over it with a `Filename too long` error. Git for Windows can work around it:

```console
git config --global core.longpaths true
```

> :information_source:
> `core.longpaths` exists only in Git for Windows — you will not find it in the upstream `git config` documentation, and setting it on Linux or macOS does nothing. Git for Windows' own docs warn that Explorer, `cmd.exe` and various tools still cannot handle those paths, so enabling it makes Git work while other things may still complain.

### You may already have it

Git is installed in essentially every CI image (GitHub Actions runners, GitLab runners, CircleCI), in every dev container image, and in most base Docker images that aren't deliberately minimal. If you are wondering whether a machine has Git and which one:

```console
git --version
```

If that prints a version, you are done. If it prints `command not found`, come back to the top of this chapter.

## Test that the installation is correct

Open a terminal and type `git`, then the enter key. You should see a long help text that pops up with lots of very anxiety-provoking words. Breathe deeply. You can ignore all of this for now.

```console
usage: git [-v | --version] [-h | --help] [-C <path>] [-c <name>=<value>]
           [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]
           [-p | --paginate | -P | --no-pager] [--no-replace-objects] [--no-lazy-fetch]
           [--no-optional-locks] [--no-advice] [--bare] [--git-dir=<path>]
           [--work-tree=<path>] [--namespace=<name>] [--config-env=<name>=<envvar>]
           <command> [<args>]

These are common Git commands used in various situations:

start a working area (see also: git help tutorial)
   clone      Clone a repository into a new directory
   init       Create an empty Git repository or reinitialize an existing one

work on the current change (see also: git help everyday)
   add        Add file contents to the index
   mv         Move or rename a file, a directory, or a symlink
   restore    Restore working tree files
   rm         Remove files from the working tree and from the index

examine the history and state (see also: git help revisions)
   bisect     Use binary search to find the commit that introduced a bug
   diff       Show changes between commits, commit and working tree, etc
   grep       Print lines matching a pattern
   log        Show commit logs
   show       Show various types of objects
   status     Show the working tree status

grow, mark and tweak your common history
   backfill   Download missing objects in a partial clone
   branch     List, create, or delete branches
   commit     Record changes to the repository
   merge      Join two or more development histories together
   rebase     Reapply commits on top of another base tip
   reset      Reset current HEAD to the specified state
   switch     Switch branches
   tag        Create, list, delete or verify a tag object signed with GPG

collaborate (see also: git help workflows)
   fetch      Download objects and refs from another repository
   pull       Fetch from and integrate with another repository or a local branch
   push       Update remote refs along with associated objects

'git help -a' and 'git help -g' list available subcommands and some
concept guides. See 'git help <command>' or 'git help <concept>'
to read about a specific subcommand or concept.
See 'git help git' for an overview of the system.
```

That is Git 2.51 talking. Older versions print a shorter list — `restore`, `switch` and `backfill` are recent arrivals — so if yours differs slightly, nothing is wrong.

On macOS, if the command line tools are not installed, typing `git` will instead pop up a dialog offering to install them. Say yes. Done.

## Configure Git

Now, and this is important, we have to tell Git who we are. As we said at the very beginning, Git lets us follow who did what, when and why — and for the "who" it needs to be told.

```console
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

> :warning:
> **That email address goes into every commit you make, and it is public forever.** Not "visible on a web page you can take down" — baked into the commit object, which means baked into its **SHA**, which means it travels to every clone of the repository. You cannot change it later without rewriting history.
>
> If you would rather not publish your personal address, GitHub will give you an alias of the form `1234567+yourname@users.noreply.github.com` along with a "Keep my email addresses private" setting, and GitLab has an equivalent. Set *that* as your `user.email` and the forge still knows the commits are yours. See [Create and configure your GitHub or GitLab account](3-github-gitlab.md "Create and configure your GitHub or GitLab account").

Then four settings that will save you real irritation.

**The name of the first branch.** `git init` still creates a branch called `master`, and prints a small lecture about it every time; GitHub and GitLab default to `main`. Pick one and stop thinking about it:

```console
git config --global init.defaultBranch main
```

**Your editor.** Git opens an editor whenever you run `git commit` without `-m`, and for `git rebase -i`, and for merge messages. If nothing is configured it uses `$EDITOR`, and if that is unset it uses `vi`. Which leads to the single most common panic in this entire subject:

> :information_source:
> **"I ran `git commit` and now I am trapped."** You are in vim. Nothing is broken. To get out: type your commit message, then press `Esc`, then type `:wq` and press enter — that is *write and quit*, and your commit is made. If you want to abandon the commit instead, press `Esc` and type `:q!` then enter — *quit, discard* — and Git will tell you `Aborting commit due to empty commit message.` Nothing was lost either way.

To not be in vim next time, pick something else:

```console
git config --global core.editor "nano"
```

or, for VS Code — and the `--wait` is not optional, it is what makes Git pause until you close the tab:

```console
git config --global core.editor "code --wait"
```

The same shape works for other editors: `"subl -n -w"`, `"zed --wait"`, `"micro"`. And if you *want* vim, `git config --global core.editor "vim"` at least makes it a choice rather than a default.

**What `git pull` should do.** By default `git pull` will merge, and when your branch and the remote's have both moved it makes a merge commit you did not ask for. Refusing that is a good habit:

```console
git config --global pull.ff only
```

Now `git pull` succeeds silently when it can simply **fast-forward**, and stops and tells you when it cannot — at which point you decide, deliberately, to merge or to rebase. We come back to this at length in [Retrieve and send code](../2-collaborating/3-git-clone-pull-remote.md "Retrieve and send code").

**Pushing a new branch.** Without help, the first push of a new branch is this:

```console
fatal: The current branch feature has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin feature
```

Every time, forever. Since Git 2.37 you can just tell it to do the obvious thing:

```console
git config --global push.autoSetupRemote true
```

and `git push` on a new branch answers:

```console
To /tmp/asr2/origin.git
 * [new branch]      feature -> feature
branch 'feature' set up to track 'origin/feature'.
```

> :information_source:
> What we have set here is the minimum for the rest of this course to behave as described. There is a longer, more opinionated set of configuration worth having once you are comfortable — aliases, a better diff, a shell prompt that shows your **branch** — and that belongs with the rest of the tooling, in [Making the command line yours](../3-tooling-ecosystem/1-git-tools.md "Making the command line yours").

### Where configuration lives

Every `--global` above wrote to a file. Git reads several, in order, and later ones win:

| Scope | File | Set with |
| --- | --- | --- |
| system | `/etc/gitconfig` | `git config --system` |
| user | `~/.gitconfig`, or `~/.config/git/config` if it exists | `git config --global` |
| repository | `.git/config` | `git config --local`, the default |
| worktree | `.git/config.worktree` | `git config --worktree` |

They are plain INI-style text files. You are allowed to open them in an editor; `git config --global --edit` does it for you.

`--local` is the default, which means that inside a repository a plain `git config user.email "..."` sets it **for that repository only**. That is the simplest way to use a different identity for one project.

And when you cannot work out where a setting came from — which happens more than you would like — ask:

```console
git config list --show-origin
```

```console
file:/Users/oripekelman/.gitconfig	user.name=Ori Pekelman
file:/Users/oripekelman/.gitconfig	user.email=ori+git-training@pekelman.com
file:/Users/oripekelman/.gitconfig	init.defaultbranch=main
```

Add `--show-scope` and it also tells you whether each line is `system`, `global`, `local` or `worktree`.

> :information_source:
> Since Git 2.46, `git config` has proper subcommands — `git config list`, `git config get user.email`, `git config set user.name "..."`, `git config unset`. The old flag forms (`git config --list`, `git config --get`) still work everywhere and are what the world still types, but they are formally deprecated. We use both in this course, deliberately, because you will meet both.

### Two identities on one machine: conditional includes

This is the genuinely useful trick. You have a work email and a personal one, and you would like commits in `~/work/` to carry the work identity without ever thinking about it again.

Git can include another config file *conditionally*, based on where the repository is. In `~/.gitconfig`:

```
[user]
	name = Ori Pekelman
	email = ori+git-training@pekelman.com
[init]
	defaultBranch = main
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work
```

And in `~/.gitconfig-work`, only what differs:

```
[user]
	email = ori@example-corp.com
```

Note the **trailing slash** on `gitdir:~/work/` — it is what makes the pattern match everything underneath the directory. Without it you are matching one exact path and wondering why nothing happens.

Let's prove it. Inside a repository under `~/work/`:

```console
git config get user.email
```

```console
ori@example-corp.com
```

And inside one anywhere else:

```console
git config get user.email
```

```console
ori+git-training@pekelman.com
```

The `includeIf` mechanism arrived in Git 2.13 with `gitdir:`; 2.23 added `onbranch:` (apply this config while on a branch matching a pattern) and 2.36 added `hasconfig:remote.*.url:` (apply it in any repository whose remote is *that* server), which is even better suited to the work/personal split — it follows the code rather than the directory.

## Prove the whole thing works

Configuration you have not tested is configuration you have guessed at. Two minutes, one throwaway repository, and we know the entire toolchain works end to end.

```console
cd /tmp
git init hello-git
cd hello-git
printf '# Hello, Git\n' > readme.md
git add readme.md
git commit -m"My first commit"
```

Which should answer:

```console
Initialized empty Git repository in /tmp/hello-git/.git/
[main (root-commit) 71e50b1] My first commit
 1 file changed, 1 insertion(+)
 create mode 100644 readme.md
```

Three things to notice, because each one confirms a setting.

* `Initialized empty Git repository` with **no `hint:` lecture** about branch names means `init.defaultBranch` took effect.
* `[main (root-commit) ...]` says `main`, not `master` — same confirmation, from the other side.
* Git did not complain `Author identity unknown` — so `user.name` and `user.email` are set. Your `71e50b1` will be different from mine, and that is expected: a **commit** hash includes your name, your email and the second you made it.

Check the identity that actually got recorded:

```console
git log --pretty=fuller
```

```console
commit 71e50b1af89627c5065c45979d42a9c252a4c1e6
Author:     Ori Pekelman <ori+git-training@pekelman.com>
AuthorDate: Wed Jul 29 23:36:13 2026 +0200
Commit:     Ori Pekelman <ori+git-training@pekelman.com>
CommitDate: Wed Jul 29 23:36:13 2026 +0200

    My first commit
```

If that says what you expect it to say, you are installed and configured. Delete the directory — `cd /tmp && rm -rf hello-git` — and go do the real thing in [First steps, first Git commands](../1-understanding-git/3-first-git-commands.md "First steps, first Git commands").

The other half of the setup, needed as soon as you want to push to a server, is in [Configure Git with an SSH key](2-git-ssh.md "Configure Git with an SSH key").

## Summary `git --version` `git config`

* Prefer your operating system's package manager over a downloaded installer, because the package manager also updates Git.
* Linux: `apt install git`, `dnf install git`, `pacman -S git`, `apk add git`. The `git-all` package is a metapackage that drags in the GUI, the Subversion bridge and the mail tools — you want plain `git`.
* macOS: `xcode-select --install` for the small Apple toolchain, or `brew install git` for a current Git. Apple's build is old and identifies itself as `(Apple Git-NNN)`; `which -a git` tells you which one your `PATH` finds first.
* Windows: `winget install -e --id Git.Git`, or Chocolatey, or Scoop — all give you Git for Windows and Git Bash. For this course, WSL2 is better still, as long as you keep your repositories inside the Linux filesystem and not under `/mnt/c`.
* On Windows, commit `* text=auto` in a `.gitattributes` rather than relying on `core.autocrlf`, because the file travels with the repository and the setting does not. Use `core.longpaths true` when Windows' 260-character path limit bites.
* `git --version` is how you find out what a machine has — including CI runners and dev containers, which almost always have Git already.
* `git config --global user.name` and `user.email` are mandatory, and the email is public in every commit forever.
* Worth setting once: `init.defaultBranch main`, `core.editor`, `pull.ff only`, `push.autoSetupRemote true`.
* If `git commit` drops you into vim: `Esc` then `:wq` to save, `Esc` then `:q!` to abandon.
* Configuration is layered — `/etc/gitconfig`, `~/.gitconfig`, `.git/config`, `.git/config.worktree` — and `git config list --show-origin` tells you which file a value came from.
* `[includeIf "gitdir:~/work/"]` keeps a work identity separate from a personal one automatically. Mind the trailing slash.
