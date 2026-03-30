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
        llama-cpp-tesla = import ./overlays/llama-cpp-tesla.nix;
        gpu-tools = import ./overlays/gpu-tools.nix;
        ollama-official-binaries = import ./overlays/ollama-official-binaries.nix;
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
          (overlays.llama-cpp-tesla final prev) //
          (overlays.gpu-tools final prev) //
          (overlays.ollama-official-binaries final prev)
        );

        # Import packages with overlays applied
        teslaPackages = import ./packages {
          inherit lib;
          pkgs = pkgsWithOverlays;
        };

      in {
        # Packages for direct installation
        packages = teslaPackages // {
          # Default to official Ollama binaries (CUDA-bundled) for most users
          default = teslaPackages.ollama-official-binaries;
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

        # CI checks (x86_64-linux only; Ollama official binaries are x86_64-linux)
        checks = pkgs.lib.optionalAttrs (system == "x86_64-linux") {
          # Verify key packages evaluate
          packages-build = pkgs.runCommand "check-packages-build" {
            inherit (teslaPackages) ollama-official-binaries tesla-gpu-info llama-cpp-tesla;
          } ''
            echo "Checking that key packages are defined..."
            echo "✓ ollama-official-binaries: $ollama_official_binaries"
            echo "✓ tesla-gpu-info: $tesla_gpu_info"
            echo "✓ llama-cpp-tesla: $llama_cpp_tesla"
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
        default = self.nixosModules.tesla-inference;

        # Deprecated: redirect to tesla-inference with warning
        gpu-monitoring = { lib, ... }: {
          imports = [ self.nixosModules.tesla-inference ];
          warnings = [ "nixosModules.gpu-monitoring is deprecated. Use nixosModules.tesla-inference with monitoring.enable = true instead." ];
        };
        ollama-cuda-service = { lib, ... }: {
          imports = [ self.nixosModules.tesla-inference ];
          warnings = [ "nixosModules.ollama-cuda-service is deprecated. Use nixosModules.tesla-inference with ollama.enable = true instead." ];
        };
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