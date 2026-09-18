#!/usr/bin/env bash
#
# scenario.sh -- regenerate the command transcripts used in the course.
#
# The course quotes a lot of real Git output. That output changes when Git
# changes (hint text gets reworded, `git init` gains a warning, the sample
# hooks list grows a file). This script replays the course's scenario against
# whatever Git is installed and writes one file per labelled step under
# `utilities/snippets/`, so that:
#
#   make examples
#   git diff utilities/snippets
#
# tells you exactly which quoted outputs in the course have gone stale.
#
#   make examples-check
#
# fails if regenerating would change anything, which is what CI should run.
#
# Everything is pinned -- identity, dates, config, locale, timezone -- so the
# same Git version always produces byte-identical output, including the SHAs.
#
# Usage:
#   utilities/scenario.sh            # regenerate snippets
#   utilities/scenario.sh --check    # fail if snippets would change
#   utilities/scenario.sh --keep     # leave the scratch repo behind to poke at
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
SNIPPETS="$HERE/snippets"
SCRATCH="$HERE/scratch"
REPO="$SCRATCH/my_first_git_project"

CHECK=0
KEEP=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK=1 ;;
        --keep)  KEEP=1 ;;
        -h|--help) sed -n '2,28p' "$0"; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

# ---------------------------------------------------------------------------
# Determinism
# ---------------------------------------------------------------------------
# A commit-id is a hash of the tree, the parents, the author and committer
# names, their emails AND the timestamps. Pin all of them and the SHAs quoted
# in the course are reproducible on any machine running the same Git version.
export GIT_AUTHOR_NAME="Ori Pekelman"
export GIT_AUTHOR_EMAIL="ori+git-training@pekelman.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

# Never read the machine's real configuration: it would leak the operator's
# aliases, default branch, pager and signing key into the course's output.
export GIT_CONFIG_GLOBAL="$SCRATCH/gitconfig"
export GIT_CONFIG_SYSTEM=/dev/null
export GIT_PAGER=cat
export PAGER=cat
export GIT_TERMINAL_PROMPT=0
export LC_ALL=C
export TZ=Europe/Paris
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE 2>/dev/null || true

# The scratch area lives inside this repository, so without a ceiling Git would
# walk up out of it and report on the *course's own* repository -- which makes the
# "this is not a git repository" step silently wrong and makes the output depend
# on whatever the operator happens to have edited.
export GIT_CEILING_DIRECTORIES="$SCRATCH"

# The commit timestamps are given explicitly, not derived, because a commit-id is
# a hash of its timestamp too: change one of these and every hash quoted in the
# chapters from that commit onward becomes wrong. They spell out a plausible
# early morning's work on 2 February 2026, in Europe/Paris.
#
#   at 06:10:30   ->   GIT_AUTHOR_DATE = GIT_COMMITTER_DATE = that instant
#
at() {
    local t
    # Seconds since the epoch for 2026-02-02T<arg>+01:00. Computed by hand so the
    # script does not depend on GNU vs BSD `date` parsing.
    case "$1" in
        06:06:51) t=1770008811 ;;   # Added readme.md
        06:10:30) t=1770009030 ;;   # Add the list of commands we learned today.
        06:15:42) t=1770009342 ;;   # Adding a license file
        06:17:22) t=1770009442 ;;   # Add .gitkeep
        06:22:10) t=1770009730 ;;   # Add git log to the list of commands
        06:25:44) t=1770009944 ;;   # Remove license file
        06:31:09) t=1770010269 ;;   # Rename files to media
        06:40:12) t=1770010812 ;;   # Add git log to the list (after the reset)
        06:41:30) t=1770010890 ;;   # Add media directory with .gitkeep
        06:46:00) t=1770011160 ;;   # Initial shopping cart code
        06:49:30) t=1770011370 ;;   # Implement shopping cart template
        06:53:00) t=1770011580 ;;   # Merge branch 'shopping_cart'
        06:55:20) t=1770011720 ;;   # Add a title file, one way
        06:57:40) t=1770011860 ;;   # Add a title file, the other way
        *) echo "at: no epoch known for '$1' -- add it to the table" >&2; exit 2 ;;
    esac
    export GIT_AUTHOR_DATE="$t +0100"
    export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"
}
at 06:06:51

