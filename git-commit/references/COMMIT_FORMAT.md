# Commit format reference

Use this reference for URLs, issue references, and additional trailers.
Follow the message rules in [SKILL.md](../SKILL.md).

## URLs

Prefer a short issue reference, documentation identifier, or concise canonical
URL over a long tracking URL. Put a necessary URL in its own paragraph.

The line limit has no automatic URL exception. Find a shorter stable reference
or omit a nonessential link. Ask only if a required link cannot satisfy the
user's instructions. Never invent or rewrite a URL in a way that changes its
target.

## Issue references

Add references only when supplied by the user or established by the diff,
branch, or repository history. Never guess an issue number.

Keep the subject meaningful without the tracker. Put references after the
body, on their own lines:

```text
Fixes #847
Closes #921
Refs PROJ-123
```

Use a closing keyword only when the commit resolves the issue. Otherwise use
the repository's non-closing form. Match the hosting platform and recent
history rather than assuming one universal keyword.

## Additional trailers

Keep trailers at the end, one per line. Put issue references and any
repository-required trailers before the sign-off. Add co-author or reviewer
trailers only when their identities and contributions are established.
