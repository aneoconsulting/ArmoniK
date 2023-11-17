export SUFFIX?=main
export REGION?=eu-west-3
export BUCKET_NAME?=armonik-tfstate
export PROFILE?=default
export TFSTATE_BUCKET_NAME=$(BUCKET_NAME)-$(SUFFIX)
BACKEND?=generated
YAML_SRC:=backend-resources.yaml

all: deploy

deploy: $(YAML_SRC)
	@mkdir -p $(BACKEND)
	aws --profile $(PROFILE) cloudformation create-stack --stack-name $(SUFFIX) --region $(REGION) --template-body file://$(YAML_SRC) --parameters ParameterKey=Tag,ParameterValue=$(SUFFIX) ParameterKey=BucketName,ParameterValue=$(BUCKET_NAME)
	@echo "Waiting for cloud formation successful deployment"
	@aws --profile $(PROFILE) cloudformation wait stack-create-complete --stack-name $(SUFFIX) --region $(REGION)
	@aws --profile $(PROFILE) cloudformation describe-stacks --stack-name $(SUFFIX) --region $(REGION) --query 'Stacks[0]' > $(BACKEND)/output.json

destroy:
	aws --profile $(PROFILE) --region $(REGION) s3api delete-objects \
		--bucket "${TFSTATE_BUCKET_NAME}" \
		--delete "`aws --profile $(PROFILE) s3api list-object-versions \
		--bucket "${TFSTATE_BUCKET_NAME}" \
		--output=json \
		--query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}'`"
	aws --profile $(PROFILE) cloudformation delete-stack --stack-name $(SUFFIX) --region $(REGION)
	@aws --profile $(PROFILE) cloudformation wait stack-delete-complete --stack-name $(shell aws --profile $(PROFILE) cloudformation describe-stacks --region $(REGION) --stack-name $(SUFFIX) --query 'Stacks[0].StackId' --output text) --region $(REGION)

