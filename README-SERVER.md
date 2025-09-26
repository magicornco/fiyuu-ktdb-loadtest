# Fiyuu KTDB Web Server

Golang ile yazılmış asenkron web server uygulaması. SQL Server driver kullanarak database connection açıp, her istek geldiğinde query atar. Environment variable'lar ile tamamen parametrik yapılandırılabilir.

## 🚀 Özellikler

- **Asenkron Web Server**: Gorilla Mux router ile yüksek performanslı HTTP server
- **SQL Server Desteği**: Microsoft SQL Server driver ile native bağlantı
- **Environment Variables**: Tamamen parametrik konfigürasyon
- **Connection Pooling**: Optimize edilmiş database connection yönetimi
- **Health Checks**: Database ve server durumu monitoring
- **CORS Desteği**: Cross-origin request desteği
- **JSON API**: RESTful JSON API endpoints
- **Graceful Shutdown**: Güvenli server kapatma

## 📋 Gereksinimler

- Go 1.21+
- SQL Server 2019+ (veya diğer desteklenen veritabanları)
- Docker & Docker Compose (opsiyonel)

## 🛠️ Kurulum

### 1. Kaynak Koddan Kurulum

```bash
# Repository'yi klonlayın
git clone <repository-url>
cd fiyuu-ktdb-loadtest

# Dependencies'leri yükleyin
go mod download

# Uygulamayı build edin
go build -o fiyuu-ktdb .
```

### 2. Environment Variables Ayarlama

```bash
# Environment dosyasını kopyalayın
cp env.example .env

# .env dosyasını düzenleyin
nano .env
```

### 3. Docker ile Kurulum

```bash
# Tüm servisleri başlatın (SQL Server, Web Server, Prometheus, Grafana)
docker-compose up -d

# Sadece web server'ı çalıştırın
docker-compose up webserver
```

## ⚙️ Konfigürasyon

### Environment Variables

| Variable | Default | Açıklama |
|----------|---------|----------|
| `SERVER_HOST` | `0.0.0.0` | Server host address |
| `SERVER_PORT` | `8080` | Server port |
| `DB_TYPE` | `mssql` | Database type (mssql, mysql, postgres, sqlite) |
| `DB_HOST` | `localhost` | Database host |
| `DB_PORT` | `1433` | Database port |
| `DB_USERNAME` | `sa` | Database username |
| `DB_PASSWORD` | - | Database password (required) |
| `DB_NAME` | `master` | Database name |
| `DB_SSL_MODE` | `disable` | SSL mode (for postgres) |
| `DB_MAX_OPEN_CONNS` | `100` | Max open connections |
| `DB_MAX_IDLE_CONNS` | `10` | Max idle connections |
| `DB_CONN_MAX_LIFETIME` | `1h` | Connection max lifetime |
| `DB_CONN_MAX_IDLE_TIME` | `10m` | Connection max idle time |
| `DEFAULT_QUERY` | `SELECT 1 as test` | Default query to execute |
| `LOG_LEVEL` | `info` | Log level (debug, info, warn, error) |
| `LOG_FORMAT` | `text` | Log format (text, json) |

### SQL Server Konfigürasyonu

```bash
# SQL Server için environment variables
export DB_TYPE=mssql
export DB_HOST=localhost
export DB_PORT=1433
export DB_USERNAME=sa
export DB_PASSWORD=YourStrong@Passw0rd
export DB_NAME=testdb
export DEFAULT_QUERY="SELECT @@VERSION as version, GETDATE() as current_time"
```

## 🚀 Kullanım

### Temel Kullanım

```bash
# Environment variables ile çalıştır
./fiyuu-ktdb

# Verbose logging ile çalıştır
./fiyuu-ktdb -v

# Belirli port ile çalıştır
SERVER_PORT=9090 ./fiyuu-ktdb
```

### Docker ile Çalıştırma

```bash
# SQL Server ile birlikte çalıştır
docker-compose up -d sqlserver webserver

# Logları kontrol et
docker-compose logs -f webserver
```

## 📡 API Endpoints

### 1. Root Endpoint
```http
GET /
```
Server bilgilerini ve mevcut endpoint'leri döner.

### 2. Health Check
```http
GET /api/v1/health
```
Database bağlantısı ve server durumunu kontrol eder.

**Response:**
```json
{
  "status": "healthy",
  "database": "connected",
  "uptime": "1h30m45s",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 3. Default Query
```http
GET /api/v1/query
```
Environment variable'da tanımlanan default query'yi çalıştırır.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "test": 1,
      "current_time": "2024-01-01T12:00:00Z"
    }
  ],
  "duration": "5ms",
  "rows_affected": 1,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 4. Custom Query
```http
POST /api/v1/query
Content-Type: application/json

{
  "query": "SELECT name FROM sys.databases WHERE database_id > 4"
}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {"name": "testdb"},
    {"name": "tempdb"}
  ],
  "duration": "10ms",
  "rows_affected": 2,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 5. Database Info
```http
GET /api/v1/db/info
```
Database bağlantı bilgilerini döner (password hariç).

