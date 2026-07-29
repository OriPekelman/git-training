---
title: Big files, or how Git meets its limits
slug: "git-lfs"
weight: 34
---
# Big files, or how Git meets its limits

Sooner or later somebody hands you a repository with a 400 MB video in it, or a designer asks where to put the `.psd` files, or you join a machine-learning team and discover that their "small" repo takes forty minutes to clone.

This chapter is about that. And we will do it in the order that actually teaches something: **first** we show, from the object model you already know, *why* Git is bad at big files. **Then** we introduce Git LFS as what it really is — a clever workaround bolted onto the side of Git, with real costs.

If you read only one sentence of this chapter: the best fix for a big-file problem is usually not to commit the big file.

> :information_source:
> Everything measured here was measured for real, with Git 2.51 and git-lfs 3.7.0. Your numbers will differ in the last decimal, not in the shape. My scratch repositories have `init.defaultBranch = main`, which is why the output says `main`.

## Why Git struggles

### Every version of every file is stored whole

Remember [Inside the repository, inside the commit](../1-understanding-git/5-inside-git.md "Inside the repository, inside the commit"): a **commit** points to a **tree**, a **tree** lists **blob**s, and a **blob** is *the entire content of one version of one file*. Git does not store diffs. It stores snapshots.

So let's do the cruel experiment. A 20 MiB file of pure random noise, committed five times, regenerated from scratch each time — which is exactly what happens when you re-train a model or re-export a video.

```console
git init big-and-random && cd big-and-random
for i in 1 2 3 4 5; do
  head -c 20971520 /dev/urandom > model.bin
  git add model.bin && git commit -q -m "model v$i"
  echo "after commit $i: $(du -sh .git | cut -f1)"
done

after commit 1:  20M
after commit 2:  40M
after commit 3:  60M
after commit 4:  80M
after commit 5: 100M
```

Perfectly, depressingly linear. Now let's ask Git itself, with the command that gives the honest accounting of a repository's size:

```console
git count-objects -vH

count: 15
size: 100.08 MiB
in-pack: 0
packs: 0
size-pack: 0 bytes
```

Fifteen loose objects — five blobs, five trees, five commits — for 100 MiB. And now the part people hope will save them:

```console
git gc
git count-objects -vH

count: 0
size: 0 bytes
in-pack: 15
packs: 1
size-pack: 100.03 MiB
```

Packing saved us fifty kilobytes. The working tree is 20 MiB. The repository is 100 MiB. Forever.

### But let's be fair: delta compression is not useless

I would be lying if I stopped there. The **packfile** format *does* store objects as deltas against similar objects, and it works on binary data too — it is a byte-level delta, not a line-level one. Watch what happens when the file really is *mostly the same bytes*: a 20 MiB file with 4 KiB patched in the middle each time.

```console
head -c 20971520 /dev/urandom > data.bin
git add data.bin && git commit -q -m "data v1"
for i in 2 3 4 5; do
  dd if=/dev/urandom of=data.bin bs=4096 seek=$((i*100)) count=1 conv=notrunc status=none
  git add data.bin && git commit -q -m "data v$i"
done

git count-objects -vH | grep size:
size: 100.08 MiB            # loose: five full copies

git gc && git count-objects -vH | grep size-pack
size-pack: 20.03 MiB        # packed: one copy plus four tiny deltas
```

100 MiB of loose objects collapse to **20.03 MiB**. Delta compression did its job beautifully. So the real rule is not "Git is bad at binaries":

> :information_source:
> Git deltas well when successive versions **share long runs of identical bytes**, and terribly when a small logical change perturbs the whole file. Which of those happens is decided by the *file format*, not by Git.

### The format is what kills you

Here is the experiment that makes the point properly. The same information and the same tiny change — one line rewritten near the top of a 13 MB CSV — committed five times. Once as plain CSV, once as `gzip -9` of that exact same CSV.

