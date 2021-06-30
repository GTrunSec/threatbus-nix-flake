{
  description = "The missing link to connect open-source threat intelligence tools.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/release-21.05";
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    devshell-flake.url = "github:numtide/devshell";
    vast2nix = { url = "github:GTrunSec/vast2nix"; inputs.nixpkgs-hardenedlinux.follows = "nixpkgs-hardenedlinux"; inputs.flake-utils.follows = "flake-utils"; };
    nixpkgs-hardenedlinux = { url = "github:hardenedlinux/nixpkgs-hardenedlinux"; };
    nvfetcher = {
      url = "github:berberman/nvfetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , flake-utils
    , flake-compat
    , devshell-flake
    , vast2nix
    , nixpkgs-hardenedlinux
    , nvfetcher
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
            configFile = pkgs.writeText "config.yml" (cfg.settings + cfg.vast_binary + cfg.vast_endpoint);
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

                  vast_endpoint = mkOption {
                    type = types.str;
                    default = "vast: 127.0.0.1:42000";
                    description = "Vast listening host";
                  };

                  vast_binary = mkOption {
                    type = types.str;
                    default = ''
                      vast_binary: ${vast2nix.packages."${pkgs.system}".vast-release}/bin/vast
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
            vast2nix.overlay
            nixpkgs-hardenedlinux.overlay
            nvfetcher.overlay
          ];
          config = { };
        };
      in
      rec {

        devShell = with pkgs; devshell.mkShell {
          imports = [ (devshell.importTOML ./nix/commands.toml) ];
          packages = [
            threatbus
            threatbus-pyvast
            nixpkgs-fmt
          ];
          commands = with pkgs; [
            {
              name = pkgs.nvfetcher-bin.pname;
              help = pkgs.nvfetcher-bin.meta.description;
              command = "cd $DEVSHELL_ROOT/nix; ${pkgs.nvfetcher-bin}/bin/nvfetcher -c ./sources.toml --no-output $@; nixpkgs-fmt _sources";
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
          ];
        };

        apps = {
          threatbus = { type = "app"; program = "${pkgs.threatbus}/bin/threatbus"; };
          threatbus-latest = { type = "app"; program = "${pkgs.threatbus-latest}/bin/threatbus"; };
          threatbus-pyvast-latest = { type = "app"; program = "${pkgs.threatbus-pyvast-latest}/bin/pyvast-threatbus"; };
          threatbus-pyvast = { type = "app"; program = "${pkgs.threatbus-pyvast}/bin/pyvast-threatbus"; };
        };

        packages = flake-utils.lib.flattenTree {
          threatbus = pkgs.threatbus;
          threatbus-latest = pkgs.threatbus-latest;
          threatbus-zeek = pkgs.threatbus-zeek;
          broker = pkgs.broker;
          threatbus-pyvast-latest = pkgs.threatbus-pyvast-latest;
          threatbus-pyvast = pkgs.threatbus-pyvast;
          vast-release = vast2nix.packages.${system}.vast-release;
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
          plugin-version = "2021.5.27";
        in
        {
          threatbus-sources = prev.callPackage ./nix/_sources/generated.nix { };

          threatbus-zeek = with final; stdenv.mkDerivation rec {
            inherit (final.threatbus-sources.threatbus-latest) src pname version;
            name = "threatbus-zeek";
            phases = [ "installPhase" ];
            buildInputs = [ ];
            installPhase = ''
              runHook preInstall
              mkdir -p $out/scripts
              cp -r $src/apps/zeek/* $out/scripts
              runHook postInstall
            '';
          };

          threatbus-latest = with final; (final.threatbus.overrideAttrs (old: rec {
            inherit (final.threatbus-sources.threatbus-latest) src pname version;
            propagatedBuildInputs = with final.python3Packages; [
              stix2
              dynaconf
              coloredlogs
              python-dateutil
              black
              pluggy
              (threatbus-zeek-plugin.overrideAttrs (old: { inherit (final.threatbus-sources.threatbus-latest) src version; plugin-version = version; }))
              (threatbus-inmem.overrideAttrs (old: { inherit (final.threatbus-sources.threatbus-latest) src version; plugin-version = version; }))
              (threatbus-file-benchmark.overrideAttrs (old: { inherit (final.threatbus-sources.threatbus-latest) src version; plugin-version = version; }))
              (threatbus-zmq-app.overrideAttrs (old: { inherit (final.threatbus-sources.threatbus-latest) src version; plugin-version = version; }))
              final.broker
            ];
          }));

          threatbus-pyvast-latest = with final; (final.threatbus-pyvast.overrideAttrs (old: {
            inherit (final.threatbus-sources.threatbus-latest) src pname;
            propagatedBuildInputs = with final.python3Packages; [
              stix2-patterns
              dynaconf
              black
              pyzmq
              coloredlogs
              pyvast
              threatbus-latest
            ];
          }));


          threatbus-pyvast = with final;
            (python3Packages.buildPythonPackage rec {
              pname = "threatbus-pyvast";
              inherit (final.threatbus-sources.threatbus-release) src version;
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
                license = "BSD-3-Clause";
              };
            });

          dynaconf = with final;
            (python3Packages.buildPythonPackage rec {
              inherit (final.threatbus-sources.dynaconf) src version pname;
              doCheck = false;
              propagatedBuildInputs = with python3Packages; [
                setuptools
              ];
            });

          stix2-patterns = with final;
            (python3Packages.buildPythonPackage rec {
              inherit (final.threatbus-sources.stix2-patterns) src version pname;
              doCheck = false;
              propagatedBuildInputs = with python3Packages; [
                antlr4-python3-runtime
                six
              ];
            });

          stix2 = with final;
            (python3Packages.buildPythonPackage rec {
              inherit (final.threatbus-sources.stix2) src version pname;
              doCheck = false;
              propagatedBuildInputs = with python3Packages; [
                stix2-patterns
                requests
                pytz
                simplejson
              ];
            });

          threatbus-zmq-app = with final; (python3Packages.buildPythonPackage rec {
            pname = "threatbus-zmq-app";
            inherit (final.threatbus-sources.threatbus-release) src version;

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
              --replace "threatbus>=${plugin-version}" ""
            '';

            meta = with lib; {
              description = "The missing link to connect open-source threat intelligence tools.";
              homepage = "https://github.com/tenzir/threatbus";
              platforms = platforms.unix;
              license = "BSD-3-Clause";
            };
          });

          threatbus-zeek-plugin = with final; python3Packages.buildPythonPackage rec {
            pname = "threatbus_zeek";
            inherit (final.threatbus-sources.threatbus-release) src version;

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
              --replace "threatbus >= ${plugin-version}" ""
            '';

            meta = with lib; {
              description = "The missing link to connect open-source threat intelligence tools.";
              homepage = "https://github.com/tenzir/threatbus";
              platforms = platforms.unix;
              license = "BSD-3-Clause"; # BSD 3-Clause variant
            };
          };

          threatbus-inmem = with final; python3Packages.buildPythonPackage rec {
            pname = "threatbus_inmem";
            inherit (final.threatbus-sources.threatbus-release) src version;
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
              --replace "threatbus >= ${plugin-version}" ""
            '';

            meta = with lib; {
              description = "The missing link to connect open-source threat intelligence tools.";
              homepage = "https://github.com/tenzir/threatbus";
              platforms = platforms.unix;
              license = "BSD-3-Clause";
            };
          };

          threatbus-file-benchmark = with final; python3Packages.buildPythonPackage rec {
            pname = "threatbus_file_benchmark";
            inherit (final.threatbus-sources.threatbus-release) src version;


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
              license = "BSD-3-Clause";
            };
          };

          threatbus = with final;
            python3Packages.buildPythonPackage rec {
              pname = "threatbus";
              inherit (final.threatbus-sources.threatbus-release) src version;

              doCheck = false;

              propagatedBuildInputs = with python3Packages;[
                stix2
                confuse
                coloredlogs
                python-dateutil
                black
                pluggy
                threatbus-zeek-plugin
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
                license = "BSD-3-Clause";
              };
            };
        };
    };
}
