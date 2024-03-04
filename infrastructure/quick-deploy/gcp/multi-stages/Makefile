export ARMONIK_SUFFIX?=main
export ARMONIK_GCP_PROJECT_ID?=$(shell gcloud config get-value project)
export ARMONIK_REGION?=europe-west1
export ARMONIK_BUCKET_NAME?=armonik-tfstate
export ARMONIK_KUBERNETES_NAMESPACE?=armonik
export KEDA_KUBERNETES_NAMESPACE?=default
export TFSTATE_BUCKET_NAME=$(ARMONIK_BUCKET_NAME)-$(ARMONIK_SUFFIX)
export PUBLIC_ACCESS_GKE?=true

CURRENT_DIR=$(shell pwd)
VPC_PARAMETERS_FILE?=$(CURRENT_DIR)/vpc/generated/vpc-output.json
GAR_PARAMETERS_FILE?=$(CURRENT_DIR)/gar/generated/gar-output.json
GKE_PARAMETERS_FILE?=$(CURRENT_DIR)/gke/generated/gke-output.json
STORAGE_PARAMETERS_FILE?=$(CURRENT_DIR)/storage/generated/storage-output.json
MONITORING_PARAMETERS_FILE?=$(CURRENT_DIR)/monitoring/generated/monitoring-output.json
KUBECONFIG?=$(CURRENT_DIR)/gke/generated/kubeconfig
GENERATED_DIR=$(CURRENT_DIR)/generated
MODULES_DIR=$(GENERATED_DIR)/infra-modules
TERRAFORM_PLUGINS?=$(GENERATED_DIR)/terraform-plugins
VERSIONS_FILE?=$(shell realpath ../../../../versions.tfvars.json)
SHELL := /bin/bash

deprecated:
	@echo "Multi-stage deployment is deprecated. Please use the all-in-one deployment."

