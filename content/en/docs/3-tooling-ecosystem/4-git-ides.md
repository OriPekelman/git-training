---
title: Editors, IDEs and the file browser
slug: "git-ides"
weight: 24
---
# Editors, IDEs and the file browser

The previous chapter was about dedicated Git clients — programs whose whole job is Git. This one is about the Git integration in the tool you actually spend your day inside. And that distinction matters more than it sounds, because the integration in your editor has one advantage no standalone client can ever have: **it already knows which line you are looking at.**

That is the whole argument. "Who changed this line, and why" is the most common question anyone asks a version control system, and your editor is the only tool that can answer it without you first telling it where to look.

## Visual Studio Code

Most likely the tool the largest number of readers of this chapter are using, so let's be concrete.

Git support is built in, not an extension. The **Source Control** view lists changed files, and clicking one opens a side-by-side diff rather than just showing you the file. You stage from there — and you can stage a single **hunk** or a selected range of lines from the diff view, which is the `git add -p` we talked about in the last chapter, with a mouse. There is a commit message box, and the sync/push/pull controls live in the status bar.

Two built-in things are worth naming specifically:

**The three-way merge editor.** When a merge conflicts, VS Code can show you three panes — "Incoming", "Current" and the Result you are building — instead of dropping you into a file full of `<<<<<<<` markers. Given how much confusion those markers cause the first ten times you meet them, this is genuinely valuable, and it is the one case where I think a graphical tool is *straightforwardly better* than the raw text. You are not being protected from anything; you are seeing the same three versions Git is seeing, laid out so a human can compare them.

**Timeline.** In the Explorer sidebar, a per-file chronology that mixes Git history with local file saves. Very handy for "this file worked an hour ago" — including in the cases where the change was never committed at all.

The extensions people actually install:

* **GitLens.** The big one. Inline **blame** at the end of the line your cursor is on — author, date, commit message, right there — plus rich hovers, a file history view, a commit graph, and "open the line's commit" navigation. If you install one Git extension, this is it. It is also the fastest way to develop the reflex of *asking* who wrote a line, because the answer is already on screen.
* **Git Graph.** Draws the **commit** graph, properly, in a tab. Does what the previous chapter said a GUI is for, without leaving the editor.
* **GitHub Pull Requests.** Review pull requests inside the editor: check out a PR branch, read the diff with the surrounding code available, leave inline comments, approve. Reviewing code in a browser means reviewing it without the ability to jump to a definition, which is a bad way to review code. This fixes that.

> :information_source:
> All of the VS Code forks — Cursor, Windsurf, VSCodium and friends — inherit this entire stack, because they are VS Code underneath. The Source Control view, the merge editor and the extension ecosystem are all there. If you have moved to one of the AI-first forks, nothing in this section changes.

## JetBrains: IntelliJ IDEA, PyCharm, WebStorm, GoLand, Rider

Plainly, and I do not think this is controversial: **this is the best-in-class Git integration in any IDE.** If you already work in a JetBrains IDE, you probably do not need a separate Git client at all.

What earns that claim:

**Local History.** Start here, because it is the feature that has saved the most people, and it is **not Git.** The IDE keeps its own timestamped record of every change to every file — edits, refactorings, deletions, file moves — independently of whether you ever committed, staged, or even saved deliberately. Right-click a file (or a directory, or the project) and you get "Local History → Show History", with diffs and one-click revert.

> :warning:
> Local History is a safety net for the work you have *not* committed yet — the hour of editing you were about to lose. It is not version control: it is local, it expires, it is not shared, and it does not survive reinstalling the IDE or working from another machine. Use it to recover from an accident, then commit properly. It is a fire extinguisher, not a fire station.

**Conflict resolution.** The three-pane merge tool, but with the IDE's understanding of the language in it: it can recognise and auto-apply non-conflicting changes, highlight the ones that genuinely clash, and let you edit the result with full completion and syntax awareness. Resolving a conflict in a file you can still navigate is a different experience from resolving one in a text editor.

**Shelve versus stash.** JetBrains offers both and the distinction is worth learning. `git stash` is Git's own mechanism, which we met in Part 2 — it lives in the repository and any Git tool can see it. A *shelf* is the IDE's own: a saved patch, held outside Git, which you can name, keep as long as you like, apply partially (file by file, or hunk by hunk), and hand to a colleague as a file. Use `stash` for "hold this for five minutes"; use a shelf for "keep this experiment around for a fortnight while I do something else".

