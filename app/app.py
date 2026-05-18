import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    # Extract the S3 bucket and object key from the event
    for record in event['Records']:
        body = json.loads(record['body'])
        if 'Records' in body:
            s3_event = body['Records'][0]
            bucket_name = s3_event['s3']['bucket']['name']
            file_key = s3_event['s3']['object']['key']

            print(f"[MOCK AI] Processing image: {file_key} from bucket {bucket_name}")

            # Mock AI inference result
            table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])
            table.put_item(Item={
                'image_id': file_key,
                'result': 'Panadol (Mock Confidence: 99%)'
            })

    return {"statusCode": 200, "body": "Success"}        