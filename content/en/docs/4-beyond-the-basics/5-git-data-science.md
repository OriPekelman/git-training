---
title: Git for data and models
slug: "git-data-science"
weight: 35
---
# Git for data and models

Git was designed in 2005 to version the Linux kernel: text, written by humans, in lines, reviewed by other humans. A 4 GB checkpoint is none of those things. Neither is a Parquet file, and neither — as we shall see, painfully — is a Jupyter notebook.

And yet the data and ML world runs on Git, because there is nothing else that does what Git does. This chapter is about how that actually works in practice: what the community has built on top, what it got right, and where you are expected to know things nobody told you.

If you came here as a data person who was handed Git and told to figure it out, welcome. If you came here as a developer who has just joined a team of data people, also welcome — you are about to understand why their repository looks like that.

## What is different about data and model work

A normal software project is reproducible when you check out a commit. A data project is reproducible when you can pin **four** things:

1. **Code** — Git does this, beautifully. This is the easy one.
2. **Data** — Git does this badly, for all the reasons in [Big files, or how Git meets its limits](4-git-lfs.md "Big files, or how Git meets its limits").
3. **Environment** — the exact library versions. Git can hold the lockfile, but only if you make one.
4. **Configuration and randomness** — hyperparameters, the random seed, the shuffle order, the GPU's non-determinism.

Miss any one of the four and "it worked yesterday" becomes a mystery. The whole ecosystem of tools we are about to look at exists because Git natively versions only the first, and everybody wants the *commit* to be the thing that pins all four.

So keep this in your head as the target: **one commit should identify one run, completely.** Everything below is a technique for getting closer to that.

## Jupyter notebooks in Git

Let's start with the daily pain, because this is what actually makes people hate Git.

A `.ipynb` file is JSON. It contains your code, and it also contains every output cell, every execution count, and every rendered image as a base64 blob. Let me measure a genuinely tiny notebook: three cells, one histogram.

```console
wc -c analysis.ipynb
   17591 analysis.ipynb
```

Seventeen kilobytes for eleven lines of code. Where did it go? Adding up the `outputs[].data["image/png"]` entries: **15360 bytes, 87% of the file**, is one PNG encoded in base64 on one enormous line.

Now watch what happens when I re-run the notebook without changing a single character of code:

```console
jupyter execute --inplace analysis.ipynb
git diff --stat

 analysis.ipynb | 28 ++++++++++++++--------------
 1 file changed, 14 insertions(+), 14 deletions(-)
```

Fourteen lines changed. One of those lines is fifteen kilobytes of base64. The others are `execution_count` going from 1 to 1, and `iopub.execute_input` timestamps. Nothing happened, and Git dutifully recorded a fifteen-kilobyte change.

Multiply by two people on two branches and you have a merge conflict inside a base64 string, which is roughly as much fun as it sounds.

### Fix one: strip the outputs with a clean filter

You already know exactly how this works, from the LFS chapter: a `clean` filter runs on `git add` and can rewrite the content on its way into the object database. `nbstripout` is that filter.

```console
pip install nbstripout      # or: uv add --dev nbstripout
nbstripout --install
```

And look what it wrote into `.git/config`:

```ini
[filter "nbstripout"]
	clean = "…/python3" -m nbstripout
	smudge = cat
	required = true
[diff "ipynb"]
	textconv = "…/python3" -m nbstripout -t
```

A `clean` that strips outputs, a `smudge` that is literally `cat` (there is nothing to put back — the outputs are *gone*, on purpose), and a `textconv` so that `git diff` compares stripped versions and shows you only real changes.

