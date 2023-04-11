CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=eks-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/eks-output.json

export TF_DATA_DIR?=$(GENERATED_DIR)
export SUFFIX?=main
export REGION?=eu-west-3
export PROFILE?=default
export TFSTATE_BUCKET_NAME?=armonik-tfstate-$(SUFFIX)
export VPC_PARAMETERS_FILE?=$(CURRENT_DIR)/../vpc/generated/vpc-output.json
export PUBLIC_ACCESS_EKS?=true
export KUBECONFIG?=$(GENERATED_DIR)/kubeconfig

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
		-var-file $(VPC_PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'suffix=$(SUFFIX)' \
		-var 'profile=$(PROFILE)' \
		-var 'enable_public_eks_access=$(PUBLIC_ACCESS_EKS)' \
		-var 'kubeconfig_file=$(KUBECONFIG)' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@echo -n "{\"eks\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json eks >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

delete:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(VPC_PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'suffix=$(SUFFIX)' \
		-var 'profile=$(PROFILE)' \
		-var 'enable_public_eks_access=$(PUBLIC_ACCESS_EKS)' \
		-var 'kubeconfig_file=$(KUBECONFIG)' \
		-state $(STATE_FILE) \
		-auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
