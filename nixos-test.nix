{ makeTest, pkgs, self }:
{
  threatbus-systemd = makeTest
    {
      name = "threatbus-systemd-vm-test";
      machine = { config, pkgs, ... }: {
        imports = [
          self.nixosModules.threatbus
          self.nixosModules.threatbus-vast
        ];

        virtualisation.memorySize = 2046;

        # services.threatbus-vast = {
        #   enable = true;
        #   extraConfig = builtins.readFile ./conf/config.vast.example.yaml;
        # };

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
        #machine.wait_for_unit("threatbus-vast.service")
      '';
    }
    {
      inherit pkgs;
      inherit (pkgs) system;
    };
}
