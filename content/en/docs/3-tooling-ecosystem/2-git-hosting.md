---
title: Hosting Git, and hosting it yourself
slug: "git-hosting"
weight: 22
---
# Hosting Git, and hosting it yourself

Let's start with the sentence that pays for this whole chapter, because once you have it, the rest of the industry stops being confusing.

**None of what a forge adds is Git.**

Browsing your code in a browser: not Git. Code review with inline comments on a diff: not Git. Issues, labels, milestones, project boards: not Git. CI pipelines, permissions, teams, SSO, protected branches, required reviewers: not Git. Releases with attached binaries, package registries, container registries, secret scanning, dependency alerts: not Git. Git gives you exactly none of that, and — this is the important part — it does not need any of it. A **remote** is a URL that speaks the Git protocol. That is the entire contract. Everything else GitHub, GitLab, Forgejo or Bitbucket put on top is *their* product, invented by them, stored in *their* database.

And here is the corollary, which is the single most useful thing you can know about forges:

> :information_source:
> **Your code is perfectly portable. Your issues, pull requests and CI configuration are the real lock-in.**
>
> Every clone of your repository is a complete copy of the whole history — that is what "distributed" means, and we spent Part 2 proving it. Moving your code from one forge to another is one command, and we will run it at the end of this chapter. Moving five years of issue threads, review conversations, labels, CI logs and release notes is an API scraping project, and moving them *faithfully* is usually impossible, because the destination does not have the same concepts.

So when you choose a forge you are not choosing where Git lives. You are choosing whose issue tracker and whose CI you are going to be married to. Choose accordingly.

## The players

Briefly and evenly, because this course is not an advertisement. What follows is about *shape* — what each one is for — not about pricing or feature checklists, which change faster than any book can track.

**GitHub.** The default, and the honest reason is network effects: it is where the people are, where the issues get reported, where the drive-by contributor already has an account. `Actions` is its CI, deeply woven into the repository (a YAML file in `.github/workflows/` and you have a pipeline). The `gh` command-line tool is genuinely good and makes pull requests scriptable from your terminal — see [Making the command line yours](1-git-tools.md "Making the command line yours") for where it fits alongside your other terminal tooling. Codespaces gives you a dev environment in a browser. Owned by Microsoft.

**GitLab.** The one you can self-host as a first-class option rather than an afterthought, and the one with the strongest *integrated* CI — GitLab CI was there before Actions and the pipeline model is still, to my taste, the more coherent of the two. The pitch is the whole DevOps suite in one product: plan, build, test, deploy, monitor. Whether that appeals depends entirely on whether you want one vendor for all of it.

**Bitbucket.** Atlassian's. The reason to be on Bitbucket is almost always that your organisation already lives in Jira, and the Jira integration is the point.

**Codeberg.** Run by a non-profit association (Codeberg e.V.) for free and open source software. It runs Forgejo. If you want a comfortable, familiar forge that is not owned by anybody's shareholders, this is the obvious place to look.

**Gitea** and **Forgejo.** Gitea began as a fork of **Gogs** — which is what the old version of this chapter recommended, and which the world has largely moved past. Gitea is a single Go binary that gives you a complete forge: web UI, issues, pull requests, CI, packages. In 2022 the Gitea project's trademark and domain were transferred to a newly created for-profit company, Gitea Ltd. Part of the community objected to that governance change and forked the code as **Forgejo**, which is now developed under the umbrella of Codeberg e.V. Both are alive, both are excellent, and the differences are more about who steers them than about what they can do. That is the whole story, and it is worth knowing only because you will see both names and wonder.

**sourcehut** (`sr.ht`). Deliberately minimal, mailing-list-native, and it works without JavaScript. Contributions arrive as patches by email — `git send-email`, the way the Linux kernel has always done it. It feels archaic until you have used it for a while, and then it feels like someone removed a great deal of noise. If the email workflow interests you, it is the best place to meet it.

**Radicle.** Peer-to-peer. There is no server: repositories, and the issues and patches attached to them, gossip between peers. It is the only entry on this list that is trying to answer "what if the forge itself were distributed, like Git is?" Young, and interesting for exactly that reason.

**Azure DevOps** and **AWS CodeCommit.** The cloud vendors' own Git hosting. The reason to use one is that your organisation is already entirely inside that cloud and wants one bill and one identity provider. Almost no open source lives on them.

> :warning:
> Vendor forges are the ones most likely to change status under you: repriced, folded into another product, or closed to new sign-ups. Before you build a company's workflow on any hosted forge — and especially on a cloud vendor's side-project forge — go and read its current documentation and pricing page yourself. Anything a book tells you about a commercial service's availability is out of date by the time you read it.

