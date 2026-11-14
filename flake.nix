{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-homebrew }:
    let
      # `dot` reads ~/.config/dotfiles/machine and passes it in as DOT_* variables.
      # The flake holds no user names, so every Mac uses the same config.
      fromDot = name:
        let value = builtins.getEnv name;
        in if value == "" then throw "${name} is not set. Run ./dot, not nix or darwin-rebuild." else value;

      machine = {
        user = fromDot "DOT_USER";
        home = fromDot "DOT_HOME";
        kind = fromDot "DOT_KIND";
        arch = fromDot "DOT_ARCH";
      };
      user = machine.user;
    in
    {
      darwinConfigurations.this = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user machine; };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # A real file or directory where a link must go is moved aside with this suffix.
            home-manager.backupFileExtension = "before-dotfiles";
            home-manager.extraSpecialArgs = { inherit user machine; };
            home-manager.users.${user} = import ./home.nix;
          }
        ];
      };
    };
}
