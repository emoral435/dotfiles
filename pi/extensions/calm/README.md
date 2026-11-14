# Calm (standalone Pi extension)

Derived from Calm in [kunchenguid/firstmate](https://github.com/kunchenguid/firstmate) (MIT, see `LICENSE`).

Calm is a Pi transcript-presentation toggle for any project.
While Calm is on, it hides the noise of a working session and keeps only genuine prompts and replies.

Calm hides:

- built-in tool-call shells and their results (`read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`),
- collapsed thinking blocks,
- mid-turn assistant working notes (the narration a model emits next to its tool calls).

Calm keeps visible:

- genuine user prompts and the genuine final assistant reply,
- Pi's stock `Working...` row.

Calm changes presentation only.
Tool execution, model context, session storage, `/export`, and `/share` are unchanged.
Every hidden row stays in the session data and in exported or shared transcripts.

This build has no Firstmate dependency: no supervision code, no `FM_HOME`, and no Firstmate configuration.

## Requirements

- Pi with the exported `AssistantMessageComponent` seam (verified against Pi 0.85.1).
  Calm never rejects a newer Pi; if a future Pi removes the thinking-layout seam, Calm logs a diagnostic and skips only that part.

## Install

Copy the `calm/` directory into your global Pi extensions directory:

```sh
mkdir -p ~/.pi/agent/extensions
cp -R pi-calm ~/.pi/agent/extensions/calm
```

The extension auto-loads on the next Pi start in any project.
No settings change is needed.

## Use

- `/calm` toggles Calm on or off.
- Calm is off by default.
- The last choice persists in `~/.pi/agent/calm-preference` and applies to every project on the next Pi start.

## Coexistence with a project-local Calm

Some projects (for example Firstmate) ship their own project-local Calm.
When a project already provides a `/calm` command, this global Calm stands down so the plain `/calm` keeps working and both do not fight.

Known limit: only when this global Calm is turned on and you then open a project that ships its own Calm, Pi loads the global extension first.
Pi gives each built-in tool name to the first extension that claims it, with no takeover, so the 7 built-in tool shells can stay hidden per the global setting rather than following that project's `/calm` toggle.
Tool execution, model context, and export are never affected.
In a project that ships its own Calm, use that project's `/calm`.

## Rollback

```sh
rm -rf ~/.pi/agent/extensions/calm
rm -f  ~/.pi/agent/calm-preference   # optional: forget the saved on/off choice
```

Removal is complete on the next Pi start.
Nothing else is modified.

## Test

```sh
tests/pi-calm-standalone.test.sh   # real Pi + tmux, no model tokens; skips if either is absent
```
