CURRENT_DIR := $(CURDIR)
GENERATED_DIR = $(CURRENT_DIR)/generated
TF_DIR = $(CURRENT_DIR)/terraform
PARAMETERS_FILE ?= $(CURRENT_DIR)/parameters.tfvars
STATE_FILE = armonik-terraform.tfstate
OUTPUT_FILE = $(GENERATED_DIR)/armonik-output.json
export KUBECONFIG ?= $(GENERATED_DIR)/kubeconfig

# Randomly generated string that is preserved across calls
RANDOM_PREFIX := $(shell [ -e $(GENERATED_DIR)/.prefix ] || { mkdir -p $(GENERATED_DIR) && LC_ALL=C tr -dc a-z0-9 </dev/urandom | head -c 10 > $(GENERATED_DIR)/.prefix ; } && cat $(GENERATED_DIR)/.prefix)

# Same layout as the other quick deploys, whose generated/ subfolders ArmoniK.Action.Deploy excludes
export TF_DATA_DIR ?= $(GENERATED_DIR)
export TF_PLUGIN_CACHE_DIR ?= $(GENERATED_DIR)/terraform-plugins
export REGION ?= eu-west-3
# help needs no AWS profile
ifeq ($(filter help,$(MAKECMDGOALS)),)
export PROFILE ?= $(or $(AWS_PROFILE),$(error AWS_PROFILE is not set, log in with your AWS CLI profile first))
endif
export NAMESPACE ?= armonik
export PREFIX ?= armonik-$(RANDOM_PREFIX)
# Existing S3 bucket holding the Terraform state (backend.tfbackend.example); the key is per PREFIX
BACKEND_CONFIG ?= $(CURRENT_DIR)/backend.tfbackend
KUBIE_DIR ?= $(HOME)/.kube

export AWS_PROFILE := $(PROFILE)
export AWS_REGION = $(REGION)
export TF_VAR_region = $(REGION)
export TF_VAR_profile = $(PROFILE)
export TF_VAR_namespace = $(NAMESPACE)
export TF_VAR_prefix = $(PREFIX)

# Upstream credentials of the ECR pull-through cache (Docker Hub and GitHub tokens), write-only in Terraform:
# from the environment when set (first deploy, rotation), else read back from the secrets of a previous apply
REGISTRY_SECRET = aws secretsmanager get-secret-value --secret-id ecr-pullthroughcache/$(PREFIX)-$(1) \
	--query SecretString --output text | jq -e '{username, access_token: .accessToken}'
REGISTRY_CREDENTIALS = \
	if [ -n "$$DOCKER_HUB_USERNAME$$DOCKER_HUB_TOKEN$$GITHUB_USERNAME$$GITHUB_TOKEN" ]; then \
		jq -n \
			--arg dhu "$${DOCKER_HUB_USERNAME:?DOCKER_HUB_USERNAME is required}" \
			--arg dht "$${DOCKER_HUB_TOKEN:?DOCKER_HUB_TOKEN is required}" \
			--arg ghu "$${GITHUB_USERNAME:?GITHUB_USERNAME is required}" \
			--arg ght "$${GITHUB_TOKEN:?GITHUB_TOKEN is required}" \
			'{docker_hub: {username: $$dhu, access_token: $$dht}, github: {username: $$ghu, access_token: $$ght}}'; \
	else \
		dh="$$($(call REGISTRY_SECRET,docker-hub))" && gh="$$($(call REGISTRY_SECRET,github))" \
			|| { echo "No registry credentials: export DOCKER_HUB_USERNAME, DOCKER_HUB_TOKEN, GITHUB_USERNAME and GITHUB_TOKEN" >&2; exit 1; }; \
		jq -n --argjson dh "$$dh" --argjson gh "$$gh" '{docker_hub: $$dh, github: $$gh}'; \
	fi
TF_CREDENTIALS = creds="$$($(REGISTRY_CREDENTIALS))" && TF_VAR_registry_credentials="$$creds"

