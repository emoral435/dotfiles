{ user, ... }:
{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;
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
      "node@16"      # Node.js 16
      "node"         # Node.js (current)
      "python@3.11"  # Python 3.11
      "python@3.13"  # Python 3.13
      "python@3.14"  # Python 3.14
      "ripgrep"      # Fast file search (also installed via Nix pkgs)
      "terraform"    # Infrastructure as code
      "tmux"         # Terminal multiplexer
    ];
    casks = [
      "ghostty" # My terminal
      "opensuperwhisper" # Like whispr, but opensource
      "google-chrome" # My default browser - I know, this drains RAM, but its the internets default
      "spotify" # Gotta listen to my music
      "visual-studio-code" # My main 'IDE', but moreso my main text editor
      "notion" # Where I love to take notes
      "rectangle" # What I use to manage my windows around the screen - super helpful, and it is what I have gotten used too
      "todoist-app" # What I use to manage my tasks
    ];
  };
}
