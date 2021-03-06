SHA = $(shell git rev-parse --short HEAD)
GO_PKGS = $$(go list ./... | grep -v vendor)
REPOSITORY = 095427547185.dkr.ecr.us-west-2.amazonaws.com/skuid/skuid
TAG = latest
VOL_PATH=/go/src/github.com/skuid/skuid
GO_VERSION=1.8
IMAGE ?= golang

ARCH=amd64
OS=darwin

VERSION=0.1.0

.PHONY: setup fmt vendored

setup:
	go get -u github.com/kardianos/govendor

fmt:
	go fmt $(GO_PKGS)

build: fmt
	docker run --rm \
		-e GOOS=$(OS) \
		-e GOARCH=$(ARCH) \
		-v $$(pwd):$(VOL_PATH) -w $(VOL_PATH) $(IMAGE):$(GO_VERSION) \
		go build -v -a -tags netgo -installsuffix netgo -ldflags '-w'

vendored:
	test $$(govendor list +e |wc -l | awk '{print $$1}') -lt 1

docker:
	docker run --rm -v $$(pwd):$(VOL_PATH) -u jenkins-slave -w $(VOL_PATH) $(IMAGE):$(GO_VERSION) go build -v -a -tags netgo -installsuffix netgo -ldflags '-w'
	docker build -t $(REPOSITORY):$(TAG) .

push:
	$$(aws ecr get-login --region us-west-2)
	docker push $(REPOSITORY):$(TAG)

release:
	git tag $(VERSION)
	GOOS=linux GOARCH=amd64 go build -o skuid_linux_amd64
	GOOS=darwin GOARCH=amd64 go build -o skuid_darwin_amd64