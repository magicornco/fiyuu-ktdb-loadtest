#!/bin/bash

# Fiyuu KTDB Full Stack Runner Script
# Starts monitoring stack + web server + load test

set -e

echo "🚀 Starting Fiyuu KTDB Full Stack..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21+ first."
    exit 1
fi

echo "✅ Docker and Go are available"

# Load production environment variables
if [ -f "env.production" ]; then
    echo "📄 Loading production environment variables..."
    export $(cat env.production | grep -v '^#' | xargs)
else
    echo "❌ Production environment file not found: env.production"
    exit 1
fi

echo "🔧 Full Stack Configuration:"
echo "   Database: $DB_TYPE://$DB_HOST:$DB_PORT/$DB_NAME"
echo "   Prometheus: http://localhost:9090"
echo "   Grafana: http://localhost:3000"
echo "   Web Server: http://localhost:8080"
echo "   Connection Count: $CONNECTION_COUNT"

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p grafana/dashboards
mkdir -p grafana/datasources

# Start monitoring stack
echo "🌟 Starting monitoring stack..."
docker-compose up -d prometheus grafana

# Wait for services to be ready
echo "⏳ Waiting for monitoring services to start..."
sleep 15

# Build the application
echo "🔨 Building application..."
go mod download
go mod tidy
go build -o fiyuu-ktdb .

if [ ! -f "fiyuu-ktdb" ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Test database connection
echo "🔍 Testing database connection..."
if ./fiyuu-ktdb --server=true -v &
SERVER_PID=$!
sleep 5

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

# Start web server in background
echo "🌟 Starting web server..."
./fiyuu-ktdb &
WEB_SERVER_PID=$!

# Wait for web server to start
sleep 3

# Test metrics endpoint
echo "🔍 Testing metrics endpoint..."
if curl -s http://localhost:8080/metrics > /dev/null; then
    echo "✅ Metrics endpoint is working"
else
    echo "⚠️  Metrics endpoint might not be ready yet"
fi

echo ""
echo "🎉 Full stack started successfully!"
echo ""
echo "📊 Access URLs:"
echo "   Grafana Dashboard: http://localhost:3000 (admin/admin)"
echo "   Prometheus: http://localhost:9090"
echo "   Web Server: http://localhost:8080"
echo "   Health Check: http://localhost:8080/api/v1/health"
echo "   Metrics: http://localhost:8080/metrics"
echo "   Database Info: http://localhost:8080/api/v1/db/info"
echo ""
echo "🔑 Grafana Login:"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "📋 Available Commands:"
echo "   Start Load Test: ./run-production-loadtest.sh"
echo "   View Logs: docker-compose logs -f"
echo "   Stop All: docker-compose down && kill $WEB_SERVER_PID"
echo ""
echo "📊 Live Monitoring:"
echo "   Open Grafana: http://localhost:3000"
echo "   View Fiyuu KTDB dashboard"
echo "   Start load testing to see live metrics"
echo ""
echo "🛑 To stop everything:"
echo "   docker-compose down"
echo "   kill $WEB_SERVER_PID"
echo ""
echo "Press Ctrl+C to stop this script (services will continue running)"
echo ""

# Keep script running and show status
while true; do
    sleep 30
    echo "📊 Status Check - $(date)"
    
    # Check web server
    if curl -s http://localhost:8080/api/v1/health > /dev/null; then
        echo "✅ Web Server: Healthy"
    else
        echo "❌ Web Server: Unhealthy"
    fi
    
    # Check Prometheus
    if curl -s http://localhost:9090/-/healthy > /dev/null; then
        echo "✅ Prometheus: Healthy"
    else
        echo "❌ Prometheus: Unhealthy"
    fi
    
    # Check Grafana
    if curl -s http://localhost:3000/api/health > /dev/null; then
        echo "✅ Grafana: Healthy"
    else
        echo "❌ Grafana: Unhealthy"
    fi
    
    echo "---"
done
