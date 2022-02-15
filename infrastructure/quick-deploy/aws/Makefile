export ARMONIK_TAG?=main
export ARMONIK_REGION?=eu-west-3
export ARMONIK_PROFILE?=default
export ARMONIK_BUCKET_NAME?=armonik-tfstate
export ARMONIK_KUBERNETES_NAMESPACE?=armonik
export TFSTATE_BUCKET_NAME="$(ARMONIK_BUCKET_NAME)-$(ARMONIK_TAG)"

CURRENT_DIR=$(shell pwd)
VPC_PARAMETERS_FILE?=$(CURRENT_DIR)/vpc/generated/output.json
STORAGE_PARAMETERS_FILE?=$(CURRENT_DIR)/storage/generated/output.json
MONITORING_PARAMETERS_FILE?=$(CURRENT_DIR)/monitoring/generated/output.json

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
#             AWS EKS              #
####################################

deploy-eks:
	$(MAKE) -C $(CURRENT_DIR)/eks deploy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-eks:
	$(MAKE) -C $(CURRENT_DIR)/eks destroy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

####################################
#       Kubernetes namespacs       #
####################################

create-namespace:
	kubectl create namespace $(ARMONIK_KUBERNETES_NAMESPACE) || true

delete-namespace:
	kubectl delete namespace $(ARMONIK_KUBERNETES_NAMESPACE) || true

####################################
#           AWS Storage            #
####################################

deploy-aws-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage deploy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-aws-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage destroy \
		TAG=$(ARMONIK_TAG) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

####################################
#           Monitoring             #
####################################

deploy-monitoring:
	$(MAKE) -C $(CURRENT_DIR)/monitoring deploy \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-monitoring:
	$(MAKE) -C $(CURRENT_DIR)/monitoring destroy \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

####################################
#             ArmoniK              #
####################################

deploy-armonik:
	$(MAKE) -C $(CURRENT_DIR)/armonik deploy \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE) \
		MONITORING_PARAMETERS_FILE=$(MONITORING_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-armonik:
	$(MAKE) -C $(CURRENT_DIR)/armonik destroy \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE) \
		MONITORING_PARAMETERS_FILE=$(MONITORING_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

####################################
#               All                #
####################################

deploy-all:

destroy-all:

clean-all:
	$(MAKE) -C $(CURRENT_DIR)/ecr clean
	$(MAKE) -C $(CURRENT_DIR)/vpc clean
	$(MAKE) -C $(CURRENT_DIR)/eks clean
	$(MAKE) -C $(CURRENT_DIR)/storage clean
	$(MAKE) -C $(CURRENT_DIR)/monitoring clean
	$(MAKE) -C $(CURRENT_DIR)/armonik clean
