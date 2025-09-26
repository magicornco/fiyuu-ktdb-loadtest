#!/bin/bash

# Fiyuu KTDB Load Test - 10 Connections

set -e

echo "🚀 Starting Fiyuu KTDB Load Test with 10 Connections..."

# Load production environment variables
if [ -f "env.production" ]; then
    echo "📄 Loading production environment variables..."
    export $(cat env.production | grep -v '^#' | xargs)
else
    echo "❌ Production environment file not found: env.production"
    exit 1
fi

# Override connection count for this test
export CONNECTION_COUNT=10
export DB_MAX_OPEN_CONNS=50

echo "🔧 Load Test Configuration:"
echo "   Database: $DB_TYPE://$DB_HOST:$DB_PORT/$DB_NAME"
echo "   Username: $DB_USERNAME"
echo "   Connection Count: $CONNECTION_COUNT"
echo "   Max Open Connections: $DB_MAX_OPEN_CONNS"
echo "   Log Level: $LOG_LEVEL"

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
echo "🌟 Starting Fiyuu KTDB Load Test with 10 Connections..."
echo "   Config File: configs/production.yaml"
echo "   Mode: Load Test (not web server)"
echo "   Target Database: TFICarrierTrackNEW"
echo "   Connection Count: 10"
echo ""
echo "Press Ctrl+C to stop the load test"
echo ""

# Run the load test
./fiyuu-ktdb --server=false -c configs/production.yaml -v
