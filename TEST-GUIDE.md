# Fiyuu KTDB Web Server - Test Rehberi

SQL Server için optimize edilmiş test süreci. Adım adım nasıl test edeceğinizi anlatıyor.

## 🚀 Test Senaryoları

### 1. Hızlı Test (Docker ile)

#### Adım 1: SQL Server'ı Başlat
```bash
# SQL Server container'ını başlat
docker-compose up -d sqlserver

# SQL Server'ın hazır olmasını bekle (30-60 saniye)
docker-compose logs -f sqlserver
```

#### Adım 2: Web Server'ı Başlat
```bash
# Web server'ı başlat
docker-compose up -d webserver

# Logları kontrol et
docker-compose logs -f webserver
```

#### Adım 3: Test Et
```bash
# Health check
curl http://localhost:8080/api/v1/health

# Default query
curl http://localhost:8080/api/v1/query

# Database info
curl http://localhost:8080/api/v1/db/info
```

### 2. Manuel Test (Direkt Makinede)

#### Adım 1: Kurulum
```bash
# Ubuntu/Debian için
chmod +x install-ubuntu.sh
./install-ubuntu.sh

# CentOS/RHEL için
chmod +x install-centos.sh
./install-centos.sh
```

#### Adım 2: Environment Ayarları
```bash
# .env dosyasını düzenle
nano .env

# Gerekli ayarlar:
DB_TYPE=mssql
DB_HOST=localhost
DB_PORT=1433
DB_USERNAME=sa
DB_PASSWORD=YourStrong@Passw0rd
DB_NAME=master
CONNECTION_COUNT=10
DEFAULT_QUERY=SELECT @@VERSION as version, GETDATE() as current_time
```

#### Adım 3: Çalıştır
```bash
# Otomatik çalıştırma
./run.sh

# Veya manuel
go mod download
go build -o fiyuu-ktdb .
./fiyuu-ktdb
```

## 📡 API Test Komutları

### Temel Testler

#### 1. Health Check
```bash
curl -X GET http://localhost:8080/api/v1/health
```

**Beklenen Sonuç:**
```json
{
  "status": "healthy",
  "database": "connected",
  "uptime": "1m30s",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### 2. Default Query
```bash
curl -X GET http://localhost:8080/api/v1/query
```

**Beklenen Sonuç:**
```json
{
  "success": true,
  "data": [
    {
      "version": "Microsoft SQL Server 2022...",
      "current_time": "2024-01-01T12:00:00Z"
    }
  ],
  "duration": "5ms",
  "rows_affected": 1,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### 3. Custom Query
```bash
curl -X POST http://localhost:8080/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT name FROM sys.databases WHERE database_id > 4"}'
```

#### 4. Database Info
```bash
curl -X GET http://localhost:8080/api/v1/db/info
```

**Beklenen Sonuç:**
```json
{
  "type": "mssql",
  "host": "localhost",
  "port": 1433,
  "database": "master",
  "username": "sa",
  "ssl_mode": "disable",
  "max_open_conns": 100,
  "max_idle_conns": 10,
  "connection_count": 10
}
```

#### 5. Database Stats
```bash
curl -X GET http://localhost:8080/api/v1/db/stats
```

## 🔧 Load Testing

### Apache Bench ile Load Test
```bash
# Basit load test
ab -n 1000 -c 10 http://localhost:8080/api/v1/query

# Daha yoğun test
ab -n 10000 -c 50 http://localhost:8080/api/v1/query

# POST request test
ab -n 1000 -c 10 -p query.json -T application/json http://localhost:8080/api/v1/query
```

### query.json dosyası:
```json
{"query": "SELECT COUNT(*) as total FROM sys.objects"}
```

### Connection Count Test
```bash
# Farklı connection count'lar ile test et
export CONNECTION_COUNT=5
./fiyuu-ktdb

# Başka terminal'de
export CONNECTION_COUNT=20
./fiyuu-ktdb
```

## 🐛 Troubleshooting

### 1. SQL Server Bağlantı Sorunu
```bash
# SQL Server'ın çalıştığını kontrol et
telnet localhost 1433

# Docker container durumunu kontrol et
docker ps | grep sqlserver

# SQL Server loglarını kontrol et
docker-compose logs sqlserver
```

### 2. Port Çakışması
```bash
# Port kullanımını kontrol et
netstat -tlnp | grep 8080
netstat -tlnp | grep 1433

# Farklı port kullan
export SERVER_PORT=9090
./fiyuu-ktdb
```

### 3. Permission Sorunu
```bash
# Script'leri executable yap
chmod +x *.sh

# Go modülünü temizle
go clean -modcache
go mod download
```

### 4. Database Permission
```sql
-- SQL Server'da user oluştur
CREATE LOGIN testuser WITH PASSWORD = 'TestPassword123!';
CREATE USER testuser FOR LOGIN testuser;
GRANT SELECT ON SCHEMA::dbo TO testuser;
```

## 📊 Performance Monitoring

### 1. Real-time Monitoring
```bash
# Server loglarını takip et
tail -f /var/log/fiyuu-ktdb.log

# Docker logları
docker-compose logs -f webserver
```

### 2. Database Monitoring
```bash
# Database stats endpoint'i
curl http://localhost:8080/api/v1/db/stats

# Prometheus metrics (eğer etkinse)
curl http://localhost:8080/metrics
```

### 3. System Monitoring
```bash
# CPU ve memory kullanımı
htop

# Network bağlantıları
netstat -an | grep 8080
netstat -an | grep 1433
```

## 🧪 Test Senaryoları

### Senaryo 1: Basit Connectivity Test
```bash
# 1. Server'ı başlat
./fiyuu-ktdb

# 2. Health check
curl http://localhost:8080/api/v1/health

# 3. Default query
curl http://localhost:8080/api/v1/query

# 4. Database info
curl http://localhost:8080/api/v1/db/info
```

### Senaryo 2: Load Test
```bash
# 1. Server'ı başlat
export CONNECTION_COUNT=20
./fiyuu-ktdb

# 2. Load test çalıştır
ab -n 5000 -c 25 http://localhost:8080/api/v1/query

# 3. Database stats kontrol et
curl http://localhost:8080/api/v1/db/stats
```

### Senaryo 3: Custom Query Test
```bash
# 1. Server'ı başlat
./fiyuu-ktdb

# 2. Custom query test
curl -X POST http://localhost:8080/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT @@VERSION as version, DB_NAME() as current_db, USER_NAME() as current_user"}'

# 3. Error handling test
curl -X POST http://localhost:8080/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT * FROM non_existent_table"}'
```

## ✅ Test Checklist

- [ ] SQL Server bağlantısı çalışıyor
- [ ] Health check endpoint çalışıyor
- [ ] Default query endpoint çalışıyor
- [ ] Custom query endpoint çalışıyor
- [ ] Database info endpoint çalışıyor
- [ ] Database stats endpoint çalışıyor
- [ ] Connection count parametresi çalışıyor
- [ ] Error handling çalışıyor
- [ ] Load test başarılı
- [ ] Logging çalışıyor
- [ ] Graceful shutdown çalışıyor

## 📞 Destek

Sorun yaşarsanız:
1. Logları kontrol edin
2. Health check endpoint'ini test edin
3. Database bağlantısını kontrol edin
4. Issue açın

---

**Not**: Test öncesi SQL Server'ın çalıştığından ve erişilebilir olduğundan emin olun.
