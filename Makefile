.DEFAULT_GOAL=build

IMAGE=azure-devops-agent

build: build-linux

build-linux:
	docker build -t ${IMAGE}:linux -f Dockerfile .

build-windows:
	docker build -t ${IMAGE}:windows -f Dockerfile.windows .

build-all: build-linux build-windows

run: run-linux

run-linux:
	docker run -it --rm ${IMAGE}:linux bash

run-windows:
	docker run -it --rm ${IMAGE}:windows powershell