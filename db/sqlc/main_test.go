package db

import (
	"context"
	"log"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	dbSource = "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable"
)

var testQueries *Queries
var testPool *pgxpool.Pool
var testStore *Store

func TestMain(m *testing.M) {
	ctx := context.Background()

	var err error
	testPool, err = pgxpool.New(ctx, dbSource)
	if err != nil {
		log.Fatal("cannot connect to db:", err)
	}

	testQueries = New(testPool)
	testStore = NewStore(testPool)

	m.Run()
}
