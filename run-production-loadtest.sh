#!/bin/bash

# Fiyuu KTDB Production Load Test Runner Script

set -e

echo "🚀 Starting Fiyuu KTDB Production Load Test..."

# Load production environment variables
if [ -f "env.production" ]; then
    echo "📄 Loading production environment variables..."
    export $(cat env.production | grep -v '^#' | xargs)
else
    echo "❌ Production environment file not found: env.production"
    exit 1
fi

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21+ first."
    exit 1
fi

echo "🔧 Production Load Test Configuration:"
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

# Test database connection first
echo "🔍 Testing database connection..."
if ./fiyuu-ktdb --server=true -v &
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

# Start the load test
echo "🌟 Starting Fiyuu KTDB Production Load Test..."
echo "   Config File: configs/production.yaml"
echo "   Mode: Load Test (not web server)"
echo "   Target Database: TFICarrierTrackNEW"
echo ""
echo "Press Ctrl+C to stop the load test"
echo ""

# Run the load test
./fiyuu-ktdb --server=false -c configs/production.yaml -v
