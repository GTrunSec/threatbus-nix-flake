{
  description = "The missing link to connect open-source threat intelligence tools.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/3a7674c896847d18e598fa5da23d7426cb9be3d2";
    threatbus-src = { url = "github:tenzir/threatbus"; flake = false; };
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    devshell-flake.url = "github:numtide/devshell";
    nixpkgs-hardenedlinux = { url = "github:hardenedlinux/nixpkgs-hardenedlinux"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, flake-compat, devshell-flake, threatbus-src, nixpkgs-hardenedlinux }:
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

          apps.threatbus = {
            type = "app";
            program = "${pkgs.threatbus}/bin/threatbus";
          };

          packages = inputs.flake-utils.lib.flattenTree
            rec {
              threatbus = pkgs.threatbus;
              broker = pkgs.broker;
            };

          hydraJobs = {
            inherit packages;
          };

          defaultPackage = pkgs.threatbus;
        }
      )
    ) //
    {
      overlay = final: prev: {

        broker = prev.callPackage "${nixpkgs-hardenedlinux}/pkgs/broker" { };

        threatbus = with final;
          (
            let
              version = "2021.02.24";
              threatbus-zeek = python3Packages.buildPythonPackage rec {
                pname = "zeek";
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
                pname = "inmem";
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
                pname = "file_benchmark";
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

              stix2-patterns = python3Packages.buildPythonPackage rec {
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
              };

              stix2 = python3Packages.buildPythonPackage rec {
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
                final.broker
              ];
              postPatch = ''
              '';
              makeWrapperArgs = [ "--prefix PYTHONPATH : $PYTHONPATH" ];
            }
          );
      };
    };
}
