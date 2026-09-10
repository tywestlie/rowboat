#!/usr/bin/env bash
set -euo pipefail

exec 200>/tmp/deploy.lock
flock -n 200 || { echo "another deploy is already running, exiting"; exit 1; }

cd /srv/rowboat

git pull origin main
docker compose build
docker compose run --rm web bin/rails db:prepare
docker compose up -d
