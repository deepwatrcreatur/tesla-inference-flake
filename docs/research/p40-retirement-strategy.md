# Strategy: Tesla P40 Retirement Threshold

## Current Value Proposition

The Tesla P40 remains a viable target for specific workloads:
- **Large Context Window Inference**: 24GB VRAM allows for reasonably large models (e.g., Llama-3 70B with 4-bit quantization) at a very low cost per GB of VRAM.
- **Batch Processing / High-Latency Tasks**: Where tokens-per-second (TPS) is less critical than total throughput or context size.
- **Home Labs / Educational Use**: Low entry cost for learning distributed inference and CUDA management.

## Retirement Triggers

We define the following triggers for retiring or demoting P40 support:
1. **Software Obsolescence**: When major inference engines (Ollama, llama.cpp) drop support for `sm_61` or require CUDA versions that no longer support Pascal.
2. **Model Architecture Shift**: When state-of-the-art (SOTA) models rely on features (like FP8 or hardware-accelerated Flash Attention) that Pascal lacks, leading to severe performance degradation (e.g., >5x slower than Volta/Ampere equivalents).
3. **Power Efficiency Gap**: When the operational cost (power) of P40 clusters materially exceeds the cost of renting or buying newer, more efficient hardware (e.g., T4, L40S) for the same token throughput.

## Support Posture Recommendation

### Current Status: **Legacy Support**

- **Maintain**: Keep existing Ollama and llama.cpp overlays functional. Ensure NixOS module compatibility.
- **Limit New Investment**: Do not attempt to backport modern inference engines (like vLLM) that are optimized for newer architectures.
- **Sunset Path**: The P40 should be moved to a "best-effort" or "community-maintained" status once NVIDIA officially drops the architecture from the stable CUDA toolkit (post-CUDA 12.x).

## Decision Matrix

| Metric | Keep (Strategic) | Legacy (Current) | Sunset (Planned) |
| :--- | :--- | :--- | :--- |
| **CUDA Version** | Latest | 12.x | 11.x or legacy-only |
| **Primary Engine** | vLLM / SOTA | llama.cpp / Ollama | llama.cpp (CPU fallback) |
| **Model Fit** | All new models | Quantized GGUF | Specialized legacy models |
| **Support Priority** | High (First-class) | Medium (Stability) | Low (Best-effort) |

## Conclusion

The P40 is no longer a strategic target for first-class, cutting-edge inference. This flake should treat it as a **stable legacy target**. We will continue to support it as long as `llama.cpp` and `Ollama` maintain Pascal compatibility, but we will not invest in making it work with Volta-era software stacks like `vLLM`.
