CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=storage-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/output.json

export TF_DATA_DIR?=$(GENERATED_DIR)
export TAG?=main
export REGION?=eu-west-3
export PROFILE?=default
export TFSTATE_BUCKET_NAME?=armonik-tfstate-$(TAG)
export VPC_PARAMETERS_FILE?=$(CURRENT_DIR)/../vpc/generated/output.json

.PHONY: apply destroy

all: init apply output
deploy: init apply output

init:
	mkdir -p generated
	terraform init \
		-backend-config 'bucket=$(TFSTATE_BUCKET_NAME)' \
		-backend-config 'region=$(REGION)' \
		-backend-config 'key=$(STATE_FILE)' \
		-backend-config 'profile=$(PROFILE)'

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(VPC_PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'tag=$(TAG)' \
		-var 'profile=$(PROFILE)' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@echo -n "{\"storage_endpoint_url\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json storage_endpoint_url >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(CURRENT_DIR)/$(OUTPUT_FILE)"

destroy:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(VPC_PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'tag=$(TAG)' \
		-var 'profile=$(PROFILE)' \
		-state $(STATE_FILE) \
		-auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
