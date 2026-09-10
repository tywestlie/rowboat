#!/usr/bin/env bash
set -euo pipefail

exec 200>/tmp/deploy.lock
flock -n 200 || { echo "another deploy is already running, exiting"; exit 1; }

cd /srv/rowboat

git pull origin main
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml run --rm web bin/rails db:prepare
docker compose -f docker-compose.prod.yml up -d --remove-orphans
