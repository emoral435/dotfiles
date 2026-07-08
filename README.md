# dotfiles

My personal MacOS setup. One repo, one area to centralize my personal opinions, and one sick setup. Enjoy.

Inspired by Meta Principle Engineer Kun Chen's own personal [dotfile repo](https://github.com/kunchenguid/dotfiles).

## What You Get
Me setup consists of the following:

* System settings (dark mode, key repeat, dock, Finder, trackpad)
* Homebrew apps (casks and CLI tools, make sure to check if you are okay with downloading these)
* Nix user packages (ripgrep, fd, fzf, jq, lazygit, Hack Nerd Font)
* Shell (oh-my-zsh, powerlevel10k prompt, aliases)
* Editor (Neovim + VSCode config)
* Neovim is the default editor -- nice things like no blinking cursor in normal mode
* Dock layout (managed manually via `bin/set-dock.sh`)
* Desktop wallpapers per monitor (managed manually via `bin/set-wallpapers.sh`)
* Agent configs (global AGENTS.md)
* Reef (window manager, auto-installed from GitHub release)

## Prerequisites

- Apple Silicon Mac, by default.
- Intel Mac: change one line.
  In `configuration.nix`, set `nixpkgs.hostPlatform = "x86_64-darwin";` (the comment right there tells you the same thing).

## Fresh-machine setup

On a brand new Mac, from a bare clone of this repo:

```sh
git clone https://github.com/emoral435/dotfiles.git
cd dotfiles
```

Before you run it: review "Make it yours" below.
Change the host label or CPU architecture if needed, and read the Homebrew cleanup warning.
`bootstrap.sh` applies the config to your machine, so do this first.

```sh
./bootstrap.sh
```

`bootstrap.sh` does four things, in order:

1. Installs Determinate Nix, if it isn't already installed.
2. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first build, because `home.nix` points at config files through `~/.dotfiles`.
3. Checks the `user` configured in `flake.nix` against your actual macOS username, and offers to fix it for you if they differ.
4. Runs the first `darwin-rebuild switch`.
   It fetches the `darwin-rebuild` tool from the nix-darwin 26.05 release branch, then applies this repo's locked flake config.

After that, `darwin-rebuild` exists and you're on the normal workflow below.

### Validate without applying

Once Nix is installed (`bootstrap.sh` step 1 handles that), you can check that the config builds without touching your system - handy when you have edited something:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

If you renamed the host label in "Make it yours", substitute your label for `mac` in these commands.

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh
```

That's it.
No separate build-and-copy step.

**Dock layout** is not automated on every rebuild - pinning apps to the dock is a one-off per machine. When you add or remove a cask that should live on the dock, run:

```sh
./bin/set-dock.sh
```

This clears the dock and pins the apps listed in the script. Currently that is: Ghostty, Google Chrome, Spotify, Visual Studio Code, Notion, and Todoist.

**Desktop wallpapers** are set once per machine. Drop your images into `home/.config/wallpapers/` as `display-1.jpg`, `display-2.jpg`, and `display-3.jpg` (one per monitor), then run:

```sh
./bin/set-wallpapers.sh
```

The script asks whether you want the same wallpaper on all displays (uses `display-1.jpg`) or a different one per monitor. If any file is empty or missing, it prints a warning and skips that display.

## Make it yours

This repo is mine.
If you clone it, review these before you run `bootstrap.sh`:

- **Username**: run `./bootstrap.sh` (it detects your macOS username and offers to set it) OR change the single `user = "emoral435"` line in `flake.nix`. You can find this out by running `whoami`, and copy it using `whoami | pbcopy`.
  Everything else (`configuration.nix`, `home.nix`, home directory paths) is threaded from that one variable.
- **Host label** `"mac"`, in three places: `flake.nix` (the `darwinConfigurations."mac"` name), `rebuild.sh:5` (the `#mac` at the end of the flake reference), and `bootstrap.sh`'s first-switch command (also `#mac`).
  All three have to match.
- **CPU architecture**, `hostPlatform` in `configuration.nix` (see Prerequisites above).

**Git identity:** this config deliberately does not set your git name or email.
Git will stop your first commit and tell you to set them (`git config --global user.name "Your Name"` and `git config --global user.email you@example.com`).
If you'd rather manage that declaratively, add this back to `home.nix` with your own identity:

```nix
programs.git = {
  enable = true;
  settings.user = {
    name = "Your Name";
    email = "you@example.com";
  };
};
```

**Homebrew cleanup warning:** `configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`.
That means every time you switch, Homebrew removes any package or cask on your machine that isn't listed in the `brews` and `casks` arrays in `configuration.nix`.
If you already have Homebrew stuff installed that isn't in that list, the first switch will uninstall it.
Read through `brews` and `casks` before you run `bootstrap.sh` or `rebuild.sh` for the first time, and add anything you want to keep.

**Heads-up:**

- `home/AGENTS.md` is my personal agent policy.
  If you clone this repo, you'd silently inherit my agent instructions - edit or delete `home/AGENTS.md` if you don't want that.

## Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs, nix-darwin, home-manager, and nix-homebrew, and declares the `mac` machine.
- `configuration.nix` - system-level config: macOS defaults, Homebrew, Reef auto-install and login item setup.
- `home.nix` - user-level config: shell, packages, prompt, and the symlinks described below.
- `rebuild.sh` - re-applies the config after the first switch.
  Run this every time you make a change.
- `bin/set-dock.sh` - one-off script to pin Homebrew casks to the macOS dock.
  Run it when you add or remove a dockable app from `brews`/`casks`.
- `bin/set-wallpapers.sh` - one-off script to set wallpapers per display.
  Run it after dropping your images into `home/.config/wallpapers/`.
- `home/` - the actual config files that get symlinked into place (Ghostty config, Neovim config, VSCode settings, zsh/powerlevel10k, wallpapers, global `AGENTS.md`).

## How the symlinks work

The files under `home/` are the real files - editing them here is editing your live config, no rebuild needed to see the change in your editor.
`home.nix` uses `mkOutOfStoreSymlink` to point the following paths straight at files in this repo, so the two never drift out of sync:

| Target (on disk) | Repo source |
|---|---|
| `~/Library/Application Support/com.mitchellh.ghostty/config` | `home/.config/ghostty/config` |
| `~/Library/Application Support/Code/User/settings.json` | `home/.config/Code/User/settings.json` |
| `~/Library/Application Support/Code/User/keybindings.json` | `home/.config/Code/User/keybindings.json` |
| `~/Library/Application Support/Code/User/snippets` | `home/.config/Code/User/snippets` |
| `~/.zshrc` | `home/.config/zsh/.zshrc` |
| `~/.p10k.zsh` | `home/.config/zsh/.p10k.zsh` |
| `~/.config/nvim` | `home/.config/nvim` |

You only run `./rebuild.sh` when you change something that isn't just a symlinked file, like a package list or a system default.

If you add a new config file to `home/`, wire it up in `home.nix` using the same `mkOutOfStoreSymlink` pattern.
