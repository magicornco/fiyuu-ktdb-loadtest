# Fiyuu KTDB Load Test Rehberi

Load test sistemi nasıl çalışır ve nasıl kullanılır.

## 🔄 Load Test Nasıl Çalışır?

### 1. **Web Server vs Load Test**

**Web Server Modu:**
- HTTP endpoint'leri sunar
- Her istek geldiğinde tek query çalıştırır
- Real-time API servisi

**Load Test Modu:**
- Belirtilen sayıda concurrent user simüle eder
- Her user sürekli query çalıştırır
- Performance metrics toplar

### 2. **Load Test Sistemi**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Load Tester   │───▶│   Worker Pool    │───▶│  SQL Server     │
│                 │    │                  │    │                 │
│ - Config        │    │ - Worker 1       │    │ - Connection 1  │
│ - Metrics       │    │ - Worker 2       │    │ - Connection 2  │
│ - Duration      │    │ - Worker N       │    │ - Connection N  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🚀 Load Test Çalıştırma

### 1. **Web Server Modu (Default)**
```bash
# Web server olarak çalıştır
./fiyuu-ktdb

# Veya açıkça belirt
./fiyuu-ktdb --server=true
```

### 2. **Load Test Modu**
```bash
# Load test olarak çalıştır
./fiyuu-ktdb --server=false

# Veya kısa hali
./fiyuu-ktdb -s=false
```

## ⚙️ Load Test Konfigürasyonu

### config.yaml dosyası:
```yaml
# Database configuration
database:
  type: mssql
  host: localhost
  port: 1433
  username: sa
  password: YourStrong@Passw0rd
  database: testdb
  
  # Connection pool settings
  max_open_conns: 100
  max_idle_conns: 10
  conn_max_lifetime: 1h
  conn_max_idle_time: 10m

# Load test configuration
test:
  duration: 5m                   # Test süresi
  concurrent_users: 10           # Eşzamanlı kullanıcı sayısı
  ramp_up_time: 30s              # Ramp-up süresi
  think_time: 1s                 # Query'ler arası bekleme
  
  # Test queries
  queries:
    - name: "select_version"
      sql: "SELECT @@VERSION as version, GETDATE() as current_time"
      weight: 40                 # Ağırlık (1-100)
      type: "select"
      
    - name: "select_databases"
      sql: "SELECT name FROM sys.databases WHERE database_id > 4"
      weight: 30
      type: "select"
      
    - name: "select_tables"
      sql: "SELECT COUNT(*) as table_count FROM INFORMATION_SCHEMA.TABLES"
      weight: 20
      type: "select"
      
    - name: "select_connections"
      sql: "SELECT COUNT(*) as connection_count FROM sys.dm_exec_connections"
      weight: 10
      type: "select"

# Metrics configuration
metrics:
  enabled: true
  interval: 10s
  output_file: "load_test_metrics.json"
  
  prometheus:
    enabled: false
    port: 8080
    path: "/metrics"
```

## 📊 Load Test Çalıştırma Örnekleri

### 1. **Basit Load Test**
```bash
# 5 dakika, 10 concurrent user
./fiyuu-ktdb --server=false -c config.yaml
```

### 2. **Yoğun Load Test**
```bash
# 30 dakika, 50 concurrent user
# config.yaml'da ayarları değiştir:
# duration: 30m
# concurrent_users: 50
./fiyuu-ktdb --server=false -c config.yaml
```

### 3. **Verbose Logging ile**
```bash
# Detaylı loglar ile
./fiyuu-ktdb --server=false -c config.yaml -v
```

## 🔧 Load Test Parametreleri

### Environment Variables ile:
```bash
# Test parametrelerini environment variable ile ayarla
export CONNECTION_COUNT=20
export DB_PASSWORD=YourStrong@Passw0rd

# Load test çalıştır
./fiyuu-ktdb --server=false
```

### Config dosyası ile:
```yaml
test:
  duration: 10m
  concurrent_users: 25
  ramp_up_time: 1m
  think_time: 500ms
```

## 📈 Load Test Sonuçları

### 1. **Console Output**
```
=== Load Test Statistics ===
Total Queries: 1500
Successful: 1485
Failed: 15
Success Rate: 99.00%
Average Duration: 45ms

Query Statistics:
  select_version: 600 total (99.50% success)
  select_databases: 450 total (98.67% success)
  select_tables: 300 total (99.33% success)
  select_connections: 150 total (98.00% success)
===========================
```

### 2. **JSON Metrics File**
```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "total_queries": 1500,
  "successful_queries": 1485,
  "failed_queries": 15,
  "success_rate": 99.0,
  "average_duration": "45ms",
  "query_stats": {
    "select_version": {
      "success": 597,
      "failed": 3
    }
  }
}
```

## 🎯 Load Test Senaryoları

### Senaryo 1: Basit Performance Test
```yaml
test:
  duration: 5m
  concurrent_users: 10
  ramp_up_time: 30s
  think_time: 1s
```

### Senaryo 2: Stress Test
```yaml
test:
  duration: 30m
  concurrent_users: 100
  ramp_up_time: 2m
  think_time: 100ms
```

### Senaryo 3: Endurance Test
```yaml
test:
  duration: 2h
  concurrent_users: 20
  ramp_up_time: 5m
  think_time: 2s
```

## 🔍 Load Test Monitoring

### 1. **Real-time Monitoring**
```bash
# Load test çalışırken başka terminal'de
tail -f load_test_metrics.json

# Database stats kontrol et
curl http://localhost:8080/api/v1/db/stats
```

### 2. **Database Monitoring**
```sql
-- SQL Server'da aktif bağlantıları kontrol et
SELECT 
    session_id,
    login_name,
    host_name,
    program_name,
    status,
    cpu_time,
    memory_usage
FROM sys.dm_exec_sessions 
WHERE is_user_process = 1
ORDER BY cpu_time DESC;
```

## 🐛 Load Test Troubleshooting

### 1. **Connection Timeout**
```yaml
database:
  max_open_conns: 200
  conn_max_lifetime: 2h
```

### 2. **Memory Issues**
```yaml
test:
  concurrent_users: 50  # Azalt
  think_time: 2s        # Artır
```

### 3. **Database Lock**
```yaml
test:
  think_time: 5s        # Artır
  queries:
    - weight: 10        # Ağırlıkları azalt
```

## 📋 Load Test Checklist

- [ ] SQL Server çalışıyor
- [ ] Config dosyası hazır
- [ ] Test queries çalışıyor
- [ ] Connection pool ayarları uygun
- [ ] Monitoring hazır
- [ ] Metrics dosyası yazılabilir
- [ ] Graceful shutdown çalışıyor

## 🚀 Hızlı Başlangıç

```bash
# 1. Config dosyasını hazırla
cp configs/sqlserver.yaml config.yaml

# 2. Database bilgilerini güncelle
nano config.yaml

# 3. Load test çalıştır
./fiyuu-ktdb --server=false -c config.yaml -v

# 4. Sonuçları kontrol et
cat load_test_metrics.json
```

---

**Not**: Load test öncesi SQL Server'ın yeterli kaynağa sahip olduğundan emin olun.
