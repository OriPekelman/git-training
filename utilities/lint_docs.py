#!/usr/bin/env python3
"""Lint the course content.

This course quotes hundreds of shell commands and was machine-translated from
French at some point in its life, which left a specific and recurring set of
scars: `git-status` for `git status`, `objects` translated to `items`, diff hunk
headers with periods instead of commas, headings missing the space after the
`#`, and callout markers that were invented on the spot and never rendered.

This script looks for exactly those, plus the structural things that break the
site (duplicate slugs, dangling chapter links, unbalanced code fences).

    utilities/lint_docs.py                 # lint content/docs
    utilities/lint_docs.py --links         # also check external URLs (slow)
    utilities/lint_docs.py path/to/file.md

Exit status is non-zero if there are errors. Warnings do not fail the run.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "content" / "docs"

# --------------------------------------------------------------------------
# Things we know about
# --------------------------------------------------------------------------

# The only two callout markers the course uses. Hugo turns these into ℹ️ and ⚠️
# when `enableEmoji` is on. Anything else was invented and renders as literal
# text on the page.
CALLOUTS = {"information_source", "warning"}

# Strings that must never appear again.
FORBIDDEN = [
    (re.compile(r"platform\.sh", re.I), "Platform.sh reference"),
    (re.compile(r"\bplatformsh\b", re.I), "Platform.sh reference"),
    (re.compile(r"openclassrooms", re.I), "OpenClassrooms reference"),
]

# `git-foo` tokens that are legitimate: real separate programs, hostnames,
# file names, or things the course deliberately introduces under that name.
GIT_HYPHEN_OK = {
    "git-lfs", "git-scm", "git-annex", "git-filter-repo", "git-town",
    "git-absorb", "git-bug", "git-cliff", "git-crypt", "git-sizer",
    "git-prompt", "git-completion", "git-secrets", "git-xet", "git-remote",
    # plumbing that really is invoked as a hyphenated program name, e.g. over
    # ssh or via --upload-pack/--receive-pack
    "git-receive-pack", "git-upload-pack", "git-upload-archive", "git-shell",
    "git-http-backend", "git-daemon",
    # the course's own helper scripts, in utilities/
    "git-object-read", "git-objects-print-all",
    # examples the course builds on purpose (custom subcommands live on PATH
    # as git-<name>)
    "git-chuck", "git-pulls", "git-pair", "git-foo", "git-ops", "git-ci",
    "git-cd", "git-ssh", "git-install", "git-guis", "git-ides", "git-tools",
    "git-hosting", "git-workflow", "git-cleanup", "git-notes", "git-data",
    "git-worktree", "git-static", "git-repo", "git-clone", "git-ecosystem",
}

# Extra tokens that follow `git ` in code blocks but are not subcommands.
NOT_SUBCOMMANDS = {
    "help", "config", "--version", "--help", "--list-cmds", "--work-tree",
    "--git-dir", "--no-pager", "--bare", "-c", "-C", "--exec-path",
}

# Chapters that deliberately have no summary section: the three narrative
# openers, and the grab-bag of tips, which is itself a summary and says so.
NO_SUMMARY_NEEDED = {"P1C1.md", "P1C2.md", "P1C3.md", "P5C5.md"}

HUNK_RE = re.compile(r"^@@ -\d+([.,]\d+)? \+\d+([.,]\d+)? @@")
BAD_HUNK_RE = re.compile(r"^@@ -\d+(\.\d+)? \+\d+(\.\d+)? @@")


def git_subcommands() -> set[str]:
    """Every subcommand the installed Git actually knows."""
    try:
        out = subprocess.run(
            ["git", "--list-cmds=main,others,nohelpers,alias,config"],
            capture_output=True, text=True, check=True,
        ).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        return set()
    return {line.strip() for line in out.splitlines() if line.strip()}


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.notes: list[str] = []

    def error(self, path: Path, line: int, msg: str) -> None:
        self.errors.append(f"{self._loc(path, line)}: error: {msg}")

    def warn(self, path: Path, line: int, msg: str) -> None:
        self.warnings.append(f"{self._loc(path, line)}: warning: {msg}")

    @staticmethod
    def _loc(path: Path, line: int) -> str:
        try:
            rel = path.relative_to(ROOT)
        except ValueError:
            rel = path
        return f"{rel}:{line}" if line else str(rel)


def parse_front_matter(lines: list[str]) -> tuple[dict[str, str], int]:
    """Return (fields, index of the line after the closing ---)."""
    if not lines or lines[0].strip() != "---":
        return {}, 0
    fields: dict[str, str] = {}
    for i, raw in enumerate(lines[1:], start=1):
        if raw.strip() == "---":
            return fields, i + 1
        if ":" in raw:
            key, _, value = raw.partition(":")
            fields[key.strip()] = value.strip().strip("\"'")
    return fields, 0


def lint_file(path: Path, rep: Report, subcommands: set[str], chapter_files: set[str]) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    fields, body_start = parse_front_matter(lines)
    if not fields:
        rep.error(path, 1, "missing YAML front matter")
    else:
        for required in ("title", "slug", "weight"):
            if required not in fields:
                rep.error(path, 1, f"front matter is missing `{required}`")
        if "weight" in fields and not fields["weight"].isdigit():
            rep.error(path, 1, f"weight is not a number: {fields['weight']!r}")

    in_fence = False
    fence_marker = ""
    fence_open_line = 0
    fence_lang = ""
    h1_count = 0

    for n, line in enumerate(lines[body_start:], start=body_start + 1):
        stripped = line.strip()

        # ---- code fences -------------------------------------------------
        fence = re.match(r"^\s*(`{3,}|~{3,})(.*)$", line)
        if fence:
            marker, rest = fence.group(1), fence.group(2).strip()
            if not in_fence:
                in_fence, fence_marker, fence_open_line = True, marker[:3], n
                fence_lang = rest
                if len(marker) > 3:
                    rep.warn(path, n, f"code fence opened with {len(marker)} backticks")
            elif marker[:3] == fence_marker:
                if len(marker) > 3:
                    rep.error(path, n, f"code fence closed with {len(marker)} backticks (should be 3)")
                in_fence = False
                fence_lang = ""
            continue

        # ---- forbidden strings (everywhere, prose and code) --------------
        for pattern, what in FORBIDDEN:
            if pattern.search(line):
                rep.error(path, n, f"{what}: {stripped[:90]}")

        # ---- inside code blocks ------------------------------------------
        if in_fence:
            if BAD_HUNK_RE.match(stripped) and not HUNK_RE.match(stripped):
                rep.error(path, n, "diff hunk header uses a period where a comma belongs "
                                   f"(translation artifact): {stripped[:60]}")
            if re.search(r"\bitems/[0-9a-f]{2}/", line) or re.search(r"^\s*[│|`+\\-]*\s*items\s*$", line):
                rep.error(path, n, "`.git/items` is a mistranslation of `.git/objects`")
            # a command line inside a console block
            m = re.match(r"^\s*(?:[\$>]\s+)?git\s+([a-zA-Z][\w-]*)", stripped)
            if m and fence_lang in ("console", "shell", "sh", "bash", ""):
                sub = m.group(1)
                if (sub not in subcommands and sub not in NOT_SUBCOMMANDS
                        and not sub.startswith("-")):
                    rep.error(path, n, f"`git {sub}` is not a Git subcommand")
            continue

        # An indented block is code too (the gitfoo chapter is written that
        # way), so `#!/bin/sh` in it is a shebang, not a broken heading.
        if line.startswith(("    ", "\t")):
            continue

        # ---- headings ----------------------------------------------------
        if line.startswith("#"):
            hashes = len(stripped) - len(stripped.lstrip("#"))
            if hashes <= 6 and not stripped[hashes:].startswith(" "):
                rep.error(path, n, f"heading is missing a space after `{'#' * hashes}`: "
                                   f"{stripped[:60]}")
            if hashes == 1:
                h1_count += 1

        # ---- callouts ----------------------------------------------------
        for marker in re.findall(r"^>\s*:([a-z_]+):", stripped):
            if marker not in CALLOUTS:
                rep.error(path, n, f"unknown callout marker `:{marker}:` "
                                   f"(use :information_source: or :warning:)")

        # ---- git-subcommand written with a hyphen ------------------------
        # `man git-check-ref-format` and `git help git-foo` are correct: man
        # pages really are named with the hyphen.
        for m in re.finditer(r"(man\s+|\bhelp\s+)?\b(git-[a-z][a-z0-9-]*)", line):
            if m.group(1):
                continue
            token = m.group(2).rstrip("-")
            if token in GIT_HYPHEN_OK:
                continue
            if token[4:] in subcommands:
                rep.error(path, n, f"`{token}` should be `git {token[4:]}`")

        # ---- chapter cross-links -----------------------------------------
        for target in re.findall(r"\]\((P\d+C\d+\.md)(?:\s+\"[^\"]*\")?\)", line):
            if target not in chapter_files:
                rep.error(path, n, f"link to a chapter that does not exist: {target}")

        # ---- French false friends and known translation scars ------------
        for pattern, msg in (
            (r"\brepertoire\b", "'repertoire' is a false friend for 'directory'"),
            (r"\bdeposit\b", "'deposit' is probably a mistranslation of 'dépôt' (repository)"),
            (r"\bnote commit\b", "'note commit' is probably 'our commit' (notre)"),
            (r"\bGithub\b", "spell it GitHub"),
            (r"\bGitlab\b", "spell it GitLab"),
            (r"\bgit hub\b", "spell it GitHub"),
        ):
            if re.search(pattern, line, re.I if "Git" not in pattern else 0):
                rep.warn(path, n, f"{msg}: {stripped[:70]}")

    if in_fence:
        rep.error(path, fence_open_line, "code fence is never closed")
    if h1_count == 0:
        rep.warn(path, 1, "chapter has no H1 heading")
    elif h1_count > 1:
        rep.warn(path, 1, f"chapter has {h1_count} H1 headings (expected 1)")

    # The convention is a closing section whose heading mentions "summary",
    # but the wording varies ("## Summary `git rm` `git mv`", "## `git init`,
    # `git add` and `git commit` summary"). A few chapters are exempt: the
    # narrative openers have nothing to summarise, and the tips chapter *is* a
    # summary.
    if (path.name not in NO_SUMMARY_NEEDED
            and not re.search(r"^#{2,3} .*summary", text, re.I | re.M)):
        rep.warn(path, 0, "chapter has no summary section")

    return fields


def check_links(paths: list[Path], rep: Report) -> None:
    import urllib.error
    import urllib.request

    seen: dict[str, bool] = {}
    for path in paths:
        for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for url in re.findall(r"https?://[^\s)\"'>\]]+", line):
                url = url.rstrip(".,;:")
                if url in seen:
                    ok = seen[url]
                else:
                    req = urllib.request.Request(
                        url, method="HEAD",
                        headers={"User-Agent": "git-training-linkcheck"},
                    )
                    try:
                        with urllib.request.urlopen(req, timeout=10) as resp:
                            ok = resp.status < 400
                    except urllib.error.HTTPError as exc:
                        ok = exc.code in (403, 405, 429)  # blocks HEAD, not dead
                    except Exception:
                        ok = False
                    seen[url] = ok
                if not ok:
                    rep.warn(path, n, f"dead or unreachable URL: {url}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="*", type=Path,
                    help="markdown files to lint (default: content/docs/*.md)")
    ap.add_argument("--links", action="store_true",
                    help="also check that external URLs resolve (slow, needs network)")
    ap.add_argument("--quiet", action="store_true", help="only print errors")
    args = ap.parse_args()

    paths = sorted(args.paths) if args.paths else sorted(DOCS.glob("P*.md"))
    if not paths:
        print("no files to lint", file=sys.stderr)
        return 1

    rep = Report()
    subcommands = git_subcommands()
    if not subcommands and not args.quiet:
        print("note: could not list Git subcommands; skipping that check")
    chapter_files = {p.name for p in DOCS.glob("*.md")}

    slugs: dict[str, list[str]] = defaultdict(list)
    weights: dict[str, list[str]] = defaultdict(list)

    for path in paths:
        fields = lint_file(path, rep, subcommands, chapter_files)
        if "slug" in fields:
            slugs[fields["slug"]].append(path.name)
        if "weight" in fields:
            weights[fields["weight"]].append(path.name)

    for slug, files in sorted(slugs.items()):
        if len(files) > 1:
            rep.errors.append(f"duplicate slug {slug!r} in {', '.join(files)}")
    for weight, files in sorted(weights.items(), key=lambda kv: int(kv[0])):
        if len(files) > 1:
            rep.errors.append(f"duplicate weight {weight} in {', '.join(files)}")

    if args.links:
        check_links(paths, rep)

    for line in rep.errors:
        print(line)
    if not args.quiet:
        for line in rep.warnings:
            print(line)

    # Only count authoring markers, i.e. TODO inside an HTML comment. The word
    # itself shows up legitimately in the content (a `TODO` file is used as an
    # example in several chapters).
    todo_re = re.compile(r"<!--[^>]*\b(TODO|FIXME)\b", re.I | re.S)
    todos = sum(len(todo_re.findall(p.read_text(encoding="utf-8"))) for p in paths)

    print()
    print(f"{len(paths)} chapters, {len(rep.errors)} errors, "
          f"{len(rep.warnings)} warnings, {todos} TODO markers")
    return 1 if rep.errors else 0


if __name__ == "__main__":
    sys.exit(main())
