# Fiyuu KTDB Load Test

🚀 **Go ile yazılmış kapsamlı SQL Server load testing aracı**

Asenkron web server ve yüksek performanslı load testing sistemi. SQL Server için optimize edilmiş, Grafana ile canlı monitoring desteği.

[![Go Version](https://img.shields.io/badge/Go-1.21+-blue.svg)](https://golang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SQL Server](https://img.shields.io/badge/Database-SQL%20Server-red.svg)](https://www.microsoft.com/en-us/sql-server)
[![Grafana](https://img.shields.io/badge/Monitoring-Grafana-orange.svg)](https://grafana.com/)

## 🚀 Özellikler

- **SQL Server Optimized**: Microsoft SQL Server için optimize edilmiş
- **Asenkron Web Server**: Yüksek performanslı HTTP API
- **Gerçekçi Load Testing**: 10K+ concurrent users desteği
- **Canlı Monitoring**: Grafana + Prometheus entegrasyonu
- **Environment Variables**: Tamamen parametrik konfigürasyon
- **Docker Desteği**: Kolay deployment ve scaling
- **Connection Pooling**: Optimize edilmiş database connection yönetimi
- **Real-time Metrics**: 5 saniyede bir güncellenen canlı grafikler

## 📋 Gereksinimler

- Go 1.21+
- Docker & Docker Compose (opsiyonel)
- MySQL 8.0+ / PostgreSQL 15+ / SQLite 3+

## 🛠️ Kurulum

### 1. Kaynak Koddan Kurulum

```bash
# Repository'yi klonlayın
git clone <repository-url>
cd fiyuu-ktdb-loadtest

# Dependencies'leri yükleyin
make deps

# Uygulamayı build edin
make build
```

### 2. Docker ile Kurulum

```bash
# Tüm servisleri başlatın (MySQL, PostgreSQL, Prometheus, Grafana)
make docker-up

# Sadece load test uygulamasını çalıştırın
make docker-run
```

## ⚙️ Konfigürasyon

### Temel Konfigürasyon

`config.yaml` dosyasını düzenleyerek test parametrelerinizi ayarlayabilirsiniz:

```yaml
database:
  type: mysql
  host: localhost
  port: 3306
  username: root
  password: password
  database: testdb

test:
  duration: 5m
  concurrent_users: 10
  ramp_up_time: 30s
  think_time: 1s
  
  queries:
    - name: "select_users"
      sql: "SELECT * FROM users LIMIT 10"
      weight: 40
      type: "select"
```

### Veritabanı Konfigürasyonları

- **MySQL**: `configs/mysql.yaml`
- **PostgreSQL**: `configs/postgres.yaml`
- **SQLite**: `configs/sqlite.yaml`

## 🚀 Kullanım

### Temel Kullanım

```bash
# Default konfigürasyon ile çalıştır
./fiyuu-ktdb-loadtest

# Belirli bir konfigürasyon dosyası ile çalıştır
./fiyuu-ktdb-loadtest -c configs/mysql.yaml

# Verbose logging ile çalıştır
./fiyuu-ktdb-loadtest -c configs/mysql.yaml -v
```

### Makefile Komutları

```bash
# MySQL ile test
make run-mysql

# PostgreSQL ile test
make run-postgres

# SQLite ile test
make run-sqlite

# Docker ile çalıştır
make docker-up
```

### CLI Parametreleri

```bash
Usage:
  fiyuu-ktdb-loadtest [flags]

Flags:
  -c, --config string   Configuration file path (default "config.yaml")
  -v, --verbose         Enable verbose logging
  -h, --help           Help for fiyuu-ktdb-loadtest
```

## 📊 Metrikler ve Monitoring

### Yerleşik Metrikler

- **Query Performance**: Ortalama süre, min/max süre
- **Success Rate**: Başarı oranı yüzdesi
- **Throughput**: Saniye başına query sayısı
- **Error Analysis**: Hata türleri ve frekansları

### Prometheus Entegrasyonu

Prometheus metriklerini etkinleştirmek için:

```yaml
metrics:
  prometheus:
    enabled: true
    port: 8080
    path: "/metrics"
```

Metrikleri görüntülemek için:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

### Metrik Dosyaları

Test sonuçları JSON formatında `metrics.json` dosyasına kaydedilir:

```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "total_queries": 1000,
  "successful_queries": 950,
  "failed_queries": 50,
  "success_rate": 95.0,
  "average_duration": "50ms"
}
```

## 🐳 Docker Deployment

### EC2'da Çalıştırma

1. **EC2 Instance Hazırlığı**:
```bash
# Docker kurulumu
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Docker Compose kurulumu
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

2. **Uygulamayı Deploy Etme**:
```bash
# Repository'yi klonlayın
git clone <repository-url>
cd fiyuu-ktdb-loadtest

# Servisleri başlatın
docker-compose up -d

# Logları kontrol edin
docker-compose logs -f loadtest
```

3. **Monitoring**:
- Prometheus: `http://ec2-ip:9090`
- Grafana: `http://ec2-ip:3000`
- Load Test Metrics: `http://ec2-ip:8080/metrics`

### Production Deployment

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  loadtest:
    image: fiyuu-ktdb-loadtest:latest
    environment:
      - CONFIG_FILE=/app/configs/production.yaml
    volumes:
      - ./configs:/app/configs
      - ./results:/app/results
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
```

## 🔧 Geliştirme

### Proje Yapısı

```
fiyuu-ktdb-loadtest/
├── cmd/                    # CLI commands
├── internal/
│   ├── config/            # Configuration management
│   ├── database/          # Database connections
│   ├── loadtest/          # Load testing logic
│   └── metrics/           # Metrics collection
├── configs/               # Configuration files
├── scripts/               # Database initialization
├── docker-compose.yml     # Docker services
├── Dockerfile            # Container definition
└── Makefile              # Build automation
```

### Test Senaryoları Yazma

Yeni test senaryoları eklemek için `config.yaml` dosyasını düzenleyin:

```yaml
test:
  queries:
    - name: "complex_join_query"
      sql: |
        SELECT u.username, COUNT(o.id) as order_count
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        WHERE u.created_at > '2024-01-01'
        GROUP BY u.id, u.username
        HAVING COUNT(o.id) > 5
      weight: 20
      type: "select"
```

### Custom Metrikler

```go
// Custom metric ekleme
metrics.RecordMetric(metrics.Metric{
    Name:   "custom_metric",
    Type:   metrics.MetricTypeGauge,
    Value:  float64(customValue),
    Labels: map[string]string{"label": "value"},
})
```

## 📈 Performance Tuning

### Database Connection Pool

```yaml
database:
  max_open_conns: 100      # Maksimum açık connection
  max_idle_conns: 10       # Maksimum idle connection
  conn_max_lifetime: 1h    # Connection yaşam süresi
  conn_max_idle_time: 10m  # Idle connection süresi
```

### Load Test Parametreleri

```yaml
test:
  concurrent_users: 50     # Eşzamanlı kullanıcı sayısı
  ramp_up_time: 2m         # Ramp-up süresi
  think_time: 500ms        # Query'ler arası bekleme
  duration: 30m            # Test süresi
```

## 🐛 Troubleshooting

### Yaygın Sorunlar

1. **Connection Timeout**:
   - `max_open_conns` değerini artırın
   - `conn_max_lifetime` değerini azaltın

2. **Memory Issues**:
   - `concurrent_users` sayısını azaltın
   - Query result set'lerini sınırlayın

3. **Database Lock**:
   - `think_time` değerini artırın
   - Query'leri optimize edin

### Debug Mode

```bash
# Verbose logging ile çalıştır
./fiyuu-ktdb-loadtest -c config.yaml -v

# Docker logs
docker-compose logs -f loadtest
```

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📞 Destek

Sorularınız için:
- Issue açın
- Email: support@fiyuu.com
- Documentation: [Wiki](link-to-wiki)

---

**Not**: Bu araç production ortamlarında kullanmadan önce test ortamında deneyiniz. Yüksek load testleri veritabanı performansını etkileyebilir.
