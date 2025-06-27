package db

import (
	"context"
	"log"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/korakrit-c/my-simplebank/util"
)

var testQueries *Queries
var testPool *pgxpool.Pool
var testStore *Store

func TestMain(m *testing.M) {
	config, err := util.LoadConfig("../..")
	if err != nil {
		log.Fatal("cannot load config:", err)
	}

	ctx := context.Background()
	testPool, err = pgxpool.New(ctx, config.DBSource)
	if err != nil {
		log.Fatal("cannot connect to db:", err)
	}

	testQueries = New(testPool)
	testStore = NewStore(testPool)

	os.Exit(m.Run())
}
