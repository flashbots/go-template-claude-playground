# Heavily inspired by Lighthouse: https://github.com/sigp/lighthouse/blob/stable/Makefile
# and Reth: https://github.com/paradigmxyz/reth/blob/main/Makefile
.DEFAULT_GOAL := help

VERSION := $(shell git describe --tags --always --dirty="-dev")

# Project configuration
PROJECT_NAME ?= go-template
COVERAGE_FILE ?= /tmp/$(PROJECT_NAME).cover.tmp
COVERAGE_THRESHOLD ?= 60

# Build configuration
LDFLAGS := -X github.com/flashbots/go-template/common.Version=$(VERSION)
BUILD_FLAGS := -trimpath -ldflags "$(LDFLAGS)" -v

##@ Help

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: v
v: ## Show the version
	@echo "Version: $(VERSION)"

##@ Build

.PHONY: clean
clean: ## Clean the build directory
	rm -rf build/

build:
	@mkdir -p ./build

.PHONY: build-cli
build-cli: build ## Build the CLI
	go build $(BUILD_FLAGS) -o ./build/cli cmd/cli/main.go

.PHONY: build-httpserver
build-httpserver: build ## Build the HTTP server
	go build $(BUILD_FLAGS) -o ./build/httpserver cmd/httpserver/main.go

.PHONY: build-all
build-all: build-cli build-httpserver ## Build all binaries
	@echo "Binaries built in ./build/"

##@ Run

.PHONY: run-cli
run-cli: build-cli ## Build and run the CLI
	./build/cli

.PHONY: run-httpserver
run-httpserver: build-httpserver ## Build and run the HTTP server
	./build/httpserver

##@ Test & Development

.PHONY: test
test: ## Run tests
	go test ./...

.PHONY: test-race
test-race: ## Run tests with race detector
	go test -race ./...

.PHONY: test-coverage
test-coverage: ## Run tests and check coverage threshold
	@go test -coverprofile=coverage.out ./...
	@coverage=$$(go tool cover -func=coverage.out | grep total | awk '{print $$3}' | tr -d '%'); \
	echo "Coverage: $${coverage}%"; \
	if [ "$${coverage%.*}" -lt "$(COVERAGE_THRESHOLD)" ]; then \
		echo "Coverage $${coverage}% is below threshold $(COVERAGE_THRESHOLD)%"; \
		exit 1; \
	fi
	@rm -f coverage.out

.PHONY: lint
lint: ## Run linters
	@test -z "$$(gofmt -d -s .)" || (echo "gofmt check failed:"; gofmt -d -s .; exit 1)
	@test -z "$$(gofumpt -d -extra .)" || (echo "gofumpt check failed:"; gofumpt -d -extra .; exit 1)
	go vet ./...
	staticcheck ./...
	golangci-lint run
	# nilaway ./...

.PHONY: fmt
fmt: ## Format the code
	gofmt -s -w .
	gci write --skip-generated -s standard -s default .
	gofumpt -w -extra .
	go mod tidy

.PHONY: gofumpt
gofumpt: ## Run gofumpt
	gofumpt -l -w -extra .

.PHONY: lt
lt: lint test ## Run linters and tests

.PHONY: ci
ci: lint test-race ## Run all CI checks

.PHONY: cover
cover: ## Run tests with coverage
	go test -coverprofile=$(COVERAGE_FILE) ./...
	go tool cover -func $(COVERAGE_FILE)
	rm -f $(COVERAGE_FILE)

.PHONY: cover-html
cover-html: ## Run tests with coverage and open the HTML report
	go test -coverprofile=$(COVERAGE_FILE) ./...
	go tool cover -html=$(COVERAGE_FILE)
	rm -f $(COVERAGE_FILE)

##@ Docker

.PHONY: docker-cli
docker-cli: ## Build the CLI Docker image
	DOCKER_BUILDKIT=1 docker build \
		--platform linux/amd64 \
		--build-arg VERSION=$(VERSION) \
		--file cli.dockerfile \
		--tag $(PROJECT_NAME)-cli:$(VERSION) \
		--tag $(PROJECT_NAME)-cli:latest \
	.

.PHONY: docker-httpserver
docker-httpserver: ## Build the HTTP server Docker image
	DOCKER_BUILDKIT=1 docker build \
		--platform linux/amd64 \
		--build-arg VERSION=$(VERSION) \
		--file httpserver.dockerfile \
		--tag $(PROJECT_NAME)-httpserver:$(VERSION) \
		--tag $(PROJECT_NAME)-httpserver:latest \
	.

##@ Tools

.PHONY: install-tools
install-tools: ## Install development tools
	go install mvdan.cc/gofumpt@latest
	go install github.com/daixiang0/gci@latest
	go install honnef.co/go/tools/cmd/staticcheck@latest
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
