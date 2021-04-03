{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.threatbus-vast;
  format = pkgs.formats.yaml { };
  configFile = format.generate "config.yml" cfg.settings // vast_binary;
in
{
  options =
    {
      services.threatbus-vast = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable threatbus-vast endpoint
          '';
        };

        vast_binary = mkOption {
          type = types.string;
          default = ''
            vast_binary : ${vast}/bin/vast
          '';
        };
        settings = mkOption {
          type = types.attrsOf types.anything;
          default = { };
        };
        package = mkOption {
          type = types.package;
          default = pkgs.threatbus-vast;
          description = "The threatbus-vast package.";
        };
      };
    };

  config = mkIf cfg.enable {
    users.users.threatbus =
      { isSystemUser = true; group = "vast"; };

    users.groups.vast = { };

    systemd.services.threatbus-vast = {
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
        exec ${cfg.package}/bin/threatbus-pyvast --config=${configFile}
      '';

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID && ${pkgs.coreutils}/bin/rm threatbus-vast.db/pid.lock";
        User = "threatbus";
        Group = "vast";
        WorkingDirectory = "/var/lib/threatbus-vast";
        ReadWritePaths = "/var/lib/threatbus-vast";
        RuntimeDirectory = "threatbus-vast";
        CacheDirectory = "threatbus-vast";
        StateDirectory = "threatbus-vast";
        SyslogIdentifier = "threatbus-vast";
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
