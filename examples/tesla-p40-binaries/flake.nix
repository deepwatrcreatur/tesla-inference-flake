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

          {
            # Tesla P40-specific configuration
            networking.hostName = "inference-host";
            boot.kernelParams = [
              # P40 requires these kernel params for proper GPU access
              "nvidia.NVRM" = "0"
            ];

            # Use official binaries ollama
            services.ollama = {
              enable = true;
              package = pkgs.ollama-official-binaries;
              host = "0.0.0.0";
              port = 11434;
              environmentVariables = {
                CUDA_VISIBLE_DEVICES = "0";
                OLLAMA_GPU_OVERHEAD = "0";
                # Point to bundled CUDA libraries and system CUDA driver
                LD_LIBRARY_PATH = "/run/opengl-driver/lib";
              };
            };
          }
        ];
      };
    };
}
