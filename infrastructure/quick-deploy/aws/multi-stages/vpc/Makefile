CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=vpc-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/vpc-output.json
MODULES_DIR?=$(GENERATED_DIR)/infra-modules
MODULES_SOURCE=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_images.infra[0]')
MODULES_VERSION=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_versions.infra')

export TF_DATA_DIR?=$(GENERATED_DIR)
export SUFFIX?=main
export REGION?=eu-west-3
export PROFILE?=default
export TFSTATE_BUCKET_NAME?=armonik-tfstate-$(SUFFIX)
export PUBLIC_VPC?=true

.PHONY: apply destroy

all: get-modules init apply output
deploy: get-modules init apply output
destroy: init delete

init:
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade \
		-backend-config 'bucket=$(TFSTATE_BUCKET_NAME)' \
		-backend-config 'region=$(REGION)' \
		-backend-config 'key=$(STATE_FILE)' \
		-backend-config 'profile=$(PROFILE)'

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'suffix=$(SUFFIX)' \
		-var 'profile=$(PROFILE)' \
		-var 'enable_public_vpc=$(PUBLIC_VPC)' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@echo -n "{\"vpc\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json vpc >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

delete:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'suffix=$(SUFFIX)' \
		-var 'profile=$(PROFILE)' \
		-var 'enable_public_vpc=$(PUBLIC_VPC)' \
		-state $(STATE_FILE) \
		-auto-approve

get-modules:
	@if [ -d $(MODULES_DIR) ]; then\
		git -C $(MODULES_DIR) fetch --all --tags;\
		git -C $(MODULES_DIR) -c advice.detachedHead=false checkout $(MODULES_VERSION);\
		git -C $(MODULES_DIR) pull origin $(MODULES_VERSION);\
    else \
      	git -c advice.detachedHead=false clone --branch $(MODULES_VERSION) $(MODULES_SOURCE) $(MODULES_DIR);\
    fi

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
