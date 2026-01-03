# Forest Video Analyzer

AWS serverless application for analyzing GoPro forestry videos using TwelveLabs Pegasus AI to identify tree cutting events and species.

## Quick Start

1. **Deploy the application:**
   ```bash
   ./deploy.sh
   ```

2. **Set up TwelveLabs API (optional):**
   ```bash
   aws lambda update-function-configuration \
     --function-name forest-video-processor \
     --environment Variables='{TWELVELABS_API_KEY=your_api_key,TWELVELABS_INDEX_ID=your_index_id}'
   ```

3. **Access the web interface** at the URL provided after deployment

## Features

- **Simple drag-and-drop interface** for video uploads
- **AI-powered analysis** using TwelveLabs Pegasus
- **Tree cutting event detection** with timestamps
- **Species identification** for cut trees
- **Text report generation** with downloadable results
- **Real-time processing status** updates

## Architecture

- **Frontend**: S3-hosted static website with vanilla JavaScript
- **Backend**: AWS Lambda functions with Python
- **Storage**: S3 for videos/reports, DynamoDB for job tracking
- **AI**: TwelveLabs Pegasus for video analysis
- **API**: API Gateway for REST endpoints

## File Structure

```
├── ARCHITECTURE.md          # Detailed architecture documentation
├── infrastructure.yaml      # CloudFormation template
├── deploy.sh               # Deployment script
├── frontend/
│   └── index.html          # Web interface
└── lambda/
    └── video_processor.py  # Main processing logic
```

## Usage

1. Upload MP4 video file via web interface
2. Wait for AI processing (typically 2-5 minutes)
3. Download generated text report with:
   - Total trees cut
   - Timestamps of cutting events
   - Species identification
   - Estimated diameters

## Sample Report Output

```
FOREST HARVESTING REPORT
========================
Video: forest_work_20240103.mp4
Date: 2024-01-03 14:30:00 UTC

SUMMARY
-------
Total Trees Cut: 3

CUTTING EVENTS
--------------
1. 00:02:15 - Oak (Est. 18" diameter)
2. 00:05:42 - Pine (Est. 14" diameter)
3. 00:08:30 - Maple (Est. 16" diameter)

SPECIES BREAKDOWN
-----------------
Oak: 1 tree
Pine: 1 tree
Maple: 1 tree
```

## Cost Estimation

- **Lambda**: ~$0.10 per video (5-minute processing)
- **S3**: ~$0.02 per GB storage
- **DynamoDB**: ~$0.01 per 1000 requests
- **API Gateway**: ~$0.01 per 1000 requests
- **TwelveLabs**: Variable based on video length

## Monitoring

View processing logs:
```bash
aws logs tail /aws/lambda/forest-video-processor --follow
```

Check job status:
```bash
aws dynamodb scan --table-name forest-processing-results
```

## Troubleshooting

- **Upload fails**: Check S3 bucket permissions
- **Processing stuck**: Verify TwelveLabs API key
- **No results**: Check CloudWatch logs for errors
- **Website not loading**: Verify S3 bucket policy

## Development

To modify the application:

1. Update Lambda code in `lambda/video_processor.py`
2. Modify frontend in `frontend/index.html`
3. Update infrastructure in `infrastructure.yaml`
4. Redeploy with `./deploy.sh`
