#!/bin/bash
set -euo pipefail

# ============================================================
# setup.sh — Budget DB teljes telepítés Hetzner szerverre
# Futtatás: sudo bash scripts/setup.sh
# ============================================================

DB_NAME="project_db"
DB_USER="project_user"
DB_HOST="localhost"
DB_PORT="5432"
MIGRATIONS_DIR="$(cd "$(dirname "$0")/../database/migrations" && pwd)"
BOOTSTRAP_DIR="$(cd "$(dirname "$0")/../database/bootstrap" && pwd)"
FLYWAY_VERSION="12.3.0"
FLYWAY_DIR="/opt/flyway"

# --- Jelszó bekérése (ne legyen plaintext a kódban) ----------
if [ -z "${DB_PASSWORD:-}" ]; then
    read -rsp "Adja meg a(z) '$DB_USER' felhasználó jelszavát: " DB_PASSWORD
    echo
fi

# --- 1. PostgreSQL telepítés (ha még nincs) ------------------
if ! command -v psql &>/dev/null; then
    echo "[1/4] PostgreSQL telepítése..."
    apt-get update -q
    apt-get install -y postgresql postgresql-contrib
else
    echo "[1/4] PostgreSQL mar telepitve, kihagyva."
fi

# --- 2. Bootstrap (superuser-ként) ---------------------------
echo "[2/4] Bootstrap futtatasa (postgres superuser)..."

sudo -u postgres psql < "$BOOTSTRAP_DIR/001_create_role.sql"
sudo -u postgres psql < "$BOOTSTRAP_DIR/002_create_database.sql"
sudo -u postgres psql < "$BOOTSTRAP_DIR/003_grants.sql"
# Jelszó beállítása külön, nem kerül process listába
sudo -u postgres psql -c "ALTER ROLE project_user PASSWORD '$DB_PASSWORD'"

# --- 3. Flyway telepítés (ha még nincs) ----------------------
echo "[3/4] Flyway ellenorzese..."

if ! command -v flyway &>/dev/null; then
    echo "  Flyway telepitese..."
    wget -q "https://github.com/flyway/flyway/releases/download/flyway-${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz" \
        -O /tmp/flyway.tar.gz
    tar -xzf /tmp/flyway.tar.gz -C /opt
    mv "/opt/flyway-${FLYWAY_VERSION}" "$FLYWAY_DIR"
    ln -sf "$FLYWAY_DIR/flyway" /usr/local/bin/flyway
    rm /tmp/flyway.tar.gz
    echo "  Flyway telepítve: $(flyway -v 2>&1 | head -1)"
else
    echo "  Flyway mar telepitve: $(flyway -v 2>&1 | head -1)"
fi

# --- 4. Migrációk futtatása Flyway-jel ----------------------
echo "[4/4] Migraciok futtatasa (Flyway)..."

flyway \
    -url="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}" \
    -user="$DB_USER" \
    -password="$DB_PASSWORD" \
    -locations="filesystem:${MIGRATIONS_DIR}" \
    migrate

echo ""
echo "Telepites kesz!"
echo "  Adatbazis  : $DB_NAME"
echo "  Felhasznalo: $DB_USER"
echo "  Kapcsolodas: psql -U $DB_USER -d $DB_NAME"
echo ""
echo "Migraciok allapota:"
flyway \
    -url="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}" \
    -user="$DB_USER" \
    -password="$DB_PASSWORD" \
    -locations="filesystem:${MIGRATIONS_DIR}" \
    info
