CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
INGRESS_CERTIFICATES_DIR=$(GENERATED_DIR)/certificates/ingress
INGRESS_CLIENT_CERT=$(INGRESS_CERTIFICATES_DIR)/client.crt
INGRESS_CLIENT_KEY=$(INGRESS_CERTIFICATES_DIR)/client.key
INGRESS_PKCS12=$(INGRESS_CERTIFICATES_DIR)/pkcs12.pem
INGRESS_CLIENT_P12=$(INGRESS_CERTIFICATES_DIR)/client.p12
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=armonik-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/armonik-output.json

export TF_DATA_DIR?=$(GENERATED_DIR)
export REGION?=eu-west-3
export PROFILE?=default
export NAMESPACE?=armonik
export SUFFIX?=main
export TFSTATE_BUCKET_NAME?=armonik-tfstate-$(SUFFIX)
export MONITORING_PARAMETERS_FILE?=$(CURRENT_DIR)/../monitoring/generated/monitoring-output.json
export STORAGE_PARAMETERS_FILE?=$(CURRENT_DIR)/../storage/generated/storage-output.json

.PHONY: apply destroy

all: init apply generate-certificate output
deploy: init apply generate-certificate output

init:
	mkdir -p $(GENERATED_DIR)
	terraform init \
		-backend-config 'bucket=$(TFSTATE_BUCKET_NAME)' \
		-backend-config 'region=$(REGION)' \
		-backend-config 'key=$(STATE_FILE)' \
		-backend-config 'profile=$(PROFILE)'

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(MONITORING_PARAMETERS_FILE) \
		-var-file $(STORAGE_PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'profile=$(PROFILE)' \
		-var 'namespace=$(NAMESPACE)' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@echo -n "{\"armonik\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json armonik >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

destroy:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var-file $(MONITORING_PARAMETERS_FILE) \
		-var-file $(STORAGE_PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'profile=$(PROFILE)' \
		-var 'namespace=$(NAMESPACE)' \
		-state $(STATE_FILE) \
		-auto-approve

generate-certificate:
	mkdir -p $(INGRESS_CERTIFICATES_DIR)
	@if [ -f "${INGRESS_CLIENT_CERT}" ] && [ -f "${INGRESS_CLIENT_KEY}" ]; then\
        cat $(INGRESS_CLIENT_CERT) $(INGRESS_CLIENT_KEY) > $(INGRESS_PKCS12);\
		openssl pkcs12 -in $(INGRESS_PKCS12) -export -out $(INGRESS_CLIENT_P12) -password pass:;\
    fi

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
