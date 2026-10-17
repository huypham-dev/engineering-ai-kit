# Security and sensitive data

## Never
- Read, print, copy, summarize or commit secrets: API keys, tokens, passwords, private keys, certificates, session cookies, production connection strings.
- Open these files unless the developer explicitly asks and the task requires it: `.env`, `.env.*` (except `.env.example`/`.env.sample`/`.env.template`), `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*`, `id_ed25519*`, `credentials*`, `secrets.*`, `*.keystore`, `google-services.json`/`GoogleService-Info.plist` with real values, `.envrc`, `.claude/settings.local.json` and `.claude/settings.json` (may contain `env` blocks with credentials), `~/.aws`, `~/.ssh`, `~/.npmrc`, `~/.netrc`.
- Run commands that print the environment wholesale (`env`, `printenv`, `set`) or echo secret variables.
- Connect to, deploy to, migrate, or run commands against production or shared environments.
- Disable security controls (auth checks, TLS verification, CSRF protection, input validation) to make something work.

## When you need configuration
Use example/template files, type definitions or documentation to learn variable *names*. If a real value is required, ask the developer to supply it through their normal mechanism; do not ask them to paste secrets into chat.

## In code you write
- Validate and encode untrusted input at boundaries; use parameterized queries.
- No secrets, tokens or personal data in source, tests, fixtures, logs, error messages or analytics.
- Least privilege for new permissions, scopes, IAM roles and CORS rules.
- Flag any change touching authentication, authorization, payments, crypto, PII or data deletion as **high risk** and call it out for human review.

## If you encounter a secret
Stop using it. Do not repeat it. Tell the developer which file/line contains what looks like a secret so they can rotate it.

## Advisory vs enforced
These rules are instructions; they reduce risk but do not guarantee it. The plugin's `PreToolUse` hook enforces a small subset (see docs/security-model.md). Real protection comes from permissions, sandboxing, branch protection and secret management outside Claude.
