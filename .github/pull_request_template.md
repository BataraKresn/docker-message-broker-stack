## Ringkasan

Jelaskan perubahan utama pada PR ini.

## Tipe Perubahan

- [ ] Bug fix
- [ ] Feature baru
- [ ] Refactor
- [ ] Perubahan dokumentasi
- [ ] Hardening/security
- [ ] CI/CD

## Checklist Validasi

- [ ] `docker compose -f docker-compose.dev.yml --env-file .env.dev config` lolos
- [ ] `docker compose -f docker-compose.prod.yml --env-file .env.prod config` lolos
- [ ] `docker compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml --env-file .env.prod config` lolos
- [ ] Tidak ada secret sensitif yang di-commit
- [ ] Dokumentasi (`README.md` / `docs/*`) diperbarui jika relevan

## Dampak Operasional

Tuliskan dampak ke deployment/monitoring/rollback jika ada.

## Catatan Keamanan

Tuliskan perubahan terkait autentikasi, network exposure, TLS, atau secret handling.
