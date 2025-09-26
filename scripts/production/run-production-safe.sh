#!/bin/bash

# Fiyuu KTDB Production Safe Load Test Runner
# Bu script production database'de güvenli yük testi yapar

set -e

echo "🚀 Starting Fiyuu KTDB Production Safe Load Test..."
echo "⚠️  WARNING: This will create load on production database!"
echo "📊 Safe Configuration: 20 concurrent users, 5 minutes duration"
echo ""

# Load production environment variables
if [ -f "env.production" ]; then
    echo "📄 Loading production environment variables..."
    export $(cat env.production | grep -v '^#' | xargs)
else
    echo "❌ Production environment file not found: env.production"
    exit 1
fi

# Override for safe testing
export CONNECTION_COUNT=20
export DB_MAX_OPEN_CONNS=50

echo "🔧 Safe Load Test Configuration:"
echo "   Database: $DB_TYPE://$DB_HOST:$DB_PORT/$DB_NAME"
echo "   Username: $DB_USERNAME"
echo "   Connection Count: $CONNECTION_COUNT (SAFE)"
echo "   Max Open Connections: $DB_MAX_OPEN_CONNS (SAFE)"
echo "   Duration: 5 minutes"
echo "   Concurrent Users: 20"
echo "   Think Time: 2 seconds"
echo ""

# Confirmation prompt
read -p "🤔 Are you sure you want to run load test on production database? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Load test cancelled by user"
    exit 1
fi

echo "✅ Confirmed. Starting safe load test..."

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

# Start the safe load test
echo "🌟 Starting Fiyuu KTDB Production Safe Load Test..."
echo "   Config File: configs/production-safe.yaml"
echo "   Mode: Load Test (not web server)"
echo "   Target Database: TFICarrierTrackNEW"
echo "   Connection Count: 20 (SAFE)"
echo "   Duration: 5 minutes"
echo "   Concurrent Users: 20"
echo ""
echo "⚠️  Monitoring production database load..."
echo "Press Ctrl+C to stop the load test"
echo ""

# Run the safe load test
./fiyuu-ktdb --server=false -c configs/production-safe.yaml -v
