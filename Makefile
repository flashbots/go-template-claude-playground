# Heavily inspired by Lighthouse: https://github.com/sigp/lighthouse/blob/stable/Makefile
# and Reth: https://github.com/paradigmxyz/reth/blob/main/Makefile
.DEFAULT_GOAL := help

# Build configuration
VERSION := $(shell git describe --tags --always --dirty="-dev")
BUILD_DIR := ./build
MODULE := github.com/flashbots/go-template
LDFLAGS := -X $(MODULE)/common.Version=$(VERSION)

# Docker configuration
DOCKER_REGISTRY ?= your-registry

# Coverage configuration
COVER_FILE := /tmp/go-template.cover.tmp

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
	rm -rf $(BUILD_DIR)/

.PHONY: build-cli
build-cli: ## Build the CLI
	@mkdir -p $(BUILD_DIR)
	go build -trimpath -ldflags "$(LDFLAGS)" -v -o $(BUILD_DIR)/cli cmd/cli/main.go

.PHONY: build-httpserver
build-httpserver: ## Build the HTTP server
	@mkdir -p $(BUILD_DIR)
	go build -trimpath -ldflags "$(LDFLAGS)" -v -o $(BUILD_DIR)/httpserver cmd/httpserver/main.go

.PHONY: build
build: build-cli build-httpserver ## Build all binaries
	@echo "Binaries built in $(BUILD_DIR)/"

.PHONY: install
install: ## Install binaries to GOPATH/bin
	go install -trimpath -ldflags "$(LDFLAGS)" ./cmd/cli
	go install -trimpath -ldflags "$(LDFLAGS)" ./cmd/httpserver

##@ Test & Development

.PHONY: test
test: ## Run tests
	go test ./...

.PHONY: test-race
test-race: ## Run tests with race detector
	go test -race ./...

.PHONY: lint
lint: ## Run linters
	@if [ -n "$$(gofmt -d -s . 2>&1)" ]; then gofmt -d -s .; exit 1; fi
	@if [ -n "$$(gofumpt -d -extra . 2>&1)" ]; then gofumpt -d -extra .; exit 1; fi
	go vet ./...
	staticcheck ./...
	golangci-lint run
	# nilaway ./...

.PHONY: fmt
fmt: ## Format the code
	gofmt -s -w .
	gci write .
	gofumpt -w -extra .
	go mod tidy

.PHONY: gofumpt
gofumpt: ## Run gofumpt
	gofumpt -l -w -extra .

.PHONY: lt
lt: lint test ## Run linters and tests

.PHONY: cover
cover: ## Run tests with coverage
	go test -coverprofile=$(COVER_FILE) ./...
	go tool cover -func $(COVER_FILE)
	rm -f $(COVER_FILE)

.PHONY: cover-html
cover-html: ## Run tests with coverage and open the HTML report
	go test -coverprofile=$(COVER_FILE) ./...
	go tool cover -html=$(COVER_FILE)
	rm -f $(COVER_FILE)

.PHONY: run-cli
run-cli: build-cli ## Build and run the CLI
	$(BUILD_DIR)/cli

.PHONY: run-httpserver
run-httpserver: build-httpserver ## Build and run the HTTP server
	$(BUILD_DIR)/httpserver

##@ Docker

.PHONY: docker-cli
docker-cli: ## Build the CLI Docker image
	DOCKER_BUILDKIT=1 docker build \
		--platform linux/amd64 \
		--build-arg VERSION=$(VERSION) \
		--file cli.dockerfile \
		--tag $(DOCKER_REGISTRY)/cli:$(VERSION) \
		--tag $(DOCKER_REGISTRY)/cli:latest \
	.

.PHONY: docker-httpserver
docker-httpserver: ## Build the HTTP server Docker image
	DOCKER_BUILDKIT=1 docker build \
		--platform linux/amd64 \
		--build-arg VERSION=$(VERSION) \
		--file httpserver.dockerfile \
		--tag $(DOCKER_REGISTRY)/httpserver:$(VERSION) \
		--tag $(DOCKER_REGISTRY)/httpserver:latest \
	.

.PHONY: docker
docker: docker-cli docker-httpserver ## Build all Docker images
