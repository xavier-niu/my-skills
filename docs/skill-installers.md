# Installer requirements

Use this specification when adding skills, importing or updating remote
snapshots, or changing or diagnosing installation behavior. Repository origins,
agent locations, conflict rules, and installation commands are defined in
[AGENTS.md](../AGENTS.md).

## Importing remote skills

Resolve the canonical Git clone URL, ref or default branch, and skill path.
A GitHub `/tree/<ref>/<path>` URL identifies a ref and subtree; do not clone
the displayed URL literally.

Before making an imported or updated skill available, review its complete
subtree and applicable repository-level license. Inspect instructions,
executables, hooks, and referenced commands. Do not import or execute code
that exfiltrates data, requests credentials, weakens agent safety controls,
or performs unrelated machine changes.

Look for required skill invocations, including slash commands, even when
upstream has no dependency manifest. Preserve all applicable attribution and
license files with the vendored payload.

## Installer configuration

Use executable, Bash-compatible, project-owned `install.sh` files with
`set -euo pipefail`. Resolve paths from the script's own location, quote paths,
and provide actionable progress and error messages. Do not execute an upstream
installer merely because it exists or pipe downloaded content into a shell.

Keep configuration explicit near the top:

- Every installer: `SKILL_SOURCE`, `SKILL_NAME`, and a `DEPENDENCIES` array
  of sibling top-level skill directory names.
- Remote installers only: `REMOTE_URL`, `REMOTE_REF`, and `REMOTE_PATH`, or
  equivalent constants.

Use Git for Git remotes, supporting public HTTPS and existing Git credentials
for private remotes. Never read, print, or persist authentication tokens in the
repository.

## Installation order

1. Validate the checked-in `SKILL.md`, including its non-empty name and
   description, its match with `SKILL_NAME` and the directory name, and name
   uniqueness within the repository. Validate installer configuration.
2. For a remote update, fetch the configured ref into a `mktemp -d` staging
   directory and validate the selected subtree's `SKILL.md` before changing
   the vendored copy. With `--skip-update`, use the validated current snapshot.
3. Install declared dependencies through their checked-in installers.
4. For a remote update, synchronize the validated staged payload into the
   skill directory. Preserve the project-owned installer and provenance
   metadata. Remove only stale files known to belong to the previous snapshot.
5. Create agent links using the detection and conflict rules in `AGENTS.md`.
6. Summarize the source type, dependencies handled, agents installed or skipped,
   and conflicts. For a remote update, include the fetched revision.

## Dependencies

Every dependency must exist as its own top-level skill with its own executable
installer. Declare only direct dependencies required for the skill to function;
do not include optional or merely related skills or download hidden dependencies
into agent directories.

Resolve dependencies relative to the repository root. Refuse missing,
outside-repository, or non-executable installers. Install in dependency-first
topological order, propagate failures, de-duplicate shared dependencies within
one run, and track the active stack to report cycles.

For example, `grill-me` invokes `/grilling`, so `grill-me/install.sh` declares
`DEPENDENCIES=("grilling")`. The sibling `grilling/install.sh` has no dependency.
Running the parent installer handles `grilling` first, respecting each skill's
source type and forwarded flags.

## Failure handling and cleanup

Download or validation failures must leave the current vendored payload and
existing links intact. Refuse updates that would overwrite local modifications
with an actionable message; the authorized `--force` exception is defined in
`AGENTS.md`.

Clean temporary files with a trap. Scope deletion to exact temporary paths,
known stale vendored files, and exact installation links. Never use broad or
unresolved deletion targets or `git reset --hard`. Account for authorized
writes made by dependency installers without allowing unrelated machine changes.

A broken link for the same intended skill target may be repaired. Keep each
agent's detection and link handling independent so an absent agent cannot fail
the run. Validation and remote updates must succeed when no supported agent is
installed, with all agent installations reported as skipped.

## Verification

For a new skill or changes affecting installation, exercise the relevant paths
using a temporary `HOME` and stub agent executables:

- Run `bash -n` on affected installers and confirm they are executable.
- Run installation twice to verify idempotency.
- Test the no-agent path and every declared dependency path.
- Verify resulting links resolve to the intended top-level skill directory
  and expose a readable `SKILL.md`.
- For local skills, verify installation leaves their payload unchanged and
  performs no network access except through declared remote dependencies.
- For remote skills, simulate update failure before synchronization and confirm
  the previous payload remains intact.
- When changing dependency, conflict, or synchronization logic, exercise the
  affected failure cases as well as successful installation.

Inspect the diff to confirm only intended skill directories and project
metadata changed. Shared installer changes require coverage of affected local
and remote workflows. Reuse existing checks where available; rerun affected
checks after fixes rather than repeating unrelated tests.
