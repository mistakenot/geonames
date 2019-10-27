package main

import (
    "fmt"
    "io/ioutil"
)

func main() {
	parents_of := make(map[int]int)
	file, err := os.Open("./data/heirarchy.tsv")
    if err != nil {
        log.Fatal(err)
    }
    defer file.Close()

    scanner := bufio.NewScanner(file)
    for scanner.Scan() {
		line := scanner.Text()
		
    }

    if err := scanner.Err(); err != nil {
        log.Fatal(err)
    }
}