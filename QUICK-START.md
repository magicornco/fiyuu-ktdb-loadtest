# Fiyuu KTDB Web Server - Quick Start Guide

Golang ile yazılmış asenkron web server uygulaması. SQL Server driver kullanarak database connection açıp, her istek geldiğinde query atar.

## 🚀 Hızlı Başlangıç

### 1. Kurulum

#### Ubuntu/Debian için:
```bash
chmod +x install-ubuntu.sh
./install-ubuntu.sh
```

#### CentOS/RHEL/Rocky Linux için:
```bash
chmod +x install-centos.sh
./install-centos.sh
```

#### Genel kurulum (tüm sistemler):
```bash
chmod +x install.sh
./install.sh
```

### 2. Konfigürasyon

Environment dosyasını düzenleyin:
```bash
nano .env
```

Gerekli ayarlar:
```bash
# Database Configuration
DB_TYPE=mssql
DB_HOST=localhost
DB_PORT=1433
DB_USERNAME=sa
DB_PASSWORD=your_password_here
DB_NAME=master

# Connection Settings
CONNECTION_COUNT=10
DB_MAX_OPEN_CONNS=100
DB_MAX_IDLE_CONNS=10

# Server Settings
SERVER_HOST=0.0.0.0
SERVER_PORT=8080
DEFAULT_QUERY=SELECT 1 as test, GETDATE() as current_time
```

### 3. Çalıştırma

#### Otomatik çalıştırma:
```bash
./run.sh
```

#### Manuel çalıştırma:
```bash
# Dependencies'leri yükle
go mod download

# Build et
go build -o fiyuu-ktdb .

# Çalıştır
./fiyuu-ktdb
```

## 📡 API Endpoints

### Health Check
```bash
curl http://localhost:8080/api/v1/health
```

### Default Query
```bash
curl http://localhost:8080/api/v1/query
```

### Custom Query
```bash
curl -X POST http://localhost:8080/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT @@VERSION as version"}'
```

### Database Info
```bash
curl http://localhost:8080/api/v1/db/info
```

### Database Stats
```bash
curl http://localhost:8080/api/v1/db/stats
```

## ⚙️ Environment Variables

| Variable | Default | Açıklama |
|----------|---------|----------|
| `SERVER_HOST` | `0.0.0.0` | Server host address |
| `SERVER_PORT` | `8080` | Server port |
| `DB_TYPE` | `mssql` | Database type |
| `DB_HOST` | `localhost` | Database host |
| `DB_PORT` | `1433` | Database port |
| `DB_USERNAME` | `sa` | Database username |
| `DB_PASSWORD` | - | Database password (required) |
| `DB_NAME` | `master` | Database name |
| `CONNECTION_COUNT` | `10` | Connection count for load testing |
| `DB_MAX_OPEN_CONNS` | `100` | Max open connections |
| `DB_MAX_IDLE_CONNS` | `10` | Max idle connections |
| `DEFAULT_QUERY` | `SELECT 1 as test` | Default query to execute |
| `LOG_LEVEL` | `info` | Log level |

## 🔧 Systemd Service

### Service'i etkinleştir:
```bash
sudo systemctl enable fiyuu-ktdb
sudo systemctl start fiyuu-ktdb
```

### Service durumunu kontrol et:
```bash
sudo systemctl status fiyuu-ktdb
```

### Service'i durdur:
```bash
sudo systemctl stop fiyuu-ktdb
```

## 🐳 Docker ile Çalıştırma (Opsiyonel)

```bash
# SQL Server ile birlikte çalıştır
docker-compose up -d sqlserver webserver

# Logları kontrol et
docker-compose logs -f webserver
```

## 📊 Monitoring

### Health Check
```bash
curl http://localhost:8080/api/v1/health
```

### Database Stats
```bash
curl http://localhost:8080/api/v1/db/stats
```

### Prometheus Metrics (eğer etkinse)
```bash
curl http://localhost:8080/metrics
```

## 🐛 Troubleshooting

### Connection Timeout
```bash
# Connection timeout ayarlarını artır
export DB_CONN_MAX_LIFETIME=2h
export DB_MAX_OPEN_CONNS=200
```

### SQL Server Bağlantı Sorunu
```bash
# SQL Server'ın çalıştığını kontrol et
telnet your-sql-server 1433

# Firewall ayarlarını kontrol et
sudo ufw status
```

### Debug Mode
```bash
# Debug logging ile çalıştır
LOG_LEVEL=debug ./fiyuu-ktdb -v
```

## 📝 Örnek Kullanım

### 1. Basit Test
```bash
# Server'ı başlat
./fiyuu-ktdb

# Health check
curl http://localhost:8080/api/v1/health

# Default query
curl http://localhost:8080/api/v1/query
```

### 2. Custom Query
```bash
curl -X POST http://localhost:8080/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT COUNT(*) as user_count FROM users"}'
```

### 3. Load Testing
```bash
# Apache Bench ile load test
ab -n 1000 -c 10 http://localhost:8080/api/v1/query
```

## 🔒 Güvenlik

### Environment Variables
```bash
# Production'da güvenli password kullan
export DB_PASSWORD=$(openssl rand -base64 32)

# .env dosyasını git'e ekleme
echo ".env" >> .gitignore
```

### Database User
```sql
-- SQL Server'da dedicated user oluştur
CREATE LOGIN fiyuu_user WITH PASSWORD = 'StrongPassword123!';
CREATE USER fiyuu_user FOR LOGIN fiyuu_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO fiyuu_user;
```

## 📞 Destek

Sorularınız için:
- Issue açın
- Email: support@fiyuu.com
- Documentation: README-SERVER.md

---

**Not**: Production ortamında kullanmadan önce güvenlik ayarlarını gözden geçirin.
