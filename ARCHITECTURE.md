# Forest Harvesting Video Analysis System

## Overview
AWS-based serverless application that analyzes GoPro forestry videos using TwelveLabs Pegasus to identify tree cutting events, species, and generate text reports for forest operators.

## Architecture Components

### Frontend (S3 + CloudFront)
- **Static Website**: Simple HTML/JS interface hosted on S3
- **User Interface**: Drag-and-drop video upload with progress tracking
- **Report Display**: Text-based results with download capability
- **CloudFront**: CDN for global distribution

### Processing Pipeline
```
Video Upload → S3 → Lambda Trigger → Step Functions → TwelveLabs → Report Generation
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
  - `upload-handler`: Generate presigned URLs for video upload
  - `video-processor`: Integrate with TwelveLabs Pegasus API
  - `report-generator`: Create formatted text reports
- **Step Functions**: Orchestrate processing workflow

#### Integration
- **SQS**: Queue for batch video processing
- **SNS**: Email notifications for job completion
- **API Gateway**: REST endpoints for frontend communication

#### Monitoring
- **CloudWatch**: Logs, metrics, and alarms
- **X-Ray**: Distributed tracing for debugging

## Data Flow

1. **Upload Phase**:
   - Operator uploads MP4 via web interface
   - Lambda generates presigned S3 URL
   - Video stored in input bucket

2. **Processing Phase**:
   - S3 event triggers Step Functions workflow
   - Video sent to TwelveLabs Pegasus API
   - AI analyzes for tree cutting events and species

3. **Output Phase**:
   - Results stored in DynamoDB
   - Text report generated and saved to S3
   - SNS notification sent to operator

## TwelveLabs Integration

### Pegasus Prompts
- Tree cutting detection: "Identify timestamps when chainsaw cuts through tree trunk"
- Species identification: "Identify tree species visible during cutting events"
- Event counting: "Count total number of trees cut in video"

### API Workflow
1. Upload video to TwelveLabs
2. Submit analysis job with forestry prompts
3. Poll for completion
4. Extract structured results

## Report Format

```
FOREST HARVESTING REPORT
========================
Video: [filename]
Date: [timestamp]
Duration: [MM:SS]

SUMMARY
-------
Total Trees Cut: X
Processing Time: X minutes

CUTTING EVENTS
--------------
[HH:MM:SS] - [Species] (Est. [XX]" diameter)
[HH:MM:SS] - [Species] (Est. [XX]" diameter)
...

SPECIES BREAKDOWN
-----------------
Oak: X trees
Pine: X trees
Maple: X trees
...
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

- **Infrastructure as Code**: AWS CDK or CloudFormation
- **CI/CD Pipeline**: GitHub Actions or AWS CodePipeline
- **Environment Separation**: Dev, staging, production stacks

## Monitoring & Alerting

- **CloudWatch Dashboards**: Processing metrics and success rates
- **Alarms**: Failed processing jobs, high error rates
- **SNS Notifications**: System alerts to administrators
- **Cost Monitoring**: Budget alerts and usage tracking
