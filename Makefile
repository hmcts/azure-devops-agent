.DEFAULT_GOAL=build

IMAGE=azure-devops-agent

build: build-linux

build-linux:
	docker build -t ${IMAGE}:linux -f Dockerfile .

build-windows:
	DOCKER_BUILDKIT=1 docker build -t ${IMAGE}:windows -f Dockerfile.windows .

build-windows-multistage:
	DOCKER_BUILDKIT=1 docker build -t ${IMAGE}:windows-multistage -f Dockerfile.windows.multistage .

build-all: build-linux build-windows

# BuildKit-enabled builds with cache
buildx-windows:
	docker buildx build --platform windows/amd64 \
		--cache-from=type=local,src=.docker-cache \
		--cache-to=type=local,dest=.docker-cache,mode=max \
		-f Dockerfile.windows \
		-t ${IMAGE}:windows \
		--load .

buildx-windows-multistage:
	docker buildx build --platform windows/amd64 \
		--cache-from=type=local,src=.docker-cache \
		--cache-to=type=local,dest=.docker-cache,mode=max \
		-f Dockerfile.windows.multistage \
		-t ${IMAGE}:windows-multistage \
		--load .

run: run-linux

run-linux:
	docker run -it --rm ${IMAGE}:linux bash

run-windows:
	docker run -it --rm ${IMAGE}:windows powershell

# Clean cache
clean-cache:
	rm -rf .docker-cache

.PHONY: build build-linux build-windows build-windows-multistage build-all buildx-windows buildx-windows-multistage run run-linux run-windows clean-cache