export TF_DATA_DIR?=generated
export TF_LOG=TRACE
export TF_LOG_PATH=generated/terraform.log

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

CURRENT_DIR=$(shell pwd)
BACKEND?=generated/backend
PARAMETERS_FILE?=parameters.tfvars

PLAN_FILE=$(BACKEND)/terraform.tfplan
STORAGE_PLAN_FILE=$(BACKEND)/storage-terraform.tfplan
MONITORING_PLAN_FILE=$(BACKEND)/monitoring-terraform.tfplan
ARMONIK_PLAN_FILE=$(BACKEND)/armonik-terraform.tfplan

STATE_FILE=$(BACKEND)/terraform.tfstate
STORAGE_STATE_FILE=$(BACKEND)/storage-terraform.tfstate
MONITORING_STATE_FILE=$(BACKEND)/monitoring-terraform.tfstate
ARMONIK_STATE_FILE=$(BACKEND)/armonik-terraform.tfstate

STORAGE_INPUT_FILE?=generated/storage-output.json
MONITORING_INPUT_FILE?=generated/monitoring-output.json

OUTPUT_FILE=generated/output.json
STORAGE_OUTPUT_FILE=generated/storage-output.json
MONITORING_OUTPUT_FILE=generated/monitoring-output.json
ARMONIK_OUTPUT_FILE=generated/armonik-output.json

export STORAGE_PARAMETERS_FILE?=$(CURRENT_DIR)/../aws/storage/generated/output.json


.PHONY: plan apply destroy

all: init apply output

deploy-storage: init storage-plan storage-apply storage-output

destroy-storage: init storage-destroy

deploy-monitoring: init monitoring-plan monitoring-apply monitoring-output

destroy-monitoring: init monitoring-destroy

deploy-armonik: init armonik-plan armonik-apply armonik-output

destroy-armonik: init armonik-destroy

destroy-all: armonik-destroy monitoring-destroy storage-destroy

init:
	mkdir -p generated
	touch generated/terraform.log
	terraform init

plan:
	terraform plan \
		-var-file $(PARAMETERS_FILE) \
		-var 'deploy={"storage":"true","monitoring":"true","armonik":"true"}' \
		-var 'kubernetes_namespaces={"storage":"$(ARMONIK_STORAGE_NAMESPACE)","monitoring":"$(ARMONIK_MONITORING_NAMESPACE)","armonik":"$(ARMONIK_NAMESPACE)"}' \
		-var 'kubernetes_secrets={"activemq_server":"$(ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME)","activemq_client":"$(ARMONIK_ACTIVEMQ_SECRET_NAME)","mongodb_server":"$(ARMONIK_STORAGE_MONGODB_SECRET_NAME)","mongodb_client":"$(ARMONIK_MONGODB_SECRET_NAME)","redis_server":"$(ARMONIK_STORAGE_REDIS_SECRET_NAME)","redis_client":"$(ARMONIK_REDIS_SECRET_NAME)","external_client":"$(ARMONIK_EXTERNAL_REDIS_SECRET_NAME)"}' \
		-out $(PLAN_FILE)

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(STORAGE_PARAMETERS_FILE) \
		-var 'kubernetes_namespaces={"storage":"$(ARMONIK_STORAGE_NAMESPACE)","monitoring":"$(ARMONIK_MONITORING_NAMESPACE)","armonik":"$(ARMONIK_NAMESPACE)"}' \
		-var 'kubernetes_secrets={"activemq_server":"$(ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME)","activemq_client":"$(ARMONIK_ACTIVEMQ_SECRET_NAME)","mongodb_server":"$(ARMONIK_STORAGE_MONGODB_SECRET_NAME)","mongodb_client":"$(ARMONIK_MONGODB_SECRET_NAME)","redis_server":"$(ARMONIK_STORAGE_REDIS_SECRET_NAME)","redis_client":"$(ARMONIK_REDIS_SECRET_NAME)","external_client":"$(ARMONIK_EXTERNAL_REDIS_SECRET_NAME)"}' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@terraform output -state=$(STATE_FILE) -json > $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(CURRENT_DIR)/$(OUTPUT_FILE)"

destroy:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(STORAGE_PARAMETERS_FILE) \
		-var 'kubernetes_namespaces={"storage":"$(ARMONIK_STORAGE_NAMESPACE)","monitoring":"$(ARMONIK_MONITORING_NAMESPACE)","armonik":"$(ARMONIK_NAMESPACE)"}' \
		-var 'kubernetes_secrets={"activemq_server":"$(ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME)","activemq_client":"$(ARMONIK_ACTIVEMQ_SECRET_NAME)","mongodb_server":"$(ARMONIK_STORAGE_MONGODB_SECRET_NAME)","mongodb_client":"$(ARMONIK_MONGODB_SECRET_NAME)","redis_server":"$(ARMONIK_STORAGE_REDIS_SECRET_NAME)","redis_client":"$(ARMONIK_REDIS_SECRET_NAME)","external_client":"$(ARMONIK_EXTERNAL_REDIS_SECRET_NAME)"}' \
		-state $(STATE_FILE) \
		-auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
