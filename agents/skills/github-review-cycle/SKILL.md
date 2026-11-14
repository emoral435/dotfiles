---
name: github-review-cycle
description: Run the Codex and Claude bot review rounds on an open PR, sweep the 3 comment surfaces, reply to agent threads, manage the ai-review-loop-finished label, and give Eddie the review kit. Use after you open a PR or push to one that is not yet out for human review.
---

# github-review-cycle

Load after you open a PR or push to it.

## GitHub review cycle

The agent review cycle runs only before a PR goes out for human review.

- Send a PR to humans (review ask, reviewer, Slack post) only after the cycle converges, or when it cannot run (no bots on the repo, or out of tokens).
- After it is out for human review, do not run more agent review rounds: no `@codex`/`@claude` posts and no bot sweeps while you address human feedback. Extra rounds bloat the PR, drop fresh approvals, and bury the human's comments.
- Address human feedback in as few commits as possible (one per review round), then stop. Run a new agent round only if Eddie asks.

Before a PR goes out, every push triggers a fresh bot review round that lands 4 to 6 minutes later, so a push does not end the task. After you open a PR and after each push:

1. Post `@codex review`. Also post `@claude review` in every repo where `claude[bot]` is installed.
2. Schedule a wake-up about 6 minutes out instead of ending the turn or idle-waiting (`ScheduleWakeup` inside a `/loop`, otherwise `Monitor` with an until-condition on new review threads). Say so, so the wait does not look like a stall.
3. Sweep all three comment surfaces:
   - inline review comments: `gh api repos/{o}/{r}/pulls/{n}/comments`
   - review summaries: `gh api repos/{o}/{r}/pulls/{n}/reviews`
   - issue comments: `gh api repos/{o}/{r}/issues/{n}/comments`
4. Fix each valid agent finding in a new commit, as small as possible, reusing what is already in the repo. The commit message and the PR description both explain everything addressed in the round in simple English within 250 words; if there is too much, say so instead of forcing it under 250.
5. Push, reply to each agent thread (see Replying), then repeat from step 1.
6. You end the loop, since your own pass triggers the next round. Stop when a pass comes back empty, the remaining findings are too marginal for another cycle, or the bots reverse each other instead of converging. Say which signal you stopped on.

Reading bot output:

- Bot logins have a `[bot]` suffix: match `chatgpt-codex-connector[bot]`, not `chatgpt-codex-connector`, or filter on `user.type == "Bot"`. A wrong login silently returns zero and looks like a clean PR.
- Codex posts a "💡 Codex Review" summary on every run; its findings live in inline `pulls/{n}/comments`. It stays silent (👍) only when it truly has none.
- Claude posts one sticky issue comment (`claude[bot]`) and edits it each run. Read its latest verdict and the head commit it names; convergence needs that verdict clean on the latest head, not only Codex.
- Before concluding "no findings", confirm the filter returns at least the known bot summary; an empty result means a wrong filter far more often than a clean PR.
- Never infer completion from green CI, an empty filter, or a review that never ran.

`ai-review-loop-finished` label:

- Apply the existing label once AI review (any model or vendor) converges on the latest commit: all three surfaces inspected and every valid actionable finding addressed.
- Remove it when you push new changes or find a new actionable finding. Restore it only after reviewing the latest commit and converging again.
- It marks AI review completion, not human approval or deploy readiness. Do not backfill older PRs unless asked.

## Replying to and resolving review threads

- Reply to agent reviewers (most often Claude and Codex/ChatGPT). Eddie addresses human reviewers directly.
- Agent reply, within 50 words, on all three surfaces: `🤖 valid|invalid: <reason>, addressed in: <commit sha>`. Omit the 🤖 when the human user speaks in their own voice.
- After you reply to a Codex/ChatGPT or Claude thread, resolve it (GraphQL `resolveReviewThread`). The human resolves a human reviewer's thread, never you.

## Repo-specific reviewers

- Machine-local rules (the work overlay appended to AGENTS.md) can name required reviewers per repo. Follow them, and never reply to a human reviewer in the agent voice.

## Review kit

Whenever you open or update PRs, end the report with a copy-pasteable review kit so Eddie never hunts for paths, worktrees, or branches. Lead with `gh pr diff` (works from any directory with `-R`). Point at Eddie's normal checkout or the remote branch, never an ephemeral subagent worktree. Template:

```

## Your review kit (no path/worktree juggling)

Easiest - `gh pr diff` works from anywhere with `-R`:

    gh pr diff <PR> -R <owner>/<repo>     # <one-line what this PR is>
    ... one line per PR ...

lazygit - open the repo, fetch, pick the branch:

    cd <normal repo checkout> && git fetch && lazygit   # branch <branch>

Plain diff fallback: git -C <repo> diff origin/main...<branch>
```

Then list every open PR in the batch with its number, repo, branch, and a one-line description.
