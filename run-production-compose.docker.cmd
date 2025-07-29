docker compose -f docker-compose.production.yml --env-file .env.production up -d

docker-compose -f docker-compose.production.optimized.yml build app --progress=plain