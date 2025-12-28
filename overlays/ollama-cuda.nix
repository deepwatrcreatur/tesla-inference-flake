final: prev:

let
  # Import our Tesla architecture helpers
  lib = import ../lib { inherit (prev) lib; };

  # Common CUDA dependencies for Tesla GPUs
  teslaUdaDeps = with final.cudaPackages; [
    cuda_nvcc
    cuda_cudart
    libcublas
    libcusparse
    libcurand
    cudnn
  ];

  # Build Ollama with specific CUDA architectures
  buildOllamaForArchitectures = architectures: prev.ollama.overrideAttrs (old: {
    # Set CUDA architectures
    cmakeFlags = (old.cmakeFlags or [ ]) ++ [
      "-DGGML_CUDA_ARCHITECTURES=${lib.buildArchString architectures}"
      "-DGGML_CUDA=ON"
    ];

    # Add Tesla-optimized CUDA dependencies
    buildInputs = (old.buildInputs or [ ]) ++ teslaUdaDeps;

    # Set up CUDA compilation environment
    preConfigure = (old.preConfigure or "") + ''
      export CUDA_PATH=${final.cudaPackages.cudatoolkit}
      export CUDACXX=${final.cudaPackages.cuda_nvcc}/bin/nvcc
      export CUDA_ARCHITECTURES="${lib.buildArchString architectures}"
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
  });

in {
  # Ollama optimized for Tesla P40 (compute 6.1)
  ollama-cuda-tesla-p40 = buildOllamaForArchitectures lib.teslaArchitectures.P40;

  # Ollama optimized for all Tesla GPUs
  ollama-cuda-tesla = buildOllamaForArchitectures lib.architectureSets.tesla-all;

  # Ollama optimized for Pascal-generation Tesla GPUs (P40, P100)
  ollama-cuda-tesla-pascal = buildOllamaForArchitectures lib.architectureSets.tesla-pascal;

  # Ollama optimized for Maxwell-generation Tesla GPUs (M40, M60)
  ollama-cuda-tesla-maxwell = buildOllamaForArchitectures lib.architectureSets.tesla-maxwell;

  # Generic Tesla-optimized Ollama (alias for tesla-all)
  ollama-cuda-tesla-generic = final.ollama-cuda-tesla;
}