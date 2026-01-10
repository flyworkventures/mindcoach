#!/bin/bash

# MindCoach API Deployment Script
# Bu script sunucuya deploy işlemini otomatikleştirir

set -e

echo "🚀 MindCoach API Deployment Başlatılıyor..."

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# .env dosyası kontrolü
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env dosyası bulunamadı!${NC}"
    echo "Lütfen önce .env dosyası oluşturun."
    exit 1
fi

# Dependencies yükleme
echo -e "${YELLOW}📦 Dependencies yükleniyor...${NC}"
npm install --production

# Database migration kontrolü
echo -e "${YELLOW}🗄️  Database migration'ları kontrol ediliyor...${NC}"
read -p "Database migration'ları çalıştırmak istiyor musunuz? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration dosyalarını manuel olarak çalıştırmanız gerekiyor:"
    echo "mysql -u DB_USER -p DB_NAME < database/migrations/XXX_migration.sql"
fi

# PM2 ile başlatma
echo -e "${YELLOW}🔄 PM2 ile başlatılıyor...${NC}"
if pm2 list | grep -q "mindcoach-api"; then
    echo "Mevcut instance yeniden başlatılıyor..."
    pm2 restart mindcoach-api
else
    echo "Yeni instance oluşturuluyor..."
    pm2 start app.js --name mindcoach-api
    pm2 save
fi

# Health check
echo -e "${YELLOW}🏥 Health check yapılıyor...${NC}"
sleep 3
if curl -f http://localhost:3013/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API başarıyla çalışıyor!${NC}"
else
    echo -e "${RED}❌ API health check başarısız!${NC}"
    echo "Logları kontrol edin: pm2 logs mindcoach-api"
    exit 1
fi

echo -e "${GREEN}✅ Deployment tamamlandı!${NC}"
echo ""
echo "Yararlı komutlar:"
echo "  - Logları görüntüle: pm2 logs mindcoach-api"
echo "  - Durum kontrolü: pm2 status"
echo "  - Yeniden başlat: pm2 restart mindcoach-api"

