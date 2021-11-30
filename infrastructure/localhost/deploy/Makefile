CONFIG_FILE?=parameters.tfvars

.PHONY: plan apply destroy

all: init plan apply

init:
	terraform init

plan:
	terraform plan -var-file=$(CONFIG_FILE) -out ./backend/terraform.tfplan

apply:
	terraform apply -var-file=$(CONFIG_FILE) -auto-approve

destroy:
	terraform destroy -var-file=$(CONFIG_FILE) -auto-approve
