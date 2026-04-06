# 08 P40 Retirement Threshold

Status: `in-progress`
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
