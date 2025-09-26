#!/bin/bash

# Fiyuu KTDB Monitoring Stack Runner Script

set -e

echo "🚀 Starting Fiyuu KTDB Monitoring Stack..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are available"

# Load production environment variables
if [ -f "env.production" ]; then
    echo "📄 Loading production environment variables..."
    export $(cat env.production | grep -v '^#' | xargs)
else
    echo "❌ Production environment file not found: env.production"
    exit 1
fi

echo "🔧 Monitoring Configuration:"
echo "   Prometheus: http://localhost:9090"
echo "   Grafana: http://localhost:3000 (admin/admin)"
echo "   Web Server: http://localhost:8080"
echo "   Metrics Endpoint: http://localhost:8080/metrics"

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p grafana/dashboards
mkdir -p grafana/datasources

# Start monitoring stack
echo "🌟 Starting monitoring stack..."
docker-compose up -d prometheus grafana

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
echo "🔍 Checking service status..."
if docker-compose ps | grep -q "Up"; then
    echo "✅ Services are running"
else
    echo "❌ Some services failed to start"
    docker-compose logs
    exit 1
fi

# Test Prometheus
echo "🔍 Testing Prometheus..."
if curl -s http://localhost:9090/-/healthy > /dev/null; then
    echo "✅ Prometheus is healthy"
else
    echo "⚠️  Prometheus might not be ready yet"
fi

# Test Grafana
echo "🔍 Testing Grafana..."
if curl -s http://localhost:3000/api/health > /dev/null; then
    echo "✅ Grafana is healthy"
else
    echo "⚠️  Grafana might not be ready yet"
fi

echo ""
echo "🎉 Monitoring stack started successfully!"
echo ""
echo "📊 Access URLs:"
echo "   Grafana Dashboard: http://localhost:3000"
echo "   Prometheus: http://localhost:9090"
echo "   Web Server: http://localhost:8080"
echo "   Metrics: http://localhost:8080/metrics"
echo ""
echo "🔑 Grafana Login:"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "📋 Next Steps:"
echo "1. Start the web server: ./run-production.sh"
echo "2. Open Grafana: http://localhost:3000"
echo "3. View the Fiyuu KTDB dashboard"
echo "4. Start load testing to see live metrics"
echo ""
echo "🛑 To stop monitoring stack:"
echo "   docker-compose down"
echo ""
echo "📊 To view logs:"
echo "   docker-compose logs -f"
