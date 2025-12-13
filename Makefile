COMPOSE = docker compose -f docker-compose.yml
DB_SVC = postgres
DB_NAME = simple_bank
DB_USER = root

postgres:
	$(COMPOSE) up -d postgres

postgres-down:
	$(COMPOSE) down

createdb: wait-for-postgres
	$(COMPOSE) exec -T $(DB_SVC) createdb --username=$(DB_USER) --owner=$(DB_USER) $(DB_NAME)

dropdb:
	$(COMPOSE) exec -T $(DB_SVC) dropdb --if-exists $(DB_NAME)

migrateup:
#	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose up
	$(COMPOSE) up --no-deps --force-recreate migrate

migratedown:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose down

migrateup1:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose up 1

migratedown1:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose down 1

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
