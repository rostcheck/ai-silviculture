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
STACK_NAME="forest-video-analyzer"

echo "🚀 Deploying complete infrastructure with stack name: $STACK_NAME"
aws cloudformation deploy \
    --template-file infrastructure-complete.yaml \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION

# Get outputs
API_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
    --output text \
    --region $REGION)

WEBSITE_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
    --output text \
    --region $REGION)

UPLOAD_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`UploadBucket`].OutputValue' \
    --output text \
    --region $REGION)

echo "🔗 API Gateway URL: $API_URL"

# Update frontend with API URL
echo "📝 Updating frontend configuration..."
sed -i.bak "s|https://YOUR_API_GATEWAY_URL/prod|$API_URL|g" frontend/index.html

WEBSITE_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
    --output text \
    --region $REGION | cut -d'/' -f3)

# Upload website to S3
echo "📤 Uploading website..."
aws s3 sync frontend/ s3://$WEBSITE_BUCKET --delete --region $REGION

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
            "Resource": "arn:aws:s3:::$(echo $WEBSITE_URL | cut -d'/' -f3)/*"
        }
    ]
}
EOF

# Get website bucket name from URL
WEBSITE_BUCKET_NAME=$(echo $WEBSITE_URL | cut -d'/' -f3)

# Disable public access block and set policy
aws s3api put-public-access-block \
    --bucket $WEBSITE_BUCKET_NAME \
    --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false \
    --region $REGION

aws s3api put-bucket-policy \
    --bucket $WEBSITE_BUCKET_NAME \
    --policy file://bucket-policy.json \
    --region $REGION

rm bucket-policy.json

# Add CORS to upload bucket
echo "🔧 Configuring CORS for upload bucket..."
aws s3api put-bucket-cors --bucket $UPLOAD_BUCKET --cors-configuration '{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST"],
      "AllowedOrigins": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3000
    }
  ]
}' --region $REGION

echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Website URL: $WEBSITE_URL"
echo "🔗 API Endpoint: $API_URL"
echo "📹 Upload Bucket: $UPLOAD_BUCKET"
echo ""
echo "📋 Videos will be uploaded to: $UPLOAD_BUCKET"
