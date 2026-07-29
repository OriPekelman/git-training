---
title: Things inspired by Git
slug: "inspired-by-git"
weight: 36
---
# Things inspired by Git

We have spent a long time in the machine room. We opened `.git/objects` with our bare hands, we followed a **commit** to a **tree** to a **blob**, we watched a **branch** turn out to be a forty-character string in a file. We learned that a name in Git is derived from the content it names, and that this one trick buys integrity, deduplication and cheap comparison all at once.

Here is the reward for that work: the idea escaped.

Git's data model turned out to be a *general* idea, and over the last twenty years it walked out of version control and into databases, package managers, container registries, build caches, certificate authorities and collaborative text editors. Once you can read a **Merkle DAG** you can read the design docs of a dozen systems that have nothing to do with source code, and you will recognise the furniture.

That is what this chapter is: a guided tour of the furniture.

## What Git actually invented (and what it didn't)

Let's be honest first, because a chapter like this can easily turn into hagiography.

Git did not invent content addressing. Ralph Merkle described hash trees in the late 1970s. Plan 9's **Venti** was a content-addressed block store — blocks named by the hash of their bytes — years before Git existed. And **Monotone** was already using cryptographic hashes to name revisions when Linus went looking for a BitKeeper replacement in April 2005; his famous message to the kernel list told people not to bother telling him about Subversion and to "start reading up on 'monotone'" instead.

Git also did not invent distributed version control. Monotone, Darcs, GNU Arch and Mercurial were all in flight at the same time.

What Git got right was the *combination*, and the combination is genuinely a design achievement:

* a **Merkle DAG of immutable snapshots** — not diffs, not changesets, whole trees, each named by its hash;
* on top of that, **cheap mutable pointers** — refs, branches, tags, **HEAD** — which are the only things in the system allowed to change;
* a design in which **replication is the normal case**, not an add-on, so no copy is privileged and `git clone` is just "give me the objects I don't have";
* and an implementation fast enough that people put up with the interface.

That last clause is doing a lot of work. Let me say the slightly uncomfortable thing: Git's data model is beautiful, and Git's command-line interface is a historical accident. `git checkout` doing five unrelated jobs, the index leaking into every third error message, `--force-with-lease` — these are scar tissue, not design.

The systems in this chapter are, almost without exception, evidence of exactly that. They kept the model and threw away the interface.

> :information_source:
> Four words we will reuse constantly below. **Content addressing**: the name is a hash of the content. **Immutable log**: objects are never modified, only added. **Mutable pointers**: small named refs into that log. **Structural sharing**: two versions that mostly agree physically share the parts that agree. Keep those four in your hand and the rest of the chapter is easy.

## Databases that borrowed the model

### Dolt

**Dolt** is the purest expression of "let's take Git's model somewhere else". It is a SQL database — MySQL wire-protocol compatible, so ordinary MySQL clients and drivers connect to it without knowing anything is unusual — whose storage *is* a commit graph.

You do not commit files. You commit rows.

```console
dolt sql -q "update employees set salary = salary * 1.1 where team = 'infra'"
dolt diff
dolt commit -am "Annual raise for the infra team"
dolt checkout -b experiment
dolt merge main
```

And because it is a database, the version control is queryable. `dolt_log` and `dolt_diff` are system tables, so "who changed this row and why" is a `SELECT`, not an archaeology project:

```console
dolt sql -q "select * from dolt_log limit 5"
dolt sql -q "select * from dolt_diff_employees where to_commit = 'HEAD'"
```

Branches can be addressed as if they were separate databases, which means a preview environment can be a branch name in a connection string. **DoltHub** is the hosted forge — the GitHub of this world, complete with pull requests over data.

> :information_source:
> Dolt is not a fork of MySQL and contains no MySQL code; the compatibility is reimplemented. The same team ships **Doltgres** (the Postgres-flavoured sibling, in beta through 2026 with a 1.0 announced for August 2026) and **DoltLite** (a versioned drop-in for SQLite, embeddable). As of mid-2026 Dolt 2.0 is the current major version, which added automatic garbage collection and compression of the object store — a problem you will recognise, because it is `git gc`.

