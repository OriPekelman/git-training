---
title: Abusing git notes for fun and profit
slug: "git-notes"
weight: 33
---
# Abusing git notes for fun and profit

A **commit** is immutable. Part 1 hammered that in: change one byte of the message, one character of the author name, and you get a different **SHA**, a different object, a different commit. That is not a bug, it is the whole point. The identity *is* the content.

But information about a commit keeps arriving after the commit exists. This one was reviewed by Sophie. This one passed CI in 4m12s and produced an artifact with digest `sha256:9f2a1c`. This one went to production on Tuesday at 18:22. This one, three weeks later, turned out to be the cause of incident INC-482. This one was written by an agent, from a prompt we would quite like to keep.

None of that was known when we typed `git commit`. And we cannot `git commit --amend` to add it, because amending makes a *new* commit and orphans everything downstream. Rewriting history in order to record history is a bad joke.

`git notes` is Git's answer: attach mutable metadata to an immutable object, without touching the object.

This is the part of Git that feels like finding a door at the back of the wardrobe. Then you step through and notice that nobody has been in here for a decade, the light switch does not work, and there are reasons for that. We will do both halves honestly: first the fun, then the caveats — and the caveats are not decoration.

## Our first note

We are in a small repository with three **commit**s — `eacb04c` "Added readme.md", `6ca3554` "Adding a license file", and at the tip `d688689` "Add pretty red button to shopping cart". Let's attach something to the tip. No output, no ceremony:

```console
git notes add -m 'Reviewed-by: Sophie <sophie@example.com>' HEAD
```

Now `git log`:

```console
git log -1

commit d68868997648ff6e3e6ae505743b668f7a6d5763
Author: Ori Pekelman <ori@pekelman.com>
Date:   Mon Mar 2 09:31:00 2026 +0100

    Add pretty red button to shopping cart

Notes:
    Reviewed-by: Sophie <sophie@example.com>
```

A `Notes:` block, indented like the message but *not* the message. The commit-id is unchanged — `d688689` before, `d688689` after. We added information to a commit without changing the commit.

Notes accumulate. `append` adds a paragraph, and `git notes edit` opens the note in your editor:

```console
git notes append -m 'Deployed-to: production 2026-03-04' HEAD
git notes show HEAD

Reviewed-by: Sophie <sophie@example.com>

Deployed-to: production 2026-03-04
```

`git notes list` shows every annotated object:

```console
git notes list

e8d2354ee95b6fd191c28e0ca02f1bea96ab3add d68868997648ff6e3e6ae505743b668f7a6d5763
```

Two **SHA**s. The second we recognize — it is our commit. The first is something else, and it is the interesting half. Hold that thought for thirty seconds.

`git show` displays notes too, and so does anything built on the log machinery. Which is our first small surprise: notes are displayed *by default*, so the moment you add one, your colleagues' `git log` output changes shape. `git log --no-notes` turns it off for one invocation. And when you use `--format`, notes are *not* included unless you ask for them with `%N` — the placeholder on which every clever use of notes turns. Remember it, we will come back to it.

## Under the hood: there is no feature here

Now the good part. `git notes` is not a subsystem bolted onto Git. It is the object model from Part 1, pointed back at itself.

Notes live in a **ref**, and by default that ref is `refs/notes/commits`:

```console
cat .git/refs/notes/commits

5d46e022bad174733a2199ec500e37419dc28d3b
```

A file under `.git/refs` containing forty characters, exactly like `.git/refs/heads/master` — and `git rev-parse refs/notes/commits` agrees. So what kind of object is `5d46e02`?

```console
git cat-file -p refs/notes/commits

tree 9593c7973ed478fc32d0b5bd16ac511ee1d27104
parent 22475090ba59acd210c74bb247c49c31ac5e4495
author Ori Pekelman <ori@pekelman.com> 1772445600 +0100
committer Ori Pekelman <ori@pekelman.com> 1772445600 +0100

Notes added by 'git notes append'
```

An ordinary **commit**. Tree, parent, author, committer, message — Git wrote the message for us, and that is the only unusual thing about it. It has a **tree**:

