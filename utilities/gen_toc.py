#!/usr/bin/env python3
"""Regenerate the table of contents on the course landing page.

Chapter titles get rewritten as the course is edited, and a hand-maintained
table of contents drifts within a week. This reads the front matter of every
chapter under `content/docs/<part>-<name>/`, groups them by part, and rewrites
the block between the two marker comments in `content/_index.md`.

    utilities/gen_toc.py            # rewrite the block
    utilities/gen_toc.py --check    # fail if it would change (for CI)
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"

# Reassigned by main() from --lang; the site keeps one content tree per language.
DOCS = CONTENT / "en" / "docs"
INDEX = CONTENT / "en" / "_index.md"

BEGIN = "<!-- BEGIN GENERATED TOC (utilities/gen_toc.py) -->"
END = "<!-- END GENERATED TOC -->"

PART_DIR_RE = re.compile(r"^(\d+)-")
CHAPTER_RE = re.compile(r"^(\d+)-")


def front_matter(path: Path) -> dict[str, str]:
    fields: dict[str, str] = {}
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return fields
    for raw in lines[1:]:
        if raw.strip() == "---":
            break
        if ":" in raw:
            key, _, value = raw.partition(":")
            fields[key.strip()] = value.strip().strip("\"'")
    return fields


def part_heading(part_dir: Path) -> tuple[str, str]:
    """A part's heading and blurb, read from its `_index.md`.

    Taken from the section page rather than hardcoded here, so the landing page,
    the sidebar and the part page cannot disagree -- and so this works for any
    language without the part titles being translated in two places.
    """
    index = part_dir / "_index.md"
    if not index.exists():
        return part_dir.name, ""
    title = front_matter(index).get("title", part_dir.name)
    body = index.read_text(encoding="utf-8").split("---", 2)[-1]
    blurb = next(
        (ln.strip() for ln in body.splitlines()
         if ln.strip() and not ln.startswith("#")),
        "",
    )
    return title, blurb


def build() -> str:
    chapters: dict[int, list[tuple[int, str, str]]] = {}
    part_dirs: dict[int, str] = {}
    for path in sorted(DOCS.glob("*/[0-9]*.md")):
        part_m = PART_DIR_RE.match(path.parent.name)
        chapter_m = CHAPTER_RE.match(path.name)
        if not part_m or not chapter_m:
            continue
        part, chapter = int(part_m.group(1)), int(chapter_m.group(1))
        part_dirs[part] = path.parent.name
        fm = front_matter(path)
        title = fm.get("title", path.stem)
        weight = int(fm.get("weight", part * 10 + chapter))
        rel = f"{path.parent.name}/{path.name}"
        chapters.setdefault(part, []).append((weight, title, rel))

    out: list[str] = [BEGIN, ""]
    for part in sorted(chapters):
        heading, blurb = part_heading(DOCS / part_dirs[part])
        out.append(f"### {heading}")
        out.append("")
        if blurb:
            out.append(blurb)
            out.append("")
        for _, title, filename in sorted(chapters[part]):
            out.append(f"1. [{title}](docs/{filename})")
        out.append("")
    out.append(END)
    return "\n".join(out)


def main() -> int:
    global DOCS, INDEX

    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="exit non-zero if the landing page is out of date")
    ap.add_argument("--lang", default="all",
                    help="language tree to rebuild: a code like 'en', or "
                         "'all' (the default) for every language present")
    args = ap.parse_args()

    langs = ([d.name for d in sorted(CONTENT.iterdir())
              if d.is_dir() and (d / "docs").is_dir()]
             if args.lang == "all" else [args.lang])
    if not langs:
        print(f"no language trees found under {CONTENT}", file=sys.stderr)
        return 1

    status = 0
    for lang in langs:
        DOCS = CONTENT / lang / "docs"
        INDEX = CONTENT / lang / "_index.md"
        status |= run_one(args.check)
    return status


def run_one(check: bool) -> int:
    if not INDEX.exists():
        print(f"{INDEX} does not exist", file=sys.stderr)
        return 1

    text = INDEX.read_text(encoding="utf-8")
    if BEGIN not in text or END not in text:
        print(f"{INDEX} has no generated-TOC markers", file=sys.stderr)
        return 1

    head, _, rest = text.partition(BEGIN)
    _, _, tail = rest.partition(END)
    new = head + build() + tail

    rel = INDEX.relative_to(ROOT)
    if new == text:
        print(f"{rel}: table of contents is up to date")
        return 0
    if check:
        print(f"{rel}: table of contents is STALE; run utilities/gen_toc.py",
              file=sys.stderr)
        return 1
    INDEX.write_text(new, encoding="utf-8")
    print(f"{rel}: rewrote the table of contents")
    return 0


if __name__ == "__main__":
    sys.exit(main())
