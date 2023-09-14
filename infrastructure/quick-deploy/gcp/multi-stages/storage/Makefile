CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=storage-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/storage-output.json
VERSIONS_FILE?=../../../../versions.tfvars.json
MODULES_DIR?=$(GENERATED_DIR)/infra-modules
MODULES_SOURCE=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_images.infra[0]')
MODULES_VERSION=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_versions.infra')
TERRAFORM_PLUGINS?=$(GENERATED_DIR)/terraform-plugins

export TF_DATA_DIR?=$(GENERATED_DIR)
export TF_PLUGIN_CACHE_DIR?=$(TERRAFORM_PLUGINS)
export SUFFIX?=main
export REGION?=europe-west1
export GCP_PROJECT_ID?=$(shell gcloud config get-value project)
export NAMESPACE?=armonik
export TFSTATE_BUCKET_NAME?=armonik-tfstate-$(SUFFIX)
export VPC_PARAMETERS_FILE?=$(CURRENT_DIR)/../vpc/generated/vpc-output.json
export GKE_PARAMETERS_FILE?=$(CURRENT_DIR)/../gke/generated/gke-output.json
export GAR_PARAMETERS_FILE?=$(CURRENT_DIR)/../gar/generated/gar-output.json

.PHONY: apply destroy

all: get-modules init apply output
deploy: get-modules init apply output
destroy: init delete

init:
	mkdir -p $(TF_PLUGIN_CACHE_DIR)
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade -reconfigure -backend-config 'bucket=$(TFSTATE_BUCKET_NAME)'

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(VPC_PARAMETERS_FILE) \
		-var-file $(GKE_PARAMETERS_FILE) \
		-var-file $(GAR_PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'suffix=$(SUFFIX)' \
		-var 'project=$(GCP_PROJECT_ID)' \
		-var 'namespace=$(NAMESPACE)' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@echo -n "{\"storage_endpoint_url\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json storage_endpoint_url >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

delete:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(VPC_PARAMETERS_FILE) \
		-var-file $(GKE_PARAMETERS_FILE) \
		-var-file $(GAR_PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'suffix=$(SUFFIX)' \
		-var 'project=$(GCP_PROJECT_ID)' \
		-var 'namespace=$(NAMESPACE)' \
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
