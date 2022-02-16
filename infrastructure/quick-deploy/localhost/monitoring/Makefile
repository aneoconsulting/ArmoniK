CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
BACKEND?=$(GENERATED_DIR)/backend
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=$(BACKEND)/terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/monitoring-output.json

export TF_DATA_DIR?=$(GENERATED_DIR)
export NAMESPACE?=armonik

.PHONY: apply destroy

all: init apply output
deploy: init apply output

init:
	mkdir -p $(GENERATED_DIR)
	terraform init

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var 'namespace=$(NAMESPACE)' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@echo -n "{\"monitoring\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json monitoring >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

destroy:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var 'namespace=$(NAMESPACE)' \
		-state $(STATE_FILE) \
		-auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
