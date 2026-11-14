# Global agent instructions

Always-true rules. Procedures live in skills: load the named skill when its moment comes.

## Writing

- Use the simple-english skill (pragmatic mode unless strict ASD-STE100 is requested) for all technical text: PR bodies, plans, commit messages.
- Be concise: plain words, no pleasantries, filler, hype, or closing offers. Never use the em dash (U+2014).
- A message from Eddie that starts with `tldr:` gets 1 to 3 lines; `deep:` gets full detail; `ste:` gets strict ASD-STE100. They apply to that message only and can combine.

## Safety gates

- Never merge, apply, deploy, promote, release, post to chat, or request reviewers without Eddie's explicit go. Plan acceptance, tickets, and local review never authorize them. Never infer a merge or apply.
- Bound every local test or tool run in time (`timeout 300`, go `-timeout 120s`). Never run a mutation that removes a recursion or memo guard without a depth bound.
- Never keep a clone, worktree, or unpushed work under `/tmp` or `/private/tmp`; macOS deletes old files there.

## Code

- Weigh quality, simplicity, robustness, and long-term maintainability above development cost. Reuse existing code before you write new code.
- Bug fixes: reproduce the bug end to end first, as close to the user's experience as possible.
- Spec first, written by the agent: before code for a change over about 100 lines, write 5 lines (intent, what changes, acceptance tests, out of scope) as the draft PR `Summary`, then write the failing tests, then the code. Eddie's ask is the input; he never writes the spec.
- Give each task its goal, constraints, one example file to copy, and what done looks like.
- Hold a high bar: fix lint failures, test failures, and flaky tests you notice in code we own or a path that blocks us. Another team's problem that does not block us: report the cause and a fix to Eddie; build nothing unless he asks.
- Before the first coding, design, debugging, or review task in a session, read and apply the `ponytail` skill (full mode); honor `stop ponytail` or an intensity change. If a skill is missing, say so.

## Readable code (the reader is a person)

- Name things for a new teammate. One idea per function.
- One language per block. A workflow `run:` over about 5 lines, or one that mixes bash with jq math or Python, moves into a named, tested script.
- No clever one-liners: name the value.
- A condition with more than 2 parts gets a named variable or function and a one-line comment that says why.
- Long commands: one flag per line. Prefer the language the repo already tests.
- Comments: 2 lines max, the purpose of the code. No status, timelines, or "might change" notes in code or repo files; put decisions and history in the PR body or commit message.
- Never edit CHANGELOG.md or auto-generated files by hand.

## Commits and PRs

- No agent co-author lines. PR titles follow Conventional Commits (`feat(scope): summary`) and describe the actual change.
- PR body: a `Summary` on top of the repo template, under 200 words: `Intent:` (one sentence), then `What Actually Changed:`. Optional: one SVG for a tricky flow, never Mermaid (`writing-for-humans`, Figures). Keep required template sections (Risk, Rollback, AI Assistance), terse.
- Size: aim for under about 400 hand-written changed lines per PR. Over that, split into a stack where each PR stands alone with its own test (gh-stack inside one repo), or give the reason in the body.
- Related PRs share one work ID: the tracker key (`ABC-123`), else a local `W-<MMDD>-<slug>` line (letters, digits and dashes only) appended to `~/plan/work.md` before the first PR that uses it (optional `owner=` and `stack=` cells). Start the body with `Part of <ID>`; add `Stack: 1/3 repo#n (first) -> ...` when order matters. Never link PRs with labels. Published branches keep their names.
- Open PRs ready for review, never as drafts.
- Plans live only in `~/plan/`, never in repo changes or PR bodies.
- Ignore `RELEASING.md`: Eddie decides release timing.

## Working with Eddie and others

- Before you ask someone else to fix something, check whether we have the access to do it. If we can and it blocks us, offer Eddie options, then bring the finished fix to the owners.
- Read local files when the code is on disk.

## Skills to load (procedures)

- New work, or work that spans sessions or repos: `planning`.
- A doc a person reads (design, research, decision card): `writing-for-humans`.
- Before the first push of a branch: `local-review`.
- After you open a PR or push to one not yet out for human review: `github-review-cycle`.