> :warning:
> By default `nbstripout --install` writes its patterns to **`.git/info/attributes`**, which is local and not shared. Your colleagues get none of this. Use `nbstripout --install --attributes .gitattributes` so the configuration is committed, exactly as we insisted for LFS:
> ```console
> *.ipynb filter=nbstripout
> *.zpln filter=nbstripout
> *.ipynb diff=ipynb
> ```
> (The `filter` still has to be defined locally — `.gitattributes` says *which* filter, never *what* it does. Put the install step in your project's setup script.)

The effect, measured:

```console
wc -c analysis.ipynb
   17620 analysis.ipynb
git cat-file -s $(git rev-parse HEAD:analysis.ipynb)
1120
git diff --stat            # ← nothing. Not one line.
```

The working file is 17.6 KB, the blob Git stored is **1120 bytes**, and after a fresh run the diff is *empty* — the clean filter produced byte-identical output, so there is genuinely nothing to commit. (`git status` may briefly still show ` M`; that is Git's stat cache being lazy, and `git add` settles it.)

### Fix two: pair with jupytext

The other approach is more radical and, in my opinion, better: decide that the notebook is not the artifact. The *script* is.

```console
jupytext --set-formats ipynb,py:percent analysis.ipynb
jupytext --sync analysis.ipynb
ls -l analysis.ipynb analysis.py

-rw-r--r--  1 you  staff  18277 analysis.ipynb
-rw-r--r--  1 you  staff    462 analysis.py
```

Eighteen kilobytes versus four hundred and sixty-two bytes, and the `.py` is a real Python file with a small YAML header in comments and `# %%` cell markers:

```python
# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
# ---

# %%
rng = np.random.default_rng()
x = rng.normal(size=2000)
print("mean:", x.mean())
```

Commit the `.py`, `.gitignore` the `.ipynb`. Now `git diff` is readable, `git blame` works, code review works, and merges are ordinary text merges. Editing either side and running `jupytext --sync` propagates the change.

### Fix three: teach Git to diff notebooks

If you genuinely need the outputs in the repository — and sometimes you do, for a report that must show the numbers it was built from — at least get a tool that understands the format. `nbdime config-git --enable --global` registers real drivers and the matching attributes:

```ini
[diff "jupyternotebook"]
	command = git-nbdiffdriver diff
[merge "jupyternotebook"]
	driver = git-nbmergedriver merge %O %A %B %L %P
```

Then `git diff` shows cell-by-cell changes instead of JSON, `nbdiff-web` gives a side-by-side view, and `nbmerge` can genuinely resolve conflicts that live in different cells.

### And the boring fix that matters most

Move the code out of the notebook. A notebook is a wonderful place to explore and a terrible place to keep a function that three notebooks need. Put the functions in `src/yourproject/`, `import` them, and let the notebook be twenty lines of narrative. Your diffs shrink, your tests become possible, and the notebook stops being the thing everyone is afraid to touch.

My opinion, stated as an opinion: **strip outputs by default, or pair with jupytext.** Committing outputs should be a deliberate decision you can defend, not something that happens to you because nobody configured anything.

## Datasets

Now the harder half. Here are the real options, with honest tradeoffs.

**Small reference data straight into Git.** A 200 KB lookup table, a fixtures file, a country-code CSV. Put it in the repo. It diffs, it reviews, it merges. Do not over-engineer this. My rough line is: text, under a megabyte or two, changes rarely, and a human would want to read the diff.

**Git LFS.** Covered in the previous chapter. Fine for a handful of medium binaries that change occasionally. Poor for a dataset with thousands of files, because every one becomes a pointer blob and a separate transfer.

**DVC.** Purpose-built for this (and, since late 2025, owned by the lakeFS people), and the model will feel familiar:

```console
dvc init
dvc add data/train.bin
cat data/train.bin.dvc

outs:
- md5: 5caeac5adb0115b0c4c8b4289caf1be4
  size: 10485760
  hash: md5
  path: train.bin
```

That is a pointer file. Same idea as an LFS pointer, but it is an ordinary tracked file with an ordinary name rather than a filter-managed impostor, which honestly makes it easier to reason about. DVC also writes the real path into a `.gitignore` for you:

```console
cat data/.gitignore
/train.bin
```

The bytes go to `.dvc/cache/files/md5/5c/aeac5adb0115b0c4c8b4289caf1be4` — content-addressed, same trick as everything else in this course — and from there to a remote:

```console
dvc remote add -d store s3://my-bucket/dvcstore     # or gs://, azure://, ssh://, or a path
dvc push
```

Then Git holds 44 KB for a 10 MiB dataset, and a colleague does `git clone && dvc pull`. The remote is *your* object storage: no vendor quota, no metered bandwidth, no per-file limits.

**git-annex.** Older, more general, harder. For "this file lives on that NAS and also on that USB disk and I want Git to know which", it is the tool that does that.

**lakeFS, Delta Lake, Iceberg.** A completely different answer: don't version the data in your repo, version it *where it lives*. lakeFS gives you Git-like branches, commits and tags over an object store, addressed as `lakefs://repo/ref/path`. Delta Lake and Iceberg keep a transaction log of immutable snapshots, so you can read a table as it was (`VERSION AS OF` / `TIMESTAMP AS OF` in Delta, a snapshot id in Iceberg). If your data is a warehouse table rather than a file, this is the correct answer and DVC is the wrong one.

**Object storage plus a committed manifest.** The underrated option. No new tool at all:

```console
(cd data && shasum -a 256 *.bin) > data.sha256
echo 'data/' >> .gitignore
git add data.sha256 && git commit -m "Pin the dataset by content hash"
cat data.sha256

6a8d56768a17512034163d1f15daf49705de190e4a59ef39fd85891d3e014ec3  a.bin
91d64d2f072a6f16889ced835b0031251bea9db17fcad6e614a76d916c312c81  b.bin
```

And the whole point of it — after one byte of `a.bin` is corrupted:

```console
(cd data && shasum -a 256 -c ../data.sha256)
a.bin: FAILED
b.bin: OK
shasum: WARNING: 1 computed checksum did NOT match
```

Exit code 1, so your `make data` refuses to continue. That is ninety-five percent of what any of these tools buys you, for four lines of shell and no dependencies.

> :information_source:
> Whichever you choose, the invariant that matters is the same: **the commit must pin an immutable content hash of the data.** Not a URL to a mutable bucket path, not "the latest export", not a date. A hash. If your `git checkout` of last March's commit can silently get this March's data, you do not have reproducibility, you have a coincidence.

## Hugging Face

Now the part the ML world actually lives in, and there is a lovely surprise waiting.

### The Hub is literally Git

Not "Git-like". Git. Every model, dataset and Space on the Hub is a Git repository you can clone with the Git you already have.

```console
git clone https://huggingface.co/hf-internal-testing/tiny-random-gpt2
cd tiny-random-gpt2
git log --oneline
71034c5 Update weights (#4)
```

And the very first thing to look at, because we spent a whole chapter on it:

```console
cat .gitattributes

*.bin.* filter=lfs diff=lfs merge=lfs -text
*.bin filter=lfs diff=lfs merge=lfs -text
*.h5 filter=lfs diff=lfs merge=lfs -text
*.onnx filter=lfs diff=lfs merge=lfs -text
*.pt filter=lfs diff=lfs merge=lfs -text
*.pth filter=lfs diff=lfs merge=lfs -text
*tfevents* filter=lfs diff=lfs merge=lfs -text
model.safetensors filter=lfs diff=lfs merge=lfs -text
{…and about ten more, .tflite, .msgpack, .arrow, .joblib…}
```

The Hub ships a generous LFS `.gitattributes` in every new repository, which is why nobody on Hugging Face ever accidentally commits a raw checkpoint. (This particular repo is a few years old and lists `model.safetensors` by name; newer templates use `*.safetensors`. The list drifts — accept whatever the Hub gives you.) And the payoff:

```console
git count-objects -vH | grep size-pack
size-pack: 13.41 KiB
```

**Thirteen kilobytes**, against 11.9 MiB sitting in `.git/lfs`. That is the entire Git history of a model repository. The weights are LFS objects, exactly as we dissected in the previous chapter:

```console
git show HEAD:model.safetensors
version https://git-lfs.github.com/spec/v1
oid sha256:8111d5afb0715dbf5a31396d31432cb56370ba23f6650a035ea0fc8a20b4e500
size 453864
```

Everything you learned about branches, tags, commits and `git log` applies to models. A model has a history. You can `git diff` its `config.json`. You can tag a release. Pull requests exist (the Hub calls them discussions, and they live under `refs/pr/`). This is genuinely one of the better design decisions in the ML ecosystem.

### Authentication

```console
hf auth login       # opens a browser, or paste a token from settings/tokens
hf auth whoami
hf auth list        # you can store several and hf auth switch between them
```

Everything also reads the `HF_TOKEN` environment variable, which is what you want in CI. `HF_HOME` relocates the whole cache and token store — handy for containers, and for keeping experiments isolated.

> :warning:
> The `huggingface-cli` command was renamed to `hf`. On the version I have here (`huggingface_hub` 1.25.1) running the old name gives you `Warning: huggingface-cli is deprecated and no longer works. Use hf instead.` — it is a stub, not an alias. Older 0.x installs still have the working `huggingface-cli`. Fast-moving surface: run `hf --help` rather than trusting a tutorial, mine included.

For `git push` to the Hub over https, the token is your password, and `hf auth login` will offer to install it as a Git credential helper. SSH works too, with a key registered in your Hub settings.

### `hf download` versus `git clone`, and why

You *can* clone a model repo. Usually you should not, and the reason is worth understanding rather than memorising.

Here is the same tiny model fetched both ways. First the clone we made above, adding up every file:

```console
  whole clone: 23.87 MiB
  .git:        11.94 MiB   (.git/objects: 0.01 MiB, .git/lfs: 11.90 MiB)
  working tree:
    model.safetensors            0.43 MiB
    pytorch_model.bin            3.40 MiB
    tf_model.h5                  8.07 MiB
    {…configs and tokenizer files…}
```

Then `hf download`, asking for only what a PyTorch program actually needs:

```console
hf download hf-internal-testing/tiny-random-gpt2 \
  --include "*.safetensors" "config.json" "tokenizer*" --revision 71034c5

hf cache list
id                                          size    refs
model/hf-internal-testing/tiny-random-gpt2  472.4K  ['71034c5']
```

23.87 MiB against 472 KiB. Fifty times. And the reasons are all mechanical:

* **`git clone` takes the whole repository.** This model ships PyTorch *and* TensorFlow *and* safetensors weights — three copies of the same parameters. You wanted one. `--include`/`allow_patterns` fetches one.
* **Two copies on disk.** A clone leaves the bytes in `.git/lfs` *and* in the working tree. 11.9 MiB each.
* **No sharing between projects.** Ten projects using the same base model means ten clones. The Hub cache is one shared, content-addressed store.
* **Transfers are better.** Resumable, parallel, chunked, and Xet-aware (below). `git-lfs` is fine; this is better.

The Python API is the same thing:

```python
from huggingface_hub import snapshot_download

path = snapshot_download(
    repo_id="hf-internal-testing/tiny-random-gpt2",
    revision="71034c5d8bde858ff824298bdedc65515b97d2b9",   # pin it!
    allow_patterns=["*.safetensors", "config.json", "tokenizer*"],
)
```

`hf_hub_download` does one file. Both return a path into the cache, so nothing is copied. (`hf cache list` is the 1.x spelling; on 0.x it is `hf cache scan`. There is also `hf cache rm` and `hf cache prune`, which you will want the first time your `~/.cache/huggingface` hits fifty gigabytes. It will.)

### The cache, and a lovely detail

```console
$HF_HOME/hub/models--hf-internal-testing--tiny-random-gpt2/
├── blobs/
│   ├── 4ff64fe5192d88c0b5dbfc578c775c0ce05dd7d0
│   └── 8111d5afb0715dbf5a31396d31432cb56370ba23f6650a035ea0fc8a20b4e500
├── refs/
│   └── 71034c5
└── snapshots/
    └── 71034c5d8bde858ff824298bdedc65515b97d2b9/
        ├── config.json        -> ../../blobs/4ff64fe5192d88c0b5…
        └── model.safetensors  -> ../../blobs/8111d5afb0715dbf5a…
```

`blobs/` holds content, `snapshots/<revision>/` holds a directory of **symlinks** with human names. Two revisions that share a file share one blob. If that structure looks familiar, it should — it is `.git/objects` plus a tree, rebuilt in a different language.

Now look closely at those two blob names. One is 40 hex characters, one is 64. Let's check the short one against the clone:

```console
git rev-parse HEAD:config.json
4ff64fe5192d88c0b5dbfc578c775c0ce05dd7d0
```

That is Git's own SHA-1 **blob** id. And the 64-character one is the LFS `oid sha256:` from the pointer we printed above. So the Hub cache names small files by their *Git blob hash* and large files by their *LFS hash*, because those are the identifiers the Hub already serves as ETags. Nobody documents this clearly; it falls straight out of the object model you learned in Part 1.

> :warning:
> Symlinks are the whole efficiency story here, so on filesystems without them (some Windows setups, some Docker volume mounts) `huggingface_hub` falls back to copying and warns. `HF_HUB_DISABLE_SYMLINKS_WARNING=1` silences the warning; it does not give you the disk back.

### Pin the revision, always

```python
AutoModel.from_pretrained("some-org/some-model", revision="a1b2c3d")
```

`main` is a moving target. Model authors force-push, re-quantize, "fix the tokenizer", and your evaluation numbers change three weeks later for no reason you can find. A commit **SHA** is immutable; a tag is nearly so. Pin the SHA in anything you will want to explain later, and record it in the run's metadata.

This is the single highest-value habit in this chapter. It costs nothing and it saves entire afternoons.

### From LFS to Xet

LFS deduplicates whole files: change one byte in a 5 GB checkpoint and you upload 5 GB, because the SHA-256 changed and that is the only unit LFS knows.

**Xet** is Hugging Face's replacement, and the idea is genuinely good. Instead of hashing the file, it cuts the file into chunks at boundaries chosen by the *content* itself — a rolling hash over a sliding window, and you cut where the hash hits a pattern. This is called **content-defined chunking**, and its magic property is that inserting bytes at the start of a file does not shift every subsequent boundary: the chunks after the insertion are identical to before. Compare with fixed-size blocks, where inserting one byte changes every block.

Chunks are then hashed, deduplicated globally, and grouped into larger blocks for transfer. Consequences:

* A fine-tune that perturbs a fraction of the weights uploads a fraction of the bytes.
* Two quantizations of the same model share whatever they share, automatically.
* Everyone downloading the same base model hits the same chunk cache.

You can watch both worlds coexisting in the Hub's own metadata. Asking the `paths-info` API about one file returns:

```json
{
  "oid": "cdebb9016e0099550c661ad5d7b4b0db174d2da7",
  "size": 453864,
  "lfs": { "oid": "8111d5afb…", "size": 453864, "pointerSize": 131 },
  "xetHash": "f8accece953fd366d4ce30597b97acc1ccedc3c785187a5ef6ecb4a8e1755122"
}
```

A Git blob oid, an LFS oid *and* a Xet hash for the same file. That is the migration made visible: the Git-visible pointer stays an LFS pointer, so plain `git clone` keeps working, while `hf`-based transfers go over Xet. On my machine `hf-xet` arrived automatically as a dependency of `huggingface_hub`, and downloads created a `$HF_HOME/xet/` chunk cache — so for the Python and CLI paths, Xet is simply on.

There is also a `git-xet` Git extension that plugs into LFS as a custom transfer agent if you want plain `git push` to go over Xet. This whole area is moving quickly: treat the state of the rollout as something to check, not something to memorise.

### Pushing a model or a dataset

```console
hf repos create my-cool-model --type model          # or --type dataset / --type space
hf upload my-cool-model ./out .                     # folder -> repo root, one commit
hf upload my-cool-model ./out/model.safetensors     # or a single file
```

From Python, `create_repo()` and `upload_folder()`, or the `push_to_hub()` method that `transformers`, `datasets` and friends put on their objects. Under the hood these are Hub commits — the same commits `git log` shows you.

What belongs in the repo:

* `config.json`, `tokenizer.json`, `preprocessor_config.json` — the small text files that make the weights usable. These diff nicely. Read their diffs.
* The weights, as `.safetensors`.
* `.gitattributes` — accept the one the Hub gives you.
* `README.md` **with YAML front matter**: this is the model card, and the front matter is structured metadata the Hub indexes. A real one:

```yaml
---
language: en
tags:
- exbert
license: apache-2.0
datasets:
- bookcorpus
- wikipedia
---
```

Other common keys are `library_name`, `pipeline_tag`, `base_model`, `metrics`, and for datasets `configs` and `dataset_info`. Fill them in: they are how anyone finds your work, and `license` in particular is not optional politeness.

What does not belong: training logs, checkpoints from every epoch, your `.env`, the raw dataset if the dataset has its own repo, and eleven quantizations nobody asked for.

Repos can be **private**, or **gated** (public metadata, access on request or after accepting terms) — useful for licensed data.

And Spaces: a Space is a Git repo that **redeploys when you push to it.** That is not a metaphor for GitOps, that is GitOps — the deployed state is a function of a commit. Worth reading alongside [GitOps](../5-automation/1-git-ops.md "GitOps").

### The two things that will actually hurt you

> :warning:
> **Never commit a token.** Not in a notebook cell, not in `config.py`, not in the `.ipynb` output where you printed it for debugging (remember, outputs are committed unless you stripped them). Once pushed, it is in history forever and rotating it is the only real fix. Use `HF_TOKEN`, use Space secrets, use your CI's secret store. A pre-commit hook that greps for `hf_[A-Za-z0-9]{34}` costs five minutes.

> :warning:
> **Model weights can execute code.** A `.bin` PyTorch checkpoint is a Python **pickle**, and unpickling runs arbitrary code by design. "Downloading a model" and "running a stranger's program" have historically been the same act. This is a real supply-chain problem, not a theoretical one — malicious models have been found on public hubs.
>
> The answers, in order of usefulness. Prefer **`.safetensors`**: an 8-byte length, a JSON header of shapes and offsets, then raw bytes — no code path at all, and it memory-maps, so it loads faster too. Keep PyTorch current: `torch.load` defaults to `weights_only=True` from PyTorch 2.6 onward (only when you do not pass `pickle_module`, and older versions do not). And read the Hub's scan results, which are real and public:
>
> ```json
> "pickleImportScan": {"status": "safe", "pickleImports": [
>   {"module": "collections", "name": "OrderedDict",       "safety": "innocuous"},
>   {"module": "torch",       "name": "ByteStorage",       "safety": "innocuous"},
>   {"module": "torch",       "name": "FloatStorage",      "safety": "innocuous"},
>   {"module": "torch._utils","name": "_rebuild_tensor_v2","safety": "innocuous"}]}
> ```
>
> That is genuine output from the Hub API for a `pytorch_model.bin`, produced by walking the pickle's opcodes without executing them. A pickle importing `os` or `subprocess` is not innocuous, and the Hub will say so — alongside a virus scan and two third-party scanners.
>
> But do not mistake scanning for safety. Hugging Face says so itself, and researchers have published checkpoints crafted to slip past the scanners (broken opcode streams, unexpected archive formats). "Pickle gets scanned" is a mitigation. "The format cannot execute code" is a property. Prefer the property.

## Experiment tracking and pipelines

### DVC pipelines: make, for data

`dvc.yaml` declares stages with dependencies, parameters and outputs. It is `make` with content hashing instead of timestamps, which is exactly the difference that matters.

```console
dvc stage add -n train -d train.py -d data/train.bin \
  -p train.seed,train.epochs -M metrics.json python train.py
cat dvc.yaml

stages:
  train:
    cmd: python train.py
    deps:
    - data/train.bin
    - train.py
    params:
    - train.epochs
    - train.seed
    metrics:
    - metrics.json:
        cache: false
```

Then `dvc repro`. The interesting output is `dvc.lock`, which you commit, and which records the hash of every input:

```yaml
stages:
  train:
    cmd: python train.py
    deps:
    - path: data/train.bin
      md5: 5caeac5adb0115b0c4c8b4289caf1be4
      size: 10485760
    - path: train.py
      md5: 56aeeb9b179df3ee66de5878110a5477
    params:
      params.yaml:
        train.epochs: 3
        train.seed: 42
```

Run it again and nothing happens:

```console
dvc repro
'data/train.bin.dvc' didn't change, skipping
Stage 'train' didn't change, skipping
Data and pipelines are up to date.
```

Change `seed: 42` to `seed: 7` in `params.yaml` and only the affected stage re-runs. Now the commit that contains `dvc.lock` pins code, data *and* configuration. That is three of our four.

### Log runs elsewhere, key them by commit

MLflow, Weights & Biases, Aim, plain JSON files in a bucket — the tool matters much less than the discipline, which is: **every run records the commit it came from.**

```console
printf '{"commit": "%s", "dirty": %s, "when": "%s"}\n' \
  "$(git rev-parse HEAD)" \
  "$([ -n "$(git status --porcelain)" ] && echo true || echo false)" \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

{"commit": "b4b269ae8f5eee76d16a414c3a8ef13ac22547d0", "dirty": true, "when": "2026-07-29T21:30:00Z"}
```

Note the `dirty` flag, and take it seriously. A run from a dirty tree is not reproducible, and knowing that six months later is the difference between "we can rebuild this" and "we cannot". Either refuse to run dirty, or record it loudly.

> :information_source:
> `git describe --always --dirty` is the tidier version, but be aware it only considers **tracked** modifications — an untracked file that your training script happily imports will not make it say `-dirty`. `git status --porcelain` sees untracked files too, which is why I use it above.

You can also attach provenance to the commit itself with [git notes](3-git-notes.md "git notes") — a note on the commit saying "run 4471, accuracy 0.913" is a genuinely nice fit for the feature, with all the caveats about notes not being pushed by default.

## Environment pinning

Short section, because there is only one rule: **the lockfile is part of the source.**

* Python: `uv.lock` (what I use — `uv sync` is reproducible and fast), `poetry.lock`, `requirements.txt` generated with `--generate-hashes`, `conda-lock`. Commit them. Commit the one that your CI actually installs from.
* CUDA and drivers are part of the environment too, and no lockfile will save you. Write down what you ran on.
* Containers: pin by **digest**, not by tag. `pytorch/pytorch:2.5.1-cuda12.1-cudnn9-runtime` can be rebuilt under you; `pytorch/pytorch@sha256:…` cannot. The `@sha256:` form is the only immutable reference, and it is the same idea as pinning a Hub revision or a dataset hash. By now you should be noticing a pattern.

## A worked example, end to end

Here is the whole thing assembled into one shape you can copy. Be clear about what this is: every *mechanism* below was run and measured for this chapter — the notebook filters, `dvc add`/`repro`/`push` against a local remote, the provenance stamp — but I did not run this exact script end to end, and steps marked NOT RUN need a Hub account and a token. So no invented output here; read it as the recipe it is.

```console
# 1. the repo: code in Git, environment locked, notebooks stripped
git init sentiment && cd sentiment
uv init --python 3.12 && uv add transformers safetensors && uv add --dev jupytext nbstripout
nbstripout --install --attributes .gitattributes
git add -A && git commit -m "Project skeleton, uv lock, notebook filters"

# 2. the dataset, pinned by hash and kept out of Git
dvc init && dvc remote add -d store s3://my-bucket/dvcstore
dvc add data/reviews.parquet
git add data/reviews.parquet.dvc data/.gitignore .dvc/config
git commit -m "Track reviews.parquet with DVC" && dvc push

# 3. the pipeline: code + data + params, all hashed into dvc.lock
dvc stage add -n train -d src/sentiment/train.py -d data/reviews.parquet \
  -p train.seed,train.epochs -o out/model.safetensors -M metrics.json \
  python -m sentiment.train
dvc repro
git add dvc.yaml dvc.lock params.yaml metrics.json && git commit -m "Train stage"

# 4. stamp the run with its provenance (commit + dirty flag + metrics)
python -c 'import json,subprocess as sp; \
 h=sp.check_output(["git","rev-parse","HEAD"],text=True).strip(); \
 d=bool(sp.check_output(["git","status","--porcelain"],text=True).strip()); \
 json.dump({"commit":h,"dirty":d}|json.load(open("metrics.json")),open("out/run.json","w"))'

# 5. publish  (NOT RUN HERE — needs a Hub token)
hf auth login
hf repos create sentiment-distilbert --type model
hf upload sentiment-distilbert ./out .
hf repos tag create sentiment-distilbert v1.0
```

And the consumer side, which is the part that has to still work in a year:

```python
from huggingface_hub import snapshot_download

path = snapshot_download(
    "you/sentiment-distilbert",
    revision="v1.0",                       # or better, the commit SHA
    allow_patterns=["*.safetensors", "config.json", "tokenizer*"],
)
```

Four things pinned: code by the Git commit, data by the DVC hash in `dvc.lock`, environment by `uv.lock`, configuration by `params.yaml` — which is itself hashed into `dvc.lock`. One commit, one run, one answer.

## Summary versioning data, models and notebooks

* Reproducibility needs **four** things pinned: code, data, environment, configuration. Git natively does the first; everything here is about making one commit pin all four.
* `.ipynb` is JSON containing outputs and base64 images — measured, 87% of a tiny notebook was one PNG, and re-running with no code change produced a 15 KB diff.
* `nbstripout --install --attributes .gitattributes` installs a **clean filter** that strips outputs (17.6 KB working file → a 1120-byte blob). Without `--attributes` it writes to `.git/info/attributes`, which your colleagues never see. `jupytext --set-formats ipynb,py:percent` pairs a notebook with a real `.py` (18277 → 462 bytes) — commit the `.py`, ignore the `.ipynb`. `nbdime config-git --enable` gives real notebook diff and merge drivers.
* Datasets: small text straight into Git; LFS for a few binaries; **DVC** (`dvc add` writes a `.dvc` pointer, `dvc push` sends bytes to your own storage); git-annex for exotic topologies; lakeFS/Delta/Iceberg when the data is a table; **object storage plus a checksummed manifest** when you want no new dependencies. The invariant: the commit must pin an immutable content hash.
* The Hugging Face Hub **is Git**. `git clone https://huggingface.co/org/model` works, and the whole history of a model repo can be 13 KiB of packfile because the weights are LFS objects.
* `hf auth login`, `HF_TOKEN`, `HF_HOME`. `huggingface-cli` was renamed to `hf`, and in `huggingface_hub` 1.x the old name no longer works at all. Prefer `hf download` / `snapshot_download(allow_patterns=…)` to `git clone`: measured 472 KiB versus 23.87 MiB for the same model, because a clone takes every framework's weights and keeps two copies.
* The Hub cache is content-addressed with symlinked snapshots, and names small files by their **Git blob SHA-1** and large files by their **LFS SHA-256**.
* Always pass `revision=` — a commit **SHA** or a tag. `main` moves.
* **Xet** replaces LFS with content-defined chunking and chunk-level dedup, so a fine-tune uploads only what changed. Files carry both an `lfs.oid` and a `xetHash` during the migration.
* Publishing: `hf repos create`, `hf upload`, `push_to_hub()`. Ship `config.json`, tokenizer files, `.safetensors`, `.gitattributes`, and a `README.md` with YAML front matter. Spaces redeploy on push, which makes them a real GitOps example.
* Never commit a token. Prefer `.safetensors` over pickle-based `.bin`, because unpickling runs code — and read, without over-trusting, the Hub's `pickleImportScan` results.
* `dvc.yaml` + `dvc repro` + `dvc.lock` is make-with-hashes. Log every run with `git rev-parse HEAD` **and** a dirty-tree flag from `git status --porcelain`. Commit your lockfile (`uv.lock`, `poetry.lock`, `conda-lock`), and pin containers by `@sha256:` digest, never by tag.
