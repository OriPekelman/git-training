# Git Getting Started!

A hands-on Git course that always looks under the hood. Built with [Hugo](https://gohugo.io)
and the vendored [hugo-book](https://github.com/alex-shpak/hugo-book) theme.

```
content/<lang>/_index.md
                       landing page; its table of contents is generated
content/<lang>/docs/<n>-<part>/_index.md
                       part section page, and the sidebar group header
content/<lang>/docs/<n>-<part>/<n>-<chapter>.md
                       the chapters, ordered by the `weight` in their front matter
utilities/             the tooling described below
STYLE.md               the binding style guide -- read it before writing a chapter
themes/hugo-book/      vendored theme (patched for Hugo 0.128+ deprecations)
```

One content tree per language: English is served from the root and French from
`/fr/`. Every tool below takes `--lang`, and defaults to every language present.

The leading numbers order the parts and chapters on disk and in the sidebar, and
are kept out of the published address by the `[permalinks]` patterns in
`hugo.toml`, so each chapter is served from a flat `/docs/<slug>/`. That has to
be done with permalinks rather than a `url` in front matter: Hugo does not add
the language prefix to an absolute front-matter `url`, so the French pages would
silently overwrite the English ones at the same path.

Chapters link to each other by relative markdown path
(`../6-appendices/1-git-install.md`), which works both when the file is read on a
forge and, via the theme's portable links, in the built site. `make build` fails
if one of them does not resolve.

## Working on it

```sh
make serve      # local preview with live reload on :1313
make lint       # check the content
make check      # everything CI runs
make help       # all targets
```

## Why there is tooling

The course quotes several hundred lines of real Git output, and it teaches by showing
what actually happens inside `.git`. That only works if the output is true. Two scripts
keep it honest:

**`utilities/scenario.sh`** replays the whole course scenario against the installed Git
and writes one transcript per step to `utilities/snippets/`. Identity, dates, timezone,
locale and config are all pinned, so the same Git version always produces byte-identical
output — including the commit hashes. The course is currently validated against Git 2.55. When Git changes a hint message or adds a sample
hook, this is how you find out:

```sh
make examples
git diff utilities/snippets     # exactly which quoted outputs went stale
make examples-check             # non-zero exit if they did (CI runs this)
```

**`utilities/lint_docs.py`** looks for the specific damage this course has accumulated.
It was machine-translated from French at one point, which left recurring scars: `git-status`
written with a hyphen, `.git/objects` translated to `.git/items`, diff hunk headers with
periods instead of commas, `##Headings` with no space, invented callout markers that never
rendered. It also checks the structural things that break the site — duplicate slugs or
weights, dangling chapter links, unbalanced code fences — and validates every `git <subcommand>`
in a code block against the installed Git.

```sh
make lint
make links      # also verify external URLs resolve (slow)
```

**`utilities/gen_toc.py`** rebuilds the landing page's table of contents from chapter front
matter, so renaming a chapter cannot silently desync it.

**`utilities/git-object-read`** and **`utilities/git-objects-print-all`** are the two helper
scripts the course itself uses to dump raw loose objects. Put them on your `PATH` and Git
picks them up as `git object-read` and `git objects-print-all`.

## Translations

The course was written in French first, but the 2026 revision was done in English, so
`content/en/` is the source of truth and `content/fr/` is translated from it. Both trees
are complete: 31 chapters each, and `utilities/lint_docs.py` checks them together.

A pre-2026 French version used to sit in a top-level `fr/` directory. It was the tone
reference for the translation -- the English is a fairly literal rendering *of* that
French, so restoring the original preserved the author's voice where a round trip would
have flattened it -- and it was deleted once the translation was finished. It is still in
the history if you ever want it:

```sh
git log --oneline -- fr/          # find the last commit that had it
git show <commit>:fr/P1C1.md      # read one file
git checkout <commit> -- fr/      # bring the whole thing back
```

Where the two disagreed, the rule was: the English revision's *corrections* win on facts,
and the original French wins on voice and on anything it uniquely had. The old text also
carried OpenClassrooms-era damage -- dropped leading letters in headings, dead links,
invented callout markers -- which was repaired rather than carried across.
