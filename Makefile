NAME = micro
GIT_COMMIT = $(shell git rev-parse --short HEAD)
GIT_TAG = $(shell git describe --abbrev=0 --tags --always --match "v*")
GIT_IMPORT = micro.dev/v4/cmd
BUILD_DATE = $(shell date +%s)
LDFLAGS = -X $(GIT_IMPORT).BuildDate=$(BUILD_DATE) -X $(GIT_IMPORT).GitCommit=$(GIT_COMMIT) -X $(GIT_IMPORT).GitTag=$(GIT_TAG)

DOCKER_BUILD = docker buildx build
DOCKER_BUILD_ARGS = --platform linux/amd64 --platform linux/arm64
DOCKER_IMAGE_NAME = micro/$(NAME)
DOCKER_IMAGE_TAG = --tag $(DOCKER_IMAGE_NAME):$(GIT_TAG)-$(GIT_COMMIT) --tag $(DOCKER_IMAGE_NAME):latest

GOPATH = $(shell go env GOPATH)
PROTO_FILES = $(wildcard proto/**/*.proto)
PROTO_GO_MICRO = $(PROTO_FILES:.proto=.pb.go) $(PROTO_FILES:.proto=.pb.micro.go)


.DEFAULT_GOAL := $(NAME)

.PHONY: tidy
tidy:
	go mod tidy

$(NAME):
	CGO_ENABLED=1 go build -ldflags "-s -w ${LDFLAGS}" -o $(NAME) cmd/micro/main.go

.PHONY: docker
docker:
	$(DOCKER_BUILD) $(DOCKER_BUILD_ARGS) $(DOCKER_IMAGE_TAGS) --push .

.PHONY: proto
proto: $(PROTO_GO_MICRO)

%.pb.micro.go %.pb.go: %.proto clean
	protoc --proto_path=. --micro_out=. --go_out=. $<

.PHONY: vet
vet:
	go vet ./...

.PHONY: test
test: vet
	go test -v -race ./...

.PHONY: clean
clean:
	rm -f $(NAME) $(PROTO_GO_MICRO)

.PHONY: gorelease-dry-run
gorelease-dry-run:
	docker run \
		--rm \
		-e CGO_ENABLED=1 \
		-v $(CURDIR):/$(NAME) \
		-w /$(NAME) \
		ghcr.io/goreleaser/goreleaser-cross:v1.20.6 \
		--clean --verbose --skip-validate --skip-publish --snapshot

.PHONY: gorelease-dry-run-docker
gorelease-dry-run-docker:
	docker run \
		--rm \
		-e CGO_ENABLED=1 \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(CURDIR):/$(NAME) \
		-w /$(NAME) \
		ghcr.io/goreleaser/goreleaser-cross:latest \
		--clean --verbose --skip-validate --skip-publish --snapshot --config .goreleaser-docker.yml

.PHONY: lint
lint: $(GOPATH)/bin/golangci-lint
	golangci-lint run ./...

$(GOPATH)/bin/golangci-lint:
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.58.0

