---
title: Graphical Git clients
slug: "git-guis"
weight: 23
---
# Graphical Git clients

This course has spent two whole parts insisting on the command line, so you might expect this chapter to be a grudging paragraph and a shrug. It is not. A good graphical Git client is a genuinely useful instrument, and refusing to use one out of terminal machismo is a way of making your life worse for no reason.

Let me be precise about *why* it helps, because "it's easier" is not the reason.

## Where a GUI is honestly better

**Because history is a graph, and a picture of a graph beats a description of one.** We have been drawing the **commit** graph with `git log --oneline --graph --decorate --all` since Part 2, and it works — but ASCII art has a hard ceiling. Show it eight active branches, a couple of merges that crossed, and a rebase that moved half of them, and you get a wall of `|` and `\` characters that your eyes slide off. A real drawing, with lanes and colours and room to breathe, tells you in one second what the terminal takes a minute to spell out. When you are trying to understand "how did these two branches end up like this", that second matters.

**Because staging by hunk, and especially by line, is a mouse job.** `git add -p` is a wonderful command and you should know it. But it is a quiz: Git shows you a **hunk**, asks `Stage this hunk [y,n,q,a,d,s,e,?]?`, and if you want half of it you end up in `e` mode editing a diff by hand, which is a small act of violence. In a GUI you click the three lines you want, they turn green, done. Splitting one messy working area into three clean **commit**s — which is a thing you should be doing far more often than you do — goes from a chore to a pleasure.

**Because archaeology is faster when you can click.** "Who wrote this line" → "what else did that commit change" → "what did this file look like before" → "show me the diff against the branch point" is a chain of four questions, and in a GUI each link is one click. In the terminal each link is a command with arguments you have to recall, and by the third one you have lost the thread of what you were actually looking for.

None of that is a concession. Those are three real strengths and they are all about *reading* the repository.

## Why we still taught you the command line

Because every GUI is a lossy façade over the same commands, and the loss is not evenly distributed.

The mapping is close to perfect for the easy things. Commit, stage, switch branch, fetch, push — the button does what the command does, and you lose nothing. The mapping gets thin exactly where Git gets interesting: rebase, cherry-pick, submodules, worktrees, anything with `--force-with-lease`, anything where you need to know precisely which ref moved.

And then there is the moment that decides the argument. **You will end up in a broken state in the middle of a rebase.** Not maybe — you will, everybody does, we spent a whole chapter on it. And when you do, you will be looking at a dialog box that says something has gone wrong and offers you two buttons, neither of which is "tell me what state the repository is actually in". The person who can type `git status`, `git rebase --abort` and `git reflog` walks away from that in fifteen seconds. The person who cannot is stuck, and their next move is usually to delete the clone and start again — which is how weeks of work get lost, in 2026, in a graphical tool.

There is a second, less dramatic reason, and it has grown teeth recently: **the command line is the interface everything else drives.** Your CI pipeline runs `git` commands. Your deployment hook runs `git` commands. Your pre-commit framework runs `git` commands. And your coding agent runs `git` commands — an agent has no hands for your mouse, so the entire vocabulary it uses to work on your repository is the one you learned in Part 1. Knowing what those commands do is now the difference between supervising an agent and hoping.

> :information_source:
> So the recommendation is both, with a clear division of labour, and it is the same one this course makes about editors in [Editors, IDEs and the file browser](4-git-ides.md "Editors, IDEs and the file browser"):
>
> * **GUI for reading and for staging.** History, blame, diffs, "what changed and who did it", picking apart a messy working area into clean commits.
> * **Command line for anything that rewrites.** Rebase, amend, reset, cherry-pick, force-push, filtering history. Anything where you want to know *exactly* what ran.
>
> That is not a compromise between two camps. It is what most experienced people actually do.

## The landscape

What follows is about what each one is *for*. I am deliberately not telling you what any of these costs, whether it is free, or how actively it is maintained — those things change, this is a book, and a book that guesses about them is worse than a book that stays quiet. Go and look at the project's own site; that takes you thirty seconds and it will be right.

**GitKraken.** The one people mean when they say "the graph one". Cross-platform, and the visual history is its centrepiece — big, clear, draggable. Strong on making merges and rebases into direct manipulation: drag one branch onto another. Deep hosted-forge integration, so issues and pull requests appear inside the client.

**Fork.** macOS and Windows. Fast, quiet, and unusually complete for how simple it looks — interactive rebase, a good merge conflict resolver, blame, submodules, and an image diff. The one I most often see on the machines of people who *also* live in the terminal, which is a meaningful signal: it does not try to hide Git from you.

**Sublime Merge.** From the makers of Sublime Text, and it inherits the important quality: it is *fast*, on repositories where other tools begin to sulk. Its distinguishing feature is the one I care most about — it shows you the actual Git command it is about to run, and it exposes a command palette rather than burying operations in menus. It reads like a Git client written by people who like Git.

**Tower.** macOS and Windows, and the most "professional tool" of the bunch in feel: careful workflows, undo for a surprising range of operations, thorough support for the awkward corners like submodules and worktrees. Aimed squarely at people who use it all day.

**GitHub Desktop.** Deliberately limited, and that is the point — it does not attempt to expose all of Git. It covers clone, branch, commit, push, pull request, and a well-made conflict flow, on a GitHub-shaped workflow. For a beginner, or for a designer or writer who needs to contribute to a repository and does not want to learn Git this month, it is a kind recommendation. For anything more, you will hit its edges quickly, and it will not help you when you do.

**GitUp.** macOS. Interesting for a reason none of the others share: it is built on the premise that the graph should update *live* as you manipulate it, with a real undo stack, so you are encouraged to poke at history and see what happens. It is the closest thing to a Git *sandbox*, and it makes an excellent teaching tool for exactly the operations that frighten people.

**SmartGit.** Cross-platform including Linux, and the one that goes furthest into the enterprise end: multiple hosting providers, deep review integration, and a strong "distributed reviews" story. Dense, but there is a lot in there.

**Sourcetree.** Atlassian's client, for macOS and Windows. The reason it is on this list is that a very large number of teams already have it because they already have Bitbucket and Jira, and the integration is the whole argument.

### The ones you already have

Here is a nice trick. Ask your Git what graphical commands it knows about:

```console
git help -a
```

Somewhere in the output:

```console
   citool                  Graphical alternative to git-commit
   gitk                    The Git repository browser
   gui                     A portable graphical interface to Git
   instaweb                Instantly browse your working repository in gitweb
