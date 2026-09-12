---
name: github-cli
description: >-
  Use `gh` for GitHub and GitHub Enterprise service tasks or explicit CLI
  requests. GitHub-hosted Git operations alone do not trigger this skill.
---

# GitHub CLI

## Tool boundary

Use `git` for every native Git operation, including clone, fetch, pull, push,
checkout, branch, tag, history, diff, merge, and rebase. Use `gh` for GitHub
service objects and APIs: pull requests, issues, comments, reviews, checks,
Actions, releases, repository metadata or settings, and CLI authentication.
For mixed tasks, use each tool for its own layer.

## Target and authentication

Use the supplied URL or repository selector. When the target is not established,
inspect `git remote get-url origin`, then `git remote -v` if needed. Identify
GitHub by the actual hostname, not the organization or repository owner; use
`gh` for `github.com` or a configured GitHub Enterprise host. When multiple
repositories or hosts are possible, select the intended target explicitly with
`--repo [HOST/]OWNER/REPO` where supported.

Check `gh` authentication only when a relevant service command needs it or
fails authentication. Do not run `gh auth status` before Git operations:
Git uses its configured SSH or HTTPS credentials independently, so a missing
or stale `gh` login does not block working Git credentials.

Use `gh help`, `gh <command> --help`, or the current GitHub CLI manual when
syntax or behavior is uncertain.

## Authorization and state

Use read-only commands for reviews and investigations. Perform external
mutations within the user's requested scope; authorization already provided
in the conversation remains sufficient, so do not request it again for the
same action. Posting comments or reviews requires explicit authorization to
publish them; a request to review alone does not provide that authorization.

Use force options that reset branches or overwrite state only when the user
explicitly authorizes the destructive effect. Never print, store, or expose
authentication tokens.
