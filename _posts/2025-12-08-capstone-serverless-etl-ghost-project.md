---
layout: post
title: "The Capstone: Serverless ETL 'Ghost Project'"
date: 2025-12-08 10:00:00 -0400
categories: [Data Engineering]
tags: [ETL, Project, GhostProject, DataScience, Portfolio]
excerpt: "A carpenter measures twice and cuts once; a cloud architect diagrams twice and codes once. Today, we assemble the skills from the previous 12 posts into a comprehensive portfolio piece."
---

A carpenter measures twice and cuts once; a cloud architect diagrams twice and codes once. Today, we assemble the skills from the previous 12 posts into a comprehensive portfolio piece: a Serverless ETL Pipeline. We will extract cryptocurrency market data, clean it using the Pandas library inside a Lambda environment, and load it into DynamoDB for querying. This isn't just a tutorial; it is a 'Ghost Project'—a tangible demonstration of value that you can put on your resume to prove you can build complex, event-driven systems.

## The Ghost Project Concept

A "Ghost Project" is work you do for a company you want to work for, before they hire you. You notice their site is slow, so you build a POC CDN using CloudFront. You see they process data manually, so you build an automated ETL pipeline. This demonstrates initiative and proves you can solve real problems.

## Architecture Overview

Our pipeline follows this flow:
1. **Extraction**: CoinGecko API → S3 (Raw Data Lake)
2. **Transformation**: S3 Event → Lambda (Pandas Processing)
3. **Loading**: Lambda → DynamoDB (Analytics Database)

## Step 1: Extraction (Ingestion)

First, let's build a script that fetches data from the CoinGecko API:

```python
import boto3
import requests
import json
from datetime import datetime

s3 = boto3.client('s3')

def fetch_crypto_data():
    """Fetch cryptocurrency market data from CoinGecko API."""
    
    url = 'https://api.coingecko.com/api/v3/coins/markets'
    params = {
        'vs_currency': 'usd',
        'order': 'market_cap_desc',
        'per_page': 100,
        'page': 1
    }
    
    try:
        response = requests.get(url, params=params, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        # Add timestamp
        timestamp = datetime.now().isoformat()
        for coin in data:
            coin['ingestion_timestamp'] = timestamp
        
        return data
    
    except requests.exceptions.RequestException as e:
        print(f"❌ Error fetching data: {e}")
        return None

def store_raw_data(bucket_name, data):
    """Store raw JSON data in S3."""
    
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    key = f"raw-data/crypto-{timestamp}.json"
    
    s3.put_object(
        Bucket=bucket_name,
        Key=key,
        Body=json.dumps(data),
        ContentType='application/json'
    )
    
    print(f"✅ Stored raw data: s3://{bucket_name}/{key}")
    return key

def lambda_handler_ingestion(event, context):
    """Lambda function to ingest crypto data."""
    
    bucket_name = os.environ['RAW_DATA_BUCKET']
    
    # Fetch data
    data = fetch_crypto_data()
    
    if data:
        # Store in S3
        key = store_raw_data(bucket_name, data)
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Data ingested successfully',
                's3_key': key,
                'records': len(data)
            })
        }
    else:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to fetch data'})
        }
```

## Step 2: Transformation (The Layer Problem)

Lambda doesn't include Pandas by default. We need to use a Lambda Layer:

```python
import json
import os
from decimal import Decimal
import boto3

# Note: This requires AWS Data Wrangler layer
# Layer ARN: arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python311:1

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

def lambda_handler_transform(event, context):
    """Transform crypto data and load into DynamoDB."""
    
    bucket_name = os.environ['RAW_DATA_BUCKET']
    table_name = os.environ['DYNAMODB_TABLE']
    
    # Get the S3 object from the event
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        # Download from S3
        response = s3.get_object(Bucket=bucket, Key=key)
        raw_data = json.loads(response['Body'].read())
        
        # Transform using Pandas (if layer is available)
        # For this example, we'll do manual transformation
        transformed_data = transform_crypto_data(raw_data)
        
        # Load into DynamoDB
        load_to_dynamodb(table_name, transformed_data)
    
    return {'statusCode': 200}

def transform_crypto_data(raw_data):
    """Transform and calculate volatility metrics."""
    
    transformed = []
    
    for coin in raw_data:
        # Calculate 24h price change percentage
        price_change_24h = coin.get('price_change_percentage_24h', 0)
        
        # Calculate volatility (simplified)
        high_24h = coin.get('high_24h', coin['current_price'])
        low_24h = coin.get('low_24h', coin['current_price'])
        volatility = ((high_24h - low_24h) / coin['current_price']) * 100
        
        item = {
            'currency': coin['symbol'].upper(),
            'timestamp': int(datetime.fromisoformat(coin['ingestion_timestamp']).timestamp()),
            'price': Decimal(str(coin['current_price'])),
            'market_cap': Decimal(str(coin['market_cap'])),
            'volume_24h': Decimal(str(coin['total_volume'])),
            'price_change_24h': Decimal(str(price_change_24h)),
            'volatility': Decimal(str(volatility)),
            'rank': coin['market_cap_rank']
        }
        
        transformed.append(item)
    
    return transformed

def load_to_dynamodb(table_name, items):
    """Load transformed data into DynamoDB."""
    
    table = dynamodb.Table(table_name)
    
    with table.batch_writer() as batch:
        for item in items:
            batch.put_item(Item=item)
    
    print(f"✅ Loaded {len(items)} records into {table_name}")
```

## Step 3: Complete Pipeline Setup

Here's a script to set up the entire pipeline:

```python
def setup_etl_pipeline():
    """Set up the complete ETL pipeline."""
    
    # Create S3 bucket for raw data
    s3 = boto3.client('s3')
    bucket_name = 'crypto-etl-raw-data'
    
    try:
        s3.create_bucket(Bucket=bucket_name)
        print(f"✅ Created bucket: {bucket_name}")
    except s3.exceptions.BucketAlreadyExists:
        print(f"Bucket {bucket_name} already exists")
    
    # Create DynamoDB table
    dynamodb = boto3.resource('dynamodb')
    table = create_table('crypto-prices')
    
    # Create Lambda functions (code from previous steps)
    # Create S3 trigger (code from previous post)
    
    print("✅ ETL pipeline setup complete!")
```

## You Have Built a Professional-Grade Data Pipeline

This project demonstrates:
- API integration
- Event-driven architecture
- Data transformation
- NoSQL database design
- Serverless computing

This is exactly the kind of project that gets you hired. It solves a real problem, uses modern AWS services, and demonstrates end-to-end system design.

In the next post, we'll shift to security automation, building an automated defense system with GuardDuty.

