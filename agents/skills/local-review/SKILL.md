---
name: local-review
description: Run the fresh-context local review and test of a complete diff before the first push of a branch. Use before you push a new branch or open a PR.
---

# local-review

Load before the first push of any branch.

## Local review before publication

- Implement the approved scope locally, then spawn a fresh-context subagent to review and test the complete local diff. This is an inline process, not a separate skill.
- Give the reviewer the accepted plan, constraints, intended base, complete diff, test evidence, and proposed PR body.
- The review requires:
  - Red-green evidence: a focused test fails without the change (in an isolated copy or temporary test config) and passes with it. If this does not apply, explain why.
  - Applicable tests and lint pass, the PR captures the intent and actual scope, and the changes work as described.
  - Readable code, reuse of existing code where possible, and minimal comments.
- Reviewers never edit the implementation. The builder fixes its own findings (resume it; no new fix worker), then reruns affected tests. Fixes under about 50 lines may be done by the coordinating agent directly.
- Review rounds: one full fresh review, then one targeted follow-up on the fixes. A third round only for P0, P1, security, or a production path. Review once per batch of small builds, not per build. Then report remaining blockers and ask for direction. Disclose unresolved findings and unavailable checks.
- Local commits are fine, so the review names a stable commit.
- For each proposed PR, report the absolute worktree path, branch, base, plan path, test results, and review verdict.
- After local review passes, push within the authorized scope and run the GitHub review cycle.
- Open PRs ready for review, never as drafts. If the task needs staged commits first, keep them local until the PR is ready.
- If later feedback needs code changes, repeat this local test and review before pushing.

## Reviewer checklist (add to every reviewer prompt)

- Readability: list every block a new teammate cannot read in 30 seconds, with a rewrite. Check the readable-code rules in AGENTS.md (one language per block, named values, named conditions with a why comment, one flag per line).
- Size: hand-written changes over about 400 lines need a stack, or a reason in the PR body.
- Reuse: name any new code that duplicates something already in the repo.
- Model: run the reviewer on a different model from the builder when one is available.
- Spec: check that the PR's 5-line spec (intent, changes, acceptance tests, out of scope) matches the diff, and that the acceptance tests exist and failed before the change.
