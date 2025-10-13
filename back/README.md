# 서버 시작
docker-compose up

# 백그라운드 실행
docker-compose up -d

# 서버 중지
docker-compose stop

# 완전 재시작
docker-compose down && docker-compose up --build

# DB 초기화
docker-compose down -v && docker-compose up