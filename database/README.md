# Budget DB

PostgreSQL adatbázis házi pénzügyi tranzakciók tárolására és elemzésére. Hetzner VPS-en fut.

## Struktúra

```
budget-db/
├── database/
│   ├── bootstrap/        # Egyszer fut, postgres superuser-ként
│   │   ├── 001_create_role.sql
│   │   ├── 002_create_database.sql
│   │   └── 003_grants.sql
│   └── migrations/       # Sorrend szerint futtatandó
│       ├── V001_create_schemas.sql
│       ├── V002_create_raw_transactions.sql
│       └── V003_create_raw_transactions_test.sql
├── scripts/
│   └── setup.sh          # Teljes telepítés egyben
└── source/
    └── tranzakciok.xlsx  # Forrásadat
```

## Adatbázis sémák

| Séma | Cél |
|---|---|
| `raw` | Nyers adat, változtatás nélkül betöltve |
| `staging` | Tisztított, validált adat |
| `intermediate` | Számított közbenső táblák |
| `mart` | Végső riporttáblák |
| `reference` | Segédtáblák (kategóriák, devizák stb.) |
| `dbo` | Általános célú séma |

## Telepítés

```bash
chmod +x scripts/setup.sh
sudo bash scripts/setup.sh
```

A script sorban elvégzi:
1. PostgreSQL telepítést (ha szükséges)
2. Role és adatbázis létrehozását
3. Jogosultságok beállítását
4. Migrációk futtatását

A jelszót futáskor kéri be, nem tárolódik fájlban.

## Kapcsolódás

```bash
psql -U project_user -d project_db
```
