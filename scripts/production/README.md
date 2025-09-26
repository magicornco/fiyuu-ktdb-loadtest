# Production Scripts

Bu klasör production ortamında güvenli bir şekilde yük testi yapmak için özel scriptler içerir.

## 🚀 Scriptler

### `run-production.sh`
- **Amaç**: Production web server'ı başlatır
- **Kullanım**: `./run-production.sh`
- **Özellikler**: 
  - Production environment variables yükler
  - Web server modunda çalışır
  - API endpoints sunar

### `run-production-loadtest.sh`
- **Amaç**: Production database'de load test yapar
- **Kullanım**: `./run-production-loadtest.sh`
- **Özellikler**:
  - 10,000 connection ile test
  - 10 dakika süre
  - Production konfigürasyonu kullanır

### `run-production-safe.sh` ⭐ **ÖNERİLEN**
- **Amaç**: Güvenli production yük testi
- **Kullanım**: `./run-production-safe.sh`
- **Özellikler**:
  - 20 concurrent user (GÜVENLİ)
  - 5 dakika süre
  - Read-only query'ler
  - Düşük connection pool
  - Onay isteme

### `run-production-stress.sh`
- **Amaç**: Kontrollü stress testi
- **Kullanım**: `./run-production-stress.sh`
- **Özellikler**:
  - 100 concurrent user (STRESS)
  - 15 dakika süre
  - Çeşitli read-only query'ler
  - Orta seviye connection pool
  - Onay isteme

## ⚠️ Güvenlik Uyarıları

1. **İlk Test**: Her zaman `run-production-safe.sh` ile başlayın
2. **Monitoring**: Test sırasında database'i izleyin
3. **Backup**: Test öncesi backup alın
4. **Onay**: Scriptler onay ister, dikkatli okuyun
5. **Saat**: Yoğun saatlerde test yapmayın

## 📊 Test Sırası

```bash
# 1. Güvenli test (önerilen)
./run-production-safe.sh

# 2. Sonuçları analiz et
# 3. Gerekirse stress test
./run-production-stress.sh

# 4. Sonuçları analiz et
# 5. Gerekirse full load test
./run-production-loadtest.sh
```

## 🔍 Monitoring

Test sırasında şunları izleyin:
- Database CPU kullanımı
- Memory kullanımı
- Connection sayısı
- Query response time
- Error rate
