export TAG
export REGION?=eu-west-3
export PROFILE?=default

CURRENT_DIR=$(shell pwd)

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

####################################
# 			  AWS VPC 		       #
####################################

deploy-vpc:
	$(MAKE) -C $(CURRENT_DIR)/vpc deploy TAG=$(TAG) REGION=$(REGION) PROFILE=$(PROFILE)

destroy-vpc:
	$(MAKE) -C $(CURRENT_DIR)/vpc destroy TAG=$(TAG) REGION=$(REGION) PROFILE=$(PROFILE)

####################################
# 			   all		           #
####################################

deploy-all: deploy-s3-of-backend deploy-ecr deploy-vpc

destroy-all: destroy-ecr destroy-vpc

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
