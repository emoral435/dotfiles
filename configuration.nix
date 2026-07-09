{ user, ... }:
{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;
  environment.variables.EDITOR = "nvim";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU
  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock = {
      autohide = true;
      wvous-br-corner = 4;
    };
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    autoMigrate = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "dockutil"     # CLI tool to configure the macOS dock
      "curl"         # Universal transfer tool
      "gh"           # GitHub CLI
      "ghcup"        # Haskell toolchain manager
      "git"          # Version control
      "go"           # Go programming language
      "golangci-lint" # Go linter
      "hugo"         # Static site generator
      "jq"           # JSON CLI processor
      "lefthook"     # Git hooks manager
      "node"         # Node.js (current)
      "python@3.14"
      "ripgrep"      # Fast file search (also installed via Nix pkgs)
      "tmux"         # Terminal multiplexer
    ];
    casks = [
      "ghostty" # My terminal
      "opensuperwhisper" # Like whispr, but opensource
      "google-chrome" # My default browser - I know, this drains RAM, but its the internets default
      "spotify" # Gotta listen to my music
      "visual-studio-code" # My main 'IDE', but moreso my main text editor
      "notion" # Where I love to take notes
      # NOTE: you want to also ENABLE Mac to allow Rectangle to move around other apps. You can enable this via Privacy & Settins -> Accessibility -> enable Rectangle
      "rectangle" # What I use to manage my windows around the screen - super helpful, and it is what I have gotten used too
      "todoist-app" # What I use to manage my tasks
    ];
  };
  # Restore Rectangle preferences from dotfiles (replaces any per-machine defaults)
  # Reef is installed from a GitHub release zip (no Homebrew cask yet)
  system.activationScripts.postActivation.text = ''
    if [ -f "/Users/${user}/.dotfiles/home/.config/rectangle/preferences.plist" ]; then
      sudo -u ${user} defaults import com.knollsoft.Rectangle "/Users/${user}/.dotfiles/home/.config/rectangle/preferences.plist"
    fi

    if [ ! -d "/Applications/Reef.app" ]; then
      echo "Installing Reef from GitHub release..."
      LATEST_URL="https://github.com/gouwsxander/Reef/releases/latest/download/Reef.zip"
      curl -fsSL --retry 3 -o /tmp/reef.zip "$LATEST_URL"
      unzip -q /tmp/reef.zip -d /Applications/
      chown -R "${user}:staff" /Applications/Reef.app
      rm /tmp/reef.zip
    fi

    # Ensure Reef is in login items
    LOGIN_ITEMS=$(sudo -u ${user} osascript -e 'tell application "System Events" to get name of every login item' 2>/dev/null)
    if ! echo "$LOGIN_ITEMS" | grep -q "Reef"; then
      sudo -u ${user} osascript -e 'tell application "System Events" to make new login item with properties {name:"Reef", path:"/Applications/Reef.app", hidden:false}'
    fi

    # Restore Reef preferences from dotfiles if available
    if [ -f "/Users/${user}/.config/reef/preferences.plist" ]; then
      sudo -u ${user} defaults import xandergouws.Reef "/Users/${user}/.config/reef/preferences.plist"
    fi
  '';
}
