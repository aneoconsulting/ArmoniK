export SUFFIX?=main
export REGION?=eu-west-3
export BUCKET_NAME?=armonik-tfstate
BACKEND?=generated
YAML_SRC:=backend-resources.yaml

all: deploy

deploy: $(YAML_SRC)
	@mkdir -p $(BACKEND)
	aws cloudformation create-stack --stack-name $(SUFFIX) --region $(REGION) --template-body file://$(YAML_SRC) --parameters ParameterKey=Tag,ParameterValue=$(SUFFIX) ParameterKey=BucketName,ParameterValue=$(BUCKET_NAME)
	@echo "Waiting for cloud formation successful deployment"
	@aws cloudformation wait stack-create-complete --stack-name $(SUFFIX) --region $(REGION)
	@aws cloudformation describe-stacks --stack-name $(SUFFIX) --region $(REGION) --query 'Stacks[0]' > $(BACKEND)/output.json

destroy:
	aws cloudformation delete-stack --stack-name $(SUFFIX) --region $(REGION)
	aws cloudformation wait stack-delete-complete --stack-name $(shell aws cloudformation describe-stacks --region $(REGION) --stack-name $(SUFFIX) --query 'Stacks[0].StackId' --output text) --region $(REGION)

