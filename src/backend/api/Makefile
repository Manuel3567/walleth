.PHONY: start stop
# Makefile

# Variables
CONTAINER_NAME = my-apisix-container
APISIX_IMAGE = apache/apisix:3.7.0-debian
CONFIG_FILE = $(shell pwd)/conf/apisix.yaml

# Targets
start:
	docker run -d --name httpbin --network api --rm -p 80:80 kennethreitz/httpbin
	docker run --rm \
	  --name $(CONTAINER_NAME) \
	  --network=api \
	  -p 9080:9080 \
	  -p 9443:9443 \
	  -v $(CONFIG_FILE):/usr/local/apisix/conf/apisix.yaml:ro \
	  -e APISIX_STAND_ALONE=true \
	  $(APISIX_IMAGE)

stop:
	docker stop httpbin 2>/dev/null 
	docker stop $(CONTAINER_NAME) 2>/dev/null 