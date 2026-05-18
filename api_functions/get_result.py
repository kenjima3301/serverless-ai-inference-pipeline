import json, boto3, os

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])
    
    # Lấy image_id từ query parameter (VD: /result?image_id=abc.jpg)
    query_params = event.get('queryStringParameters') or {}
    image_id = query_params.get('image_id')
    
    if not image_id:
        return {"statusCode": 400, "body": json.dumps({"error": "Thiếu tham số image_id"})}
        
    response = table.get_item(Key={'image_id': image_id})
    item = response.get('Item')
    
    if not item:
        return {"statusCode": 202, "body": json.dumps({"status": "PENDING", "message": "Đang xử lý..."})}
        
    return {"statusCode": 200, "body": json.dumps({"status": "SUCCESS", "result": item.get('result')})}