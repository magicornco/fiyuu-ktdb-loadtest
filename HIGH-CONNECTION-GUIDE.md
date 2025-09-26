# High Connection Load Test Guide

10,000 connection ile yüksek performanslı load test rehberi.

## 🚀 10K Connection Ayarları

### **Production Environment:**
```bash
# env.production
DB_MAX_OPEN_CONNS=10000
DB_MAX_IDLE_CONNS=100
CONNECTION_COUNT=10000
```

### **Production Config:**
```yaml
# configs/production.yaml
database:
  max_open_conns: 10000
  max_idle_conns: 100

test:
  concurrent_users: 10000
  duration: 10m
  ramp_up_time: 1m
```

## ⚡ Yüksek Connection Test Senaryoları

### **1. Basit 10K Connection Test:**
```bash
# Production load test
./run-production-loadtest.sh
```

### **2. Aşamalı Connection Test:**
```bash
# 1K connection
export CONNECTION_COUNT=1000
./fiyuu-ktdb --server=false -c configs/production.yaml

# 5K connection
export CONNECTION_COUNT=5000
./fiyuu-ktdb --server=false -c configs/production.yaml

# 10K connection
export CONNECTION_COUNT=10000
./fiyuu-ktdb --server=false -c configs/production.yaml
```

### **3. Stress Test:**
```bash
# Maksimum connection ile stress test
export CONNECTION_COUNT=10000
export DB_MAX_OPEN_CONNS=10000
./fiyuu-ktdb --server=false -c configs/production.yaml -v
```

## 📊 Performance Monitoring

### **1. Database Connection Monitoring:**
```sql
-- SQL Server'da aktif bağlantıları kontrol et
SELECT 
    COUNT(*) as total_connections,
    COUNT(CASE WHEN is_user_process = 1 THEN 1 END) as user_connections,
    COUNT(CASE WHEN is_user_process = 0 THEN 1 END) as system_connections
FROM sys.dm_exec_sessions;

-- En çok CPU kullanan bağlantılar
SELECT TOP 10
    session_id,
    login_name,
    host_name,
    program_name,
    cpu_time,
    memory_usage,
    status
FROM sys.dm_exec_sessions 
WHERE is_user_process = 1
ORDER BY cpu_time DESC;
```

### **2. System Resource Monitoring:**
```bash
# CPU ve memory kullanımı
htop

# Network bağlantıları
netstat -an | grep 1433 | wc -l

# Process monitoring
ps aux | grep fiyuu-ktdb
```

### **3. Application Monitoring:**
```bash
# Real-time metrics
curl http://localhost:8080/api/v1/db/stats

# Health check
curl http://localhost:8080/api/v1/health
```

## 🔧 Optimizasyon Ayarları

### **1. SQL Server Optimizasyon:**
```sql
-- Connection timeout ayarları
EXEC sp_configure 'remote query timeout', 0;
EXEC sp_configure 'query wait', -1;

-- Memory ayarları
EXEC sp_configure 'max server memory', 8192; -- 8GB
EXEC sp_configure 'min server memory', 2048; -- 2GB

-- Connection ayarları
EXEC sp_configure 'user connections', 0; -- Unlimited
```

### **2. Application Optimizasyon:**
```yaml
# configs/production.yaml
database:
  max_open_conns: 10000
  max_idle_conns: 100
  conn_max_lifetime: 30m  # Daha kısa lifetime
  conn_max_idle_time: 5m  # Daha kısa idle time

test:
  concurrent_users: 10000
  ramp_up_time: 5m        # Daha uzun ramp-up
  think_time: 100ms       # Daha kısa think time
```

### **3. System Optimizasyon:**
```bash
# Linux kernel ayarları
echo 'net.core.somaxconn = 65535' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog = 65535' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog = 5000' >> /etc/sysctl.conf
sysctl -p

# File descriptor limit
ulimit -n 65535
```

## 🎯 Test Senaryoları

### **Senaryo 1: Connection Burst Test**
```bash
# Ani connection artışı testi
export CONNECTION_COUNT=10000
export DB_MAX_OPEN_CONNS=10000
./fiyuu-ktdb --server=false -c configs/production.yaml
```

### **Senaryo 2: Sustained Load Test**
```yaml
# configs/sustained-load.yaml
test:
  duration: 1h
  concurrent_users: 10000
  ramp_up_time: 10m
  think_time: 50ms
```

### **Senaryo 3: Connection Pool Test**
```bash
# Farklı pool boyutları ile test
for conns in 1000 5000 10000; do
    export CONNECTION_COUNT=$conns
    export DB_MAX_OPEN_CONNS=$conns
    echo "Testing with $conns connections..."
    ./fiyuu-ktdb --server=false -c configs/production.yaml
done
```

## 📈 Expected Results

### **10K Connection Test Sonuçları:**
```
=== Load Test Statistics ===
Total Queries: 50000
Successful: 49500
Failed: 500
Success Rate: 99.00%
Average Duration: 150ms
Max Duration: 2000ms
Min Duration: 10ms

Connection Pool Stats:
  Max Open Connections: 10000
  Open Connections: 10000
  In Use: 8500
  Idle: 1500
  Wait Count: 0
  Wait Duration: 0ms
===========================
```

## 🐛 Troubleshooting

### **1. Connection Timeout:**
```bash
# Connection timeout ayarlarını artır
export DB_CONN_MAX_LIFETIME=2h
export DB_MAX_OPEN_CONNS=15000
```

### **2. Memory Issues:**
```bash
# Memory kullanımını azalt
export DB_MAX_IDLE_CONNS=50
export CONNECTION_COUNT=5000
```

### **3. Database Lock:**
```bash
# Think time'ı artır
# config.yaml'da:
# think_time: 1s
```

## ✅ 10K Connection Checklist

- [ ] SQL Server 10K connection destekliyor
- [ ] System resources yeterli (CPU, Memory, Network)
- [ ] Kernel parameters optimize edildi
- [ ] Connection pool ayarları uygun
- [ ] Monitoring hazır
- [ ] Error handling çalışıyor
- [ ] Graceful shutdown test edildi

## 🚀 Quick Start

```bash
# 1. Production environment'ı yükle
source env.production

# 2. 10K connection test çalıştır
./run-production-loadtest.sh

# 3. Sonuçları kontrol et
cat production_metrics.json
```

---

**Not**: 10K connection test öncesi SQL Server'ın yeterli kaynağa sahip olduğundan ve connection limit'lerinin uygun olduğundan emin olun.
