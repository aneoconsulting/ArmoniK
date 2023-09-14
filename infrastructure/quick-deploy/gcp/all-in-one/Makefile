CURRENT_DIR:=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
INGRESS_CERTIFICATES_DIR=$(GENERATED_DIR)/certificates/ingress
PARAMETERS_FILE?=parameters.tfvars
EXTRA_PARAMETERS_FILE?=../../../../extra.tfvars.json
VERSIONS_FILE?=../../../../versions.tfvars.json
STATE_FILE=armonik-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/armonik-output.json
MODULES_DIR=$(GENERATED_DIR)/infra-modules
MODULES_SOURCE=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_images.infra[0]')
MODULES_VERSION=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_versions.infra')

# Randomly generated string that is preserved across calls
RANDOM_PREFIX != [ -e $(GENERATED_DIR)/.prefix ] || { mkdir -p $(GENERATED_DIR) && tr -dc a-z0-9 </dev/urandom | head -c 10 > $(GENERATED_DIR)/.prefix ; } && cat $(GENERATED_DIR)/.prefix

export TF_DATA_DIR?=$(GENERATED_DIR)
export TF_PLUGIN_CACHE_DIR?=$(GENERATED_DIR)/terraform-plugins
export PROJECT_ID?=$(shell gcloud config get-value project)
export REGION?=europe-west1
export NAMESPACE?=armonik
export PREFIX?=armonik-$(RANDOM_PREFIX)
export TFSTATE_BUCKET_NAME?=$(PREFIX)-tfstate

export TF_VAR_region?=$(REGION)
export TF_VAR_namespace?=$(NAMESPACE)
export TF_VAR_prefix?=$(PREFIX)
export TF_VAR_project?=$(PROJECT_ID)

.PHONY: apply destroy

all: get-modules init apply output kubeconfig
deploy: get-modules init apply output kubeconfig
destroy: init delete

env:
	@set

init:
	mkdir -p $(TF_PLUGIN_CACHE_DIR)
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade -reconfigure -backend-config 'bucket=$(TFSTATE_BUCKET_NAME)'

plan:
	terraform plan -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -out=/dev/null

apply:
	terraform apply -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -auto-approve

refresh:
	terraform refresh -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE)

delete:
	terraform destroy -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -auto-approve

output:
	@terraform output -state=$(STATE_FILE) -json | jq 'map_values(.value)' > $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

kubeconfig:
	@echo "Execute the following commands:"
	@echo "------------------------------"
	@echo "export KUBECONFIG=$(shell cat $(GENERATED_DIR)/armonik-output.json | jq -r '.gke.kubeconfig_file')"

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
