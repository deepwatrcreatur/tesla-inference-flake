{
  description = "Tesla GPU-optimized inference tools for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # Import overlays (system-independent)
      overlays = {
        ollama-cuda = import ./overlays/ollama-cuda.nix;
        gpu-tools = import ./overlays/gpu-tools.nix;
        default = import ./overlays/ollama-cuda.nix;
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;  # Allow CUDA packages
          };
        };


        # Helper functions for CUDA architecture support
        lib = import ./lib { inherit (pkgs) lib; };

        # Apply all overlays to pkgs
        pkgsWithOverlays = pkgs.extend (final: prev:
          (overlays.ollama-cuda final prev) //
          (overlays.gpu-tools final prev)
        );

        # Import packages with overlays applied
        teslaPackages = import ./packages {
          inherit lib;
          pkgs = pkgsWithOverlays;
        };

      in {
        # Packages for direct installation
        packages = teslaPackages // {
          default = teslaPackages.ollama-cuda-tesla;
        };


        # Development shell with full CUDA development environment
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Development tools
            git
            nix
            nixpkgs-fmt

            # GPU monitoring (cross-platform)
            teslaPackages.tesla-gpu-info
            teslaPackages.gpu-monitoring-tools
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            # CUDA development tools (Linux only)
            cudaPackages.cuda_nvcc
            cudaPackages.cuda_cudart
            cudaPackages.libcublas

            # GPU monitoring (Linux-specific)
            pciutils
          ];

          shellHook = ''
            echo "Tesla Inference Flake Development Environment"
            echo "Platform: ${pkgs.stdenv.hostPlatform.system}"
            ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
              echo "CUDA Development Tools Available:"
              echo "  - nvcc: $(nvcc --version 2>/dev/null | head -1 || echo 'CUDA Compiler')"
            ''}
            ${pkgs.lib.optionalString (!pkgs.stdenv.isLinux) ''
              echo "Note: CUDA tools not available on this platform"
            ''}
            echo "  - tesla-gpu-info: Tesla GPU information tool"
            echo "Available packages: ollama-cuda-tesla, gpu-monitoring-tools"
            echo "Run 'nix flake show' to see all outputs"
          '';
        };

        # CI checks
        checks = {
          # Verify all packages build
          packages-build = pkgs.runCommand "check-packages-build" {
            # Reference key packages to ensure they evaluate
            inherit (teslaPackages) ollama-cuda-tesla tesla-gpu-info;
          } ''
            echo "Checking that key packages are defined..."
            echo "✓ ollama-cuda-tesla: $ollama_cuda_tesla"
            echo "✓ tesla-gpu-info: $tesla_gpu_info"
            echo "✓ Package definitions evaluate successfully"
            touch $out
          '';
        };
      }
    ) // {
      # Overlays for use in other flakes (system-independent)
      inherit overlays;

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