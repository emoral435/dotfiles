{ config, pkgs, user, treehouse, ... }:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    lazygit
    neovim
    treehouse.packages.${pkgs.system}.default
    # the font everything renders in
    nerd-fonts.hack
  ];

  programs.zsh = {
    enable = false;  # disabled -- .zshrc managed via symlink below (handles oh-my-zsh + p10k itself)
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  # home.file.".config/wezterm".source =
  #   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";

  # Ghostty terminal
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/ghostty/config";
    force = true;
  };

  # VSCode: remove pre-existing directories to prevent ln from failing to replace them with symlinks
  home.activation.removeVSCodeDirs = config.lib.dag.entryBefore ["linkGeneration"] ''
    rm -rf "${config.home.homeDirectory}/Library/Application Support/Code/User/settings.json"
    rm -rf "${config.home.homeDirectory}/Library/Application Support/Code/User/keybindings.json"
    rm -rf "${config.home.homeDirectory}/Library/Application Support/Code/User/snippets"
  '';

  # VSCode: install extensions that dotfiles depend on
  home.activation.installVSCodeExtensions = config.lib.dag.entryAfter ["linkGeneration"] ''
    if command -v code >/dev/null 2>&1; then
      code --install-extension akamud.vscode-theme-onedark --force 2>/dev/null || true
    fi
  '';

  # VSCode
  home.file."Library/Application Support/Code/User/settings.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/Code/User/settings.json";
    force = true;
  };
  home.file."Library/Application Support/Code/User/keybindings.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/Code/User/keybindings.json";
    force = true;
  };
  home.file."Library/Application Support/Code/User/snippets" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/Code/User/snippets";
    force = true;
  };

  # Neovim
  home.file.".config/nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
    force = true;
  };

  # Zsh / Powerlevel10k
  home.file.".zshrc" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/zsh/.zshrc";
    force = true;
  };
  home.file.".p10k.zsh" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/zsh/.p10k.zsh";
    force = true;
  };

  # Herdr
   home.file.".config/herdr/config.toml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr/config.toml";
    force = true;
  };
}
