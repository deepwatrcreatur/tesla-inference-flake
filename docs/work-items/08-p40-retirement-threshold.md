# 08 P40 Retirement Threshold

Status: `done`
Suggested branch: `docs/p40-retirement-threshold`
Priority: `medium`

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

- [x] Document which workloads still make the P40 worth keeping
- [x] Define what counts as a retirement trigger, such as unsupported software,
  poor model fit, or materially better newer platforms
- [x] Separate "keep as legacy capacity" from "continue investing engineering
  effort in this target"
- [x] Leave a short recommendation on whether the flake should keep Tesla/P40 as
  a core path, a legacy path, or a sunset path

## Workloads Where P40 Still Makes Sense

- Low- to medium-throughput inference on 7B-class models where latency is not
  critical and power is amortized over 24/7 use.
- Batch/offline generation jobs (summarization, codegen experiments, synthetic
  data) where queueing is acceptable.
- Homelab or test environments that benefit from existing P40 sunk cost more
  than from peak efficiency.

## Retirement Triggers

- Key engines for this flake (e.g. `llama-cpp-python`, `ollama`) drop
  first-class support for Pascal (sm_61) in upstream or nixpkgs.
- Toolchains or drivers required for secure operation are no longer maintained
  for Pascal-era GPUs.
- Tokens-per-watt or tokens-per-dollar on a modest modern GPU (e.g. 3060/4060
  class) materially outperforms the P40 for the same workloads.
- Operational constraints (noise, thermals, rack space) dominate the value of
  the extra capacity.

## Legacy vs Investment

- **Legacy capacity**: keep P40 overlays, templates, and docs working on a
  best-effort basis; accept that some new models or engines may be unsupported.
- **Active investment**: add new features, engines, or complex workarounds
  specifically for Pascal/Maxwell.

This flake should treat P40 as **legacy capacity**: maintain existing paths,
avoid adding new engine integrations that do not naturally support Pascal, and
prefer investing engineering time in modern GPU workflows.

## Recommendation

- Keep Tesla/P40 as a **legacy path**: supported for existing workloads via
  `llama-cpp-python` and `ollama` overlays, but not a primary target for new
  features.
- Do not block new work on preserving P40 parity with modern GPUs when it would
  require invasive patches or diverging from upstream tooling.
- When two designs compete, prefer the one that keeps the modern GPU path
  simple, even if it means additional friction on legacy P40 setups.

## Non-Goals

- immediately deleting Tesla support from the flake
- pretending mini-PC anecdotes alone are enough to settle the decision
- committing to a specific replacement platform in the same PR

## Validation

- the repo has an explicit support posture for P40-class hardware
- future work can tell whether Tesla support is strategic, legacy, or sunset
- the retirement criteria are concrete enough to guide follow-up decisions
