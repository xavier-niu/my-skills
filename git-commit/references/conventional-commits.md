# Conventional Commits override

Use only when the user explicitly requests overriding the mandatory subsystem
format. Repository history alone does not enable this override. The remaining
message and sign-off rules in [SKILL.md](../SKILL.md) still apply unless the
user also changes them.

Replace the subsystem subject with `<type>[optional scope]: <Title>`.
Use `feat` for new behavior, `fix` for a bug fix, and the appropriate repository
convention for documentation, refactoring, tests, build, or CI changes.
A scope identifies the affected module, such as `fix(auth)`.

For a breaking change, add `!` before the colon or a `BREAKING CHANGE:` footer
explaining the impact and required migration. Use only when the change
actually breaks compatibility.

```text
fix(auth): Prevent expired sessions from passing validation

Expired sessions could remain usable until the next cleanup pass. Check the
expiration timestamp during validation to reject them immediately.

Signed-off-by: Author Name <author@example.com>
```