# ---------------------------------------------------------------------------
# Snapshot helpers
# ---------------------------------------------------------------------------
CURRENT_LABEL="00-unlabelled"

label() {  # label <name> -- start a new snippet file
    CURRENT_LABEL="$1"
    : > "$SNIPPETS/$CURRENT_LABEL.txt"
}

# run <command...> -- echo the command as the reader would type it, then run it
# and capture stdout+stderr. Absolute paths are rewritten so the snippet does
# not embed the operator's home directory.
run() {
    local out rc
    printf '$ %s\n' "$*" >> "$SNIPPETS/$CURRENT_LABEL.txt"
    set +e
    out="$( "$@" 2>&1 )"
    rc=$?
    set -e
    printf '%s\n' "$out" \
        | sed -e "s|$REPO|~/projects/my_first_git_project|g" \
              -e "s|$SCRATCH|~/projects|g" \
              -e "s|$HOME|~|g" \
        >> "$SNIPPETS/$CURRENT_LABEL.txt"
    [ $rc -ne 0 ] && printf '# (exit status %d)\n' "$rc" >> "$SNIPPETS/$CURRENT_LABEL.txt"
    return 0
}

note() { printf '# %s\n' "$*" >> "$SNIPPETS/$CURRENT_LABEL.txt"; }

# `tree` is not installed everywhere; fall back to ls. LC_ALL=C is pinned above
# so that Git speaks English, but it also makes tree draw the box characters in
# ASCII, so ask for UTF-8 explicitly to match what the reader sees.
showtree() {
    if command -v tree > /dev/null 2>&1; then run tree --charset=UTF-8 --noreport "$@"
    else run ls -lRa "$@"; fi
}

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
if [ "$CHECK" = 1 ]; then
    PREVIOUS="$(mktemp -d)"
    [ -d "$SNIPPETS" ] && cp -R "$SNIPPETS/." "$PREVIOUS/" 2>/dev/null || true
fi

rm -rf "$SCRATCH"
mkdir -p "$SCRATCH" "$SNIPPETS"
# Deliberately does NOT set init.defaultBranch: P1C3 quotes the hint that Git
# prints when it is unset, so suppressing it here would make that chapter stale.
cat > "$GIT_CONFIG_GLOBAL" <<'EOF'
[core]
	pager = cat
EOF

echo "Replaying the course scenario with $(git --version)"
label 00-git-version
run git --version


# ---------------------------------------------------------------------------
# P1C3 -- a directory that is not yet a repository
# ---------------------------------------------------------------------------
mkdir -p "$REPO"
cd "$REPO"

label p1c3-not-a-repo
run git status

label p1c3-git-init
note "no init.defaultBranch is set, so Git prints its hint -- P1C3 quotes it"
run git init

# ---------------------------------------------------------------------------
# P1C4 -- add and commit
# ---------------------------------------------------------------------------
label p1c4-fresh-git-dir
showtree .git

printf '# My first Git project\n' > readme.md

label p1c4-status-untracked
run git status

label p1c4-add
run git add readme.md
run git status
run git ls-files -s

label p1c4-objects-after-add
showtree .git/objects
note "one blob: readme.md, addressed by the hash of its content"
run git cat-file --batch-check --batch-all-objects

at 06:06:51
label p1c4-first-commit
run git commit -m "Added readme.md"
run git status
C1="$(git rev-parse HEAD)"

cat > readme.md <<'EOF'
# My first Git project

Today we learned the following Git commands:

1. `git init` - initialize a new git repository
2. `git status` - find out the status of the working directory relative to the git repository
3. `git add` - add files to the git index to prepare for a commit
4. `git commit -m"{commit message}"` - save a milestone in the git repository
EOF

label p1c4-status-modified
run git status

at 06:10:30
label p1c4-second-commit
run git add readme.md
run git commit -m "Add the list of commands we learned today."
C2="$(git rev-parse HEAD)"

# This heredoc must stay byte-identical to the one printed in P1C4, or the
# LICENSE blob hash changes and every commit hash from here on diverges from
# what the chapters quote.
cat > LICENSE <<'EOF'
Git Example by Ori Pekelman

