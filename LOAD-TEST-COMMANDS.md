# Load Test Commands Guide

Farklı connection sayıları ile load test yapma komutları.

## 🚀 Hızlı Komutlar

### **10 Connection Load Test:**
```bash
# Hazır script ile
chmod +x run-loadtest-10.sh
./run-loadtest-10.sh
```

### **Dinamik Connection Test:**
```bash
# Parametrik script ile
chmod +x run-loadtest-dynamic.sh

# 10 connection, 5 dakika
./run-loadtest-dynamic.sh 10 5m

# 50 connection, 10 dakika
./run-loadtest-dynamic.sh 50 10m

# 100 connection, 15 dakika
./run-loadtest-dynamic.sh 100 15m

# 1000 connection, 30 dakika
./run-loadtest-dynamic.sh 1000 30m

# 10000 connection, 1 saat
./run-loadtest-dynamic.sh 10000 1h
```

## ⚙️ Manuel Komutlar

### **Environment Variable ile:**
```bash
# 10 connection
export CONNECTION_COUNT=10
./fiyuu-ktdb --server=false -c configs/production.yaml -v

# 50 connection
export CONNECTION_COUNT=50
./fiyuu-ktdb --server=false -c configs/production.yaml -v

# 100 connection
export CONNECTION_COUNT=100
./fiyuu-ktdb --server=false -c configs/production.yaml -v

# 1000 connection
export CONNECTION_COUNT=1000
./fiyuu-ktdb --server=false -c configs/production.yaml -v

# 10000 connection
export CONNECTION_COUNT=10000
./fiyuu-ktdb --server=false -c configs/production.yaml -v
```

### **Config Dosyası ile:**
```bash
# configs/production.yaml dosyasını düzenle
nano configs/production.yaml

# concurrent_users: 10  # İstediğin connection sayısını yaz
# duration: 5m          # Test süresini ayarla

# Load test çalıştır
./fiyuu-ktdb --server=false -c configs/production.yaml -v
```

## 📊 Test Senaryoları

### **Senaryo 1: Basit Test (10 Connection)**
```bash
./run-loadtest-dynamic.sh 10 5m
```

### **Senaryo 2: Orta Seviye Test (100 Connection)**
```bash
./run-loadtest-dynamic.sh 100 10m
```

### **Senaryo 3: Yoğun Test (1000 Connection)**
```bash
./run-loadtest-dynamic.sh 1000 30m
```

### **Senaryo 4: Stress Test (10000 Connection)**
```bash
./run-loadtest-dynamic.sh 10000 1h
```

### **Senaryo 5: Aşamalı Test**
```bash
# 10 connection
./run-loadtest-dynamic.sh 10 2m

# 50 connection
./run-loadtest-dynamic.sh 50 2m

# 100 connection
./run-loadtest-dynamic.sh 100 2m

# 500 connection
./run-loadtest-dynamic.sh 500 2m

# 1000 connection
./run-loadtest-dynamic.sh 1000 2m
```

## 🔧 Monitoring ile Birlikte

### **Full Stack + Load Test:**
```bash
# 1. Monitoring stack'i başlat
./run-monitoring.sh

# 2. Web server'ı başlat
./run-production.sh

# 3. Load test'i başlat
./run-loadtest-dynamic.sh 10 5m

# 4. Grafana'da canlı metrikleri izle
# http://localhost:3000
```

### **Sadece Load Test:**
```bash
# Monitoring olmadan sadece load test
./run-loadtest-dynamic.sh 10 5m
```

## 📈 Beklenen Sonuçlar

### **10 Connection Test:**
```
=== Load Test Statistics ===
Total Queries: 500
Successful: 495
Failed: 5
Success Rate: 99.00%
Average Duration: 25ms
===========================
```

### **100 Connection Test:**
```
=== Load Test Statistics ===
Total Queries: 5000
Successful: 4950
Failed: 50
Success Rate: 99.00%
Average Duration: 45ms
===========================
```

### **1000 Connection Test:**
```
=== Load Test Statistics ===
Total Queries: 50000
Successful: 49500
Failed: 500
Success Rate: 99.00%
Average Duration: 150ms
===========================
```

## 🎯 Özel Test Komutları

### **Kısa Test (1 dakika):**
```bash
./run-loadtest-dynamic.sh 10 1m
```

### **Uzun Test (2 saat):**
```bash
./run-loadtest-dynamic.sh 100 2h
```

### **Farklı Config ile:**
```bash
# SQL Server config ile
./run-loadtest-dynamic.sh 10 5m configs/sqlserver.yaml

# Production config ile
./run-loadtest-dynamic.sh 10 5m configs/production.yaml
```

## 🔍 Debug Mode

### **Verbose Logging ile:**
```bash
# Detaylı loglar ile
./run-loadtest-dynamic.sh 10 5m
# -v flag otomatik olarak eklenir
```

### **Log Dosyasına Kaydet:**
```bash
# Logları dosyaya kaydet
./run-loadtest-dynamic.sh 10 5m 2>&1 | tee loadtest.log
```

## 📋 Test Checklist

- [ ] Database bağlantısı çalışıyor
- [ ] Config dosyası hazır
- [ ] Connection count ayarlandı
- [ ] Test süresi belirlendi
- [ ] Monitoring hazır (opsiyonel)
- [ ] Log dosyası hazır (opsiyonel)

## 🚀 Hızlı Başlangıç

```bash
# 1. 10 connection test
./run-loadtest-dynamic.sh 10 5m

# 2. Sonuçları kontrol et
cat production_metrics.json

# 3. Grafana'da metrikleri izle
# http://localhost:3000
```

---

**Not**: Connection sayısını değiştirmek için sadece ilk parametreyi değiştirin. Örnek: `./run-loadtest-dynamic.sh 50 10m`
