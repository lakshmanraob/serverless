#!/bin/bash

DIGITS_RE='^[0-9]+$'
TEMPLATE_FILE_NAME='serverless.cfn.yml'
PACKAGE_FILE_NAME='serverless-xfm.cfn.yml'
STACK_NAME='ServerlessTodo'
JSON_CONTENT='{"todo_id": "1001", "active": true, "description": "What TODO next?"}'

# Check if the aws cli is installed
if ! command -v aws > /dev/null; then
    echo "aws cli was not found. Please install before running this script."
    exit 1
fi

ACCOUNT_ID=`aws iam get-user | grep 'arn:aws:iam' | tr -dc '0-9'`
BUCKET_NAME="${ACCOUNT_ID}-serveless-todo-app"
REGION=${REGION_VAL}

# Check if the account id is valid
if ! [[ ${ACCOUNT_ID} =~ ${DIGITS_RE} ]] ; then
   echo "Invalid account ID" >&2
   exit 1
fi

# Try to create the bucket
if aws s3 mb s3://${BUCKET_NAME}; then
    echo "Bucket s3://${BUCKET_NAME} created successfully"
else
    echo "Failed creating bucket s3://${BUCKET_NAME}"
    # exit 1
fi

# Try to create CloudFormation package
if aws cloudformation package --template-file ${TEMPLATE_FILE_NAME} --output-template-file ${PACKAGE_FILE_NAME} --s3-bucket ${BUCKET_NAME}; then
    echo "CloudFormation successfully created the package ${PACKAGE_FILE_NAME}"
else
    echo "Failed creating CloudFormation package"
    # exit 1
fi

# Try to deploy the package
if aws cloudformation deploy --template-file ${PACKAGE_FILE_NAME} --region ${REGION} --stack-name ${STACK_NAME} --capabilities CAPABILITY_IAM; then
    echo "CloudFormation successfully deployed the serverless app package"
else
    echo "Failed deploying CloudFormation package"
    exit 1
fi

# Will retrieve the REST_API_ID from the created stack
REST_API_ID=`aws cloudformation list-stack-resources --region ${REGION} --stack-name ${STACK_NAME} | grep -A2 'AWS::ApiGateway::RestApi' | grep 'PhysicalResourceId' | awk '{print $2}' | tr -d '"' | tr -d ","`
# creating the rest api url
REST_API_URL="https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/Stage"

echo "The rest API url is ${REST_API_URL}"
echo "You can try adding a new to do item by running the following command:"
echo "curl -X POST -H 'Content-Type: application/json' -d '${JSON_CONTENT}' ${REST_API_URL}/todo/new"
echo ""
echo "To fetch the all TODO items, execute the following command:"
echo "curl ${REST_API_URL}/todo/all"
