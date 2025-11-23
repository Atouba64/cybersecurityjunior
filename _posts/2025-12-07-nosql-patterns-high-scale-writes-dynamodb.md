---
layout: post
title: "NoSQL Patterns: High-Scale Writes to DynamoDB"
date: 2025-11-19 14:00:00 -0400
categories: [Database]
tags: [DynamoDB, NoSQL, DatabaseDesign, Python, BigData]
excerpt: "Our data is extracted and transformed. Now it needs a home. While S3 is great for storage, it's terrible for querying real-time applications."
---

Our data is extracted and transformed. Now it needs a home. While S3 is great for storage, it is terrible for querying real-time applications. For that, we need Amazon DynamoDB, a hyperscale NoSQL database. However, simply looping through our data and writing one row at a time is inefficient and slow. In this post, we will master the batch_writer interface in Boto3 to load thousands of records in seconds. We will also tackle the infamous 'Float vs. Decimal' error that trips up almost every Python developer using DynamoDB for the first time.

## SQL vs. NoSQL: Choosing the Right Tool

Before diving in, let's understand when to use DynamoDB vs. RDS:

**Use RDS (PostgreSQL/MySQL) when:**
- You need complex queries with joins
- You have relational data
- You need ACID transactions across multiple tables
- You have predictable, moderate traffic

**Use DynamoDB when:**
- You need millisecond latency
- You have high, unpredictable traffic
- You need infinite horizontal scaling
- You're building serverless applications

For startups, DynamoDB's pay-per-request model means $0 when idle, making it ideal for early-stage applications.

## Data Modeling: Partition Key vs. Sort Key

DynamoDB uses a two-key system:

```python
import boto3
from decimal import Decimal
import json

dynamodb = boto3.resource('dynamodb')

def create_table(table_name):
    """Create a DynamoDB table."""
    
    table = dynamodb.create_table(
        TableName=table_name,
        KeySchema=[
            {
                'AttributeName': 'currency',
                'KeyType': 'HASH'  # Partition key
            },
            {
                'AttributeName': 'timestamp',
                'KeyType': 'RANGE'  # Sort key
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'currency',
                'AttributeType': 'S'  # String
            },
            {
                'AttributeName': 'timestamp',
                'AttributeType': 'N'  # Number
            }
        ],
        BillingMode='PAY_PER_REQUEST'  # On-demand pricing
    )
    
    # Wait for table to be created
    table.wait_until_exists()
    
    print(f"✅ Created table: {table_name}")
    return table
```

### Understanding Keys

- **Partition Key (HASH)**: Determines which partition stores the item
- **Sort Key (RANGE)**: Orders items within a partition

Example: `currency='BTC'` and `timestamp=1640995200` allows you to query all Bitcoin prices sorted by time.

## Efficient Writing: Batching

The anti-pattern is writing items one at a time:

```python
# BAD: Slow and expensive
table = dynamodb.Table('crypto-prices')
for item in data:
    table.put_item(Item=item)  # One API call per item
```

The solution is batch writing:

```python
def bulk_write_items(table_name, items):
    """Efficiently write multiple items to DynamoDB."""
    
    table = dynamodb.Table(table_name)
    
    # Use batch_writer for automatic buffering and retries
    with table.batch_writer() as batch:
        for item in items:
            batch.put_item(Item=item)
    
    print(f"✅ Wrote {len(items)} items to {table_name}")
```

### How batch_writer Works

The `batch_writer` context manager:
- Automatically batches items (up to 25 per request)
- Handles retries for throttled requests
- Manages unprocessed items
- Reduces API calls by 25x

## The "Decimal" Problem

This is where most Python developers get stuck. DynamoDB requires numeric types to be `Decimal`, not `float`:

```python
# This will FAIL
item = {
    'currency': 'BTC',
    'timestamp': 1640995200,
    'price': 45000.50  # float - will cause error!
}

# This will WORK
from decimal import Decimal

item = {
    'currency': 'BTC',
    'timestamp': 1640995200,
    'price': Decimal('45000.50')  # Decimal - correct!
}
```

### Solution: JSON Loading with Decimal

When loading JSON data, use a custom parser:

```python
def load_json_with_decimal(json_string):
    """Load JSON, converting floats to Decimals."""
    
    def decimal_default(obj):
        if isinstance(obj, float):
            return Decimal(str(obj))
        raise TypeError
    
    return json.loads(json_string, parse_float=Decimal)
```

Or when reading from a file:

```python
import json
from decimal import Decimal

# Read JSON file
with open('data.json', 'r') as f:
    data = json.load(f, parse_float=Decimal)
```

## Complete Example: Loading Crypto Data

Here's a complete example that loads cryptocurrency data:

```python
def load_crypto_data_to_dynamodb(table_name, data_file):
    """Load cryptocurrency price data into DynamoDB."""
    
    table = dynamodb.Table(table_name)
    
    # Load and parse data
    with open(data_file, 'r') as f:
        data = json.load(f, parse_float=Decimal)
    
    # Prepare items
    items = []
    for record in data:
        item = {
            'currency': record['symbol'],
            'timestamp': int(record['timestamp']),
            'price': Decimal(str(record['price'])),
            'volume': Decimal(str(record['volume'])),
            'market_cap': Decimal(str(record['market_cap']))
        }
        items.append(item)
    
    # Batch write
    with table.batch_writer() as batch:
        for item in items:
            batch.put_item(Item=item)
    
    print(f"✅ Loaded {len(items)} records into {table_name}")
```

## Querying Data

Once data is loaded, querying is straightforward:

```python
def query_crypto_prices(table_name, currency, start_time, end_time):
    """Query cryptocurrency prices for a time range."""
    
    table = dynamodb.Table(table_name)
    
    response = table.query(
        KeyConditionExpression=Key('currency').eq(currency) & 
                              Key('timestamp').between(start_time, end_time)
    )
    
    return response['Items']
```

## Preparing for the Data Pipeline

You've mastered:
- Efficient batch writing
- Handling Decimal types
- Data modeling with partition and sort keys

This foundation is essential for the ETL pipeline we'll build in the next post—the capstone project that ties everything together.

