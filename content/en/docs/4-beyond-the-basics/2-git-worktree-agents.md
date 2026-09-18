---
title: Worktrees and agents, parallel work at machine speed
slug: "git-worktree-agents"
weight: 32
---
# Worktrees and agents, parallel work at machine speed

The previous chapter taught a 2015 feature. This chapter is about why, ten years later, a lot of people suddenly discovered they needed it.

## What changed

For as long as there has been version control, the rate at which a repository changed was bounded by how fast humans could type. One person, one editor, one working directory: the tooling matched the biology.

Coding agents broke that assumption. Whatever you use — Claude Code, Codex, Aider, Cursor's background agents, Devin-likes, and whatever ships next month — the interesting property is not that it writes code. It is that you can run **several at once**. And the moment you can, the bottleneck moves. It is no longer typing speed. It is how many independent changes you can have in flight without them colliding.

And now look at your working directory. One set of files. One **index**. One **HEAD**.

A single working tree is a **mutex**.

Two agents editing files in the same directory produce garbage, and they produce it quietly. Agent A reads a file, thinks about it for eight seconds, and writes it back — over the version agent B wrote in the meantime. Nobody errors. `git status` shows a plausible-looking diff. The tests fail somewhere unrelated an hour later. Git will not save you: Git sees a working directory, and a working directory has no notion of who wrote what.

This is a concurrency problem, and it has the shape of every concurrency problem: either serialise access, or give each worker its own copy of the mutable state.

Git has had the second option since 2015.

## The core pattern

One worktree per agent per task. Each on its own branch. All sharing one object database.

```console
git worktree add ../wt-rounding  -b agent/rounding  main
git worktree add ../wt-coupon    -b agent/coupon    main
git worktree add ../wt-empty     -b agent/empty     main
```

Then launch one agent in each directory, with the constraint that its working directory *is* that worktree. That is the whole idea. Everything else in this chapter is consequences.

Here is a runnable version. Nothing about it is clever, which is the point:

```console
#!/bin/sh
# fan-out.sh <task-file>...   one worktree, one branch, one agent per task
set -e
root=$(git rev-parse --show-toplevel)
parent=$(dirname "$root")
base=${BASE:-main}
git -C "$root" fetch --quiet origin "$base" 2>/dev/null || true

for task in "$@"; do
  slug=$(basename "$task" .md)
  dir="$parent/wt-$slug"
  git -C "$root" worktree add --quiet -b "agent/$slug" "$dir" "$base"
  if [ -x "$dir/setup-worktree.sh" ]; then (cd "$dir" && ./setup-worktree.sh); fi
  echo "==> agent/$slug ready in $dir"
  # launch your agent here, with $dir as its working directory, e.g.
  # (cd "$dir" && your-agent --prompt-file "$root/$task") &
done
git -C "$root" worktree list
```

```console
sh fan-out.sh tasks/rounding.md tasks/coupon.md

  bootstrap: installing deps in /home/ori/fanlab/wt-rounding
==> agent/rounding ready in /home/ori/fanlab/wt-rounding
  bootstrap: installing deps in /home/ori/fanlab/wt-coupon
==> agent/coupon ready in /home/ori/fanlab/wt-coupon
/home/ori/fanlab/app          da53256 [main]
/home/ori/fanlab/wt-coupon    da53256 [agent/coupon]
/home/ori/fanlab/wt-rounding  da53256 [agent/rounding]
```

Note the `setup-worktree.sh` hook. We argued in the previous chapter that a project whose worktrees are cheap to create is a project with good bootstrap scripts. With agents that stops being an aesthetic point and becomes load-bearing, because you are going to do this twenty times a day. An agent can also run the script itself — that is a fine thing to put in its instructions.

> :information_source:
> This pattern is becoming standard in the harnesses themselves rather than something you build. As of Claude Code 2.1, for instance, `claude -w` / `claude --worktree [name]` starts a session in a fresh worktree, and `--tmux` (which requires `--worktree`) puts each one in its own terminal pane. Other tools have their own spellings, and some create worktrees behind your back without telling you. Check the version you actually have — flags in this corner of the world change monthly. The *Git* underneath does not.

## Why not the alternatives

### Multiple clones

This works. People do it. It costs disk and, on a big repository, bandwidth and a lot of waiting.

But the real objection is different, and it is the argument for this whole chapter: **with separate clones, the agents cannot see each other's work.**