### Why Git's blobs would not have worked: prolly trees

Here is the deepest idea in this chapter, and it is worth slowing down for.

Suppose you naively did Git-for-databases: store each table as one big **blob** and build a Merkle DAG of those blobs. You would get history, and you would get integrity. You would also get two disasters.

First, **diffs would cost the size of the table**. Change one row in a ten-million-row table and the blob's hash changes, so the only way to know *what* changed is to read both versions end to end. Git gets away with this because source files are small and there are lots of them; a table is one enormous file.

Second, **you would have no indexed lookup at all**. `WHERE id = 42` in a blob means a scan.

The classic fix for the second problem is a **B-tree**, which is what every SQL database uses. But a B-tree is *history dependent*: its internal shape depends on the order the writes arrived. Two B-trees holding identical data can have completely different internal structure, so they cannot share storage and they cannot be compared cheaply. Exactly the two properties we need.

A **prolly tree** — "probabilistic B-tree", also described as a content-addressed B-tree — is the fix for both at once. It is a B-tree whose node boundaries are chosen by a rolling hash of the content rather than by insertion order, and whose nodes are named by the hash of their contents. Two consequences fall out:

* **It is history independent.** The same set of rows always produces the same tree, and therefore the same root hash, no matter what order you inserted them in. So identical subtrees between two versions are literally the same node, shared — structural sharing, exactly as Git shares an unchanged **tree** object between commits.
* **Diff costs the size of the difference, not the size of the data.** To diff two versions you walk both roots; wherever the child hashes are equal you stop, because equal hash means equal subtree. Changing one row touches one leaf and the O(log n) nodes above it. Everything else compares equal on the first hash check.

And because it is still a B-tree underneath, ordered range scans and indexed seeks still work at roughly B-tree speed.

That is the whole trick: **content addressing gives you the cheap diff, the B-tree shape gives you the query, and history independence is what lets the two coexist.** Dolt's own documentation puts diff at O(d) where d is the size of the change, against O(n) for a B-tree.

> :information_source:
> Prolly trees were not invented by the Dolt team. They came out of **Noms**, an earlier "versioned, forkable, syncable database" by largely the same people. Noms itself is dead — the repository has been archived since 2021 — but its storage ideas are alive inside Dolt, and Dolt's docs credit it explicitly. A nice reminder that in this field ideas outlive products.

### Where Dolt actually fits

Dolt publishes its own sysbench numbers and as of Dolt 2.0 claims to be in the same neighbourhood as MySQL on that benchmark. Take that for what it is: a synthetic single-branch benchmark, run by the vendor.

Be realistic. Every read has to traverse a content-addressed tree, the engine is young, and the operational ecosystem around it — replication topologies, the ten years of tuning folklore, the people you can hire who already know it — is nothing like Postgres's or MySQL's. Nobody should move a high-write OLTP workload onto it because a chapter of a Git course sounded enthusiastic.

The sweet spot is **data that humans curate, review and need to audit**: reference data, pricing tables, configuration, taxonomies, ML training sets, public datasets. Anywhere you have ever wanted to ask "who changed this row, when, and what did the reviewer say", Dolt is answering a real question that a normal database answers badly.

### The neighbours

Once you see the pattern you find it everywhere in the data world, and each one borrowed a specific piece:

* **TerminusDB** — the same idea for a document-graph/knowledge-graph database: branch, diff, merge and time-travel over structured documents rather than tables, with changes stored as immutable delta layers. Worth a status note: stewardship of the open source project moved to a company called DFRNT in 2025 and it is still shipping releases (12.0.4 in February 2026), but this project has changed hands and changed product direction more than once, so check its health before you build on it.
* **lakeFS** — Git-like branching, committing and merging over object storage (S3 and friends). The borrowed idea is the one you already know from **worktrees**: a branch is a *pointer*, so branching a petabyte is a metadata operation that copies no objects at all. O(1) branches over a data lake. Actively developed, and Treeverse — the company behind it — acquired the DVC project in late 2025.
* **Apache Iceberg** and **Delta Lake** — the same insight arriving from the data-warehouse side rather than from Git. A table is an immutable log of metadata files pointing at immutable data files, so "time travel" is just reading an older metadata pointer. Iceberg has named refs (tags and branches) over its snapshots; **Project Nessie** goes further and gives you catalog-wide, cross-table branches and commits, which is the closest thing to a real repository in that ecosystem.
* **Neon** and **PlanetScale** — the "branch your database for every preview environment" pattern. Neon (serverless Postgres, acquired by Databricks in 2025) does copy-on-write branching of storage; PlanetScale branches schemas and merges them with *deploy requests*, which are pull requests for DDL. Neither is a Merkle DAG, and it is worth being precise about that — what they borrowed is not the storage model but the *social* model: cheap isolated copies plus a review step before a merge.

