{ makeTest, pkgs, self, vast2nix }:
{
  threatbus-vm-systemd = makeTest
    {
      name = "threatbus-systemd";
      machine = { config, pkgs, ... }: {
        imports = [
          self.nixosModules.threatbus
          self.nixosModules.threatbus-vast
        ];

        virtualisation.memorySize = 2046;

        services.threatbus = {
          enable = true;
          extraConfig = builtins.readFile ./conf/config.example.yaml;
        };
      };
      testScript = ''
        start_all()
        machine.wait_for_unit("multi-user.target")
        machine.wait_for_unit("threatbus.service")
        with subtest("test threatbus ZeroMQ Ports"):
             machine.wait_for_open_port(13379)#zeroMQ-app
             machine.wait_for_open_port(13372)#zeroMQ-app
             machine.wait_for_open_port(13373)#zeroMQ-app
      '';
    }
    {
      inherit pkgs;
      inherit (pkgs) system;
    };
  threatbus-vast-vm-systemd = makeTest
    {
      name = "threatbus-systemd";
      machine = { config, pkgs, ... }: {
        imports = [
          self.nixosModules.threatbus
          self.nixosModules.threatbus-vast
          vast2nix.nixosModules.vast
        ];

        virtualisation.memorySize = 2046;

        services.threatbus-vast = {
          enable = true;
          extraConfig = builtins.readFile ./conf/config.vast.example.yaml;
        };
        services.vast = {
          enable = true;
        };

        services.threatbus = {
          enable = true;
          extraConfig = builtins.readFile ./conf/config.example.yaml;
        };
      };
      testScript = ''
        machine.start()
        machine.wait_for_unit("multi-user.target")
        machine.wait_for_unit("threatbus.service")
        machine.wait_for_unit("vast.service")
        machine.wait_for_open_port(4000)#zeroMQ-app
        with subtest("test threatbus ZeroMQ Ports"):
             machine.wait_for_open_port(13379)#zeroMQ-app
             machine.wait_for_open_port(13372)#zeroMQ-app
             #machine.wait_for_open_port(13373)#zeroMQ-app
        machine.wait_for_unit("threatbus-vast.service")
      '';
    }
    {
      inherit pkgs;
      inherit (pkgs) system;
    };
}
