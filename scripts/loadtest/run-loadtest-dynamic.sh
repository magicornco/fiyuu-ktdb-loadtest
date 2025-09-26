#!/bin/bash

# Fiyuu KTDB Dynamic Load Test Runner
# Usage: ./run-loadtest-dynamic.sh [connection_count] [duration] [config_file]

set -e

# Default values
DEFAULT_CONNECTIONS=10
DEFAULT_DURATION="5m"
DEFAULT_CONFIG="configs/production.yaml"

# Parse command line arguments
CONNECTION_COUNT=${1:-$DEFAULT_CONNECTIONS}
DURATION=${2:-$DEFAULT_DURATION}
CONFIG_FILE=${3:-$DEFAULT_CONFIG}

echo "🚀 Starting Fiyuu KTDB Dynamic Load Test..."
echo "   Connection Count: $CONNECTION_COUNT"
echo "   Duration: $DURATION"
echo "   Config File: $CONFIG_FILE"

# Load production environment variables
if [ -f "env.production" ]; then
    echo "📄 Loading production environment variables..."
    export $(cat env.production | grep -v '^#' | xargs)
else
    echo "❌ Production environment file not found: env.production"
    exit 1
fi

# Override connection count for this test
export CONNECTION_COUNT=$CONNECTION_COUNT
export DB_MAX_OPEN_CONNS=$((CONNECTION_COUNT * 2))

echo "🔧 Load Test Configuration:"
echo "   Database: $DB_TYPE://$DB_HOST:$DB_PORT/$DB_NAME"
echo "   Username: $DB_USERNAME"
echo "   Connection Count: $CONNECTION_COUNT"
echo "   Max Open Connections: $DB_MAX_OPEN_CONNS"
echo "   Duration: $DURATION"
echo "   Log Level: $LOG_LEVEL"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    echo "Available config files:"
    ls -la configs/ 2>/dev/null || echo "No configs directory found"
    exit 1
fi

# Download dependencies
echo "📦 Downloading dependencies..."
go mod download
go mod tidy

# Build the application
echo "🔨 Building application..."
go build -o fiyuu-ktdb .

if [ ! -f "fiyuu-ktdb" ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Test database connection first
echo "🔍 Testing database connection..."
if ./fiyuu-ktdb --server=true -v &
SERVER_PID=$!
sleep 3

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

# Start the load test
echo "🌟 Starting Fiyuu KTDB Dynamic Load Test..."
echo "   Config File: $CONFIG_FILE"
echo "   Mode: Load Test (not web server)"
echo "   Target Database: TFICarrierTrackNEW"
echo "   Connection Count: $CONNECTION_COUNT"
echo "   Duration: $DURATION"
echo ""
echo "Press Ctrl+C to stop the load test"
echo ""

# Run the load test
./fiyuu-ktdb --server=false -c "$CONFIG_FILE" -v
