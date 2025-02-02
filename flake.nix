{
  description = "NixOS Configuration for code.syoi.org";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    deploy-rs.url = "github:serokell/deploy-rs";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      deploy-rs,
      sops-nix,
      treefmt-nix,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      defaultSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachSystem = lib.genAttrs defaultSystems;
      treefmtEval = eachSystem (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
    in
    {
      nixosConfigurations = {
        code = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            sops-nix.nixosModules.sops
          ];
        };
      };

      deploy.nodes = {
        "code.syoi.org" = {
          hostname = "ssh.syoi.org";
          profiles.system = {
            sshUser = "stommydx";
            user = "root";
            interactiveSudo = true;
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.code;
          };
        };
      };

      formatter = eachSystem (system: treefmtEval.${system}.config.build.wrapper);
    };
}
