# Skill repository

This repository keeps reusable agent skills in top-level directories. Skills
have one of two origins:

- **Local skills** are authored and maintained in this repository. Their
  checked-in files are the source of truth and must never be replaced from a
  remote.
- **Remote skills** are loaded from GitHub or another Git remote. Their
  checked-in files are a reviewable vendored snapshot that `install.sh` can
  update from recorded upstream provenance.

Declare the origin explicitly in every installer as `SKILL_SOURCE="local"` or
`SKILL_SOURCE="remote"`. Do not infer it from directory contents or Git
history.

## Installing skills from this repository

Treat a request to install a skill already present in `my-skills` as a request
to run that skill's checked-in installer. Do not bypass it with a generic skill
installer, because the project installer enforces origin, dependencies, local
modification checks, and the canonical agent destinations.

From the repository root, install one skill with:

```bash
./<skill-name>/install.sh
```

The command may be run from another working directory because every installer
resolves the repository from its own path. It performs these operations:

1. Validates the checked-in skill and installer configuration.
2. Installs every declared dependency in dependency-first order.
3. For a remote skill, fetches and validates upstream before replacing the
   vendored snapshot. A local skill never accesses the network or rewrites its
   payload.
4. Links the repository skill directory into every detected supported agent.
5. Prints an installation summary, including skipped agents and conflicts.

Supported user installations are:

- Codex: `$HOME/.agents/skills/<skill-name>`
- Claude Code: `$HOME/.claude/skills/<skill-name>`

An absent agent is skipped. An existing link to the same repository skill is
an idempotent success. A file, directory, or link to another source is a
conflict and must be left unchanged.

Remote installers also accept:

- `--skip-update` to install the current vendored snapshot without fetching
  upstream.
- `--force` to replace locally modified vendored files with the fetched
  upstream snapshot. Use it only when the user explicitly authorizes losing
  those local modifications.

Local installers accept these flags only so they can forward them to remote
dependencies; neither flag changes the local skill payload.

Examples:

```bash
./git-commit/install.sh
./grill-me/install.sh
./humanizer/install.sh --skip-update
```

`grill-me` automatically installs its declared `grilling` dependency first.
Do not install dependencies manually unless diagnosing their installer.

After installation, list the skills found in known agent directories with:

```bash
./ls-skill.sh
```

Tell the user to start a new coding-agent turn or restart the agent if the
newly installed skill is not discovered in the current session. Installation
writes to user agent directories and a remote update uses the network, so
request the required execution approval when the environment restricts either
operation.

## Repository layout

- Put each skill in its own directory directly under the repository root,
  named after the skill's `name` from `SKILL.md`.
- Keep the usable skill payload directly in that directory. A typical layout
  is `<skill-name>/SKILL.md`, optional `agents/`, `assets/`, `references/`, and
  `scripts/`, plus `<skill-name>/install.sh`.
- For a local skill, edit the payload directly in its top-level directory.
- For a remote skill, vendor the selected upstream payload into its top-level
  directory. Do not use a nested Git checkout or submodule as the installed
  payload; files must remain reviewable and versioned by this repository.
- Require a valid `SKILL.md` with non-empty `name` and `description` fields.
  Refuse a new skill when its declared name conflicts with another skill.
- Preserve all license and attribution files that apply to a remote skill.
  Record its remote URL, ref, and remote subdirectory near the top of
  `install.sh`.

## Locally authored skills

- Treat the checked-in skill directory as the only source of truth.
- Its installer must not access the network, fetch a remote, rewrite the skill
  payload, or define remote provenance fields.
- Its installer validates the local `SKILL.md`, installs dependencies, creates
  agent links, and prints a summary.
- Dependencies may be local or remote. Calling each dependency's own
  `install.sh` preserves that dependency's correct source behavior.
- When modifying an older local skill without an `install.sh`, add one and
  bring the directory into compliance with this file.

## Loading remote skills

1. Resolve the canonical clone URL, ref or default branch, and skill path. A
   GitHub `/tree/<ref>/<path>` URL identifies both a ref and a subdirectory; do
   not clone the displayed URL literally.
2. Read the complete skill subtree and any repository-level license that
   applies to it. Review instructions, executable files, hooks, and referenced
   commands before making the skill locally available.
3. Do not import or execute code that exfiltrates data, requests credentials,
   weakens agent safety controls, or performs unrelated machine changes.
4. Look for references to other skills, including slash commands and explicit
   invocations. Treat a skill that delegates its job to another skill as a
   dependency, even if the upstream repository has no dependency manifest.

## Required `install.sh`

Every skill directory, local or remote, must contain an executable,
Bash-compatible `install.sh`. It is project-owned installer code, not an
unreviewed upstream installer. Use `set -euo pipefail`, resolve paths from the
script's own location, quote every path, and provide useful progress and error
messages.

Every installer must perform these common steps in order:

