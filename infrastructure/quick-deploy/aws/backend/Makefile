export TAG?=main
export REGION?=eu-west-3
export BUCKET_NAME?=armonik-tfstate
BACKEND?=generated
YAML_SRC:=backend-resources.yaml

all: deploy

deploy: $(YAML_SRC)
	@mkdir -p $(BACKEND)
	aws cloudformation create-stack --stack-name $(TAG) --region $(REGION) --template-body file://$(YAML_SRC) --parameters ParameterKey=Tag,ParameterValue=$(TAG) ParameterKey=BucketName,ParameterValue=$(BUCKET_NAME)
	@echo "Waiting for cloud formation successful deployment"
	@aws cloudformation wait stack-create-complete --stack-name $(TAG) --region $(REGION)
	@aws cloudformation describe-stacks --stack-name $(TAG) --region $(REGION) --query 'Stacks[0]' > $(BACKEND)/output.json

destroy:
	aws cloudformation delete-stack --stack-name $(TAG) --region $(REGION)
	aws cloudformation wait stack-delete-complete --stack-name $(shell aws cloudformation describe-stacks --region $(REGION) --stack-name $(TAG) --query 'Stacks[0].StackId' --output text) --region $(REGION)

