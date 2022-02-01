export TF_DATA_DIR?=generated
export TF_LOG=TRACE
export TF_LOG_PATH=generated/terraform.log
BACKEND?=generated/backend
PARAMETERS_FILE?=parameters.tfvars
PLAN_FILE=$(BACKEND)/terraform.tfplan
STATE_FILE=$(BACKEND)/terraform.tfstate
OUTPUT_FILE=generated/output.json
OUTPUT_ENVVARS=generated/output.conf
CURRENT_DIR=$(shell pwd)

.PHONY: plan apply destroy

all: init plan apply

init:
	mkdir -p generated
	touch generated/terraform.log
	terraform init

plan:
	terraform plan -var-file=$(PARAMETERS_FILE) -out $(PLAN_FILE)

apply:
	terraform apply -var-file=$(PARAMETERS_FILE) -auto-approve
	$(MAKE) -C . output
	@echo "\nOUTPUT FILE: $(CURRENT_DIR)/$(OUTPUT_FILE)"

output:
	@echo "MONGODB_URL=\"`terraform output -state=$(STATE_FILE) -json mongodb_endpoint_url | jq -r '.url'`\"" > $(OUTPUT_ENVVARS)
	@echo "MONGODB_HOST=\"`terraform output -state=$(STATE_FILE) -json mongodb_endpoint_url | jq -r '.host'`\"" > $(OUTPUT_ENVVARS)
	@echo "MONGODB_PORT=\"`terraform output -state=$(STATE_FILE) -json mongodb_endpoint_url | jq -r '.port'`\"" > $(OUTPUT_ENVVARS)
	@echo "REDIS_URL=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.url'`\"" >> $(OUTPUT_ENVVARS)
	@echo "REDIS_HOST=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.host'`\"" >> $(OUTPUT_ENVVARS)
	@echo "REDIS_PORT=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.port'`\"" >> $(OUTPUT_ENVVARS)
	@echo "ACTIVEMQ_URL=\"`terraform output -state=$(STATE_FILE) -json activemq_endpoint_url | jq -r '.url'`\"" >> $(OUTPUT_ENVVARS)
	@echo "ACTIVEMQ_HOST=\"`terraform output -state=$(STATE_FILE) -json activemq_endpoint_url | jq -r '.host'`\"" >> $(OUTPUT_ENVVARS)
	@echo "ACTIVEMQ_PORT=\"`terraform output -state=$(STATE_FILE) -json activemq_endpoint_url | jq -r '.port'`\"" >> $(OUTPUT_ENVVARS)
	@echo "EXTERNAL_URL=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.url'`\"" >> $(OUTPUT_ENVVARS)
	@echo "EXTERNAL_HOST=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.host'`\"" >> $(OUTPUT_ENVVARS)
	@echo "EXTERNAL_PORT=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.port'`\"" >> $(OUTPUT_ENVVARS)

destroy:
	terraform destroy -var-file=$(PARAMETERS_FILE) -auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/mongodb
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/redis
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/activemq
