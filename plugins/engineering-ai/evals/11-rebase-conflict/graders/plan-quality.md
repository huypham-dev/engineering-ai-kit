---
type: llm
---

PASS if the reply is a rebase plan for feature/cart-tax onto main that (a) lists the branch's commits "add removeItem" and "include 8% sales tax in total", (b) names src/cart.js as a predicted or likely conflict, (c) proposes a backup branch or another restore point, (d) names `npm test` (or `node --test`) as verification and attributes it to package.json, and (e) explicitly asks the developer to approve before rebasing.
FAIL if it already rebased or merged, proposes resolving with `git merge`/`git pull`, invents a command not present in the repo, or omits the approval request.
