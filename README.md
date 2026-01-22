# go-template

[![Goreport status](https://goreportcard.com/badge/github.com/flashbots/go-template)](https://goreportcard.com/report/github.com/flashbots/go-template)
[![Test status](https://github.com/flashbots/go-template/actions/workflows/checks.yml/badge.svg?branch=main)](https://github.com/flashbots/go-template/actions?query=workflow%3A%22Checks%22)

Toolbox and building blocks for new Go projects, to get started quickly and right-footed!

## What's Included

This template provides two entry points:

- **CLI** ([`cmd/cli/main.go`](/cmd/cli/main.go)) - Command-line application using [urfave/cli](https://cli.urfave.org/)
- **HTTP Server** ([`cmd/httpserver/main.go`](/cmd/httpserver/main.go)) - Web server with graceful shutdown, health checks, and Prometheus metrics

Key features:
- Makefile with `lint`, `test`, `build`, `fmt` and more
- Linting with `gofmt`, `gofumpt`, `go vet`, `staticcheck` and `golangci-lint`
- Structured logging using [slog](https://pkg.go.dev/golang.org/x/exp/slog) (with debug and JSON options)
- [GitHub Workflows](.github/workflows/) for linting, testing, releasing, and Docker publishing
- Postgres database with migrations
- [NilAway](https://github.com/uber-go/nilaway) for nil safety checking

---

## Quick Start

```bash
# Build the HTTP server
make build-httpserver

# Run the server
./build/httpserver

# In another terminal, test the endpoints
curl http://localhost:8080/livez    # Health check
curl http://localhost:8090/metrics  # Prometheus metrics
```

---

## Project Structure

| Directory | Description |
|-----------|-------------|
| `cmd/cli/` | CLI application entry point (urfave/cli) |
| `cmd/httpserver/` | HTTP server entry point |
| `httpserver/` | Server implementation (chi router, graceful shutdown) |
| `database/` | Postgres layer using sqlx |
| `database/migrations/` | In-memory migrations registered in `Migrations` variable |
| `metrics/` | VictoriaMetrics-based Prometheus metrics with HTTP middleware |
| `common/` | Shared utilities including structured logging setup |

---

## HTTP Server

### Endpoints

| Endpoint | Port | Description |
|----------|------|-------------|
| `/api` | 8080 | Main API endpoint |
| `/livez` | 8080 | Liveness probe (always returns OK) |
| `/readyz` | 8080 | Readiness probe (returns 503 when draining) |
| `/drain` | 8080 | Enable drain mode (marks server not ready) |
| `/undrain` | 8080 | Disable drain mode (marks server ready) |
| `/debug/*` | 8080 | pprof endpoints (when `--pprof` enabled) |
| `/metrics` | 8090 | Prometheus metrics |

### CLI Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--listen-addr` | `127.0.0.1:8080` | Address for API server |
| `--metrics-addr` | `127.0.0.1:8090` | Address for Prometheus metrics |
| `--log-json` | `false` | Output logs in JSON format |
| `--log-debug` | `false` | Enable debug logging |
| `--log-uid` | `false` | Add UUID to all log messages |
| `--log-service` | `your-project` | Service name in logs |
| `--pprof` | `false` | Enable pprof debug endpoints |
| `--drain-seconds` | `45` | Seconds to wait during drain |

---

## Development

### Build Commands

```bash
make build-cli        # Build CLI binary to ./build/cli
make build-httpserver # Build HTTP server binary to ./build/httpserver
make build            # Build all binaries
```

### Lint and Test

```bash
make lint   # Run all linters
make test   # Run all tests
make fmt    # Format code
make lt     # Run both lint and test
```

### Install Dev Dependencies

```bash
go install mvdan.cc/gofumpt@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install go.uber.org/nilaway/cmd/nilaway@latest
go install github.com/daixiang0/gci@latest
```

### Database Tests

Database tests require a running Postgres instance and are enabled with the `RUN_DB_TESTS` environment variable:

```bash
# Start the database
docker run -d --name postgres-test -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=postgres \
  postgres

# Run the tests
RUN_DB_TESTS=1 make test

# Stop the database
docker rm -f postgres-test
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `RUN_DB_TESTS` | Set to `1` to run database tests |
| `DB_DONT_APPLY_SCHEMA` | Set to skip automatic migration on database connection |

---

## Related Resources

- [flashbots/flashbots-repository-template](https://github.com/flashbots/flashbots-repository-template) - Public project setup template
- [flashbots/go-utils](https://github.com/flashbots/go-utils) - Common Go utilities
- [goperf.dev](https://goperf.dev) - Advanced Golang tips & tricks

---

Pick and choose whatever is useful to you! Don't feel the need to use everything, or even to follow this structure.
