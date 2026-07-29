---
title: Continuous deployment
url: "/docs/git-cd/"
weight: 44
---
# Continuous deployment

In the [previous chapter](3-git-static-site.md "Deploying a simple static site") we deployed a site by pushing
to a branch, and the whole mechanism fitted in a shell script. Real applications are not much
harder — but they force us to be precise about *when* a release happens, *what* exactly gets
released, and what we do when it goes wrong.

All three of those questions have Git answers, which is why this chapter belongs in a Git course.

## Three words people use interchangeably, and should not

**Continuous integration** is about the mainline: every change is merged often and the mainline is
always green. That was the [previous chapter but one](2-git-ci.md "Continuous integration with Git").

**Continuous delivery** means every green commit is *releasable*. The artifact is built, signed,
tested and sitting in a registry; the pipeline right up to production is automated and rehearsed.
The last step is a human decision — somebody clicks, or pushes a tag.

**Continuous deployment** means that last step is gone. Green commit, therefore released. No
button.

The distinction is not pedantry, because the gap between the two is where organisations actually
live. Continuous delivery is an engineering achievement: you can ship at any moment. Continuous
deployment is an organisational one: you have decided you *will*. Plenty of excellent teams stop
deliberately at delivery, because their customers are hospitals or banks and a release is a
scheduled, communicated event.

My opinion, since this course gives opinions: get to continuous *delivery* first, always. It is
pure upside — the ability to ship in five minutes is exactly what you want during an incident,
whether or not you exercise it hourly. Whether you then remove the button is a business decision,
not a technical one.

## Triggering a release from Git

### Deploy on push to a branch

The simplest trigger, and the one we already built: something watches a branch, and every commit
that lands there gets deployed. Perfect for staging environments and for static sites.

### Deploy on tag

The other trigger, and the better one for anything a customer sees:

```console
git tag -a v1.2.3 -m 'Release 1.2.3'
git push --follow-tags
```

CI listens for `refs/tags/v*` and takes it from there. In GitHub Actions:

```yaml
on:
  push:
    tags: ['v*.*.*']
```

Here is the opinion, and it is a strong one: **tags are the right trigger for anything a customer
sees**, because a tag is a deliberate, named, immutable decision, while a branch tip is merely
whatever landed last. "Release 1.2.3" is a sentence a human chose to say. "The current tip of
`main`" is an accident of merge ordering that nobody signed off on. When someone asks you at 2
a.m. what is in production, `v1.2.3` is an answer; "whatever was on main around six" is not.

> :information_source:
> `git push --follow-tags` pushes your commits plus the **annotated** tags that lead to them — and
> deliberately not lightweight tags. That is another good reason to use `git tag -a`: annotated
> tags are objects with an author, a date and a message (and can be signed with `-s`), and they
> are the ones that travel. I tested this while writing the chapter: a lightweight `git tag lw-1`
> is silently left behind by `--follow-tags`, which is exactly the sort of thing that ruins an
> afternoon.

### Environment branches, tag promotion, or promoting the artifact

Three shapes, in increasing order of how much I like them.

