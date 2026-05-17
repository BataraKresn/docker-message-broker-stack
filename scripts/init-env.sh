#!/bin/bash
# Inisialisasi file .env.dev dan .env.prod dari template jika belum ada
set -e

if [[ ! -f .env.dev ]]; then
  cp .env.dev.example .env.dev
  echo ".env.dev dibuat dari template."
fi
if [[ ! -f .env.prod ]]; then
  cp .env.prod.example .env.prod
  echo ".env.prod dibuat dari template."
fi
