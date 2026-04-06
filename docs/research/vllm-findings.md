# Research: vLLM Package Scope and Architecture Support

## Current Status in Nixpkgs

- **Attribute**: `nixpkgs#vllm` (or `python3Packages.vllm`)
- **Default Device**: CPU (`VLLM_TARGET_DEVICE = "cpu"`)
- **CUDA Support**: Enabled when built via `pkgsForCudaArch.sm_XX.vllm` for compatible architectures (e.g., `sm_80` / A100).
- **Legacy Support (Pascal/sm_61)**: Currently broken or unsupported in `nixpkgs` for `x86_64-linux` due to `cudnn` dependency marking the platform as `badPlatforms` for that architecture.

## Findings for Tesla P40 / Maxwell

- **Evaluation Failures**: Attempting to evaluate `vllm` for `sm_61` (P40) or older results in evaluation errors because `cudnn` (a required dependency for vLLM's CUDA path) is not supported on these older architecture package sets in modern `nixpkgs`.
- **Software Fit**: Upstream `vllm` optimizations (Flash Attention, etc.) are heavily tailored for Volta+ (SM 7.0+) hardware. While community forks exist, they are not integrated into `nixpkgs` and would require significant maintenance effort to carry as overlays.

## Recommendations

1. **Exclusivity**: Do **not** add `vllm` as a supported engine for the Tesla P40/Maxwell baseline in this flake.
2. **Alternative**: Continue to recommend `llama-cpp-python` and `ollama` (via the existing overlays) as the primary inference engines for Pascal/Maxwell hardware. They have mature, stable support for these architectures.
3. **Future Scope**: If `vllm` is integrated into this flake in the future, it should be exposed only for newer GPU targets (V100/T4 and later) where `nixpkgs` evaluation is stable and upstream support is first-class.

## Conclusion

The Nixpkgs `vllm` package is not a "drop-in" addition for legacy Tesla hardware. Integrating it would either require disabling CUDA (CPU-only, which defeats the purpose of this flake) or carrying invasive, brittle patches for legacy CUDA support.