**Annotate.** Right-click the gutter → Annotate with Git Blame, and every line grows an author and a revision. Click one and you are in that commit. It is the same idea as GitLens and it is built in.

**Interactive rebase from the log.** In the Git log view, select a range of commits and you get a graphical interactive rebase: drag to reorder, mark for squash, reword, drop. It is the clearest presentation of `git rebase -i` I have seen anywhere — which does not mean you should learn the operation here first. Learn what it does from the command line, where you can see the todo list Git is actually building, and then enjoy the nice version.

## Neovim and Vim

**`vim-fugitive`.** Tim Pope's, and the reason many Vim users have never installed a Git client. It makes `:Git` a first-class command — `:Git blame` opens a scrollbound blame pane you can navigate, `:Git` alone opens a status buffer where you stage and unstage with a keypress, `:Gdiffsplit` puts the index and working versions side by side as two buffers so you can *resolve a conflict by editing across windows*. That last one is the trick: it turns Git operations into buffer manipulation, which is the thing Vim is already best at.

**`gitsigns.nvim`.** Signs in the gutter for added, changed and removed lines, plus the operations you want on them right there: stage a hunk, reset a hunk, preview a hunk, jump to the next one, and inline blame for the current line. This is the one that changes your daily habits, because staging a single hunk becomes two keystrokes.

**`diffview.nvim`.** A proper diff and file-history browser: review all the changes of a branch, or the history of a single file, or a merge conflict, in a real three-way layout.

**`neogit`.** An explicit attempt to bring the Magit experience — see immediately below — to Neovim. A single status buffer that is also a menu system, where you press keys to build up Git commands. If the paragraph that follows appeals to you and you are not going to move to Emacs, this is your route.

## Emacs: Magit

Magit deserves its own paragraph, and not out of politeness.

It is arguably the best interface to Git that anyone has built, in any form. The design is a status buffer that is simultaneously a display and a control surface: everything about the repository's current state is shown as collapsible sections — untracked files, unstaged changes, staged changes, unpushed commits, stashes — and every one of them is actionable where it sits. Put the cursor on a hunk and press `s` to stage it. On a line within a hunk, with a region selected, `s` stages *those lines*. `c c` commits. `b b` switches branch. `r i` starts an interactive rebase, presented as a menu of what you can do next.

The thing that makes it different from every other Git UI is the discoverability. Press a prefix key and Magit shows you a menu — the available commands, their flags, and what each flag means — so you learn Git's actual vocabulary by using the interface, rather than instead of it. Flags you toggle in the menu correspond to real command-line options. Nothing is hidden.

Which is why the following is true, and why I mention it in a course built on the command line: **some people genuinely learn Git through Magit**, and they end up understanding it better than average, not worse. It is the one graphical interface I would call *pedagogical*. If you already use Emacs, use Magit. If you do not use Emacs, this is one of the two or three arguments people actually give for starting.

## Zed and Helix

**Zed** has Git support built in and documented: a Git panel showing the working tree and the staging area, a project-wide diff view where you stage or unstage individual hunks, per-file history, branch creation and switching, stash, worktrees, fetch/push/pull with remote selection, a merge-conflict resolution view, and clickable permalinks out to GitHub, GitLab, Bitbucket, sourcehut and Codeberg. It will also draft a commit message with an LLM if you ask it to — which, like all such offers, is fine for the boring commits and no substitute for saying *why* on the ones that matter.

**Helix** is a modal editor in the Vim lineage with a deliberately different philosophy about plugins and built-ins. Rather than freeze a moving target into a book, go and read its own documentation for what its Git support covers today — it is short, and it will be accurate.

## Windows, and the file browser

Windows deserves its own section because the integration point there is different: it is the file manager.

**TortoiseGit** puts Git into the Windows Explorer shell. Overlay icons on file and folder icons tell you at a glance what is modified, staged, ignored or clean; right-clicking anything gives you a context menu of Git operations; and there are proper dialogs for commit, log, diff, blame and merge. For people who think about their project as folders rather than as a repository — and for the many roles in a company that are not full-time developers — this is a genuinely good way in. Note that it is Explorer integration, not an editor plugin, so it composes with whatever else you use. (Its ancestor TortoiseSVN did the same job for Subversion, which is why the naming feels like it comes from another era; it does.)

