import json, boto3, os

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])
    
    # Lấy request_id từ query parameter (VD: /result?request_id=abc.jpg)
    query_params = event.get('queryStringParameters') or {}
    request_id = query_params.get('request_id')
    
    if not request_id:
        return {"statusCode": 400, "body": json.dumps({"error": "Thiếu tham số request_id"})}
        
    response = table.get_item(Key={'request_id': request_id})
    item = response.get('Item')
    
    if not item:
        return {"statusCode": 202, "body": json.dumps({"status": "PENDING", "message": "Đang xử lý..."})}
        
    return {"statusCode": 200, "body": json.dumps({"status": "SUCCESS", "result": item.get('result'), "drug_code": item.get('drug_code', 'N/A')})}