final: prev:

let
  # Only enable CUDA overlays on Linux systems
  isLinux = final.stdenv.isLinux;
  # Tesla GPU CUDA architecture mappings
  teslaArchitectures = {
    "K20" = [ "35" ];
    "K40" = [ "35" ];
    "K80" = [ "37" ];
    "M40" = [ "52" ];
    "M60" = [ "52" ];
    "P40" = [ "61" ];
    "P100" = [ "60" ];
  };

  # Build CUDA architecture string for cmake
  buildArchString = architectures: prev.lib.concatStringsSep ";" architectures;

  # Predefined architecture sets
  architectureSets = {
    tesla-legacy = [ "35" "37" ];  # K-series
    tesla-maxwell = [ "52" ];      # M-series
    tesla-pascal = [ "60" "61" ];  # P-series
    tesla-all = [ "35" "37" "52" "60" "61" ];
  };

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
}