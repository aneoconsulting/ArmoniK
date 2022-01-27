CURRENT_DIR=$(shell pwd)

.PHONY: docs

all: docs

docs:
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/needed-storage
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/aws/kms
