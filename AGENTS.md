# Project notes for agents

- `dot` is the only entry point; users never type nix. Keep `README.md`, `dot help`, and `dot doctor` in step when you add a verb or a linked file.
- This repo is public. Never commit work rules, company names, internal URLs, people, ids, or tokens. Work rules go in `~/.config/agents/work.md` on the work Mac.
- `flake.nix` holds no user names: it reads `DOT_*` variables that `dot` sets from `~/.config/dotfiles/machine`.
- Never use git stash (the stash list is shared across worktrees); commit to a branch instead.
- `homebrew.onActivation.cleanup = "none"` in `configuration.nix` is deliberate: manual installs survive a rebuild.
- Vendored third-party skills keep their license text in `agents/skills/LICENSES/`.
