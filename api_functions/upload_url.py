import json, boto3, os, uuid

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = os.environ['S3_BUCKET']
    # Tạo tên file ngẫu nhiên để không bị trùng lặp
    file_name = f"{uuid.uuid4()}.jpg" 
    
    # Tạo Presigned URL (Sống trong 5 phút = 300 giây)
    presigned_url = s3_client.generate_presigned_url(
        'put_object',
        Params={'Bucket': bucket_name, 'Key': file_name, 'ContentType': 'image/jpeg'},
        ExpiresIn=300
    )
    
    return {
        "statusCode": 200,
        "body": json.dumps({
            "upload_url": presigned_url,
            "image_id": file_name,
            "message": "Dùng upload_url để PUT file ảnh lên bằng Binary body. Hạn dùng 5 phút."
        })
    }