Cross-links: this is the same territory as [Worktrees](1-git-worktree.md "Worktrees") and [Git for data and models](5-git-data-science.md "Git for data and models"), from the other direction.

## Version control systems that learned from Git and moved on

A Git course should be honest about this: Git is not the last word, and the interesting successors are not toys.

### Jujutsu

**Jujutsu** — the command is `jj` — is the one to actually try. It is written in Rust, it is developed in the open at `jj-vcs/jj`, and as of July 2026 it is at version 0.43. Note the leading zero; more on that in a moment.

The decisive practical fact: **jj uses a Git repository as its storage backend.** You can run `jj git init` inside a repository you already have, or `jj git clone` a URL, work in `jj`, and push to the same GitHub or Forgejo remote as everyone else. Your colleagues never find out. There is no migration, no conversion, no commitment.

Three design choices, each of which is a direct answer to something that has already annoyed you in this course:

**The working copy is itself a commit.** Not staged, not stashed — a real commit, which `jj` amends automatically every time you touch a file. There is no **index**, no **staging** area, and no such thing as a dirty tree. All those `git status` states we spent a chapter untangling collapse into "this commit is the one you're editing". Committing is not "save my work", it is "start describing a new one".

**Every operation is recorded in an operation log.** `jj op log` shows you every mutation of the repository — not just commits, but rebases, bookmark moves, fetches, the lot — and `jj undo` reverses any of them.

```console
jj op log
jj undo
```

Think about what that means. `git reflog` only tells you where refs used to point, and only for refs; recovering from a bad rebase is a manual reconstruction job. In `jj` the *whole repository state* is a versioned thing and undo is one word. This is the feature that most reliably converts people.

**Conflicts are first-class objects stored in commits.** In Git, a conflict is a broken state of your working tree that you must resolve *right now* before anything else can happen — which is why an interrupted `git rebase` is such a miserable experience. In `jj`, a conflict is data recorded *in the commit*. A rebase of twenty commits never stops halfway; it completes, and some of the resulting commits are marked as containing conflicts, which you resolve whenever you like, in whatever order you like.

> :warning:
> Honest status as of mid-2026. `jj` still calls itself experimental, and version 0.43 means what it says: the project has stated there will be workflow changes and backward-incompatible on-disk format changes before 1.0. Git compatibility is the stable part and plenty of people use it daily, but: Git hooks are not supported, `.gitattributes` is ignored, submodules are not visible in the working copy, and partial/shallow clones and Git LFS do not work. Also brace yourself for vocabulary — what Git calls a branch, `jj` calls a **bookmark**, borrowed from Mercurial.

### Pijul and the theory of patches

**Pijul** attacks the deepest thing on the list: merge itself.

Git's three-way merge is a *heuristic over snapshots*. Given two commits and a merge base, it guesses. It is a good guess, and it is not associative — merging A then B can give you a different result from merging B then A, and there are constructed cases where Git silently produces a wrong interleaving without reporting a conflict at all.

Pijul's model is a **commutative algebra of patches**. Changes are objects with a real mathematical structure, independent changes commute, and merges are therefore associative: the order you merge in does not change the result or the resulting identifier. That is a genuinely stronger guarantee than Git offers, and it makes rebase-style history cleanup largely unnecessary, because applying a change in a different order is not a rewrite, it is just application.

