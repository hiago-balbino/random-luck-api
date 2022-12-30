.PHONY: all help setup fmt lint vulncheck tests cover sonarqube-up sonarqube-down sonarqube-analysis build run-api compose-ps compose-up compose-down doc clean

APP_NAME=random_luck

## help: show this help
help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

## setup: run the command mod download and tidy from Go
setup:
	GO111MODULE=on go mod download
	go mod tidy
	go mod verify

## fmt: run go formatter recursively on all files
fmt:
	gofmt -s -w .

## lint: run all linters configured
lint:
	golangci-lint run ./...

## vulncheck: run all vulnerability checks
vulncheck:
	govulncheck ./...

## tests: run all unit tests
tests:
	go test -race -coverprofile coverage.out ./... -short=true -count=1

## pipeline: run all necessary steps to go through the pipeline
pipeline: setup fmt lint vulncheck tests

## cover: run the command tool cover to open coverage file as HTML
cover: tests
	go tool cover -html coverage.out

## sonarqube-up: start sonarqube container
sonarqube-up:
	docker run -d --name sonarqube -p ${SONAR_PORT}:${SONAR_PORT} sonarqube

## sonarqube-down: stop sonarqube container
sonarqube-down:
	docker rm sonarqube -f

## sonarqube-analysis: run sonar scanner
sonarqube-analysis: tests
	${SONAR_BINARY} -Dsonar.host.url=${SONAR_HOST} -Dsonar.login=${SONAR_LOGIN} -Dsonar.password=${SONAR_PASSWORD}

## build: create an executable of the application
build:
	go build -o ${APP_NAME} .
	
## run-api: build project and run the API using the built binary
run-api: build
	./${APP_NAME} api

## compose-ps: list all containers running
compose-ps:
	docker-compose -f docker-compose.yml ps

## compose-up: start the API
compose-up:
	docker-compose -f docker-compose.yml up -d

## compose-down: stop the API
compose-down:
	docker-compose -f docker-compose.yml down

## clean: run the go clean command and removes the application binary
clean:
	go clean
	rm ${APP_NAME}

## doc: run the project documentation using HTTP
doc:
	godoc -http=:6060

all: help