TERRAFORM = terraform -chdir=$(TF_DIR)
TF_VARS = -var-file=$(PARAMETERS_FILE)
HELMFILE = helmfile --file $(CURRENT_DIR)/helmfile.yaml.gotmpl

.PHONY: all help deploy destroy delete get-modules init plan apply output \
	kubeconfig kubie registry-login charts charts-diff charts-destroy check-images cliconfig clean-ecr clean env

all: deploy

help: ## Show this help
	@echo "Usage: make <target> [VARIABLE=value...]"
	@echo
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "Variables:"
	@echo "  PROFILE          AWS CLI profile (default: AWS_PROFILE, required)"
	@echo "  REGION           AWS region (default: eu-west-3)"
	@echo "  PREFIX           Name prefix of every resource (default: armonik-<random>, kept in generated/.prefix)"
	@echo "  NAMESPACE        Namespace of the ArmoniK release (default: armonik)"
	@echo "  BACKEND_CONFIG   Terraform backend file with the state bucket (default: backend.tfbackend)"
	@echo "  PARAMETERS_FILE  Terraform variables (default: parameters.tfvars)"
	@echo "  KUBIE_DIR        Directory kubie reads kubeconfigs from (default: ~/.kube)"
	@echo
	@echo "Environment, for plan, apply and delete:"
	@echo "  DOCKER_HUB_USERNAME, DOCKER_HUB_TOKEN, GITHUB_USERNAME, GITHUB_TOKEN"
	@echo "                   Upstream credentials of the ECR pull-through cache, for the first deploy or a"
	@echo "                   rotation; read back from Secrets Manager otherwise"
	@echo
	@echo "Charts, for charts, charts-diff and check-images:"
	@echo "  ARMONIK_CHART_VERSION  Published ArmoniK charts version (default: pinned in helmfile.yaml.gotmpl)"
	@echo "  ARMONIK_CHARTS_DIR     Local ArmoniK.Infra/charts checkout, instead of the published charts"

deploy: init apply output kubeconfig registry-login charts cliconfig ## Deploy everything: infrastructure, then charts
destroy: init output kubeconfig delete ## Destroy everything: charts, infrastructure, cache repositories

env: ## Print the environment make runs with
	@set

# Kept for ArmoniK.Action.Deploy: this deployment uses no ArmoniK.Infra Terraform module
get-modules: ## No-op, kept for ArmoniK.Action.Deploy
	@true

init: ## Initialize Terraform with the state backend
	@mkdir -p $(TF_PLUGIN_CACHE_DIR)
	@[ -f "$(BACKEND_CONFIG)" ] || { echo "$(BACKEND_CONFIG) not found: copy backend.tfbackend.example and set the state bucket" >&2; exit 1; }
	$(TERRAFORM) init -upgrade -reconfigure \
		-backend-config '$(BACKEND_CONFIG)' \
		-backend-config 'key=$(PREFIX)/$(STATE_FILE)'

plan: ## Terraform plan
	$(TF_CREDENTIALS) $(TERRAFORM) plan $(TF_VARS)

apply: ## Terraform apply
	$(TF_CREDENTIALS) $(TERRAFORM) apply $(TF_VARS) -auto-approve

output: ## Write the Terraform outputs to generated/armonik-output.json
	@mkdir -p $(GENERATED_DIR)
	@$(TERRAFORM) output -json | jq 'map_values(.value)' > $(OUTPUT_FILE)
	@echo "OUTPUT FILE: $(OUTPUT_FILE)"

kubeconfig: ## Write the cluster kubeconfig to generated/kubeconfig
	aws eks update-kubeconfig --name "$$(jq -r .eks.name $(OUTPUT_FILE))" --kubeconfig $(KUBECONFIG)
	@echo "export KUBECONFIG=$(KUBECONFIG)"

