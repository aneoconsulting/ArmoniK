export TF_DATA_DIR?=generated
export TF_LOG=TRACE
export TF_LOG_PATH=generated/terraform.log
BACKEND?=generated/backend
ARMONIK_PARAMETERS_FILE?=armonik-parameters.tfvars
STORAGE_PARAMETERS_FILE?=storage-parameters.tfvars
MONITORING_PARAMETERS_FILE?=monitoring-parameters.tfvars
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
	terraform plan -var-file=$(ARMONIK_PARAMETERS_FILE) -var-file=$(STORAGE_PARAMETERS_FILE) -var-file=$(MONITORING_PARAMETERS_FILE) -out $(PLAN_FILE)

apply:
	terraform apply -var-file=$(ARMONIK_PARAMETERS_FILE) -var-file=$(STORAGE_PARAMETERS_FILE) -var-file=$(MONITORING_PARAMETERS_FILE) -auto-approve
	$(MAKE) -C . output

output:
	@echo "`terraform output -state=$(STATE_FILE) -json`" > $(OUTPUT_FILE)

destroy:
	terraform destroy -var-file=$(ARMONIK_PARAMETERS_FILE) -var-file=$(STORAGE_PARAMETERS_FILE) -var-file=$(MONITORING_PARAMETERS_FILE) -auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file README-parameters.md --output-mode inject $(CURRENT_DIR)
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/armonik-components
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/monitoring/seq
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/monitoring/grafana
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/monitoring/prometheus
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/monitoring/kubernetes-dashboard
