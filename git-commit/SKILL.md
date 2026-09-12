---
name: git-commit
description: >-
  Create atomic, signed-off Git commits. Use for staging, committing,
  amending, splitting commits, or drafting and reviewing commit messages.
allowed-tools:
  - Bash(git:*)
  - Read
  - Edit
---

# Git Commit Skill

Create atomic, signed-off commits with `{subsystem}: {Title}` messages.

## Workflow

Inspect the working tree, staged changes, and enough recent history to
understand the change and choose a subsystem. Scale inspection to semantic
scope; a large line count alone does not imply a complex change.

Group changes by motivation, keeping each commit independently useful and
reversible. Use `git add -p` for mixed changes within a file. Preserve unrelated
user changes and check `git diff --cached` against the intended commit.

Draft the message using the rules below, then always run `git commit -s`.
Check the literal message before committing; terminal wrapping does not count.
Verify the resulting message and diff with `git show`, and use `git status`
to confirm the intended remainder.

## Message rules

- Require a subsystem prefix. Choose an existing subsystem from history or
  the shortest accurate name from the changed path or module, such as `auth`,
  `docs`, or `cuda-101`. Repository style informs vocabulary and tone within
  these rules; it does not replace the prefix with a Conventional Commit type.
- Capitalize the title, use imperative mood, and omit a trailing period.
- Limit every handwritten line to 75 columns, including the complete subject.
- Include a body on every commit, separated from the subject by a blank line.
  Explain the motivation and major mechanism. Add compatibility or operational
  impact when material. Scale detail to semantic scope without inventorying
  files or functions or imposing a fixed paragraph count.
- Keep related sentences in one paragraph; separate distinct topics with a
  single blank line. Prefer a message file or heredoc. With `-m`, use one value
  per paragraph because Git inserts blank lines between values.
- Let Git add the sign-off from its configured identity; do not invent an
  identity or duplicate the trailer.

```text
auth: Fix session expiration race

Requests could observe a session expiring during validation and return an
intermittent 401. Reuse the grace period while an active request completes.

Signed-off-by: Author Name <author@example.com>
```

Never push unless explicitly asked. Verify authorship and commit hash before
amending.

## References

Read only the reference needed for the task. These references supplement the
rules above.

- [Atomic commits](references/ATOMIC_COMMITS.md): mixed refactoring,
  dependency, or behavior changes that need careful commit boundaries.
- [Commit format](references/COMMIT_FORMAT.md): URLs, issue references, and
  additional trailers.
- [Common mistakes](references/COMMON_MISTAKES.md): uncertain message coverage
  or commit boundaries.
- [Conventional Commits](references/conventional-commits.md): only when the
  user explicitly requests overriding the subsystem format.

The three uppercase references adapt GitLab's `commit-messages` skill.
Attribution and license terms are in
[LICENSES/GitLab-commit-messages.txt](LICENSES/GitLab-commit-messages.txt).