1. **Validate.** Confirm that the local skill name and `SKILL.md` are valid.
2. **Install dependencies.** Run each dependency's local `install.sh` before
   exposing the dependent skill to any agent.
3. **Install the skill.** Create an absolute symlink from each detected agent's
   user skill directory to the skill directory.
4. **Summarize.** Print the source type, dependencies handled, agents
   installed, agents skipped, and any conflicts. For a remote skill, also
   print the fetched revision.

A remote installer must first extend that workflow as follows:

1. Fetch the configured ref into a directory created with `mktemp -d`, select
   the configured remote subtree, and validate its `SKILL.md`. Do not change
   the current vendored copy yet.
2. Install dependencies using their local installers.
3. Synchronize the validated staged payload into the current skill directory,
   and then install the skill links. Preserve this repository's `install.sh`
   and provenance metadata. Remove only stale files known to belong to the
   previous upstream snapshot.

Additional installer requirements:

- Keep configuration explicit near the top of the script. Every installer has
  `SKILL_SOURCE`, `SKILL_NAME`, and a `DEPENDENCIES` array of local top-level
  directory names. A remote installer additionally has constants equivalent
  to `REMOTE_URL`, `REMOTE_REF`, and `REMOTE_PATH`.
- For remote skills, use Git for Git remotes. Support public HTTPS remotes and
  the user's existing Git credentials for private remotes, but never read,
  print, or persist an authentication token in the repository.
- For remote skills, never pipe downloaded content into a shell and never
  execute an upstream install script merely because it exists.
- Make every installation idempotent and safe to rerun. For remote skills,
  download and validation failures must leave the current vendored copy and
  existing agent links intact.
- For remote skills, do not overwrite local edits silently. Refuse with an
  actionable message when updating would replace locally modified vendored
  files; an explicit `--force` option may be implemented for a user-requested
  overwrite.
- Clean temporary files with a trap. Do not use broad or unresolved deletion
  targets, `git reset --hard`, or commands that can affect files outside the
  current skill directory and the exact installation links.
- If an installation target already links to this skill directory, treat it as
  success. A broken link created for this same target may be repaired. If a
  real file, directory, or link to another source occupies the target, report
  the conflict and leave it untouched.
- A local validation or remote update must still succeed when no supported
  coding agent is installed; report that all agent installations were skipped.

## Local agent targets

Detect an agent by its executable, not merely by a leftover configuration
directory. Install only to agents present on the machine and print `skipped`
for absent agents.

- Codex: when `command -v codex` succeeds, link the skill at
  `$HOME/.agents/skills/<skill-name>`.
- Claude Code: when `command -v claude` succeeds, link the skill at
  `$HOME/.claude/skills/<skill-name>`.
- Add another agent only after verifying its current executable name and user
  skill directory from primary documentation. Keep its detection and install
  block independent so an absent agent cannot fail the whole run.

Use one canonical target per agent. Do not create duplicate Codex links in
legacy and current directories, because duplicate skill names can both appear
in selectors.

Keep the root-level `ls-skill.sh` inventory script synchronized with supported
agent locations. Unlike installers, this read-only inventory may scan an
existing skill directory even when its agent executable is currently absent,
so it can report stale or externally installed skills accurately.

## Skill dependencies

- Every dependency must also exist as its own top-level local or remote skill
  directory with its own `install.sh`; do not download a hidden dependency
  directly into an agent's home directory.
- Declare direct dependencies in `DEPENDENCIES`. Resolve each entry relative
  to the repository root and refuse missing, outside-repository, or
  non-executable dependency installers.
- Install in dependency-first topological order. Propagate failures, de-duplicate
  shared dependencies within one run, and track the active stack so cycles are
  reported instead of recursing forever.
- Keep dependencies narrow: declare only skills required for the installed
  skill to function, not optional or merely related skills.

Known example: upstream `grill-me` says to run `/grilling`, so importing
`grill-me` also requires a sibling `grilling/` directory. Use
`DEPENDENCIES=("grilling")` in `grill-me/install.sh`, while
`grilling/install.sh` has no dependency. Running `grill-me/install.sh` must
update and install `grilling` first, then update and install `grill-me`.

## Verification

Before considering any skill complete:

- Run `bash -n <skill-name>/install.sh` and ensure it is executable.
- Exercise the installer with a temporary `HOME` and stub agent executables so
  tests do not modify the developer's real agent configuration.
- Run it twice to verify idempotency.
- Test the no-agent path and every declared dependency path.
- For a local skill, verify that installation performs no network access and
  does not modify its payload.
- For a remote skill, test update failure before synchronization and confirm
  the previous vendored payload remains intact.
- Verify each resulting link resolves to the intended top-level skill
  directory and that `SKILL.md` is readable through the link.
- Inspect `git diff` and confirm an update changed only the intended skill
  directories and project metadata.