```console
git ls-tree refs/notes/commits

100644 blob e8d2354ee95b6fd191c28e0ca02f1bea96ab3add	d68868997648ff6e3e6ae505743b668f7a6d5763
```

Sit with this for a second. One entry, and the *filename* is `d68868997648ff6e3e6ae505743b668f7a6d5763` — the **SHA** of the commit we annotated. The note attached to commit `d688689` is literally a file *named* `d688689…`. And the **blob** is the note:

```console
git cat-file -p e8d2354ee95b6fd191c28e0ca02f1bea96ab3add

Reviewed-by: Sophie <sophie@example.com>

Deployed-to: production 2026-03-04
```

That is the whole mechanism. A notes ref is a branch whose tree, if you checked it out, would be a directory full of files named after object IDs, each containing free text. `git notes` is a convenience wrapper over `git hash-object`, `git mktree` and `git commit-tree`. There is no fifth object type. There never was. (And now the `git notes list` output makes sense: it prints `<note-blob> <annotated-object>`, the same two SHAs as the `ls-tree` line.)

### Notes have a history

If the notes ref is a branch of commits, it has a **log**:

```console
git log --oneline refs/notes/commits

5d46e02 Notes added by 'git notes append'
2247509 Notes added by 'git notes add'
```

One commit for our `add`, one for our `append`. *Every* note operation writes a commit. And since they are commits, we can diff our metadata over time:

```console
git diff 2247509 5d46e02

diff --git a/d68868997648ff6e3e6ae505743b668f7a6d5763 b/d68868997648ff6e3e6ae505743b668f7a6d5763
index afa2012..e8d2354 100644
--- a/d68868997648ff6e3e6ae505743b668f7a6d5763
+++ b/d68868997648ff6e3e6ae505743b668f7a6d5763
@@ -1 +1,3 @@
 Reviewed-by: Sophie <sophie@example.com>
+
+Deployed-to: production 2026-03-04
```

A diff whose filename is a commit-id. If that does not make you smile a little, this may not be the chapter for you.

The practical consequence: **notes are versioned**, so a deleted note is recoverable. Let's annotate the middle commit, then destroy it:

```console
git notes add -m 'CI: build 3391 passed in 4m12s' HEAD~1
git notes remove HEAD~1

Removing note for object HEAD~1

git notes show HEAD~1

error: no note found for object 6ca3554109e26e6a8571d9a5d7e4966d8b00d025.
```

Gone. Is it a good time to panic? No. You should never panic. The notes ref has a reflog and the old tree is still an object, so we ask for a *path* inside a previous revision of the notes tree — the path being the annotated commit's SHA:

```console
git show 'refs/notes/commits@{1}:6ca3554109e26e6a8571d9a5d7e4966d8b00d025'

CI: build 3391 passed in 4m12s
```

And `git update-ref refs/notes/commits refs/notes/commits@{1}` puts the whole previous state back. `git update-ref` on a notes ref, because it is just a ref.

### Fanout

One flat tree with one entry per annotated object is fine for a few dozen notes. It is not fine for fifty thousand: a tree object is a single blob of bytes that must be rewritten in full on every change. So Git fans out, exactly like `.git/objects`. In a repository where we made 400 commits and gave each one a note:

```console
git ls-tree refs/notes/commits | head -3

040000 tree 6d8eb7fd415526489c6e3cb46abb3437ec4f989c	00
040000 tree 46d2b9d94a9d1090a106fc1200f6c3c27ca39f4b	03
040000 tree 87eee3c9c82d836a0b90e316216e56c54eeb6941	07
```

Two hex digits of directory, the rest as the filename. In our run it flipped from flat to fanned out when the 58th note landed. Git decides on its own, both shapes are valid and can coexist, and the exact threshold is an implementation detail we should not build anything on.

Does it scale? Here is the real notes ref of the Git project itself, which maps every commit to the mailing-list message it came from:

