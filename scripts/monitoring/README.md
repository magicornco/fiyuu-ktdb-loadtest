# Monitoring Scripts

Bu klasör Grafana ve Prometheus monitoring için scriptler içerir.

## 📊 Scriptler

### `run-monitoring.sh`
- **Amaç**: Sadece monitoring servislerini başlatır
- **Kullanım**: `./run-monitoring.sh`
- **Özellikler**:
  - Prometheus ve Grafana başlatır
  - Web server olmadan sadece monitoring
  - Docker Compose kullanır

### `run-full-stack.sh`
- **Amaç**: Tüm stack'i başlatır
- **Kullanım**: `./run-full-stack.sh`
- **Özellikler**:
  - SQL Server + Web Server + Prometheus + Grafana
  - Tam monitoring stack
  - Docker Compose kullanır

## 🚀 Kullanım

### Sadece Monitoring
```bash
# Prometheus ve Grafana'yı başlat
./run-monitoring.sh

# Erişim:
# - Grafana: http://localhost:3000 (admin/admin)
# - Prometheus: http://localhost:9090
```

### Tam Stack
```bash
# Tüm servisleri başlat
./run-full-stack.sh

# Erişim:
# - Web Server: http://localhost:8080
# - Grafana: http://localhost:3000 (admin/admin)
# - Prometheus: http://localhost:9090
# - SQL Server: localhost:1433
```

## 📈 Monitoring Özellikleri

### Grafana Dashboard
- **Database Connections**: Açık, boşta, kullanımda
- **Connection Pool Stats**: Wait count, duration
- **Connection Lifecycle**: Max idle/lifetime closed
- **Server Info**: Database type, host, name

### Prometheus Metrics
- `fiyuu_ktdb_connections_open` - Açık connection sayısı
- `fiyuu_ktdb_connections_idle` - Boşta connection sayısı
- `fiyuu_ktdb_connections_in_use` - Kullanımda connection sayısı
- `fiyuu_ktdb_connections_wait_count` - Bekleyen connection sayısı
- `fiyuu_ktdb_connections_wait_duration` - Bekleme süresi

## 🔧 Servis Yönetimi

### Servisleri Başlat
```bash
# Sadece monitoring
docker-compose up -d prometheus grafana

# Tam stack
docker-compose up -d
```

### Servisleri Durdur
```bash
# Sadece monitoring
docker-compose down prometheus grafana

# Tam stack
docker-compose down
```

### Logları İzle
```bash
# Tüm servisler
docker-compose logs -f

# Belirli servis
docker-compose logs -f webserver
docker-compose logs -f prometheus
docker-compose logs -f grafana
```

## 📊 Dashboard Erişimi

### Grafana
- **URL**: http://localhost:3000
- **Username**: admin
- **Password**: admin
- **Dashboard**: Fiyuu KTDB Dashboard

### Prometheus
- **URL**: http://localhost:9090
- **Metrics**: http://localhost:8080/metrics
- **Targets**: http://localhost:9090/targets
