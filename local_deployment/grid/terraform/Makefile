export ARMONIK_GENERATED_DIR_PATH

TF_SRCS:=$(wildcard *.tf)

all:

.PHONY: clean apply reset init

init:
	terraform init

apply: $(TF_SRCS) $(GRID_CONFIG)
	terraform apply -var-file $(GRID_CONFIG)

destroy:
	terraform destroy -var-file $(GRID_CONFIG)

validate:
	terraform validate

reset:
	rm -rf .terraform* terraform.tfstate* $(ARMONIK_GENERATED_DIR_PATH)/Agent_config.json $(ARMONIK_GENERATED_DIR_PATH)/Client_config.json
	
clean: reset
	