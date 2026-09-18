# Style guide for this course

This is an internal document (not published content). Read it before writing any chapter.

## What this course is

A hands-on Git course, written originally in French and translated to English. It teaches Git
by *doing*, and — this is its distinguishing feature — by **always looking under the hood**.
The reader types a command, sees the real output, then we open `.git` and show them the objects
that just changed. The pedagogical bet is: "a little pain now for a lot of glory later".

The learner is assumed to be a beginner or intermediate developer with a terminal, on
macOS/Linux/WSL. They are *not* assumed to know systems programming, but they are treated as
intelligent adults who deserve the real explanation.

## Voice and tone — non-negotiable

* **First person plural.** "Let's type", "we will see", "our repository". The author and the
  reader are doing this together. Occasional first person singular for opinions and anecdotes
  ("As someone who recruits quite a few developers, ...").
* **Warm, playful, slightly irreverent.** "We're gonna take a peek into the monster's innards."
  "Is it a good time to panic? No. You should never panic." "Sometimes it's nice to get rid of
  the weight of the past."
* **Short paragraphs.** Two to four sentences. Lots of white space.
* **Honest about complexity.** When something is genuinely hard, say so, and say that we are
  deliberately simplifying: "This is the first time in this course where we are not going to
  tell you the whole truth." Never pretend Git is simpler than it is; never dump complexity on
  the reader without warning either.
* **Opinionated.** The course takes positions (use the command line; never rewrite shared
  history; always `git mv`; commit messages matter). State them as opinions, with the reason.
* **No corporate voice, no marketing, no vendor pitch.** No "leverage", no "seamlessly", no
  "in today's fast-paced world". If a product is named, it is named because it is genuinely
  the tool people use.

## Hard rules

1. **Never mention Platform.sh.** The author no longer works there. No `platform` CLI, no
   `ori@platform.sh` email, no platform.sh examples. Use `ori+git-training@pekelman.com` for the author
   identity in example output, or a neutral `you@example.com` in instructions.
2. **Every command must be real and correct.** If you write output, it must be what the
   command actually prints with a recent Git (2.40+). When in doubt, run it. There is a
   scenario harness in `utilities/` — use it.
3. **No invented SHAs that contradict each other.** Within a chapter, a given commit keeps a
   given SHA. If you must show hashes, either take them from a real run, or keep them
   consistent and say they will differ on the reader's machine.
4. **Vendor-neutral.** Where a hosted service is needed, prefer showing the concept plus two
   or three real options (GitHub, GitLab, Forgejo, Codeberg…). Do not turn a chapter into an
   advertisement for one.
5. **Don't over-claim about AI tooling.** In the agentic chapters, describe mechanics that are
   true of any coding agent. Name tools as examples, not endorsements, and mark fast-moving
   details as fast-moving.

## Mechanics

* Front matter is YAML: `title`, `slug`, `weight`. Do not change existing slugs — they are
  the published URLs.
* One `#` H1 at the top matching the title. Then `##` sections, `###` subsections. **Always
  put a space after the `#`** — the original has bugs like `##The working directory` that
  render as literal text.
* Code blocks: ```console for anything typed at a shell or its output; ```markdown, ```yaml,
  ```python etc. for file contents. Never leave a fence unclosed.
* Callouts use the existing convention, a blockquote starting with an emoji shortcode:
  * `> :information_source:` — a useful aside, a "by the way", a deeper explanation.
  * `> :warning:` — a trap, a footgun, something that will bite them.
  Put the marker on its own line or at the start of the first line, then the text. Do not
  invent new markers (the original has a couple of broken ones like `:example:` and
  `:info_source_:` — those are bugs, use the two above).
* Every chapter ends with a **summary section** listing the commands and concepts introduced,
  as a bullet list, in the style of:
  ```
  ## Summary `git rm` `git mv`

  * `git rm` allows us to remove files and directories
  * `git mv` allows us to rename files and directories
  ```
* Cross-reference other chapters with a relative markdown link to the file, e.g.
  `[Installing and configuring Git](P6C1.md "Installing and configuring Git")`.
* British/American spelling: the text is loosely American. Don't fuss.
* Length. Prose is wrapped one paragraph per line, and a chapter that shows real terminal
  output typically runs 40–45% code fences, so line counts are not a good proxy for reading
  time. In practice:
  * **Parts 1 and 2 are read in order**, so they should stay tight. Part 1 chapters run
    30–500 lines. If a Part 2 chapter passes ~800, ask whether a demonstration is carrying
    its weight, because the reader is still building the model and cannot skim yet.
  * **Parts 3 to 6 are reference.** The reader arrives from the menu with a question. Long is
    fine there; being incomplete is not.
  * Either way: do not pad, and never write a chapter that is only headings. If you cut,
    cut a whole demonstration rather than thinning the prose around it — half-explained
    output is worse than no output.

## Terminology

Bold the Git nouns on first and important use, as the original does: **commit**, **branch**,
**tree**, **blob**, **tag**, **remote**, **HEAD**, **index**, **staging**, **worktree**,
**SHA**, **commit-id**, **tree-id**, **detached head**, **fast-forward**.

## Current-as-of

Written/updated in 2026. Git 2.55 is current. Assume `git switch` / `git restore` exist and
are worth teaching alongside `git checkout` (teach `checkout` because that is what the world
still types, but tell the reader the modern split exists and why). Assume default branch may
be `main` (GitHub, GitLab) while `git init` still says `master` unless configured — explain
`init.defaultBranch`. Assume SHA-256 repositories exist but SHA-1 is still the default.