### 6. Database Stats
```http
GET /api/v1/db/stats
```
Database connection pool istatistiklerini döner.

## 🔧 Geliştirme

### Proje Yapısı

```
fiyuu-ktdb-loadtest/
├── internal/
│   ├── config/          # Environment-based configuration
│   ├── database/        # Database connection management
│   └── server/          # HTTP server implementation
├── scripts/             # Database initialization scripts
├── docker-compose.yml   # Docker services
├── Dockerfile          # Container definition
└── main.go             # Application entry point
```

### Yeni Endpoint Ekleme

```go
// internal/server/server.go içinde
func (s *Server) setupRoutes() {
    api := s.router.PathPrefix("/api/v1").Subrouter()
    
    // Yeni endpoint
    api.HandleFunc("/custom", s.handleCustom).Methods("GET")
}

func (s *Server) handleCustom(w http.ResponseWriter, r *http.Request) {
    // Custom logic
    response := map[string]interface{}{
        "message": "Custom endpoint",
        "timestamp": time.Now(),
    }
    s.sendJSONResponse(w, http.StatusOK, response)
}
```

### Custom Query Handler

```go
func (s *Server) handleCustomQuery(w http.ResponseWriter, r *http.Request) {
    // Query parametrelerini al
    query := r.URL.Query().Get("sql")
    if query == "" {
        s.sendErrorResponse(w, http.StatusBadRequest, "Query parameter required", nil)
        return
    }
    
    // Query'yi çalıştır
    s.executeQuery(w, query)
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

# Environment variables'ları ayarlayın
export DB_HOST=your-sql-server-host
export DB_PASSWORD=your-password
export DEFAULT_QUERY="SELECT @@VERSION as version"

# Servisleri başlatın
docker-compose up -d webserver
```

3. **Health Check**:
```bash
# Server durumunu kontrol edin
curl http://localhost:8080/api/v1/health

# Default query'yi test edin
curl http://localhost:8080/api/v1/query
```

### Production Deployment

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  webserver:
    image: fiyuu-ktdb:latest
    environment:
      - DB_TYPE=mssql
      - DB_HOST=production-sql-server
      - DB_PASSWORD=${DB_PASSWORD}
      - DEFAULT_QUERY=SELECT COUNT(*) as total_users FROM users
      - LOG_LEVEL=info
      - LOG_FORMAT=json
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
    restart: unless-stopped
```

## 📊 Monitoring ve Logging

### Health Monitoring

```bash
# Health check endpoint'i
curl http://localhost:8080/api/v1/health

# Database stats
curl http://localhost:8080/api/v1/db/stats
```

### Logging

```bash
# Verbose logging
LOG_LEVEL=debug ./fiyuu-ktdb

# JSON logging (production)
LOG_FORMAT=json ./fiyuu-ktdb
```

### Prometheus Metrics

```bash
# Prometheus metrics endpoint'i
curl http://localhost:8080/metrics
```

## 🔒 Güvenlik

### Environment Variables Güvenliği

```bash
# Production'da güvenli password kullanın
export DB_PASSWORD=$(openssl rand -base64 32)

# .env dosyasını git'e eklemeyin
echo ".env" >> .gitignore
```

### Database Güvenliği

```sql
-- SQL Server'da dedicated user oluşturun
CREATE LOGIN fiyuu_user WITH PASSWORD = 'StrongPassword123!';
CREATE USER fiyuu_user FOR LOGIN fiyuu_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO fiyuu_user;
```

## 🐛 Troubleshooting

### Yaygın Sorunlar

1. **Connection Timeout**:
```bash
# Connection timeout ayarlarını artırın
export DB_CONN_MAX_LIFETIME=2h
export DB_MAX_OPEN_CONNS=200
```

2. **SQL Server Bağlantı Sorunu**:
```bash
# SQL Server'ın çalıştığını kontrol edin
telnet your-sql-server 1433

# Firewall ayarlarını kontrol edin
```

3. **Permission Denied**:
```bash
# Database user'ın gerekli permission'ları olduğunu kontrol edin
```

### Debug Mode

```bash
# Debug logging ile çalıştır
LOG_LEVEL=debug ./fiyuu-ktdb -v

# Docker logs
docker-compose logs -f webserver
```

## 📝 Örnek Kullanım Senaryoları

### 1. Basit Health Check

```bash
# Server'ı başlat
./fiyuu-ktdb

# Health check
curl http://localhost:8080/api/v1/health
```

### 2. Custom Query Çalıştırma

```bash
# SQL query gönder
curl -X POST http://localhost:8080/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT COUNT(*) as user_count FROM users"}'
```

### 3. Load Testing

```bash
# Apache Bench ile load test
ab -n 1000 -c 10 http://localhost:8080/api/v1/query
```

## 📞 Destek

Sorularınız için:
- Issue açın
- Email: support@fiyuu.com
- Documentation: [Wiki](link-to-wiki)

---

**Not**: Bu web server production ortamlarında kullanmadan önce güvenlik ayarlarını gözden geçirin ve test ortamında deneyin.
