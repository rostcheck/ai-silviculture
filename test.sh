#!/bin/bash

# Forest Video Analyzer - Test Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME_PREFIX="forest-"
TEST_VIDEO_FILE="test.mp4"

echo -e "${BLUE}🧪 Forest Video Analyzer - Test Suite${NC}"
echo "========================================"

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        return 1
    fi
}

# Function to get stack outputs
get_stack_output() {
    local stack_name=$1
    local output_key=$2
    aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --query "Stacks[0].Outputs[?OutputKey=='$output_key'].OutputValue" \
        --output text \
        --region us-east-1 2>/dev/null
}

# Find the deployed stack
echo -e "${YELLOW}🔍 Finding deployed stack...${NC}"
STACK_NAME=$(aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query "StackSummaries[?starts_with(StackName, '$STACK_NAME_PREFIX')].StackName" \
    --output text \
    --region us-east-1 | head -1)

if [ -z "$STACK_NAME" ]; then
    echo -e "${RED}❌ No deployed forest stack found. Please run ./deploy.sh first${NC}"
    exit 1
fi

echo -e "${GREEN}Found stack: $STACK_NAME${NC}"

# Get stack outputs
echo -e "${YELLOW}📋 Getting stack outputs...${NC}"
API_ENDPOINT=$(get_stack_output "$STACK_NAME" "ApiEndpoint")
WEBSITE_URL=$(get_stack_output "$STACK_NAME" "WebsiteURL")
UPLOAD_BUCKET=$(get_stack_output "$STACK_NAME" "UploadBucket")
REPORT_BUCKET=$(get_stack_output "$STACK_NAME" "ReportBucket")

echo "API Endpoint: $API_ENDPOINT"
echo "Website URL: $WEBSITE_URL"
echo "Upload Bucket: $UPLOAD_BUCKET"
echo "Report Bucket: $REPORT_BUCKET"

# Test 1: API Gateway Health Check
echo -e "\n${YELLOW}🌐 Test 1: API Gateway Health Check${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" "$API_ENDPOINT/upload" -X OPTIONS)
print_result $([[ "$response" == "200" ]] && echo 0 || echo 1) "API Gateway CORS preflight"

# Test 2: Upload Handler - Get Presigned URL
echo -e "\n${YELLOW}📤 Test 2: Upload Handler${NC}"
FILE_SIZE=$(stat -f%z "$TEST_VIDEO_FILE" 2>/dev/null || stat -c%s "$TEST_VIDEO_FILE" 2>/dev/null | head -1)
upload_response=$(curl -s -X POST "$API_ENDPOINT/upload" \
    -H "Content-Type: application/json" \
    -d "{\"filename\":\"$(basename "$TEST_VIDEO_FILE")\",\"fileSize\":$FILE_SIZE}")

if echo "$upload_response" | jq -e '.jobId' > /dev/null 2>&1; then
    JOB_ID=$(echo "$upload_response" | jq -r '.jobId')
    UPLOAD_URL=$(echo "$upload_response" | jq -r '.uploadUrl')
    print_result 0 "Upload handler returned presigned URL"
    echo "Job ID: $JOB_ID"
else
    print_result 1 "Upload handler failed"
    echo "Response: $upload_response"
    exit 1
fi

# Test 3: Check if test video exists
echo -e "\n${YELLOW}📥 Test 3: Check test video${NC}"
if [ ! -f "$TEST_VIDEO_FILE" ]; then
    print_result 1 "Test video file not found: $TEST_VIDEO_FILE"
    exit 1
else
    print_result 0 "Test video file exists ($(du -h "$TEST_VIDEO_FILE" | cut -f1))"
fi

# Test 4: Upload video to S3
echo -e "\n${YELLOW}☁️ Test 4: Upload video to S3${NC}"
upload_result=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$UPLOAD_URL" \
    -H "Content-Type: video/mp4" \
    --data-binary "@$TEST_VIDEO_FILE")
print_result $([[ "$upload_result" == "200" ]] && echo 0 || echo 1) "Video uploaded to S3"

# Test 5: Verify video in S3 bucket
echo -e "\n${YELLOW}🗂️ Test 5: Verify video in S3 bucket${NC}"
sleep 2  # Give S3 a moment to process
s3_check=$(aws s3 ls "s3://$UPLOAD_BUCKET/$JOB_ID/" --region us-east-1 2>/dev/null | grep "$(basename "$TEST_VIDEO_FILE")" | wc -l | tr -d ' ')
print_result $([[ "$s3_check" -gt 0 ]] && echo 0 || echo 1) "Video exists in S3 bucket"

