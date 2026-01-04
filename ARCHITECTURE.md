# Forest Harvesting Video Analysis System

## Overview
AWS-based serverless application that analyzes GoPro forestry videos using AWS Bedrock TwelveLabs Pegasus to identify tree cutting events, species, and generate text reports for forest operators.

## Implementation Status

### ✅ COMPLETED COMPONENTS
- **Frontend**: S3-hosted static website with drag-and-drop interface
- **Complete Infrastructure**: S3 buckets, DynamoDB, IAM roles
- **Upload Handler**: Lambda function with multipart upload support
- **Video Processor**: Lambda function with AWS Bedrock TwelveLabs Pegasus integration
- **Status Checker**: Lambda function for job status and results retrieval
- **Complete Upload**: Lambda function for multipart upload completion
- **API Gateway**: Complete REST API with CORS support
- **S3 Event Triggers**: Custom resource for bucket notifications
- **Deployment Scripts**: Automated CloudFormation deployment
- **Testing Suite**: Comprehensive command-line test scripts
- **Report Generation**: Formatted text output with download capability
- **Error Handling**: Comprehensive error management throughout
- **Multipart Upload**: Large file upload support (>100MB)

### 🎯 PRODUCTION READY
- **Complete end-to-end functionality**
- **Automated testing and validation**
- **Scalable serverless architecture**
- **AWS Bedrock AI integration** - no API keys needed
- **Real TwelveLabs Pegasus analysis** with structured JSON output

## Architecture Components

### Frontend (S3 + CloudFront)
- **Static Website**: Simple HTML/JS interface hosted on S3
- **User Interface**: Drag-and-drop video upload with progress tracking
- **Report Display**: Text-based results with download capability
- **CloudFront**: CDN for global distribution

### Processing Pipeline
```
Video Upload → S3 → Lambda Trigger → AWS Bedrock Pegasus → Report Generation
```

### AWS Services

#### Storage
- **S3 Buckets**:
  - `forest-videos-input`: Raw GoPro MP4 uploads
  - `forest-reports-output`: Generated text reports
  - `forest-website`: Static website hosting
- **DynamoDB**: Processing results and job status

#### Compute
- **Lambda Functions**:
  - `UploadHandlerFunction`: Generate presigned URLs with multipart support
  - `VideoProcessorFunction`: Process videos with AWS Bedrock Pegasus integration
  - `StatusCheckerFunction`: Check job status and retrieve results
  - `CompleteUploadFunction`: Handle multipart upload completion
  - `BucketNotificationFunction`: Custom resource for S3 event configuration

#### Integration
- **S3 Event Triggers**: Automatic processing on video upload
- **API Gateway**: REST endpoints with full CORS support
- **Custom Resources**: CloudFormation custom resources for complex configurations
- **Presigned URLs**: Secure direct-to-S3 uploads

#### Monitoring
- **CloudWatch**: Logs, metrics, and alarms for all Lambda functions
- **DynamoDB**: Real-time job tracking and status management
- **Error Handling**: Comprehensive error management and reporting

## Data Flow

1. **Upload Phase**:
   - Operator uploads MP4 via web interface
   - Lambda generates presigned S3 URL (single or multipart)
   - Video uploaded directly to S3 input bucket

2. **Processing Phase**:
   - S3 event automatically triggers VideoProcessorFunction
   - Job status updated to "processing" in DynamoDB
   - Video analyzed with AWS Bedrock TwelveLabs Pegasus

3. **Output Phase**:
   - Results stored in DynamoDB with completion status
   - Text report generated and saved to S3 output bucket
   - Report available for download via presigned URL

## API Endpoints

### POST /upload
- **Purpose**: Get presigned URL for video upload
- **Input**: `{"filename": "video.mp4", "fileSize": 123456}`
- **Output**: Presigned URL (single or multipart) + job ID

### POST /complete
- **Purpose**: Complete multipart upload
- **Input**: Upload ID, parts list, bucket/key info
- **Output**: Success confirmation

### GET /status/{jobId}
- **Purpose**: Check processing status and get results
- **Output**: Job status, results, report download URL

### Bedrock Integration

### TwelveLabs Pegasus Model
- **Model**: `us.twelvelabs.pegasus-1-2-v1:0` (regional inference profile)
- **Region**: `us-east-1` (matches S3 bucket location)
- **Input**: S3 video URI + structured JSON prompt
- **Output**: JSON analysis with tree cutting events and species

### Analysis Workflow
1. Lambda invokes Bedrock with S3 video URI and structured prompt
2. Pegasus analyzes video for forestry content using regional inference profile
3. JSON parsing extracts structured data (trees_cut, events array)
4. Results formatted into downloadable report

### Prompt Structure
```json
{
  "inputPrompt": "Analyze this forestry video and return JSON: {\"trees_cut\": total_number, \"events\": [{\"timestamp\": \"MM:SS when tree begins to fall\", \"species\": \"name\", \"diameter\": inches}]} for each tree cutting event observed.",
  "mediaSource": {
    "s3Location": {
      "uri": "s3://bucket/key",
      "bucketOwner": "account_id"
    }
  }
}
```

## Report Format

```
FOREST HARVESTING REPORT
========================
Video: [filename]
Date: [timestamp]
Analysis: AWS Bedrock TwelveLabs Pegasus AI

SUMMARY
-------
Total Trees Cut: X

CUTTING EVENTS
--------------
[MM:SS] - [Species] (Est. [XX]" diameter)
[MM:SS] - [Species] (Est. [XX]" diameter)
...

--- End of Report ---
```

## Security & Compliance

- **IAM Roles**: Least privilege access for all services
- **S3 Bucket Policies**: Restrict access to authorized users
- **API Gateway**: Rate limiting and authentication
- **Encryption**: At-rest and in-transit for all data

## Scalability

- **Serverless**: Auto-scaling based on demand
- **SQS**: Handle batch processing of multiple videos
- **DynamoDB**: On-demand scaling for results storage
- **CloudFront**: Global edge caching

## Cost Optimization

- **S3 Lifecycle**: Move old videos to cheaper storage classes
- **Lambda**: Pay-per-execution model
- **Reserved Capacity**: For predictable DynamoDB usage
- **CloudWatch**: Monitor and optimize resource usage

## Deployment

### Prerequisites
- AWS CLI configured with appropriate permissions
- CloudFormation access for stack creation
- IAM permissions for Lambda, S3, DynamoDB, API Gateway

### Deployment Steps
```bash
# 1. Deploy infrastructure
./deploy.sh

# 2. Test deployment
./quick-test.sh    # Basic validation
./test.sh          # Comprehensive testing

# 3. AI analysis is automatic (uses AWS Bedrock)
```

### Stack Outputs
- **ApiEndpoint**: API Gateway URL for frontend integration
- **WebsiteURL**: S3 static website URL
- **UploadBucket**: S3 bucket name for video uploads
- **ReportBucket**: S3 bucket name for generated reports

## Monitoring & Alerting

- **CloudWatch Dashboards**: Processing metrics and success rates
- **Alarms**: Failed processing jobs, high error rates
- **SNS Notifications**: System alerts to administrators
- **Cost Monitoring**: Budget alerts and usage tracking