Its ancestor is **Darcs**, which had the same idea first and got a reputation for "exponential merge" — pathological cases where the merge algorithm took effectively forever. Pijul's whole engineering claim is a sound theory that also runs fast.

Don't oversell it and don't let anyone sell it to you. As of 2026 Pijul is at 1.0-beta, it is actively developed, it hosts itself on its own forge (the Nest), and its ecosystem is tiny. It is on this list because the theory is beautiful and because it is the only project here willing to say that Git's merge is *approximately* right rather than right.

### Sapling

**Sapling** is Meta's client, open-sourced in 2022 and still actively developed. Lineage: Mercurial, not Git — it grew out of years of Meta patching `hg` — but it speaks Git, clones from GitHub, and its `sl` command line is a lot of people's favourite UI in this whole space.

The idea it borrowed, and then broke: Git assumes `clone` means "download everything". At Meta's repository size that assumption is simply false, so Sapling fetches lazily — a clone pulls the main branches, and commit, tree and file data arrive on demand as you ask for them.

Be fair about the context, though. Git felt the same pressure and answered it: partial clone, sparse checkout, the sparse index, `scalar`. Sapling exists because Git's answers were late, not because Git had none.

### Fossil, which disagrees on purpose

**Fossil** is on this list precisely because it is *not* inspired by Git. It is D. Richard Hipp's version control system — the SQLite author's — and it is a deliberate argument against several of Git's choices.

The whole repository is a **single SQLite file**, which you back up by copying it. It bundles wiki, tickets, forum, chat and technotes *into the repository*, so project history and project conversation replicate together instead of one living in Git and the other living in somebody's SaaS account. And it refuses to rewrite history on principle: there is no `rebase`, and Fossil's documentation contains a long, well-argued essay called "Rebase Considered Harmful" whose central point is that a rebase is a merge that deliberately forgets one of its parents.

You do not have to agree — this course has taught you rebase and told you when to use it. But the argument is good, it is made in public, and Fossil is alive (2.28.0 shipped in March 2026). Reading somebody's careful reasons for rejecting a tool you use is worth an hour.

### Mercurial, fairly

**Mercurial** was born within weeks of Git in 2005, solving the same problem, and by most people's reckoning with a cleaner and more consistent command line. It lost on network effects, not on merit — GitHub happened to Git.

It is not dead. Mercurial 7.2.1 shipped in April 2026, the project gave a talk at FOSDEM 2026 titled roughly "twenty years and counting", and it is still in serious use in places. It also lost its most visible holdout: Mozilla moved Firefox's source of truth from Mercurial to Git in 2025.

### And Git keeps stealing back

The competition has been good for everyone, and it would be dishonest to present Git as static. Partial clone and sparse checkout answer Sapling's scale problem. The sparse index made huge checkouts fast. `git rebase --update-refs` answers the stacked-branch workflow that `jj` and Sapling are built around. The `commit-graph` file made history traversal cheap. And **reftable**, a new refs backend introduced in Git 2.45, matured through 2.51 and slated to become the default format for new repositories in Git 3.0, finally fixes the "a branch is a file in a directory" design that we looked at with our own eyes in [Playing with our revisions](../1-understanding-git/7-play-with-git-revisions.md "Playing with our revisions").

## The Merkle DAG outside version control

Now the fun part: the same primitive, solving problems that have nothing to do with source code.

### Nix and Guix: content addressing for builds

**Nix** and **Guix** apply the idea to *builds*. Every package lives at a path like:

```console
/nix/store/9pmvd4xn1kb0lbz3q0z7iv1hrp4z8g6j-hello-2.12.1
```

That hash is not decoration. It is the identity of the package, and — for a normal Nix package — it is derived from a hash of *all of the build's inputs*: the source, the compiler, the flags, the dependencies, transitively. Change any input and you get a different path. Two builds with the same inputs are the same path and can be shared.

This is Git's rule — "the name is derived from the content" — moved from file contents to build graphs. And it buys the same things: deduplication, a cache that can never be stale (a stale entry would have a different name), and atomic rollback, because a Nix "generation" is a set of pointers into an immutable store, so rolling back your entire system is repointing a symlink. A mutable pointer into an immutable log. We have seen this before.

