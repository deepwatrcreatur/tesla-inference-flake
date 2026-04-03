# Agent Prompts

Read [`START-HERE.md`](./START-HERE.md) first.

## Prompt 1: CI Eval Cleanup

Work on [`01-ci-eval-cleanup.md`](./01-ci-eval-cleanup.md).

Create a branch named `ci/eval-cleanup`.

Task:
- remove redundant package evaluation from the CI matrix
- keep the current coverage shape, just cleaner and less noisy

## Prompt 2: Explicit K-Series Package Map

Work on [`02-explicit-k-series-package-map.md`](./02-explicit-k-series-package-map.md).

Create a branch named `refactor/explicit-k-series-package-map`.

Task:
- make `K20`, `K40`, and `K80` explicit in the module’s package map

## Prompt 3: Localhost Firewall Hardening

Work on [`03-localhost-firewall-hardening.md`](./03-localhost-firewall-hardening.md).

Create a branch named `fix/localhost-firewall-hardening`.

Task:
- treat `localhost` as local-only alongside `127.0.0.1` and `::1`
- avoid opening firewall rules unexpectedly for local-only configurations

## Prompt 4: Safer Template Firewall Defaults

Work on [`04-safer-template-firewall-defaults.md`](./04-safer-template-firewall-defaults.md).

Create a branch named `docs/safer-template-firewall-defaults`.

Task:
- make example templates safer by default
- prefer explicit allowed ports over disabling the firewall entirely

## Prompt 5: Enum Eval Coverage

Work on [`05-enum-eval-coverage.md`](./05-enum-eval-coverage.md).

Create a branch named `ci/enum-eval-coverage`.

Task:
- add cheap eval coverage for all supported GPU enum values
- do not pretend this is hardware-backed GPU testing

## Prompt 6: Option Validation Assertions

Work on [`06-option-validation-assertions.md`](./06-option-validation-assertions.md).

Create a branch named `feat/option-validation-assertions`.

Task:
- add a small amount of early validation for obviously invalid option
  combinations