# Test 6: Check initial job status
echo -e "\n${YELLOW}📊 Test 6: Check job status${NC}"
sleep 3  # Give processing a moment to start
status_response=$(curl -s "$API_ENDPOINT/status/$JOB_ID")
if echo "$status_response" | jq -e '.status' > /dev/null 2>&1; then
    STATUS=$(echo "$status_response" | jq -r '.status')
    print_result 0 "Status endpoint returned: $STATUS"
else
    print_result 1 "Status endpoint failed"
    echo "Response: $status_response"
fi

# Test 7: Wait for processing completion
echo -e "\n${YELLOW}⏳ Test 7: Wait for processing completion${NC}"
echo "Waiting for video processing (max 2 minutes)..."
for i in {1..24}; do
    sleep 5
    status_response=$(curl -s "$API_ENDPOINT/status/$JOB_ID")
    STATUS=$(echo "$status_response" | jq -r '.status' 2>/dev/null || echo "unknown")
    
    echo -n "."
    
    if [[ "$STATUS" == "completed" ]]; then
        echo ""
        print_result 0 "Video processing completed"
        REPORT_URL=$(echo "$status_response" | jq -r '.reportUrl')
        break
    elif [[ "$STATUS" == "failed" ]]; then
        echo ""
        print_result 1 "Video processing failed"
        echo "Error: $(echo "$status_response" | jq -r '.error' 2>/dev/null || echo 'Unknown error')"
        break
    fi
    
    if [[ $i -eq 24 ]]; then
        echo ""
        print_result 1 "Processing timeout (2 minutes)"
        echo "Final status: $STATUS"
    fi
done

# Test 8: Download and verify report
if [[ "$STATUS" == "completed" && -n "$REPORT_URL" ]]; then
    echo -e "\n${YELLOW}📄 Test 8: Download and verify report${NC}"
    report_content=$(curl -s "$REPORT_URL")
    if echo "$report_content" | grep -q "FOREST HARVESTING REPORT"; then
        print_result 0 "Report downloaded and contains expected content"
        echo "Report preview:"
        echo "$report_content" | head -10
    else
        print_result 1 "Report download failed or invalid content"
    fi
fi

# Test 9: Check DynamoDB entry
echo -e "\n${YELLOW}🗄️ Test 9: Verify DynamoDB entry${NC}"
TABLE_NAME="forest-processing-results"

# Poll for DynamoDB entry (max 30 seconds)
for i in {1..15}; do
    db_item=$(aws dynamodb get-item \
        --table-name "$TABLE_NAME" \
        --key "{\"jobId\":{\"S\":\"$JOB_ID\"}}" \
        --region us-east-1 \
        --output json 2>/dev/null)
    
    if echo "$db_item" | jq -e '.Item' > /dev/null 2>&1; then
        print_result 0 "DynamoDB entry exists"
        DB_STATUS=$(echo "$db_item" | jq -r '.Item.status.S' 2>/dev/null || echo "unknown")
        echo "Database status: $DB_STATUS"
        break
    fi
    
    if [[ $i -eq 15 ]]; then
        print_result 1 "DynamoDB entry not found after 30 seconds"
    else
        sleep 2
    fi
done

# Test 10: Cleanup
echo -e "\n${YELLOW}🧹 Test 10: Cleanup${NC}"
print_result 0 "No cleanup needed (using existing test video)"

# Summary
echo -e "\n${BLUE}📋 TEST SUMMARY${NC}"
echo "================"
echo "Stack Name: $STACK_NAME"
echo "Job ID: $JOB_ID"
echo "Final Status: $STATUS"
echo "API Endpoint: $API_ENDPOINT"
echo "Website: $WEBSITE_URL"

if [[ "$STATUS" == "completed" ]]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo "The Forest Video Analyzer is working correctly."
else
    echo -e "\n${YELLOW}⚠️ TESTS COMPLETED WITH ISSUES${NC}"
    echo "Check the logs above for details."
fi

echo -e "\n${BLUE}💡 Next Steps:${NC}"
echo "1. Visit the website: $WEBSITE_URL"
echo "2. Upload videos through the web interface"
echo "3. Monitor logs: aws logs tail /aws/lambda/forest-processor-$STACK_NAME --follow"
