export TF_DATA_DIR?=generated
export TF_LOG=TRACE
export TF_LOG_PATH=generated/terraform.log
BACKEND?=generated/backend
CONFIG_FILE?=parameters.tfvars

.PHONY: plan apply destroy

all: init plan apply

init:
	terraform init

plan:
	terraform plan -var-file=$(CONFIG_FILE) -out $(BACKEND)/terraform.tfplan

apply:
	terraform apply -var-file=$(CONFIG_FILE) -auto-approve

destroy:
	terraform destroy -var-file=$(CONFIG_FILE) -auto-approve
