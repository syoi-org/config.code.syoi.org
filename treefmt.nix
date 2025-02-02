{ ... }:

{

  projectRootFile = "flake.nix";

  programs.mdformat = {
    enable = true;
    settings.number = true;
  };
  programs.nixfmt.enable = true;
  programs.yamlfmt.enable = true;

}