```console
git fetch --depth=1 https://github.com/git/git.git 'refs/notes/amlog:refs/notes/amlog'
git ls-tree -r refs/notes/amlog | wc -l

   40030

git ls-tree -r refs/notes/amlog | sed -n '20000p'

100644 blob e8905b07b71a4bae63b2c474efadf70152c46af1	7f/42/31229dd54f4094efefd8a4f62bccf6f53c9d

git cat-file -p e8905b07b71a4bae63b2c474efadf70152c46af1

Message-Id: <3a41ad889cc33a1fc0414b8f14af6438b49c88ee.1723886761.git.gitgitgadget@gmail.com>
```

Forty thousand notes, two levels of fanout, maintained for years by the Git maintainer. Scaling is not the problem with notes.

## Namespaces: the feature nobody knows about

`refs/notes/commits` is only the *default*. Any `refs/notes/<whatever>` is a notes ref, and each is an independent tree. This is what makes notes genuinely useful, and it is the least known thing about them.

```console
git notes --ref=ci add -m '{"build":3391,"duration_s":252,"result":"pass","artifact":"sha256:9f2a1c"}' HEAD
git notes --ref=ci add -m '{"build":3388,"duration_s":261,"result":"pass","artifact":"sha256:1bd4e0"}' HEAD~1
git notes --ref=ci add -m '{"build":3385,"duration_s":249,"result":"fail","artifact":null}' HEAD~2
git notes --ref=deploys add -m 'env=production at=2026-03-04T18:22:11Z by=ori rollback-to=6ca3554' HEAD

git for-each-ref refs/notes

85eb48c17708f90719b062903c657c6f658f0ad4 commit	refs/notes/ci
37331e01dfcf9c686a226281393dc0992e33a911 commit	refs/notes/commits
02998e9b79b9467dc27d5cfb1fb2c8f538ecba53 commit	refs/notes/deploys
```

`--ref=ci` means `refs/notes/ci`; the prefix is added for you. Three independent little databases — and `git log` shows only the default one, unless we ask:

```console
git log -1 --oneline --notes=ci --notes=deploys

d688689 Add pretty red button to shopping cart
Notes (ci):
    {"build":3391,"duration_s":252,"result":"pass","artifact":"sha256:9f2a1c"}

Notes (deploys):
    env=production at=2026-03-04T18:22:11Z by=ori rollback-to=6ca3554
```

The knobs, which belong in your config rather than in your fingers:

* `core.notesRef` — which ref `git notes` reads and writes by default (`git notes get-ref` prints the current one; `GIT_NOTES_REF` does the same in the environment).
* `notes.displayRef` — which refs `git log` *displays*, and it takes globs: `git config notes.displayRef 'refs/notes/*'`. Set it once and every namespace shows up in your log.
* `--notes=<ref>`, `--notes='*'` and `--no-notes` per invocation.

## You can annotate anything

Notes attach to *objects*, not to commits. The tree entry is a filename, and any object ID makes a valid filename. So let's annotate a **blob**:

```console
git notes --ref=provenance add -m 'Generated by an agent from prompt: "make the cart button red"' $(git rev-parse HEAD:style.css)
git ls-tree refs/notes/provenance

100644 blob d67def0628781ef5fb38669b60b1453f71f2cbc7	d9ef44daba3c84a1e7213ec3f231f03f57d7c63a
```

`d9ef44d` is not a commit — it is the content of `style.css`. We have annotated a *file version*, and that annotation follows that exact content into every branch and every clone that ever holds it. The same works on a **tree**, and on an annotated **tag** object: `git notes --ref=provenance add -m 'Signed off by legal' $(git rev-parse v0.1)`.

> :warning:
> Delightful, and half-supported. `git log` and `git show` only *display* notes when they are showing a commit. `git show <blob>` prints the file content and says nothing about your beautiful note. To read notes on other objects you use `git notes show <object>`, or you go under the hood with `git ls-tree` and `git cat-file`. Nothing else in the ecosystem will surface them for you.

## Fun and profit

Now that we know it is just trees and blobs, here is what notes are actually used for.