> :information_source:
> A precision, since we have been careful about this word: standard Nix store paths are *input*-addressed, not content-addressed — the hash is of the recipe, not of the output bytes. Genuinely content-addressed outputs exist in Nix but are still behind an experimental flag (`ca-derivations`). The difference matters for reproducibility arguments and hardly at all for the analogy.

### Docker and OCI images

Open a container image manifest and you will find something extremely familiar: a list of layers, each named by a digest, plus a config **blob**, also named by a digest. The manifest itself has a digest. That is a Merkle tree, and `docker pull` is `git fetch` — "send me the objects I am missing, by hash". Layer sharing between images is structural sharing, exactly as Git shares a **tree** object between two commits.

And here is where the OCI world is *worse* than Git, in a way you are now equipped to be annoyed by: **tags are mutable**. `ubuntu:latest` today and `ubuntu:latest` tomorrow are different images with the same name. It is the anti-**SHA**.

Which is why serious deployments pin by digest:

```console
docker pull ubuntu@sha256:<digest>
```

This is precisely the lesson you already learned about branches versus **commit-id**s. A tag or a branch name tells you *where someone is pointing right now*; only the hash tells you *what you are getting*. Every mature CI pipeline eventually rediscovers this the hard way.

### IPFS, and BitTorrent before it

**IPFS** is content addressing promoted to a network protocol. Content gets a **CID**, and you ask the network for the CID rather than asking a particular server for a path. Its DAG format (IPLD, and the unixfs layout for files) is close enough to Git's trees-and-blobs to be uncanny, and there is an IPLD codec for Git objects (`go-ipld-git`, still maintained), so Git objects can be addressed natively in IPFS's graph. That is a niche corner rather than a mainstream feature, but the fact that it *fits* tells you how similar the two data models are.

The honest note: content addressing solves integrity and deduplication. It does not solve **availability** or **discovery** — a hash tells you what you want, not who has it, and if nobody has it the hash is just a very reliable way of being disappointed. That gap is the source of most of IPFS's practical difficulty.

**BitTorrent** got there before Git shipped, and deserves a line for lineage: a torrent is essentially a hash list over fixed-size pieces, and that is exactly *why* pieces can arrive in any order, from anyone, over any path, and still assemble into the right file. Verify each piece against its hash and you no longer need to trust the sender. Same trick, 2001.

### Transparency logs, signatures, and why Git is not a blockchain

**Certificate Transparency** (RFC 6962, now RFC 9162) is an append-only Merkle tree of every TLS certificate a log has seen. Because it is a Merkle tree you can prove cheaply that a certificate is *in* the log, and that a newer version of the log is a strict superset of an older one — so a log that tries to show different things to different people gets caught. Browsers require certificates to be logged. **Sigstore**'s Rekor does the same for software signatures; **in-toto** attestations describe build provenance; Go's module checksum database is the same structure again, which is what `go.sum` is really checking against.

Then there are **blockchains**, which are also hash-linked append-only structures, and which is where we should say something sharp, because people say this constantly and it is wrong:

**Git is not a blockchain.** It has no consensus mechanism and no proof of work. Anyone with push access can rewrite history and force-push it, and the hashes will be perfectly valid — they will just be the hashes of a *different* history. What Git's hashes guarantee is that **a given history has not been silently altered**: if you have a **commit-id** from a trustworthy source, everything reachable from it is pinned. What they do not guarantee is that it is *the* history, because nothing in Git decides which history is canonical. That is a social fact, stored in a mutable ref on a server somebody controls.

Which is exactly why **signed commits and signed tags** exist. A signature binds a specific hash to a specific key, and a chain of signed commits means "this person asserts this exact tree and this exact ancestry". It is worth being clear about the limits: a signature proves who asserted a commit, not that the code is good, not that the branch you fetched is up to date, and not that the signer wasn't compromised. It is a strong statement about *provenance* and nothing more. The SSH key you set up in [Configure Git with an SSH key](../6-appendices/2-git-ssh.md "Configure Git with an SSH key") can do double duty here — modern Git can sign with SSH keys, not only GPG.

```console
git log --show-signature -1
git verify-commit HEAD
```

