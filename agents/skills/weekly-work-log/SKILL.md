---
name: weekly-work-log
description: Generate my weekly work log from GitHub, Linear, Slack, Notion (docs I authored) and local sessions, then update the per-project story files. Use when I ask for my weekly log.
---
# Weekly work log
## Inputs
Window: last 7 days unless I say otherwise. Project slugs live in `career/projects.yml`.
## Gather
1. GitHub: merged PRs I AUTHORED, and PRs I REVIEWED, kept separate.
2. Linear: issues I owned or closed, grouped by project.
3. Notion: search pages I created or edited in the window (design docs, RFCs, postmortems, runbooks).
For each: title, link, the decision made, alternatives considered, who it was for.
4. Slack: threads where I made a decision, unblocked someone, or handled an incident.
5. Local sessions: use only for context, never as proof of impact.
If a source is unreachable, say so in one line and continue.
## Group
Map every item to a slug in `projects.yml`. If nothing fits, propose a new slug
and add it to the file. Never invent near-duplicate names.
## Entry template (one per project, max ~12 lines each)
- Project: <slug>
- Type: Shipped | Design | Debugging/Incident | Leadership/Collab | Docs
- My role: Led | Owned | Contributed | Reviewed | Supported | Unclear
(derive from PR authorship and docs authored; write Unclear rather than guess)
- Problem: one sentence, in terms a non-team member would understand
- What I did: max 3 bullets, no PR-number lists
- Why / tradeoffs: from Notion, PR descriptions, Slack. "Not found" if absent
- Outcome: one sentence
- Metric: value | source | confidence (measured / reported / estimated)
- Rough edges: bugs, rollbacks, near-misses, what went wrong
- Interview-worthy: Y/N + one-line reason
- Sources: links only
## Rules
- Prefer outcome metrics (latency, cost, incidents, time saved, adoption) over
activity metrics (PR count, lines changed, checks passed).
- Never state a number without a source. "Reported by a tool/agent" = confidence: reported.
- Reviewing is not authoring. Do not upgrade my role.
- Skip trivial work (dependency bumps, typo fixes) unless it was a project.
- Whole log under ~150 lines.
## Update project files
For each project touched, append one line to `career/projects/<slug>.md`
under "Timeline" (date, what happened, role). If Situation / My role / Result
sections are missing or outdated, update them from this week's evidence.
## Finish
End with "Questions for me": at most 4 questions about things you could not
determine (my reasoning, my exact role, the real impact, what I'd do differently).
I answer them in a couple of minutes and you fold the answers into the project files.
## Scripts
- `scripts/github.sh [WEEKS] [ORG]`: my merged authored PRs in the window, as JSON (`gh`, `jq`).
- `scripts/datadog.sh [WEEKS]`: Datadog monitors and SLOs I changed; skips itself without `DD_API_KEY` and `DD_APP_KEY`.