Agent A commits in clone A. Agent B, in clone B, has no way to see that commit until somebody pushes it to a shared remote and somebody else fetches it. So you cannot diff their work. You cannot merge one into another. You cannot ask "did these two solve it the same way?" without a round trip through a server.

With worktrees, `refs/heads/*` is shared. The instant agent A commits, its branch exists for everyone:

```console
git diff agent/a agent/b
git log --oneline agent/a..agent/b
git range-diff main..agent/a main..agent/b
```

No push. No fetch. No network. This is the killer argument and it is not close.

### A container or VM per agent

Stronger isolation, and the right answer when you do not fully trust the agent with your machine — which is a completely reasonable position to hold. It is heavier: an image, a volume, a startup cost, and the shared-object-store advantage above goes away unless you mount it in.

And note that these are not competing choices. Inside the container you still want a worktree, because you still want each agent on its own branch in one object store.

> :warning:
> A worktree is **not a sandbox**. It isolates *files and refs*. It does not isolate *processes and syscalls*. The agent can `cd ..` into your main worktree. It can read `.git/config`, including any credentials or URLs in it. It can read and modify the shared `hooks/`. It can `git push`. It can `rm -rf` anything your user account can. If your threat model includes "the agent does something destructive", a worktree does nothing for you and you want a container, a VM, or a machine you do not care about.

### One worktree, agents taking turns

Simple, and *correct* when the tasks touch the same code. If two changes genuinely overlap, parallelising them does not make them faster — it makes them into a merge conflict you will resolve by hand. Serialising is not a failure. It is often the honest answer.

## Fan-out and fan-in patterns

### Parallel independent tasks

N unrelated tickets, N worktrees, N branches, review and merge each. The mechanics are trivial. The hard part is the scheduling question: **which tasks are actually independent?**

Git can help you guess, because your history already records which files change together. If two areas of the codebase have never appeared in the same **commit**, they are probably safe to work on simultaneously. If they always appear together, they are not:

```console
git log --pretty=format:'--' --name-only -- src | head -40
```

Every `--` starts a commit; the filenames under it changed together. Feed that to `sort | uniq -c` on pairs and you have a crude coupling map. Crude is fine — you are making a scheduling guess, not proving a theorem.

### Competitive generation

Same task, N agents, N worktrees. Then compare and pick.

The obvious tool is `git diff`, and for the *result* it is the right one:

```console
git diff --stat try-a try-b

 src/cart.py | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)
```

But that compares two end states. What you usually want to compare is two *approaches* — two whole series of commits built on the same base. There is a command for exactly that, `git range-diff`. It has existed since Git 2.19 and almost nobody knows it.

`git range-diff` takes two ranges of commits and produces a **diff of diffs**. It pairs up commits from the two series that look like they are trying to do the same thing, then shows how they differ. Two agents' attempts at one task is precisely the case it was designed for (it was written for comparing versions of a patch series on a mailing list, which is the same shape).

Two agents that solved it differently:

```console
git range-diff main..try-a main..try-b

1:  afa5504 < -:  ------- Format prices with integer arithmetic
-:  ------- > 1:  31c644d Use Decimal to format prices
2:  f4be4ee = 2:  db33408 Add a test for format_price
```

Read the middle column. `<` means "only in the left series". `>` means "only in the right series". `=` means "these two commits are identical in content". So: they took completely different approaches to the fix, and then wrote *byte-for-byte the same test*. Which is a genuinely interesting thing to learn in one line of output.

Now two agents that took the same approach, one of them more carefully:

```console
git range-diff main..try-a main..try-c

1:  afa5504 = 1:  e757365 Format prices with integer arithmetic
2:  f4be4ee ! 2:  21945c0 Add a test for format_price
    @@ Metadata
     Author: Ori Pekelman <ori+git-training@pekelman.com>

      ## Commit message ##
    -    Add a test for format_price
    +    Add tests for format_price

      ## tests/test_cart.py ##
     @@
    @@ tests/test_cart.py
     +def test_format_price():
     +    from src.cart import format_price
     +    assert format_price(1999) == "19.99"
    ++    assert format_price(5) == "0.05"
```

`=` on the first commit: identical fix. `!` on the second: same intent, different content — and then the nested diff, where the doubled `++` marks a line present only in `try-c`. It added a test for the five-cent case. That is your winner, and you found out in one command.

`--no-patch` gives you just the summary table when you only want the shape:

