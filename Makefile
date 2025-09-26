# Makefile for Fiyuu KTDB Load Test

.PHONY: build run test clean docker-build docker-run help

# Variables
BINARY_NAME=fiyuu-ktdb-loadtest
DOCKER_IMAGE=fiyuu-ktdb-loadtest
DOCKER_TAG=latest

# Default target
all: build

# Build the application
build:
	@echo "Building $(BINARY_NAME)..."
	go build -o $(BINARY_NAME) .

# Run the application with default config
run: build
	@echo "Running $(BINARY_NAME)..."
	./$(BINARY_NAME) -c config.yaml

# Run with MySQL config
run-mysql: build
	@echo "Running with MySQL config..."
	./$(BINARY_NAME) -c configs/mysql.yaml -v

# Run with PostgreSQL config
run-postgres: build
	@echo "Running with PostgreSQL config..."
	./$(BINARY_NAME) -c configs/postgres.yaml -v

# Run with SQLite config
run-sqlite: build
	@echo "Running with SQLite config..."
	./$(BINARY_NAME) -c configs/sqlite.yaml -v

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# Clean build artifacts
clean:
	@echo "Cleaning..."
	go clean
	rm -f $(BINARY_NAME)
	rm -f coverage.out coverage.html
	rm -f *.json
	rm -f *.db

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

# Format code
fmt:
	@echo "Formatting code..."
	go fmt ./...

# Lint code
lint:
	@echo "Linting code..."
	golangci-lint run

# Docker build
docker-build:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

# Docker run
docker-run: docker-build
	@echo "Running Docker container..."
	docker run --rm -p 8080:8080 -v $(PWD)/configs:/app/configs $(DOCKER_IMAGE):$(DOCKER_TAG)

# Docker compose up
docker-up:
	@echo "Starting services with Docker Compose..."
	docker-compose up -d

# Docker compose down
docker-down:
	@echo "Stopping services..."
	docker-compose down

# Docker compose logs
docker-logs:
	@echo "Showing logs..."
	docker-compose logs -f

# Setup development environment
setup:
	@echo "Setting up development environment..."
	go mod download
	go mod tidy
	@echo "Creating results directory..."
	mkdir -p results
	@echo "Setup complete!"

# Install tools
install-tools:
	@echo "Installing development tools..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Help
help:
	@echo "Available targets:"
	@echo "  build          - Build the application"
	@echo "  run            - Run with default config"
	@echo "  run-mysql      - Run with MySQL config"
	@echo "  run-postgres   - Run with PostgreSQL config"
	@echo "  run-sqlite     - Run with SQLite config"
	@echo "  test           - Run tests"
	@echo "  test-coverage  - Run tests with coverage"
	@echo "  clean          - Clean build artifacts"
	@echo "  deps           - Download dependencies"
	@echo "  fmt            - Format code"
	@echo "  lint           - Lint code"
	@echo "  docker-build   - Build Docker image"
	@echo "  docker-run     - Run Docker container"
	@echo "  docker-up      - Start services with Docker Compose"
	@echo "  docker-down    - Stop services"
	@echo "  docker-logs    - Show logs"
	@echo "  setup          - Setup development environment"
	@echo "  install-tools  - Install development tools"
	@echo "  help           - Show this help"
