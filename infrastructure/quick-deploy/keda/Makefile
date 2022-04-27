export KEDA_KUBERNETES_NAMESPACE?=default
CURRENT_DIR=$(shell pwd)

####################################
#       Kubernetes namespace       #
####################################

create-namespace:
	kubectl create namespace $(KEDA_KUBERNETES_NAMESPACE) || true

delete-namespace:
	kubectl delete namespace $(KEDA_KUBERNETES_NAMESPACE) || true

####################################
#            Storage               #
####################################

deploy-keda:
	$(MAKE) -C $(CURRENT_DIR)/sources deploy \
		NAMESPACE=$(KEDA_KUBERNETES_NAMESPACE)

destroy-keda:
	$(MAKE) -C $(CURRENT_DIR)/sources destroy \
		NAMESPACE=$(KEDA_KUBERNETES_NAMESPACE) \

clean-keda:
	$(MAKE) -C $(CURRENT_DIR)/sources clean

####################################
#               All                #
####################################

deploy-all: create-namespace deploy-keda
destroy-all: destroy-keda
clean-all: clean-keda
