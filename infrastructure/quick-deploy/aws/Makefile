export ARMONIK_TAG?=main
export ARMONIK_REGION?=eu-west-3
export ARMONIK_PROFILE?=default
export ARMONIK_BUCKET_NAME?=armonik-tfstate
export TFSTATE_BUCKET_NAME="$(ARMONIK_BUCKET_NAME)-$(ARMONIK_TAG)"

CURRENT_DIR=$(shell pwd)
VPC_PARAMETERS_FILE?=$(CURRENT_DIR)/vpc/generated/output.json
STORAGE_PARAMETERS_FILE?=$(CURRENT_DIR)/storage/generated/output.json

.PHONY: plan apply destroy

all: init plan apply output

####################################
# KSM and S3 buckets for TF states #
####################################

deploy-s3-of-backend:
	$(MAKE) -C $(CURRENT_DIR)/backend deploy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		BUCKET_NAME=$(ARMONIK_BUCKET_NAME)

destroy-s3-of-backend:
	$(MAKE) -C $(CURRENT_DIR)/backend destroy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		BUCKET_NAME=$(ARMONIK_BUCKET_NAME)

####################################
#            AWS ECR               #
####################################

deploy-ecr:
	$(MAKE) -C $(CURRENT_DIR)/ecr deploy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-ecr:
	$(MAKE) -C $(CURRENT_DIR)/ecr destroy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

####################################
#             AWS VPC              #
####################################

deploy-vpc:
	$(MAKE) -C $(CURRENT_DIR)/vpc deploy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-vpc:
	$(MAKE) -C $(CURRENT_DIR)/vpc destroy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

####################################
#           AWS Storage            #
####################################

deploy-aws-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage deploy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-aws-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage destroy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

####################################
#             AWS EKS              #
####################################

deploy-eks:
	$(MAKE) -C $(CURRENT_DIR)/eks deploy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-eks:
	$(MAKE) -C $(CURRENT_DIR)/eks destroy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

####################################
#               All                #
####################################

deploy-all: deploy-ecr deploy-vpc deploy-aws-storage deploy-eks

destroy-all: destroy-eks destroy-aws-storage destroy-vpc destroy-ecr

clean-all:
	$(MAKE) -C $(CURRENT_DIR)/vpc clean
	$(MAKE) -C $(CURRENT_DIR)/ecr clean
	$(MAKE) -C $(CURRENT_DIR)/storage clean
	$(MAKE) -C $(CURRENT_DIR)/eks clean










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
