---
name: planning
description: Decide whether new work needs a plan file, write and keep plans in ~/plan, and run central local tickets. Use at the start of new work, when Eddie asks for a plan, or when work spans sessions or repos.
---

# planning

Load at the start of new work. The global AGENTS.md rules still apply.

## Planning

- Start new work in native Plan Mode when the harness supports it. Claim native Plan Mode only when the harness is in it, not when only the prompt asks for planning.
- In auto mode without an explicit go-ahead, first suggest a short, skimmable plan that leaves out nothing important.
- A plan file is not automatic. At the start of new work, decide, then tell Eddie in one line which mode you picked:
  - No plan file (default): single-session, single-repo work, such as a bug fix, small feature, review, or anything that ships in one sitting. Capture intent and decisions in the PR body and commit message; they are the durable record.
  - Plan file: the work spans more than one session or more than one repo, or Eddie asks for a plan. Central tickets apply only when a plan file exists.
  - Genuinely ambiguous: ask once, "one-off or multi-session?". Do not ask when the work clearly fits one side.

### Plan file

- One Markdown plan at `~/plan/YYYY-MM/DD-<project-name>.md`, with the original creation date and a stable, descriptive name. Reuse it for the same work instead of a separate implementation plan or summary.
- For existing work, keep its current plan and links until an agreed migration avoids duplicate records.
- Top: `Owner: <agent-name>`, then a concise TLDR. When ownership changes, update the owner and keep the previous owner in the history.
- Content, in rough order: intent, findings, sources, important technical details, alternatives, decisions, open questions, tests, proposed PRs. Concise, readable prose, no fixed word limit.
- Include enough evidence and explanation for Eddie to assess whether the proposal will work. Put long queries and evidence in readable blocks or linked files.
- After feedback, update the TLDR and relevant sections in place. Keep decisions and their reasons current, without appended feedback logs or numbered round sections.
- Keep the proposed PR list current: each PR's purpose, dependencies, and unresolved questions.
- Give the absolute plan path (expand `~`) whenever you hand off or revise the plan.
- When Eddie accepts the plan, record the agreed decisions and findings before you implement the approved scope.
- If Plan Mode prevents writing the file, disclose that and save the plan after the supported mode change.

### Delegated worker base

- Before a delegated worker branches or creates a worktree, fetch and base it on fresh `origin/main` (or the repo's stated default branch), never a stale local `main` or an unrelated local branch.
- If the needed code exists only on an unmerged branch, base on that branch explicitly, state why, and flag the divergence from `origin/main` for reconciliation at ship time.

## Central local tickets

Use only when the work has a plan file; skip for one-off, single-repo work tracked by its PR alone.

- Before creating specs or tickets, read the repo's `docs/agents/issue-tracker.md` when present.
- Keep cross-repo tickets beside the canonical plan, under `~/plan/YYYY-MM/<task-name>/issues/`: one numbered Markdown file per ticket, plus a Work index in the plan that links every ticket.
- Repo configuration and worktrees reference these absolute paths; they keep no ticket or spec copies.
- Each ticket records its canonical spec, target repo, blockers, acceptance criteria, triage status, and execution state.
- At session start, read the Work index and relevant tickets, reconcile progress with Git/PR evidence, and pick an unblocked ticket.
- Before parallel work starts, assign distinct tickets centrally. Record each agent, worktree, branch, and assignment time.
- At every handoff, update the ticket with progress, test/review evidence, blockers, related PRs, and the next action.
- Distinguish local implementation, awaiting review/ship, merged code, and deployed resources. Completion needs the ticket's acceptance evidence, not just a commit.
- Surface abandoned assignments and unfinished follow-up; never silently mark them complete or assume a dormant agent will resume.
- An optional issue in an external tracker can track the overall milestone and its human owner. Keep execution detail in local tickets.
- Create or update external issues only with explicit user authorization. Avoid one external issue per ticket unless requested.
- Version and back up central records through an agreed storage workflow; disclose when Git or backup is not configured.
