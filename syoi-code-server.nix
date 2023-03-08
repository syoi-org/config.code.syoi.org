{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/syoi-code-server.nix
  ];

  services.syoi-code-server = {
    enable = true;
    instances = {
      stommydx = { createUser = false; };
    };
    domain = "code-v2.syoi.org"
  };

  services.cloudflared = {
    enable = true;
    tunnel = {
      code-server = {
        ingress = {
          "code-v2.syoi.org" = "http://localhost:80";
        };
      };
    };
  };

  sops = {
    age = {
      sshKeyPaths = []; # prevent import error during first install
      keyFile = "/etc/sops-nix/key.txt";
      generateKey = true;
    };
    gnupg.sshKeyPaths = []; # prevent import error during first install
    secrets = {
      tunnel-credentials = {
        sopsFile = ./secrets/tunnel-credentials.json;
        format = "json";
      };
    };
  };
}
