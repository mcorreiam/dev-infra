# dev-infra

Ambiente local de desenvolvimento com Docker, organizado como a infra de uma
pequena empresa: **bancos de dados compartilhados** (Postgres, Redis, MongoDB)
rodando uma única vez, e cada projeto se conecta a eles via rede Docker externa.

## Bootstrap (PC zerado)

```bash
curl -fsSL https://raw.githubusercontent.com/mcorreiam/dev-infra/main/bootstrap.sh | bash
```

Instala Docker + git + gh, clona este repo em `~/projects` e sobe a infra.

## Estrutura

```
~/projects/
├── bootstrap.sh        # Setup completo em PC novo
├── new-project.sh      # Cria projeto do template
├── infra/              # Serviços compartilhados (subir UMA vez)
│   ├── docker-compose.yml
│   ├── .env
│   └── Makefile
└── projeto-exemplo/    # Template: FastAPI + React/Vite
```

## Uso diário

```bash
# Infra (de ~/projects/infra)
make up                          # sobe postgres, redis, mongo + GUIs
make create-db DB=meu_banco      # cria database Postgres
make status && make logs

# Novo projeto (de ~/projects)
./new-project.sh meu-app         # valida nome, aloca portas, cria banco
cd meu-app && docker compose up -d --build
```

## Conexões (dentro da rede `dev-shared`)

| Serviço  | Hostname         | URL de exemplo                                        |
|----------|------------------|-------------------------------------------------------|
| Postgres | `infra-postgres` | `postgresql://dev:dev@infra-postgres:5432/<db>`       |
| Redis    | `infra-redis`    | `redis://infra-redis:6379`                            |
| MongoDB  | `infra-mongo`    | `mongodb://dev:dev@infra-mongo:27017/<db>`            |

GUIs no host: Redis Commander → http://localhost:8081 · Mongo Express → http://localhost:8082

## Regras

- Nunca `localhost` para banco dentro de container — use os hostnames `infra-*`.
- Nunca `depends_on` apontando para serviços da infra (compose externo).
- Portas no host são alocadas incrementalmente pelo `new-project.sh`.
- Dados persistem nos volumes `dev-pgdata`, `dev-redisdata`, `dev-mongodata`.
