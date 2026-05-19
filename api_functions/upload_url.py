import json, boto3, os, uuid

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = os.environ['S3_BUCKET']
    # Tạo tên file ngẫu nhiên để không bị trùng lặp
    file_name = f"{uuid.uuid4()}.zip" 
    
    # Tạo Presigned URL (Sống trong 5 phút = 300 giây)
    presigned_url = s3_client.generate_presigned_url(
        'put_object',
        Params={
            'Bucket': bucket_name, 
            'Key': file_name, 
            'ContentType': 'application/zip'},
        ExpiresIn=300
    )
    
    return {
        "statusCode": 200,
        "body": json.dumps({
            "upload_url": presigned_url,
            "request_id": file_name,
            "message": "Use upload_url to PUT file as binary body. Expires in 5 minutes."
        })
    }