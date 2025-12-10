postgres:
	docker compose -f docker-compose.db.yml up -d

postgres-down:
	docker compose -f docker-compose.db.yml down

createdb: wait-for-postgres
	docker exec -it postgres17 createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres17 dropdb simple_bank

migrateup:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose up

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
	docker compose -f docker-compose.db.yml -f docker-compose.app.yml build --no-cache
	docker compose -f docker-compose.db.yml -f docker-compose.app.yml up -d

mock:
	mockgen -package mockdb -destination db/mock/store.go github.com/korakrit-c/my-simplebank/db/sqlc Store

wait-for-postgres:
	until docker exec postgres17 pg_isready -U root >/dev/null 2>&1; do \
		echo "Waiting for postgres..."; \
		sleep 1; \
	done

.PHONY: postgres postgres-down createdb dropdb migrateup migratedown migrateup1 migratedown1 sqlc test server mock wait-for-postgres
