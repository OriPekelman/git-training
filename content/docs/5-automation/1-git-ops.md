---
title: GitOps
url: "/docs/git-ops/"
weight: 41
---
# GitOps

We have spent four parts of this course learning what Git actually is: a content-addressed
database of **commit**s, **tree**s and **blob**s, with a few movable references pointing into it.
We now know how to branch, merge, rebase, push, tag and recover. This last part is about what
happens when we point all of that at *machines* instead of at colleagues.

And the first idea we need is the one with the marketing name: **GitOps**.

## The idea, in one sentence

The Git repository holds the *desired state* of a system, and an automated agent continuously
makes reality look like it.

That is all. Read it twice, because everything else in this chapter is a consequence.

Notice what is *not* in that sentence. There is no "and then someone runs the deploy script".
There is no human in the loop at the moment of change. The human's job is to change the
repository — the agent's job is to notice, and to converge. If reality drifts away from the
repository, the agent pulls it back.

## The four principles

The word was coined in 2017 at Weaveworks — Alexis Richardson's post *GitOps — Operations by
Pull Request* is the origin story — and it was later given a proper, vendor-neutral definition
by the [OpenGitOps](https://opengitops.dev/) project, which lives in the GitOps Working Group of
the CNCF's App Delivery TAG. The current GitOps Principles are version 1.0.0, and they read:

1. **Declarative** — "A system managed by GitOps must have its desired state expressed
   declaratively."
2. **Versioned and Immutable** — "Desired state is stored in a way that enforces immutability,
   versioning and retains a complete version history."
3. **Pulled Automatically** — "Software agents automatically pull the desired state declarations
   from the source."
4. **Continuously Reconciled** — "Software agents continuously observe actual system state and
   attempt to apply the desired state."

> :information_source:
> Notice that the principles never say the word "Git". They say "a way that enforces
> immutability, versioning and retains a complete version history" — which is a description of
> Git written by people who did not want to name it. In practice, everybody uses Git.

## Why Git, in the vocabulary we already have

Here is the honest version of the pitch, in the words of this course.

A **commit** is an immutable record of *who* changed the desired state, *when*, and — if the
commit message is any good — *why*. It can be signed, so we can also prove it. A **tag** names a
release. A revert is a rollback. A pull request is a change-control process, complete with
review and approval, that we already have and already know how to use.

That is a remarkably good audit story for a production system, and we got it for free, because we
were going to use Git anyway.

So let us be a little irreverent: GitOps is mostly a rebranding of "keep your configuration in
version control and automate the apply". Sysadmins have been doing versions of this for thirty
years. Nothing in the four principles would have surprised anyone running Puppet in 2010.

But the rebranding was *useful*, and I say that as someone allergic to rebranding. It made two
things explicit that used to be accidents:

* the **pull** model — the machine fetches its own configuration, rather than a build server
  reaching in and pushing;
* the **reconciliation loop** — the apply is not an event that happened once on Tuesday, it is a
  loop that runs forever.

Those two ideas were worth a name.

## Push versus pull

In a **push** deployment, the CI system holds credentials for production and shoves the new state
in: `kubectl apply`, `ssh prod 'systemctl restart …'`, `aws s3 sync`, `terraform apply`.

In a **pull** deployment, something *inside* production watches the repository and applies what it
finds there. Nothing outside needs a key to the inside.

The security argument is the strong one, and it is worth stating bluntly. In the push model, your
CI runner is a machine that can deploy to production, that runs code from every branch anybody
pushes, that executes third-party plugins downloaded at run time, and whose logs half the company
can read. It is the juiciest target in your infrastructure. In the pull model there are no
production credentials in CI at all: something in the cluster has read access to a Git
repository, and that is the entire trust relationship.

The direction of the arrow is the point. Outbound reads from production are much easier to defend
than inbound writes to production.

> :information_source:
> Push is not evil, and we are going to spend the next three chapters happily pushing. For a
> small project a deploy key and a webhook are perfectly fine. But when someone asks "why would
> I run an agent instead of just calling `kubectl apply` from CI?", the answer is the paragraph
> above.

## Drift, and what "continuously reconciled" buys us

Three in the morning. The site is down. Someone runs `kubectl edit deployment/api` and bumps the
memory limit. The site comes back. Everyone goes back to bed.

The repository now says one thing and production says another. This is **drift**, and every
system that applies configuration only when a human asks it to will drift, silently, forever. Six
weeks later somebody deploys an unrelated change, the memory limit goes back to whatever the
repository always said it was, the site goes down again, and nobody understands why.

A reconciliation loop closes that hole. Every few minutes the agent compares desired state with
actual state, and then does one of two things:

* **Self-heal**: put it back. The 3 a.m. edit is undone within minutes, which is brutal but at
  least honest — the repository is the truth, and if you want the memory limit changed you change
  the repository.
* **Alert**: report the divergence and leave it alone.

Both are legitimate; Argo CD, for instance, lets you choose per application. My opinion: turn
self-healing on wherever you can, because a system that tolerates drift is a system that lies to
you. And make the emergency path a one-line commit rather than a `kubectl edit`, so that nobody
is punished for doing the right thing at 3 a.m.

## The tools that actually do this

**Kubernetes.** [Argo CD](https://argo-cd.readthedocs.io/) and [Flux](https://fluxcd.io/) are the
two grown-up implementations — both CNCF graduated projects, Flux in November 2022 and Argo a
week later in December 2022. Both run *inside* the cluster, watch one or more Git repositories,
and reconcile manifests. Argo CD leads with a UI and a strong "here is your application, here is
its sync status" model; Flux leads with a set of composable controllers and no UI to speak of.
Pick either. Do not run both.

**Infrastructure.** Terraform, or its fork [OpenTofu](https://opentofu.org/), with the plan
posted to the pull request. [Atlantis](https://www.runatlantis.io/) is the classic self-hosted way
to do that: it comments the `plan` on the PR and runs the `apply` when a reviewer comments back.
Terraform Cloud and its competitors sell the same shape as a service. Be aware that this one is
*not* a real reconciliation loop unless you also run drift detection on a schedule — plain
Terraform converges only when someone asks it to.

**Ansible**, pulled rather than pushed: `ansible-pull` clones a repository onto the managed host
and runs a playbook out of it, from cron. Old, unglamorous, and precisely the four principles.

**Nix and NixOS.** This is the under-appreciated GitOps story. A NixOS machine's entire
configuration — packages, services, kernel, users — is a declarative expression, and
`nixos-rebuild switch --flake github:you/config#myhost` reconciles the machine to the flake at
that commit, with `flake.lock` pinning every input to an exact hash. Declarative, versioned,
immutable, pulled. Nix's model is a cousin of Git's — see
[Things inspired by Git](../4-beyond-the-basics/6-inspired-by-git.md "Things inspired by Git") — and if you have ever wanted to
`git revert` an operating system, this is how you do it.

**Kubernetes operators** in general are reconciliation loops. GitOps is what you get when the
loop's input happens to live in a repository.

### GitOps for one small server

You do not need a cluster. Here is a complete, honest GitOps setup for a single machine, which
you could build this afternoon.

First a reconcile script that does nothing at all unless the upstream branch has actually moved:

```sh
#!/bin/sh
# /usr/local/bin/reconcile
set -eu

cd /srv/myapp
git fetch --quiet origin

if [ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ]; then
    exit 0                     # already in the desired state, nothing to do
fi

git merge --ff-only '@{u}'     # refuse anything that is not a fast-forward
make deploy
```

> :information_source:
> `@{u}` means "the upstream of the current branch" — usually `origin/main`. Worth knowing:
> `git rev-parse --abbrev-ref '@{u}'` tells you what yours is. And `--ff-only` is the entire
> safety model here: if history was rewritten upstream, the reconcile *fails* instead of
> silently doing something creative on a production machine.

Then a `systemd` timer to run it every five minutes:

```ini
# /etc/systemd/system/reconcile.service
[Unit]
Description=Reconcile /srv/myapp with its Git repository

[Service]
Type=oneshot
ExecStart=/usr/local/bin/reconcile
```

```ini
# /etc/systemd/system/reconcile.timer
[Unit]
Description=Reconcile every five minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

`systemctl enable --now reconcile.timer`, and we are done. That is a pull-based, continuously
reconciling deployment with a full audit trail, in about twenty lines, with no production
credentials stored anywhere off the machine. Anyone who tells you GitOps requires Kubernetes is
selling something.

## How to lay out the repositories

This is where teams argue, so here are the choices and what each one costs.

**One repository or two?** Application source in one repository, deployment configuration in
another, is the mainstream recommendation, and the reason is delightfully concrete. If CI builds
an image and then commits the new image tag into the *same* repository that triggered it, that
commit triggers CI, which builds an image, which commits a tag… congratulations, we have built a
machine that turns electricity into nothing.

Two ways out, and you generally want both:

* Put `[skip ci]` in the automated commit message. GitHub Actions honours `[skip ci]`,
  `[ci skip]`, `[no ci]`, `[skip actions]` and `[actions skip]` — but only for `push` and
  `pull_request` events, not for `pull_request_target`. GitLab honours `[skip ci]` as well.
* Use path filters, so that a change under `deploy/` never triggers the build job in the first
  place.

Separating the repositories makes the loop structurally impossible rather than merely
discouraged, which is why people do it.

**One repository per environment, or one directory per environment?** Directory-per-environment
(`envs/staging/`, `envs/production/`) is easier to diff and easier to promote: a promotion is a
commit that copies a version number from one directory to another, and you can *see* how staging
and production differ with one `git diff`. Repository-per-environment gives stricter access
control — only release managers can push to the production repository — at the price of never
being quite sure how the two differ. Start with directories.

**And the same manifest for three environments?** Do not paste it three times. Use overlays: a
Kustomize base plus per-environment patches, or one Helm chart plus three `values` files. The rule
of thumb is that the *difference* between environments should be a small, readable file, and
everything else should be shared.

## Secrets, the awkward part

You cannot commit plaintext secrets, and GitOps wants everything in the repository. That tension
is real, and anyone who glosses over it is not being straight with you. Four honest answers:

* **Sealed Secrets** — you encrypt a value with the public key of a controller running in the
  cluster; the resulting `SealedSecret` is safe to commit, and only that cluster can decrypt it.
  Simple, and cluster-bound by design.
* **SOPS with age or a cloud KMS** — encrypts only the *values* in a YAML file, leaving the keys
  and the structure readable, so a `git diff` still tells you something. Decryption happens at
  apply time; Flux integrates it directly.
* **External Secrets Operator** — commit only a *reference*: "the database password lives at this
  path in Vault". The operator fetches the real value and materialises the secret in the cluster.
  The secret never touches Git at all. This is the model that scales best across teams.
* **git-crypt** — transparent file encryption at the Git level, driven by `.gitattributes`.
  Charming, simple, and it does not solve key rotation.

> :warning:
> A secret committed once is committed forever. Rewriting history does not un-send the fetches
> that your colleague, your CI cache and three forks have already done. If a live credential
> lands in a repository, the *first* action is always to rotate the credential; cleaning up
> history is a distant second — see
> [Keep a clean history, recover from mistakes](../2-collaborating/6-git-cleanup.md "Keep a clean history, recover from mistakes").
> Catching it before it lands is what secret scanning in CI is for, and we will set that up in
> [Continuous integration](2-git-ci.md "Continuous integration with Git").

## What GitOps is bad at

I like GitOps. It is still not a theory of everything, and here is where it creaks.

**Ordered, multi-step operations.** Reconciliation describes a fixed point, not a procedure.
"Drain these nodes, migrate this data, then flip that flag" is a *sequence*, and expressing
sequences inside a declarative loop ranges from awkward (sync waves, hooks, phases) to actively
silly.

**State.** Manifests are cheap to converge because there is no data in them. Databases have data.
A schema migration is not a desired state that can be idempotently re-applied in both directions.

**Break-glass.** During an incident, the difference between `kubectl edit` and "open a PR, get an
approval, wait for the sync interval" is measured in minutes of downtime. Every mature GitOps
shop has an emergency path; the good ones make it *loud* — logged, alerted, and reconciled away
as soon as the matching commit lands.

**And `git revert` looks more like a rollback than it really is.** Reverting the commit that
bumped an image tag genuinely brings the old container back. It does not un-migrate the database,
un-send the emails, or un-charge the credit cards. Reverting a manifest rolls back
*configuration*, not *consequences*. We will come back to this in
[Continuous deployment](4-git-cd.md "Continuous deployment"), because it is the most over-promised
thing in this entire field.

## Summary `git rev-parse '@{u}'` `git merge --ff-only`

* **GitOps**: the Git repository is the single source of truth for desired state, and an agent
  continuously reconciles reality toward it.
* The four **GitOps Principles** (OpenGitOps v1.0.0) are declarative, versioned and immutable,
  pulled automatically, continuously reconciled. The term comes from Weaveworks in 2017.
* Git supplies the audit trail for free: a **commit** records who changed the desired state, when
  and why; a **tag** names a release; a revert is a rollback; a pull request is change control.
* **Push** deployment gives the CI system production credentials. **Pull** deployment does not.
  That is the strongest argument for the pull model.
* **Drift** is what happens when configuration is applied only on demand. Continuous
  reconciliation either self-heals it or alerts on it.
* The tools: **Argo CD** and **Flux** on Kubernetes, **Terraform/OpenTofu** with **Atlantis** for
  infrastructure, `ansible-pull`, **NixOS** from a flake — and a `systemd` timer running
  `git fetch` plus `make deploy` on one small server, which is a real GitOps setup.
* `git rev-parse '@{u}'` names the upstream of the current branch; `git merge --ff-only` is the
  catch that makes an automated pull refuse rewritten history.
* Separate the application repository from the configuration repository so CI cannot retrigger
  itself; if you cannot, use `[skip ci]` and path filters.
* Secrets never go in as plaintext: **Sealed Secrets**, **SOPS**, **External Secrets Operator**
  or **git-crypt** — and rotate first, clean history second.
* GitOps is weak at ordered migrations, at stateful changes and at emergencies, and a revert
  rolls back configuration rather than consequences.
