export TF_DATA_DIR?=generated
export TF_LOG=TRACE
export TF_LOG_PATH=generated/terraform.log
BACKEND?=generated/backend
PARAMETERS_FILE?=parameters.tfvars
PLAN_FILE=$(BACKEND)/terraform.tfplan
STATE_FILE=$(BACKEND)/terraform.tfstate
OUTPUT_FILE=generated/output.json
CURRENT_DIR=$(shell pwd)

export ARMONIK_STORAGE_NAMESPACE?=armonik-storage
export ARMONIK_MONITORING_NAMESPACE?=monitoring-storage
export ARMONIK_NAMESPACE?=armonik

export ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME?=activemq-storage-secret
export ARMONIK_ACTIVEMQ_SECRET_NAME?=activemq-storage-secret
export ARMONIK_STORAGE_MONGODB_SECRET_NAME?=mongodb-storage-secret
export ARMONIK_MONGODB_SECRET_NAME?=mongodb-storage-secret
export ARMONIK_STORAGE_REDIS_SECRET_NAME?=redis-storage-secret
export ARMONIK_REDIS_SECRET_NAME?=redis-storage-secret
export $ARMONIK_EXTERNAL_REDIS_SECRET_NAME?=external-storage-secret


.PHONY: plan apply destroy

all: init plan apply output

init:
	mkdir -p generated
	touch generated/terraform.log
	terraform init

plan:
	terraform plan \
		-var-file $(PARAMETERS_FILE) \
		-var 'kubernetes_namespaces={"storage":"$(ARMONIK_STORAGE_NAMESPACE)","monitoring":"$(ARMONIK_MONITORING_NAMESPACE)","armonik":"$(ARMONIK_NAMESPACE)"}' \
		-var 'kubernetes_secrets={"activemq_server":"$(ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME)","activemq_client":"$(ARMONIK_ACTIVEMQ_SECRET_NAME)","mongodb_server":"$(ARMONIK_STORAGE_MONGODB_SECRET_NAME)","mongodb_client":"$(ARMONIK_MONGODB_SECRET_NAME)","redis_server":"$(ARMONIK_STORAGE_REDIS_SECRET_NAME)","redis_client":"$(ARMONIK_REDIS_SECRET_NAME)","external_client":"$(ARMONIK_EXTERNAL_REDIS_SECRET_NAME)"}' \
		-out $(PLAN_FILE)

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var 'kubernetes_namespaces={"storage":"$(ARMONIK_STORAGE_NAMESPACE)","monitoring":"$(ARMONIK_MONITORING_NAMESPACE)","armonik":"$(ARMONIK_NAMESPACE)"}' \
		-var 'kubernetes_secrets={"activemq_server":"$(ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME)","activemq_client":"$(ARMONIK_ACTIVEMQ_SECRET_NAME)","mongodb_server":"$(ARMONIK_STORAGE_MONGODB_SECRET_NAME)","mongodb_client":"$(ARMONIK_MONGODB_SECRET_NAME)","redis_server":"$(ARMONIK_STORAGE_REDIS_SECRET_NAME)","redis_client":"$(ARMONIK_REDIS_SECRET_NAME)","external_client":"$(ARMONIK_EXTERNAL_REDIS_SECRET_NAME)"}' \
		-auto-approve

output:
	terraform output \
		-state=$(STATE_FILE) \
		-json > $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(CURRENT_DIR)/$(OUTPUT_FILE)"

destroy:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var 'kubernetes_namespaces={"storage":"$(ARMONIK_STORAGE_NAMESPACE)","monitoring":"$(ARMONIK_MONITORING_NAMESPACE)","armonik":"$(ARMONIK_NAMESPACE)"}' \
		-var 'kubernetes_secrets={"activemq_server":"$(ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME)","activemq_client":"$(ARMONIK_ACTIVEMQ_SECRET_NAME)","mongodb_server":"$(ARMONIK_STORAGE_MONGODB_SECRET_NAME)","mongodb_client":"$(ARMONIK_MONGODB_SECRET_NAME)","redis_server":"$(ARMONIK_STORAGE_REDIS_SECRET_NAME)","redis_client":"$(ARMONIK_REDIS_SECRET_NAME)","external_client":"$(ARMONIK_EXTERNAL_REDIS_SECRET_NAME)"}' \
		-auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
