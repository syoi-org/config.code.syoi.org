{ lib, pkgs, config, ... }:

let
  cfg = config.services.syoi-code-server;

  instancesOptions = { name, ... }: {
    options = {
      user = lib.mkOption {
        type = lib.types.str;
        example = "alice";
        default = "${name}";
        description = lib.mdDoc ''
          User account under which code-server runs
        '';
      };
      createUser = lib.mkOption {
        type = lib.types.bool;
        example = false;
        default = true;
        description = lib.mdDoc ''
          Whether a new UNIX user account should be created
        '';
      };
    };
  };

  # assign port consecutively from cfg.port to cfg.port + no_of_instances - 1
  instancesCfg = lib.listToAttrs
    (lib.imap0
      (i: v: lib.nameValuePair v.name (v.value // {
        port = cfg.port + i;
      }))
      (lib.mapAttrsToList
        (k: v: lib.nameValuePair k v)
        cfg.instances));
in
{
  options.services.syoi-code-server = {
    enable = lib.mkEnableOption "management of syoi code-server";

    package = lib.mkOption {
      default = pkgs.code-server;
      defaultText = "pkgs.code-server";
      description = lib.mdDoc "Which code-server derivation to use.";
      type = lib.types.package;
    };

    domain = lib.mkOption {
      default = "localhost";
      description = lib.mdDoc "The domain name pointing to code-server.";
      type = lib.types.str;
    };

    extraArguments = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--disable-telemetry" ];
      description = lib.mdDoc "Additional arguments that passed to code-server";
      example = ''[ "--verbose" ]'';
    };

    instances = lib.mkOption {
      default = { };
      type = with lib.types; attrsOf (submodule instancesOptions);
      description = lib.mdDoc "code-server instances to be created automatically by the system.";
    };

    defaultHandler = lib.mkOption {
      default = "";
      description = lib.mdDoc "Default caddy handler if user is not specified or not found.";
      type = lib.types.str;
    };
  };


  config = lib.mkIf cfg.enable
    {
      services.caddy = {
        enable = true;
        user = "root";
        group = "code";
      };
      systemd.tmpfiles.settings = {
        "50-syoi-code-server" = {
          "/run/code-server" = {
            d = {
              user = "code";
              group = "code";
              mode = "0777";
            };
          };
        };
      };
      systemd.services =
        lib.mapAttrs'
          (name: instanceCfg: lib.nameValuePair "code-server@${name}" {
            description = "VSCode server";
            wantedBy = [ "multi-user.target" ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            serviceConfig = {
              ExecStart = "${cfg.package}/bin/code-server --socket /run/code-server/${name}.sock --socket-mode 200 " + lib.escapeShellArgs cfg.extraArguments;
              Restart = "on-failure";
              User = instanceCfg.user;
            };
          })
          instancesCfg;
      services.caddy.virtualHosts = {
        "http://${cfg.domain}" = {
          extraConfig = (lib.concatStrings (lib.mapAttrsToList
            (name: instanceCfg: ''
              handle_path /${instanceCfg.user}/* {
                reverse_proxy unix//run/code-server/${name}.sock
              }

              handle /${instanceCfg.user} {
                redir http://${cfg.domain}/${instanceCfg.user}/
              }


            '')
            instancesCfg)) + ''
            handle {
              ${cfg.defaultHandler}
            }
          '';
        };
      };
      users.users = lib.mapAttrs'
        (name: instanceCfg: lib.nameValuePair instanceCfg.user (lib.mkIf instanceCfg.createUser {
          isNormalUser = true;
          shell = pkgs.zsh;
        }))
        instancesCfg;
    };
}

