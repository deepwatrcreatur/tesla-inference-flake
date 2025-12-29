{
  description = "Tesla P40 inference configuration example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tesla-inference.url = "github:deepwatrcreatur/tesla-inference-flake";
  };

  outputs = { nixpkgs, tesla-inference, ... }: {
    nixosConfigurations.inference-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        tesla-inference.nixosModules.tesla-inference
        {
          # Tesla P40 specific configuration
          tesla-inference = {
            enable = true;
            gpu = "P40";

            # Ollama service with P40 optimization
            ollama = {
              enable = true;
              modelsPath = "/models/ollama";
              port = 11434;
              host = "0.0.0.0";
            };

            # GPU monitoring
            monitoring.enable = true;
          };

          # Basic system configuration
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;

          fileSystems."/" = {
            device = "/dev/disk/by-label/nixos";
            fsType = "ext4";
          };

          fileSystems."/boot" = {
            device = "/dev/disk/by-label/boot";
            fsType = "vfat";
          };

          networking.hostName = "inference-host";
          networking.firewall.enable = false; # Adjust for your security needs

          services.openssh.enable = true;
          users.users.admin = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };

          system.stateVersion = "24.11";
        }
      ];
    };
  };
}