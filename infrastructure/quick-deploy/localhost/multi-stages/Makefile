export ARMONIK_KUBERNETES_NAMESPACE?=armonik
export ARMONIK_SHARED_HOST_PATH?=$(HOME)/data
export ARMONIK_FILE_STORAGE_FILE?=HostPath
export ARMONIK_FILE_SERVER_IP?=
export KEDA_KUBERNETES_NAMESPACE?=default
export METRICS_SERVER_KUBERNETES_NAMESPACE?=kube-system
export EXTERNAL_DATA_PLANE_NAMESPACE?=external-data-plane
export KEDA=$(shell kubectl get deploy -A -l app=keda-operator --no-headers=true -o name)
export METRICS_SERVER=$(shell kubectl get deploy -A -l k8s-app=metrics-server --no-headers=true -o name)

CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
MODULES_DIR=$(GENERATED_DIR)/infra-modules
TERRAFORM_PLUGINS?=$(GENERATED_DIR)/terraform-plugins
VERSIONS_FILE?=$(shell realpath ../../../../versions.tfvars.json)

####################################
#       Kubernetes namespace       #
####################################

create-namespace:
	@kubectl get namespace $(ARMONIK_KUBERNETES_NAMESPACE)  > /dev/null 2>&1 && echo "namespace : '$(ARMONIK_KUBERNETES_NAMESPACE)' is already created." || kubectl create namespace $(ARMONIK_KUBERNETES_NAMESPACE)
	@kubectl get namespace $(KEDA_KUBERNETES_NAMESPACE)  > /dev/null 2>&1 && echo "namespace : '$(KEDA_KUBERNETES_NAMESPACE)' is already created." || kubectl create namespace $(KEDA_KUBERNETES_NAMESPACE)
	@kubectl get namespace $(METRICS_SERVER_KUBERNETES_NAMESPACE)  > /dev/null 2>&1 &&  echo "namespace : '$(METRICS_SERVER_KUBERNETES_NAMESPACE)' is already created." || kubectl create namespace $(METRICS_SERVER_KUBERNETES_NAMESPACE)
	@kubectl get namespace $(EXTERNAL_DATA_PLANE_NAMESPACE)  > /dev/null 2>&1 &&  echo "namespace : '$(EXTERNAL_DATA_PLANE_NAMESPACE)' is already created." || kubectl create namespace $(EXTERNAL_DATA_PLANE_NAMESPACE)

delete-namespace:
	kubectl delete namespace $(ARMONIK_KUBERNETES_NAMESPACE) || true
	kubectl delete namespace $(KEDA_KUBERNETES_NAMESPACE) || true
	kubectl delete namespace $(METRICS_SERVER_KUBERNETES_NAMESPACE) || true
	kubectl delete namespace $(EXTERNAL_DATA_PLANE_NAMESPACE) || true

####################################
#              KEDA                #
####################################

deploy-keda:
	@if [ "${KEDA}" = "" ]; then\
        $(MAKE) -C $(CURRENT_DIR)/keda deploy \
        NAMESPACE=$(KEDA_KUBERNETES_NAMESPACE) \
        MODULES_DIR=$(MODULES_DIR) \
        TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
        VERSIONS_FILE=$(VERSIONS_FILE);\
    fi

destroy-keda:
	$(MAKE) -C $(CURRENT_DIR)/keda destroy \
	NAMESPACE=$(KEDA_KUBERNETES_NAMESPACE) \
	MODULES_DIR=$(MODULES_DIR) \
	TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
	VERSIONS_FILE=$(VERSIONS_FILE)

clean-keda:
	$(MAKE) -C $(CURRENT_DIR)/keda clean

####################################
#         Metrics server           #
####################################

deploy-metrics-server:
	@if [ "${METRICS_SERVER}" = "" ]; then\
		$(MAKE) -C $(CURRENT_DIR)/metrics-server deploy \
		NAMESPACE=$(METRICS_SERVER_KUBERNETES_NAMESPACE) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE);\
	fi

destroy-metrics-server:
	$(MAKE) -C $(CURRENT_DIR)/metrics-server destroy \
	NAMESPACE=$(METRICS_SERVER_KUBERNETES_NAMESPACE) \
	MODULES_DIR=$(MODULES_DIR) \
	TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
	VERSIONS_FILE=$(VERSIONS_FILE)

clean-metrics-server:
	$(MAKE) -C $(CURRENT_DIR)/metrics-server clean

####################################
#            Storage               #
####################################

deploy-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage deploy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		EXTERNAL_DATA_PLANE_NAMESPACE=$(EXTERNAL_DATA_PLANE_NAMESPACE) \
		SHARED_HOST_PATH=$(ARMONIK_SHARED_HOST_PATH) \
		FILE_STORAGE_FILE=$(ARMONIK_FILE_STORAGE_FILE) \
		FILE_SERVER_IP=$(ARMONIK_FILE_SERVER_IP) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

destroy-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage destroy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		EXTERNAL_DATA_PLANE_NAMESPACE=$(EXTERNAL_DATA_PLANE_NAMESPACE) \
		SHARED_HOST_PATH=$(ARMONIK_SHARED_HOST_PATH) \
		FILE_STORAGE_FILE=$(ARMONIK_FILE_STORAGE_FILE) \
		FILE_SERVER_IP=$(ARMONIK_FILE_SERVER_IP) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

clean-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage clean

####################################
#           Monitoring             #
####################################

deploy-monitoring:
	$(MAKE) -C $(CURRENT_DIR)/monitoring deploy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

destroy-monitoring:
	$(MAKE) -C $(CURRENT_DIR)/monitoring destroy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

clean-monitoring:
	$(MAKE) -C $(CURRENT_DIR)/monitoring clean

####################################
#             ArmoniK              #
####################################

deploy-armonik:
	$(MAKE) -C $(CURRENT_DIR)/armonik deploy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		EXTERNAL_DATA_PLANE_NAMESPACE=$(EXTERNAL_DATA_PLANE_NAMESPACE) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

destroy-armonik:
	$(MAKE) -C $(CURRENT_DIR)/armonik destroy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		EXTERNAL_DATA_PLANE_NAMESPACE=$(EXTERNAL_DATA_PLANE_NAMESPACE) \
		MODULES_DIR=$(MODULES_DIR) \
		TERRAFORM_PLUGINS=$(TERRAFORM_PLUGINS) \
		VERSIONS_FILE=$(VERSIONS_FILE)

clean-armonik:
	$(MAKE) -C $(CURRENT_DIR)/armonik clean

####################################
#             Modules              #
####################################

clean-modules:
	@rm -rf $(GENERATED_DIR)

####################################
#               All                #
####################################

deploy-all: create-namespace deploy-keda deploy-metrics-server deploy-storage deploy-monitoring deploy-armonik

destroy-all: destroy-armonik destroy-monitoring destroy-storage destroy-metrics-server destroy-keda delete-namespace

clean-all: clean-armonik clean-monitoring clean-storage clean-metrics-server clean-keda clean-modules
