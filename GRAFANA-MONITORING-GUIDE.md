# Grafana Live Monitoring Guide

Canlı istatistikleri Grafana ile görüntüleme rehberi.

## 🚀 Hızlı Başlangıç

### **1. Full Stack Başlatma:**
```bash
# Tüm servisleri başlat (monitoring + web server)
chmod +x run-full-stack.sh
./run-full-stack.sh
```

### **2. Sadece Monitoring Stack:**
```bash
# Sadece Grafana + Prometheus
chmod +x run-monitoring.sh
./run-monitoring.sh
```

### **3. Manuel Başlatma:**
```bash
# Monitoring stack
docker-compose up -d prometheus grafana

# Web server
./run-production.sh

# Load test
./run-production-loadtest.sh
```

## 📊 Grafana Dashboard

### **Erişim:**
- **URL:** http://localhost:3000
- **Username:** admin
- **Password:** admin

### **Dashboard Özellikleri:**

#### **1. Database Connections Panel:**
- **Open Connections:** Açık connection sayısı
- **Idle Connections:** Boşta bekleyen connection'lar
- **In Use Connections:** Kullanımda olan connection'lar

#### **2. Connection Wait Statistics:**
- **Wait Count:** Connection bekleme sayısı
- **Wait Duration:** Connection bekleme süresi (ms)

#### **3. Connection Closures:**
- **Max Idle Closed:** Max idle nedeniyle kapatılan connection'lar
- **Max Idle Time Closed:** Max idle time nedeniyle kapatılan connection'lar
- **Max Lifetime Closed:** Max lifetime nedeniyle kapatılan connection'lar

#### **4. Server Information:**
- **Database Type:** SQL Server
- **Database Host:** 172.16.201.34
- **Database Name:** TFICarrierTrackNEW

#### **5. Connection Usage Percentage:**
- **Connection Usage %:** Connection kullanım yüzdesi

## 🔧 Prometheus Metrics

### **Metrics Endpoint:**
```bash
# Metrics endpoint'i
curl http://localhost:8080/metrics
```

### **Available Metrics:**
```
# Connection metrics
fiyuu_ktdb_connections_open
fiyuu_ktdb_connections_idle
fiyuu_ktdb_connections_in_use
fiyuu_ktdb_connections_wait_count
fiyuu_ktdb_connections_wait_duration
fiyuu_ktdb_connections_max_idle_closed
fiyuu_ktdb_connections_max_idle_time_closed
fiyuu_ktdb_connections_max_lifetime_closed

# Server info
fiyuu_ktdb_server_info
```

## 📈 Live Monitoring Senaryoları

### **Senaryo 1: Web Server Monitoring**
```bash
# 1. Full stack'i başlat
./run-full-stack.sh

# 2. Grafana'yı aç
# http://localhost:3000

# 3. Dashboard'u görüntüle
# Fiyuu KTDB Monitoring Dashboard

# 4. API test et
curl http://localhost:8080/api/v1/query
```

### **Senaryo 2: Load Test Monitoring**
```bash
# 1. Monitoring stack'i başlat
./run-monitoring.sh

# 2. Web server'ı başlat
./run-production.sh

# 3. Load test'i başlat
./run-production-loadtest.sh

# 4. Grafana'da canlı metrikleri izle
```

### **Senaryo 3: 10K Connection Test**
```bash
# 1. Full stack'i başlat
./run-full-stack.sh

# 2. Grafana dashboard'u aç

# 3. 10K connection load test
export CONNECTION_COUNT=10000
./fiyuu-ktdb --server=false -c configs/production.yaml -v

# 4. Canlı connection metriklerini izle
```

## 🎯 Dashboard Panels

### **Panel 1: Database Connections**
```promql
# Open connections
fiyuu_ktdb_connections_open

# Idle connections
fiyuu_ktdb_connections_idle

# In use connections
fiyuu_ktdb_connections_in_use
```

### **Panel 2: Connection Wait Statistics**
```promql
# Wait count
fiyuu_ktdb_connections_wait_count

# Wait duration
fiyuu_ktdb_connections_wait_duration
```

### **Panel 3: Connection Closures**
```promql
# Max idle closed
fiyuu_ktdb_connections_max_idle_closed

# Max idle time closed
fiyuu_ktdb_connections_max_idle_time_closed

# Max lifetime closed
fiyuu_ktdb_connections_max_lifetime_closed
```

### **Panel 4: Connection Usage Percentage**
```promql
# Connection usage percentage
(fiyuu_ktdb_connections_in_use / fiyuu_ktdb_connections_open) * 100
```

## 🔍 Monitoring Best Practices

### **1. Real-time Monitoring:**
- Dashboard refresh rate: 5s
- Time range: Last 1 hour
- Auto-refresh: Enabled

### **2. Alerting (Opsiyonel):**
```yaml
# Grafana alert rules
- alert: HighConnectionUsage
  expr: (fiyuu_ktdb_connections_in_use / fiyuu_ktdb_connections_open) * 100 > 90
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High connection usage detected"
```

### **3. Performance Tuning:**
```bash
# Connection pool monitoring
curl http://localhost:8080/api/v1/db/stats

# Health check
curl http://localhost:8080/api/v1/health

# Database info
curl http://localhost:8080/api/v1/db/info
```

## 📊 Expected Metrics

### **Normal Operation:**
```
Open Connections: 10-100
Idle Connections: 5-50
In Use Connections: 5-50
Wait Count: 0-10
Wait Duration: 0-100ms
```

### **High Load (10K Connections):**
```
Open Connections: 10000
Idle Connections: 100-1000
In Use Connections: 9000-9500
Wait Count: 0-100
Wait Duration: 0-500ms
```

### **Connection Issues:**
```
Wait Count: > 1000
Wait Duration: > 1000ms
Connection Usage: > 95%
```

## 🐛 Troubleshooting

### **1. Grafana Not Loading:**
```bash
# Check Grafana status
docker-compose logs grafana

# Restart Grafana
docker-compose restart grafana
```

### **2. No Metrics in Grafana:**
```bash
# Check Prometheus
curl http://localhost:9090/targets

# Check metrics endpoint
curl http://localhost:8080/metrics

# Check web server
curl http://localhost:8080/api/v1/health
```

### **3. Dashboard Not Found:**
```bash
# Check dashboard files
ls -la grafana/dashboards/

# Restart Grafana
docker-compose restart grafana
```

## 🚀 Quick Commands

### **Start Everything:**
```bash
./run-full-stack.sh
```

### **Start Monitoring Only:**
```bash
./run-monitoring.sh
```

### **Start Load Test:**
```bash
./run-production-loadtest.sh
```

### **Stop Everything:**
```bash
docker-compose down
```

### **View Logs:**
```bash
docker-compose logs -f
```

## 📋 Monitoring Checklist

- [ ] Grafana accessible at http://localhost:3000
- [ ] Prometheus accessible at http://localhost:9090
- [ ] Web server accessible at http://localhost:8080
- [ ] Metrics endpoint working at http://localhost:8080/metrics
- [ ] Dashboard showing live data
- [ ] Connection metrics updating
- [ ] Load test generating metrics
- [ ] Alerts configured (if needed)

---

**Not**: Grafana dashboard'u 5 saniyede bir otomatik olarak güncellenir. Load test çalıştırdığınızda canlı olarak connection metriklerini görebilirsiniz.