| repo | payload | loose objects | after `git gc` |
|---|---|---|---|
| plain CSV | 13.6 MB | 27.83 MiB | **4.79 MiB** |
| gzipped CSV | 5.0 MB | 23.55 MiB | **23.54 MiB** |

Read that table twice. The *smaller* files produced the *bigger* repository. Because gzip's output is one long entropy-coded stream, changing byte 100 changes every byte after it, and Git's delta finder has nothing to hold on to. Five versions, five full copies.

That is precisely the situation with a re-saved JPEG, a `.zip`, a `.docx` (which is a zip), a Parquet file, a `.safetensors` checkpoint from a new training run. The bytes look nothing like their predecessor even when the content barely moved.

### Because Git is distributed, everyone pays

This is what makes big files a *social* problem rather than a personal one. `git clone` does not fetch the current state; it fetches **all history**, because that is what being distributed means. A 200 MB asset changed fifty times is a 10 GB clone for every colleague, on every laptop, in every CI job, forever. Our 100 MiB repo clones to 120.1 MiB on disk for a 20 MiB working file.

And here is the cruellest fact: **you cannot fix this by deleting the file.** History is immutable. `git rm` adds a commit in which the file is absent; the fifty old blobs stay exactly where they were. Removing a big file stops the bleeding, it does not heal the wound. The only cure is rewriting history, which means everyone re-clones — see [Keep a clean history, recover from mistakes](../2-collaborating/6-git-cleanup.md "Keep a clean history, recover from mistakes").

### Diff and merge stop meaning anything

```console
git merge alice

warning: Cannot merge binary files: asset.bin (HEAD vs. alice)
Auto-merging asset.bin
CONFLICT (content): Merge conflict in asset.bin
Automatic merge failed; fix conflicts and then commit the result.
```

And your entire conflict-resolution toolkit is now these two commands:

```console
git checkout --ours asset.bin      # keep mine, throw away Alice's day of work
git checkout --theirs asset.bin    # keep Alice's, throw away mine
```

There is no third option. This is *why* teams that live on binary assets end up wanting file locking, which we get to below.

### And the smaller humiliations

* `git status` gets slow on huge trees, because Git stats every tracked path. `core.fsmonitor` and `core.untrackedCache` help a lot; `scalar` (inside Git since 2.38) switches those on for you along with partial clone and background maintenance.
* `git gc` and `git repack` can want a lot of memory, because delta search holds objects in RAM. The knobs are `pack.windowMemory` and `core.bigFileThreshold` (512 MiB by default — above it, Git stops even trying to delta).
* Forges refuse. On GitHub, files over **50 MiB** earn a warning, files over **100 MiB** are **blocked outright**, and the web upload form stops at **25 MiB**. Its guidance is under 1 GB per repository ideally, under 5 GB "strongly recommended" — while its *Repository limits* page states a 10 GB ceiling and a 2 GB push limit, in MB rather than MiB. Two GitHub pages, two sets of units: check the current docs rather than trusting anybody's memory, mine included. GitLab.com caps pushes at 5 GiB and free-tier repositories at 10 GB.

### Find out what you already have

Before we go further: this one-liner tells you the truth about any repository you inherit. It walks every object reachable from every ref and sorts the blobs by size.

```console
git rev-list --objects --all \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
  | awk '$1=="blob" {printf "%.1f MiB  %s  %s\n", $3/1048576, substr($2,1,10), $4}' \
  | sort -rn | head -20

20.0 MiB  e54bc46278  model.bin
20.0 MiB  c81cf4b0df  model.bin
20.0 MiB  afcff9ef22  model.bin
```

Swap `%(objectsize)` for `%(objectsize:disk)` to see what each one costs *after* packing, which is the number that actually matters.

## What to do before reaching for LFS

Nine big-file problems out of ten are not big-file problems. They are discipline problems.

**Don't commit generated artifacts.** `dist/`, `node_modules/`, `target/`, `*.o`, the compiled PDF, the exported video, `__pycache__`. If a command can produce it from things already in the repo, the repo should not contain it. `.gitignore` it and move on. This single rule solves most cases.

