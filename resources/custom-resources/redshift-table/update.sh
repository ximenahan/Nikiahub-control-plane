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
LAMBDA_CODE=RedshiftTable-lambda.zip

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

# Find all the functions for this microservice
# We must list in the redshift-table case since functions are created with a tenant ID suffix
eval FUNCTIONS=\$\("aws --region $MY_AWS_REGION lambda list-functions --query 'Functions[?starts_with(FunctionName, \`sb-${ENVIRONMENT}-redshift-table-\`)] | [].FunctionName' --output text"\)
FUNCTIONS=($FUNCTIONS)
for FX in "${FUNCTIONS[@]}"; do
    printf "Updating function code for %s\n" $FX
    aws lambda --region "$MY_AWS_REGION" update-function-code --function-name "$FX" --s3-bucket "$SAAS_BOOST_BUCKET" --s3-key $LAMBDA_STAGE_FOLDER/$LAMBDA_CODE
done
