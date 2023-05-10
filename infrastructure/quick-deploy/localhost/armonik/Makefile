CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
BACKEND?=$(GENERATED_DIR)/backend
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=$(BACKEND)/armonik-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/armonik-output.json
VERSIONS_FILE?=../../../../versions.tfvars.json
MODULES_SOURCE=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_images.infra[0]')
MODULES_VERSION=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_versions.infra')

export TF_DATA_DIR?=$(GENERATED_DIR)
export NAMESPACE?=armonik

.PHONY: apply destroy

all: get-modules init apply output
deploy: get-modules init apply output
destroy: get-modules init delete

init:
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var 'namespace=$(NAMESPACE)' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@echo -n "{\"armonik\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json armonik >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

delete:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var 'namespace=$(NAMESPACE)' \
		-state $(STATE_FILE) \
		-auto-approve

get-modules:
	@if [ -d $(MODULES_DIR) ]; then\
		git -C $(MODULES_DIR) -c advice.detachedHead=false checkout $(MODULES_VERSION);\
    else \
      	git -c advice.detachedHead=false clone --branch $(MODULES_VERSION) $(MODULES_SOURCE) $(MODULES_DIR);\
    fi

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