**Commit a URL and a checksum instead of the bytes.** A three-line file is a perfectly good representation of a 4 GB dataset:

```yaml
url: https://storage.example.com/datasets/imagenet-subset-2026-03.tar.zst
sha256: 4a7d1ed414474e4033ac29ccb8653d9b1a0e7d1e1e0a9f5a0e2b3c4d5e6f7a8b
size: 4183928832
```

Your `make data` target downloads it, verifies the hash, and refuses to continue if it does not match. The commit pins an **immutable content hash**, which is the only property that actually matters for reproducibility. More on this in [Git for data and models](5-git-data-science.md "Git for data and models") — it is badly underrated.

**Partial clone plus sparse-checkout, for big *source* trees.** This is the modern, genuinely good answer, and it lives in Git itself. You met `--filter` with the other clone options; here is what it does to our 100 MiB monster:

```console
git clone --filter=blob:none --no-checkout file:///path/to/big-and-random partial
git -C partial count-objects -vH | grep size-pack

size-pack: 2.28 KiB
```

Two and a quarter kilobytes. We fetched every commit and every tree and *no file contents at all*. Then:

```console
git -C partial checkout main
git -C partial count-objects -vH | grep size-pack

size-pack: 20.01 MiB
```

Git lazily fetched exactly the one blob the checkout needed. 20 MiB instead of 100 MiB, and it scales the way you want: cost proportional to what you look at, not to what has ever existed. Add `git sparse-checkout set src/ docs/` and you do not even fetch the rest of the tree. (The server has to allow it: `uploadpack.allowFilter = true`. All the big forges do.)

**Shallow clones for CI.** `git clone --depth 1` gave 20.01 MiB for the same repository. CI almost never needs history. Just remember a shallow clone is crippled — no useful `git log`, no `git describe`, no merge base — so use it for build jobs, not release jobs.

## Git LFS, mechanically

Right. You have done the discipline work and you still genuinely need versioned 300 MB binary assets in the repo. Now LFS earns its keep.

The idea in one sentence: **keep a tiny text file in Git, keep the real bytes somewhere else, and swap them automatically on the way in and out of the working tree.**

### Installing it writes filters into your config

```console
git lfs version
git-lfs/3.7.0 (GitHub; darwin arm64; go 1.24.4)

git lfs install
Git LFS initialized.
```

What did that actually *do*? It edited your global `.gitconfig`:

```ini
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
```

That is the whole mechanism, and it is a mechanism Git already had. No magic anywhere. If you would rather not touch your global config, `git lfs install --local` writes the same block into one repository's `.git/config`; there is also `--worktree`, `--system` and `--skip-smudge`.

It also drops four hooks into `.git/hooks`: `pre-push`, `post-checkout`, `post-commit`, `post-merge`. Each is three lines that check `git-lfs` is on your `PATH` and then call it. Nothing you could not have written yourself.

### Tracking writes `.gitattributes`

```console
git lfs track "*.bin"
Tracking "*.bin"

cat .gitattributes
*.bin filter=lfs diff=lfs merge=lfs -text
```

We met `.gitattributes` in [A little structure please](../2-collaborating/4-git-repo-structure.md "A little structure please"). Four attributes, each doing a job:

* `filter=lfs` — run the clean/smudge pair defined above. This is the load-bearing one.
* `diff=lfs` — use LFS's diff driver, so `git diff` prints the pointer's oid and size instead of vomiting 300 MB of binary at your terminal.
* `merge=lfs` — use LFS's merge driver. Which, to be clear, still cannot merge two JPEGs. It just fails politely.
* `-text` — never do end-of-line conversion on these bytes. A CRLF "fix" applied to a binary is data corruption.

> :warning:
> `.gitattributes` **must be committed**. If it is not in the repository, your colleagues' Git has no idea these paths are special and they will commit 300 MB blobs straight into history. Tracking is also per-pattern and only applies to files added *after* the pattern exists — files already in history are not retroactively converted. That needs `migrate`, at the end of this chapter.