```console
git range-diff --no-patch main..try-a main..try-c

1:  afa5504 = 1:  e757365 Format prices with integer arithmetic
2:  f4be4ee ! 2:  21945c0 Add a test for format_price
```

Then pick a winner and delete the losers, or cherry-pick the best commits out of each. `git cherry-pick` across worktree branches costs nothing, because they are all in one object store.

### Pipeline

Worktree A implements. Worktree B reviews A's branch. Worktree C writes tests against it. Because refs are shared, B and C see A's commits **the instant they exist** — no push, no pull, no coordination:

```console
cd ../wt-review
git log --oneline main..agent/implement
git diff main...agent/implement
```

This is the pattern that is genuinely impossible with separate clones, and it is worth structuring work around.

### Long-running verification

An agent iterating in one worktree while the full suite runs against a pinned commit in another:

```console
git worktree add --detach ../verify agent/implement
cd ../verify && ./run-tests.sh
```

`--detach` matters here: it pins a specific **commit**, so the agent's next commit does not move the ground under a running test suite. That is not a detail, it is the reason detached worktrees exist.

### The fan-in problem

Here is where optimism goes to die. N branches all based on the same `main` will conflict with each other in proportion to how much they overlap, and you only find out at merge time.

Things that help, roughly in order of how much:

* **Merge in order of increasing size.** Small, obviously-correct changes first. Every merge you land makes the next rebase noisier, so pay that cost on the branches that can absorb it.
* **`git rerere`.** Enable it (`git config rerere.enabled true`) and Git records how you resolved a conflict, then replays that resolution the next time the same conflict shows up. With one branch that is a nicety. With five branches that you are going to rebase repeatedly onto a moving `main`, it is the difference between annoying and unbearable. We saw it work in real output: on the second attempt at the same merge Git printed `Resolved 'src/format.py' using previous resolution.` and left the file correct.
* **Rebase each branch onto the previous one** rather than all onto `main`, when the changes are related. You resolve each conflict once, in a small context, instead of resolving a pile of them at the end.
* **Force-push hygiene.** Agents rebase and amend, which means they force-push. `--force-with-lease` instead of `--force`, always. But read the warning below, because in this specific setup the lease is weaker than you think.

> :warning:
> A verified, non-obvious footgun. `--force-with-lease` protects you by comparing the remote against your local **remote-tracking ref**. Remote-tracking refs are *shared between worktrees*. So when agent B pushes to a branch, `refs/remotes/origin/<branch>` is updated for **everyone** — including agent A, who never saw B's commit. A's lease then looks perfectly up to date, and its force-push destroys B's work:
>
> ```console
> # worktree A, which never fetched B's commit:
> git push --force-with-lease origin topic
> To ../o.git
>  + f0a048b...d218b5a topic -> topic (forced update)
> ```
>
> The same scenario between two separate *clones* is refused, because there the tracking refs are independent:
>
> ```console
> git push --force-with-lease origin topic
> To /home/ori/lease2/o.git
>  ! [rejected]        topic -> topic (stale info)
> ```
>
> The lesson: give each agent its **own branch namespace** (`agent/<slug>/...`) and never let two of them push to one branch. `--force-with-lease --force-if-includes` helps somewhat, but not sharing a branch helps completely.

## Operational reality

This is the part people learn the hard way. None of it is about Git.

**Bootstrap cost.** Every worktree needs dependencies. Shared caches are the fix: `CARGO_TARGET_DIR`, `UV_CACHE_DIR`, the pnpm store, `ccache`. Symlink `.env`. Use `direnv` so a `.envrc` per worktree exports the right values when anything `cd`s in. Then put all of it in `setup-worktree.sh`, commit it, and let the agent run it.

**Port collisions.** If each agent starts a dev server, they all want `:3000`. Assign deterministically from the worktree name so it is stable across restarts:

```console
for n in feature-x hotfix wt-coupon; do
  printf '%-12s %s\n' "$n" $(( 3000 + $(printf '%s' "$n" | cksum | cut -d' ' -f1) % 100 ))
done

feature-x    3067
hotfix       3032
wt-coupon    3001
```

In the worktree itself that is `port=$(( 3000 + $(printf '%s' "$(basename "$PWD")" | cksum | cut -d' ' -f1) % 100 ))`, and `direnv` is the natural place to put it. Not collision-proof — hash it into a wider range, or keep an index file, if you are running many.

