#!/bin/bash

# Define colors for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "=== GIAI ĐOẠN 1: DỌN DẸP TÀI NGUYÊN (CLEAN UP) ==="
if [ $(docker ps -a -q -f name=quickbite-db) ]; then
    echo "Phát hiện container 'quickbite-db' đang tồn tại. Đang tiến hành xóa..."
    docker stop quickbite-db > /dev/null 2>&1
    docker rm quickbite-db > /dev/null 2>&1
    echo -e "${GREEN}Dọn dẹp container thành công.${NC}"
else
    echo "Không tìm thấy container 'quickbite-db'. Tiến hành bước tiếp theo."
fi

echo ""
echo "=== GIAI ĐOẠN 2: KIỂM SOÁT CỔNG MẠNG (PORT CHECK) ==="
if lsof -i :5432 -sTCP:LISTEN -t >/dev/null 2>&1 || nc -z localhost 5432 >/dev/null 2>&1 ; then
    echo -e "${RED}[LỖI] Cổng 5432 trên máy host đang bị chiếm dụng bởi tiến trình khác!${NC}"
    echo -e "${RED}Dừng kịch bản khởi tạo (Exit code 1).${NC}"
    exit 1
else
    echo "Cổng 5432 trống. Sẵn sàng khởi chạy."
fi

echo ""
echo "=== GIAI ĐOẠN 3: KHỞI TẠO DATABASE ==="
docker run -d \
  --name quickbite-db \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=12345678 \
  postgres:15-alpine

echo "Đã gửi lệnh khởi chạy container quickbite-db."

echo ""
echo "=== GIAI ĐOẠN 4: KIỂM THỬ ĐỘ SẴN SÀNG (SMOKE TEST) ==="
echo "Tạm dừng 5 giây để PostgreSQL hoàn tất khởi động..."
sleep 5

docker exec quickbite-db pg_isready -U postgres > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}===============================================${NC}"
    echo -e "${GREEN} DATABASE STAGING KHỞI TẠO THÀNH CÔNG! ${NC}"
    echo -e "${GREEN}===============================================${NC}"
    exit 0
else
    echo -e "${RED}[LỖI] Database chưa sẵn sàng hoặc khởi chạy thất bại!${NC}"
    echo -e "${RED}--- 20 DÒNG LOG CUỐI CÙNG CỦA CONTAINER ---${NC}"
    docker logs --tail 20 quickbite-db
    exit 1
fi
