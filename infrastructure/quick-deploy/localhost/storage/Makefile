CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
BACKEND?=$(GENERATED_DIR)/backend
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=$(BACKEND)/storage-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/storage-output.json

export TF_DATA_DIR?=$(GENERATED_DIR)
export NAMESPACE?=armonik
export SHARED_HOST_PATH?=$(HOME)/data
export FILE_STORAGE_FILE?=HostPath
export FILE_SERVER_IP?=

.PHONY: apply destroy

all: init apply output
deploy: init apply output
destroy: init delete

init:
	mkdir -p $(GENERATED_DIR)
	terraform init

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var 'shared_storage={"host_path":"$(SHARED_HOST_PATH)","file_storage_type":"$(FILE_STORAGE_FILE)","file_server_ip":"$(FILE_SERVER_IP)"}' \
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
		-var 'shared_storage={"host_path":"$(SHARED_HOST_PATH)","file_storage_type":"$(FILE_STORAGE_FILE)","file_server_ip":"$(FILE_SERVER_IP)"}' \
		-var 'namespace=$(NAMESPACE)' \
		-state $(STATE_FILE) \
		-auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
