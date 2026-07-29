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

If you have never used Git at all, start at the beginning and do not skip [Inside the repository, inside the commit](docs/P1C5.md) — it is the chapter the rest of the course leans on.

If you already use Git daily and want the parts you probably do not know: [One repository, many working trees](docs/P4C1.md), [Abusing git notes for fun and profit](docs/P4C3.md), and [Things inspired by Git](docs/P4C6.md).

## Table of contents

<!-- BEGIN GENERATED TOC (utilities/gen_toc.py) -->

### Part 1 — Understanding Git

What Git is, and what actually happens inside `.git` when you save your work.

1. [What is Git?](docs/P1C1.md)
1. [Git and its ecosystem](docs/P1C2.md)
1. [First steps, first Git commands](docs/P1C3.md)
1. [Let's save our work!](docs/P1C4.md)
1. [Inside the repository, inside the commit](docs/P1C5.md)
1. [We know how to save... but how to modify? to delete ? to cancel?](docs/P1C6.md)
1. [Playing with our revisions](docs/P1C7.md)

### Part 2 — Collaborating

Branches, remotes, merges, conflicts, and how to recover when it goes wrong.

1. [Collaborate with Git](docs/P2C1.md)
1. [Working with remote repositories](docs/P2C2.md)
1. [Retrieve and send code](docs/P2C3.md)
1. [A little structure please](docs/P2C4.md)
1. [Implement an efficient collaborative workflow](docs/P2C5.md)
1. [Keep a clean history, recover from mistakes](docs/P2C6.md)

### Part 3 — The tooling ecosystem

The command line, the forges, the GUIs and the editor integrations.

1. [Making the command line yours](docs/P3C1.md)
1. [Hosting Git, and hosting it yourself](docs/P3C2.md)
1. [Graphical Git clients](docs/P3C3.md)
1. [Editors, IDEs and the file browser](docs/P3C4.md)

### Part 4 — Beyond the basics

Worktrees, agents, notes, large files, data and models — and the ideas Git spawned.

1. [One repository, many working trees](docs/P4C1.md)
1. [Worktrees and agents, parallel work at machine speed](docs/P4C2.md)
1. [Abusing git notes for fun and profit](docs/P4C3.md)
1. [Big files, or how Git meets its limits](docs/P4C4.md)
1. [Git for data and models](docs/P4C5.md)
1. [Things inspired by Git](docs/P4C6.md)

### Part 5 — Git as the engine of automation

GitOps, continuous integration, continuous deployment, and a bag of tricks.

1. [GitOps](docs/P5C1.md)
1. [Continuous integration with Git](docs/P5C2.md)
1. [Deploying a simple static site](docs/P5C3.md)
1. [Continuous deployment](docs/P5C4.md)
1. [Shining in society and amazing friends with Gitfoo](docs/P5C5.md)

### Part 6 — Appendices

Installing Git, SSH keys and signing, and setting up a hosting account.

1. [Installing and configuring Git](docs/P6C1.md)
1. [Configure Git with an SSH key](docs/P6C2.md)
1. [Create and configure your GitHub or GitLab account](docs/P6C3.md)

<!-- END GENERATED TOC -->

## About

Written by Ori Pekelman. The examples are not decorative: they are regenerated against the installed Git by `utilities/scenario.sh`, so what you read is what the command actually prints. If you find something wrong, that is a bug — please report it.
