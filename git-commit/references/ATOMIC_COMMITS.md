# Atomic commits reference

Use this reference to split a working tree into reviewable, reversible commits.
The core rule is one logical change per commit, not one file per commit.

## Decide whether to split

Split changes when they have different motivations, can be reviewed or
reverted independently, or would deserve different subject lines. A single
logical change may span many files, layers, tests, and documentation.

Use these questions:

1. Would reverting one part while keeping the other make sense?
2. Can each part leave the repository buildable and tests meaningful?
3. Does each part solve a different problem or serve a different audience?
4. Does the proposed subject need `and` to join independent actions?
5. Would a reviewer benefit from seeing one change without the other?

Mostly “yes” means split. Keep changes together when separation would create
an invalid intermediate state or when every hunk is necessary for one behavior.

## Common split strategies

- **Refactoring and behavior:** Separate a behavior-preserving refactor from a
  feature or fix when each stands on its own. Keep a small enabling refactor
  with the behavior only when it has no independent purpose or safe state.
- **Bug fixes:** Keep the fix and its regression test together. Split a second
  unrelated bug even when it touches the same module.
- **Features:** Split independently useful sub-features. Keep implementation,
  tests, and documentation for one coherent feature together.
- **Dependencies:** Group updates that must move together for compatibility.
  Split unrelated package upgrades and generated lockfile changes.
- **Formatting and generated output:** Separate broad mechanical churn from
  semantic edits when doing so makes the semantic diff reviewable.
- **Cleanup discovered during work:** Split opportunistic cleanup unless it is
  required to make the requested change correct.

## Practical staging

- Start from `git status`, `git diff --stat HEAD`, and `git diff HEAD`.
- Map each hunk to its motivation before staging.
- Use `git add -p` to separate mixed hunks in one file.
- Check `git diff --cached` before every commit and `git diff` afterward to
  confirm the intended remainder is still present.
- Never discard unrelated user changes just to manufacture a clean boundary.

## Anti-rationalizations

Reject these reasons for bundling unrelated work:

- “It is faster.” A bundled commit costs more during review, revert, and
  bisection.
- “They are all small.” Small independent changes are usually easiest to
  separate.
- “They touch the same file.” File location does not define logical scope.
- “The work happened together.” Development chronology is not commit design.
- “It is the end of the day.” Time pressure does not make unrelated changes
  atomic.

Do not split mechanically either. More commits are not inherently better; each
commit must describe a useful, valid unit of change.

## Refactoring example

Bad bundle:

```text
db: Refactor connection pool and add health endpoint
```

Prefer two commits when both states are valid:

```text
db: Reuse one connection pool

Per-request pool creation exhausted database connections under load. Share a
bounded process-level pool instead.
```

```text
health: Add database readiness check

Load balancers need to stop routing traffic when the database is unavailable.
Return an unhealthy status when the shared pool cannot acquire a connection.
```