# kubie picks up ~/.kube/*.yaml; the profile is embedded so the context works from any shell
kubie: ## Write the cluster kubeconfig to ~/.kube/<cluster>.yaml, for kubie
	@name="$$(jq -r .eks.name $(OUTPUT_FILE))"; \
	aws eks update-kubeconfig --name "$$name" --alias "$$name" --profile $(PROFILE) --kubeconfig $(KUBIE_DIR)/$$name.yaml && \
	chmod 600 $(KUBIE_DIR)/$$name.yaml && \
	echo "kubie ctx $$name"

# helm pulls the charts through the ECR pull-through cache
registry-login: ## Log helm in to the ECR registry
	aws ecr get-login-password | helm registry login --username AWS --password-stdin "$$(jq -r .registry.host $(OUTPUT_FILE))"

charts: ## Apply the helmfile (Karpenter, LB Controller, operators, ArmoniK)
	$(HELMFILE) apply --skip-diff-on-install

charts-diff: ## Diff the helmfile against the cluster
	$(HELMFILE) diff

# Every image must come from the pull-through cache
check-images: ## Fail if a rendered image does not come from the pull-through cache
	$(HELMFILE) template --include-crds=false | sh $(CURRENT_DIR)/scripts/check-images.sh "$$(jq -r .registry.host $(OUTPUT_FILE))"

# Reverse order of the deployment, waiting at the two steps that otherwise leave AWS resources behind:
# the NLB (removed by the AWS Load Balancer Controller) and the Karpenter nodes (removed by Karpenter)
charts-destroy: ## Remove the charts in order, waiting for the NLB and the Karpenter nodes
	-$(HELMFILE) --selector name=armonik destroy
	@echo "Waiting for the load balancers to be removed"
	@for i in $$(seq 60); do \
		[ "$$(kubectl get svc -A -o json | jq '[.items[] | select(.spec.type == "LoadBalancer")] | length')" = 0 ] && break; \
		sleep 10; \
	done
	-$(HELMFILE) --selector name=aws-secret-store destroy
	-$(HELMFILE) --selector name=armonik-operators destroy
	-$(HELMFILE) --selector name=aws-load-balancer-controller destroy
	-kubectl delete nodepools.karpenter.sh --all --wait=false
	@echo "Waiting for the Karpenter nodes to be removed"
	@for i in $$(seq 60); do \
		[ "$$(kubectl get nodeclaims.karpenter.sh -o name 2>/dev/null | wc -l | tr -d ' ')" = 0 ] && break; \
		sleep 10; \
	done
	-$(HELMFILE) --selector name=karpenter-nodes destroy
	-$(HELMFILE) --selector name=karpenter destroy

# The pull-through cache repositories are created by ECR on the first pull, outside the state
clean-ecr: ## Delete the repositories created by the pull-through cache
	@for repo in $$(aws ecr describe-repositories --query "repositories[?starts_with(repositoryName, '$(PREFIX)/')].repositoryName" --output text); do \
		aws ecr delete-repository --repository-name "$$repo" --force > /dev/null && echo "deleted $$repo"; \
	done

delete: ## Remove the charts, then terraform destroy, then the cache repositories
	-$(MAKE) charts-destroy
	$(TF_CREDENTIALS) $(TERRAFORM) destroy $(TF_VARS) -auto-approve
	$(MAKE) clean-ecr

# Point the ArmoniK CLI to the ingress NLB
cliconfig: ## Write the ArmoniK CLI configuration to generated/armonik-cli.yaml
	@host=""; for i in $$(seq 60); do \
		host="$$(kubectl get svc -n $(NAMESPACE) armonik-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"; \
		[ -n "$$host" ] && break; sleep 10; \
	done; \
	printf '# ArmoniK Connection Configuration\n---\nendpoint: http://%s:5001\n' "$$host" > $(GENERATED_DIR)/armonik-cli.yaml
	@echo "export AKCONFIG=$(GENERATED_DIR)/armonik-cli.yaml"

clean: ## Remove the local Terraform data (providers, modules, lock file)
	rm -rf $(GENERATED_DIR)/providers $(GENERATED_DIR)/modules $(GENERATED_DIR)/terraform.tfstate $(TF_DIR)/.terraform.lock.hcl
