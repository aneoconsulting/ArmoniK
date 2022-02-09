export TF_DATA_DIR?=generated
export TF_LOG=TRACE
export TF_LOG_PATH=generated/terraform.log
export TAG
export REGION?=eu-west-3
export PROFILE?=default

CURRENT_DIR=$(shell pwd)
BACKEND?=generated/backend
PARAMETERS_FILE?=parameters.tfvars
PLAN_FILE=$(BACKEND)/terraform.tfplan
STATE_FILE=$(BACKEND)/terraform.tfstate
OUTPUT_FILE=generated/output.json


.PHONY: plan apply destroy

all: init plan apply output

####################################
# KSM and S3 buckets for TF states #
####################################

deploy-s3-of-backend:
	$(MAKE) -C $(CURRENT_DIR)/backend deploy TAG=$(TAG) REGION=$(REGION)

destroy-s3-of-backend:
	$(MAKE) -C $(CURRENT_DIR)/backend destroy TAG=$(TAG) REGION=$(REGION)

####################################
# 			  AWS ECR 		       #
####################################
deploy-ecr:
	$(MAKE) -C $(CURRENT_DIR)/ecr deploy TAG=$(TAG) REGION=$(REGION) PROFILE=$(PROFILE)

destroy-ecr:
	$(MAKE) -C $(CURRENT_DIR)/ecr destroy TAG=$(TAG) REGION=$(REGION) PROFILE=$(PROFILE)

init:
	mkdir -p generated
	touch generated/terraform.log
	terraform init

plan:
	terraform plan \
		-var-file $(PARAMETERS_FILE) \
		-out $(PLAN_FILE)

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@terraform output -state=$(STATE_FILE) -json > $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(CURRENT_DIR)/$(OUTPUT_FILE)"

destroy:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-state $(STATE_FILE) \
		-auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
