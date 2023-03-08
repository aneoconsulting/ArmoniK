CURRENT_DIR:=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
INGRESS_CERTIFICATES_DIR=$(GENERATED_DIR)/certificates/ingress
PARAMETERS_FILE?=parameters.tfvars
VERSIONS_FILE?=../../../../versions.tfvars.json
STATE_FILE=$(GENERATED_DIR)/armonik-terraform.tfstate

# Randomly generated string that is preserved accross calls

export TF_DATA_DIR?=$(GENERATED_DIR)
export NAMESPACE?=armonik
export PREFIX?=armonik-local

export TF_VAR_namespace?=$(NAMESPACE)
export TF_VAR_prefix?=$(PREFIX)

.PHONY: apply destroy

all: init apply output
deploy: init apply output
destroy: init delete

env:
	@set

init:
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE)

plan:
	terraform plan -state $(STATE_FILE) -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -out=/dev/null

apply:
	terraform apply -state $(STATE_FILE) -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -auto-approve

refresh:
	terraform refresh -state $(STATE_FILE) -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -auto-approve

delete:
	terraform destroy -state $(STATE_FILE) -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -auto-approve

output:
	terraform output -state=$(STATE_FILE) -json | jq 'map_values(.value)' > $(GENERATED_DIR)/armonik-output.json

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
