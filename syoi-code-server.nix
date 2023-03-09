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
    domain = "code-v2.syoi.org";
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      code-server = {
        ingress = {
          "code-v2.syoi.org" = "http://localhost:80";
          "ssh-v2.syoi.org" = "ssh://localhost:22";
        };
        default = "http_status:404";
        credentialsFile = config.sops.secrets.tunnel-credentials.path;
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
        owner = "cloudflared";
        group = "cloudflared";
        restartUnits = [ "cloudflared-tunnel-code-server.service" ];
      };
    };
  };
}
