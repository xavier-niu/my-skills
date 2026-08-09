---
name: git-commit
description: >-
  Always use this skill for git commit work. Trigger when the user asks to
  commit, git commit, commit my changes, make a commit, stage and commit, run
  /commit, create a signed-off commit, amend a commit, split commits, write or
  review a commit message, inspect git status/diff/log for commit planning, or
  use git add/git commit workflows.
allowed-tools:
  - Bash(git:*)
  - Read
  - Edit
---

# Git Commit Skill

Create atomic, signed-off commits with `{subsystem}: {Title}` messages.

## Process

1. **Inspect** — `git status`, `git diff --stat HEAD`, `git diff HEAD`, and
   `git log --oneline -20`. From the log, pick up the project's subsystem
   names, capitalization, and tone. For a large diff, map its semantic changes
   and inspect key hunks instead of judging complexity from line count alone.
2. **Group** — split unrelated changes across commits. Use `git add -p` when
   one file contains multiple logical changes. For mixed refactoring,
   dependency, or behavior changes, read
   [references/ATOMIC_COMMITS.md](references/ATOMIC_COMMITS.md).
3. **Draft** — explain the motivation and major mechanism. Include
   compatibility or operational impact when material. Keep the body concise,
   but let genuinely large or architecturally complex changes carry enough
   context to remain useful to a future maintainer. Read
   [references/COMMIT_FORMAT.md](references/COMMIT_FORMAT.md) when the message
   needs URLs, issue references, trailers, or multiple paragraphs.
4. **Commit** — always `git commit -s`. One logical change per commit.
   Before committing, check the literal message text for the two common
   failures: any handwritten line over 75 columns, and blank lines inserted
   between sentences that belong in the same paragraph.
5. **Verify** — compare the message with the diff for accurate semantic
   coverage, then run `git show` and `git status` to confirm nothing important
   was left behind. When a draft is vague, bundled, or difficult to format,
   check [references/COMMON_MISTAKES.md](references/COMMON_MISTAKES.md).

## Message Format

```
<subsystem>: <Title in imperative mood, no trailing period>

<Body explaining the motivation and major mechanism (required). Add
compatibility or operational impact when material. Wrap at 75 columns.>

Signed-off-by: ...   (added automatically by -s)
```

Hard rules:

- Subject ≤ 75 chars total (including the `subsystem: ` prefix). Shorten the
  title or pick a tighter subsystem rather than overflow.
- Imperative mood — "Add X", not "Added X" or "Adds X". Test: subject completes
  "If applied, this commit will ___".
- No period at end of subject.
- Blank line between subject and body.
- **No handwritten line may exceed 75 columns**: subject and body included.
  Count the literal message before committing; do not rely on the terminal,
  editor, or Git to wrap it after the fact.
- **Body is required on every commit.** Even small changes get at least one
  sentence stating *why* the change was made.
- Use no fixed body template or paragraph count. Keep it concise by default and
  expand it only when the change is genuinely large or architecturally complex.
- Judge message depth by semantic scope, not line count alone. Do not omit a
  major mechanism merely to make a large change sound simple.
- Include only architectural facts useful to a future maintainer. Do not
  enumerate files, functions, or every affected subsystem.
- Prefer a heredoc or message file when committing. If using `-m`, keep a
  whole paragraph in one body `-m` value. Do not use one `-m` per sentence,
  because Git inserts blank lines between separate `-m` values.
- Multiple paragraphs are allowed only for distinct topics; separate paragraphs
  with a single blank line. **Do not put a blank line between sentences in the
  same paragraph.**

## Subsystem

Prefer an existing prefix from recent history. Otherwise use the shortest
accurate name derived from the changed path or module. Examples: `auth`,
`docs`, `services`, `cuda-101`, `tcp-close-wait`.

This skill uses `{subsystem}:` prefixes, not Conventional Commit types
(`feat:`, `fix:`, etc.), unless the user explicitly asks for them. See
[references/conventional-commits.md](references/conventional-commits.md) if
they do.

## Reference precedence

The rules in this `SKILL.md` always override bundled references. In
particular, keep the `{subsystem}: {Title}` subject, the 75-character limit,
the required body, and the mandatory `Signed-off-by` trailer added by
`git commit -s`.

The three uppercase references adapt GitLab's `commit-messages` skill. They
add edge-case and review guidance without importing its conflicting no-prefix,
72-character, or optional-body defaults. Attribution and license terms are in
[`LICENSES/GitLab-commit-messages.txt`](LICENSES/GitLab-commit-messages.txt).

## Examples

Good:
- `cuda-101: Add SGEMM CMake sample`
- `auth: Fix null pointer in login handler`
- `docs: Update API examples`
- Body: `Prevent readers from observing mixed cache generations. Reuse the
  existing generation marker while rebuilding the index.`

Bad:
- `fixed stuff` / `wip` / `Changes`
- `Update file.js` — missing subsystem
- `feat: added new feature` — wrong format and past tense
- `Update several files and refactor functions` — implementation inventory,
  not motivation or mechanism.
- Body sentences separated by an empty line — creates fake paragraphs.
- Any subject or handwritten body line longer than 75 columns.

## Reminders

- Never push to remote unless explicitly asked.
- Verify authorship and commit hash before amending.
- Match the project's existing style — consistency beats personal preference.
