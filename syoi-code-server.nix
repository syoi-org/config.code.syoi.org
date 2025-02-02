{
  config,
  lib,
  ...
}:

{
  imports = [
    ./modules/syoi-code-server.nix
    ./backup.nix
  ];

  services.syoi-code-server = {
    enable = true;
    instances = {
      stommydx = {
        createUser = false;
      };
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
      "http://git.syoi.org" = {
        extraConfig = "reverse_proxy http://localhost:${builtins.toString config.services.forgejo.settings.server.HTTP_PORT}";
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
          "git.syoi.org" = "unix:/srv/code/caddy.sock";
          "ssh.syoi.org" = "ssh://localhost:22";
          "leaderboard.syoi.org" = "unix:/srv/code/caddy.sock";
          # "tft24.syoi.org" = "unix:/srv/code/caddy.sock";
        };
        default = "http_status:404";
        credentialsFile = config.sops.secrets.tunnel-credentials.path;
      };
    };
  };

  services.forgejo = {
    enable = true;
    database = {
      type = "sqlite3";
    };
    secrets = {
      storage = {
        MINIO_ENDPOINT = config.sops.secrets.r2-endpoint.path;
        MINIO_ACCESS_KEY_ID = config.sops.secrets.r2-access-key.path;
        MINIO_SECRET_ACCESS_KEY = config.sops.secrets.r2-secret-key.path;
      };
    };
    settings = {
      server = {
        DOMAIN = "git.syoi.org";
        ROOT_URL = "https://${config.services.forgejo.settings.server.DOMAIN}/";
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
      storage = {
        STORAGE_TYPE = "minio";
        MINIO_BUCKET = "forgejo-data";
        MINIO_USE_SSL = true;
        MINIO_CHECKSUM_ALGORITHM = "md5"; # for compatibility with R2
      };
    };
  };

  services.litestream = {
    enable = true;
    environmentFile = config.sops.templates.litestream.path;
    settings = {
      access-key-id = "$LITESTREAM_ACCESS_KEY_ID";
      secret-access-key = "$LITESTREAM_SECRET_ACCESS_KEY";
      dbs = [
        {
          path = config.services.forgejo.database.path;
          replicas = [
            {
              type = "s3";
              endpoint = "$LITESTREAM_S3_ENDPOINT";
              bucket = "forgejo-litestream";
              force-path-style = true;
            }
          ];
        }
      ];
    };
  };

  systemd.services.litestream.serviceConfig = {
    User = lib.mkForce config.services.forgejo.user;
    Group = lib.mkForce config.services.forgejo.group;
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
      r2-access-key = {
        sopsFile = ./secrets/r2.json;
        key = "access_key";
        format = "json";
        owner = "forgejo";
        group = "forgejo";
        restartUnits = [ "forgejo.service" ];
      };
      r2-secret-key = {
        sopsFile = ./secrets/r2.json;
        key = "secret_key";
        format = "json";
        owner = "forgejo";
        group = "forgejo";
        restartUnits = [ "forgejo.service" ];
      };
      r2-endpoint = {
        sopsFile = ./secrets/r2.json;
        key = "endpoint";
        format = "json";
        owner = "forgejo";
        group = "forgejo";
        restartUnits = [ "forgejo.service" ];
      };
    };
    templates = {
      litestream = {
        content = ''
          LITESTREAM_S3_ENDPOINT=${config.sops.placeholder.r2-endpoint}
          LITESTREAM_ACCESS_KEY_ID=${config.sops.placeholder.r2-access-key}
          LITESTREAM_SECRET_ACCESS_KEY=${config.sops.placeholder.r2-secret-key}
        '';
        owner = "forgejo";
        group = "forgejo";
        restartUnits = [ "litestream.service" ];
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

  # temporarily allow insecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "litestream-0.3.13" # latest version as of 2024-12-27
  ];
}
