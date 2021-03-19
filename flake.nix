{
  description = "The missing link to connect open-source threat intelligence tools.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/3a7674c896847d18e598fa5da23d7426cb9be3d2";
    threatbus-src = { url = "github:tenzir/threatbus"; flake = false; };
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    devshell-flake.url = "github:numtide/devshell";
    mach-nix = { url = "github:DavHau/mach-nix"; inputs.nixpkgs.follows = "nixpkgs"; };
    nixpkgs-hardenedlinux = { url = "github:hardenedlinux/nixpkgs-hardenedlinux"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, flake-compat, devshell-flake, mach-nix, threatbus-src, nixpkgs-hardenedlinux }:
    { }
    //
    (flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlay
              devshell-flake.overlay
            ];
            config = { };
          };
        in
        rec {

          devShell = with pkgs; devshell.mkShell {
            packages = [
              threatbus
              broker
              vast
            ];
            commands = with pkgs; [
              {
                name = "threatbus-inmem";
                command = ''
                  threatbus -c config.plugins.yaml
                '';
                category = "plugins";
                help = ''
                  test the plugins with threatbus
                '';
              }

              {
                name = "threatbus-configFile";
                command = ''
                  threatbus -c config.example.yaml
                '';
                category = "config.yaml";
                help = ''
                  test the config.yaml with threatbus
                '';
              }
            ];
          };

          apps = {
            threatbus = { type = "app"; program = "${pkgs.threatbus}/bin/threatbus"; };
            threatbus-vast = { type = "app"; program = "${pkgs.threatbus-vast}/bin/pyvast-threatbus"; };
          };

          packages = inputs.flake-utils.lib.flattenTree
            rec {
              threatbus = pkgs.threatbus;
              broker = pkgs.broker;
              threatbus-vast = pkgs.threatbus-vast;
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
          version = "2021.02.24";

          machLib = import mach-nix
            {
              pypiDataRev = "2205d5a0fc9b691e7190d18ba164a3c594570a4b";
              pypiDataSha256 = "1aaylax7jlwsphyz3p73790qbrmva3mzm56yf5pbd8hbkaavcp9g";
              python = "python38";
            };

          python-packages-custom = machLib.mkPython rec {
            requirements = ''
              pyvast==2021.2.24
            '';
          };
        in
        {

          broker = prev.callPackage "${nixpkgs-hardenedlinux}/pkgs/broker" { };

          threatbus-vast = with final;
            (python3Packages.buildPythonPackage {
              pname = "threatbus_vast";
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
                python-packages-custom
                (threatbus.overridePythonAttrs (_: {
                  src = prev.fetchurl {
                    url = "https://github.com/tenzir/threatbus/archive/2020.12.16.tar.gz";
                    hash = "sha256-8hbOftFkOvuf7XG4GN2WscVDWImqDgkIhlT1VdKHFfw=";
                  };
                }))
              ];
              postPatch = ''
                substituteInPlace apps/vast/setup.py \
                --replace "threatbus >= 2020.12.16, < 2021.2.24" "" \
                --replace "threatbus-zmq-app >= 2020.12.16, < 2021.2.24" ""
              '';
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
              --replace "threatbus>=2021.2.24" ""
            '';
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
                    --replace "threatbus >= 2021.2.24" ""
                  '';
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
                    --replace "threatbus>=2021.2.24" ""
                  '';
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
                    --replace "threatbus>=2021.2.24" ""
                  '';
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
              }
            );
        };
    };
}