## Jurisdiction, and the European forges

Here is a selection criterion that barely existed when the first version of this course was written, and which now comes up in most procurement conversations: **where, legally and physically, does the code sit?**

Three things turned that from a hypothetical into a question with a budget line. **GDPR** gave "where is this data processed, and under whose law" a precise legal meaning and an enforcement mechanism. **Consolidation** concentrated the field — GitHub is Microsoft's, Bitbucket is Atlassian's — so "pick a different vendor" stopped being much of a hedge. And **training-data scraping** turned "who can read my code" from a philosophical question into an operational one, which is the same worry as the line at the end of this chapter about whose model your source ends up in.

Be precise about what a European forge does and does not buy you, because the marketing around this is thick. It gives you a jurisdiction, usually a **DPA** — a data processing agreement, the contract that actually says what the operator may do with your data — and an operator who is not structurally obliged to hand things to a foreign government. It does not give you better uptime, a better product, or immunity from being acquired. It is a governance choice, exactly like self-hosting, and it should be argued on those terms.

### The public forges

We have already met two of these under [The players](#the-players): **Codeberg**, the Berlin non-profit running Forgejo, which is the obvious first stop for free and open source work; and **sourcehut**, the minimal email-driven forge, which is European-operated and still cheap — the paid tiers have hovered around a couple of euros a month, so check the current page rather than this sentence.

The others worth knowing by name:

**Framagit.** A public GitLab instance run by **Framasoft**, a French non-profit with a long history of running free services as a deliberate alternative to the large platforms. Free, French-hosted, and popular with civic-tech and associative projects. If you want a familiar GitLab interface without being GitLab's customer, this is it.

**GNU Savannah.** The Free Software Foundation's forge, and the oldest thing on this list by a wide margin. It is strict: `savannah.gnu.org` is for official GNU packages, and `savannah.nongnu.org` for other projects that are free software by the FSF's definition. The interface is from another era. It is on this list because it is genuinely durable — it has outlived most of its contemporaries — and because that strictness is the point, not an oversight.

**Pushin.eu.** A newer Dutch-operated entrant (PCX IT), running on bare metal in Scaleway's Paris datacentres with no US failover, and taking an explicit position against AI training on hosted code. As of this writing it is an invite-only beta, with general availability targeted for 2027 and pricing said to be comparable to GitHub and GitLab. 

> :information_source:
> Fast-moving: Pushin.eu's status and pricing may change as it moves from beta to GA. Check current information before relying on it.

**Codebahn.** Swedish-operated, French-hosted, paid, and built on Forgejo. Its differentiator is contractual rather than technical: a published DPA, which is exactly the artifact a European legal department will ask for and which most free forges cannot offer.

You will also see **Tangled** and **Plain** in curated lists. They are new enough that the useful advice is simply to check whether they still exist, and who is paying for them, before you rely on either.

And for the no-operator-at-all position, **Radicle** is covered under [The players](#the-players) — it is the only entry here with no server to be in a jurisdiction at all.

| Service | What it is | Operated / hosted | Cost |
| --- | --- | --- | --- |
| Codeberg | Forgejo, non-profit | Germany | Free |
| Framagit | GitLab, non-profit | France | Free |
| GNU Savannah | FSF forge, free software only | EU / US | Free |
| sourcehut | Minimal, email workflow | Europe | Low paid tiers |
| Pushin.eu | Forge, sovereignty-focused | Netherlands / Paris | Beta; paid later |
| Codebahn | Forgejo, with a DPA | Sweden / France | Paid |
| Radicle | Peer-to-peer, no operator | Nowhere in particular | Free |
| Forgejo, Gitea, Gogs, GitLab CE, OneDev | Software you run | Your own machine | Free |

A rule of thumb, offered as one: **Codeberg or Framagit** for a free public home; **Codebahn or Pushin.eu** if you need a paid operator and a signed DPA; **Radicle** if you want no central operator; **Forgejo on your own VPS** — Hetzner, Scaleway, OVH — if you want the whole thing under your control. That last one is the next section, and it is not free in the way the table suggests.

> :warning:
> Much of the writing that ranks these services is published by sites whose business *is* European digital sovereignty, and several of the "EU alternative" directories are marketing surfaces rather than neutral comparisons. Read them for the checkable facts — which engine it runs, which company operates it, which country the servers are in, whether there is a DPA, what it costs — and discard the rankings. Those facts you can verify yourself in ten minutes; the rankings you cannot.

> :information_source:
> One thing does not change whichever box you tick: **`git clone` still gives everyone a complete copy of the history.** A forge choice is reversible in a way that almost no other infrastructure decision is, which is a good reason not to agonise over it — and an excellent reason to keep the exit rehearsed. We do exactly that in [Migration and exit](#migration-and-exit).

## Self-hosting

This is the section that earns the chapter, because you can do all of it, right now, on your own machine.

The reason to self-host is not usually money. It is sovereignty: your source code is arguably the most valuable thing your organisation owns, and there is something to be said for it living somewhere you control. Air-gapped networks, regulated industries and paranoid individuals all end up here.

### The minimum viable Git server: a bare repository and ssh

The whole thing is one command. A **bare** repository is a repository with no working area — just the `.git` innards, promoted to be the directory itself. It exists to be pushed to.

Let's build one for real. Make a scratch directory anywhere and run:

```console
git init --bare project.git
```

Look inside it:

```console
ls -F project.git
```

```console
config
description
HEAD
hooks/
info/
objects/
refs/
```

Recognise every single one of those? You should — this is exactly the `.git` directory we took apart in Part 1, with the working area removed. `objects/` holds the **blob**s, **tree**s and **commit**s. `refs/` holds the **branch**es and **tag**s. There is no `index`, because there is nothing to stage. A bare repository has a `bare = true` line in its `config` and that is essentially the only difference.

> :information_source:
> The `.git` suffix on the directory name is pure convention, and a good one: it tells the next human that this is a bare repository and not a checkout they can edit.

Now clone it, exactly as you would clone anything:

```console
git clone project.git myproject
```

```console
Cloning into 'myproject'...
warning: You appear to have cloned an empty repository.
done.
```

Commit something and push it:

```console
cd myproject
echo "# My project" > readme.md
git add readme.md
git commit -m "Initial commit"
```

```console
[main (root-commit) 4c3419c] Initial commit
 1 file changed, 1 insertion(+)
 create mode 100644 readme.md
```

```console
git push origin main
```

```console
To ../project.git
 * [new branch]      main -> main
```

That is a Git server. Not a toy version of one — a real one, with the same object store, the same refs and the same protocol as anything you have ever pushed to. Clone it again into a second directory and you have two developers sharing a repository.

The only thing that changes when the repository lives on another machine is the URL. Put the bare repository at `/srv/git/project.git` on a box you can ssh into, and:

```console
git clone you@git.example.com:/srv/git/project.git
```

Git runs `ssh you@git.example.com` and asks it to execute `git-upload-pack` on the far side. That is it. That is the entire "server". There is no daemon to install, no port to open beyond the ssh port you already have, no database. Everyone who can ssh in and has filesystem permission on that directory can push.

> :warning:
> Two people pushing to a *non-bare* repository is where beginners get hurt: the receiving repository's working area does not update, so it ends up disagreeing with its own **HEAD** and the next person to log in is very confused. Git will usually refuse outright (`refusing to update checked out branch`). Shared repositories are bare. Always.

### Giving out access without giving out shell accounts

The naive version above gives every developer a Unix login. You do not want that. The classic fix, which ships with Git itself, is `git-shell` — a login shell that permits nothing except the handful of server-side Git commands:

```console
git shell --help
```

The manual page's own synopsis tells you how it is meant to be used: `chsh -s $(command -v git-shell) <user>`. So you create one Unix user, conventionally called `git`, set its shell to `git-shell`, and then everyone's ssh public keys go into that single user's `~/.ssh/authorized_keys`. Anyone who authenticates lands in a shell that can push and fetch and cannot do anything else — try `ssh git@host` interactively and you get shown the door.

You can tighten it further with the options `authorized_keys` supports:

```
command="/usr/bin/git-shell -c \"$SSH_ORIGINAL_COMMAND\"",no-port-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAA... alice
```

The `command=` prefix means "whatever this key asks for, run *this* instead". Forwarding and pty allocation are switched off, so the key cannot be used as a tunnel.

> :warning:
> That is one shared account, so it is all-or-nothing: every key in that file can push to every repository, and delete every branch. There is no notion of "Alice may push to `main`, Bob may not". For a three-person team that trusts each other, fine. Beyond that you want the next step.

### gitolite, for actual access control

`gitolite` is the classic answer: a single Perl program that sits behind that same `git` user and consults a configuration file to decide who may do what. The elegant part is that its configuration *is a Git repository* — you clone `gitolite-admin`, edit a text file, add a public key, commit, push, and the server reconfigures itself. Access control as version-controlled data.

The rules look roughly like this:

```
repo project
    RW+     =   alice
    RW      =   bob
    R       =   @interns
```

`R` is read, `RW` is push, `RW+` is push including the force-pushes and branch deletions that rewrite history — and note how neatly that maps onto the thing we insisted on in Part 2, that you do not rewrite shared history. Here you can simply not grant it. Rules can be per-branch too, which is how you get "nobody force-pushes `main`" without a web UI anywhere in sight.

No web interface, no issues, no CI. Just Git and permissions, on a box, forever. There is a lot to like about that.

### A whole forge: Gitea or Forgejo

When you do want the web UI, the issues, the pull requests and the CI, and you want them on your own hardware, this is where to go. Both are a single binary plus a database, and both are genuinely comfortable to run — a small VPS is enough for a team.

The shape of a `docker-compose.yml`, to give you the idea:

```yaml
services:
  forgejo:
    image: codeberg.org/forgejo/forgejo:VERSION
    restart: unless-stopped
    environment:
      - FORGEJO__database__DB_TYPE=sqlite3
    volumes:
      - ./data:/data
    ports:
      - "3000:3000"
      - "222:22"
```

Two ports, because a forge is two servers wearing one coat: HTTP for humans and browsers, ssh for `git push`. One volume, which holds the repositories, the database and the uploads — and which is therefore the thing you must back up. Replace `VERSION` with a real published tag rather than using `latest`, put a reverse proxy in front for TLS, and read the project's own installation documentation before you trust it with anything, because deployment details are exactly the sort of thing that goes stale in a book.

### What you just signed up for

Running a forge is not hard. Running one *well*, for years, is a job. Honestly:

* **Backups.** Not optional, and see the warning below.
* **TLS.** Certificates, and their renewal, forever.
* **Spam and abuse**, the moment you allow public registration. Every public forge operator has a story.
* **Upgrades.** Security releases arrive on the upstream project's schedule, not yours, and database migrations mean you cannot skip five versions.
* **Uptime.** Your CI is now your problem at 3am. So is the disk filling up.
* **Storage growth.** Repositories only get bigger, and if anyone enables **LFS** the object store can dwarf the repositories themselves.

> :warning:
> **A clone is not a backup.** This is the mistake that costs people their week.
>
> A `git clone` — even a mirror clone — copies the Git repository. Faithfully and completely, which is exactly why it feels like a backup. But it does not contain: issues, pull requests and their review threads, wikis, releases and their uploaded binaries, CI configuration and history, webhooks, deploy keys, or user and permission data. None of that is in Git. It is in the forge's database.
>
> **LFS** objects are not in the clone either unless you explicitly fetch them — see [Big files, or how Git meets its limits](../4-beyond-the-basics/4-git-lfs.md "Big files, or how Git meets its limits"), which is also where the "does my server support LFS?" question gets answered, because LFS needs cooperation from the far end and not every host provides it.
>
> A real backup of a self-hosted forge is a snapshot of its data volume *and* a dump of its database, restored somewhere occasionally to prove it works. An untested backup is a rumour.

And if what you actually want is not a forge but automatic deployment when you push, that is a `post-receive` hook on precisely the kind of bare repository we just built — twelve lines of shell. We build one end to end in [Deploying a simple static site](../5-automation/3-git-static-site.md "Deploying a simple static site").

## Migration and exit

Now the promise from the top of the chapter, kept. Moving the code is two commands.

`git clone --mirror` makes a bare clone that copies *every* ref exactly as it is on the source — all branches, all tags, all notes — rather than just the branches you would normally track:

```console
git clone --mirror project.git mig.git
```

```console
Cloning into bare repository 'mig.git'...
done.
```

```console
cd mig.git
git show-ref
```

```console
4c3419c10ae9e130fa0f6d1380bef47ae95dd36e refs/heads/main
10e6bad5e03f8df0045fcea75ec4359d57acbeca refs/heads/topic
0acd489d251b48c651986e90272114900a49e495 refs/tags/v1.0
```

Two branches and a tag, all present. Now point it at the new home and push the mirror image back out:

```console
git remote set-url origin ../newhome.git
git push --mirror origin
```

```console
To ../newhome.git
 * [new branch]      main -> main
 * [new branch]      topic -> topic
 * [new tag]         v1.0 -> v1.0
```

And at the destination:

```console
git show-ref
```

```console
4c3419c10ae9e130fa0f6d1380bef47ae95dd36e refs/heads/main
10e6bad5e03f8df0045fcea75ec4359d57acbeca refs/heads/topic
0acd489d251b48c651986e90272114900a49e495 refs/tags/v1.0
```

Identical **SHA**s, because the objects are content-addressed and nothing about them depends on where they are stored. Your history did not "move" so much as get copied byte-perfect. Replace the two local paths with two forge URLs and you have migrated a repository between hosts. In real life you will also want to check the source for **LFS** objects (they migrate separately, with `git lfs fetch --all` and `git lfs push --all`) and to remember that `--mirror` on the push side is destructive at the destination: it makes the target match the source, deleting refs that are not in the mirror. Push to an empty repository.

> :warning:
> `git push --mirror` will happily delete branches at the destination that do not exist in your mirror. Never point it at a repository someone else is using.

Everything else needs the API. The forges know this and most of them ship importers — GitLab, Gitea and Forgejo can all pull a repository *plus* its issues and pull requests from GitHub given a token, and they do a decent job. Expect losses at the edges: nested comment threads, reactions, review states, automation, and anything that maps onto a concept the destination does not have. Budget real time for it, and do it once rather than twice.

## On durability, and who owns the copy

A short closing thought, not a sermon.

Self-hosting is usually presented as a cost decision. It is not. It is a governance decision: who can read your code, who can revoke your access, who gets to change the terms, and whose model your source ends up in. Those are legitimate questions with legitimate answers in both directions — plenty of serious organisations are on GitHub on purpose, because being where the contributors are is worth something real.

But one thing is not a matter of taste: **"it's on GitHub" is not an archival strategy.** A company can be acquired, a policy can change, an account can be suspended by mistake, a repository can be deleted by its owner. If a piece of software matters in ten years, something other than its vendor needs to be holding a copy.

The organisation that actually does this work is [Software Heritage](https://www.softwareheritage.org/), which systematically crawls and permanently archives public source code — commit history included — as cultural heritage. It is free, it is not a forge, and if your project is public you can ask it to save your repository today. It costs you nothing and it is the closest thing our field has to a library.

And in the meantime, notice that you already have the beginnings of a distributed archive: every colleague's laptop holds a complete copy of the history. Git was designed by someone who did not want a single point of failure. It would be a shame to reintroduce one.

## Summary, hosting and forges

* **A forge is not Git.** Web UI, code review, issues, CI, permissions, releases and registries are the host's product, not part of Git.
* **Code is portable; issues, pull requests and CI configuration are the lock-in.** Plan your exit before you need it.
* The players, by shape: **GitHub** (network effects, Actions, `gh`), **GitLab** (self-hostable, integrated CI), **Bitbucket** (Jira), **Codeberg** (non-profit, runs Forgejo), **Gitea**/**Forgejo** (self-hosted forge in one binary; forked in 2022 over governance), **sourcehut** (email/patch workflow, minimal), **Radicle** (peer-to-peer), plus the cloud vendors' own.
* **Jurisdiction is a selection criterion now**, driven by GDPR, vendor consolidation and training-data scraping. European public forges: **Codeberg** (Germany, free), **Framagit** (France, free, GitLab), **GNU Savannah** (FSF, free software only), **sourcehut**, **Pushin.eu** (beta) and **Codebahn** (paid, with a published **DPA**). A European operator buys you a jurisdiction and a contract — not uptime, not a better product, and not immunity from acquisition.
* Read the "EU alternative" directories for checkable facts — engine, operator, country, DPA, price — and ignore their rankings, because most of them sell sovereignty for a living.
* `git init --bare` creates a repository with no working area — the thing you push to. A bare repository plus ssh *is* a Git server.
* Shared repositories must be bare; pushing to a checked-out branch breaks the receiving working area.
* `git-shell` is a restricted login shell that allows only Git's server-side commands; combine it with one `git` user and `command=` restrictions in `authorized_keys`.
* `gitolite` adds per-repository and per-branch access control, configured through a Git repository you push to.
* **Gitea**/**Forgejo** give you a full forge on your own hardware; a single binary, a database, and a volume you must back up.
* Self-hosting means owning backups, TLS, spam, upgrades, uptime and storage growth.
* **A clone is not a backup**: it contains no issues, pull requests, wikis, releases, CI configuration or **LFS** objects.
* `git clone --mirror` then `git push --mirror` moves all refs and objects between hosts, byte for byte. `--mirror` on push is destructive at the destination.
* **LFS** objects migrate separately, and everything that is not Git needs the forge's API or importer.
* Software Heritage, not your forge, is what actually archives source code for the long term.
