---
type: llm
---

PASS if the reply is an implementation plan that (a) lists src/cart.js and a test file such as test/cart.test.js as the files to change, (b) covers the not-found case as an acceptance criterion or edge case, (c) names `npm test` (or `node --test`) as the verification command and attributes it to package.json, and (d) explicitly asks the developer to approve before implementing.
FAIL if it claims code was already written, invents a test/lint command not present in the repo (e.g. jest, vitest, eslint), or omits the approval request.
