{
  description = "Tesla GPU-optimized inference tools for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
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

        # Import overlays
        overlays = {
          ollama-cuda = import ./overlays/ollama-cuda.nix;
          gpu-tools = import ./overlays/gpu-tools.nix;
        };

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

        # Overlays for use in other flakes
        overlays = overlays // {
          default = overlays.ollama-cuda;
        };

        # Development shell (without CUDA tools to avoid unfree license issues)
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Development tools
            git
            nix
            nixpkgs-fmt

            # GPU monitoring (non-CUDA tools)
            pciutils

            # Note: CUDA tools omitted from devShell to avoid unfree license issues
            # Use: nix shell .#ollama-cuda-tesla-p40 --impure for CUDA development
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