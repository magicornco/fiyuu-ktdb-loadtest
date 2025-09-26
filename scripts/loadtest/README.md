# Load Test Scripts

Bu klasör farklı load test senaryoları için scriptler içerir.

## 🧪 Scriptler

### `run-loadtest.sh`
- **Amaç**: Genel load test
- **Kullanım**: `./run-loadtest.sh [config-file]`
- **Özellikler**:
  - Varsayılan: `configs/sqlserver.yaml`
  - Özel config dosyası alabilir
  - Background'da çalışır

### `run-loadtest-10.sh`
- **Amaç**: 10 connection ile test
- **Kullanım**: `./run-loadtest-10.sh`
- **Özellikler**:
  - Sabit 10 connection
  - Production environment kullanır
  - Hızlı test için ideal

### `run-loadtest-dynamic.sh`
- **Amaç**: Dinamik connection test
- **Kullanım**: `./run-loadtest-dynamic.sh [connections] [duration] [config]`
- **Özellikler**:
  - Parametrik connection sayısı
  - Parametrik süre
  - Esnek konfigürasyon

## 🎯 Kullanım Örnekleri

### Hızlı Test (10 Connection)
```bash
./run-loadtest-10.sh
```

### Dinamik Test
```bash
# 50 connection, 10 dakika
./run-loadtest-dynamic.sh 50 10m

# 200 connection, 30 dakika, özel config
./run-loadtest-dynamic.sh 200 30m configs/custom.yaml
```

### Genel Test
```bash
# Varsayılan config ile
./run-loadtest.sh

# Özel config ile
./run-loadtest.sh configs/production.yaml
```

## 📊 Test Senaryoları

| Script | Connections | Duration | Use Case |
|--------|-------------|----------|----------|
| `run-loadtest-10.sh` | 10 | Config'den | Hızlı test |
| `run-loadtest-dynamic.sh` | Parametrik | Parametrik | Esnek test |
| `run-loadtest.sh` | Config'den | Config'den | Standart test |

## ⚙️ Konfigürasyon

Tüm scriptler şu konfigürasyon dosyalarını kullanabilir:
- `configs/sqlserver.yaml` - Local SQL Server
- `configs/production.yaml` - Production database
- `configs/production-safe.yaml` - Güvenli production test
- `configs/production-stress.yaml` - Stress production test
