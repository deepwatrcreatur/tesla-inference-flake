# Enum Eval Coverage

Status: `blocked`
Suggested branch: `ci/enum-eval-coverage`
Priority: `medium`

## Goal

Add cheap full-enum evaluation coverage for supported GPU values without
pretending CI provides real hardware-backed validation.

## Blocked

K20, K40, M60, and P100 package expressions fail to evaluate on standard
CI providers due to environment constraints. Expanding the matrix to cover
all enum values causes CI errors. The evaluation-matrix job in ci.yml is
intentionally limited to P40, M40, and K80 until this constraint is
resolved — see the comment in that file. Do not add the excluded GPUs back
without first verifying the CI environment supports their evaluation.
