export TF_DATA_DIR?=generated
export TF_LOG=TRACE
export TF_LOG_PATH=generated/terraform.log
BACKEND?=generated/backend
CONFIG_FILE?=parameters.tfvars
PLAN_FILE=$(BACKEND)/terraform.tfplan
STATE_FILE=$(BACKEND)/terraform.tfstate
OUTPUT_FILE=generated/output.conf
CURRENT_DIR=$(shell pwd)

.PHONY: plan apply destroy

all: init plan apply

init:
	mkdir -p generated
	touch generated/terraform.log
	terraform init

plan:
	terraform plan -var-file=$(CONFIG_FILE) -out $(PLAN_FILE)

apply:
	terraform apply -var-file=$(CONFIG_FILE) -auto-approve
	$(MAKE) -C . output
	@echo "\nOUTPUT FILE: $(CURRENT_DIR)/$(OUTPUT_FILE)"

output:
	@echo "MONGODB_URL=\"`terraform output -state=$(STATE_FILE) -json mongodb_endpoint_url | jq -r '.url'`\"" > $(OUTPUT_FILE)
	@echo "MONGODB_HOST=\"`terraform output -state=$(STATE_FILE) -json mongodb_endpoint_url | jq -r '.host'`\"" > $(OUTPUT_FILE)
	@echo "MONGODB_PORT=\"`terraform output -state=$(STATE_FILE) -json mongodb_endpoint_url | jq -r '.port'`\"" > $(OUTPUT_FILE)
	@echo "REDIS_URL=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.url'`\"" >> $(OUTPUT_FILE)
	@echo "REDIS_HOST=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.host'`\"" >> $(OUTPUT_FILE)
	@echo "REDIS_PORT=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.port'`\"" >> $(OUTPUT_FILE)
	@echo "ACTIVEMQ_URL=\"`terraform output -state=$(STATE_FILE) -json activemq_endpoint_url | jq -r '.url'`\"" >> $(OUTPUT_FILE)
	@echo "ACTIVEMQ_HOST=\"`terraform output -state=$(STATE_FILE) -json activemq_endpoint_url | jq -r '.host'`\"" >> $(OUTPUT_FILE)
	@echo "ACTIVEMQ_PORT=\"`terraform output -state=$(STATE_FILE) -json activemq_endpoint_url | jq -r '.port'`\"" >> $(OUTPUT_FILE)
	@echo "EXTERNAL_URL=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.url'`\"" >> $(OUTPUT_FILE)
	@echo "EXTERNAL_HOST=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.host'`\"" >> $(OUTPUT_FILE)
	@echo "EXTERNAL_PORT=\"`terraform output -state=$(STATE_FILE) -json redis_endpoint_url | jq -r '.port'`\"" >> $(OUTPUT_FILE)
	@echo "AWS_EBS_ID=\"`terraform output -state=$(STATE_FILE) -json aws_ebs | jq -r '.id'`\"" >> $(OUTPUT_FILE)

destroy:
	terraform destroy -var-file=$(CONFIG_FILE) -auto-approve

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file README-parameters.md --output-mode inject $(CURRENT_DIR)
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/../modules/needed-storage
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/../modules/aws/kms
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/onpremise/mongodb
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/onpremise/redis
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/onpremise/activemq
	terraform-docs markdown table --output-file README.md --output-mode inject $(CURRENT_DIR)/modules/aws/ebs