**CI and build metadata.** The canonical use, and the one notes are genuinely good at. The build system knows the commit-id, and it knows the build number, the duration, the artifact digest, the test counts — so it writes them onto that exact commit. No table joining a SHA to a build, no expiring URL: the metadata travels with the repository.

**Code review records.** Not hypothetical. Gerrit's `reviewnotes` plugin writes review metadata into `refs/notes/review`: `Submitted-by:`, `Submitted-at:`, `Reviewed-on:` with a link to the change, `Code-Review+2:` per reviewer, `Comments-Total:`, `Comments-Unresolved:`. It has been a plugin rather than core Gerrit since 2.6, and it is not fetched by default (foreshadowing) — but it exists, in production, at scale.

**Deploy provenance and retroactive annotation** — the second being the thing commit messages structurally cannot do, because the truth arrived later:

```console
git notes --ref=deploys append -m 'env=production at=2026-03-05T09:40:00Z by=bob rollback-to=6ca3554' HEAD
git notes --ref=incidents add -m 'Root cause of INC-482. Reverted by 9f2a1c3.' 6ca3554
git notes --ref=papers add -m 'Figure 3 of the preprint was generated from this commit.' eacb04c
```

**Carrying a note across a cherry-pick.** `git notes copy` moves an annotation from one object to another. We cherry-picked a hotfix (`380015b`) onto `master`, and the new commit has no note, so:

```console
git notes --ref=ci copy 380015b HEAD
git notes --ref=ci list

cec5a2aa204a87d381914d163a162f157ea31fe6 380015bf6aae44b48f8773f0e050508b79c3654f
cec5a2aa204a87d381914d163a162f157ea31fe6 c4772c92069db44285928750a3671487456aa407
```

Look closely: two annotated commits, *one* note blob. Content-addressed storage does not store the same note twice, so copying a note costs one tree entry. (Copying onto an object that already has a note refuses unless you add `-f`.)

**Carrying notes across a rewrite, automatically.** By default `git commit --amend` and `git rebase` do *not* carry your notes — the note stays glued to the old, now-orphaned commit, and `git notes list` cheerfully goes on pointing at a SHA nobody references. That behaviour is config-driven, and the config is off out of the box:

```console
git config notes.rewriteRef 'refs/notes/*'
git rebase master
git notes show HEAD

CI: build 43 passed
```

Related: `notes.rewrite.amend` and `notes.rewrite.rebase` (both default to true, but do nothing until `notes.rewriteRef` is set) and `notes.rewriteMode` (`concatenate` by default; also `overwrite`, `cat_sort_uniq`, `ignore`) for when the target already has a note. If you use notes at all, set `notes.rewriteRef`. It is the difference between notes that survive your workflow and notes that evaporate the first time you tidy up a branch.

**Structured data, and querying it.** Nothing stops you putting JSON in a note, and `%N` gets it back out. The `grep .` drops the blank lines `%N` emits for unannotated commits:

```console
git log --format='%h %N' --notes=ci | grep .

d688689 {"build":3391,"duration_s":252,"result":"pass","artifact":"sha256:9f2a1c"}
6ca3554 {"build":3388,"duration_s":261,"result":"pass","artifact":"sha256:1bd4e0"}
eacb04c {"build":3385,"duration_s":249,"result":"fail","artifact":null}
```

From there it is just Unix — `git log --format='%h %s %N' --notes=ci | grep '"result":"fail"'` lists the commits whose build failed, and with `jq` we can go further:

```console
git log --format='%N' --notes=ci | grep . | jq -s 'map(.duration_s) | add / length'

254
```

Average build duration over the history of a branch, computed from the repository, offline, with no build server involved. That is a genuinely nice thing to be able to do.

**Agent and AI provenance.** Notes fit this better than most alternatives. When a commit is produced by an agent there is metadata a human reader of the log does not want in the message: the prompt, the model identifier, the tool version, which of five candidate patches got picked, the review verdict. Put it in `refs/notes/agent` and the commit message stays a commit message. It composes with the per-agent worktrees from [Worktrees and agents](2-git-worktree-agents.md "Worktrees and agents") — the harness writes the note, the human reads the message. Nothing here is magic and none of it is settled practice; it is one reasonable place to put machine-generated context, and this is a fast-moving area.

