{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.threatbus;
  format = pkgs.formats.yaml { };
  configFile = format.generate "config.yml" cfg.settings;
in
{
  options =
    {
      services.threatbus = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable threatbus endpoint
          '';
        };

        settings = mkOption {
          type = types.attrsOf types.anything;
          default = { };
        };

        package = mkOption {
          type = types.package;
          default = pkgs.threatbus;
          description = "The threatbus package.";
        };
      };
    };

  config = mkIf cfg.enable {
    users.users.threatbus =
      { isSystemUser = true; group = "threatbus"; };

    users.groups.threatbus = { };

    systemd.services.threatbus = {
      enable = true;
      description = "Visibility Across Space and Time";
      wantedBy = [ "multi-user.target" ];

      after = [
        "network-online.target"
        #"zeek.service
      ];

      confinement = {
        enable = true;
        binSh = null;
      };

      script = ''
        exec ${cfg.package}/bin/threatbus --config=${configFile}
      '';

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID && ${pkgs.coreutils}/bin/rm threatbus.db/pid.lock";
        User = "threatbus";
        WorkingDirectory = "/var/lib/threatbus";
        ReadWritePaths = "/var/lib/threatbus";
        RuntimeDirectory = "threatbus";
        CacheDirectory = "threatbus";
        StateDirectory = "threatbus";
        SyslogIdentifier = "threatbus";
        PrivateUsers = true;
        DynamicUser = mkForce false;
        PrivateTmp = true;
        ProtectHome = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
      };
    };
  };
}