**Git for Windows** is the package that gives you `git` itself, plus **Git Bash** — an msys2-based shell that means every command in this course works, unmodified, on Windows. It also brings `gitk` and `git gui` along, and installs the credential manager that handles authenticating to forges.

**WSL2** is what I would recommend to a Windows developer today, and the reason is not ideology: it is that essentially every tool, hook, script and CI configuration in the Git world is written assuming a Unix shell, and under WSL2 you simply have one. Line endings, file permission bits, shell hooks and `#!` lines all stop being special cases.

> :warning:
> There is one real WSL2 trap and it is a performance cliff: keep your repositories *inside* the Linux filesystem, not on the mounted Windows drives under `/mnt/c/`. Crossing that boundary for every file operation makes Git operations dramatically slower on any repository of real size. [Installing and configuring Git](../6-appendices/1-git-install.md "Installing and configuring Git") covers this, along with the `core.autocrlf` question that everyone on Windows meets in their first week.

## The split that matters

Here is the opinion this chapter exists to deliver, and it is the same one the previous chapter arrived at from the other direction:

**Use your editor's integration for everything that *reads* the repository. Use the command line for everything that *rewrites* it.**

Reading — blame, history, diffs, hunk-level staging, "what did this file look like at that commit", searching the log — is where the graphical tool's extra information is pure profit. It knows your cursor position, it can render three panes side by side, it can put an author's name at the end of the line, and it costs you nothing to be wrong about a click. Read in the editor. Read a lot; most people do not read their repository nearly enough.

Rewriting — rebase, amend, reset, cherry-pick, filtering history, force-pushing — is where you need to know *exactly what ran*, because these are the operations where the repository afterwards is not simply the repository before plus something. **HEAD** moved, refs moved, commits were replaced by different commits with different **SHA**s, and the old ones are now reachable only through the **reflog**. When that goes sideways, your recovery depends entirely on being able to say what happened. "I clicked the button that said Rebase" is not something you can reason from. `git rebase --onto main feature~3 feature` is.

And notice that this is not a rule about trust. It is a rule about *reversibility*. Reading is free and wrong readings cost nothing. Rewriting is where the cost lives, so that is where you want your hands on the actual controls.

There is one exception I will make happily, and it is the merge editor. When a conflict happens, the three-pane view in VS Code or JetBrains is better than the marker-filled file, and it is not doing anything behind your back — the same three versions, arranged for a human. Take it.

## Summary, editors and IDEs

* Your editor's Git integration has one advantage no standalone client has: it knows which line you are looking at, so "who changed this and why" is always one gesture away.
* **VS Code**: built-in Source Control view, hunk- and line-level staging from the diff, the three-way merge editor, and the Timeline (which includes uncommitted local saves). Extensions that matter: **GitLens** (inline blame, history, graph), **Git Graph**, **GitHub Pull Requests** (review with code navigation available). The VS Code forks inherit all of it.
* **JetBrains** IDEs have the best-in-class integration: **Local History** (not Git — a local safety net that expires and is not shared), a language-aware conflict resolver, **shelve** alongside `git stash`, **Annotate** for blame, and graphical interactive rebase from the log view.
* **Vim/Neovim**: `vim-fugitive` (`:Git` as a first-class interface, conflict resolution across buffers), `gitsigns.nvim` (gutter signs plus stage/reset/preview hunk), `diffview.nvim`, `neogit`.
* **Emacs: Magit** — a status buffer that is also a control surface, with discoverable menus that teach you Git's real vocabulary. Some people learn Git through it, and learn it well.
* **Zed** documents a Git panel, staging area, hunk staging, file history, branches, stash, worktrees, conflict resolution and forge permalinks. For **Helix**, read its own documentation.
* **Windows**: **TortoiseGit** for Explorer shell integration and overlay icons, **Git for Windows** / **Git Bash** so the Unix commands in this course just work, and **WSL2** as the recommendation — but keep repositories inside the Linux filesystem, not under `/mnt/c/`.
* **The split: editor for reading, command line for rewriting.** Reading is free; rewriting is where you need to know exactly what ran. The graphical merge conflict editor is the exception worth taking.
