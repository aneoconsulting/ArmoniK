CURRENT_DIR:=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
INGRESS_CERTIFICATES_DIR=$(GENERATED_DIR)/certificates/ingress
PARAMETERS_FILE?=parameters.tfvars
EXTRA_PARAMETERS_FILE?=../../../../extra.tfvars.json
VERSIONS_FILE?=../../../../versions.tfvars.json
STATE_FILE=armonik-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/armonik-output.json
MODULES_DIR=$(GENERATED_DIR)/infra-modules
MODULES_SOURCE=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_images.infra[0]')
MODULES_VERSION=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_versions.infra')

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

all: get-modules init apply output kubeconfig
deploy: get-modules init apply output kubeconfig
destroy: init delete

env:
	@set

bootstrap-deploy: $(YAML_SRC)
	@mkdir -p $(GENERATED_DIR)
	@echo $(PREFIX)
	aws --profile $(PROFILE) cloudformation create-stack --stack-name $(PREFIX) --region $(REGION) --template-body file://$(CURRENT_DIR)/bootstrap.yml --parameters ParameterKey=BucketName,ParameterValue=$(TFSTATE_BUCKET_NAME)
	@echo "Waiting for cloud formation successful deployment"
	@aws --profile $(PROFILE) cloudformation wait stack-create-complete --stack-name $(PREFIX) --region $(REGION)
	@aws --profile $(PROFILE) cloudformation describe-stacks --stack-name $(PREFIX) --region $(REGION) --query 'Stacks[0]' > $(GENERATED_DIR)/output.json

bootstrap-destroy:
	aws --profile $(PROFILE) --region $(REGION) s3api delete-objects \
		--bucket "${TFSTATE_BUCKET_NAME}" \
		--delete "`aws s3api list-object-versions \
		--bucket "${TFSTATE_BUCKET_NAME}" \
		--output=json \
		--query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}'`"
	aws --profile $(PROFILE) cloudformation delete-stack --stack-name $(PREFIX) --region $(REGION)
	aws --profile $(PROFILE) cloudformation wait stack-delete-complete --stack-name $(shell aws cloudformation describe-stacks --region $(REGION) --stack-name $(PREFIX) --query 'Stacks[0].StackId' --output text) --region $(REGION)


init:
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade -reconfigure \
		-backend-config 'bucket=$(TFSTATE_BUCKET_NAME)' \
		-backend-config 'region=$(REGION)' \
		-backend-config 'key=$(STATE_FILE)' \
		-backend-config 'profile=$(PROFILE)' \
		-var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE)	

plan:
	terraform plan -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -out=/dev/null

apply:
	terraform apply -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -auto-approve

refresh:
	terraform refresh -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE)

delete:
	terraform destroy -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -auto-approve

output:
	@terraform output -state=$(STATE_FILE) -json | jq 'map_values(.value)' > $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

kubeconfig:
	@echo "Execute the following commands:"
	@echo "------------------------------"
	@echo "export KUBECONFIG=$(shell cat $(GENERATED_DIR)/armonik-output.json | jq -r '.eks.kubeconfig_file')"

get-modules:
	@if [ -d $(MODULES_DIR) ]; then\
		git -C $(MODULES_DIR) fetch --all --tags;\
		git -C $(MODULES_DIR) -c advice.detachedHead=false checkout $(MODULES_VERSION);\
		git -C $(MODULES_DIR) pull origin $(MODULES_VERSION);\
    else \
      	git -c advice.detachedHead=false clone --branch $(MODULES_VERSION) $(MODULES_SOURCE) $(MODULES_DIR);\
    fi

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
