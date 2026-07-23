#!/bin/bash
#
# bootstrap.sh — Monta o ambiente de dev completo em um PC zerado (Ubuntu/Debian).
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/mcorreiam/dev-infra/main/bootstrap.sh | bash
#   # ou, se ja tiver o repo clonado:
#   ./bootstrap.sh
#
# O que faz:
#   1. Instala Docker Engine + Compose plugin
#   2. Instala git e GitHub CLI (gh)
#   3. Adiciona o usuario ao grupo docker
#   4. Clona o repositorio dev-infra em ~/projects (se ainda nao existir)
#   5. Cria a rede dev-shared e sobe a infra (Postgres, Redis, Mongo + GUIs)
#

set -euo pipefail

REPO_URL="${DEV_INFRA_REPO:-https://github.com/mcorreiam/dev-infra.git}"
TARGET_DIR="${DEV_INFRA_DIR:-$HOME/projects}"

info() { echo ""; echo "=== $* ==="; }

# --- 1. Pre-requisitos do apt -------------------------------------------------
info "Instalando pre-requisitos"
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git make

# --- 2. Docker ----------------------------------------------------------------
if command -v docker &>/dev/null; then
    info "Docker ja instalado: $(docker --version)"
else
    info "Instalando Docker"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# --- 3. GitHub CLI ------------------------------------------------------------
if command -v gh &>/dev/null; then
    info "GitHub CLI ja instalado: $(gh --version | head -1)"
else
    info "Instalando GitHub CLI"
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y gh
fi

# --- 4. Grupo docker ----------------------------------------------------------
if id -nG | grep -qw docker; then
    info "Usuario ja esta no grupo docker (sessao atual)"
elif getent group docker | grep -qw "$USER"; then
    info "Usuario esta no grupo docker, mas a sessao atual nao"
    echo ""
    echo ">>> Rode:  exec su - \$USER"
    echo ">>> Depois: $0"
    exit 0
else
    info "Adicionando usuario ao grupo docker"
    sudo usermod -aG docker "$USER"
    echo ""
    echo ">>> Rode:  exec su - \$USER"
    echo ">>> Depois: $0"
    exit 0
fi

# --- 5. Clone do repositorio --------------------------------------------------
if [ -d "$TARGET_DIR/infra" ]; then
    info "Repositorio ja existe em $TARGET_DIR"
else
    info "Clonando repositorio para $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    # Se estamos rodando a partir do proprio repo clonado, nao precisa clonar
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-/dev/null}")" 2>/dev/null && pwd || echo "")"
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/infra/docker-compose.yml" ]; then
        info "Rodando a partir do repo local, pulando clone"
    else
        git clone "$REPO_URL" "$TARGET_DIR"
    fi
fi

# --- 6. Sobe a infra ----------------------------------------------------------
info "Criando rede dev-shared"
docker network create dev-shared 2>/dev/null || echo "Rede dev-shared ja existe"

info "Subindo servicos da infra"
docker compose -f "$TARGET_DIR/infra/docker-compose.yml" --env-file "$TARGET_DIR/infra/.env" up -d

info "Aguardando healthchecks"
sleep 10
docker compose -f "$TARGET_DIR/infra/docker-compose.yml" ps

info "Ambiente pronto!"
echo ""
echo "  Postgres:    localhost:5432  (dev/dev)"
echo "  Redis:       localhost:6379"
echo "  MongoDB:     localhost:27017 (dev/dev)"
echo "  Redis GUI:   http://localhost:8081"
echo "  Mongo GUI:   http://localhost:8082"
echo ""
echo "  Novo projeto:  cd $TARGET_DIR && ./new-project.sh <nome>"
echo "  Criar banco:   cd $TARGET_DIR/infra && make create-db DB=<nome_db>"
