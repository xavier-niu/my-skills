# Common commit mistakes

Use this checklist before committing when a message or commit boundary is
uncertain. Resolve every applicable red flag against `../SKILL.md`.

## Subject red flags

- [ ] The required `<subsystem>: ` prefix is missing or inaccurate.
- [ ] The title after the colon starts with a lowercase letter.
- [ ] The title uses past tense (`Fixed`, `Added`) or a present participle
      (`Fixing`, `Adding`) instead of imperative mood.
- [ ] The subject ends with a period.
- [ ] The complete subject exceeds 75 characters.
- [ ] The subject is vague, such as `Update stuff`, `Fix bug`, or `WIP`.
- [ ] The subject is only an issue reference.
- [ ] The subject uses `and` to bundle independent changes.
- [ ] A Conventional Commit type appears without an explicit user request.

## Body and trailer red flags

- [ ] There is no blank line between subject and body.
- [ ] The required body is missing.
- [ ] The body only lists what changed and gives no motivation.
- [ ] The body inventories files, functions, or implementation trivia.
- [ ] Related sentences are split into artificial one-sentence paragraphs.
- [ ] A handwritten line exceeds 75 characters.
- [ ] An issue number, URL, limitation, or compatibility claim was guessed.
- [ ] A closing keyword claims to resolve an issue the commit does not fix.
- [ ] An issue reference appears in the subject instead of after the body.
- [ ] The `Signed-off-by` trailer is missing, duplicated, or uses an identity
      other than the one Git would add with `git commit -s`.

## Scope red flags

- [ ] The staged diff contains more than one motivation.
- [ ] Refactoring, formatting, dependency churn, or cleanup obscures a
      functional change that could stand alone.
- [ ] Tests or documentation necessary for the change were left for an
      unrelated later commit.
- [ ] Unrelated user changes were staged because they were nearby.
- [ ] The commit cannot be reverted without also reverting independent work.

## History and mutation red flags

- [ ] The message ignores the repository's established subsystem vocabulary
      or capitalization.
- [ ] The commit amends an already-pushed shared commit without explicit
      authorization and coordination.
- [ ] A force option, reset, or cleanup would overwrite unrelated work.
- [ ] The final `git show` does not match the message.
- [ ] `git status` reveals important changes unintentionally left behind.

## Corrections

| Mistake | Correction |
|---|---|
| `Fixed the auth bug` | `auth: Fix null session validation` |
| `auth: Update stuff` | Name the exact behavior or invariant changed |
| `auth: Fix #847` | Describe the fix; put `Fixes #847` after the body |
| Body says only “Changed X to Y” | Explain why X failed and why Y is needed |
| Refactor and feature share one subject | Split when each is independently valid |
| Missing sign-off | Commit with `git commit -s` |

When a draft trips several checks, rewrite it from the diff's motivation rather
than patching individual words. When the staged change trips several scope
checks, unstage and regroup before drafting the message.