**Attestations.** Notes are a popular place to stash signed statements — SBOMs, provenance, scan results. Fine, with one caveat people miss: a note is not signed because it is a note. The notes *commits* can be signed like any other commit, and the payload can be a detached signature you verify yourself, but a plain note carries no more authority than a text file.

**The party trick.** Since a notes ref is a tree of files named after object IDs, you can abuse it as a tiny key/value store inside the repository. The keys have to be object IDs — so make them be:

```console
KEY=$(printf 'deploy-target' | git hash-object -w --stdin)
git notes --ref=kv add -m 'eu-west-1' $KEY
git notes --ref=kv show $(printf 'deploy-target' | git hash-object --stdin)

eu-west-1
```

Hash the key into a blob, annotate the blob, look it up by re-hashing the key. It works, it is versioned, it replicates for free — and it is completely deranged; a YAML file in the tree is better in every respect. But `refs/notes/*` is just a namespace, and Git is full of people doing this sort of thing: `refs/replace` for object substitution, `refs/stash` for stashes, `refs/pull/*` on GitHub for pull request heads. Nobody promised the ref namespace would stay tidy.

## The caveats, which are not small

Everything above is true. Here is why almost nobody uses notes, and why that is partly deserved.

### Notes are not fetched, and not pushed

This is the killer. `git clone` does not bring notes. `git fetch` does not update them. `git push` does not send them. The default refspecs cover `refs/heads/*` and tags, full stop.

Clone a repository whose server holds four notes refs, run `git notes list`, and you get nothing. Not an error — *nothing*. You have to ask, by name, with a **refspec**:

```console
git fetch origin 'refs/notes/*:refs/notes/*'

From ../origin
 * [new ref]         refs/notes/ci         -> refs/notes/ci
 * [new ref]         refs/notes/commits    -> refs/notes/commits
 * [new ref]         refs/notes/deploys    -> refs/notes/deploys
 * [new ref]         refs/notes/provenance -> refs/notes/provenance
```

To make it permanent, add a second `fetch` line to the remote in `.git/config`:

```console
git config --add remote.origin.fetch '+refs/notes/*:refs/notes/*'

[remote "origin"]
	url = ../origin.git
	fetch = +refs/heads/*:refs/remotes/origin/*
	fetch = +refs/notes/*:refs/notes/*
```

Pushing is the mirror image — `git push origin 'refs/notes/*:refs/notes/*'`, which reports ` * [new reference]   refs/notes/ci -> refs/notes/ci` and friends. You can put that in a `push` refspec too, but do it knowingly: it means every namespace on your machine goes up every time.

This single default is, I am fairly sure, the whole story of why notes are unloved. Someone tries them, they work beautifully, they push, a colleague clones, the notes are not there, and the reasonable conclusion is "git notes don't work". They do work. They are just invisible until every participant has edited their config.

> :warning:
> Notice the `+` in that fetch refspec: it means *force*. If you fetch `+refs/notes/*:refs/notes/*` while holding local notes the server does not have, your local notes ref is overwritten and your work survives only in the reflog. We did exactly this to ourselves while writing this chapter. Safer: fetch into a side namespace with `git fetch origin 'refs/notes/*:refs/notes/remote/*'` and merge deliberately.

### Merging notes is a real operation with real conflicts

Two people annotate the same commit in the same namespace and the notes refs diverge. Bob pushes second:

```console
git push origin 'refs/notes/deploys:refs/notes/deploys'

 ! [rejected]        refs/notes/deploys -> refs/notes/deploys (fetch first)
error: failed to push some refs to '../origin.git'
```

Non-fast-forward, exactly like a branch, because it *is* a branch. So Bob fetches theirs to one side and merges:

