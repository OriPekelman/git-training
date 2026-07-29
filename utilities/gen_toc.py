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
DOCS = ROOT / "content" / "docs"
INDEX = ROOT / "content" / "_index.md"

BEGIN = "<!-- BEGIN GENERATED TOC (utilities/gen_toc.py) -->"
END = "<!-- END GENERATED TOC -->"

# The part titles and blurbs are also the body of each part's `_index.md`, which
# this script does not own. Keep the two in step when editing either.
PARTS = {
    1: ("Understanding Git", "What Git is, and what actually happens inside `.git` when you save your work."),
    2: ("Collaborating", "Branches, remotes, merges, conflicts, and how to recover when it goes wrong."),
    3: ("The tooling ecosystem", "The command line, the forges, the GUIs and the editor integrations."),
    4: ("Beyond the basics", "Worktrees, agents, notes, large files, data and models — and the ideas Git spawned."),
    5: ("Git as the engine of automation", "GitOps, continuous integration, continuous deployment, and a bag of tricks."),
    6: ("Appendices", "Installing Git, SSH keys and signing, and setting up a hosting account."),
}

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


def build() -> str:
    chapters: dict[int, list[tuple[int, str, str]]] = {}
    for path in sorted(DOCS.glob("*/[0-9]*.md")):
        part_m = PART_DIR_RE.match(path.parent.name)
        chapter_m = CHAPTER_RE.match(path.name)
        if not part_m or not chapter_m:
            continue
        part, chapter = int(part_m.group(1)), int(chapter_m.group(1))
        fm = front_matter(path)
        title = fm.get("title", path.stem)
        weight = int(fm.get("weight", part * 10 + chapter))
        rel = f"{path.parent.name}/{path.name}"
        chapters.setdefault(part, []).append((weight, title, rel))

    out: list[str] = [BEGIN, ""]
    for part in sorted(chapters):
        name, blurb = PARTS.get(part, (f"Part {part}", ""))
        out.append(f"### Part {part} — {name}")
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
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="exit non-zero if the landing page is out of date")
    args = ap.parse_args()

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

    if new == text:
        print("landing page table of contents is up to date")
        return 0
    if args.check:
        print("landing page table of contents is STALE; run utilities/gen_toc.py",
              file=sys.stderr)
        return 1
    INDEX.write_text(new, encoding="utf-8")
    print(f"rewrote the table of contents in {INDEX.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