To the extent possible under law, the person who associated CC0 with
Git Example has waived all copyright and related or neighboring rights
to Git Example.

You should have received a copy of the CC0 legalcode along with this
work. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
EOF

at 06:15:42
label p1c4-third-commit
run git add LICENSE
run git commit -m "Adding a license file"
C3="$(git rev-parse HEAD)"

label p1c4-all-objects
showtree .git/objects
run git cat-file --batch-check --batch-all-objects

# ---------------------------------------------------------------------------
# P1C5 -- inside the objects
# ---------------------------------------------------------------------------
label p1c5-cat-file-commit
run git cat-file -t "$C2"
note "the raw commit object: tree, parent, author, committer, message"
run git cat-file -p "$C2"
run git show "$C2"
run git show --stat "$C2"

label p1c5-ls-tree
note "the tree of the third commit"
run git show "$C3^{tree}"
run git ls-tree "$C3^{tree}"
note "the two versions of readme.md, and LICENSE, as blobs"
run git rev-parse "$C1:readme.md"
run git rev-parse "$C2:readme.md"
run git rev-parse "$C3:LICENSE"

label p1c5-empty-dir-ignored
run mkdir files
run git status

at 06:17:22
label p1c5-gitkeep
run touch files/.gitkeep
run git add files/.gitkeep
run git commit -m "Add .gitkeep so files will be added to the repository"
C4="$(git rev-parse HEAD)"
run git ls-tree "$C4^{tree}"
run git ls-tree "$C4:files"
note "an empty blob always hashes to e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"
run git hash-object -t blob /dev/null
showtree .git/objects

label p1c5-log-four
run git log
run git log --oneline

# A pristine copy at this point, so the `git rm` and plain-`mv` demonstrations
# below do not disturb the narrative history.
cp -a "$REPO" "$SCRATCH/snapshot_c4"

# ---------------------------------------------------------------------------
# P1C6 -- modify, delete, rename
# ---------------------------------------------------------------------------
label p1c6-rm-by-hand
run rm LICENSE
run git status

at 06:22:10
label p1c6-rm-committed
run git add LICENSE
run git commit -m "Remove license file"
C5="$(git rev-parse HEAD)"

label p1c6-git-rm
note "the same thing done in one step, on an untouched copy of the repository"
cd "$SCRATCH/snapshot_c4"
run git rm LICENSE
run git status
cd "$REPO"

at 06:25:44
label p1c6-git-mv
run git mv files media
run git status
run git commit -m "Rename files to media"
C6="$(git rev-parse HEAD)"

label p1c6-mv-by-hand
note "renaming with the shell instead, which Git cannot recognise as a rename"
cd "$SCRATCH/snapshot_c4"
run git reset --hard
run mv files media
run git status
cd "$REPO"

# ---------------------------------------------------------------------------
# P1C7 -- reading and rewriting history
# ---------------------------------------------------------------------------
label p1c7-log-six
run git log

printf '\n5. `git log` view all revisions\n' >> readme.md
at 06:31:09
label p1c7-seventh-commit
run git commit -am "added git log command"
C7="$(git rev-parse HEAD)"
run git log -1
run git log --oneline
run cat readme.md

label p1c7-diff
run git diff HEAD~1
run git diff "$C5" "$C7"

label p1c7-blame
run git blame readme.md

label p1c7-show
run git show "$C7"

label p1c7-detached-head
run git checkout "$C6"
run cat readme.md
run git log --oneline
note "git log shows only the past of where we are; --branches shows the rest"
run git log --oneline --branches
run git status
run git checkout master

label p1c7-refs-under-the-hood
run cat .git/HEAD
run cat .git/refs/heads/master
run git rev-parse HEAD
run git for-each-ref

label p1c7-graph-before-reset
run git log --graph --pretty=format:'%h - (%ad) %s - %an%d' --date=short

label p1c7-reset
run git reset "$C2"
run git status
run git log --oneline

at 06:40:12
run git add readme.md
run git commit -m "Add git log to the list of commands we learned"
at 06:41:30
run git add media
run git commit -m "Add media directory with .gitkeep"

