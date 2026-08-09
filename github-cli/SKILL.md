---
name: github-cli
description: >-
  Use for GitHub or GitHub Enterprise service operations and explicit GitHub
  CLI (`gh`) requests: pull requests, issues, comments, reviews, checks,
  Actions, releases, repository metadata or settings, authentication, and API
  queries. Do not trigger merely because a Git remote is GitHub-hosted. Use
  `git`, never `gh`, for native Git operations such as clone, remote, fetch,
  pull, push, checkout, branch, tag, log, diff, merge, and rebase.
---

# GitHub CLI

Use `gh` only for GitHub's service layer. Use `git` for every native Git
operation, even when the repository is hosted on GitHub.

## Keep the tool boundary strict

| Operation | Tool |
|---|---|
| Working tree, history, remotes, branches, tags, clone, fetch, pull, push, checkout, merge, and rebase | `git` |
| Pull requests, issues, comments, reviews, checks, Actions, releases, repository settings, and GitHub API calls | `gh` |

If local repository state or the Git transport can perform the operation, use
`git`. Use `gh` only when the task requires a GitHub service object or API.
Do not run `gh auth status` before a Git operation; Git's SSH or HTTPS
credentials are independent of GitHub CLI authentication.

## Route by hosting provider

1. Determine whether the request is a Git operation, a GitHub service
   operation, or a mixed task before checking GitHub CLI authentication.
2. For a Git operation, use `git` only and let Git use its configured SSH or
   HTTPS credentials.
3. For a GitHub service operation, resolve the target from an explicit URL or
   repository selector. Otherwise inspect `git remote get-url origin`; if
   `origin` is absent or ambiguous, inspect `git remote -v`.
4. Classify the actual hostname, not the organization or repository owner.
   Use `gh` only for `github.com` or a configured GitHub Enterprise host.
5. When multiple repositories or hosts are possible, pass
   `--repo [HOST/]OWNER/REPO`. Check `gh` authentication only when a relevant
   GitHub service command needs it or fails authentication.

## Choose the correct interface

- Use `gh` for pull requests, issues, comments, reviews, checks, Actions runs
  and workflows, releases, GitHub repository metadata or settings,
  authentication, and GitHub API calls.
- Use `git` for status, add, commit, remote inspection, clone, fetch, pull,
  push, checkout, branch, tag, log, diff, merge, and rebase.
- For mixed tasks, use each tool only for its own layer. A stale or missing
  `gh` login does not block Git operations when Git credentials work.
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
