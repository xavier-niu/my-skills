# Skill repository

This repository keeps reusable agent skills in top-level directories named
for the `name` in each `SKILL.md`. Keep the usable payload directly in that
directory, with non-empty `name` and `description` frontmatter. Skill names
must be unique.

## Origins and ownership

Every installer declares `SKILL_SOURCE="local"` or `SKILL_SOURCE="remote"`.
Never infer origin from directory contents or Git history.

- **Local skills:** Checked-in files are the source of truth. Edit them directly;
  never replace them from upstream. Local installers never fetch or rewrite
  their own payload and define no remote provenance fields. Remote dependencies
  may fetch through their own installers.
- **Remote skills:** Checked-in files are reviewable vendored snapshots, not
  nested Git checkouts or submodules. Record the remote URL, ref, and subtree
  near the top of `install.sh`, and preserve applicable licenses and attribution.

Every new skill must have an executable, project-owned Bash `install.sh`.
Add a missing installer when installing a legacy skill or explicitly migrating
it. An instruction-only edit does not require migrating its installer.

## Installing existing skills

Run the skill's checked-in installer; do not bypass it with a generic installer:

```bash
./<skill-name>/install.sh
```

Installers resolve paths from their own location and install declared
dependencies automatically. Do not install dependencies manually unless
diagnosing an installer problem.

Remote installers accept `--skip-update` to use the vendored snapshot and
`--force` to replace modified vendored files. Use `--force` only when the user
explicitly authorizes losing those modifications. Local installers accept
these flags only to forward them to dependencies.

After installation, run `./ls-skill.sh`. If the skill is not discovered, tell
the user to start a new coding-agent turn or restart the agent. Request the
execution approval required by the environment for writes to user agent
locations or network access.

## Agent locations

| Agent | Detection | Canonical skill target |
|---|---|---|
| Codex | `command -v codex` | `$HOME/.agents/skills/<skill-name>` |
| Claude Code | `command -v claude` | `$HOME/.claude/skills/<skill-name>` |

Install only for detected executables; skip absent agents. Use absolute links
to the top-level repository skill. An existing link to that directory is an
idempotent success. Leave files, directories, and links to other sources
untouched and report conflicts. Do not create duplicate legacy agent links.

Keep `ls-skill.sh` synchronized with these locations. Its read-only inventory
may scan existing directories even when the executable is absent. Add another
agent only after verifying its executable and user skill directory in primary
documentation.

## Task-specific guidance

Read [Installer requirements](docs/skill-installers.md) when adding a skill,
importing or updating a remote snapshot, or changing or diagnosing installers,
dependency declarations, or agent targets. It defines upstream review,
installation ordering, failure handling, and installer verification.

For instruction-only edits, validate changed skill frontmatter and references,
and inspect the diff for intended scope. For other documentation-only edits,
check affected links and consistency. Run installer checks when the change
can affect installation behavior; documentation edits alone do not require
repeating them.

Use disposable fixtures, temporary home directories, and stub agent executables
for installer tests. Run relevant checks, fix failures caused by the requested
change, and rerun affected checks without asking for approval at each step.
Stop testing once the relevant checks pass unless new evidence warrants more.
