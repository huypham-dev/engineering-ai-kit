# Adapter: backend (Node.js / TypeScript and other stacks)

Use this to *discover* conventions. Do not assume a framework, ORM or test runner.

## Signals by stack
| Stack | Signals |
|---|---|
| Node/TS | `package.json` with `express`, `fastify`, `@nestjs/*`, `koa`, `hono`, `@trpc/*`, `graphql`; `src/server.*`, `src/routes` |
| Python | `pyproject.toml`, `requirements*.txt`, `setup.cfg`, `manage.py` (Django), `fastapi`/`flask` imports |
| Go | `go.mod`, `cmd/`, `internal/` |
| Java/Kotlin | `pom.xml`, `build.gradle(.kts)`, `src/main/java` |
| .NET | `*.sln`, `*.csproj` |
| Ruby | `Gemfile`, `config/routes.rb` |
| PHP | `composer.json`, `artisan` |

## What to discover
| Topic | Where to look |
|---|---|
| Entry points & layering | Router/controller/service/repository folders; DI setup (NestJS modules, etc.) |
| Data layer | ORM/query builder (Prisma `schema.prisma`, TypeORM, Sequelize, Drizzle, Knex, SQLAlchemy, GORM, JPA); migrations folder and how migrations are created |
| API contracts | OpenAPI/Swagger files, GraphQL schema, protobufs, shared DTO/validation (zod, class-validator, pydantic) |
| Tests | Test runner config; unit vs integration split; how integration tests get a DB (docker-compose, testcontainers, in-memory) |
| Config | Config loader and `.env.example` (names only — never open real `.env`) |
| Observability | Logger in use and log format; error reporting; metrics |
| Lint/format/typecheck | Language-native tools as configured (`eslint`, `ruff`, `black`, `mypy`, `golangci-lint`, `gofmt`, `ktlint`, `spotless`, `dotnet format`, `rubocop`, `phpstan`) — only if present in config or CI |

## Common risk areas
Backward-compatible API and schema changes, migrations (reversibility, locking, data backfill), transactions and idempotency, authz on every new endpoint, input validation, pagination limits, timeouts and retries on outbound calls, N+1 queries, logging of PII/secrets, concurrency and race conditions.

## Verification hints
Integration tests may require services (DB, queue, cache). If they are not available, run unit tests and report integration tests as COULD NOT RUN with the missing dependency. Never point tests at shared or production databases.
