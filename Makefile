.DEFAULT=build

IMAGE=hmcts/azure-devops-agent

build:
	docker build -t ${IMAGE} .

run:
	docker run -it --rm ${IMAGE} bash