### CRDTs and local-first software

Here is a question every Git user eventually asks: why can't Git merge my document the way Google Docs does, live, with no conflicts?

Because Git's merge is **batch** and **general**. It runs when you ask it to, over arbitrary bytes, and when two people edited the same lines it has no idea which meaning was intended, so it stops and asks a human. That is the correct behaviour for source code.

**CRDTs** — conflict-free replicated data types — get automatic, total merge by *constraining the data types*. If your text is a CRDT sequence rather than a byte array, concurrent edits have a defined, deterministic combination, always, with no human in the loop. **Automerge** and **Yjs** are the two you will meet in practice, and they power most of the "local-first" software movement: apps that work offline, sync peer to peer, and never show you a conflict dialog.

The tradeoff is precise and worth internalising: **CRDTs guarantee convergence, not correctness.** Everyone ends up with the same document; nobody promises that document makes sense. Two people editing the same function signature will converge on something syntactically valid and semantically nonsense. That is the same bargain you make when you type `-X theirs` on a merge — "just pick one, I want this to finish" — except made systematically, in advance, for every conflict.

And Automerge's own internals will look familiar: a change is identified by the SHA-256 hash of its bytes, changes reference their predecessors, and the result is a hash-linked DAG of changes that the documentation itself compares to Git commits. Even the escape from Git's merge model kept Git's storage model.

### Content addressing as a build cache

**Unison** (the language, not the file synchroniser) takes it furthest: a Unison definition is identified by the hash of its syntax tree, and the code is stored in a database under that hash rather than in text files. Names are just metadata pointing at hashes. The consequences are startling — renaming is instant and cannot break anything, two versions of a dependency can coexist because they are simply different hashes, and there are no builds, because a compiled artifact keyed by the hash of its input can never be stale.

The same insight, less radically, is how **Bazel** and **Buck** work: an action's cache key is a hash of its inputs, its command line and its environment, so a shared cache across a whole engineering organisation is safe. Cache invalidation, famously one of the two hard problems, mostly stops being a problem when the name *is* the content.

### Git used deliberately as a database

Finally, the systems that did not borrow Git's ideas — they borrowed Git.

* **git-bug** stores issues as objects in their own refs, so your bug tracker clones, branches and works offline like the code. Actively developed and surprisingly pleasant.
* **Gerrit** keeps its entire review dataset in the Git repository — NoteDb, with change metadata under `refs/changes/*/meta` and review data in notes refs — which is the same trick as [git notes](3-git-notes.md "git notes"), industrialised.
* **GitHub** and friends publish pull requests as refs under `refs/pull/*`, which is why you can fetch a PR you have no other access to.
* **Argo CD** and **Flux** treat a Git repository as the desired state of a cluster and continuously reconcile reality against it — the whole subject of [GitOps](../5-automation/1-git-ops.md "GitOps").
* **Radicle** builds a peer-to-peer forge on top of Git: repositories, issues and patches replicate between peers with no server in the middle. Its current protocol generation is called Heartwood and it is at 1.9.x as of mid-2026 — a real, if small, project.
* **libgit2** and **gitoxide** are reusable Git implementations (C and Rust) that exist so you can build things like the above without shelling out to `git`. `jj` uses gitoxide for its Git backend.

## What to take away

Four transferable lessons, and they are worth more than the list of names:

**Derive names from content and you get integrity, deduplication and cache invalidation for free.** Not "cheaply" — free, as a side effect. If the name is the hash, a corrupted object is detectable, an identical object is stored once, and a cache entry can never be stale, because a changed input has a different name.

**Separate an immutable log from mutable pointers into it and you get history, branching and rollback for free.** Git, Nix generations, a lakeFS branch, an Iceberg snapshot ref, a Docker tag: same shape. Everything interesting is immutable; everything mutable is tiny.

**Structural sharing makes "copy the whole world" cheap.** This is why a branch costs 41 bytes, a **worktree** costs almost nothing, a Nix rollback is instant, branching a petabyte in lakeFS is a metadata write, and a hundred containers share one base layer. Once versions share their unchanged parts physically, the cost of a new version is the size of the change.

