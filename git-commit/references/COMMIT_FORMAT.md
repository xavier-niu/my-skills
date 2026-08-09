# Commit format reference

Use this reference for subject details, body structure, URLs, issue references,
and trailers. The core rules in `../SKILL.md` take precedence.

## Subject line

Use this exact default shape:

```text
<subsystem>: <Imperative title>
```

Check all of the following:

- Derive the shortest accurate subsystem from recent history or the changed
  path. A subsystem prefix is required.
- Capitalize the first word of the title after the colon.
- Use imperative mood: `Add`, `Fix`, `Remove`, `Prevent`, or another command
  form. The sentence “If applied, this commit will …” must read naturally.
- Keep the complete subject at or below 75 characters, including the prefix.
- Do not end the subject with a period.
- Make it meaningful without an issue tracker. `auth: Fix #847` is not enough.
- Treat `and` as a split warning, not proof. Split when it joins independent
  changes; keep it only when it names one indivisible behavior.

Use Conventional Commits only when explicitly requested. Then read
`conventional-commits.md`; its prefix counts toward the 75-character limit.

## Body format

Always leave one blank line after the subject and always include a body.

Lead with the motivation or failure mode that makes the change necessary. Add
the major mechanism, effects, limitations, compatibility impact, or operational
impact only when those facts help a future maintainer. Do not merely narrate
the diff or enumerate files.

Wrap every handwritten line at 75 characters or fewer. Keep sentences from the
same topic in one paragraph. Start a new paragraph only for a distinct topic,
such as a separate limitation or deployment consequence.

```text
auth: Fix session expiration race

Requests could observe a session expiring during validation and return an
intermittent 401. Reuse the grace period while an active request completes.
```

## URLs

- Prefer a short issue reference, documentation identifier, or concise
  canonical URL over a long tracking URL.
- Put a necessary URL in its own paragraph so prose wrapping remains clear.
- The local 75-character rule has no automatic URL exception. Do not silently
  add an overlong URL. Find a shorter stable reference, omit a nonessential
  link, or ask the user how to proceed.
- Never invent, shorten, or rewrite a URL in a way that changes its target.

## Issue references

Add an issue reference only when supplied by the user or established by the
diff, branch, or repository history. Never guess an issue number.

Keep the subject readable without the tracker. Put references after the body,
on their own lines:

```text
Fixes #847
Closes #921
Refs PROJ-123
```

Use a closing keyword only when this commit actually resolves the issue.
Otherwise use the repository's non-closing form, such as `Refs` or
`Related-to`. Match the hosting platform and recent history rather than
assuming one universal keyword.

## Trailers and sign-off

Keep trailers at the end of the message, with one trailer per line. Put issue
references and any repository-required trailers before the sign-off.

Always run `git commit -s`; do not make sign-off optional. Let Git add the
`Signed-off-by` trailer from the configured author identity. Do not handwrite a
different identity or duplicate an existing sign-off.

Example:

```text
scheduler: Add CPU architecture filter

Mixed x86 and ARM workers could receive incompatible binaries. Filter workers
by the architecture label before assigning a workload.

Fixes #847

Signed-off-by: Author Name <author@example.com>
```
