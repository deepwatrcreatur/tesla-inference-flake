# Overlay for Ollama using official pre-built binaries
# Downloads from GitHub releases and bundles CUDA libraries

final: prev:

let
  inherit (final.stdenv.lib) lib;

  # Latest ollama version (can be overridden)
  version = "0.13.5";

in
{
  # Ollama using official pre-built binaries
  # This provides latest ollama with CUDA 12/13 libraries bundled
  ollama-official-binaries = prev.stdenv.mkDerivation rec {
    pname = "ollama";
    inherit version;

    src = prev.fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v\${version}/ollama-linux-amd64.tgz";
      sha256 = "sha256-+xQOpCQ3BtAIewEIQY7lxvdO3Ov18U4vKJuONr0wPQ8=";
    };

    sourceRoot = ".";

    nativeBuildInputs = with final; [
      autoPatchelfHook
      patchelf
    ];
    buildInputs = with final; [ final.stdenv.cc.cc ];

    autoPatchelfIgnoreMissingDeps = [
      "libgcc_s.so.1"
      "libcuda.so.1"
    ];

    installPhase = ''
      mkdir -p \$out/bin \$out/lib
      cp bin/ollama \$out/bin/ollama
      cp -r lib/* \$out/lib/

      # Set RPATH to include bundled CUDA libraries
      patchelf --set-rpath "\$ORIGIN/../lib/ollama/cuda_v12:\$ORIGIN/../lib/ollama/cuda_v13:\$ORIGIN/..:\$ORIGIN" \$out/bin/ollama
    '';

    passthru = {
      inherit version;
      # Official binaries support all modern Tesla GPUs with CUDA 12.x
      # P40 (6.1), P100 (6.0), M40/M60 (5.2), K80 (3.7)
      supportedGPUs = [ "K80" "K40" "K20" "M40" "M60" "P40" "P100" ];
    };
  };

  # Convenience aliases for Tesla GPUs (same binary, different naming)
  ollama-cuda-tesla-binaries = final.ollama-official-binaries;
  ollama-cuda-tesla-p40-binaries = final.ollama-official-binaries;
  ollama-cuda-tesla-pascal-binaries = final.ollama-official-binaries;
  ollama-cuda-tesla-maxwell-binaries = final.ollama-official-binaries;
}