```console
git fetch origin 'refs/notes/deploys:refs/notes/theirs'
git notes --ref=deploys merge refs/notes/theirs

Automatic notes merge failed. Fix conflicts in .git/NOTES_MERGE_WORKTREE and commit the result with 'git notes merge --commit', or abort the merge with 'git notes merge --abort'.
Auto-merging notes for d68868997648ff6e3e6ae505743b668f7a6d5763
CONFLICT (content): Merge conflict in notes for object d68868997648ff6e3e6ae505743b668f7a6d5763
```

There is a whole conflict worktree, in a directory you have never looked at, containing one file per conflicted note — named, of course, after the annotated commit:

```console
cat .git/NOTES_MERGE_WORKTREE/*

env=production at=2026-03-04T18:22:11Z by=ori rollback-to=6ca3554

env=staging at=2026-03-05T08:02:00Z by=alice

<<<<<<< refs/notes/deploys
env=production at=2026-03-05T09:40:00Z by=bob
=======
env=staging at=2026-03-05T08:02:00Z by=alice
>>>>>>> refs/notes/theirs
```

You edit it, then `git notes merge --commit` — or `git notes merge --abort`.

The strategies (`-s`, or `notes.mergeStrategy`) are `manual` (the default, above), `ours`, `theirs`, `union` and `cat_sort_uniq`. For append-only logs — deploys, builds, scan results — `union` is usually what you want. But there is no free lunch: `union` is *dumb concatenation*, so paragraphs both sides already shared appear twice in the result. And `cat_sort_uniq` does deduplicate, at the price of sorting your lines: merging two deploy logs that way gave us `deployed: canary`, `deployed: production`, `deployed: staging` — a tidy alphabetical list of things that happened in no particular order. Choose your poison, and prefer one writer per namespace if you can arrange it.

### The forges do not show them

GitHub does not display notes. It did once: the feature was announced in August 2010 — notes appeared at the bottom of a commit's diff — and that same blog post now carries an update dated 14 August 2014 saying displaying Git notes is no longer supported. Requests to bring it back are still open in GitHub's community discussions. GitLab does not display them either, and has long-open issues asking for it. Both will store and serve the refs perfectly well — you can push and fetch notes to either — but the web UI is silent.

Plainly: if your team's source of truth is a web UI, notes are invisible, and invisible metadata rots. Six months later half of it is wrong and nobody knows, because nobody ever saw it.

There is a smaller, funnier version of the same problem: notes commits are commits living in `refs/`, so a `git log --all` in our little three-commit repository now lists sixteen commits, thirteen of them with messages like `Notes added by 'git notes add'` and `Notes removed by 'git notes remove'`. Harmless, and a good illustration of how little of Git knows what a note is.

### Nothing else reads them

`git log`, `git show`, `git notes`. That is the list. Your IDE's blame gutter does not show notes. Your PR review tool does not. `git blame` does not. Anything you build on notes, you build yourself — usually a shell script and a `--format='%N'`.

### They are not a database

No index, no query language, no transactions, no access control. Every write rewrites a tree and appends a commit; two writers racing on one ref means one of them gets a rejected push and has to merge. Reads are a full `git log` walk unless you build your own index.

Forty thousand notes: fine. A note per commit per CI run: fine. A per-request event log: absolutely not. Notes are a filing cabinet, not a time-series database.

### They are mutable, which is the point and the danger

A note is not evidence. Anyone who can push to `refs/notes/*` can rewrite the entire notes history, and the only trace outside their own machine is that a ref moved non-fast-forward. `git notes remove`, `git update-ref`, force-push, done — and the log afterwards looks perfectly innocent.

If you need tamper-evidence you need signatures: sign the notes commits, or put a signed payload inside the note and verify it yourself. The note alone proves nothing.

### `git gc` and `git notes prune`

Notes are reachable from their ref, so notes commits and note blobs are safe from `git gc`. Delete a notes ref, though, and its whole history becomes garbage at the next `gc`.

The other direction is `git notes prune`, which drops notes whose annotated object no longer exists. Run `git notes prune -n` first — it prints the object IDs whose notes would go. And note that "no longer exists" means *really* gone: an unreachable commit that has not been garbage collected yet still counts as existing, so `prune` is a slower guillotine than it looks. The removal is itself a notes commit, so it is recoverable from the reflog for as long as the reflog lasts. Recoverable-for-now is not the same as safe.