**The hard part is never the storage. It is the merge.** Every system in this chapter has essentially the same storage answer and a *different* answer to "what happens when two people changed the same thing". Git guesses with a three-way merge and asks a human when it can't. Dolt merges rows and detects constraint violations. Pijul proves its merges commute. `jj` stores the conflict and lets you continue. CRDTs converge by construction and accept nonsense. Fossil refuses to let you pretend the divergence never happened. That question is where the design lives.

You now understand Git's plumbing well enough to read any of these projects' design documents — and you will find, page after page, that you already know the vocabulary. Hash. Immutable object. Ref. Snapshot. Merge base. Structural sharing. Go and read Dolt's storage engine page, or the jj design docs, or the OCI image spec. You are not a tourist there anymore.

## Summary — ideas and the systems that borrowed them

* **Content addressing** — the name is a hash of the content. Predates Git (Merkle, 1970s; Plan 9's Venti; Monotone, which Linus credited).
* **Merkle DAG + cheap refs + replication as default** — Git's actual contribution is the combination, not any single piece.
* **Dolt** — Git's commit graph as a MySQL-compatible SQL database; `dolt_log` and `dolt_diff` as queryable system tables; **prolly trees** for structural sharing *and* indexed queries *and* O(change) diffs. Siblings: Doltgres (Postgres, beta), DoltLite (SQLite).
* **Noms** — where prolly trees were invented. Archived since 2021; the ideas survived in Dolt.
* **TerminusDB** — branch/diff/merge for a document-graph database. Alive but has changed hands; check its health first.
* **lakeFS** — branch a petabyte in O(1) by copying metadata only. Same insight as a **worktree**.
* **Iceberg / Delta Lake / Nessie** — immutable metadata log pointing at immutable data files; time travel and branching arriving from the warehouse side.
* **Neon / PlanetScale** — cheap isolated database copies plus a review step before merge. Borrowed the social model, not the storage model.
* **Jujutsu (`jj`)** — Git-backed, so adoptable today. Working copy *is* a commit (no **index**), operation log with universal `jj undo`, conflicts as first-class objects so rebases never stop halfway. Still pre-1.0 in 2026.
* **Pijul** — merge as a commutative algebra of patches, so merges are associative. Darcs's descendant. Beta, tiny ecosystem, beautiful theory.
* **Sapling** — Meta's Git-compatible client from the Mercurial lineage; lazy history fetching for repositories too big for `clone`-everything.
* **Fossil** — deliberately un-Git-like: single SQLite file, wiki/tickets/forum in the repo, no rebase on principle.
* **Mercurial** — Git's contemporary, arguably better UI, lost on network effects; still shipping in 2026.
* **Git itself** — partial clone, sparse index, `--update-refs`, commit-graph, reftable. The competition has been good for us.
* **Nix / Guix** — content (well, input) addressing for *builds*; `/nix/store/<hash>-name` is a blob store, and a generation is a mutable pointer into an immutable store.
* **Docker / OCI** — layers and manifests named by digest; `pull` is a fetch of missing objects. Mutable tags are the anti-**SHA** — pin by digest.
* **IPFS** — content addressing as a network protocol; DAG format close to trees-and-blobs. Solves integrity and dedup, not availability or discovery.
* **BitTorrent** — a hash list is why pieces can arrive in any order from anyone. 2001.
* **Certificate Transparency / Sigstore / Go checksum DB** — append-only Merkle logs for tamper-evidence.
* **Blockchains** — also hash-linked, but Git is *not* one: no consensus, no proof of work. Hashes prove a given history wasn't silently altered, not that it is *the* history. Hence signed commits and tags.
* **CRDTs (Automerge, Yjs)** — automatic total merge by constraining the data types. Convergence, not correctness — the same bargain as `-X theirs`.
* **Unison / Bazel / Buck** — content addressing as the basis for build caching. When the name is the content, cache invalidation stops being a problem.
* **git-bug, Gerrit NoteDb, `refs/pull/*`, Argo CD, Flux, Radicle, libgit2, gitoxide** — Git used deliberately as a database, or reimplemented so you can.
