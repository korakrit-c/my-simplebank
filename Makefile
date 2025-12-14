COMPOSE = docker compose -f docker-compose.yml
DB_SVC = postgres
DB_NAME = simple_bank
DB_USER = root
DB_PASSWORD ?= secret
DB_HOST ?= localhost
DB_PORT ?= 5432

DB_SOURCE ?= postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable

postgres:
	$(COMPOSE) up -d postgres

postgres-down:
	$(COMPOSE) down

createdb: wait-for-postgres
	$(COMPOSE) exec -T $(DB_SVC) createdb --username=$(DB_USER) --owner=$(DB_USER) $(DB_NAME)

dropdb:
	$(COMPOSE) exec -T $(DB_SVC) dropdb --if-exists $(DB_NAME)

migrateup:
	@if command -v migrate >/dev/null 2>&1; then \
		migrate -path db/migration -database "$(DB_SOURCE)" -verbose up; \
	else \
		$(COMPOSE) up --no-deps --force-recreate migrate; \
	fi

migratedown:
	migrate -path db/migration -database "$(DB_SOURCE)" -verbose down

migrateup1:
	migrate -path db/migration -database "$(DB_SOURCE)" -verbose up 1

migratedown1:
	migrate -path db/migration -database "$(DB_SOURCE)" -verbose down 1

sqlc:
	sqlc generate

test:
	go test -v -cover ./...

server:
	$(COMPOSE) up --build -d

mock:
	mockgen -package mockdb -destination db/mock/store.go github.com/korakrit-c/my-simplebank/db/sqlc Store

wait-for-postgres:
	until $(COMPOSE) exec -T $(DB_SVC) pg_isready -U $(DB_USER) -d $(DB_NAME) >/dev/null 2>&1; do \
		echo "Waiting for postgres..."; \
		sleep 1; \
	done

.PHONY: postgres postgres-down createdb dropdb migrateup migratedown migrateup1 migratedown1 sqlc test server mock wait-for-postgres
