#!/bin/bash

# Quick Test - Forest Video Analyzer

echo "🚀 Quick Test - Forest Video Analyzer"
echo "====================================="

# Find deployed stack
STACK_NAME=$(aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query "StackSummaries[?starts_with(StackName, 'forest-')].StackName" \
    --output text --region us-east-1 | head -1)

if [ -z "$STACK_NAME" ]; then
    echo "❌ No deployed stack found. Run ./deploy.sh first"
    exit 1
fi

# Get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
    --output text --region us-east-1)

echo "📍 Stack: $STACK_NAME"
echo "🔗 API: $API_ENDPOINT"

# Test API endpoints
echo -e "\n🧪 Testing API endpoints..."

echo -n "  /upload (OPTIONS): "
curl -s -o /dev/null -w "%{http_code}" "$API_ENDPOINT/upload" -X OPTIONS | grep -q "200" && echo "✅" || echo "❌"

echo -n "  /upload (POST): "
response=$(curl -s -X POST "$API_ENDPOINT/upload" -H "Content-Type: application/json" -d '{"filename":"test.mp4","fileSize":1000000}')
echo "$response" | jq -e '.jobId' > /dev/null 2>&1 && echo "✅" || echo "❌"

if echo "$response" | jq -e '.jobId' > /dev/null 2>&1; then
    JOB_ID=$(echo "$response" | jq -r '.jobId')
    echo -n "  /status/$JOB_ID (GET): "
    curl -s "$API_ENDPOINT/status/$JOB_ID" | jq -e '.jobId' > /dev/null 2>&1 && echo "✅" || echo "❌"
fi

echo -e "\n✅ Quick test complete!"
echo "Run ./test.sh for comprehensive testing"