**Global mutable state, which is the real limit.** Test databases, Redis keyspaces, message queues, S3 buckets, fixture directories, `/tmp` paths. This, not Git, is what actually stops you from running five test suites at once. The fixes, in order of preference: a database name or schema per worktree; `COMPOSE_PROJECT_NAME` per worktree so Docker Compose does not share containers; or accept it and serialise the test runs while parallelising the editing. If your test suite cannot run twice concurrently on one machine, no amount of Git will make agents parallel.

**Disk.** N × working tree, as established. Fine for source. Painful the moment your repository holds large binaries — see [Git LFS](4-git-lfs.md "Git LFS") for the shape of that problem.

**CPU and RAM.** N agents, plus N language servers, plus N test runs. As a rule of thumb, budget one worktree per two cores and check your memory headroom before believing it — a language server on a large project can be a gigabyte or more, and the number that actually works on your machine is something you measure, not something you read in a course. When your laptop starts swapping, everything gets slower than doing the tasks one at a time, and you will not notice for twenty minutes.

**Cleanup discipline.** Agents create branches and worktrees and abandon them without a shred of remorse. Run something like this on a schedule:

```console
#!/bin/sh
# Remove every agent/* worktree whose branch is already merged into $BASE.
set -e
base=${BASE:-main}
root=$(git rev-parse --show-toplevel)
git -C "$root" worktree list --porcelain |
  awk '/^worktree /{w=$2} /^branch /{print $2"\t"w}' |
  while IFS="	" read -r ref dir; do
    branch=${ref#refs/heads/}
    case "$branch" in agent/*) ;; *) continue ;; esac
    if git -C "$root" merge-base --is-ancestor "$ref" "$base"; then
      echo "merged  -> removing $branch"
      git -C "$root" worktree remove "$dir"
      git -C "$root" branch -d "$branch"
    else
      echo "ahead   -> keeping  $branch"
    fi
  done
git -C "$root" worktree prune -v
```

```console
sh fan-in-cleanup.sh

ahead   -> keeping  agent/coupon
merged  -> removing agent/rounding
Deleted branch agent/rounding (was 750878a).
```

Note the order — worktree first, then branch — because as we saw, a branch that a worktree holds cannot be deleted.

> :warning:
> Abandoned worktrees keep garbage alive. An agent's commits are reachable from that worktree's `HEAD` and `logs/HEAD`, so `git gc` cannot collect them, even with `--prune=now`. I made a throwaway commit in a detached worktree, ran `git gc --prune=now`, and `git cat-file -t <sha>` still answered `commit`. After `git worktree remove` plus `git reflog expire --expire-unreachable=now --all`, the same `git cat-file` finally said `could not get object info`. A repository accumulating abandoned agent worktrees simply never shrinks.

**Observability.** With five agents running, "what is going on" is a real question. Three commands answer most of it.

`git worktree list` is your dashboard — who is where, on what:

```console
git worktree list

/home/ori/fleet/app            8bc9a36 [main]
/home/ori/fleet/wt-coupon      aa3b806 [bug/coupon]
/home/ori/fleet/wt-empty-cart  daacd41 [bug/empty-cart]
/home/ori/fleet/wt-rounding    95e2fdc [bug/rounding]
```

`git for-each-ref` tells you who has actually produced something. `%(ahead-behind:main)` prints two numbers, commits ahead and commits behind:

```console
git for-each-ref --sort=-committerdate refs/heads/ \
  --format='%(refname:short)|%(ahead-behind:main)|%(contents:subject)'

bug/empty-cart|1 0|Refuse to check out an empty cart
bug/coupon|1 0|Clamp coupons so a total can never go negative
bug/rounding|1 0|Round prices with integer arithmetic
main|0 0|Initial app
```

Three branches, each one commit ahead of `main`, none behind. And `git log --all --oneline --graph` shows the shape of the whole fleet at once:

```console
* daacd41 Refuse to check out an empty cart
| * aa3b806 Clamp coupons so a total can never go negative
|/
| * 95e2fdc Round prices with integer arithmetic
|/
* 8bc9a36 Initial app
```

Three prongs off one base. That picture is what a healthy fan-out looks like, and a glance tells you when it stops being one.

**Commit hygiene.** Agents commit badly in both directions: one enormous commit for a change with four separable parts, or eleven commits called `fix`, `fix again`, `wip`. Both are fixable with `git rebase -i` *before* a human sees the branch, and doing it is worth the two minutes — you are about to ask somebody to review this.

