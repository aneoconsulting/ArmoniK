CURRENT_DIR:=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
INGRESS_CERTIFICATES_DIR=$(GENERATED_DIR)/certificates/ingress
PARAMETERS_FILE?=parameters.tfvars
VERSIONS_FILE?=../../../../versions.tfvars.json
STATE_FILE=armonik-terraform.tfstate

# Randomly generated string that is preserved across calls
RANDOM_PREFIX != [ -e $(GENERATED_DIR)/.prefix ] || { mkdir -p $(GENERATED_DIR) && tr -dc a-z0-9 </dev/urandom | head -c 10 > $(GENERATED_DIR)/.prefix ; } && cat $(GENERATED_DIR)/.prefix

export TF_DATA_DIR?=$(GENERATED_DIR)
export REGION?=eu-west-3
export PROFILE?=default
export NAMESPACE?=armonik
export PREFIX?=armonik-$(RANDOM_PREFIX)
export TFSTATE_BUCKET_NAME?=$(PREFIX)-tfstate

export TF_VAR_region?=$(REGION)
export TF_VAR_profile?=$(PROFILE)
export TF_VAR_namespace?=$(NAMESPACE)
export TF_VAR_prefix?=$(PREFIX)

.PHONY: apply destroy

all: init apply output
deploy: init apply output
destroy: init delete

env:
	@set

bootstrap-deploy: $(YAML_SRC)
	@mkdir -p $(GENERATED_DIR)
	echo $(PREFIX)
	aws cloudformation create-stack --stack-name $(PREFIX) --region $(REGION) --template-body file://$(CURRENT_DIR)/bootstrap.yml --parameters ParameterKey=BucketName,ParameterValue=$(TFSTATE_BUCKET_NAME)
	@echo "Waiting for cloud formation successful deployment"
	@aws cloudformation wait stack-create-complete --stack-name $(PREFIX) --region $(REGION)
	@aws cloudformation describe-stacks --stack-name $(PREFIX) --region $(REGION) --query 'Stacks[0]' > $(GENERATED_DIR)/output.json

bootstrap-destroy:
	aws cloudformation delete-stack --stack-name $(PREFIX) --region $(REGION)
	aws cloudformation wait stack-delete-complete --stack-name $(shell aws cloudformation describe-stacks --region $(REGION) --stack-name $(PREFIX) --query 'Stacks[0].StackId' --output text) --region $(REGION)


init:
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade \
		-backend-config 'bucket=$(TFSTATE_BUCKET_NAME)' \
		-backend-config 'region=$(REGION)' \
		-backend-config 'key=$(STATE_FILE)' \
		-backend-config 'profile=$(PROFILE)' \
		-var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) 	

plan:
	terraform plan -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -out=/dev/null

apply:
	terraform apply -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -auto-approve

refresh:
	terraform refersh -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -auto-approve

delete:
	terraform destroy -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -auto-approve

output:
	terraform output -state=$(STATE_FILE) -json | jq 'map_values(.value)' > $(GENERATED_DIR)/armonik-output.json

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
