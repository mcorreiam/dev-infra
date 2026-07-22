#!/bin/bash

set -e

echo "=== Dev Environment Setup ==="
echo ""

if ! command -v docker &> /dev/null; then
    echo "Docker nao encontrado. Instalando..."
    echo ""
    echo "Execute os seguintes comandos:"
    echo ""
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y ca-certificates curl gnupg"
    echo "  sudo install -m 0755 -d /etc/apt/keyrings"
    echo "  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
    echo "  sudo chmod a+r /etc/apt/keyrings/docker.gpg"
    echo "  echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \$VERSION_CODENAME) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    echo ""
    exit 1
fi

echo "Docker encontrado: $(docker --version)"
echo "Docker Compose: $(docker compose version)"
echo ""

echo "=== Criando rede dev-shared ==="
docker network create dev-shared 2>/dev/null && echo "Rede dev-shared criada" || echo "Rede dev-shared ja existe"
echo ""

echo "=== Subindo servicos ==="
docker compose up -d
echo ""

echo "=== Aguardando servicos ==="
sleep 5
docker compose ps
echo ""

echo "=== Ambiente pronto! ==="
echo ""
echo "Servicos disponiveis:"
echo "  Postgres:    localhost:5432  (dev/dev)"
echo "  Redis:       localhost:6379"
echo "  MongoDB:     localhost:27017 (dev/dev)"
echo "  Redis GUI:   localhost:8081"
echo "  Mongo GUI:   localhost:8082"
echo ""
echo "Para criar um banco Postgres para um projeto:"
echo "  make create-db DB=nome_do_projeto"
echo ""