More importantly: ask the agent to write the commit message explaining **why**. The diff already says what. An agent has the context — which failing test, which report, what it tried first — at the moment it commits, and that context is gone forever ten minutes later. This is the same argument the whole course has been making about commit messages, except that now you can put it in a prompt and get it for free.

**Hooks fire everywhere.** Hooks are shared, and each worktree runs them. A three-second `pre-commit` hook running your full linter is a nuisance for you and a tax multiplied by N agents each committing every few minutes. Make the hook fast, or make it check only staged files.

## Guardrails

A short list of things you should simply refuse to let a fleet of agents do. Not out of paranoia — each of these is something I have watched go wrong.

**No force-push to a shared branch.** Covered above: the lease does not protect you here. One branch namespace per agent.

**No `git clean -xfd`.** Agents reach for it because it is the textbook way to get a pristine tree. In a worktree it deletes exactly the untracked files that make the worktree work:

```console
git clean -xfdn
Would remove .env

git clean -xfd
Removing .env
```

The symlink dies and the original survives, so you get away with it that time. If you *copied* the `.env` instead of linking it, it is gone. Prefer `git stash --include-untracked` or `git restore`, or make the guard explicit in the agent's instructions.

**No amending or rebasing anything already pushed.** The rule from [Playing with our revisions](../1-understanding-git/7-play-with-git-revisions.md "Playing with our revisions") does not get suspended because a machine is typing. If a human or a CI job has seen the commit, it is history now.

**No pushing to `main`.** Protected branches on your forge are the real enforcement; a rule in a prompt is a suggestion. Use both.

Two structural measures are worth more than all four rules together.

*Per-worktree config.* With `extensions.worktreeConfig` on, give each agent worktree its own identity:

```console
git config --worktree user.name  "agent-rounding"
git config --worktree user.email "agent-rounding@example.invalid"
```

Now `git log`, `git blame` and `git shortlog -n -s` tell you which agent wrote which line, forever. That is worth a lot when you are auditing.

*A remote they can push to that is not the real one.* The strong version: point the agents' `origin` at a bare repository on your own disk, review there, and push upstream yourself. It costs one `git init --bare` and it removes an entire category of accident.

## End to end

One concrete run. Three independent bugs in a small Python application: prices round wrong, coupons can push a total negative, and checkout accepts an empty cart. Three separate files — which is *why* we can parallelise them.

Fan out:

```console
for b in rounding coupon empty-cart; do
  git worktree add -q "../wt-$b" -b "bug/$b" main
done
git worktree list

/home/ori/fleet/app            8bc9a36 [main]
/home/ori/fleet/wt-coupon      8bc9a36 [bug/coupon]
/home/ori/fleet/wt-empty-cart  8bc9a36 [bug/empty-cart]
/home/ori/fleet/wt-rounding    8bc9a36 [bug/rounding]
```

**[Narration.]** Now three agents run, one per directory, each told to fix its bug and commit with a message explaining why. I am not going to show you invented terminal output from an AI tool. What follows is real Git output from the state they left behind.

Each branch has one commit:

```console
git log --oneline main..bug/rounding
95e2fdc Round prices with integer arithmetic

git diff --stat main...bug/rounding
 src/format.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

And the message explains itself, which is the whole ask:

```console
git log -1 bug/rounding

commit 95e2fdc531dab793a8f03a715f54c169031bd580
Author: Ori Pekelman <ori+git-training@pekelman.com>
Date:   Wed Jul 29 07:20:00 2026 +0200

    Round prices with integer arithmetic

    Float division rendered 5 cents as 0.05000000000000001. Money is integral,
    so divmod on cents has no representation error to begin with.
```

Before merging, check the independence assumption was true:

```console
for b in bug/rounding bug/coupon bug/empty-cart; do
  echo "$b:"; git diff --name-only "main...$b" | sed 's/^/    /'
done

bug/rounding:
    src/format.py
bug/coupon:
    src/cart.py
bug/empty-cart:
    src/checkout.py
```

Three branches, three files, no overlap. This will be painless — and if it had *not* looked like this, that is the moment to change the merge order rather than to discover it mid-conflict.

Fan in:

```console
git merge --no-ff -m'Merge bug/rounding'   bug/rounding
git merge --no-ff -m'Merge bug/coupon'     bug/coupon
git merge --no-ff -m'Merge bug/empty-cart' bug/empty-cart

Merge made by the 'ort' strategy.
 src/format.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
Merge made by the 'ort' strategy.
 src/cart.py | 4 ++++
 1 file changed, 4 insertions(+)
