CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
PARAMETERS_FILE?=parameters.tfvars
BACKEND_SUFFIX?=armonik
OUTPUT_FILE=$(GENERATED_DIR)/storage-output.json
VERSIONS_FILE?=../../../../versions.tfvars.json
MODULES_DIR?=$(GENERATED_DIR)/infra-modules
MODULES_SOURCE=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_images.infra[0]')
MODULES_VERSION=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_versions.infra')

export KUBE_CONFIG_PATH?=$(HOME)/.kube/config
export TF_DATA_DIR?=$(GENERATED_DIR)
export TF_PLUGIN_CACHE_DIR?=$(TERRAFORM_PLUGINS)
export NAMESPACE?=armonik
export EXTERNAL_DATA_PLANE_NAMESPACE?=external-data-plane
export SHARED_HOST_PATH?=$(HOME)/data
export FILE_STORAGE_FILE?=HostPath
export FILE_SERVER_IP?=

.PHONY: apply destroy

all: get-modules init apply output
deploy: get-modules init apply output
destroy: init delete

init:
	mkdir -p $(TF_PLUGIN_CACHE_DIR)
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade -reconfigure \
		-backend-config="secret_suffix=storage-$(BACKEND_SUFFIX)" 

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(VERSIONS_FILE) \
		-var 'shared_storage={"host_path":"$(SHARED_HOST_PATH)","file_storage_type":"$(FILE_STORAGE_FILE)","file_server_ip":"$(FILE_SERVER_IP)"}' \
		-var 'namespace=$(NAMESPACE)' \
		-var 'external_data_plane_namespace=$(EXTERNAL_DATA_PLANE_NAMESPACE)' \
		-auto-approve

output:
	@echo -n "{\"storage_endpoint_url\":" > $(OUTPUT_FILE)
	@terraform output -json storage_endpoint_url >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

delete:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(VERSIONS_FILE) \
		-var 'shared_storage={"host_path":"$(SHARED_HOST_PATH)","file_storage_type":"$(FILE_STORAGE_FILE)","file_server_ip":"$(FILE_SERVER_IP)"}' \
		-var 'namespace=$(NAMESPACE)' \
		-var 'external_data_plane_namespace=$(EXTERNAL_DATA_PLANE_NAMESPACE)' \
		-auto-approve

state-pull:
	terraform state pull

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
