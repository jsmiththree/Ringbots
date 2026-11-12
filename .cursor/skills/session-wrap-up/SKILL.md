---
name: session-wrap-up
description: >-
  Checkpoint the current Ringbots feature or thought by updating the docs,
  opening one clean GitHub pull request, and merging it. Use when the user
  says to update the repo, PR, PR/merge, open a pull request, or merge the
  current changes. The user may keep working after the merge.
---

# Checkpoint

When the user says to update the repo, or to PR and merge, checkpoint the feature or thought in progress. Update the documentation that thought changed, then open one clean pull request and merge it.

A checkpoint is not the end of the work. More features can follow on the updated `main`. Do this only when the user asks. Do not checkpoint just because a change looks finished.

## Docs first

Read the current feature or thought and the diff. Update only the docs that drifted.

| Path | Update it when |
| --- | --- |
| `docs/` | Gameplay rules from the design document were clarified or re-read. Do not edit the Google Doc. |
| `engineering/README.md` | Build decisions changed: the clock, orders, scope, or build order. |
| `engineering/hosting.md` | The public URL, tunnel, or Caddy setup changed. |
| `README.md` | The public map of the repo changed. |

Leave a file alone when this thought did not change its subject. If nothing at all changed, stop. Do not open an empty pull request.

## Clean pull request

The repo is GitHub: `https://github.com/jsmiththree/Ringbots.git`. Use `git` and `gh`. Both are already on PATH. Do not search for install locations. Do not use the Origin CLI.

The shell is PowerShell. Pass commit messages and pull request bodies with here-strings, not bash heredocs.

```powershell
git commit -m @"
Why this change exists.

"@
```

```powershell
gh pr create --title "Short title" --body @"
## Summary
- What changed and why.

## Test plan
- [ ] Check that matches the diff.

"@
```

1. Start from an up-to-date `main`. Create a new branch for this checkpoint.
2. Stage only the files for this feature or thought. Never stage `godot/.godot/`, secrets, or unrelated work that is still in progress.
3. One commit. The message says why.
4. Push with `git push -u origin HEAD`.
5. Open the pull request with `gh pr create`.
6. Merge with `gh pr merge --squash --delete-branch` once GitHub reports it mergeable and required checks are clear. Squash keeps `main` to one commit per checkpoint.
7. Confirm the local checkout is on `main`, even with `origin/main`, and the working tree is clean.
8. Return the pull request URL. The next feature starts from that `main`.

Never update git config. Never skip hooks. Never force-push. If a hook rejects the commit, fix the problem and make a new commit.

If `gh` is not logged in, say so and stop. Do not invent another way to publish.
