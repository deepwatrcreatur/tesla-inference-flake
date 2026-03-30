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

  # Build CUDA architecture strings
  buildArchString = architectures: prev.lib.concatStringsSep ";" architectures;
  # For CMake's CMAKE_CUDA_ARCHITECTURES, dots are not allowed; use integer codes like 35, 61.
  buildCmakeArchString = architectures:
    prev.lib.concatStringsSep ";" (map (arch: prev.lib.replaceStrings ["."] [""] arch) architectures);

  # Predefined architecture sets
  architectureSets = {
    tesla-legacy = [ "3.5" "3.7" ];    # K-series (Kepler)
    tesla-maxwell = [ "5.2" ];         # M-series
    tesla-pascal = [ "6.0" "6.1" ];    # P-series
    tesla-all = [ "3.5" "3.7" "5.2" "6.0" "6.1" ];
    # CI/build-safe set that avoids Kepler (nvcc 12.8+ on nix-ci.com rejects
    # compute_35/37). Use this in CI jobs that must pass there, while keeping
    # tesla-all for real deployments.
    tesla-ci = [ "5.2" "6.0" "6.1" ];
  };

  # Filter architectures based on the CUDA toolkit we are building against.
  # CUDA 12.8+ no longer supports Kepler (compute_35/37), so we drop those
  # architectures from the *effective* build set when running on such
  # toolchains while keeping them in the declarative sets above for users who
  # pin an older CUDA.
  cudaVersion = final.cudaPackages.cudatoolkit.version or "0";
  supportsKepler = prev.lib.versionOlder cudaVersion "12.8";
  effectiveArchitecturesForCuda = architectures:
    if supportsKepler then architectures
    else prev.lib.filter (arch: !(arch == "3.5" || arch == "3.7")) architectures;

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
    let
      effectiveArchitectures = effectiveArchitecturesForCuda architectures;
    in
    if isLinux then prev.llama-cpp.overrideAttrs (old: {
      # Set CUDA architectures and enable CUDA support
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DGGML_CUDA=ON"
        # CI (nix-ci.com) runs with a CUDA toolchain that does not yet support
        # the newest compute capabilities (e.g. compute_121a). We pin
        # CMAKE_CUDA_ARCHITECTURES to the Tesla-focused set here so default
        # flake checks stay green; advanced users targeting newer GPUs can
        # copy this overlay and adjust `architectureSets` or `teslaArchitectures`.
        "-DCMAKE_CUDA_ARCHITECTURES=${buildCmakeArchString effectiveArchitectures}"
        "-DCUDA_ARCHITECTURES=${buildCmakeArchString effectiveArchitectures}"
        "-DGGML_CUDA_F16=ON"                    # Enable FP16 (where supported)
        "-DGGML_CUDA_FORCE_DMMV=ON"            # Force use of DMMV kernel for older GPUs
        "-DGGML_CUDA_FORCE_MMQ=OFF"            # Disable MMQ for compatibility
      ] ++ prev.lib.optionals (prev.lib.any (arch: prev.lib.versionOlder arch "7.0") effectiveArchitectures) [
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
        export CMAKE_CUDA_ARCHITECTURES="${buildCmakeArchString effectiveArchitectures}"
        export CUDA_ARCHITECTURES="${buildCmakeArchString effectiveArchitectures}"

        # Tesla-specific CUDA compiler flags
        export NVCCFLAGS="-gencode arch=compute_${prev.lib.replaceStrings ["."] [""] (builtins.head effectiveArchitectures)},code=sm_${prev.lib.replaceStrings ["."] [""] (builtins.head effectiveArchitectures)}"

        echo "Building llama-cpp for Tesla GPU architectures: ${buildArchString effectiveArchitectures}"
      '';

      # Ensure CUDA is available during build
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        final.cudaPackages.cuda_nvcc
        final.pkg-config
      ];

      # Add metadata about supported architectures
      # Disable import check to avoid CUDA runtime dependency in build
      pythonImportsCheck = [ ];
      passthru = (old.passthru or { }) // {
        # Report the *effective* architectures actually compiled for this
        # CUDA toolkit, so metadata matches the binary.
        cudaArchitectures = effectiveArchitectures;
        teslaOptimized = true;
        supportedGpus = prev.lib.attrNames (prev.lib.filterAttrs (_: v: prev.lib.any (a: builtins.elem a effectiveArchitectures) v) teslaArchitectures);
      };
    }) else prev.llama-cpp; # Fall back to standard llama-cpp on non-Linux systems

  # Build llama-cpp-python with Tesla optimizations
  buildLlamaCppPythonForArchitectures = architectures:
    let
      effectiveArchitectures = effectiveArchitecturesForCuda architectures;
    in
    if isLinux then prev.python3Packages.llama-cpp-python.overrideAttrs (old: {
      # Set environment variables for CUDA compilation
      preBuild = (old.preBuild or "") + ''
        export CMAKE_ARGS="-DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=${buildCmakeArchString effectiveArchitectures} -DCUDA_ARCHITECTURES=${buildCmakeArchString effectiveArchitectures} -DGGML_CUDA_F16=ON"
        export CUDA_PATH=${final.cudaPackages.cudatoolkit}
        export CUDACXX=${final.cudaPackages.cuda_nvcc}/bin/nvcc

        echo "Building llama-cpp-python for Tesla GPU architectures: ${buildArchString effectiveArchitectures}"
      '';

      # Add CUDA dependencies
      buildInputs = (old.buildInputs or [ ]) ++ teslaCudaDeps;
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        final.cudaPackages.cuda_nvcc
      ];

      # Add metadata
      # Disable import check to avoid CUDA runtime dependency in build
      pythonImportsCheck = [ ];
      passthru = (old.passthru or { }) // {
        # Match metadata to the CUDA architectures actually compiled for this
        # toolkit version.
        cudaArchitectures = effectiveArchitectures;
        teslaOptimized = true;
      };
    }) else prev.python3Packages.llama-cpp-python;

