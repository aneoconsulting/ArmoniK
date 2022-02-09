# This file is part of the ArmoniK project
#
# Copyright (C) ANEO, 2021-2021. All rights reserved.
#   L. Ziane Khodja   <lzianekhodja@aneo.fr>
#   J. Gurhem         <jgurhem@aneo.fr>
#   D. Holczer        <dholczer@aneo.fr>
#   D. Dubuc          <ddubuc@aneo.fr>
#   W. Kirschenmann   <wkirschenmann@aneo.fr>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

export TAG
export REGION?=eu-west-3
BACKEND?=generated
YAML_SRC:=backend-resources.yaml

all: deploy

deploy: $(YAML_SRC)
	@mkdir -p $(BACKEND)
	aws cloudformation create-stack --stack-name $(TAG) --region $(REGION) --template-body file://$(YAML_SRC) --parameters ParameterKey=BucketTag,ParameterValue=$(TAG)
	@echo "Waiting for cloud formation successful deployment"
	@aws cloudformation wait stack-create-complete --stack-name $(TAG) --region $(REGION)
	@aws cloudformation describe-stacks --stack-name $(TAG) --region $(REGION) --query 'Stacks[0]' > $(BACKEND)/output.json

destroy:
	aws cloudformation delete-stack --stack-name $(TAG) --region $(REGION)
	aws cloudformation wait stack-delete-complete --stack-name $(shell aws cloudformation describe-stacks --region $(REGION) --stack-name $(TAG) --query 'Stacks[0].StackId' --output text) --region $(REGION)

