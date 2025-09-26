#!/bin/bash

# Fiyuu KTDB Native Monitoring Runner
# Bu script native olarak kurulmuş Prometheus ve Grafana'yı başlatır

set -e

echo "🚀 Starting Fiyuu KTDB Native Monitoring Stack..."
echo "================================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root. Run as a regular user."
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Prometheus is installed
if ! command_exists prometheus; then
    echo "❌ Prometheus is not installed!"
    echo "Please run the installation script first:"
    echo "  ./scripts/installation/install-ubuntu.sh"
    echo "  or"
    echo "  ./scripts/installation/install-centos.sh"
    exit 1
fi

# Check if Grafana is installed
if ! command_exists grafana-server; then
    echo "❌ Grafana is not installed!"
    echo "Please run the installation script first:"
    echo "  ./scripts/installation/install-ubuntu.sh"
    echo "  or"
    echo "  ./scripts/installation/install-centos.sh"
    exit 1
fi

# Copy Prometheus configuration if it doesn't exist
if [ ! -f "/etc/prometheus/prometheus.yml" ]; then
    echo "📄 Copying Prometheus configuration..."
    sudo cp prometheus-native.yml /etc/prometheus/prometheus.yml
    sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
    echo "✅ Prometheus configuration copied"
fi

# Start Prometheus
echo "📊 Starting Prometheus..."
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Check Prometheus status
if sudo systemctl is-active --quiet prometheus; then
    echo "✅ Prometheus is running"
else
    echo "❌ Failed to start Prometheus"
    sudo systemctl status prometheus
    exit 1
fi

# Start Grafana
echo "📈 Starting Grafana..."
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Check Grafana status
if sudo systemctl is-active --quiet grafana-server; then
    echo "✅ Grafana is running"
else
    echo "❌ Failed to start Grafana"
    sudo systemctl status grafana-server
    exit 1
fi

# Wait a moment for services to fully start
echo "⏳ Waiting for services to fully start..."
sleep 5

# Test Prometheus
echo "🔍 Testing Prometheus..."
if curl -s http://localhost:9090 > /dev/null; then
    echo "✅ Prometheus is accessible at http://localhost:9090"
else
    echo "⚠️  Prometheus might not be fully ready yet"
fi

# Test Grafana
echo "🔍 Testing Grafana..."
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Grafana is accessible at http://localhost:3000"
else
    echo "⚠️  Grafana might not be fully ready yet"
fi

echo ""
echo "🎉 Native Monitoring Stack Started Successfully!"
echo ""
echo "📊 Access URLs:"
echo "   Prometheus: http://localhost:9090"
echo "   Grafana: http://localhost:3000 (admin/admin)"
echo ""
echo "🔧 Service Management:"
echo "   sudo systemctl status prometheus     # Check Prometheus status"
echo "   sudo systemctl status grafana-server # Check Grafana status"
echo "   sudo systemctl stop prometheus       # Stop Prometheus"
echo "   sudo systemctl stop grafana-server   # Stop Grafana"
echo "   sudo systemctl restart prometheus    # Restart Prometheus"
echo "   sudo systemctl restart grafana-server # Restart Grafana"
echo ""
echo "📈 Next Steps:"
echo "1. Start your Fiyuu KTDB web server:"
echo "   ./scripts/run.sh"
echo ""
echo "2. Configure Grafana datasource:"
echo "   - Go to http://localhost:3000"
echo "   - Login with admin/admin"
echo "   - Add Prometheus datasource: http://localhost:9090"
echo ""
echo "3. Import Fiyuu KTDB dashboard from grafana/dashboards/"
echo ""
echo "⚠️  Note: Make sure your Fiyuu KTDB web server is running"
echo "   and accessible at http://localhost:8080/metrics"
