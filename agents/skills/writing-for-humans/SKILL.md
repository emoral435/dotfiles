---
name: writing-for-humans
description: "Writing a doc a person reads, such as a design or research doc, decision card, README, runbook, or short answer. Use when the user names writing-for-humans or gives a word budget."
---

# Writing for humans

A person reads this doc to understand, decide, or act. The doc is a _brief_: the point first, the reasoning after, and every line one the author can defend. Sentences come from the `simple-english` skill. Agent-only text (`## Agent context`, a handoff) is not part of this skill: add it only when the user asks, with `writing-for-agents`. An agent can write the first draft. The user reviews and owns the decision part.

## Steps

1. **Write the header lines.** Put these lines at the top, before the title or right under it:
   - `For: <reader>, to <task>.`
   - `Not covered: <what the doc leaves out>.`
   - `Budget: N` only if the user gave a number. The default budget is 750 words.
   - `Kind: design` or `Kind: research` for those docs.

   Done when the reader, the task, and the scope each name something real.
2. **Open with the point.** State what you propose or found, and why, in a few sentences. Then give the detail that supports it. Done when a reader who stops after the first paragraph knows the point.
3. **Source every factual claim.** Give a short source in the text: a file, a PR, a page, or a command. Label a recommendation as yours. A design or research doc ends with a `## Sources` section for people. Done when every claim has a source or a "recommendation" label.
4. **Draw only the hard idea.** Read [Figures](#figures). Done when each figure passes its rules, or the doc has none.
5. **Write the sentences with `simple-english`.** Done when its self-check passes.
6. **Fit the budget.** Tables and code blocks count. `## Sources` and any heading that ends in `(not counted)` do not; each runs until the next heading of the same or a higher level. Done when `python3 ~/.agents/skills/writing-for-humans/scripts/check.py <doc>` exits 0.
7. **Get a fresh review.** Hand the doc and [Review](#review) to a fresh-context reviewer (a subagent). Answer its questions, fix each finding, rerun step 6, and ask for a new review. Done when the reviewer passes it.

## Figures

Draw a figure only for the one idea that prose explains badly: an order across 3 or more actors, a before and after change, or a state change. A line of steps is a numbered list. A set of facts is a table. Draw an SVG, never Mermaid, and never the whole system.

1. Write the caption first, as `**Figure N. <takeaway>.**` right under the image. If the caption states no takeaway, draw nothing.
2. If the figure needs more than one paragraph or 5 bullets to explain, split it.
3. For a before and after change, start from `~/.agents/skills/writing-for-humans/resources/before-after-template.svg`. For other shapes, keep its palette, text rules, and limits: 6 boxes per column, 2 lines per box, 2 clusters. `~/.agents/skills/writing-for-humans/resources/sequence-example.svg` shows a sequence.
4. Give the root `<svg>` `role="img"`, a `<title>`, and a `<desc>`. Say the takeaway in the text too.
5. Carry meaning with a shape or a label as well as a color. Use ASCII bytes only.
6. Keep the file next to the doc and embed it as `![alt](file.svg)`. Render it with `qlmanage -t -s 900 -o <dir> <file>.svg`, read the PNG, and fix any overlap.

## Review

The reviewer runs every check and reports PASS or FAIL with findings. A failure starts with the stock reply: "This does not meet our docs standard."

1. Script: `python3 ~/.agents/skills/writing-for-humans/scripts/check.py <doc>` exits 0.
2. Point test: read only the first paragraph and write the point in one sentence. Then read the rest. The sentence matches the doc.
3. Task test: do the reader's task (decide, or follow the steps) from the doc alone, and challenge one key assumption.
4. Source test: list 5 random sentences with line numbers and ask the author for each source. A missing source is a FAIL.
5. Thinking test: ask the author for one line on what they decided while writing. No answer is a FAIL.
6. Cut test: name text to cut.