```

`gitk` is a history browser, and `git gui` is a commit tool with hunk- and line-level staging. They are written in Tcl/Tk, they look like 1998, and they are part of the Git project itself — which means they have no telemetry, no account, no sign-up, and no opinion about which forge you use. They also still work perfectly well. `gitk --all` next time you are lost in a branch tangle is a genuinely reasonable move, and `git citool` is `git gui` in "just make one commit" mode.

> :warning:
> "Ships with Git" depends on how Git was packaged for you. On this Mac, Git came from Homebrew, `git help -a` lists `gitk` — and `command -v gitk` finds nothing, because Homebrew splits the Tcl/Tk tools into a separate `git-gui` formula. Linux distributions often package them separately too (`gitk`, `git-gui`), while Git for Windows includes them. If the command is missing, it is a packaging decision, not a broken installation: install your platform's `gitk` / `git-gui` package.

### Watching what your GUI actually did

Since this course is built on looking under the hood, here is the trick that makes any graphical client honest, whether it wants to be or not: **after it does something you did not fully understand, ask the reflog.**

A branch got rebased onto `main` — and it genuinely does not matter whether that happened because someone typed `git rebase main` or because someone clicked a button labelled "Rebase onto main", because Git records the same thing either way. Afterwards:

```console
git reflog -8
```

```console
d0cb4bd HEAD@{0}: rebase (finish): returning to refs/heads/topic
d0cb4bd HEAD@{1}: rebase (pick): Add c
7f66bdf HEAD@{2}: rebase (pick): Add b
7dd54fb HEAD@{3}: rebase (start): checkout main
7d9b88e HEAD@{4}: commit: Add c
10e6bad HEAD@{5}: checkout: moving from main to topic
7dd54fb HEAD@{6}: commit: Second commit on main
4c3419c HEAD@{7}: checkout: moving from main to main
```

Read it bottom-up and the entire operation is narrated: the rebase started by checking out `main` at `7dd54fb`, replayed "Add b" and then "Add c" as *new* commits, and finally moved the `topic` branch to the end of the replay. Notice that `Add c` appears twice, at `HEAD@{4}` as `7d9b88e` and at `HEAD@{1}` as `d0cb4bd` — that is a rebase for you: the same change, a brand new **commit**. And the original is still there, named, one command away.

No client can hide from that, because the reflog is written by Git itself. Whatever the button did, this is what it did. Use it whenever a GUI surprises you — it is the cheapest Git lesson available.

### And in the terminal

If what you actually wanted was a nicer interface without leaving the terminal at all, that is a real category with real answers — `lazygit` and `gitui` give you panes, keyboard-driven staging and a browsable graph in a TUI. They live in [Making the command line yours](1-git-tools.md "Making the command line yours") with the rest of the terminal toolkit.

## Choosing one

Five questions. The last is the one that matters most.

1. **Does it show the true graph?** Not a prettified straight line — the actual **commit** graph, with all branches, merge commits with both parents visible, and unreferenced work you can still reach. If a tool draws you a simplified history, it is lying to you about the thing you came to it for.
2. **Can it do an interactive rebase?** Reorder, squash, reword, drop, edit. This is the acid test for how deep the tool really goes, because it is the operation where a shallow façade cannot fake it.
3. **Does it understand submodules, LFS and worktrees?** These are where clients quietly fall over. A tool that does not know about **worktree**s will show you nonsense the day you use one; a tool that does not know about **LFS** will happily commit a 400MB pointer-shaped mess.
4. **Does it phone home?** Some of these are accounts and subscriptions with a client attached. That may be perfectly fine with you. Decide on purpose rather than by accident, and check what your employer's policy says about a tool that has read access to all your source.
5. **Does it show you the commands it runs?** This is the real tell. A client that surfaces `git rebase --onto ...` before executing it is teaching you every time you use it, and after six months you can do the operation without it. A client that hides the command keeps you dependent on itself, forever, and abandons you the moment something goes wrong. Prefer the honest one.

That fifth question is also the reason a GUI is not a shortcut past this course. The good ones assume you know what a **commit**, a **ref** and the **index** are — which, several chapters in, you do. That is what makes them powerful in your hands and dangerous in a beginner's.

## Summary, graphical clients

* A GUI is genuinely better for three things: seeing the **commit** graph as a picture, staging by **hunk** or by line with a mouse, and clicking through code archaeology.
* Every GUI is a lossy façade over the same commands. The loss is worst exactly where Git is most interesting: rebase, cherry-pick, submodules, worktrees, force-pushing.
* When a rebase breaks — and it will — you need `git status`, `git rebase --abort` and `git reflog`. No dialog box replaces them.
* The command line is also the interface CI, hooks and coding agents drive, so it is not optional knowledge any more.
* Recommended split: **GUI for reading and staging, command line for anything that rewrites history.**
* The landscape by shape: **GitKraken** (the graph, drag-and-drop merges), **Fork** (fast and complete, does not hide Git), **Sublime Merge** (fast, shows you the commands), **Tower** (thorough, wide undo), **GitHub Desktop** (deliberately limited, kind to beginners), **GitUp** (live graph with undo, great for learning), **SmartGit** (enterprise depth, includes Linux), **Sourcetree** (Atlassian and Jira).
* `gitk`, `git gui` and `git citool` come from the Git project itself — old-looking, no telemetry, still useful. Whether they are installed depends on your packaging.
* `lazygit` and `gitui` are the terminal answer to the same need — see [Making the command line yours](1-git-tools.md "Making the command line yours").
* Choosing one: true graph, interactive rebase, submodules/LFS/worktrees, telemetry, and above all **does it show you the command it runs**.