Merge made by the 'ort' strategy.
 src/checkout.py | 2 ++
 1 file changed, 2 insertions(+)
```

```console
git log --oneline --graph

*   acc977c Merge bug/empty-cart
|\
| * daacd41 Refuse to check out an empty cart
* |   f1df641 Merge bug/coupon
|\ \
| * | aa3b806 Clamp coupons so a total can never go negative
| |/
* |   5c1c370 Merge bug/rounding
|\ \
| |/
|/|
| * 95e2fdc Round prices with integer arithmetic
|/
* 8bc9a36 Initial app
```

`--no-ff` on purpose: the merge commits record that these were three parallel efforts, which is true and which the person reading this history in six months will want to know.

Clean up — worktrees first, branches second:

```console
git branch --merged main

+ bug/coupon
+ bug/empty-cart
+ bug/rounding
* main
```

The `+` markers are Git telling you these branches are still held by worktrees, which is exactly why the next line comes before the one after it:

```console
for b in rounding coupon empty-cart; do git worktree remove "../wt-$b"; done
git branch --merged main --format='%(refname:short)' | grep -v '^main$' | xargs git branch -d

Deleted branch bug/coupon (was aa3b806).
Deleted branch bug/empty-cart (was daacd41).
Deleted branch bug/rounding (was 95e2fdc).
```

```console
git worktree list
/home/ori/fleet/app  acc977c [main]

git branch
* main
```

Back to one desk. Three bugs fixed.

## An honest closing note

The agent tooling in this chapter is a year or two old. Flags will be renamed, harnesses will grow their own orchestration, some of the products named here will not exist in three years, and the specific `claude -w` I verified while writing this may have moved by the time you read it. Treat every product detail above as a snapshot.

The Git underneath is from 2015 and is not going anywhere. `git worktree`, the `gitdir:` link, one shared object store, per-worktree **HEAD** and **index**, `git range-diff`, `rerere`. None of it was designed for this and all of it fits, because it was designed around the actual structure of the problem: history is shared, checkouts are not.

Which is, finally, the payoff for all the time this course spent making you `cat .git/HEAD`. You can now evaluate any new agent harness — including ones that do not exist yet — with three questions:

1. What does it do to **HEAD**?
2. What does it do to the **index**?
3. What does it do to my **refs**, and can it push?

Anything that answers those honestly is worth trying. Anything that cannot answer them is doing something to your repository that you should find out about before you trust it with your work.

## Summary, worktrees and agents

* A single working tree is a mutex. Concurrent agents in one directory silently overwrite each other, and Git cannot detect it.
* The pattern: one worktree per agent per task, each on its own branch, all sharing one object store.
* Worktrees beat multiple clones because **refs are shared** — every agent's commits are instantly visible to every other, so `git diff`, `git log A..B`, `git range-diff` and `git cherry-pick` work across agents with no network at all.
* A worktree is **not a sandbox**. It isolates files and refs, not processes. Use containers when you need a real boundary — with worktrees inside them.
* Patterns: parallel independent tasks; competitive generation compared with `git range-diff`; pipelines where one worktree reviews another's branch as it appears; long-running verification against a `--detach`ed pinned commit.
* `git range-diff <range-a> <range-b>` diffs two *series* of commits. `=` identical, `!` same intent different content (with a nested diff), `<` and `>` present in only one side. It is the right tool for comparing two attempts at one task.
* `git rerere` earns its keep the moment you have several branches to rebase onto a moving `main`.
* `--force-with-lease` is weaker between worktrees than between clones, because remote-tracking refs are shared. Give every agent its own branch namespace.
* The real limits are not Git: bootstrap cost, port collisions, shared test databases and other global mutable state, disk, and RAM. Fix them with `setup-worktree.sh`, deterministic per-worktree ports, per-worktree database names and `COMPOSE_PROJECT_NAME`.
* Clean up on a schedule: remove the worktree *before* deleting its branch, `git worktree prune`, and remember that an abandoned worktree's `HEAD` and reflog keep objects alive against `git gc`.
* Observe with `git worktree list`, `git for-each-ref --format='%(refname:short)|%(ahead-behind:main)|%(contents:subject)'` and `git log --all --oneline --graph`.
* Guardrails worth enforcing: no force-push to shared branches, no `git clean -xfd` (it removes the `.env` you symlinked), no amending or rebasing anything already pushed, no pushing to `main`. In the strong version, give the agents a remote that is not the real one.
