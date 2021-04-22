{ config, lib, pkgs, ... }:

{
  services.threatbus-vast = {
    enable = true;
    vast_endpoint = "127.0.0.1:42000";
    settings = builtins.readFile ./config.vast.deploy.yaml;
  };

  services.threatbus = {
    enable = true;
    settings = builtins.readFile ./config.deploy.yaml;
  };

  services.vast = {
    enable = true;
    endpoint = "127.0.0.1:4000";
    settings = {
      log-file = "/var/lib/vast/server.log";
    };
  };
}