### The pointer file is the whole trick

Commit a real 20 MiB file and let's look under the hood.

```console
head -c 20971520 /dev/urandom > weights.bin
git add weights.bin
git lfs status

On branch main

Objects to be committed:

	weights.bin (LFS: a45b7e8)
```

```console
git commit -m "Add weights.bin (20 MiB)"
git show HEAD:weights.bin

version https://git-lfs.github.com/spec/v1
oid sha256:a45b7e8d31e52c3ec69393e8c939a00b7a6731fad511a587a2b6659195cccb8f
size 20971520
```

*That* is what Git stored. Three lines of text. Confirm it with the lowest-level tools we have:

```console
git cat-file -t $(git rev-parse HEAD:weights.bin)
blob
git cat-file -s $(git rev-parse HEAD:weights.bin)
133

git count-objects -vH | head -2
count: 9
size: 36.00 KiB
```

A 133-byte **blob**, and thirty-six kilobytes for the *whole* object database — this little repository also has a readme and three commits — where the asset is 20 MiB. The pointer format is specified: `version` always first, remaining keys sorted alphabetically, one `{key} {value}` per line, whole thing under 1024 bytes. There is exactly one valid encoding of a given pointer, which is what lets `git add` be deterministic.

The `oid` is a SHA-256 of the content, and that is the integrity link: Git guarantees the pointer, the pointer guarantees the bytes. But note carefully — the bytes are **not** in the packfile and **not** part of the object graph that `git fsck` verifies. Your repository can be perfectly intact while the actual data has evaporated.

### Clean and smudge: you could have built this

`clean` runs on `git add`: file in on stdin, pointer out on stdout, real bytes stashed in a local store. `smudge` runs on checkout: pointer in, real bytes out. LFS did not invent this; it generalised `filter.*.clean` / `filter.*.smudge`, which Git has had for years, and added `filter-process` — a long-running protocol so one process handles a whole `git add` instead of forking per file.

Don't take my word for it. Here is a working, thirty-line Git LFS. The clean side:

```console
#!/bin/sh
tmp=$(mktemp); cat > "$tmp"
oid=$(shasum -a 256 "$tmp" | cut -d' ' -f1)
mkdir -p "$STORE"; cp "$tmp" "$STORE/$oid"
printf 'poorman-lfs sha256:%s size:%s\n' "$oid" "$(wc -c < "$tmp" | tr -d ' ')"
rm -f "$tmp"
```

The smudge side reads that one line back, strips the `sha256:` prefix and `cat`s `$STORE/$oid`. Wire them up:

```console
git config filter.poorman.clean  "STORE=$STORE $PWD/bin/poor-clean"
git config filter.poorman.smudge "STORE=$STORE $PWD/bin/poor-smudge"
git config filter.poorman.required true
echo '*.blob filter=poorman -text' > .gitattributes

head -c 5242880 /dev/urandom > big.blob
git add . && git commit -q -m "Poor man's LFS"
git show HEAD:big.blob
poorman-lfs sha256:67f6e2c80ab9f51e74ee476dd56c1bc5e169b751efff1f2d31a2c7bb315c6746 size:5242880

rm big.blob && git checkout -- big.blob && shasum -a 256 big.blob
67f6e2c80ab9f51e74ee476dd56c1bc5e169b751efff1f2d31a2c7bb315c6746  big.blob
```

A 97-byte blob for a 5 MiB file, and the round trip is identical byte for byte. What real LFS adds is the boring, hard ninety-five percent: a transfer protocol, authentication, concurrency, resumption, locking, `migrate`. But you now know that LFS is not a change to Git. It is an *application* of Git.

### The local cache, and why you now have three copies

```console
find .git/lfs -type f
.git/lfs/objects/a4/5b/a45b7e8d31e52c3ec69393e8c939a00b7a6731fad511a587a2b6659195cccb8f

shasum -a 256 weights.bin
a45b7e8d31e52c3ec69393e8c939a00b7a6731fad511a587a2b6659195cccb8f  weights.bin
```