####################################
#             TFSTATE Bucket       #
####################################
deploy-gcs-of-backend: deprecated
	@if [[ $${TFSTATE_BUCKET_NAME} =~ ^[a-z0-9]([-a-z0-9_]*[a-z0-9])?$$ && $${#TFSTATE_BUCKET_NAME} -ge 3 && $${#TFSTATE_BUCKET_NAME} -le 63 && ! $${TFSTATE_BUCKET_NAME} =~ -- && ! $${TFSTATE_BUCKET_NAME} =~ ^- && ! $${TFSTATE_BUCKET_NAME} =~ -$$ ]]; then \
		echo "TFSTATE bucket Name : ${TFSTATE_BUCKET_NAME} is valid"; \
	else \
		echo -e "\e[91mError : Invalid TFSTATE bucket Name : '${TFSTATE_BUCKET_NAME}' ref: https://cloud.google.com/storage/docs/buckets#naming \e[0m"; \
		exit 1; \
	fi; \

	@if gsutil ls -b gs://${TFSTATE_BUCKET_NAME} > /dev/null 2>&1; then \
		echo "The bucket : ${TFSTATE_BUCKET_NAME} already exists."; \
	else \
		if gsutil mb -l ${ARMONIK_REGION} gs://${TFSTATE_BUCKET_NAME}; then \
			echo "The bucket ${TFSTATE_BUCKET_NAME} has been successfuly created."; \
		else \
			echo -e "\e[91mError : TFSTATE bucket Name : '${TFSTATE_BUCKET_NAME}' has NOT been created. \e[0m"; \
			gsutil ls -b gs://${TFSTATE_BUCKET_NAME}; \
			exit 1; \
		fi; \
	fi

destroy-gcs-of-backend: deprecated
	@if gsutil ls -b gs://${TFSTATE_BUCKET_NAME} > /dev/null 2>&1; then \
		if gsutil rm -r gs://${TFSTATE_BUCKET_NAME}; then \
		echo "The bucket : ${TFSTATE_BUCKET_NAME} has been deleted."; \
		else \
			echo -e "\e[91mError : The bucket : ${TFSTATE_BUCKET_NAME} has NOT been deleted. \e[0m"; \
			gsutil ls -b gs://${TFSTATE_BUCKET_NAME}; \
			exit 1; \
		fi \
	else \
		echo "The bucket ${TFSTATE_BUCKET_NAME} is not in your bucket list."; \
	fi 

####################################
#             GCP VPC              #
####################################

deploy-vpc: deprecated
	$(MAKE) -C $(CURRENT_DIR)/vpc deploy \
		GCP_PROJECT_ID=$(ARMONIK_GCP_PROJECT_ID) \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

destroy-vpc: deprecated
	$(MAKE) -C $(CURRENT_DIR)/vpc destroy \
		GCP_PROJECT_ID=$(ARMONIK_GCP_PROJECT_ID) \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

clean-vpc: deprecated
	$(MAKE) -C $(CURRENT_DIR)/vpc clean

####################################
#            GCP GAR               #
####################################

deploy-gar: deprecated
	$(MAKE) -C $(CURRENT_DIR)/gar deploy \
		GCP_PROJECT_ID=$(ARMONIK_GCP_PROJECT_ID) \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

destroy-gar: deprecated
	$(MAKE) -C $(CURRENT_DIR)/gar destroy \
		GCP_PROJECT_ID=$(ARMONIK_GCP_PROJECT_ID) \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

clean-gar: deprecated
	$(MAKE) -C $(CURRENT_DIR)/gar clean

####################################
#             GCP GKE              #
####################################

deploy-gke: deprecated
	$(MAKE) -C $(CURRENT_DIR)/gke deploy \
		GCP_PROJECT_ID=$(ARMONIK_GCP_PROJECT_ID) \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		PUBLIC_ACCESS_GKE=$(PUBLIC_ACCESS_GKE) \
		KUBECONFIG=$(KUBECONFIG) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

destroy-gke: deprecated
	$(MAKE) -C $(CURRENT_DIR)/gke destroy \
		GCP_PROJECT_ID=$(ARMONIK_GCP_PROJECT_ID) \
		SUFFIX=$(ARMONIK_SUFFIX) \
		REGION=$(ARMONIK_REGION) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		PUBLIC_ACCESS_GKE=$(PUBLIC_ACCESS_GKE) \
		KUBECONFIG=$(KUBECONFIG) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

clean-gke: deprecated
	$(MAKE) -C $(CURRENT_DIR)/gke clean

####################################
#       Kubernetes namespace       #
####################################

create-namespace: deprecated
	@KEDA=$(shell kubectl --kubeconfig $(KUBECONFIG) get deploy -A -l app=keda-operator --no-headers=true -o name)
	@METRICS_SERVER=$(shell kubectl --kubeconfig $(KUBECONFIG) get deploy -A -l k8s-app=metrics-server --no-headers=true -o name)
	@kubectl --kubeconfig $(KUBECONFIG) get namespace $(ARMONIK_KUBERNETES_NAMESPACE)  > /dev/null 2>&1 && echo "namespace : '$(ARMONIK_KUBERNETES_NAMESPACE)' is already created." || kubectl --kubeconfig $(KUBECONFIG) create namespace $(ARMONIK_KUBERNETES_NAMESPACE)
	@kubectl --kubeconfig $(KUBECONFIG) get namespace $(KEDA_KUBERNETES_NAMESPACE)  > /dev/null 2>&1 && echo "namespace : '$(KEDA_KUBERNETES_NAMESPACE)' is already created." || kubectl --kubeconfig $(KUBECONFIG) create namespace $(KEDA_KUBERNETES_NAMESPACE)

delete-namespace: deprecated
	kubectl --kubeconfig $(KUBECONFIG) delete namespace $(ARMONIK_KUBERNETES_NAMESPACE) || true
	kubectl --kubeconfig $(KUBECONFIG) delete namespace $(KEDA_KUBERNETES_NAMESPACE) || true

####################################
#              KEDA                #
####################################

deploy-keda: deprecated
	@if [ "${KEDA}" = "" ]; then\
        $(MAKE) -C $(CURRENT_DIR)/keda deploy \
        	GKE_PARAMETERS_FILE=$(GKE_PARAMETERS_FILE) \
        	GAR_PARAMETERS_FILE=$(GAR_PARAMETERS_FILE) \
        	NAMESPACE=$(KEDA_KUBERNETES_NAMESPACE) \
        	SUFFIX=$(ARMONIK_SUFFIX) \
        	TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
        	MODULES_DIR=$(MODULES_DIR) \
        	TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
        	VERSIONS_FILE=$(VERSIONS_FILE);\
    fi

destroy-keda: deprecated
	$(MAKE) -C $(CURRENT_DIR)/keda destroy \
		GKE_PARAMETERS_FILE=$(GKE_PARAMETERS_FILE) \
		GAR_PARAMETERS_FILE=$(GAR_PARAMETERS_FILE) \
		NAMESPACE=$(KEDA_KUBERNETES_NAMESPACE) \
		SUFFIX=$(ARMONIK_SUFFIX) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

clean-keda: deprecated
	$(MAKE) -C $(CURRENT_DIR)/keda clean

####################################
#           GCP Storage            #
####################################

deploy-storage: deprecated
	$(MAKE) -C $(CURRENT_DIR)/storage deploy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		GCP_PROJECT_ID=$(ARMONIK_GCP_PROJECT_ID) \
		REGION=$(ARMONIK_REGION) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		GKE_PARAMETERS_FILE=$(GKE_PARAMETERS_FILE) \
		GAR_PARAMETERS_FILE=$(GAR_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

destroy-storage: deprecated
	$(MAKE) -C $(CURRENT_DIR)/storage destroy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		GCP_PROJECT_ID=$(ARMONIK_GCP_PROJECT_ID) \
		REGION=$(ARMONIK_REGION) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		VPC_PARAMETERS_FILE=$(VPC_PARAMETERS_FILE) \
		GKE_PARAMETERS_FILE=$(GKE_PARAMETERS_FILE) \
		GAR_PARAMETERS_FILE=$(GAR_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

clean-storage: deprecated
	$(MAKE) -C $(CURRENT_DIR)/storage clean

####################################
#           Monitoring             #
####################################

deploy-monitoring: deprecated
	$(MAKE) -C $(CURRENT_DIR)/monitoring deploy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE) \
		GKE_PARAMETERS_FILE=$(GKE_PARAMETERS_FILE) \
		GAR_PARAMETERS_FILE=$(GAR_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

destroy-monitoring: deprecated
	$(MAKE) -C $(CURRENT_DIR)/monitoring destroy \
		SUFFIX=$(ARMONIK_SUFFIX) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE) \
		GKE_PARAMETERS_FILE=$(GKE_PARAMETERS_FILE) \
		GAR_PARAMETERS_FILE=$(GAR_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

clean-monitoring: deprecated
	$(MAKE) -C $(CURRENT_DIR)/monitoring clean

####################################
#             ArmoniK              #
####################################

deploy-armonik: deprecated
	$(MAKE) -C $(CURRENT_DIR)/armonik deploy \
		GCP_PROJECT_ID=$(ARMONIK_GCP_PROJECT_ID) \
		SUFFIX=$(ARMONIK_SUFFIX) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE) \
		MONITORING_PARAMETERS_FILE=$(MONITORING_PARAMETERS_FILE) \
		GKE_PARAMETERS_FILE=$(GKE_PARAMETERS_FILE) \
		GAR_PARAMETERS_FILE=$(GAR_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

destroy-armonik: deprecated
	$(MAKE) -C $(CURRENT_DIR)/armonik destroy \
		GCP_PROJECT_ID=$(ARMONIK_GCP_PROJECT_ID) \
		SUFFIX=$(ARMONIK_SUFFIX) \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE) \
		MONITORING_PARAMETERS_FILE=$(MONITORING_PARAMETERS_FILE) \
		GKE_PARAMETERS_FILE=$(GKE_PARAMETERS_FILE) \
		GAR_PARAMETERS_FILE=$(GAR_PARAMETERS_FILE) \
		TFSTATE_BUCKET_NAME=$(TFSTATE_BUCKET_NAME) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

clean-armonik: deprecated
	$(MAKE) -C $(CURRENT_DIR)/armonik clean

####################################
#          KUBECONFIG              #
####################################

kubeconfig: deprecated
	@echo "Execute the following commands:"
	@echo "------------------------------"
	@echo "export KUBECONFIG=$(shell cat $(GKE_PARAMETERS_FILE) | jq -r '.gke.kubeconfig_path')"

####################################
#             Modules              #
####################################

clean-modules: deprecated
	@rm -rf $(GENERATED_DIR)

####################################
#               All                #
####################################

deploy-all: deploy-vpc deploy-gar deploy-gke create-namespace deploy-keda deploy-storage deploy-monitoring deploy-armonik kubeconfig

destroy-all: destroy-armonik destroy-monitoring destroy-storage destroy-keda delete-namespace destroy-gke destroy-gar destroy-vpc

clean-all: clean-armonik clean-monitoring clean-storage clean-keda clean-gke clean-gar clean-vpc clean-modules
