{
  description = "python-develop";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/3a7674c896847d18e598fa5da23d7426cb9be3d2";
    threatbus-src = { url = "github:tenzir/threatbus"; flake = false; };
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    mach-nix = { url = "github:DavHau/mach-nix"; inputs.nixpkgs.follows = "nixpkgs"; };
    nixpkgs-hardenedlinux = { url = "github:hardenedlinux/nixpkgs-hardenedlinux"; inputs.nixpkgs.follows = "nixpkgs"; };

  };

  outputs = inputs@{ self, nixpkgs, flake-utils, flake-compat, mach-nix, threatbus-src, nixpkgs-hardenedlinux }:
    { }
    //
    (flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlay
            ];
            config = { };
          };
        in
        rec {
          devShell = with pkgs; mkShell {
            buildInputs = [
            ];
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
              threatbus-zeek = python3Packages.buildPythonPackage rec {
                pname = "zeek";
                version = "2021.02.24";
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
                postPatch = ''
                '';
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
                postPatch = ''

                '';
              };
            in
            python3Packages.buildPythonPackage rec {
              pname = "threatbus";
              version = "2021.02.24";

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
