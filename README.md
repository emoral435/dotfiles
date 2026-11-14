For: me, to keep my work Mac and my personal Mac set up the same way.
Not covered: secrets, work-only rules, and apps that are not in the Homebrew lists.

# dotfiles

On a new Mac, paste this one line into Terminal:

```sh
git clone https://github.com/emoral435/dotfiles.git ~/github/emoral435/dotfiles && ~/github/emoral435/dotfiles/dot
```

After that, type `dot` whenever you want this Mac up to date. That is the whole workflow.

## How your two Macs stay the same

Both Macs use the same config from this repo. The only thing that differs is a small file that `dot` writes the first time: `~/.config/dotfiles/machine`. It holds your user name, home folder, CPU type, and your answer to the one question `dot` asks: work or personal. Most config files are links into the repo: Ghostty, herdr, Neovim, zsh, and VS Code. An edit you make in the app or the file lands in the repo. Each time you type `dot`, it shows any edits you made on this Mac and asks to push them. Then it pulls the edits from your other Mac and applies everything. A change on one Mac reaches the other on its next `dot`.

## What `dot` does

| You type | What happens |
| --- | --- |
| `dot` | First run: installs Nix, asks work or personal, and sets up the Mac. Later runs: push your edits, pull, apply |
| `dot --dry-run` | Builds everything and changes nothing |
| `dot save` | Pushes your edits now, without applying |
| `dot doctor` | Checks the setup. Ends with "All good" or a numbered list of what to type |
| `dot edit <thing>` | Opens `agents`, `work`, `pi`, `ghostty`, `herdr`, `zsh`, `nvim`, or `nix` |

You never type `nix` or `darwin-rebuild`. `dot` runs them for you. Every error ends with the next command to type.

## Coding agents

- `agents/AGENTS.md`: my rules for every agent. `dot` writes `~/AGENTS.md`, `~/.claude/CLAUDE.md`, and `~/.codex/AGENTS.md` from it.
- `agents/skills/`: my skills, linked for pi, Claude Code, and `~/.agents`. Third-party skills keep their MIT licenses in `agents/skills/LICENSES/`.
- `pi/`: pi settings and extensions. `dot` merges the settings, so pi can still save its own keys.

## Keep work things off this public repo

- Work agent rules go in `~/.config/agents/work.md` (`dot edit work`). `dot` adds them to `~/AGENTS.md` on that Mac only.
- Shell settings for one Mac go in `~/.zshrc.local`.
- List words that must never be pushed in `~/.config/dotfiles/private-words`, one per line. `dot save` stops if an edit contains one.

## Good to know

- Homebrew cleanup is `none`: apps you install by hand stay.
- Git name and email are not set here. Set them once with `git config --global`.
- The dock and wallpapers are one-off scripts: `bin/set-dock.sh` and `bin/set-wallpapers.sh`.
- Rectangle needs Accessibility access the first time (System Settings, Privacy & Security).

## Repo map

| Path | Holds |
| --- | --- |
| `dot` | The one command |
| `flake.nix` | One shared config. It reads the machine file through `dot` |
| `configuration.nix` | macOS defaults and Homebrew apps |
| `home.nix`, `agents.nix` | Links from your home folder into this repo |
| `home/` | Config files: Ghostty, herdr, Neovim, VS Code, zsh |
| `agents/`, `pi/` | Agent rules, skills, and pi setup |
| `bin/` | One-off dock and wallpaper scripts |
