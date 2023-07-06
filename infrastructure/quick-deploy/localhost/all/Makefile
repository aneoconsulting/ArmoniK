CURRENT_DIR:=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
INGRESS_CERTIFICATES_DIR=$(GENERATED_DIR)/certificates/ingress
PARAMETERS_FILE?=parameters.tfvars
EXTRA_PARAMETERS_FILE?=../../../../extra.tfvars.json
VERSIONS_FILE?=../../../../versions.tfvars.json
OUTPUT_FILE=$(GENERATED_DIR)/armonik-output.json
MODULES_DIR=$(GENERATED_DIR)/infra-modules
MODULES_SOURCE=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_images.infra[0]')
MODULES_VERSION=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_versions.infra')

export KUBE_CONFIG_PATH?=$(HOME)/.kube/config
export TF_DATA_DIR?=$(GENERATED_DIR)
export NAMESPACE?=armonik
export PREFIX?=armonik-local
export TF_VAR_namespace?=$(NAMESPACE)
export TF_VAR_prefix?=$(PREFIX)

.PHONY: apply destroy

all: get-modules init apply output
deploy: get-modules init apply output
destroy: init delete

env:
	@set

init:
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade -reconfigure -backend-config="secret_suffix=$(PREFIX)" -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE)

plan:
	terraform plan -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE)  -out=/dev/null

apply:
	terraform apply -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -auto-approve

refresh:
	terraform refresh -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -auto-approve

delete:
	terraform destroy -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -auto-approve

state-pull:
	terraform state pull

output:
	@terraform output -json | jq 'map_values(.value)' > $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

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
