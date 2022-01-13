export TF_DATA_DIR?=generated
export TF_LOG=TRACE
export TF_LOG_PATH=generated/terraform.log
BACKEND?=generated/backend
CONFIG_FILE?=parameters.tfvars
PLAN_FILE=$(BACKEND)/terraform.tfplan

.PHONY: plan apply destroy

all: init plan apply

init:
	mkdir -p generated
	touch generated/terraform.log
	terraform init

plan:
	terraform plan -var-file=$(CONFIG_FILE) -out $(PLAN_FILE)

apply:
	terraform apply -var-file=$(CONFIG_FILE) -auto-approve

destroy:
	terraform destroy -var-file=$(CONFIG_FILE) -auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform
