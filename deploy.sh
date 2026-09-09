#!/usr/bin/env bash
set -euo pipefail

cd /srv/rowboat

git pull origin main
docker compose build
docker compose run --rm web bin/rails db:migrate
docker compose up -d