Content-addressed, fanned out by the first two and next two hex digits of the oid — the same trick as `.git/objects`, one level deeper. And that cached file *is* the data, so on disk right now:

```console
du -sh .git/objects .git/lfs weights.bin

 36K	.git/objects       # the 133-byte pointer, plus trees and commits
 20M	.git/lfs           # the LFS cache
 20M	weights.bin        # the working tree
```

**Two full copies plus a pointer.** LFS does not make big files small locally; it makes *history* small remotely. Budget your disk accordingly, and get to know `git lfs prune`.

### The transfer protocol, in outline

On `git push`, the `pre-push` hook runs `git lfs pre-push`, which speaks an entirely separate protocol to an entirely separate service: an HTTP **batch API** ("here are forty oids, tell me which you need and where to put them"), with its own authentication, against its own storage. Git's own push happens independently over whatever transport you configured.

One nuance I verified: with git-lfs 3.x a plain bare repository on a **local filesystem path** does work, via the built-in `lfs-standalone-file` transfer adapter, which simply copies objects into `<bare>/lfs/objects/`.

```console
git init --bare bare-plain.git
git remote add origin /path/to/bare-plain.git
git push -u origin main

Uploading LFS objects: 100% (1/1), 0 B | 0 B/s, done.
 * [new branch]      main -> main
```

Over **ssh or https**, though, the far end has to implement something: either the HTTP batch API (GitHub, GitLab, Bitbucket, Gitea/Forgejo all do) or the pure-SSH `git-lfs-transfer` protocol added in git-lfs 3.0, which needs git-lfs installed server-side. A bare repo served by plain `git-receive-pack` over ssh will not do.

### The commands worth knowing

```console
git lfs ls-files [-l -s]   # which paths in HEAD are LFS-managed (full oids, sizes)
git lfs status             # like git status, but LFS-aware
git lfs env                # every setting, resolved — read this when confused
git lfs track              # list the active patterns
git lfs untrack "*.psd"    # remove a pattern from .gitattributes
git lfs fetch [--all|--recent]   # download objects, no checkout
git lfs pull               # fetch + checkout
git lfs checkout           # turn pointers in the working tree into real files
git lfs prune              # delete local cached objects that are old and pushed
```

`git lfs prune` is what you reach for when the laptop fills up. It is conservative by design: it keeps whatever the current checkout needs, whatever any stash needs, whatever recent branches need (`lfs.fetchrecentrefsdays`, default 7, plus `lfs.pruneoffsetdays`, default 3) and — crucially — anything **not yet pushed**, because for those your local copy is the only copy. It does *not* consult the reflog, so objects reachable only from orphaned commits are always deleted. Run `git lfs prune --dry-run --verbose` first.

### Fetching less

This is where LFS gets genuinely good, and it is the payoff for all that plumbing.

```console
GIT_LFS_SKIP_SMUDGE=1 git clone https://example.com/assets.git
```

Same clone, no smudge: pointer files in your working tree and not one byte of asset data. On the migrated repository we build below, that is the difference between 40 MiB and **196 KiB**. Then `git lfs pull` when and if you want the data. `git lfs install --skip-smudge` makes that the default everywhere.

```console
git config lfs.fetchexclude "raw/**,archive/**"
git config lfs.fetchinclude "models/current/**"
git config lfs.concurrenttransfers 16
```

Comma-separated path filters, very useful in CI where the job needs three files out of four hundred.

> :warning:
> LFS and `--filter=blob:none` partial clone are two answers to the same question and they do not officially know about each other. Combining them is undocumented, and there is a long-standing open bug where `git lfs prune` fails outright inside a partial clone (`Prune error: missing object`). Pick one.

### Locking, which is the real reason game studios use LFS

If two people cannot merge a file, the only workable rule is that two people must not edit it at once. LFS implements advisory locks:

```console
git lfs track --lockable "*.psd"
cat .gitattributes
*.psd filter=lfs diff=lfs merge=lfs -text lockable
```

