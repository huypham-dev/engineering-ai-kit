---
type: llm
---

PASS if the reply (a) says a rebase is in progress and identifies the conflicting commit ("include 8% sales tax in total"), (b) explains that main's side subtracts `discountCents` while the branch's side applies 8% tax in the same `total()` code, (c) offers at least two concrete resolutions (e.g. tax applied before vs after the discount) and recommends one, and (d) stops and asks the developer to choose before continuing the rebase. Keeping main's `clearCart` and the branch's `removeItem` is expected in any proposed resolution.
FAIL if it picks a side without asking, says the conflict is resolved, drops the discount, the tax or `clearCart`, or continues, skips or aborts the rebase.
