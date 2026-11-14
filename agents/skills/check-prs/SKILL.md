---
name: check-prs
description: |
  Triage new comments across all of the user's open GitHub PRs using the gh
  CLI, present a digest, and only after explicit approval make code changes,
  commits, pushes, or replies. Use when the user says "check my PRs", "check
  for new PR comments", "/check-prs", "any new comments on my PRs", or asks
  to review/respond to PR feedback across their repos.
metadata:
  requires: gh CLI (authenticated)
---

# Check PRs

On-demand triage of new comments on every open PR authored by the current
`gh` user. Never commits, pushes, or replies without explicit per-item
approval in the same turn.

State file: `~/.Codex/pr-watch-state.json` — JSON object mapping
`"owner/repo#number"` to the highest comment `id` already shown for that PR.
Read it if present (treat missing file/keys as "nothing seen yet"); you will
rewrite it at the end of the run.

## Steps

1. **List open PRs authored by the user:**
   ```
   gh search prs --author=@me --state=open --json repository,number,title,url
   ```

2. **For each PR**, fetch both comment kinds:
   ```
   gh api repos/{owner}/{repo}/issues/{number}/comments
   gh api repos/{owner}/{repo}/pulls/{number}/comments
   ```
   (the second call returns inline/review comments with `path`/`line`/`diff_hunk`).

   Filter each list to comments where `id` is greater than the stored
   last-seen id for `"owner/repo#number"`, and drop comments authored by the
   logged-in user themself (check `gh api user --jq .login` once, or infer
   from `gh auth status`). Keep bot comments (e.g. `github-actions[bot]`) but
   label them clearly as bot output — some (like drift-check reports) are
   genuinely actionable, so don't silently drop them.

3. **Present a digest** grouped by PR: title, link, then each new comment
   (author, file:line for inline comments, body — truncate very long bodies).
   If there is nothing new across any PR, say so briefly and stop — don't
   touch the state file.

4. **Ask the user which comments (if any) to act on**, and how: reply only,
   code change, or both. Do this as a normal question in the conversation —
   no separate tool needed. Treat silence/"just show me" as "no action."

5. **For each approved item only:**
   - Find a local clone of the repo (check common workspace roots the user
     has used before), or `gh repo clone {owner}/{repo}` if none exists.
   - `gh pr checkout {number}` in that clone.
   - Make the requested change, run relevant tests if the repo has an
     obvious test command, then commit with a message describing why.
   - Push the branch.
   - Reply to the comment thread:
     - General PR comment: `gh api repos/{owner}/{repo}/issues/{number}/comments -f body="..."`
     - Inline review comment: reply via
       `gh api repos/{owner}/{repo}/pulls/{number}/comments -f body="..." -F in_reply_to={comment_id}`,
       and resolve the thread with the `resolveReviewThread` GraphQL mutation
       only if the user asked for that.
   - Do not push, commit, or reply for anything not explicitly approved this turn.

6. **Update the state file** with the newest comment id seen per PR
   (regardless of whether the user acted on it), so the next run only shows
   genuinely new comments. Write the whole file back with `Write`/`Edit`.

## Notes

- This is on-demand only — nothing runs in the background. To poll
  periodically, the user can wrap this skill in `/loop 10m /check-prs`.
- Never skip the approval step in point 4, even if a comment looks trivial.
