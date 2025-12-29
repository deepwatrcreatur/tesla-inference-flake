{
  description = "Modern GPU inference configuration example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tesla-inference.url = "github:deepwatrcreatur/tesla-inference-flake";
  };

  outputs = { nixpkgs, tesla-inference, ... }: {
    nixosConfigurations.modern-inference = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        tesla-inference.nixosModules.tesla-inference
        {
          # Modern GPU configuration (RTX 3000+, 4000+ series)
          tesla-inference = {
            enable = true;

            # Use standard Ollama for modern GPUs
            ollama = {
              enable = true;
              modelsPath = "/models/ollama";
              port = 11434;
              host = "0.0.0.0";
              # Modern GPUs use standard nixpkgs ollama
              package = nixpkgs.ollama;
            };

            # GPU monitoring
            monitoring.enable = true;
          };

          # Modern GPU specific packages
          environment.systemPackages = with nixpkgs; [
            # Use standard CUDA packages for modern hardware
            cudaPackages.cuda_nvcc
            cudaPackages.cudnn
            # Standard Ollama works well with modern GPUs
            ollama
          ];

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

          networking.hostName = "modern-inference";
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