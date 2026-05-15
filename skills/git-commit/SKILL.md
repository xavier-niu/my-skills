---
name: git-commit
description: Use for commit-related git workflows, including creating, staging, reviewing, amending, or preparing git commits. Applies when the user asks to commit changes, run /commit, create signed-off commits, write commit messages, split changes into atomic commits, inspect git status/diff for commit planning, or use git add/git commit workflows.
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
4. **Verify** — `git show` the commit, then `git status` to confirm nothing
   important was left behind.

## Message Format

```
<subsystem>: <Title in imperative mood, no trailing period>

<Body explaining WHY (required), wrapped at 75 columns. Use blank lines
to separate additional paragraphs.>

Signed-off-by: ...   (added automatically by -s)
```

Hard rules:

- Subject ≤ 75 chars total (including the `subsystem: ` prefix). Shorten the
  title or pick a tighter subsystem rather than overflow.
- Imperative mood — "Add X", not "Added X" or "Adds X". Test: subject completes
  "If applied, this commit will ___".
- No period at end of subject.
- Blank line between subject and body.
- **Body lines wrap at ≤ 75 columns** — pass the message via a heredoc or
  multiple `-m` flags with newlines already in place. Do not rely on the
  terminal to wrap.
- **Body is required on every commit.** Even small changes get at least one
  sentence stating *why* the change was made.
- Multiple paragraphs are allowed; **separate paragraphs with a single blank
  line**. Do not put blank lines inside a paragraph.

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

Bad:
- `fixed stuff` / `wip` / `Changes`
- `Update file.js` — missing subsystem
- `feat: added new feature` — wrong format and past tense

## Reminders

- Never push to remote unless explicitly asked.
- Verify authorship and commit hash before amending.
- Match the project's existing style — consistency beats personal preference.
