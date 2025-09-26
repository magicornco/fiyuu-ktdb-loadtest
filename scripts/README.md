# Scripts Directory

Bu klasör Fiyuu KTDB Load Test projesinin tüm scriptlerini kategorilere ayırarak organize eder.

## 📁 Klasör Yapısı

### 🏭 `production/` - Production Scripts
Production ortamında çalıştırılacak scriptler:
- `run-production.sh` - Production web server
- `run-production-loadtest.sh` - Production load test
- `run-production-safe.sh` - Güvenli production yük testi (20 user)
- `run-production-stress.sh` - Stress production testi (100 user)

### 🧪 `loadtest/` - Load Test Scripts
Farklı load test senaryoları:
- `run-loadtest.sh` - Genel load test
- `run-loadtest-10.sh` - 10 connection test
- `run-loadtest-dynamic.sh` - Dinamik connection test

### 📊 `monitoring/` - Monitoring Scripts
Grafana ve Prometheus monitoring:
- `run-monitoring.sh` - Sadece monitoring servisleri
- `run-full-stack.sh` - Tüm stack (DB + Web + Monitoring)

### 🔧 `installation/` - Installation Scripts
Sistem kurulum scriptleri:
- `install.sh` - Genel kurulum
- `install-ubuntu.sh` - Ubuntu/Debian kurulum
- `install-centos.sh` - CentOS/RHEL kurulum

### 🚀 `run.sh` - Ana Script
Ana çalıştırma scripti (root seviyede)

## 🎯 Kullanım

Her klasördeki scriptleri çalıştırmadan önce executable yapın:

```bash
chmod +x scripts/*/*.sh
chmod +x scripts/run.sh
```

## ⚠️ Production Kullanımı

Production scriptleri kullanmadan önce:
1. `env.production` dosyasını kontrol edin
2. Database bağlantı bilgilerini doğrulayın
3. Güvenli test ile başlayın (`run-production-safe.sh`)
4. Sonuçları analiz edin
5. Gerekirse stress test yapın (`run-production-stress.sh`)
