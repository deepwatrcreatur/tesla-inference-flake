{
  description = "Tesla P40 inference configuration using official ollama binaries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tesla-inference.url = "github:deepwatrcreatur/tesla-inference-flake";
  };

  outputs = { nixpkgs, tesla-inference, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.inference-host = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Use official binaries overlay instead of source builds
          { nixpkgs.overlays = [ tesla-inference.overlays.ollama-official-binaries ]; }

          # Use inference configuration module
          tesla-inference.nixosModules.tesla-inference

          ({ pkgs, ... }: {
            # Tesla P40-specific configuration
            tesla-inference = {
              enable = true;
              gpu = "P40";

              # Use official binaries ollama
              ollama = {
                enable = true;
                package = pkgs.ollama-official-binaries;
                modelsPath = "/models/ollama";
                host = "0.0.0.0";
                port = 11434;
                environmentVariables = {
                  CUDA_VISIBLE_DEVICES = "0";
                  OLLAMA_GPU_OVERHEAD = "0";
                  # Point to bundled CUDA libraries and system CUDA driver
                  LD_LIBRARY_PATH = "/run/opengl-driver/lib";
                };
              };

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
            networking.firewall.allowedTCPPorts = [ 11434 ]; # Ollama API

            services.openssh.enable = true;
            users.users.admin = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
            };

            system.stateVersion = "24.11";
          })
        ];
      };
    };
}