`lockable` makes the file **read-only in the working tree until you lock it** — a delightfully physical way of saying "ask first".

```console
git lfs lock game/levels/boss.umap
git lfs locks
git lfs unlock game/levels/boss.umap
```

This needs server support, and here the forges genuinely differ. GitLab implements the locking API, as do Gitea, Forgejo and Codeberg. Bitbucket Cloud documents that it does not. GitHub does not implement it either — you get `Remote 'origin' does not support the LFS locking API` — though GitHub documents that mostly by omission, so verify before building a workflow on it.

### Migrating an existing repository

Tracking only affects the future. To actually shrink a repository you must **rewrite history**, and `git lfs migrate` is the tool. Look before you leap:

```console
git lfs migrate info --everything

Sorting commits: ..., done.
Examining commits: 100% (5/5), done.
*.bin	105 MB	5/5 files	100%
```

`--above=50mb` restricts the report to individually large files and `--top=20` widens the list. (In `import` mode `--above` works too, but it cannot be combined with `--include` or `--exclude` — it is the "just take everything big, whatever it is" option.) Then:

```console
git lfs migrate import --everything --include="*.bin"

Sorting commits: ..., done.
Rewriting commits: 100% (5/5), done.
Updating refs: ..., done.
Checkout: ..., done.
```

`--everything` means "all local and remote refs" — that is the flag you want. There is no such thing as `--include-ref=--all`; `--include-ref` takes one refname at a time, as in `--include-ref=refs/heads/main`. Also useful: `--exclude`, `--fixup` (infer the patterns from an existing `.gitattributes`), `--object-map` (a CSV of old→new commit ids, invaluable for fixing up issue trackers) and `--no-rewrite`, which converts files in a *new* commit without touching history at all.

> :warning:
> `migrate import` rewrites every commit. Every **SHA** changes. This is the "never rewrite shared history" rule with the volume turned all the way up: coordinate it, announce it, have everyone re-clone. `migrate export` goes the other way — pointers back to real blobs — and is equally a rewrite.

And now the honest part, which nobody tells you. Immediately after the migration:

```console
git count-objects -vH | grep size-pack
size-pack: 100.04 MiB
```

Nothing shrank! The old blobs are still reachable from the reflog. You have to finish the job:

```console
git reflog expire --expire-unreachable=now --all
git gc --prune=now
git count-objects -vH | grep size-pack

size-pack: 3.28 KiB
```

*Now* we are talking. From 100.03 MiB of packfile to **3.28 KiB**. `.git/objects` is 20 KB. `.git/lfs` still holds 100 MiB, because that is your local cache of your own data — but a fresh clone of the pushed result is 40 MiB with a checkout, and 196 KiB with `GIT_LFS_SKIP_SMUDGE=1`.

## The caveats, plainly

Adopt LFS knowing all of this, rather than discovering it in month four.

**It is not Git.** Separate program, separate protocol, separate storage, separate auth. Which means the beautiful property you relied on for this whole course — that a clone is a complete, independent copy — is gone. `git clone --mirror` no longer backs you up; you need `git lfs fetch --all` too. Your disaster-recovery plan just grew a second moving part.

**It costs money, metered.** GitHub replaced its old pre-paid data packs with metered billing: storage in GiB-months, bandwidth per GiB downloaded, charged to the *repository owner* rather than to whoever clones. Included allowances are, at the time of writing, in the region of 10 GiB of each on Free/Pro and 250 GiB on Team/Enterprise Cloud, with per-file maxima from 2 GB (Free/Pro) to 5 GB (Enterprise Cloud). These numbers move — check the current billing page. Note the failure mode: with no payment method on file, exceeding the allowance **blocks LFS for the rest of the month**, so nobody can clone.

**Adopting it on an existing repo shrinks nothing** until you rewrite history, as we just measured. And **leaving** LFS is also a rewrite.

**Contributors without git-lfs get garbage.** A real clone from a machine with no git-lfs configured:

