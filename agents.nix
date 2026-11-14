{ config, lib, ... }:
let
  home = config.home.homeDirectory;
  dotfiles = "${home}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";

  # Every folder in agents/skills is one skill. LICENSES holds third-party license texts.
  skillNames = builtins.attrNames
    (lib.filterAttrs (name: type: type == "directory" && name != "LICENSES") (builtins.readDir ./agents/skills));
  skillLinks = root: lib.listToAttrs (map (name: {
    name = "${root}/${name}";
    value = { source = link "agents/skills/${name}"; force = true; };
  }) skillNames);

  piExtensions = [ "quiet-tools.ts" "schedule-wakeup.ts" "calm" ];
  piExtensionLinks = lib.listToAttrs (map (name: {
    name = ".pi/agent/extensions/${name}";
    value = { source = link "pi/extensions/${name}"; force = true; };
  }) piExtensions);

  # `dot sync-agents` writes this file: the repo rules plus ~/.config/agents/work.md when present.
  # It lives outside the repo, so the work overlay can never be committed.
  generatedAgents = config.lib.file.mkOutOfStoreSymlink "${home}/.config/agents/AGENTS.md";
in
{
  home.file = skillLinks ".agents/skills"
    // skillLinks ".pi/agent/skills"
    // skillLinks ".claude/skills"
    // piExtensionLinks
    // {
      "AGENTS.md" = { source = generatedAgents; force = true; };
      ".codex/AGENTS.md" = { source = generatedAgents; force = true; };
      ".claude/CLAUDE.md" = { source = generatedAgents; force = true; };
    };

  # On every switch: rebuild the generated AGENTS.md and merge pi settings.
  home.activation.dotfilesAgents = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    "${dotfiles}/dot" sync-agents || true
  '';
}
