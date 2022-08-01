export ARMONIK_KUBERNETES_NAMESPACE?=armonik
export ARMONIK_SHARED_HOST_PATH?=$(HOME)/data
export ARMONIK_FILE_STORAGE_FILE?=HostPath
export ARMONIK_FILE_SERVER_IP?=
export KEDA_KUBERNETES_NAMESPACE?=default
export METRICS_SERVER_KUBERNETES_NAMESPACE?=kube-system
export KEDA=$(shell kubectl get deploy -A -l app=keda-operator --no-headers=true -o name)
export METRICS_SERVER=$(shell kubectl get deploy -A -l k8s-app=metrics-server --no-headers=true -o name)

CURRENT_DIR=$(shell pwd)
STORAGE_PARAMETERS_FILE?=$(CURRENT_DIR)/storage/generated/storage-output.json
MONITORING_PARAMETERS_FILE?=$(CURRENT_DIR)/monitoring/generated/monitoring-output.json

####################################
#       Kubernetes namespace       #
####################################

create-namespace:
	kubectl create namespace $(ARMONIK_KUBERNETES_NAMESPACE) || true
	kubectl create namespace $(KEDA_KUBERNETES_NAMESPACE) || true
	kubectl create namespace $(METRICS_SERVER_KUBERNETES_NAMESPACE) || true

delete-namespace:
	kubectl delete namespace $(ARMONIK_KUBERNETES_NAMESPACE) || true
	kubectl delete namespace $(KEDA_KUBERNETES_NAMESPACE) || true
	kubectl delete namespace $(METRICS_SERVER_KUBERNETES_NAMESPACE) || true

####################################
#              KEDA                #
####################################

deploy-keda:
	@if [ "${KEDA}" = "" ]; then\
        $(MAKE) -C $(CURRENT_DIR)/keda deploy NAMESPACE=$(KEDA_KUBERNETES_NAMESPACE);\
    fi

destroy-keda:
	$(MAKE) -C $(CURRENT_DIR)/keda destroy NAMESPACE=$(KEDA_KUBERNETES_NAMESPACE)

clean-keda:
	$(MAKE) -C $(CURRENT_DIR)/keda clean

####################################
#         Metrics server           #
####################################

deploy-metrics-server:
	@if [ "${METRICS_SERVER}" = "" ]; then\
		$(MAKE) -C $(CURRENT_DIR)/metrics-server deploy NAMESPACE=$(METRICS_SERVER_KUBERNETES_NAMESPACE);\
	fi

destroy-metrics-server:
	$(MAKE) -C $(CURRENT_DIR)/metrics-server destroy NAMESPACE=$(METRICS_SERVER_KUBERNETES_NAMESPACE)

clean-metrics-server:
	$(MAKE) -C $(CURRENT_DIR)/metrics-server clean

####################################
#            Storage               #
####################################

deploy-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage deploy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		SHARED_HOST_PATH=$(ARMONIK_SHARED_HOST_PATH) \
		FILE_STORAGE_FILE=$(ARMONIK_FILE_STORAGE_FILE) \
		FILE_SERVER_IP=$(ARMONIK_FILE_SERVER_IP)

destroy-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage destroy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		SHARED_HOST_PATH=$(ARMONIK_SHARED_HOST_PATH) \
		FILE_STORAGE_FILE=$(ARMONIK_FILE_STORAGE_FILE) \
		FILE_SERVER_IP=$(ARMONIK_FILE_SERVER_IP)

clean-storage:
	$(MAKE) -C $(CURRENT_DIR)/storage clean

####################################
#           Monitoring             #
####################################

deploy-monitoring:
	$(MAKE) -C $(CURRENT_DIR)/monitoring deploy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE)

destroy-monitoring:
	$(MAKE) -C $(CURRENT_DIR)/monitoring destroy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE)

clean-monitoring:
	$(MAKE) -C $(CURRENT_DIR)/monitoring clean

####################################
#             ArmoniK              #
####################################

deploy-armonik:
	$(MAKE) -C $(CURRENT_DIR)/armonik deploy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE) \
		MONITORING_PARAMETERS_FILE=$(MONITORING_PARAMETERS_FILE)

destroy-armonik:
	$(MAKE) -C $(CURRENT_DIR)/armonik destroy \
		NAMESPACE=$(ARMONIK_KUBERNETES_NAMESPACE) \
		STORAGE_PARAMETERS_FILE=$(STORAGE_PARAMETERS_FILE) \
		MONITORING_PARAMETERS_FILE=$(MONITORING_PARAMETERS_FILE)

clean-armonik:
	$(MAKE) -C $(CURRENT_DIR)/armonik clean

####################################
#               All                #
####################################

deploy-all: create-namespace deploy-keda deploy-metrics-server deploy-storage deploy-monitoring deploy-armonik

destroy-all: destroy-armonik destroy-monitoring destroy-storage destroy-metrics-server destroy-keda

clean-all: clean-armonik clean-monitoring clean-storage clean-metrics-server clean-keda
