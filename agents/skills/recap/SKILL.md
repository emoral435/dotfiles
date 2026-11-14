---
name: recap
description: Summarize the current project, plan progress, PRs, user decisions, and next action in this chat.
disable-model-invocation: true
---

# Recap

Give the user an on-demand status summary in the current chat.
An optional argument selects a project or topic from this conversation.

## Gather

1. Identify the active task from the conversation and latest explicit user direction.
   Separate the main project from side questions. If the topic is ambiguous, name the ambiguity instead of choosing silently.
2. Reuse the canonical plan and linked handoff or evidence already identified for that task.
   Read only what is needed to establish the current stage, remaining work, and unresolved decisions.
3. Confirm the project directory before reading Git state. The shell directory can belong to another project.
   Use narrowly scoped, read-only checks for relevant branch and working changes when needed.
4. List only PRs tied to this scope. Use current read-only remote results when available and permitted.
   Otherwise label their state as recorded or user-reported, not verified now.
5. Reconcile older records with later user decisions and evidence.
   Name unresolved conflicts. Missing evidence means unknown, not complete or passing.

## Reply

Keep the summary under 150 words, excluding the PR state. Use concise, plain language.
Start with the current stage and one recommended next action. Then cover, in order:

0. Where we are: if the task follows a workflow skill or a staged plan (for example a migration skill with numbered stages), read that skill's stage list and name the current stage in its own words. List the stages that are done, the current stage, and the stages not started, one short line each, numbered as in the skill. Start the current stage's line with `→ ` before its number, so the reader sees where the work is at a glance. The arrow does not count toward the word limit. If the task follows more than one workflow, give one line per workflow. If no staged workflow applies, say so in one line.
1. Done: what you did since the user last saw a summary (for example, while they were away).
2. Plan: completed stages and remaining stages. Give the absolute plan path only if the user does not already have it.
3. Next: the next steps in order, each with its owner and any approval required.
4. PR state: on its own line or block after the summary. Include only PRs tied to this scope, checked live when possible, and relevant local unpublished work. Write each PR as a Markdown link with its full URL, for example `[app#10093](https://github.com/owner/app/pull/10093)`, so that it is clickable. It does not count toward the word limit.
   End the block with a merge-order line. If PRs must merge in a specific order, list that order and the reason for each dependency, for example "Merge order: api#1, then web#2 (web#2 fails closed without api#1)." If no order is required, write "Merge order: none required, these PRs are independent." Base the order on recorded dependencies, not on guesses.

Mention open questions or approvals only where they block a next step.

Use None known or Unknown when appropriate. Do not invent progress percentages or completion dates.
Keep resolved decisions out of Needs you, but mention a recent decision if it changes the next step.
Distinguish test results from independent review and preserve review counts and unreviewed corrections.
If no canonical plan exists, say so. Do not create one just to complete a recap.
End after the summary rather than asking a generic follow-up question.

## Boundaries

Recap is read-only. Do not edit plans, source, skill files, or status records during a recap.
Do not run tests, start monitoring, create tasks, send messages, or publish changes.
A next action is a recommendation, not authority to execute it.
Use only this conversation and relevant linked records, not unrelated sessions or fleet-wide searches.
Keep private prompts, credentials, and unrelated personal details out of the summary.
