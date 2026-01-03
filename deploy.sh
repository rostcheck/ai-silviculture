#!/bin/bash

# Forest Video Analyzer - Deployment Script

set -e

echo "🌲 Deploying Forest Video Analyzer..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Get AWS account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

echo "📍 Deploying to Account: $ACCOUNT_ID, Region: $REGION"

# Deploy CloudFormation stack
echo "🚀 Deploying infrastructure..."
aws cloudformation deploy \
    --template-file infrastructure-simple.yaml \
    --stack-name forest-video-analyzer \
    --capabilities CAPABILITY_IAM \
    --region $REGION

# Get API Gateway URL
API_URL=$(aws cloudformation describe-stacks \
    --stack-name forest-video-analyzer \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
    --output text \
    --region $REGION)

# Get Website URL
WEBSITE_URL=$(aws cloudformation describe-stacks \
    --stack-name forest-video-analyzer \
    --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
    --output text \
    --region $REGION)

echo "🔗 API Gateway URL: $API_URL"

# Update frontend with API URL
echo "📝 Updating frontend configuration..."
sed -i.bak "s|https://YOUR_API_GATEWAY_URL/prod|$API_URL|g" frontend/index.html

# Upload website to S3
echo "📤 Uploading website..."
aws s3 sync frontend/ s3://forest-website-$ACCOUNT_ID --delete --region $REGION

# Set bucket policy for public website access
echo "🌐 Setting up public website access..."
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::forest-website-$ACCOUNT_ID/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket forest-website-$ACCOUNT_ID \
    --policy file://bucket-policy.json \
    --region $REGION

rm bucket-policy.json

echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Website URL: $WEBSITE_URL"
echo "🔗 API Endpoint: $API_URL"
echo ""
echo "📋 Next Steps:"
echo "1. Set up TwelveLabs API key (optional):"
echo "   aws lambda update-function-configuration --function-name forest-video-processor --environment Variables='{TWELVELABS_API_KEY=your_api_key,TWELVELABS_INDEX_ID=your_index_id}'"
echo ""
echo "2. Test the application by uploading an MP4 video at: $WEBSITE_URL"
echo ""
echo "3. Monitor logs with:"
echo "   aws logs tail /aws/lambda/forest-video-processor --follow"
