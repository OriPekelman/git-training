# Git Getting Started!

A hands-on Git course that always looks under the hood. Built with [Hugo](https://gohugo.io)
and the vendored [hugo-book](https://github.com/alex-shpak/hugo-book) theme.

```
content/_index.md      landing page; its table of contents is generated
content/docs/P<part>C<chapter>.md
                       the chapters, ordered by the `weight` in their front matter
fr/                    the older French version, not yet updated from the English
utilities/             the tooling described below
STYLE.md               the binding style guide -- read it before writing a chapter
themes/hugo-book/      vendored theme (patched for Hugo 0.128+ deprecations)
```

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
output — including the commit hashes. When Git changes a hint message or adds a sample
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

The English content under `content/` is the source of truth. The French version in `fr/`
predates the current revision and has not been brought forward yet.
