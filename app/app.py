import json
import io
import urllib.parse
import os
import boto3
import zipfile
import numpy as np
import onnxruntime as ort
from PIL import Image
import cv2

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])
ort_session = ort.InferenceSession("model.onnx")

with open('class_info.json', 'r', encoding='utf-8') as f:
    idx_to_info = json.load(f)

def apply_clahe_rgb(img_array):
    lab = cv2.cvtColor(img_array, cv2.COLOR_RGB2LAB)
    l_channel, a_channel, b_channel = cv2.split(lab)

    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    cl = clahe.apply(l_channel)

    merged = cv2.merge((cl, a_channel, b_channel))
    return cv2.cvtColor(merged, cv2.COLOR_LAB2RGB)

def process_image_bytes(img_bytes):
    """Đọc ảnh từ RAM (bytes)"""
    img = Image.open(io.BytesIO(img_bytes)).convert('RGB')
    img.thumbnail((800, 800), Image.Resampling.LANCZOS)
    
    img_arr = np.array(img)
    img_arr = apply_clahe_rgb(img_arr)
    
    img_clahe_pil = Image.fromarray(img_arr)
    img_resized = img_clahe_pil.resize((160, 160), Image.Resampling.BILINEAR)
    img_arr_final = np.array(img_resized).astype(np.float32) / 255.0
    
    mean = np.array([0.485, 0.456, 0.406])
    std = np.array([0.229, 0.224, 0.225])
    img_arr_final = (img_arr_final - mean) / std
    
    img_arr_final = np.transpose(img_arr_final, (2, 0, 1))
    return img_arr_final

def lambda_handler(event, context):
    for sqs_record in event.get('Records', []):
        try:
            s3_event = json.loads(sqs_record['body'])
            
            if 'Event' in s3_event and s3_event['Event'] == 's3:TestEvent':
                continue
                
            for s3_record in s3_event.get('Records', []):
                bucket_name = s3_record['s3']['bucket']['name']
                object_key = urllib.parse.unquote_plus(s3_record['s3']['object']['key'])
                
                print(f"Bắt đầu xử lý file: s3://{bucket_name}/{object_key}")
                
                # Tải file ZIP từ S3
                response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
                zip_bytes = response['Body'].read()
                
                valid_images = []
                
                with zipfile.ZipFile(io.BytesIO(zip_bytes)) as z:
                    for filename in z.namelist():
                        if filename.endswith('/') or '__MACOSX' in filename:
                            continue
                        if filename.lower().endswith(('.jpg', '.jpeg', '.png')):
                            valid_images.append(z.read(filename))
                            if len(valid_images) == 2:
                                break
                            
                del zip_bytes
                if len(valid_images) < 2:
                    print(f"[LỖI DỮ LIỆU] File ZIP thiếu ảnh hợp lệ (cần 2 ảnh, tìm thấy {len(valid_images)})")
                    continue

                arr_top = process_image_bytes(valid_images[0])
                arr_side = process_image_bytes(valid_images[1])

                views = np.stack([arr_top, arr_side])
                views = np.expand_dims(views, axis=0)

                # Chạy Inference
                ort_inputs = {'input_views': views.astype(np.float32)}
                outputs = ort_session.run(None, ort_inputs)
                
                pm = outputs[0][0] 
                exp_pm = np.exp(pm - np.max(pm))
                probabilities = exp_pm / np.sum(exp_pm)
                
                top_class = int(np.argmax(probabilities))
                top_prob = float(probabilities[top_class])
                drug_info = idx_to_info.get(str(top_class), {"name": f"Class {top_class}", "drug_code": "N/A"})
                drug_name = drug_info["name"]
                drug_code = drug_info["drug_code"]

                # 6. Ghi kết quả vào DynamoDB
                result_text = f"{drug_name} (Confidence: {top_prob*100:.2f}%)"
                
                table.put_item(Item={
                    'request_id': object_key,
                    'status': 'SUCCESS',
                    'result': result_text,
                    'drug_code': drug_code
                })
                
                print(f"Hoàn tất! Đã lưu DynamoDB: {object_key} -> {result_text}")

        except Exception as e:
            print(f"[LỖI HỆ THỐNG] Lỗi xử lý SQS message: {str(e)}")
            raise e

    return {
        'statusCode': 200,
        'body': json.dumps('Xử lý SQS và lưu kết quả thành công!')
    }