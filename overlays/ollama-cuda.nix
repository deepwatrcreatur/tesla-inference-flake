final: prev:

let
  # Import central architecture logic
  teslaLib = import ../lib { inherit (prev) lib; };
  inherit (teslaLib) teslaArchitectures architectureSets buildArchString;

  # Only enable CUDA overlays on Linux systems
  isLinux = final.stdenv.isLinux;

  # Common CUDA dependencies for Tesla GPUs (Linux only)
  teslaUdaDeps = if isLinux then with final.cudaPackages; [
    cuda_nvcc
    cuda_cudart
    libcublas
    libcusparse
    libcurand
    cudnn
  ] else [];

  # Build Ollama with specific CUDA architectures (Linux only)
  buildOllamaForArchitectures = architectures:
    if isLinux then prev.ollama.overrideAttrs (old: {
      # Set CUDA architectures
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DGGML_CUDA_ARCHITECTURES=${buildArchString architectures}"
        "-DGGML_CUDA=ON"
      ];

      # Add Tesla-optimized CUDA dependencies
      buildInputs = (old.buildInputs or [ ]) ++ teslaUdaDeps;

      # Set up CUDA compilation environment
      preConfigure = (old.preConfigure or "") + ''
        export CUDA_PATH=${final.cudaPackages.cudatoolkit}
        export CUDACXX=${final.cudaPackages.cuda_nvcc}/bin/nvcc
        export CUDA_ARCHITECTURES="${buildArchString architectures}"
      '';

      # Ensure CUDA is available during build
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        final.cudaPackages.cuda_nvcc
        final.pkg-config
      ];

      # Add metadata about supported architectures
      passthru = (old.passthru or { }) // {
        cudaArchitectures = architectures;
        teslaOptimized = true;
      };
    }) else prev.ollama; # Fall back to standard Ollama on non-Linux systems

in {
  # Ollama optimized for Tesla P40 (compute 6.1)
  ollama-cuda-tesla-p40 = buildOllamaForArchitectures teslaArchitectures.P40;

  # Ollama optimized for all Tesla GPUs
  ollama-cuda-tesla = buildOllamaForArchitectures architectureSets.tesla-all;

  # Ollama optimized for Pascal-generation Tesla GPUs (P40, P100)
  ollama-cuda-tesla-pascal = buildOllamaForArchitectures architectureSets.tesla-pascal;

  # Ollama optimized for Maxwell-generation Tesla GPUs (M40, M60)
  ollama-cuda-tesla-maxwell = buildOllamaForArchitectures architectureSets.tesla-maxwell;

  # Generic Tesla-optimized Ollama (alias for tesla-all)
  ollama-cuda-tesla-generic = final.ollama-cuda-tesla;

  # Override standard Ollama for drop-in compatibility
  ollama = final.ollama-cuda-tesla;
}