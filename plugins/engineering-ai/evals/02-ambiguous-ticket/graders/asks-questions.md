---
type: llm
---

PASS if the reply identifies that the ticket is ambiguous, asks at least two specific clarifying questions that would change the implementation (for example: percentage vs fixed amount, per item vs whole cart, rounding of cents, whether discounts stack, what "the old system" did), and does NOT present a final plan as ready to implement.
FAIL if it picks an interpretation and presents a plan as ready for approval without asking, or if it writes code.
