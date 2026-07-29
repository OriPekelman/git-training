---
title: Git Getting Started!
type: docs
---
# Git, from the inside out

Hello and welcome.

This course begins with a very simple observation: if you want to have a job in IT, no matter which one, knowing Git is not optional. Git is used everywhere.

There is no shortage of Git tutorials that hand you six commands and wish you luck. This is not one of them. Here we do something slightly unusual and, I promise, much more useful: **every time you type a command, we open the hood and look at what it did.** You will create a commit, and then you will go and read the commit — the actual file, in the actual directory, with the actual forty characters of hash. You will discover that a branch is a text file containing one line. You will find your own deleted work still sitting in the object store, waiting for you.

This costs a little more effort in the first hour. It pays for itself roughly forever, because the alternative is memorising incantations and panicking when one of them fails.

> :information_source:
> The course assumes you can open a terminal and are willing to type in it. It does not assume you know anything about version control, or about systems programming. If a terminal makes you nervous, [this gentle introduction](https://tutorial.djangogirls.org/en/intro_to_command_line/) is fifteen minutes well spent, and then come back.

## How to read this

Parts 1 and 2 are the course proper, and they are meant to be read in order, with your hands on the keyboard. Everything from Part 3 onward is more of a reference: dip in when you need it.

If you have never used Git at all, start at the beginning and do not skip [Inside the repository, inside the commit](docs/1-understanding-git/5-inside-git.md) — it is the chapter the rest of the course leans on.

If you already use Git daily and want the parts you probably do not know: [One repository, many working trees](docs/4-beyond-the-basics/1-git-worktree.md), [Abusing git notes for fun and profit](docs/4-beyond-the-basics/3-git-notes.md), and [Things inspired by Git](docs/4-beyond-the-basics/6-inspired-by-git.md).

## Table of contents

<!-- BEGIN GENERATED TOC (utilities/gen_toc.py) -->

### Part 1 — Understanding Git

What Git is, and what actually happens inside `.git` when you save your work.

1. [What is Git?](docs/1-understanding-git/1-what-is-git.md)
1. [Git and its ecosystem](docs/1-understanding-git/2-git-ecosystem.md)
1. [First steps, first Git commands](docs/1-understanding-git/3-first-git-commands.md)
1. [Let's save our work!](docs/1-understanding-git/4-save-work-with-git.md)
1. [Inside the repository, inside the commit](docs/1-understanding-git/5-inside-git.md)
1. [We know how to save... but how to modify? to delete ? to cancel?](docs/1-understanding-git/6-modify-delete-files-with-git.md)
1. [Playing with our revisions](docs/1-understanding-git/7-play-with-git-revisions.md)

### Part 2 — Collaborating

Branches, remotes, merges, conflicts, and how to recover when it goes wrong.

1. [Collaborate with Git](docs/2-collaborating/1-collaborate-with-git.md)
1. [Working with remote repositories](docs/2-collaborating/2-git-remote.md)
1. [Retrieve and send code](docs/2-collaborating/3-git-clone-pull-remote.md)
1. [A little structure please](docs/2-collaborating/4-git-repo-structure.md)
1. [Implement an efficient collaborative workflow](docs/2-collaborating/5-git-workflow.md)
1. [Keep a clean history, recover from mistakes](docs/2-collaborating/6-git-cleanup.md)

### Part 3 — The tooling ecosystem

The command line, the forges, the GUIs and the editor integrations.

1. [Making the command line yours](docs/3-tooling-ecosystem/1-git-tools.md)
1. [Hosting Git, and hosting it yourself](docs/3-tooling-ecosystem/2-git-hosting.md)
1. [Graphical Git clients](docs/3-tooling-ecosystem/3-git-guis.md)
1. [Editors, IDEs and the file browser](docs/3-tooling-ecosystem/4-git-ides.md)

### Part 4 — Beyond the basics

Worktrees, agents, notes, large files, data and models — and the ideas Git spawned.

1. [One repository, many working trees](docs/4-beyond-the-basics/1-git-worktree.md)
1. [Worktrees and agents, parallel work at machine speed](docs/4-beyond-the-basics/2-git-worktree-agents.md)
1. [Abusing git notes for fun and profit](docs/4-beyond-the-basics/3-git-notes.md)
1. [Big files, or how Git meets its limits](docs/4-beyond-the-basics/4-git-lfs.md)
1. [Git for data and models](docs/4-beyond-the-basics/5-git-data-science.md)
1. [Things inspired by Git](docs/4-beyond-the-basics/6-inspired-by-git.md)

### Part 5 — Git as the engine of automation

GitOps, continuous integration, continuous deployment, and a bag of tricks.

1. [GitOps](docs/5-automation/1-git-ops.md)
1. [Continuous integration with Git](docs/5-automation/2-git-ci.md)
1. [Deploying a simple static site](docs/5-automation/3-git-static-site.md)
1. [Continuous deployment](docs/5-automation/4-git-cd.md)
1. [Shining in society and amazing friends with Gitfoo](docs/5-automation/5-git-foo.md)

### Part 6 — Appendices

Installing Git, SSH keys and signing, and setting up a hosting account.

1. [Installing and configuring Git](docs/6-appendices/1-git-install.md)
1. [Configure Git with an SSH key](docs/6-appendices/2-git-ssh.md)
1. [Create and configure your GitHub or GitLab account](docs/6-appendices/3-github-gitlab.md)

<!-- END GENERATED TOC -->

## About

Written by Ori Pekelman. The examples are not decorative: they are regenerated against the installed Git by `utilities/scenario.sh`, so what you read is what the command actually prints. If you find something wrong, that is a bug — please report it.