## So when should we actually use notes?

My honest recommendation, having played with this a lot.

**Reach for notes when** the metadata is machine-generated, produced by automation, consumed by automation, in a repository you control end to end, in its own namespace with a single writer. CI results, build provenance, agent metadata, commit-to-external-ID mappings. Set `notes.rewriteRef`, put the fetch and push refspecs in the tooling rather than asking humans to remember them, pick `union`, and never let two systems write the same namespace.

**Do not reach for notes when** a human needs to see it in a pull request; when it must be authoritative or tamper-evident; when it must survive a rewrite; or when it must be visible to someone who cloned the repository and configured nothing.

For those cases the boring alternatives are better, and saying so is more useful than winning the argument:

* **Commit trailers.** `Co-authored-by:`, `Signed-off-by:`, `Reviewed-by:`, `Fixes:`, or your own `Build-Id:`. They live *in* the message, so they are immutable, visible in every tool and every forge UI, and they survive a fresh clone with zero configuration. `git interpret-trailers` writes them and `git log --format='%(trailers:key=Fixes)'` reads them back. If the information exists at commit time, this is almost always the right answer.
* **Annotated tags** for release metadata: a **tag** object holds a message, a tagger, a date and a signature, and people already push tags out of habit.
* **An external system keyed by commit SHA.** A table with a `commit_sha` column is unglamorous and gives you indexes, queries, permissions and an audit trail. Every CI system on earth does this. It is not wrong.
* **A CI artifact store** for anything large, binary or high-volume. Test reports do not belong in a Git object.

Notes are a lovely piece of design: the object model turned back on itself, no new concepts, all the power of refs and trees and blobs aimed at metadata. The mechanism is excellent. The defaults, and fifteen years of ecosystem indifference, are what let it down. Learn it, use it where it fits, and do not be the person who put the deploy log somewhere their teammates will never look.

## Summary `git notes`

* `git notes add -m'<text>' <object>` attaches a mutable note to an immutable object; `-f` overwrites an existing one
* `git notes append`, `edit`, `show`, `list`, `copy`, `remove`, `prune` and `get-ref` are the other verbs
* `git notes merge <ref>` merges two diverged notes refs, with `-s manual|ours|theirs|union|cat_sort_uniq`; manual conflicts land in `.git/NOTES_MERGE_WORKTREE` and end with `git notes merge --commit` or `--abort`
* **notes ref** — notes live in `refs/notes/commits` by default, or `refs/notes/<anything>` with `--ref=<name>`. It is an ordinary ref pointing at an ordinary **commit**, whose **tree** has one entry per annotated object: the *filename* is the object's **SHA** and the **blob** is the note text
* Every note operation creates a commit, so `git log -p refs/notes/commits` is the history of your metadata, and `refs/notes/commits@{1}` recovers what you just deleted
* Notes trees **fan out** into `ab/cdef…` subdirectories automatically as they grow, like `.git/objects`
* Notes can annotate **any** object — **commit**, **blob**, **tree**, **tag** — but only commits get them displayed automatically
* `git log --notes=<ref>`, `--notes='*'`, `--no-notes` and `--format='%N'` control and extract notes; `core.notesRef`, `notes.displayRef`, `notes.mergeStrategy`, `notes.rewriteRef` and `notes.rewriteMode` are the config
* `notes.rewriteRef` is what carries notes across `git commit --amend` and `git rebase`; without it, rewriting history orphans them
* **Notes are not cloned, fetched or pushed by default** — you need explicit refspecs: `git push origin 'refs/notes/*:refs/notes/*'`, and a `fetch = +refs/notes/*:refs/notes/*` line in the remote config. This is the single reason most people conclude notes don't work
* Forge web UIs do not display notes, almost no third-party tool reads them, notes are mutable and therefore not evidence, and they are a filing cabinet rather than a database
* When notes are the wrong tool, use **commit trailers**, **annotated tags**, an external system keyed by commit SHA, or a CI artifact store
