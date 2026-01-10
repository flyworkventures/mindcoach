# MindCoach API - Sunucuya Deploy Rehberi

Bu rehber, MindCoach API'sini production sunucusuna deploy etmek için adım adım talimatlar içerir.

## 📋 Ön Gereksinimler

- Linux sunucu (Ubuntu 20.04+ önerilir)
- Node.js 18+ yüklü
- MySQL 8.0+ yüklü ve çalışıyor
- Nginx (reverse proxy için)
- PM2 (process manager için)
- SSL sertifikası (Let's Encrypt önerilir)
- Domain adı (opsiyonel ama önerilir)

---

## 🚀 Adım 1: Sunucu Hazırlığı

### 1.1 Sistem Güncellemesi

```bash
sudo apt update
sudo apt upgrade -y
```

### 1.2 Node.js Kurulumu

```bash
# Node.js 18.x kurulumu
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Versiyon kontrolü
node --version
npm --version
```

### 1.3 MySQL Kurulumu

```bash
sudo apt install mysql-server -y
sudo mysql_secure_installation
```

### 1.4 Nginx Kurulumu

```bash
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
```

### 1.5 PM2 Kurulumu

```bash
sudo npm install -g pm2
```

---

## 📦 Adım 2: Proje Dosyalarını Sunucuya Yükleme

### 2.1 Git ile Clone (Önerilen)

```bash
cd /var/www
sudo git clone <your-repository-url> mindcoach-api
sudo chown -R $USER:$USER mindcoach-api
cd mindcoach-api/mc_apis
```

### 2.2 Manuel Yükleme

Eğer Git kullanmıyorsanız:

```bash
# SCP ile dosyaları yükleyin
scp -r mc_apis/ user@your-server:/var/www/mindcoach-api/
```

---

## 🗄️ Adım 3: Database Kurulumu

### 3.1 MySQL Database Oluşturma

```bash
sudo mysql -u root -p
```

MySQL konsolunda:

```sql
CREATE DATABASE mindcoach CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'mindcoach_user'@'localhost' IDENTIFIED BY 'güçlü_şifre_buraya';
GRANT ALL PRIVILEGES ON mindcoach.* TO 'mindcoach_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3.2 Migration Dosyalarını Çalıştırma

```bash
cd /var/www/mindcoach-api/mc_apis/database/migrations

# Tüm migration'ları sırayla çalıştırın
mysql -u mindcoach_user -p mindcoach < 001_create_users_table.sql
mysql -u mindcoach_user -p mindcoach < 002_add_indexes.sql
mysql -u mindcoach_user -p mindcoach < 003_create_user_tokens_table.sql
mysql -u mindcoach_user -p mindcoach < 004_create_consultants_table.sql
mysql -u mindcoach_user -p mindcoach < 005_create_chats_table.sql
mysql -u mindcoach_user -p mindcoach < 006_create_messages_table.sql
mysql -u mindcoach_user -p mindcoach < 007_add_file_fields_to_messages.sql
mysql -u mindcoach_user -p mindcoach < 008_add_voice_fields_to_messages.sql
mysql -u mindcoach_user -p mindcoach < 009_add_content_fields_to_messages.sql
mysql -u mindcoach_user -p mindcoach < 010_add_3d_url_to_consultants.sql
mysql -u mindcoach_user -p mindcoach < 011_create_appointments_table.sql
mysql -u mindcoach_user -p mindcoach < 012_create_moods_table.sql
```

**Veya tek komutla:**

```bash
for file in /var/www/mindcoach-api/mc_apis/database/migrations/*.sql; do
    mysql -u mindcoach_user -p mindcoach < "$file"
done
```

---

## ⚙️ Adım 4: Environment Variables (.env) Dosyası Oluşturma

```bash
cd /var/www/mindcoach-api/mc_apis
nano .env
```

`.env` dosyasına şunları ekleyin:

```env
# Server Configuration
PORT=3013
NODE_ENV=production
REALTIME_WS_PORT=3001

# Database Configuration
DB_HOST=localhost
DB_USER=mindcoach_user
DB_PASSWORD=güçlü_şifre_buraya
DB_NAME=mindcoach

# JWT Configuration
# JWT_SECRET oluşturmak için: npm run generate-secret
JWT_SECRET=buraya_güçlü_jwt_secret_key_gelecek
JWT_EXPIRES_IN=7d
JWT_ISSUER=mindcoach-api
JWT_AUDIENCE=mindcoach-app

# OAuth Providers (Gerekirse)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret

APPLE_TEAM_ID=your_apple_team_id
APPLE_KEY_ID=your_apple_key_id
APPLE_CLIENT_ID=your_apple_client_id

# Bunny CDN (Dosya yükleme için)
BUNNY_CDN_STORAGE_ZONE=your_storage_zone
BUNNY_CDN_API_KEY=your_api_key
BUNNY_CDN_PULL_ZONE=your_pull_zone_url

# OpenAI (AI özellikleri için)
OPENAI_API_KEY=your_openai_api_key

# Webhook URL (AI chat için)
WEBHOOK_URL=http://89.252.179.227:5678/webhook/chat-assistant
```

**JWT_SECRET oluşturma:**

```bash
npm run generate-secret
```

Çıktıdaki key'i `.env` dosyasına ekleyin.

### .env Dosyasını Güvenli Hale Getirme

```bash
chmod 600 .env
```

---

## 📦 Adım 5: Dependencies Yükleme

```bash
cd /var/www/mindcoach-api/mc_apis
npm install --production
```

---

## 🔧 Adım 6: PM2 ile Uygulamayı Başlatma

### 6.1 PM2 Ecosystem Dosyası Oluşturma

```bash
nano ecosystem.config.js
```

İçeriği:

```javascript
module.exports = {
  apps: [{
    name: 'mindcoach-api',
    script: 'app.js',
    cwd: '/var/www/mindcoach-api/mc_apis',
    instances: 2, // CPU core sayısına göre ayarlayın
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3013
    },
    error_file: '/var/log/pm2/mindcoach-api-error.log',
    out_file: '/var/log/pm2/mindcoach-api-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    max_memory_restart: '500M',
    watch: false
  }]
};
```

### 6.2 PM2 ile Başlatma

```bash
# Log dizini oluştur
sudo mkdir -p /var/log/pm2
sudo chown -R $USER:$USER /var/log/pm2

# PM2 ile başlat
pm2 start ecosystem.config.js

# PM2'yi sistem başlangıcında otomatik başlat
pm2 startup
pm2 save

# Durum kontrolü
pm2 status
pm2 logs mindcoach-api
```

---

## 🌐 Adım 7: Nginx Reverse Proxy Yapılandırması

### 7.1 Nginx Config Dosyası Oluşturma

```bash
sudo nano /etc/nginx/sites-available/mindcoach-api
```

İçeriği:

```nginx
server {
    listen 80;
    server_name api.yourdomain.com; # Domain adınızı buraya yazın

    # API için
    location / {
        proxy_pass http://localhost:3013;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeout ayarları
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket için (Socket.IO)
    location /socket.io/ {
        proxy_pass http://localhost:3013;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Realtime WebSocket için
    location /realtime/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Client body size limit (dosya yükleme için)
    client_max_body_size 50M;
}
```

### 7.2 Nginx Config'i Aktif Etme

```bash
sudo ln -s /etc/nginx/sites-available/mindcoach-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔒 Adım 8: SSL Sertifikası Kurulumu (Let's Encrypt)

### 8.1 Certbot Kurulumu

```bash
sudo apt install certbot python3-certbot-nginx -y
```

### 8.2 SSL Sertifikası Alma

```bash
sudo certbot --nginx -d api.yourdomain.com
```

Certbot otomatik olarak:
- SSL sertifikası alacak
- Nginx config'ini güncelleyecek
- Otomatik yenileme ayarlayacak

### 8.3 SSL Otomatik Yenileme Testi

```bash
sudo certbot renew --dry-run
```

---

## 🔥 Adım 9: Firewall Yapılandırması

```bash
# UFW firewall kurulumu
sudo apt install ufw -y

# Gerekli portları aç
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# Firewall'u aktif et
sudo ufw enable
sudo ufw status
```

---

## ✅ Adım 10: Test ve Doğrulama

### 10.1 Health Check

```bash
curl http://localhost:3013/health
```

Beklenen çıktı:
```json
{"status":"ok","timestamp":"2024-01-01T00:00:00.000Z"}
```

### 10.2 API Test

```bash
# Domain üzerinden test
curl https://api.yourdomain.com/health
```

### 10.3 PM2 Durum Kontrolü

```bash
pm2 status
pm2 logs mindcoach-api --lines 50
```

### 10.4 Nginx Log Kontrolü

```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## 🔄 Adım 11: Güncelleme ve Bakım

### 11.1 Kod Güncelleme

```bash
cd /var/www/mindcoach-api/mc_apis
git pull origin main
npm install --production
pm2 restart mindcoach-api
```

### 11.2 Database Migration

Yeni migration varsa:

```bash
cd /var/www/mindcoach-api/mc_apis/database/migrations
mysql -u mindcoach_user -p mindcoach < yeni_migration.sql
```

### 11.3 PM2 Komutları

```bash
# Uygulamayı yeniden başlat
pm2 restart mindcoach-api

# Uygulamayı durdur
pm2 stop mindcoach-api

# Uygulamayı sil
pm2 delete mindcoach-api

# Logları temizle
pm2 flush

# Monitoring
pm2 monit
```

---

## 🐛 Sorun Giderme

### API Çalışmıyor

```bash
# PM2 logları kontrol et
pm2 logs mindcoach-api

# Port kullanımda mı kontrol et
sudo netstat -tulpn | grep 3013

# Process kontrol et
ps aux | grep node
```

### Database Bağlantı Hatası

```bash
# MySQL servisini kontrol et
sudo systemctl status mysql

# Database bağlantısını test et
mysql -u mindcoach_user -p mindcoach -e "SELECT 1;"

# .env dosyasını kontrol et
cat .env | grep DB_
```

### Nginx 502 Bad Gateway

```bash
# Nginx error logları
sudo tail -f /var/log/nginx/error.log

# PM2 durumunu kontrol et
pm2 status

# API'nin çalıştığını doğrula
curl http://localhost:3013/health
```

### SSL Sertifika Sorunları

```bash
# Sertifika durumunu kontrol et
sudo certbot certificates

# Sertifikayı yenile
sudo certbot renew
```

---

## 📊 Monitoring ve Logging

### PM2 Monitoring

```bash
# Real-time monitoring
pm2 monit

# Web dashboard (opsiyonel)
pm2 web
```

### Log Rotation

PM2 otomatik log rotation yapar, ama manuel ayarlamak için:

```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
```

---

## 🔐 Güvenlik Önerileri

1. **.env Dosyası Güvenliği**
   ```bash
   chmod 600 .env
   ```

2. **Database Kullanıcı İzinleri**
   - Sadece gerekli database'e erişim verin
   - Güçlü şifre kullanın

3. **Firewall**
   - Sadece gerekli portları açın
   - SSH için key-based authentication kullanın

4. **SSL/TLS**
   - Her zaman HTTPS kullanın
   - SSL sertifikasını düzenli yenileyin

5. **Düzenli Güncellemeler**
   ```bash
   sudo apt update && sudo apt upgrade -y
   npm audit fix
   ```

---

## 📝 Özet Checklist

- [ ] Sunucu hazırlığı tamamlandı (Node.js, MySQL, Nginx, PM2)
- [ ] Proje dosyaları sunucuya yüklendi
- [ ] Database oluşturuldu ve migration'lar çalıştırıldı
- [ ] .env dosyası oluşturuldu ve yapılandırıldı
- [ ] Dependencies yüklendi
- [ ] PM2 ile uygulama başlatıldı
- [ ] Nginx reverse proxy yapılandırıldı
- [ ] SSL sertifikası kuruldu
- [ ] Firewall yapılandırıldı
- [ ] Health check test edildi
- [ ] Monitoring kuruldu

---

## 🆘 Destek

Sorun yaşarsanız:

1. PM2 loglarını kontrol edin: `pm2 logs mindcoach-api`
2. Nginx loglarını kontrol edin: `sudo tail -f /var/log/nginx/error.log`
3. Database bağlantısını test edin
4. Port'ların açık olduğunu kontrol edin

---

**Başarılar! 🚀**