in {
  # llama-cpp optimized for Tesla P40 (compute 6.1)
  llama-cpp-tesla-p40 = buildLlamaCppForArchitectures teslaArchitectures.P40;

  # llama-cpp optimized for all Tesla GPUs (including Kepler)
  llama-cpp-tesla = buildLlamaCppForArchitectures architectureSets.tesla-all;
  # CI-only variant that skips Kepler for nvcc 12.8 on nix-ci.com
  llama-cpp-tesla-ci = buildLlamaCppForArchitectures architectureSets.tesla-ci;

  # llama-cpp optimized for Pascal-generation Tesla GPUs (P40, P100)
  llama-cpp-tesla-pascal = buildLlamaCppForArchitectures architectureSets.tesla-pascal;

  # llama-cpp optimized for Maxwell-generation Tesla GPUs (M40, M60)
  llama-cpp-tesla-maxwell = buildLlamaCppForArchitectures architectureSets.tesla-maxwell;

  # llama-cpp-python optimized for Tesla P40
  python3Packages = prev.python3Packages // {
    llama-cpp-python-tesla-p40 = buildLlamaCppPythonForArchitectures teslaArchitectures.P40;
    # Full Tesla set (including Kepler); use this for real deployments that
    # need K20/K40/K80 support.
    llama-cpp-python-tesla = buildLlamaCppPythonForArchitectures architectureSets.tesla-all;
    # CI-only variant without Kepler for nvcc 12.8 on nix-ci.com / GitHub
    # Actions. Use this in CI jobs when the CUDA toolchain cannot target
    # compute_35/37, while keeping the full package set for production.
    llama-cpp-python-tesla-ci = buildLlamaCppPythonForArchitectures architectureSets.tesla-ci;
    llama-cpp-python-tesla-pascal = buildLlamaCppPythonForArchitectures architectureSets.tesla-pascal;
    llama-cpp-python-tesla-maxwell = buildLlamaCppPythonForArchitectures architectureSets.tesla-maxwell;
  };

  # Convenience alias for most common Tesla use case
  llama-cpp-tesla-generic = final.llama-cpp-tesla-pascal;

  # Override standard llama-cpp for drop-in compatibility
  llama-cpp = final.llama-cpp-tesla;

  # Override python3Packages.llama-cpp-python
  python3Packages = prev.python3Packages // {
    llama-cpp-python = final.python3Packages.llama-cpp-python-tesla;
  };
}