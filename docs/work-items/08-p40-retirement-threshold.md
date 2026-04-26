# 08 P40 Retirement Threshold

Status: `done`
Suggested branch: `docs/p40-retirement-threshold`

## Strategic Posture (April 2026)

The Tesla P40 remains a **strategic target** for the "Thorncliffe" Cluster. With 72GB of aggregate VRAM across 3 nodes, it currently provides a unique "VRAM-to-Dollar" ratio that is not yet matched by entry-level consumer hardware.

## Retirement Triggers

Retirement or demotion to "Legacy/Sunset" status will be triggered by:

1. **Software Abandonment:** If `llama.cpp` and `vllm-pascal` both stop supporting Pascal/CC 6.1, the engineering overhead to carry custom patches exceeds the hardware's value.
2. **Efficiency Parity:** When a modern GPU with 24GB+ VRAM (e.g., RTX 5060/Titan-successor) achieves 3x the P40's tokens-per-second at <50% of the power consumption, the "tokens-per-watt" becomes the primary driver for retirement.
3. **Model Misalignment:** If the "Deep Thinker" models (e.g., Llama-4 70B+) require architectural features (like FP8 or specific tensor cores) that Pascal cannot emulate with reasonable performance (~1 tok/sec floor).

## Recommendation

Keep Tesla/P40 as a **Core Path** for the 2026-2027 cycle. Continue investing in optimization for the 3x P40 "Thorncliffe" cluster.

## Goal

Define when Tesla P40 hardware should remain a supported legacy target versus
when it should be retired or demoted in favor of newer inference platforms.

## Context

The flake currently provides real value for Tesla-era GPUs through Ollama and
llama.cpp, but newer inference stacks are increasingly built around software
that assumes more modern hardware. The decision point is no longer just raw
tokens per dollar; it is whether the software roadmap still fits Pascal-era
cards well enough to justify power, maintenance, and support complexity.

## Tasks

- [ ] Document which workloads still make the P40 worth keeping
- [ ] Define what counts as a retirement trigger, such as unsupported software,
  poor model fit, or materially better newer platforms
- [ ] Separate "keep as legacy capacity" from "continue investing engineering
  effort in this target"
- [ ] Leave a short recommendation on whether the flake should keep Tesla/P40 as
  a core path, a legacy path, or a sunset path

## Non-Goals

- immediately deleting Tesla support from the flake
- pretending mini-PC anecdotes alone are enough to settle the decision
- committing to a specific replacement platform in the same PR

## Validation

- the repo has an explicit support posture for P40-class hardware
- future work can tell whether Tesla support is strategic, legacy, or sunset
- the retirement criteria are concrete enough to guide follow-up decisions
