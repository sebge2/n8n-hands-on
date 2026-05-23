REGISTRY ?= sebge2
IMAGE_NAME ?= n8n-runner
VERSION = 1.0.0
IMAGE_VERSIONED = $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
IMAGE_LATEST    = $(REGISTRY)/$(IMAGE_NAME):latest

all: build

login:
	docker login

build:
	docker build -t $(IMAGE_VERSIONED) -t $(IMAGE_LATEST) .
	docker image prune -f

push:
	docker push $(IMAGE_VERSIONED)
	docker push $(IMAGE_LATEST)

release: build push

clean:
	-docker rmi $(IMAGE_VERSIONED)
	-docker rmi $(IMAGE_LATEST)
	docker system prune -f
