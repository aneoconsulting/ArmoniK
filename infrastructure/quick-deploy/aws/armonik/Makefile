CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=armonik-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/output.json

export TF_DATA_DIR?=$(GENERATED_DIR)
export REGION?=eu-west-3
export PROFILE?=default
export NAMESPACE?=armonik
export TFSTATE_BUCKET_NAME?=armonik-tfstate-$(TAG)

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
		-var 'region=$(REGION)' \
		-var 'profile=$(PROFILE)' \
		-var 'namespace=$(NAMESPACE)' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@echo -n "{\"armonik\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json armonik >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

destroy:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'profile=$(PROFILE)' \
		-var 'namespace=$(NAMESPACE)' \
		-state $(STATE_FILE) \
		-auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
