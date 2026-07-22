.PHONY: up down restart status logs setup create-db

setup:
	@echo "=== Criando rede dev-shared ==="
	@docker network create dev-shared 2>/dev/null || echo "Rede ja existe"
	@echo "=== Subindo servicos ==="
	docker compose up -d
	@echo ""
	@echo "=== Servicos disponiveis ==="
	@echo "  Postgres:    localhost:5432  (dev/dev/devdb)"
	@echo "  Redis:       localhost:6379"
	@echo "  MongoDB:     localhost:27017 (dev/dev)"
	@echo "  Redis GUI:   localhost:8081"
	@echo "  Mongo GUI:   localhost:8082"
	@echo ""
	@echo "=== Conexao entre projetos ==="
	@echo "  Postgres: infra-postgres:5432"
	@echo "  Redis:    infra-redis:6379"
	@echo "  MongoDB:  infra-mongo:27017"

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

status:
	docker compose ps

logs:
	docker compose logs -f

create-db:
	@if [ -z "$(DB)" ]; then echo "Uso: make create-db DB=nome_do_banco"; exit 1; fi
	docker exec -it infra-postgres psql -U dev -c "CREATE DATABASE $(DB);"
	@echo "Banco '$(DB)' criado com sucesso"

drop-db:
	@if [ -z "$(DB)" ]; then echo "Uso: make drop-db DB=nome_do_banco"; exit 1; fi
	docker exec -it infra-postgres psql -U dev -c "DROP DATABASE $(DB);"
	@echo "Banco '$(DB)' removido"

list-dbs:
	docker exec -it infra-postgres psql -U dev -c "\l"
