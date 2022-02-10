CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=eks-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/output.json

export TF_DATA_DIR?=$(GENERATED_DIR)
export TAG?=main
export REGION?=eu-west-3
export PROFILE?=default
export TFSTATE_BUCKET_NAME?=armonik-tfstate
export VPC_PARAMETERS_FILE?=$(CURRENT_DIR)/../vpc/generated/output.json
export STORAGE_PARAMETERS_FILE?=$(CURRENT_DIR)/../storage/generated/output.json

.PHONY: apply destroy

all: init apply output
deploy: init apply output

init:
	mkdir -p generated
	touch generated/terraform.log
	terraform init \
		-backend-config 'bucket=$(TFSTATE_BUCKET_NAME)' \
		-backend-config 'region=$(REGION)' \
		-backend-config 'key=$(STATE_FILE)' \
		-backend-config 'profile=$(PROFILE)'

	@echo -n "{\"s3_fs\":" > $(GENERATED_DIR)/s3-fs.json
	@cat $(STORAGE_PARAMETERS_FILE) | jq '.storage_endpoint_url.shared' >> $(GENERATED_DIR)/s3-fs.json
	@echo -n "}" >> $(GENERATED_DIR)/s3-fs.json

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(VPC_PARAMETERS_FILE) \
		-var-file $(GENERATED_DIR)/s3-fs.json \
		-var 'region=$(REGION)' \
		-var 'tag=$(TAG)' \
		-var 'profile=$(PROFILE)' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@echo -n "{\"eks\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json eks >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(CURRENT_DIR)/$(OUTPUT_FILE)"

destroy:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(VPC_PARAMETERS_FILE) \
		-var-file $(GENERATED_DIR)/s3-fs.json \
		-var 'region=$(REGION)' \
		-var 'tag=$(TAG)' \
		-var 'profile=$(PROFILE)' \
		-state $(STATE_FILE) \
		-auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
