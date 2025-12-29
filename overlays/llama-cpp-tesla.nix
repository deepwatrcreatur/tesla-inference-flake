final: prev:

let
  # Only enable CUDA overlays on Linux systems
  isLinux = final.stdenv.isLinux;

  # Tesla GPU CUDA architecture mappings (compute capability)
  teslaArchitectures = {
    "K20" = [ "3.5" ];
    "K40" = [ "3.5" ];
    "K80" = [ "3.7" ];
    "M40" = [ "5.2" ];
    "M60" = [ "5.2" ];
    "P40" = [ "6.1" ];
    "P100" = [ "6.0" ];
  };

  # Build CUDA architecture string for cmake
  buildArchString = architectures: prev.lib.concatStringsSep ";" architectures;

  # Predefined architecture sets
  architectureSets = {
    tesla-legacy = [ "3.5" "3.7" ];    # K-series
    tesla-maxwell = [ "5.2" ];         # M-series
    tesla-pascal = [ "6.0" "6.1" ];    # P-series
    tesla-all = [ "3.5" "3.7" "5.2" "6.0" "6.1" ];
  };

  # Common CUDA dependencies for Tesla GPUs (Linux only)
  teslaCudaDeps = if isLinux then with final.cudaPackages; [
    cuda_nvcc
    cuda_cudart
    libcublas
    libcusparse
    libcurand
  ] else [];

  # Build llama-cpp with specific CUDA architectures for Tesla GPUs
  buildLlamaCppForArchitectures = architectures:
    if isLinux then prev.llama-cpp.overrideAttrs (old: {
      # Set CUDA architectures and enable CUDA support
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DGGML_CUDA=ON"
        "-DCUDA_ARCHITECTURES=${buildArchString architectures}"
        "-DGGML_CUDA_F16=ON"                    # Enable FP16 (where supported)
        "-DGGML_CUDA_FORCE_DMMV=ON"            # Force use of DMMV kernel for older GPUs
        "-DGGML_CUDA_FORCE_MMQ=OFF"            # Disable MMQ for compatibility
      ] ++ prev.lib.optionals (prev.lib.any (arch: prev.lib.versionOlder arch "7.0") architectures) [
        # Additional optimizations for pre-Volta Tesla GPUs
        "-DGGML_CUDA_DMMV_X=32"               # Optimized DMMV tile size for Tesla
        "-DGGML_CUDA_MMV_Y=1"                 # Reduce MMV tile size for older GPUs
      ];

      # Add Tesla-optimized CUDA dependencies
      buildInputs = (old.buildInputs or [ ]) ++ teslaCudaDeps;

      # Set up CUDA compilation environment
      preConfigure = (old.preConfigure or "") + ''
        export CUDA_PATH=${final.cudaPackages.cudatoolkit}
        export CUDACXX=${final.cudaPackages.cuda_nvcc}/bin/nvcc
        export CUDA_ARCHITECTURES="${buildArchString architectures}"

        # Tesla-specific CUDA compiler flags
        export NVCCFLAGS="-gencode arch=compute_${prev.lib.replaceStrings ["."] [""] (builtins.head architectures)},code=sm_${prev.lib.replaceStrings ["."] [""] (builtins.head architectures)}"

        echo "Building llama-cpp for Tesla GPU architectures: ${buildArchString architectures}"
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
        supportedGpus = prev.lib.attrNames (prev.lib.filterAttrs (_: v: prev.lib.any (a: builtins.elem a architectures) v) teslaArchitectures);
      };
    }) else prev.llama-cpp; # Fall back to standard llama-cpp on non-Linux systems

  # Build llama-cpp-python with Tesla optimizations
  buildLlamaCppPythonForArchitectures = architectures:
    if isLinux then prev.python3Packages.llama-cpp-python.overrideAttrs (old: {
      # Set environment variables for CUDA compilation
      preBuild = (old.preBuild or "") + ''
        export CMAKE_ARGS="-DGGML_CUDA=ON -DCUDA_ARCHITECTURES=${buildArchString architectures} -DGGML_CUDA_F16=ON"
        export CUDA_PATH=${final.cudaPackages.cudatoolkit}
        export CUDACXX=${final.cudaPackages.cuda_nvcc}/bin/nvcc

        echo "Building llama-cpp-python for Tesla GPU architectures: ${buildArchString architectures}"
      '';

      # Add CUDA dependencies
      buildInputs = (old.buildInputs or [ ]) ++ teslaCudaDeps;
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        final.cudaPackages.cuda_nvcc
      ];

      # Add metadata
      passthru = (old.passthru or { }) // {
        cudaArchitectures = architectures;
        teslaOptimized = true;
      };
    }) else prev.python3Packages.llama-cpp-python;

in {
  # llama-cpp optimized for Tesla P40 (compute 6.1)
  llama-cpp-tesla-p40 = buildLlamaCppForArchitectures teslaArchitectures.P40;

  # llama-cpp optimized for all Tesla GPUs
  llama-cpp-tesla = buildLlamaCppForArchitectures architectureSets.tesla-all;

  # llama-cpp optimized for Pascal-generation Tesla GPUs (P40, P100)
  llama-cpp-tesla-pascal = buildLlamaCppForArchitectures architectureSets.tesla-pascal;

  # llama-cpp optimized for Maxwell-generation Tesla GPUs (M40, M60)
  llama-cpp-tesla-maxwell = buildLlamaCppForArchitectures architectureSets.tesla-maxwell;

  # llama-cpp-python optimized for Tesla P40
  python3Packages = prev.python3Packages // {
    llama-cpp-python-tesla-p40 = buildLlamaCppPythonForArchitectures teslaArchitectures.P40;
    llama-cpp-python-tesla = buildLlamaCppPythonForArchitectures architectureSets.tesla-all;
    llama-cpp-python-tesla-pascal = buildLlamaCppPythonForArchitectures architectureSets.tesla-pascal;
    llama-cpp-python-tesla-maxwell = buildLlamaCppPythonForArchitectures architectureSets.tesla-maxwell;
  };

  # Convenience alias for most common Tesla use case
  llama-cpp-tesla-generic = final.llama-cpp-tesla-pascal;
}