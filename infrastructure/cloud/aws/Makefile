export TF_DATA_DIR?=generated
export TF_LOG=TRACE
export TF_LOG_PATH=generated/terraform.log
BACKEND?=generated/backend
GLOBAL_PARAMETERS_FILE?=global-parameters.tfvars
PLAN_FILE=$(BACKEND)/terraform.tfplan
STATE_FILE=$(BACKEND)/terraform.tfstate
OUTPUT_FILE=generated/output.json
CURRENT_DIR=$(shell pwd)

.PHONY: plan apply destroy

all: init plan apply

init:
	mkdir -p generated
	touch generated/terraform.log
	terraform init

plan:
	terraform plan -var-file=$(GLOBAL_PARAMETERS_FILE) -out $(PLAN_FILE)

apply:
	terraform apply -var-file=$(GLOBAL_PARAMETERS_FILE) -auto-approve
	$(MAKE) -C . output
	@echo "\nOUTPUT FILE: $(CURRENT_DIR)/$(OUTPUT_FILE)"

output:
	@echo "`terraform output -state=$(STATE_FILE) -json`" > $(OUTPUT_FILE)

destroy:
	terraform destroy -var-file=$(GLOBAL_PARAMETERS_FILE) -auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file README-PARAMETERS.md --output-mode inject $(CURRENT_DIR)
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/account
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/kms

