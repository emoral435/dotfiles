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
}
