{ lib }:

{
  # Tesla GPU CUDA architecture mappings
  teslaArchitectures = {
    # Kepler generation
    "K20" = [ "35" ];
    "K40" = [ "35" ];
    "K80" = [ "37" ];

    # Maxwell generation
    "M40" = [ "52" ];
    "M60" = [ "52" ];

    # Pascal generation
    "P40" = [ "61" ];
    "P100" = [ "60" ];
  };

  # Get CUDA architectures for a specific Tesla GPU
  getArchitectures = gpu:
    lib.attrByPath [gpu] (throw "Unsupported Tesla GPU: ${gpu}")
      lib.teslaArchitectures;

  # Build CUDA architecture string for cmake
  buildArchString = architectures:
    lib.concatStringsSep ";" architectures;

  # Check if a GPU supports a specific compute capability
  supportsCompute = gpu: capability:
    lib.elem capability (lib.getArchitectures gpu);

  # Get all supported architectures (useful for multi-GPU setups)
  getAllArchitectures = gpus:
    lib.unique (lib.flatten (map lib.getArchitectures gpus));

  # Predefined architecture sets for common configurations
  architectureSets = {
    tesla-legacy = [ "35" "37" ];  # K-series
    tesla-maxwell = [ "52" ];      # M-series
    tesla-pascal = [ "60" "61" ];  # P-series
    tesla-all = [ "35" "37" "52" "60" "61" ];
  };
}