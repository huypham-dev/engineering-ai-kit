# Code review

## What to look for (priority order)
1. Correctness bugs and regressions: wrong logic, broken contract, off-by-one, null handling, async/race issues, wrong error propagation.
2. Security: injection, authz/authn gaps, secrets in code or logs, unsafe deserialization, SSRF, XSS, path traversal, overly broad permissions (see security.md).
3. Data safety: migrations, destructive operations, backwards compatibility.
4. Missing edge cases and test gaps for the changed behaviour.
5. Performance problems with a realistic trigger (N+1 queries, unbounded loops, re-render storms).
6. Maintainability issues that will plausibly cause a bug. Pure style is out of scope unless it violates a documented repo rule.

## Classify every finding
- **Confirmed** — you can point to the line and describe a concrete input/state that produces wrong behaviour. Ideally verified by reading the callers or running a test.
- **Potential** — plausible but depends on something you could not verify (runtime config, caller behaviour, data shape). Say exactly what would confirm or dismiss it.
- **Nit** — optional, low impact. Keep to a minimum.

Never present a Potential concern as Confirmed. If you are unsure, it is Potential.

## Finding format
```
[Confirmed|Potential|Nit] <severity: high|medium|low> — <file>:<line>
What: <one sentence>
Why it matters: <concrete failure scenario>
Suggested fix: <short>
```

## Discipline
- Review the actual diff, not your memory of the plan.
- Read surrounding code before claiming a bug; many "bugs" are handled by the caller.
- Prefer fewer, high-signal findings over long lists.
- "No confirmed issues found" is a valid outcome. Say what you checked.
