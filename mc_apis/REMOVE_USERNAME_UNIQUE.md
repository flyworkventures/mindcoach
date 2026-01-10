# Username Unique Constraint Kaldırma

## Sorun
Username field'ında unique constraint (`uk_username`) hala aktif ve "Duplicate entry 'Guest user' for key 'uk_username'" hatası veriyor.

## Çözüm

### 1. Sunucuda Migration'ı Çalıştırın

SSH ile sunucuya bağlanın ve aşağıdaki komutu çalıştırın:

```bash
# MySQL/MariaDB'ye bağlanın
mysql -u root -p mindcoach

# Veya .env dosyasındaki bilgileri kullanarak:
mysql -h localhost -u YOUR_DB_USER -p mindcoach
```

Sonra SQL komutunu çalıştırın:

```sql
-- Önce mevcut index'leri kontrol edin
SHOW INDEX FROM users WHERE Key_name = 'uk_username';

-- Eğer uk_username varsa, kaldırın
ALTER TABLE `users` DROP INDEX `uk_username`;

-- Kontrol edin (artık unique constraint olmamalı)
SHOW INDEX FROM users WHERE Key_name = 'uk_username';
```

### 2. Alternatif: Script ile Çalıştırma

Eğer `.env` dosyanızda database bilgileri varsa:

```bash
cd /path/to/mc_apis
bash scripts/remove_username_unique.sh
```

### 3. Manuel Kontrol

Migration'ın başarılı olduğunu kontrol etmek için:

```sql
-- Tüm index'leri göster
SHOW INDEX FROM users;

-- Username üzerinde unique constraint olmamalı
-- Sadece idx_username (non-unique index) olmalı
```

### 4. Test

Migration'dan sonra misafir kullanıcı oluşturmayı tekrar deneyin. Artık "Duplicate entry" hatası almamalısınız.

## Not

- `idx_username` index'i korunuyor (performans için)
- Sadece `uk_username` unique constraint kaldırılıyor
- Artık birden fazla kullanıcı aynı username'i kullanabilir (örn: "Guest user")

