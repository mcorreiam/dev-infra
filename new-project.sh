#!/bin/bash
#
# new-project.sh — Cria um novo projeto conectado à infra compartilhada.
#
# Uso:
#   ./new-project.sh <nome-do-projeto>
#
# O que faz:
#   1. Valida o nome (lowercase, sem espaços, apto para DNS/db)
#   2. Copia o template projeto-exemplo/
#   3. Aloca portas livres automaticamente (backend + frontend)
#   4. Cria o banco Postgres do projeto (se a infra estiver no ar)
#   5. Ajusta .env e docker-compose.yml com o nome do projeto
#

set -euo pipefail

INFRA_DIR="$(cd "$(dirname "$0")/infra" && pwd)"
TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)/projeto-exemplo"
PROJECTS_ROOT="$(cd "$(dirname "$0")" && pwd)"

die() { echo "Erro: $*" >&2; exit 1; }

# --- Validação do nome -------------------------------------------------------
NAME="${1:-}"
[ -z "$NAME" ] && die "Uso: ./new-project.sh <nome-do-projeto> (ex: meu-saas)"

# Nome deve ser válido para: diretório, container, database, DNS
echo "$NAME" | grep -qE '^[a-z][a-z0-9-]*$' \
    || die "Nome invalido '$NAME'. Use apenas letras minusculas, numeros e hifens, comecando com letra."

PROJECT_DIR="$PROJECTS_ROOT/$NAME"
[ -d "$PROJECT_DIR" ] && die "Diretorio $PROJECT_DIR ja existe"

# Nome do banco: hifen nao e valido sem quoting, entao troca por underscore
DB_NAME="${NAME//-/_}_db"

# --- Alocação de portas ------------------------------------------------------
# Procura a maior porta usada nos .env dos projetos existentes e soma 1.
# Ranges: backend 8000-8999, frontend 3000-3999.
next_port() {
    local var_name=$1 default=$2 max=0 port
    for env_file in "$PROJECTS_ROOT"/*/.env; do
        [ -f "$env_file" ] || continue
        port=$(grep -E "^${var_name}=" "$env_file" 2>/dev/null | cut -d= -f2 || true)
        [ -n "$port" ] && [ "$port" -gt "$max" ] 2>/dev/null && max=$port
    done
    if [ "$max" -eq 0 ]; then echo "$default"; else echo $((max + 1)); fi
}

BACKEND_PORT=$(next_port BACKEND_PORT 8000)
FRONTEND_PORT=$(next_port FRONTEND_PORT 3000)

# --- Criação -----------------------------------------------------------------
echo "=== Criando projeto: $NAME ==="
echo "  Diretorio:     $PROJECT_DIR"
echo "  Banco:         $DB_NAME"
echo "  Backend port:  $BACKEND_PORT"
echo "  Frontend port: $FRONTEND_PORT"
echo ""

cp -r "$TEMPLATE_DIR" "$PROJECT_DIR"

# Remove artefatos do template que nao devem ir para o novo projeto
rm -rf "$PROJECT_DIR/backend/src/__pycache__"

# Compose: troca o nome do projeto (chave 'name:' do compose)
sed -i "s/^name: exemplo$/name: $NAME/" "$PROJECT_DIR/docker-compose.yml"
sed -i "s/exemplo_db/$DB_NAME/g" "$PROJECT_DIR/docker-compose.yml"

# .env do projeto
cat > "$PROJECT_DIR/.env" <<EOF
PROJECT_DB=$DB_NAME
BACKEND_PORT=$BACKEND_PORT
FRONTEND_PORT=$FRONTEND_PORT
EOF

# .gitignore do projeto
cat > "$PROJECT_DIR/.gitignore" <<'EOF'
__pycache__/
*.pyc
node_modules/
dist/
.env.local
EOF

# --- Banco de dados ----------------------------------------------------------
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^infra-postgres$'; then
    if docker exec infra-postgres psql -U dev -lqt | cut -d'|' -f1 | grep -qw "$DB_NAME"; then
        echo "Banco '$DB_NAME' ja existe, pulando criacao"
    else
        docker exec infra-postgres psql -U dev -c "CREATE DATABASE $DB_NAME;" >/dev/null
        echo "Banco '$DB_NAME' criado"
    fi
else
    echo "AVISO: infra-postgres nao esta rodando. Crie o banco depois:"
    echo "  cd infra && make create-db DB=$DB_NAME"
fi

echo ""
echo "=== Projeto pronto ==="
echo ""
echo "  cd $PROJECT_DIR"
echo "  docker compose up -d --build"
echo ""
echo "  Backend:  http://localhost:$BACKEND_PORT"
echo "  Frontend: http://localhost:$FRONTEND_PORT"
