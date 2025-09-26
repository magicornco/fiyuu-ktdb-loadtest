#!/bin/bash

# Fiyuu KTDB Production Stress Test Runner
# Bu script production database'de kontrollü stress testi yapar

set -e

echo "🚀 Starting Fiyuu KTDB Production Stress Test..."
echo "⚠️  WARNING: This will create significant load on production database!"
echo "📊 Stress Configuration: 100 concurrent users, 15 minutes duration"
echo ""

# Load production environment variables
if [ -f "env.production" ]; then
    echo "📄 Loading production environment variables..."
    export $(cat env.production | grep -v '^#' | xargs)
else
    echo "❌ Production environment file not found: env.production"
    exit 1
fi

# Override for stress testing
export CONNECTION_COUNT=100
export DB_MAX_OPEN_CONNS=200

echo "🔧 Stress Test Configuration:"
echo "   Database: $DB_TYPE://$DB_HOST:$DB_PORT/$DB_NAME"
echo "   Username: $DB_USERNAME"
echo "   Connection Count: $CONNECTION_COUNT (STRESS)"
echo "   Max Open Connections: $DB_MAX_OPEN_CONNS (STRESS)"
echo "   Duration: 15 minutes"
echo "   Concurrent Users: 100"
echo "   Think Time: 1 second"
echo ""

# Confirmation prompt
read -p "🤔 Are you sure you want to run STRESS test on production database? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Stress test cancelled by user"
    exit 1
fi

echo "✅ Confirmed. Starting stress test..."

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

# Start the stress test
echo "🌟 Starting Fiyuu KTDB Production Stress Test..."
echo "   Config File: configs/production-stress.yaml"
echo "   Mode: Load Test (not web server)"
echo "   Target Database: TFICarrierTrackNEW"
echo "   Connection Count: 100 (STRESS)"
echo "   Duration: 15 minutes"
echo "   Concurrent Users: 100"
echo ""
echo "⚠️  Monitoring production database stress..."
echo "Press Ctrl+C to stop the stress test"
echo ""

# Run the stress test
./fiyuu-ktdb --server=false -c configs/production-stress.yaml -v
