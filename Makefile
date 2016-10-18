NAMESPACE := namespace 
REGISTRY := quay.io/osterzel 
CONTAINER_NAME := radiator
VERSION := $(shell git rev-parse head | cut -c1-10) 
DOCKER_CONTAINER := $(REGISTRY)/$(CONTAINER_NAME):$(VERSION)

docker:
	docker build -t $(DOCKER_CONTAINER) .

push:
	docker push $(DOCKER_CONTAINER)

run:
	docker run -t -i -p 3030:3030 $(DOCKER_CONTAINER)
