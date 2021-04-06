{
  description = "The missing link to connect open-source threat intelligence tools.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/3a7674c896847d18e598fa5da23d7426cb9be3d2";
    threatbus-src = { url = "github:tenzir/threatbus"; flake = false; };
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    devshell-flake.url = "github:numtide/devshell";
    vast-flake = { url = "github:GTrunSec/vast/nix-flake"; inputs.nixpkgs-hardenedlinux.follows = "nixpkgs-hardenedlinux"; inputs.flake-utils.follows = "flake-utils"; };
    nixpkgs-hardenedlinux = { url = "github:hardenedlinux/nixpkgs-hardenedlinux"; inputs.flake-utils.follows = "flake-utils"; };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , flake-utils
    , flake-compat
    , devshell-flake
    , vast-flake
    , threatbus-src
    , nixpkgs-hardenedlinux
    }:
    {
      nixosModules = {

        threatbus = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.services.threatbus;
            configFile = pkgs.writeText "config.yml" cfg.settings;
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
                    default = { };
                    description = ''
                      settings = builtins.readFile ./config.example.yaml;
                    '';
                  };

                  dataDir = mkOption {
                    type = types.path;
                    default = "/var/lib/threatbus";
                    description = ''
                      Data directory for threatbus
                    '';
                  };

                  package = mkOption {
                    type = types.package;
                    default = self.outputs.packages."${pkgs.system}".threatbus;
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
                description = "The missing link to connect open-source threat intelligence tools.";
                wantedBy = [ "multi-user.target" ];

                after = [
                  "network-online.target"
                ];

                environment = {
                  THREATBUSDIR = "${cfg.dataDir}";
                };

                script = ''
                  exec ${cfg.package}/bin/threatbus --config=${configFile}
                '';

                serviceConfig = {
                  Restart = "always";
                  RestartSec = "10";
                  ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
                  User = "threatbus";
                  Type = "simple";
                  WorkingDirectory = "${cfg.dataDir}";
                  ReadWritePaths = "${cfg.dataDir}";
                  RuntimeDirectory = "threatbus";
                  CacheDirectory = "threatbus";
                  StateDirectory = "threatbus";
                  SyslogIdentifier = "threatbus";
                  PrivateUsers = true;
                  ProtectSystem = "strict";
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
          };

        threatbus-vast = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.services.threatbus-vast;
            configFile = pkgs.writeText "config.yml" (cfg.settings + cfg.vast_binary);
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
                    default = ''
                      vast_binary: ${vast-flake.packages."x86_64-linux".vast}/bin/vast
                    '';
                  };

                  settings = mkOption {
                    default = { };
                    description = ''
                      settings = builtins.readFile ./config.vast.example.yaml;
                    '';
                  };

                  dataDir = mkOption {
                    type = types.path;
                    default = "/var/lib/threatbus-vast";
                    description = ''
                      Data directory for threatbus vast
                    '';
                  };

                  package = mkOption {
                    type = types.package;
                    default = self.outputs.packages."${pkgs.system}".threatbus-pyvast;
                    description = "The threatbus-vast package.";
                  };
                };
              };

            config = mkIf cfg.enable {
              users.users.threatbus =
                { isSystemUser = true; group = "threatbus"; };

              users.groups.threatbus = { };

              systemd.services.threatbus-vast = {
                enable = true;
                description = "Vast::The missing link to connect open-source threat intelligence tools.";
                wantedBy = [ "multi-user.target" ];

                after = [
                  "network-online.target"
                  "vast.service"
                ];

                script = ''
                  exec ${cfg.package}/bin/pyvast-threatbus --config=${configFile}
                '';

                environment = {
                  PYVAST_THREATBUSDIR = "${cfg.dataDir}";
                };

                serviceConfig = {
                  Restart = "always";
                  RestartSec = "10";
                  Type = "simple";
                  ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
                  User = "threatbus";
                  WorkingDirectory = "${cfg.dataDir}";
                  ReadWritePaths = "${cfg.dataDir}";
                  RuntimeDirectory = "threatbus-vast";
                  CacheDirectory = "threatbus-vast";
                  StateDirectory = "threatbus-vast";
                  SyslogIdentifier = "threatbus-vast";
                  PrivateUsers = true;
                  ProtectSystem = "strict";
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
          };
      };
    }
    //
    (flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ]
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.overlay
            devshell-flake.overlay
            vast-flake.overlay
          ];
          config = { };
        };
      in
      rec {

        devShell = with pkgs; devshell.mkShell {
          packages = [
            threatbus
            broker
            threatbus-pyvast
          ];
          commands = with pkgs; [
            {
              name = "threatbus-inmem";
              command = ''
                threatbus -c config.plugins.yaml
              '';
              category = "plugin";
              help = ''
                test the plugin with threatbus
              '';
            }
            {
              name = "threatbus-vast";
              command = ''
                pyvast-threatbus -c config.vast.example.yaml
              '';
              category = "threatbus";
              help = ''
                test the threatbus with vast
              '';
            }
            {
              name = "get_vast";
              command = ''
                nix build github:GTrunSec/vast/nix-flake#vast
                vast_binary=$(readlink -f ./result/bin/vast)
                sed -i "s|/nix/store/.*./bin/vast|$vast_binary|" ./config.vast.example.yaml
                echo $vast_binary
              '';
              help = "print vast executable path";
              category = "vast";
            }

            {
              name = "threatbus-test";
              command = ''
                threatbus -c config.example.yaml
              '';
              category = "threatbus";
              help = ''
                test the config.yaml with threatbus
              '';
            }
          ];
        };

        apps = {
          threatbus = { type = "app"; program = "${pkgs.threatbus}/bin/threatbus"; };
          threatbus-pyvast = { type = "app"; program = "${pkgs.threatbus-pyvast}/bin/pyvast-threatbus"; };
        };

        packages = flake-utils.lib.flattenTree {
          threatbus = pkgs.threatbus;
          broker = pkgs.broker;
          threatbus-pyvast = pkgs.threatbus-pyvast;
          vast = vast-flake.packages.${system}.vast;
        };

        hydraJobs = {
          inherit packages;
        };

        defaultPackage = pkgs.threatbus;
      }
      )
    ) //
    {
      overlay = final: prev:
        let
          version = "2021.3.25";
        in
        {

          broker = prev.callPackage "${nixpkgs-hardenedlinux}/pkgs/broker" { };

          threatbus-pyvast = with final;
            (python3Packages.buildPythonPackage {
              pname = "threatbus_pyvast";
              inherit version;

              src = threatbus-src;
              preConfigure = ''
                cd apps/vast
              '';

              doCheck = false;

              propagatedBuildInputs = with python3Packages; [
                stix2
                stix2-patterns
                confuse
                black
                pyzmq
                threatbus-zmq-app
                coloredlogs
                pyvast
                threatbus
              ];

              postPatch = ''
                substituteInPlace apps/vast/setup.py \
                --replace "threatbus >= ${version}" "" \
                --replace "threatbus-zmq-app >= 2020.12.16, < 2021.2.24" ""
              '';

              meta = with lib; {
                description = "The missing link to connect open-source threat intelligence tools.";
                homepage = "https://github.com/tenzir/threatbus";
                platforms = platforms.unix;
                license = licenses.bsd3; # BSD 3-Clause variant
              };
            });

          stix2-patterns = with final;
            (python3Packages.buildPythonPackage rec {
              pname = "stix2-patterns";
              version = "1.3.2";
              src = python3Packages.fetchPypi {
                inherit pname version;
                sha256 = "sha256-F0/lMC0sMiMgUDOvmHdUEyqepFqfjgiu+vvgVJyInqQ=";
              };
              doCheck = false;
              propagatedBuildInputs = with python3Packages; [
                antlr4-python3-runtime
                six
              ];
            });

          stix2 = with final;
            (python3Packages.buildPythonPackage rec {
              pname = "stix2";
              version = "2.1.0";
              src = python3Packages.fetchPypi {
                inherit pname version;
                sha256 = "sha256-FcnPWZ9cQxJOdv5xuIPkkY9vTPZbCExY7GS2GA9FyTg=";
              };
              doCheck = false;
              propagatedBuildInputs = with python3Packages; [
                stix2-patterns
                requests
                pytz
                simplejson
              ];
            });

          threatbus-zmq-app = with final; (python3Packages.buildPythonPackage rec {
            pname = "threatbus_zmq_app";
            inherit version;
            src = threatbus-src;

            preConfigure = ''
              cd plugins/apps/threatbus_zmq_app
            '';

            doCheck = false;

            propagatedBuildInputs = with python3Packages; [
              stix2
              stix2-patterns
              python-dateutil
              pyzmq
            ];

            postPatch = ''
              substituteInPlace plugins/apps/threatbus_zmq_app/setup.py \
              --replace "threatbus>=${version}" ""
            '';

            meta = with lib; {
              description = "The missing link to connect open-source threat intelligence tools.";
              homepage = "https://github.com/tenzir/threatbus";
              platforms = platforms.unix;
              license = licenses.bsd3; # BSD 3-Clause variant
            };
          });

          threatbus = with final;
            (
              let
                threatbus-zeek = python3Packages.buildPythonPackage rec {
                  pname = "threatbus_zeek";
                  inherit version;
                  src = threatbus-src;

                  preConfigure = ''
                    cd plugins/apps/threatbus_zeek
                  '';

                  doCheck = false;

                  propagatedBuildInputs = with python3Packages; [
                    stix2
                    stix2-patterns
                  ];

                  postPatch = ''
                    substituteInPlace plugins/apps/threatbus_zeek/setup.py \
                    --replace "threatbus >= ${version}" ""
                  '';

                  meta = with lib; {
                    description = "The missing link to connect open-source threat intelligence tools.";
                    homepage = "https://github.com/tenzir/threatbus";
                    platforms = platforms.unix;
                    license = licenses.bsd3; # BSD 3-Clause variant
                  };
                };

                threatbus-inmem = python3Packages.buildPythonPackage rec {
                  pname = "threatbus_inmem";
                  inherit version;
                  src = threatbus-src;
                  preConfigure = ''
                    cd plugins/backbones/threatbus_inmem
                  '';
                  doCheck = false;
                  propagatedBuildInputs = with python3Packages; [
                    stix2
                    stix2-patterns
                  ];

                  postPatch = ''
                    substituteInPlace plugins/backbones/threatbus_inmem/setup.py \
                    --replace "threatbus >= 2021.2.24" ""
                  '';

                  meta = with lib; {
                    description = "The missing link to connect open-source threat intelligence tools.";
                    homepage = "https://github.com/tenzir/threatbus";
                    platforms = platforms.unix;
                    license = licenses.bsd3; # BSD 3-Clause variant
                  };
                };

                threatbus-file-benchmark = python3Packages.buildPythonPackage rec {
                  pname = "threatbus_file_benchmark";
                  inherit version;
                  src = threatbus-src;


                  preConfigure = ''
                    cd plugins/backbones/file_benchmark
                  '';

                  doCheck = false;

                  propagatedBuildInputs = with python3Packages; [
                    stix2
                    stix2-patterns
                  ];

                  postPatch = ''
                    substituteInPlace plugins/backbones/file_benchmark/setup.py \
                    --replace "threatbus >= 2021.2.24" ""
                  '';

                  meta = with lib; {
                    description = "The missing link to connect open-source threat intelligence tools.";
                    homepage = "https://github.com/tenzir/threatbus";
                    platforms = platforms.unix;
                    license = licenses.bsd3; # BSD 3-Clause variant
                  };
                };

              in
              python3Packages.buildPythonPackage rec {
                pname = "threatbus";
                inherit version;
                src = threatbus-src;

                doCheck = false;

                propagatedBuildInputs = with python3Packages;[
                  stix2
                  confuse
                  coloredlogs
                  python-dateutil
                  black
                  pluggy
                  threatbus-zeek
                  threatbus-inmem
                  threatbus-file-benchmark
                  threatbus-zmq-app
                  final.broker
                ];
                postPatch = ''
              '';
                meta = with lib; {
                  description = "The missing link to connect open-source threat intelligence tools.";
                  homepage = "https://github.com/tenzir/threatbus";
                  platforms = platforms.unix;
                  license = licenses.bsd3; # BSD 3-Clause variant
                };
              }
            );
        };
    };
}
