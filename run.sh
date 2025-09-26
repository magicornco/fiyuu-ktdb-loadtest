#!/bin/bash

# Fiyuu KTDB Web Server - Direct Machine Run Script

set -e

echo "🚀 Starting Fiyuu KTDB Web Server..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21+ first."
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
REQUIRED_VERSION="1.21"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Go version $GO_VERSION is too old. Please install Go $REQUIRED_VERSION or higher."
    exit 1
fi

echo "✅ Go version: $GO_VERSION"

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "📄 Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  No .env file found. Using system environment variables or defaults."
fi

# Set default environment variables if not set
export SERVER_HOST=${SERVER_HOST:-"0.0.0.0"}
export SERVER_PORT=${SERVER_PORT:-"8080"}
export DB_TYPE=${DB_TYPE:-"mssql"}
export DB_HOST=${DB_HOST:-"localhost"}
export DB_PORT=${DB_PORT:-"1433"}
export DB_USERNAME=${DB_USERNAME:-"sa"}
export DB_NAME=${DB_NAME:-"master"}
export DB_SSL_MODE=${DB_SSL_MODE:-"disable"}
export DB_MAX_OPEN_CONNS=${DB_MAX_OPEN_CONNS:-"100"}
export DB_MAX_IDLE_CONNS=${DB_MAX_IDLE_CONNS:-"10"}
export DB_CONN_MAX_LIFETIME=${DB_CONN_MAX_LIFETIME:-"1h"}
export DB_CONN_MAX_IDLE_TIME=${DB_CONN_MAX_IDLE_TIME:-"10m"}
export CONNECTION_COUNT=${CONNECTION_COUNT:-"10"}
export DEFAULT_QUERY=${DEFAULT_QUERY:-"SELECT 1 as test, GETDATE() as current_time"}
export LOG_LEVEL=${LOG_LEVEL:-"info"}
export LOG_FORMAT=${LOG_FORMAT:-"text"}

# Check required environment variables
if [ -z "$DB_PASSWORD" ]; then
    echo "❌ DB_PASSWORD environment variable is required!"
    echo "Please set it in your .env file or export it:"
    echo "export DB_PASSWORD='your_password_here'"
    exit 1
fi

echo "🔧 Configuration:"
echo "   Server: $SERVER_HOST:$SERVER_PORT"
echo "   Database: $DB_TYPE://$DB_HOST:$DB_PORT/$DB_NAME"
echo "   Username: $DB_USERNAME"
echo "   Connection Count: $CONNECTION_COUNT"
echo "   Log Level: $LOG_LEVEL"

# Download dependencies
echo "📦 Downloading dependencies..."
go mod download
go mod tidy

# Build the application
echo "🔨 Building application..."
go build -o fiyuu-ktdb .

# Check if build was successful
if [ ! -f "fiyuu-ktdb" ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Test database connection
echo "🔍 Testing database connection..."
if ./fiyuu-ktdb -v &
SERVER_PID=$!
sleep 3

# Test health endpoint
if curl -s http://localhost:$SERVER_PORT/api/v1/health > /dev/null; then
    echo "✅ Database connection successful!"
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
else
    echo "❌ Database connection failed!"
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
    exit 1
fi

# Start the server
echo "🌟 Starting Fiyuu KTDB Web Server..."
echo "   Health Check: http://localhost:$SERVER_PORT/api/v1/health"
echo "   Default Query: http://localhost:$SERVER_PORT/api/v1/query"
echo "   Database Info: http://localhost:$SERVER_PORT/api/v1/db/info"
echo "   Database Stats: http://localhost:$SERVER_PORT/api/v1/db/stats"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Run the server
./fiyuu-ktdb
