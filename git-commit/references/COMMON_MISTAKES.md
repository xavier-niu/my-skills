# Common commit mistakes

Use this reference when message coverage or commit boundaries are uncertain.
Apply the message rules in [SKILL.md](../SKILL.md) without repeating a full
review for a straightforward commit.

## Message coverage

A subject such as `auth: Update stuff` or `auth: Fix #847` does not explain the
behavior. Name the change and put issue references after the body. A body
that says only "Changed X to Y" should explain why X failed or why Y is needed.
Do not guess motivation, limitations, or compatibility claims.

When a draft is vague in several places, rewrite it from the diff's motivation
rather than patching individual words. Compare it with the staged diff so it
covers the major mechanism and makes no claims about unstaged work.

## Commit boundaries

A subject containing `and` is a warning only when it joins independent changes.
Refactoring, formatting, dependency churn, and cleanup may obscure a behavior
change that could stand alone. Keep required tests and documentation with the
change they support.

When the staged change bundles independent work, regroup the relevant hunks
without discarding unrelated changes. Consult [ATOMIC_COMMITS.md](ATOMIC_COMMITS.md)
for difficult splits.

## History changes

Amending an already-pushed shared commit requires explicit authorization and
coordination. Do not use a force option, reset, or cleanup that overwrites
unrelated work.
