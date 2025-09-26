#!/bin/bash

# Fiyuu KTDB Native Monitoring Stopper
# Bu script native olarak kurulmuş Prometheus ve Grafana'yı durdurur

set -e

echo "🛑 Stopping Fiyuu KTDB Native Monitoring Stack..."
echo "================================================="

# Stop Grafana
echo "📈 Stopping Grafana..."
if sudo systemctl is-active --quiet grafana-server; then
    sudo systemctl stop grafana-server
    echo "✅ Grafana stopped"
else
    echo "ℹ️  Grafana was not running"
fi

# Stop Prometheus
echo "📊 Stopping Prometheus..."
if sudo systemctl is-active --quiet prometheus; then
    sudo systemctl stop prometheus
    echo "✅ Prometheus stopped"
else
    echo "ℹ️  Prometheus was not running"
fi

echo ""
echo "🎉 Native Monitoring Stack Stopped Successfully!"
echo ""
echo "🔧 To restart monitoring:"
echo "   ./scripts/monitoring/run-native-monitoring.sh"
echo ""
echo "🔧 To disable auto-start:"
echo "   sudo systemctl disable prometheus"
echo "   sudo systemctl disable grafana-server"
