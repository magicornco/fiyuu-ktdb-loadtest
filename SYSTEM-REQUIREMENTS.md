# System Requirements Guide

Farklı connection sayıları için gerekli makine özellikleri.

## 🖥️ Minimum Sistem Gereksinimleri

### **10-100 Connection Test:**
```
CPU: 2 cores (2.0 GHz)
RAM: 4 GB
Disk: 20 GB SSD
Network: 100 Mbps
OS: Linux/Windows/macOS
```

### **100-1000 Connection Test:**
```
CPU: 4 cores (2.5 GHz)
RAM: 8 GB
Disk: 50 GB SSD
Network: 1 Gbps
OS: Linux/Windows/macOS
```

### **1000-10000 Connection Test:**
```
CPU: 8 cores (3.0 GHz)
RAM: 16 GB
Disk: 100 GB SSD
Network: 10 Gbps
OS: Linux (recommended)
```

## 📊 Detaylı Analiz

### **CPU Gereksinimleri:**

#### **10 Connection:**
- **CPU Usage:** %5-10
- **Cores:** 2 cores yeterli
- **Frequency:** 2.0 GHz+

#### **100 Connection:**
- **CPU Usage:** %15-25
- **Cores:** 4 cores önerilir
- **Frequency:** 2.5 GHz+

#### **1000 Connection:**
- **CPU Usage:** %40-60
- **Cores:** 8 cores gerekli
- **Frequency:** 3.0 GHz+

#### **10000 Connection:**
- **CPU Usage:** %70-90
- **Cores:** 16+ cores önerilir
- **Frequency:** 3.5 GHz+

### **RAM Gereksinimleri:**

#### **10 Connection:**
- **Application RAM:** 100-200 MB
- **System RAM:** 2-4 GB
- **Total:** 4 GB yeterli

#### **100 Connection:**
- **Application RAM:** 500-800 MB
- **System RAM:** 4-6 GB
- **Total:** 8 GB önerilir

#### **1000 Connection:**
- **Application RAM:** 2-4 GB
- **System RAM:** 8-12 GB
- **Total:** 16 GB gerekli

#### **10000 Connection:**
- **Application RAM:** 8-16 GB
- **System RAM:** 16-32 GB
- **Total:** 32+ GB önerilir

## 🏗️ Önerilen Makine Konfigürasyonları

### **Development/Test Makinesi:**
```
CPU: Intel i5-8400 / AMD Ryzen 5 3600
RAM: 16 GB DDR4
Disk: 500 GB SSD
Network: 1 Gbps
OS: Ubuntu 20.04 LTS
```

### **Production Test Makinesi:**
```
CPU: Intel i7-10700K / AMD Ryzen 7 3700X
RAM: 32 GB DDR4
Disk: 1 TB NVMe SSD
Network: 10 Gbps
OS: Ubuntu 20.04 LTS
```

### **High-Performance Test Makinesi:**
```
CPU: Intel Xeon E5-2680 v4 / AMD EPYC 7302P
RAM: 64 GB DDR4 ECC
Disk: 2 TB NVMe SSD
Network: 25 Gbps
OS: Ubuntu 20.04 LTS
```

## ☁️ Cloud Instance Önerileri

### **AWS EC2:**
```
10-100 Connection: t3.medium (2 vCPU, 4 GB RAM)
100-1000 Connection: t3.large (2 vCPU, 8 GB RAM)
1000-10000 Connection: c5.2xlarge (8 vCPU, 16 GB RAM)
10000+ Connection: c5.4xlarge (16 vCPU, 32 GB RAM)
```

### **Google Cloud:**
```
10-100 Connection: e2-medium (2 vCPU, 4 GB RAM)
100-1000 Connection: e2-standard-2 (2 vCPU, 8 GB RAM)
1000-10000 Connection: c2-standard-8 (8 vCPU, 32 GB RAM)
10000+ Connection: c2-standard-16 (16 vCPU, 64 GB RAM)
```

