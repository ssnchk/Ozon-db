package main

import (
	"database/sql"
	"fmt"
	_ "github.com/lib/pq"
	"os"
	"strconv"
	"sync"
	"time"
)

func main() {
	fmt.Println("Start working service")
	connStr := fmt.Sprintf("host=haproxy port=5000 user=%s password=%s dbname=%s sslmode=disable", os.Getenv("CREATOR_USER"), os.Getenv("CREATOR_PASSWORD"), os.Getenv("DB_NAME"))
	workingTime, err := strconv.Atoi(os.Getenv("SERVICE_WORKING_TIME"))
	if err != nil {
		panic(err.Error())
	}
	restTime, err := strconv.Atoi(os.Getenv("SERVICE_REST_TIME"))
	if err != nil {
		panic(err.Error())
	}

	bd, err := sql.Open("postgres", connStr)
	defer bd.Close()
	if err != nil {
		panic(err.Error())
	}

	requests := mustLoadSql()

	wg := &sync.WaitGroup{}
	for _, request := range requests {
		wg.Add(1)
		go imitateWork(request, bd, workingTime, restTime, wg)
	}
	wg.Wait()

	fmt.Println("Done")
}

func mustLoadSql() (res []string) {
	scripts, err := os.ReadDir("/app/sql")
	if err != nil {
		panic(err.Error())
	}

	for _, script := range scripts {
		text, _ := os.ReadFile("/app/sql/" + script.Name())
		res = append(res, string(text))
	}
	return res
}

func executeQuery(request string, db *sql.DB, ticker <-chan time.Time, endTime <-chan time.Time) {
	for {
		select {
		case <-ticker:
			_, err := db.Exec(request)
			fmt.Println("Executed query: \n", request)
			if err != nil {
				fmt.Println(err.Error())
			}
		case <-endTime:
			return
		}
	}
}

func imitateWork(request string, db *sql.DB, workingTime int, restTime int, wg *sync.WaitGroup) {
	ticker := time.NewTicker(time.Duration(restTime) * time.Second)
	after := time.After(time.Duration(workingTime) * time.Second)
	defer ticker.Stop()
	defer wg.Done()

	executeQuery(request, db, ticker.C, after)
}
