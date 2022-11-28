CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=metrics-server-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/metrics-server-output.json

export TF_DATA_DIR?=$(GENERATED_DIR)
export REGION?=eu-west-3
export PROFILE?=default
export NAMESPACE?=kube-system
export SUFFIX?=main
export TFSTATE_BUCKET_NAME?=armonik-tfstate-$(SUFFIX)

.PHONY: apply destroy

all: init apply output
deploy: init apply output
destroy: init delete

init:
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade \
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
	@echo -n "{\"metrics_server\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json metrics_server >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

delete:
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
