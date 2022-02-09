export TAG?=main
export REGION?=eu-west-3
export PROFILE?=default
#export TFSTATE_S3_BUCKET?=$(shell aws cloudformation describe-stacks --stack-name $(TAG) --region $(REGION) --query 'Stacks[0].Outputs[0].OutputValue' --output text)
export TFSTATE_S3_BUCKET

CURRENT_DIR=$(shell pwd)

.PHONY: plan apply destroy

all: init plan apply output

####################################
# KSM and S3 buckets for TF states #
####################################

deploy-s3-of-backend:
	$(MAKE) -C $(CURRENT_DIR)/backend deploy TAG=$(TAG) REGION=$(REGION) TFSTATE_S3_BUCKET=$(TFSTATE_S3_BUCKET)

destroy-s3-of-backend:
	$(MAKE) -C $(CURRENT_DIR)/backend destroy TAG=$(TAG) REGION=$(REGION) TFSTATE_S3_BUCKET=$(TFSTATE_S3_BUCKET)

####################################
#            AWS ECR               #
####################################

deploy-ecr:
	$(MAKE) -C $(CURRENT_DIR)/ecr deploy TAG=$(TAG) REGION=$(REGION) PROFILE=$(PROFILE) TFSTATE_S3_BUCKET=$(TFSTATE_S3_BUCKET)

destroy-ecr:
	$(MAKE) -C $(CURRENT_DIR)/ecr destroy TAG=$(TAG) REGION=$(REGION) PROFILE=$(PROFILE) TFSTATE_S3_BUCKET=$(TFSTATE_S3_BUCKET)

####################################
#             AWS VPC              #
####################################

deploy-vpc:
	$(MAKE) -C $(CURRENT_DIR)/vpc deploy TAG=$(TAG) REGION=$(REGION) PROFILE=$(PROFILE) TFSTATE_S3_BUCKET=$(TFSTATE_S3_BUCKET)

destroy-vpc:
	$(MAKE) -C $(CURRENT_DIR)/vpc destroy TAG=$(TAG) REGION=$(REGION) PROFILE=$(PROFILE) TFSTATE_S3_BUCKET=$(TFSTATE_S3_BUCKET)

####################################
#           AWS Storage            #
####################################

deploy-aws-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage deploy TAG=$(TAG) REGION=$(REGION) PROFILE=$(PROFILE) TFSTATE_S3_BUCKET=$(TFSTATE_S3_BUCKET)

destroy-aws-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage destroy TAG=$(TAG) REGION=$(REGION) PROFILE=$(PROFILE) TFSTATE_S3_BUCKET=$(TFSTATE_S3_BUCKET)

####################################
#               All                #
####################################

deploy-all: deploy-s3-of-backend deploy-ecr deploy-vpc deploy-aws-storage

destroy-all: destroy-ecr destroy-vpc destroy-aws-storage

clean-all:
	$(MAKE) -C $(CURRENT_DIR)/vpc clean
	$(MAKE) -C $(CURRENT_DIR)/ecr clean










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