**Environment branches.** `main` deploys to staging, and a `production` branch deploys to
production; promoting means merging or fast-forwarding `main` into `production`. It is easy to
understand and easy to see (`git log production..main` is literally "what is waiting to go
live"). Its flaw is that the two branches can genuinely diverge, and then you have a merge
conflict standing between you and a release.

**Tag-based promotion.** One branch, and releases are tags. `v1.2.3` deploys to staging;
`v1.2.3-prod`, or a GitHub Release marked non-prerelease, or a manual approval on the same tag,
goes to production. Fewer moving refs, no divergence.

**Promote the artifact, do not rebuild it.** Build the container image *once*, from one commit,
and promote *that exact image* — by digest, `sha256:…`, not by tag — through staging to
production. This is the one to aim for.

Why? Because rebuilding per environment is a reproducibility bug wearing a hat. Two builds of the
same commit are not guaranteed to be the same bytes: a base image moved, a transitive dependency
published a patch, a mirror served a different file, the build ran on a runner with a different
toolchain. If staging and production run *different bytes*, then testing on staging proved
something about a program that is not in production. Build once, test that thing, ship that thing.

## Stamp the version into the artifact

Small habit, enormous payoff. Every deployed thing should be able to tell you which commit it is.

```console
$ git describe --tags --always --dirty
v1.1.0-1-g1b81782
```

That output, from a real repository, reads: one commit after the tag `v1.1.0`, at commit
`1b81782` (the `g` stands for "git"). Add `--dirty` and an uncommitted change appends `-dirty`,
which is how a build script tells you it is building something that exists nowhere in history:

```console
$ git describe --tags --always --dirty
v1.1.0-1-g1b81782-dirty
```

`--always` makes it fall back to a bare SHA when there are no tags at all, so the command never
fails in a fresh repository.

Bake that string, plus the full commit SHA and the build time, into the artifact — a Go `ldflags`
variable, a `VERSION` file in the image, a build argument, an environment variable — and expose it
on a boring endpoint:

```console
$ curl -s https://example.com/version
{"version":"v1.1.0-1-g1b81782","commit":"1b81782f4c…","built":"2026-07-29T21:36:22Z"}
```

During an incident, this one endpoint collapses an entire category of confusion. "Is the fix
deployed?" stops being a conversation and becomes a `curl`. And because the SHA is content-derived,
you can hand it to `git show` and see *exactly* what is running, which is a promise no version
number alone can make.

> :warning:
> Version stamping is the number one victim of the shallow clone. In a `fetch-depth: 1` job
> there are no tags, so `git describe --tags --always` cheerfully prints a bare SHA and exits
> zero. Your release gets stamped `1b81782` instead of `v1.1.0`, and nobody notices until it
> matters.

## Letting commit messages drive the version number

If your commit messages follow a convention, a machine can compute the release for you. The
dominant one is Conventional Commits: `feat: …`, `fix: …`, `chore: …`, and `feat!:` or a
`BREAKING CHANGE:` trailer for incompatible changes.

The mechanism is simple enough that you could write it yourself, and worth understanding rather
than treating as magic. The tool:

1. finds the most recent release tag;
2. reads every commit message since that tag;
3. maps them to a bump — a `fix` is a patch, a `feat` is a minor, a breaking change is a major;
4. writes or extends `CHANGELOG.md` from the subjects it just parsed;
5. creates the new tag (and usually a GitHub Release), which then triggers the deployment we set
   up above.

`semantic-release` does this end-to-end on every push. `release-please` instead maintains a
standing "release PR" that accumulates the changelog, so a human still merges it — a nice halfway
house between automation and consent. `changesets` inverts the whole thing: contributors write a
small changeset file describing their change's impact, which suits monorepos publishing many
packages.

And the tradeoff, honestly: this puts *machine-readable structure* into *human* commit messages.
You get versioning and changelogs for free, and you pay by never again writing a commit subject
in a natural voice — plus a squashed pull request title now silently decides your version number.
Whether that is a good trade depends on how much you value the changelog. On a library with
thousands of users: obviously worth it. On an internal service that deploys forty times a day:
probably not.

## Changelogs out of history

Even without automated versioning, your history is a changelog if you ask it nicely:

```console
$ git log --pretty='* %s (%h)' v1.0.0..v1.1.0
* feat: add the other thing (efacf84)
* fix: correct the thing (b37d565)
```

That is real output. `v1.0.0..v1.1.0` is the range syntax from
[Playing with our revisions](../1-understanding-git/7-play-with-git-revisions.md "Playing with our revisions"); `%s` is the subject and `%h`
the abbreviated SHA. Add `--no-merges` to drop merge commits and you have something you can paste
into a release note.

[`git-cliff`](https://git-cliff.org/) is the polished version of this idea: a configurable
changelog generator that reads Conventional Commits out of your history and groups them into
sections. It changes nothing about your repository, which makes it very easy to adopt and very
easy to drop.

## Rollback, honestly

Two different things wear this name, and confusing them costs downtime.

**Redeploy the previous artifact.** The image from the last release is still in the registry, so
you point production back at that digest. Seconds. No build, no test run, no risk of pulling in
something new. This is the *fast* rollback, and during an incident it is the correct move.

**Revert the commit.** `git revert <sha>` creates a *new* commit that undoes the change, which
flows through review, CI and deployment like any other change. Minutes rather than seconds — and
it is the *auditable* rollback: history records that we shipped the change, and then that we
deliberately took it back, and the next person to deploy does not resurrect the bug by accident.

Mature setups do both, in that order: flip the digest to stop the bleeding, then revert the commit
so the repository stops disagreeing with production. If you only ever do the first, your next
deploy re-releases the bug. If you only ever do the second, your outage is as long as your
pipeline.

> :information_source:
> This is also why `git revert` and not `git reset` on a shared branch: reverting adds history,
> resetting rewrites it, and the branch everybody deploys from is the last place you want to
> rewrite. We argued this at length in
> [Keep a clean history, recover from mistakes](../2-collaborating/6-git-cleanup.md "Keep a clean history, recover from mistakes").

## Then databases arrive and spoil everything

Everything above assumes that deploying is replacing a stateless thing with another stateless
thing. Add a database and the tidy model breaks, because you cannot revert a migration the way you
revert a file.

The practices that survive contact with reality:

* **Forward-only migrations.** Do not write `down` migrations you never test — they lull you into
  thinking rollback exists. If a migration was wrong, the fix is another migration.
* **Expand and contract** (also called parallel change). To rename a column: add the new column
  and write to both (expand); migrate the readers; backfill; and only in a *later* release, once
  no deployed version reads the old column, drop it (contract). Three boring releases instead of
  one exciting one, and at every point in between, both the old and the new code work — which is
  precisely what makes rollback possible at all.
* **Separate the schema change from the code change.** A deploy that ships both at once can only
  be rolled back as a unit, which is to say: cannot.

And say the honest thing out loud: *"just revert it"* is a lie once state is involved. Reverting
the commit that added the migration does not un-add the column, does not restore the rows the
migration rewrote, and does not un-send the twelve thousand emails your new feature dispatched
before you noticed. A revert restores *code*. Nothing restores *consequences*.

## Deployment strategies, briefly

* **Blue/green.** Two identical environments; deploy to the idle one, test it, flip the load
  balancer. Rollback is flipping back. Expensive (two of everything) and wonderfully simple.
* **Rolling.** Replace instances a few at a time. What Kubernetes does by default. Cheap; requires
  that two versions can coexist for a few minutes, which brings us right back to expand/contract.
* **Canary.** Send 1% of traffic to the new version, watch, then 10%, then everything. The best
  bug-catcher of the three, because your real users test it and only a few of them suffer.
* **Feature flags.** Ship the code inert, switch the behaviour on later — for internal users
  first, then a percentage, then everybody.

That last one deserves the emphasis, because it is the one with a Git consequence: **feature flags
decouple deployment from release.** With a flag, merging to `main` no longer means "customers see
this", so there is no reason to keep a branch alive for three weeks waiting for a feature to be
finished. That is the missing piece that makes trunk-based development practical, and it is why
the branching-model discussion in
[A little structure please](../2-collaborating/4-git-repo-structure.md "A little structure please") ends up being a discussion about
flags. The cost is real, though: every flag is a fork in your code and a combinatorial explosion
in what "tested" means. Flags are debt with an interest rate — delete them once the feature is
unconditional.

## Progressive delivery and observability gates

The natural conclusion of canarying is to let the *monitoring* decide. The deployment controller
shifts a little traffic, watches your error rate, latency percentiles or SLO burn rate for a few
minutes, and either advances or rolls back automatically. Argo Rollouts and Flagger do exactly
this for Kubernetes, driving the analysis off Prometheus queries.

It is a lovely idea and it works, on one condition: your metrics must be good enough to bet a
release on. If nobody trusts the dashboard, an automated gate is just a slower deploy with extra
steps.

## Where the credentials live

Now the uncomfortable question. To deploy from CI, the CI system needs the power to change
production. Historically that meant a long-lived secret — an AWS access key, a `kubeconfig`, an SSH
key — pasted into the repository's CI variables, where it sat for three years, readable by every
workflow, including the one that runs a third-party action from a fork.

The modern answer is **OIDC federation**, and it is a genuine improvement rather than a fashion.
The CI platform acts as an OpenID Connect identity provider. Your workflow asks it for a
short-lived, cryptographically signed token that states verifiable facts: this token was issued to
repository `you/your-project`, for the workflow at `refs/tags/v1.2.3`, in environment
`production`. The cloud provider is configured to trust that issuer, to check those claims, and to
hand back credentials that expire in an hour.

What this buys you:

* **No long-lived secret exists.** There is nothing in your CI variables to steal, and nothing to
  rotate.
* **The trust is scoped to a ref.** You can allow deployment to production *only* from tags
  matching `v*`, enforced by the cloud provider, not by your YAML.
* **Every deployment is attributable** to a repository, a workflow and a commit, because those
  facts are inside the signed token.

In GitHub Actions it is two lines of permissions and one step:

```yaml
permissions:
  id-token: write     # allowed to request an OIDC token
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v6
    with:
      role-to-assume: arn:aws:iam::123456789012:role/deploy-production
      aws-region: eu-west-1
```

Notice how this follows directly from the push-versus-pull argument in
[GitOps](1-git-ops.md "GitOps"). We cannot make the production credential disappear in a push model —
something outside has to be able to reach in — but we *can* make it short-lived, narrowly scoped
and impossible to steal from a variables page. That is the best available answer for push-based
deployment, and it is why the GitOps crowd's security argument, while still true, is a good deal
less dramatic than it was in 2018.

## A worked example: tag, build, stamp, deploy

Putting the whole chapter together. Pushing `v1.2.3` builds one container image, tags it with both
the version *and* the commit SHA, and deploys it **by digest**.

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags: ['v*.*.*']

permissions:
  contents: read
  packages: write     # push to GitHub's container registry
  id-token: write     # OIDC, for the deploy job

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0        # we need tags for git describe

      - id: version
        run: echo "value=$(git describe --tags --always --dirty)" >> "$GITHUB_OUTPUT"

      - uses: docker/setup-buildx-action@v4

      - uses: docker/login-action@v4
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # Computes the image tags for us: the semver from the git tag, plus the SHA.
      - id: meta
        uses: docker/metadata-action@v6
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=semver,pattern={{version}}
            type=sha,format=long

      - id: build
        uses: docker/build-push-action@v7
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          build-args: |
            GIT_SHA=${{ github.sha }}
            VERSION=${{ steps.version.outputs.value }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production     # a required approval can hang off this
    steps:
      - uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: arn:aws:iam::123456789012:role/deploy-production
          aws-region: eu-west-1

      # Deploy the exact bytes we just built, by digest — never by a mutable tag.
      - run: |
          ./deploy.sh "ghcr.io/${{ github.repository }}@${{ needs.build.outputs.digest }}"
```

Three details carry the whole argument. `fetch-depth: 0`, or `git describe` lies. The image is
tagged with the version *and* the long SHA, so you can always get from a running container back to
a commit. And the deploy job consumes `needs.build.outputs.digest` — the immutable content address
of the image — rather than re-resolving `:v1.2.3`, which somebody could overwrite tomorrow.

> :warning:
> Action versions move. The majors above (`checkout@v7`, `setup-buildx-action@v4`,
> `login-action@v4`, `metadata-action@v6`, `build-push-action@v7`,
> `configure-aws-credentials@v6`) are current in mid-2026 — check, and pin third-party actions
> to a commit SHA rather than a tag, for the reason we gave in
> [Continuous integration](2-git-ci.md "Continuous integration with Git").

## And the other way round

Everything in this chapter is **push**: our CI reaches into production and changes it. Read it
next to [GitOps](1-git-ops.md "GitOps"), which is the same job done in reverse — a tag lands, an agent
inside the cluster notices, and it pulls the change in. The Git mechanics are identical, and it is
only the direction of the arrow, and therefore who holds the keys, that differs.

## Summary `git tag -a` `git push --follow-tags` `git describe` `git revert`

* **Continuous delivery** means every green commit is releasable; **continuous deployment** means
  it is actually released. Get to delivery first — it is pure upside.
* Deploy on push to a branch for staging; deploy on **tag** for anything a customer sees, because
  a tag is a deliberate, named, immutable decision.
* `git tag -a v1.2.3 -m '…'` then `git push --follow-tags`; CI triggers on `refs/tags/v*`.
  `--follow-tags` pushes annotated tags only.
* Prefer **promoting the artifact** (the same image digest through every environment) over
  environment branches or per-environment rebuilds. Rebuilding per environment is a
  reproducibility bug.
* Stamp `git describe --tags --always --dirty` and the full commit SHA into every artifact and
  expose it at `/version`. Shallow clones silently break this.
* Conventional Commits plus `semantic-release`, `release-please` or `changesets` compute the
  version bump, changelog and tag from commit messages since the last tag — at the cost of
  machine-readable commit subjects.
* Changelogs from history: `git log --pretty='* %s (%h)' v1.0.0..v1.1.0`, or `git-cliff`.
* Rollback: redeploying the previous artifact is the *fast* rollback, `git revert` is the
  *auditable* one. Do both, in that order.
* Databases break the model: forward-only migrations, expand/contract, and never believe that a
  revert undoes consequences.
* Blue/green, rolling, canary, and **feature flags** — which decouple deploy from release and are
  what make trunk-based development practical.
* Progressive delivery lets monitoring decide, with automated rollback on an SLO breach.
* Use **OIDC federation** (`id-token: write`) instead of long-lived cloud credentials in CI
  variables.
