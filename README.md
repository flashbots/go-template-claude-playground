# go-template

[![Goreport status](https://goreportcard.com/badge/github.com/flashbots/go-template)](https://goreportcard.com/report/github.com/flashbots/go-template)
[![Test status](https://github.com/flashbots/go-template/actions/workflows/checks.yml/badge.svg?branch=main)](https://github.com/flashbots/go-template/actions?query=workflow%3A%22Checks%22)

Toolbox and building blocks for new Go projects, to get started quickly and right-footed!

## What's Included

This template provides scaffolding for Go projects with two entry points:

- **CLI application** (`cmd/cli/main.go`) - Command-line interface using [urfave/cli](https://cli.urfave.org/)
- **HTTP server** (`cmd/httpserver/main.go`) - Web server with graceful shutdown, health checks, and metrics

### Features

- [`Makefile`](Makefile) with `lint`, `test`, `build`, `fmt` and more
- Linting with `gofmt`, `gofumpt`, `go vet`, `staticcheck` and `golangci-lint`
- Logging setup using [slog](https://pkg.go.dev/golang.org/x/exp/slog) (with debug and JSON options)
- [GitHub Workflows](.github/workflows/) for linting, testing, releasing, and Docker publishing
- HTTP server with graceful shutdown, health endpoints, and Prometheus metrics
- Postgres database layer with automatic migrations
- [nilaway](https://github.com/uber-go/nilaway) for nil safety analysis

---

## Quick Start

### Build and Run the HTTP Server

```bash
# Build the HTTP server
make build-httpserver

# Run it
./build/httpserver

# The server runs on:
# - API: http://127.0.0.1:8080
# - Metrics: http://127.0.0.1:8090/metrics
```

### Build and Run the CLI

```bash
# Build the CLI
make build-cli

# Run it
./build/cli --help
```

---

## Project Structure

| Directory | Description |
|-----------|-------------|
| `cmd/cli/` | CLI entry point using urfave/cli |
| `cmd/httpserver/` | HTTP server entry point |
| `httpserver/` | Server implementation (chi router, graceful shutdown) |
| `database/` | Postgres database layer using sqlx |
| `database/migrations/` | Database migrations (run automatically on connect) |
| `metrics/` | VictoriaMetrics-based Prometheus metrics |
| `common/` | Shared utilities (logging setup) |

---

## HTTP Server Endpoints

The server runs two HTTP servers: the main API (default `:8080`) and metrics (default `:8090`).

### Main API (port 8080)

| Endpoint | Description |
|----------|-------------|
| `/api` | Main API endpoint |
| `/livez` | Liveness probe - returns 200 if server is running |
| `/readyz` | Readiness probe - returns 200 if server is ready to accept traffic |
| `/drain` | Enable drain mode (readiness returns 503) |
| `/undrain` | Disable drain mode |
| `/debug/*` | pprof endpoints (when `--pprof` flag is enabled) |

### Metrics (port 8090)

| Endpoint | Description |
|----------|-------------|
| `/metrics` | Prometheus metrics |

### CLI Flags

```
--listen-addr    API listen address (default: 127.0.0.1:8080)
--metrics-addr   Metrics listen address (default: 127.0.0.1:8090)
--log-json       Output logs in JSON format
--log-debug      Enable debug logging
--log-uid        Add unique ID to all log messages
--log-service    Service name for logs (default: your-project)
--pprof          Enable pprof debug endpoints
--drain-seconds  Seconds to wait during drain (default: 45)
```

---

## Development

### Install Dev Dependencies

```bash
go install mvdan.cc/gofumpt@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install go.uber.org/nilaway/cmd/nilaway@latest
go install github.com/daixiang0/gci@latest
```

### Common Commands

```bash
make lint   # Run all linters
make test   # Run tests
make fmt    # Format code
make lt     # Run lint + test
make build  # Build all binaries
```

### Database Tests

Database tests require a running Postgres instance and the `RUN_DB_TESTS=1` environment variable:

```bash
# Start Postgres
docker run -d --name postgres-test -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=postgres \
  postgres

# Run tests with database
RUN_DB_TESTS=1 make test

# Cleanup
docker rm -f postgres-test
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `RUN_DB_TESTS` | Set to `1` to run database integration tests |
| `DB_DONT_APPLY_SCHEMA` | Set to any value to skip automatic migration on database connect |

---

## Related Resources

- [flashbots-repository-template](https://github.com/flashbots/flashbots-repository-template) - Public project setup
- [go-utils](https://github.com/flashbots/go-utils) - Common Go utilities
- [goperf.dev](https://goperf.dev) - Advanced Go performance tips & tricks

---

Pick and choose whatever is useful to you! Don't feel the need to use everything, or even to follow this structure.
