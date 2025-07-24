CURRENT_DIR != pwd
GENERATED_DIR=$(CURRENT_DIR)/generated
INGRESS_CERTIFICATES_DIR=$(GENERATED_DIR)/certificates/ingress
PARAMETERS_FILE?=parameters.tfvars
EXTRA_PARAMETERS_FILE?=../../../extra.tfvars.json
VERSIONS_FILE?=../../../versions.tfvars.json
OUTPUT_FILE=$(GENERATED_DIR)/armonik-output.json
MODULES_DIR=$(GENERATED_DIR)/infra-modules
MODULES_SOURCE_DEFAULT != jq -r '.armonik_images.infra[0]' $(VERSIONS_FILE)
MODULES_VERSION_DEFAULT != jq -r '.armonik_versions.infra' $(VERSIONS_FILE)
MODULES_SOURCE?=$(MODULES_SOURCE_DEFAULT)
MODULES_VERSION?=$(MODULES_VERSION_DEFAULT)

export KUBE_CONFIG_PATH?=$(HOME)/.kube/config
export TF_DATA_DIR?=$(GENERATED_DIR)
export TF_PLUGIN_CACHE_DIR?=$(GENERATED_DIR)/terraform-plugins
export NAMESPACE?=armonik
export PREFIX?=armonik-local
export TF_VAR_namespace?=$(NAMESPACE)
export TF_VAR_prefix?=$(PREFIX)

.PHONY: apply destroy

all: get-modules init apply output cliconfig
deploy: get-modules init apply output cliconfig
destroy: init delete

env:
	@set

init:
	mkdir -p $(TF_PLUGIN_CACHE_DIR)
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade -reconfigure -backend-config="secret_suffix=$(PREFIX)" -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE)

plan:
	terraform plan -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE)  -out=/dev/null

apply:
	terraform apply -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -auto-approve

refresh:
	terraform refresh -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE)

delete:
	terraform destroy -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE) -auto-approve

console:
	terraform console -var-file=$(VERSIONS_FILE) -var-file=$(PARAMETERS_FILE) -var-file=$(EXTRA_PARAMETERS_FILE)

state-pull:
	terraform state pull

import-error:
	@if ! terraform state push errored.tfstate 2>/dev/null; then\
		terraform state push errored.tfstate 2>&1 | sed -n 's/^.*ID:\s*\(\w*\)\s*/\1/p' | xargs terraform force-unlock -force || true;\
		terraform state push errored.tfstate;\
	fi
	@echo terraform state push errored.tfstate
	rm -f errored.tfstate

output:
	@terraform output -json | jq 'map_values(.value)' > $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

get-modules:
	@if [ -d $(MODULES_DIR) ]; then \
		if [ -n "$(MODULES_VERSION)" ]; then \
			git -C $(MODULES_DIR) fetch --depth 1 origin tag $(MODULES_VERSION) || \
			git -C $(MODULES_DIR) fetch --depth 1 origin $(MODULES_VERSION) ; \
			git -C $(MODULES_DIR) -c advice.detachedHead=false switch -d $(MODULES_VERSION); \
		fi \
	else \
		if [ -n "$(MODULES_VERSION)" ]; then \
			git -c advice.detachedHead=false clone --branch $(MODULES_VERSION) --depth 1 $(MODULES_SOURCE) $(MODULES_DIR); \
			git -C $(MODULES_DIR) config --replace-all remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" ; \
		else \
			echo "MODULES_DIR does not exist and MODULES_VERSION is empty" >&2; \
			exit 1; \
		fi \
	fi

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)

cliconfig:
	@echo "Run to point your ArmoniK CLI to this deployment:"
	@echo "------------------------------"
	@echo "export AKCONFIG=$(GENERATED_DIR)/armonik-cli.yaml"
