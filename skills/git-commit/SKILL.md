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

1. **Inspect** — `git status`, `git diff HEAD`, `git log --oneline -20`. From
   the log, pick up the project's subsystem names, capitalization, and tone.
2. **Group** — split unrelated changes across commits. Use `git add -p` when
   one file contains multiple logical changes.
3. **Commit** — always `git commit -s`. One logical change per commit.
   Before committing, check the literal message text for the two common
   failures: any handwritten line over 75 columns, and blank lines inserted
   between sentences that belong in the same paragraph.
4. **Verify** — `git show` the commit, then `git status` to confirm nothing
   important was left behind.

## Message Format

```
<subsystem>: <Title in imperative mood, no trailing period>

<Body explaining WHY (required), wrapped at 75 columns. Keep related
sentences in one paragraph; use blank lines only between paragraphs.>

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

## Examples

Good:
- `cuda-101: Add SGEMM CMake sample`
- `auth: Fix null pointer in login handler`
- `docs: Update API examples`
- Body: `Keep adjacent sentences together in one wrapped paragraph. Add a
  blank line only when starting a distinct paragraph.`

Bad:
- `fixed stuff` / `wip` / `Changes`
- `Update file.js` — missing subsystem
- `feat: added new feature` — wrong format and past tense
- Body sentences separated by an empty line — creates fake paragraphs.
- Any subject or handwritten body line longer than 75 columns.

## Reminders

- Never push to remote unless explicitly asked.
- Verify authorship and commit hash before amending.
- Match the project's existing style — consistency beats personal preference.