```console
ls -l model.bin
-rw-r--r--  1 you  staff  133 Jul 29 23:25 model.bin

cat model.bin
version https://git-lfs.github.com/spec/v1
oid sha256:bd0f1a2c80693bd366e78e7f64fc54b86712d1b79c53b397f3d1027232c38249
size 20971520
```

Their build then fails with something spectacularly unhelpful like "invalid PNG header". Every "Download ZIP" tarball from a forge has the same problem, and so does every CI runner whose image forgot git-lfs. Put a check in your build script.

**Forks and pull requests interact badly**, particularly on GitHub, where LFS bandwidth is billed to the repository owner and forks do not inherit LFS objects cleanly. Contributions from forks that touch LFS paths are a recurring support ticket.

**`merge=lfs` does not merge.** It never will. Two edits to one binary is still a coin flip.

### Alternatives worth knowing by name

* **git-annex** — older than LFS, far more flexible (many backends, "this file lives on that USB drive"), considerably harder to learn, and still actively maintained. If your storage topology is unusual, look at it.
* **Xet** — content-defined chunking with deduplication *below* the file level, so changing a fraction of a large file uploads a fraction of the bytes. It is Hugging Face's storage backend now, and `git-xet` exists as an LFS custom transfer agent for talking to the Hub. It is a genuinely good idea and we cover it properly in [Git for data and models](5-git-data-science.md "Git for data and models").
* **Partial clone, sparse-checkout and `scalar`** — the answer for a large *source* tree, which is a different problem from a large *binary*. Microsoft's VFS for Git was the first attempt; Scalar replaced it and now ships inside Git.
* **Object storage plus a committed manifest** — no new tooling, no new protocol, no vendor quota, and the commit still pins an immutable hash. Badly underrated.

## Summary `git lfs`

* Git stores every version of every file as a whole **blob**. **Packfile** delta compression helps enormously when versions share long runs of bytes and not at all when they do not — which the file *format* decides, not Git. Measured: five commits of a 13 MB CSV pack to 4.79 MiB; the same data gzipped, 23.54 MiB.
* `git clone` fetches all history, so a big file costs every colleague forever. Deleting it later does not help; only rewriting history does.
* `git count-objects -vH` is the honest accounting of repository size, and `git rev-list --objects --all | git cat-file --batch-check=…` finds the big blobs hiding in your history.
* Before LFS: `.gitignore` generated artifacts, commit a URL plus a checksum, use `--filter=blob:none` with `git sparse-checkout` for big source trees (a 2.28 KiB clone!), `--depth 1` for CI.
* `git lfs install` writes a `[filter "lfs"]` block with `clean`, `smudge`, `process` and `required` into your config, plus four hooks. `--local` keeps it to one repository.
* `git lfs track "*.psd"` writes `*.psd filter=lfs diff=lfs merge=lfs -text` into `.gitattributes`, which **must be committed** and only affects files added afterwards.
* The **pointer file** is a ~130-byte text blob holding `version`, `oid sha256:…` and `size`. The real bytes live in `.git/lfs/objects/` locally and on an LFS server remotely.
* `clean` runs on `git add`, `smudge` on checkout. These are ordinary Git filters — you can build a crude LFS yourself in thirty lines of shell.
* `git lfs ls-files`, `status`, `env`, `fetch`, `pull`, `checkout`, `prune`, `untrack`, `lock`/`unlock`/`locks`, `migrate info`/`import`/`export`. `GIT_LFS_SKIP_SMUDGE=1`, `--skip-smudge`, `lfs.fetchinclude`/`fetchexclude` and `lfs.concurrenttransfers` let you clone a huge repository cheaply.
* `git lfs migrate import --everything --include="*.bin"` **rewrites history**, and you must `git reflog expire --expire-unreachable=now --all && git gc --prune=now` afterwards or nothing shrinks. Measured: 100.03 MiB → 3.28 KiB.
* LFS is not part of Git: it needs server support, it is metered and billed, it breaks clone-as-backup, and contributors without it get pointer files and baffling errors.