label p1c7-graph-after-reset
note "a clean four-commit history; the abandoned commits are still in the reflog"
run git log --graph --pretty=format:'%h - (%ad) %s - %an%d' --date=short

label p1c7-reflog
run git reflog

# ---------------------------------------------------------------------------
# P2C1 -- branches
# ---------------------------------------------------------------------------
label p2c1-create-branch
run git checkout -b shopping_cart
run cat .git/HEAD
showtree .git/refs
run git branch -vv

mkdir -p lib
printf '// shopping cart\n' > lib/shopping_cart.js
at 06:46:00
label p2c1-branch-commit
note "-a would not pick this up: lib/shopping_cart.js is still untracked"
run git commit -am "Initial shopping cart code"
run git add lib
run git commit -m "Initial shopping cart code"

label p2c1-sub-branch
run git checkout -b shopping_cart_template
mkdir -p views
cat > views/shopping_cart.html <<'EOF'
<html>
<head>
<title>Shopping cart template</title>
</head>
<body>
I am a template
</body>
</html>
EOF
at 06:49:30
run git add views
run git commit -m "Implement shopping cart template"

label p2c1-branch-list
run git checkout master
run git checkout -b homepage
note "four branch names, each pointing at exactly one commit"
run git branch -vv

label p2c1-fast-forward-merge
run git checkout shopping_cart
run git status
run git log -1
run git merge shopping_cart_template
showtree .
run git log --oneline --graph --decorate --all

# ---------------------------------------------------------------------------
# P2C5 -- a real merge commit, and a real conflict
# ---------------------------------------------------------------------------
run git checkout master
at 06:53:00
label p2c5-real-merge
run git merge --no-ff shopping_cart -m "Merge branch 'shopping_cart'"
note "a merge commit has two parent lines"
run git cat-file -p HEAD
run git merge-base master shopping_cart
run git log --oneline --graph --decorate --all

label p2c5-conflict
run git switch -c conflicting master
printf '# The title, one way\n' > title.md
at 06:55:20
run git add title.md
run git commit -q -m "Add a title file, one way"
run git switch master
printf '# The title, the other way\n' > title.md
at 06:57:40
run git add title.md
run git commit -q -m "Add a title file, the other way"
run git merge conflicting
run git status
note "the index holds up to three stages while a conflict is unresolved"
run git ls-files -u
run cat title.md
run git merge --abort
run git branch -D conflicting

# ---------------------------------------------------------------------------
# P4C1 -- worktrees
# ---------------------------------------------------------------------------
label p4c1-worktree
run git worktree add ../hotfix -b hotfix/urgent
run git worktree list
note "in a linked worktree, .git is a file, not a directory"
run cat ../hotfix/.git
showtree .git/worktrees
note "you cannot check out the same branch in two worktrees"
run git worktree add ../nope master
run git worktree remove ../hotfix
run git branch -D hotfix/urgent

# ---------------------------------------------------------------------------
# P4C3 -- notes
# ---------------------------------------------------------------------------
label p4c3-notes
run git notes add -m "Reviewed by nobody in particular" HEAD
run git log -1
run git rev-parse refs/notes/commits
note "the notes ref is an ordinary commit whose tree is keyed by object id"
run git cat-file -p refs/notes/commits
run git ls-tree refs/notes/commits

# ---------------------------------------------------------------------------
# Wrap up
# ---------------------------------------------------------------------------
label 99-final-state
run git log --oneline --graph --decorate --all
run git count-objects -vH

cd "$ROOT"
[ "$KEEP" = 0 ] && rm -rf "$SCRATCH"

if [ "$CHECK" = 1 ]; then
    if diff -rq "$PREVIOUS" "$SNIPPETS" > /dev/null 2>&1; then
        rm -rf "$PREVIOUS"
        echo "OK: snippets are up to date for $(git --version)"
    else
        echo "STALE: regenerating the snippets changed them." >&2
        diff -ru "$PREVIOUS" "$SNIPPETS" >&2 || true
        rm -rf "$PREVIOUS"
        exit 1
    fi
else
    echo "Wrote $(ls -1 "$SNIPPETS" | wc -l | tr -d ' ') snippets to utilities/snippets/"
    echo "Review what changed with: git diff utilities/snippets"
fi
