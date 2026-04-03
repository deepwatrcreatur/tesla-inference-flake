# Explicit K-Series Package Map

Status: `blocked`
Suggested branch: `refactor/explicit-k-series-package-map`
Priority: `high`

## Goal

Make `K20`, `K40`, and `K80` explicit in the module’s package map even if they
currently resolve to the same package.

## Blocked

K20 and K40 package expressions fail to evaluate on standard CI providers.
Until CI can cover them, making them explicit in the package map would add
entries with no CI validation. Do not attempt this work until the CI
environment constraint is resolved (see work item 05).
