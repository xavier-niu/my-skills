---
name: github-cli
description: >-
  Use for tasks that target GitHub or GitHub Enterprise, a repository whose
  remote is GitHub-hosted, or the GitHub CLI (`gh`). Trigger for GitHub pull
  requests, issues, checks, Actions, releases, repository metadata,
  authentication, and API queries. Route by the actual remote hostname,
  prefer `gh` for GitHub service operations, retain `git` for native version
  control, and do not use `gh` with non-GitHub hosting providers.
---

# GitHub CLI

Use `gh` as the primary interface to GitHub services without replacing
ordinary Git operations.

## Route by hosting provider

1. Resolve the target repository from an explicit URL or repository selector.
   Otherwise inspect `git remote get-url origin`; if `origin` is absent or
   ambiguous, inspect `git remote -v`.
2. Classify by the actual hostname, not the organization or repository owner.
   Treat `github.com` and configured GitHub Enterprise instances as GitHub.
   For example, `github.com/alibaba/project` is GitHub-hosted, while an
   Alibaba or Ant internal host running another platform is not.
3. Use `gh` only when the target is a GitHub host. For another provider, use
   its supported CLI or API, or use plain `git` for Git-level operations.
4. When multiple repositories or hosts are possible, target the repository
   explicitly with `--repo [HOST/]OWNER/REPO`. Check authentication with
   `gh auth status --hostname HOST` when authentication is relevant.

## Choose the correct interface

- Prefer `gh` for pull requests, issues, checks, Actions runs and workflows,
  releases, GitHub repository metadata, authentication, and GitHub API calls.
- Prefer `git` for working-tree state, commits, branches, history, diffs,
  fetch, pull, push, merge, and rebase.
- Use `gh pr checkout` when a pull request identity should drive the checkout;
  inspect `git status` first and preserve unrelated local changes.
- Use `gh help`, `gh <command> --help`, or the current GitHub CLI manual when
  syntax or behavior is uncertain. Do not rely on recalled flags when local
  help can verify them.

## Protect state

- Begin review and investigation with read-only commands such as `view`,
  `list`, `status`, `diff`, and API GET requests.
- Perform external mutations such as commenting, editing, closing, merging,
  releasing, triggering workflows, rerunning jobs, or cancelling runs only
  when the user requests them.
- Do not use force options that reset branches or overwrite state unless the
  user explicitly authorizes the destructive effect.
- Never print, store, or expose authentication tokens.
