# Overlay for Ollama using official pre-built binaries
# Downloads from GitHub releases and bundles CUDA libraries

final: prev:

let
  inherit (final) lib;

  # Pinned Ollama version with a known-good official binary asset
  version = "0.18.2";

in
{
  # Ollama using official pre-built binaries
  # This provides latest ollama with CUDA 12/13 libraries bundled
  ollama-official-binaries = prev.stdenv.mkDerivation rec {
    pname = "ollama";
    inherit version;

    src = prev.fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v\${version}/ollama-linux-amd64.tar.zst";
      sha256 = "1h5zfbz4b6rrx7n7r7k3ga4v903xw0q4wanhfvn5hbxm2chsnwis";
    };

    sourceRoot = ".";

    nativeBuildInputs = with final; [
      zstd
    ];
    buildInputs = with final; [ final.stdenv.cc.cc patchelf ];

    autoPatchelfIgnoreMissingDeps = [
      "libgcc_s.so.1"
      "libcuda.so.1"
    ];

    installPhase = ''
      mkdir -p $out/bin $out/lib
      cp bin/ollama $out/bin/ollama
      cp -r lib/* $out/lib/

      # Set RPATH to include bundled CUDA libraries and the standard C++ library
      patchelf --set-rpath "${final.stdenv.cc.cc.lib}/lib:$ORIGIN/../lib/ollama/cuda_v12:$ORIGIN/../lib/ollama/cuda_v13:$ORIGIN/..:$ORIGIN" $out/bin/ollama
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
