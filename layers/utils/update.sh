#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ -z $1 ]; then
    echo "Usage: $0 <Environment> [Lambda Folder]"
    exit 2
fi

MY_AWS_REGION=$(aws configure list | grep region | awk '{print $2}')
echo "AWS Region = $MY_AWS_REGION"

ENVIRONMENT=$1
LAMBDA_STAGE_FOLDER=$2
if [ -z $LAMBDA_STAGE_FOLDER ]; then
	LAMBDA_STAGE_FOLDER="lambdas"
fi
LAMBDA_CODE=Utils-lambda.zip
LAYER_NAME="sb-${ENVIRONMENT}-utils"

#set this for V2 AWS CLI to disable paging
export AWS_PAGER=""

SAAS_BOOST_BUCKET=$(aws --region $MY_AWS_REGION ssm get-parameter --name "/saas-boost/${ENVIRONMENT}/SAAS_BOOST_BUCKET" --query 'Parameter.Value' --output text)
echo "SaaS Boost Bucket = $SAAS_BOOST_BUCKET"
if [ -z $SAAS_BOOST_BUCKET ]; then
    echo "Can't find SAAS_BOOST_BUCKET in Parameter Store"
    exit 1
fi

# Do a fresh build of the project
mvn
if [ $? -ne 0 ]; then
    echo "Error building project"
    exit 1
fi

# And copy it up to S3
aws s3 cp target/$LAMBDA_CODE s3://$SAAS_BOOST_BUCKET/$LAMBDA_STAGE_FOLDER/

# Publish a new version of the layer
PUBLISHED_LAYER=$(aws --region $MY_AWS_REGION lambda publish-layer-version --layer-name "${LAYER_NAME}" --compatible-runtimes java11 --content S3Bucket="${SAAS_BOOST_BUCKET}",S3Key="${LAMBDA_STAGE_FOLDER}/${LAMBDA_CODE}")

# Use eval to deal with the backticks in the filter expression
eval LAYER_VERSION_ARN=\$\("aws lambda list-layers --query 'Layers[?LayerName==\`${LAYER_NAME}\`].LatestMatchingVersion.LayerVersionArn' --output text"\)
echo "Published new layer = $LAYER_VERSION_ARN"

# Find all the functions for this SaaS Boost environment that have layers
eval FUNCTIONS=\$\("aws --region $MY_AWS_REGION lambda list-functions --query 'Functions[?starts_with(FunctionName, \`sb-${ENVIRONMENT}-\`)] | [?Layers != null] | [].FunctionName' --output text"\)
# Because the saas-boost-app-services-macro relies on the Utils package, we need to make sure that also gets updated
# In case we have multiple environments in the same account/region, this could potentially override the Utils implementation
# when one environment is updated from underneath another. This shouldn't be an issue unless the Utils upgrade includes a 
# change to the isBlank, isEmpty, logRequestEvent, or Utils.toJson functions.
FUNCTIONS=($FUNCTIONS "saas-boost-app-services-macro")
#echo "Updating ${#FUNCTIONS[@]} functions with new layer version"

for FX in ${FUNCTIONS[@]}; do
	# The order of the function's layers must be maintained. Iterate through this function's layers
	# and update this layer's ARN with the newly published version.
	FOUND=0
	LAYERS=""
	for LAYER_ARN in $(aws --region $MY_AWS_REGION lambda get-function --function-name $FX --query 'Configuration.Layers[].Arn' --output text); do
		if [[ $LAYER_ARN == *"${LAYER_NAME}"* ]]; then
			LAYER_ARN=$LAYER_VERSION_ARN
			FOUND=1
		fi
		if [ ${#LAYERS} -gt 0 ]; then
			LAYERS="${LAYERS} "
		fi
		LAYERS="${LAYERS}${LAYER_ARN}"
	done
	if (( $FOUND )); then
		eval "aws --region $MY_AWS_REGION lambda update-function-configuration --function-name $FX --layers $LAYERS"
	fi
done