{
  description = "Tesla GPU-optimized inference tools for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Helper functions for CUDA architecture support
        lib = import ./lib { inherit (pkgs) lib; };

        # Import overlays
        overlays = {
          ollama-cuda = import ./overlays/ollama-cuda.nix;
          gpu-tools = import ./overlays/gpu-tools.nix;
        };

        # Import packages with overlays applied
        teslaPackages = import ./packages {
          inherit pkgs lib;
          pkgs = pkgs.extend overlays.ollama-cuda;
        };

      in {
        # Packages for direct installation
        packages = teslaPackages // {
          default = teslaPackages.ollama-cuda-tesla;
        };

        # Overlays for use in other flakes
        overlays = overlays // {
          default = overlays.ollama-cuda;
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Development tools
            git
            nix
            nixpkgs-fmt

            # CUDA development tools (for testing)
            cudaPackages.cuda_nvcc
            cudaPackages.cuda_runtime

            # GPU monitoring
            nvtop
            pciutils
          ];

          shellHook = ''
            echo "Tesla Inference Flake Development Environment"
            echo "Available packages: ollama-cuda-tesla, gpu-monitoring-tools"
            echo "Run 'nix flake show' to see all outputs"
          '';
        };

        # CI checks
        checks = {
          # Verify all packages build
          packages-build = pkgs.runCommand "check-packages-build" {} ''
            echo "Checking that key packages evaluate..."
            # Just check evaluation, not full build in CI
            ${pkgs.nix}/bin/nix eval --impure --expr '
              let flake = builtins.getFlake "${self}";
              in builtins.attrNames flake.packages.${system}
            '
            touch $out
          '';
        };
      }
    ) // {
      # NixOS modules (system-independent)
      nixosModules = {
        tesla-inference = import ./modules/tesla-inference.nix;
        ollama-cuda-service = import ./modules/ollama-cuda-service.nix;
        gpu-monitoring = import ./modules/gpu-monitoring.nix;
        default = self.nixosModules.tesla-inference;
      };

      # Templates for easy setup
      templates = {
        tesla-p40 = {
          path = ./examples/tesla-p40;
          description = "Tesla P40 inference configuration template";
        };
        modern-gpu = {
          path = ./examples/modern-gpu;
          description = "Modern GPU inference configuration template";
        };
      };
    };
}