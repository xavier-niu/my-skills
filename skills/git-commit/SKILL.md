---
name: git-commit
description: Use for commit-related git workflows, including creating, staging, reviewing, amending, or preparing git commits. Applies when the user asks to commit changes, run /commit, create signed-off commits, write commit messages, split changes into atomic commits, inspect git status/diff for commit planning, or use git add/git commit workflows.
allowed-tools:
  - Bash(git:*)
  - Read
  - Edit
---

# Git Commit Skill

This skill helps you create well-structured, atomic git commits with signed-off,
subsystem-prefixed commit messages.

## When to Use This Skill

Use this skill when:
- You need to commit changes to a git repository
- You want to create atomic, logically grouped commits
- You need to follow commit message best practices
- You have multiple changes that should be split into separate commits
- You need to use git partial adds (git add -p) for fine-grained control

## Task Overview

Based on the current git status and changes, create a set of logically grouped, atomic commits.
Be specific with each grouping, and keep scope minimal. Leverage partial adds to
make sure that multiple changes within a single file aren't batched into
commits with unrelated changes.

## Process

1. **Analyze Current State**
   - Check git status to see staged and unstaged changes
   - Review git diff to understand what has changed
   - Check recent commits (`git log --oneline -20`) to understand:
     - the subsystem names commonly used by the project
     - the project's capitalization and wording conventions
     - typical subject line length and formatting patterns

2. **Group Changes Logically**
   - Identify related changes that should be committed together
   - Separate unrelated changes into different commits
   - Use `git add -p` for partial adds when a file contains multiple logical changes

3. **Create Commits**
   - Stage the appropriate changes for each commit
   - Write commit messages following the best practices below
   - Always create commits with `git commit -s`
   - Verify each commit is atomic and complete

## Commit Message Format

Use this subject format for every commit:

```
{subsystem}: {commit title}
```

Examples:

- `cuda-101: Add SGEMM CMake sample`
- `tcp-close-wait: Add Go client reconnect loop`
- `attention: Remove unused helper`

Before writing commits, inspect recent history to choose a subsystem that
matches the project. Prefer an existing subsystem prefix when one clearly
applies. If no existing prefix applies, choose the shortest accurate subsystem
name from the changed path or module.

### Body Format

Write the body as one paragraph:

- Do not leave blank lines inside the body.
- Wrap body lines so no line exceeds 75 characters.
- Explain what changed and why; avoid repeating implementation details that are
  obvious from the diff.
- Keep the body only when it adds useful context.

### Signed-Off Commits

Always commit with `-s`:

```
git commit -s
```

The sign-off trailer is separate from the body and is added by Git.

## Git Commit Message Best Practices

Follow these rules for excellent commit messages:

1. **Separate subject from body with a blank line** - Critical for readability
2. **Use `{subsystem}: {commit title}` for the subject** - Keeps history scannable
3. **Keep the subject concise** - Prefer one clear change summary
4. **Subject must not exceed 75 characters** - Including the `{subsystem}: ` prefix; shorten the title (or pick a tighter subsystem) rather than overflow
5. **Do not end subject line with a period** - It's a title, not a sentence
6. **Use imperative mood in subject** - "Add feature" not "Added feature"
   - Test: Subject should complete "If applied, this commit will _____"
7. **Wrap body at 75 characters** - Ensures readability in terminals
8. **Use one body paragraph** - Do not put blank lines inside the body
9. **Use body to explain what and why vs. how** - Code shows how, commit explains why
10. **Always commit with `git commit -s`** - Add a Signed-off-by trailer

### Message Structure

```
<subsystem>: <concise title, imperative, no period>

<body: one paragraph, wrapped at 75 characters, no blank lines inside>

<Signed-off-by trailer added by git commit -s>
```

### Key Principles

- **Atomic commits**: Each commit should represent one logical change
- **Context is king**: Explain WHY the change was made, not just what
- **Future-proof**: Write for someone (including future you) reading this months later
- **Consistency**: Maintain uniform style across the project

### Examples

**Good Examples:**
- `cuda-101: Add SGEMM CMake sample`
- `auth: Fix null pointer in login handler`
- `docs: Update API examples`
- `tcp-close-wait: Remove stale binaries`

**Bad Examples:**
- `fixed stuff`
- `Changes`
- `wip`
- `Update file.js`
- `Add user authentication middleware` (missing subsystem)
- `feat added new feature` (incorrect format)

## Implementation Steps

1. Run `git status` to see current state
2. Run `git diff HEAD` to see all changes
3. Run `git log --oneline -20` to analyze recent commit style
   - Identify existing subsystem prefixes
   - Note the typical capitalization and wording style
   - Identify any project-specific conventions
4. Identify logical groupings of changes
5. For each logical group:
   - Stage the relevant changes (use `git add -p` if needed)
   - Create a signed-off commit with `git commit -s`
   - Use the subject format `{subsystem}: {commit title}`
   - Use one body paragraph wrapped at 75 characters when a body is useful
   - Verify the commit with `git show`
6. After all commits, run `git status` to verify nothing important was missed

## Reference Documentation

For conventional commit details, see:
- [Conventional Commits Reference](references/conventional-commits.md)

This skill intentionally prefers `{subsystem}: {commit title}` over
conventional commit type prefixes unless the user explicitly requests
conventional commits.

## Notes

- **ALWAYS check recent git history first** to determine subsystem names
- **Match the project's existing style** - consistency is more important than personal preference
- Always use `git commit -s`
- DO NOT push to remote unless explicitly asked
- Always verify authorship and commit details before amending
- Use `git add -p` for interactive staging when files contain multiple unrelated changes
- Keep commits focused and atomic - one logical change per commit
- If in doubt about the subsystem, choose the shortest changed path/module name
