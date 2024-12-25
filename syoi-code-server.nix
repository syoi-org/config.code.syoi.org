{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/syoi-code-server.nix
  ];

  services.syoi-code-server = {
    enable = true;
    instances = {
      stommydx = { createUser = false; };
      jackylkk2003 = { };
      longhuen = { };
      azidoazideazide = { };
      happychau = { };
      htlam = { };
      chemistrying = { };
      notming = { };
    };
    domain = "code.syoi.org";
    defaultHandler = ''
      redir https://github.com/syoi-org/code.syoi.org
    '';
  };

  services.caddy = {
    enable = true;
    user = "root";
    group = "code";
    globalConfig = ''
      default_bind unix//srv/code/caddy.sock|0220
    '';
    virtualHosts = {
      "http://leaderboard.syoi.org" = {
        extraConfig = ''
          reverse_proxy http://chemistrying.ddns.net
        '';
      };
      #      "http://tft24.syoi.org" = {
      #        extraConfig = ''
      #          reverse_proxy http://localhost:28080
      #        '';
      #      };
    };
  };

  services.cloudflared = {
    enable = true;
    user = "code";
    group = "code";
    tunnels = {
      code-server = {
        ingress = {
          "code.syoi.org" = "unix:/srv/code/caddy.sock";
          "ssh.syoi.org" = "ssh://localhost:22";
          "leaderboard.syoi.org" = "unix:/srv/code/caddy.sock";
          # "tft24.syoi.org" = "unix:/srv/code/caddy.sock";
        };
        default = "http_status:404";
        credentialsFile = config.sops.secrets.tunnel-credentials.path;
      };
    };
  };

  sops = {
    age = {
      sshKeyPaths = [ ]; # prevent import error during first install
      keyFile = "/etc/sops-nix/key.txt";
      generateKey = true;
    };
    gnupg.sshKeyPaths = [ ]; # prevent import error during first install
    secrets = {
      tunnel-credentials = {
        sopsFile = ./secrets/tunnel-credentials.json;
        format = "json";
        owner = "code";
        group = "code";
        restartUnits = [ "cloudflared-tunnel-code-server.service" ];
      };
    };
  };

  users.users.code = {
    isSystemUser = true;
    description = "SYOI Code Server System User";
    group = "code";
    home = "/srv/code";
    homeMode = "770";
    createHome = true;
  };
  users.groups.code = { };

  # temporarily allow nodejs 16 for code-server
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-16.20.2"
  ];
}
