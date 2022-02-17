export ARMONIK_SUFFIX?=main
export ARMONIK_REGION?=eu-west-3
export ARMONIK_PROFILE?=default
export ARMONIK_BUCKET_NAME?=armonik-tfstate
export ARMONIK_KUBERNETES_NAMESPACE?=armonik
export TFSTATE_BUCKET_NAME="$(ARMONIK_BUCKET_NAME)-$(ARMONIK_SUFFIX)"

CURRENT_DIR=$(shell pwd)
VPC_PARAMETERS_FILE?=$(CURRENT_DIR)/vpc/generated/vpc-output.json
STORAGE_PARAMETERS_FILE?=$(CURRENT_DIR)/storage/generated/storage-output.json
MONITORING_PARAMETERS_FILE?=$(CURRENT_DIR)/monitoring/generated/monitoring-output.json
EKS_PARAMETERS_FILE?=$(CURRENT_DIR)/eks/generated/eks-output.json

####################################
# KSM and S3 buckets for TF states #
####################################

deploy-s3-of-backend:
	$(MAKE) -C $(CURRENT_DIR)/backend deploy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		BUCKET_NAME=$(ARMONIK_BUCKET_NAME)

destroy-s3-of-backend:
	$(MAKE) -C $(CURRENT_DIR)/backend destroy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		BUCKET_NAME=$(ARMONIK_BUCKET_NAME)

####################################
#            AWS ECR               #
####################################

deploy-ecr:
	$(MAKE) -C $(CURRENT_DIR)/ecr deploy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-ecr:
	$(MAKE) -C $(CURRENT_DIR)/ecr destroy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

clean-ecr:
	$(MAKE) -C $(CURRENT_DIR)/ecr clean

####################################
#             AWS VPC              #
####################################

deploy-vpc:
	$(MAKE) -C $(CURRENT_DIR)/vpc deploy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-vpc:
	$(MAKE) -C $(CURRENT_DIR)/vpc destroy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

clean-vpc:
	$(MAKE) -C $(CURRENT_DIR)/vpc clean

####################################
#             AWS EKS              #
####################################

deploy-eks:
	$(MAKE) -C $(CURRENT_DIR)/eks deploy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-eks:
	$(MAKE) -C $(CURRENT_DIR)/eks destroy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

clean-eks:
	$(MAKE) -C $(CURRENT_DIR)/eks clean

####################################
#       Kubernetes namespace       #
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
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		EKS_PARAMETERS_FILE=$(EKS_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

destroy-aws-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage destroy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		PROFILE=$(ARMONIK_PROFILE) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		EKS_PARAMETERS_FILE=$(EKS_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME)

clean-aws-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage clean

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

clean-monitoring:
	$(MAKE) -C $(CURRENT_DIR)/monitoring clean

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

clean-armonik:
	$(MAKE) -C $(CURRENT_DIR)/armonik clean

####################################
#               All                #
####################################

deploy-all: deploy-ecr deploy-vpc deploy-eks deploy-aws-storage deploy-monitoring deploy-armonik

destroy-all: destroy-armonik destroy-monitoring destroy-aws-storage destroy-eks destroy-vpc destroy-ecr

clean-all: clean-armonik clean-monitoring clean-aws-storage clean-eks clean-vpc clean-ecr
