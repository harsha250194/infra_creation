echo refresh the dev env
$(aws-okta env okta-dev)
TABLE_NAME="ctp-21mm-syntheticmonitoring-devd"

echo create DynamoDB Table
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --key-schema \
        AttributeName=servicesuite,KeyType=HASH \
        AttributeName=timestampms,KeyType=RANGE \
    --attribute-definitions \
        AttributeName=servicesuite,AttributeType=S \
        AttributeName=timestampms,AttributeType=N \
    --provisioned-throughput \
        ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-west-2

echo waiting for the process to complete DynamoDB Table creation ....
#aws dynamodb wait table-exists --table-name $TABLE_NAME

echo Describing DynamoDB Table ....
aws dynamodb describe-table --table-name $TABLE_NAME | grep TableStatus

echo defining DynamoDB TTL attribute
aws dynamodb update-time-to-live --table-name $TABLE_NAME --time-to-live-specification "Enabled=true, AttributeName=ttl"

echo describing DynamoDB TTL
aws dynamodb describe-time-to-live --table-name $TABLE_NAME