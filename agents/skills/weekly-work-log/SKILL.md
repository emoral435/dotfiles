---
name: weekly-work-log
description: Generate my weekly work log from GitHub, Linear, Slack, Notion (docs I authored) and local sessions, then update the per-project story files. Use when I ask for my weekly log.
---
# Weekly work log

Run unattended and never ask questions. Follow `~/career-log/WEEKLY_RUN.md` exactly: it drives the `careerlog` pipeline in `~/career-log` (fetch, normalize, digest, judge, validate, render, email).

- `~/career-log/raw/` never leaves the machine: never attach, quote or paste it.
- If `~/career-log/WEEKLY_RUN.md` is missing, stop and say so in one line.

Final output: two lines: whether the email sent, and the run notes.
