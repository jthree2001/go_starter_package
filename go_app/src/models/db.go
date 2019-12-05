package models

import (
	"log"

	_ "github.com/lib/pq"
	"github.com/jmoiron/sqlx"
)

var DB *sqlx.DB

func init() {
	var err error
	driver_name := "postgres"
	if driver_name == "" {
		log.Fatal("Invalid driver name")
	}
	dsn := "host=localhost port=5432 user=postgres dbname=starter_package_development sslmode=disable password=root"
	if dsn == "" {
		log.Fatal("Invalid DSN")
	}
	DB, err = sqlx.Connect(driver_name, dsn)
	if err != nil {
		log.Fatal(err)
	}
}