### **Azure:**
```
10-100 Connection: Standard_B2s (2 vCPU, 4 GB RAM)
100-1000 Connection: Standard_B4ms (4 vCPU, 16 GB RAM)
1000-10000 Connection: Standard_D8s_v3 (8 vCPU, 32 GB RAM)
10000+ Connection: Standard_D16s_v3 (16 vCPU, 64 GB RAM)
```

## 🔧 Sistem Optimizasyonu

### **Linux Kernel Ayarları:**
```bash
# File descriptor limit
echo '* soft nofile 65535' >> /etc/security/limits.conf
echo '* hard nofile 65535' >> /etc/security/limits.conf

# Network settings
echo 'net.core.somaxconn = 65535' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog = 65535' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog = 5000' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_keepalive_time = 600' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_keepalive_intvl = 60' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_keepalive_probes = 10' >> /etc/sysctl.conf

# Apply settings
sysctl -p
```

### **Go Runtime Ayarları:**
```bash
# GOMAXPROCS ayarla
export GOMAXPROCS=8

# GC ayarları
export GOGC=100
export GOMEMLIMIT=8GiB
```

## 📈 Performance Beklentileri

### **10 Connection Test:**
```
Expected QPS: 100-500
Response Time: 10-50ms
CPU Usage: %5-10
Memory Usage: 200-500 MB
```

### **100 Connection Test:**
```
Expected QPS: 500-2000
Response Time: 20-100ms
CPU Usage: %15-25
Memory Usage: 500-1000 MB
```

### **1000 Connection Test:**
```
Expected QPS: 2000-10000
Response Time: 50-200ms
CPU Usage: %40-60
Memory Usage: 2-4 GB
```

### **10000 Connection Test:**
```
Expected QPS: 10000-50000
Response Time: 100-500ms
CPU Usage: %70-90
Memory Usage: 8-16 GB
```

## 🚨 Uyarılar ve Limitler

### **Sistem Limitleri:**
```bash
# File descriptor limit kontrolü
ulimit -n

# Process limit kontrolü
ulimit -u

# Memory limit kontrolü
free -h
```

### **Network Limitleri:**
```bash
# Network connection kontrolü
netstat -an | grep 1433 | wc -l

# Bandwidth kontrolü
iftop -i eth0
```

### **Database Limitleri:**
```sql
-- SQL Server connection limit kontrolü
SELECT COUNT(*) FROM sys.dm_exec_connections;

-- Max connections ayarı
EXEC sp_configure 'user connections', 0;
```

## 💰 Maliyet Analizi

### **AWS EC2 Maliyetleri (US East):**
```
t3.medium: ~$30/ay (10-100 connection)
t3.large: ~$60/ay (100-1000 connection)
c5.2xlarge: ~$300/ay (1000-10000 connection)
c5.4xlarge: ~$600/ay (10000+ connection)
```

### **Google Cloud Maliyetleri:**
```
e2-medium: ~$25/ay (10-100 connection)
e2-standard-2: ~$50/ay (100-1000 connection)
c2-standard-8: ~$250/ay (1000-10000 connection)
c2-standard-16: ~$500/ay (10000+ connection)
```

## 🎯 Öneriler

### **Başlangıç için:**
- **10-100 connection:** 4 core, 8 GB RAM
- **Maliyet:** ~$50-100/ay

### **Production test için:**
- **100-1000 connection:** 8 core, 16 GB RAM
- **Maliyet:** ~$200-400/ay

### **Stress test için:**
- **1000+ connection:** 16+ core, 32+ GB RAM
- **Maliyet:** ~$500-1000/ay

## 🔍 Monitoring Gereksinimleri

### **Grafana + Prometheus:**
```
CPU: +1 core
RAM: +2 GB
Disk: +10 GB
```

### **Log Storage:**
```
Disk: +50 GB (test başına)
```

---

**Not**: Bu gereksinimler SQL Server'ın da aynı makinede çalıştığı varsayımıyla hesaplanmıştır. SQL Server ayrı bir makinede ise, test makinesi gereksinimleri %30-50 azalabilir.
