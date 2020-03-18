v ?= v0.2.1

all: build

build:
	docker pull alpine:latest && docker pull node:alpine
	docker build --build-arg ELASTALERT_VERSION=$(v) -t elastalert .

server: build
	docker run -it --rm -p 3030:3030 \
	--net="host" \
	elastalert:3.0.0-beta.0

.PHONY: build
