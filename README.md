# 🚀 Serverless Event-Driven MLOps Pipeline on AWS

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)

## 📌 Tổng quan dự án (Project Overview)
Một hệ thống tự động hóa hoàn toàn (End-to-End) để triển khai mô hình AI Phân loại thuốc. Hệ thống sử dụng kiến trúc Event-Driven Serverless giúp xử lý hàng ngàn ảnh cùng lúc mà không bị quá tải, tối ưu chi phí (FinOps) thông qua mô hình Pay-per-request và bảo mật cao với AWS IAM Least Privilege.

Toàn bộ hạ tầng được viết dưới dạng mã (IaC) bằng Terraform và triển khai qua GitHub Actions CI/CD Pipeline.

## 🏗️ Kiến trúc hệ thống (Architecture Flow)

Hệ thống được chia làm 2 luồng chính:

**1. Luồng Giao tiếp Client (Synchronous API):**
- `GET /upload-url`: Client gọi API Gateway -> Lambda trả về S3 Presigned URL. Client dùng Presigned URL để PUT ảnh trực tiếp lên S3 (vượt qua giới hạn payload 10MB của API Gateway).
- `GET /result`: Client Long-polling API Gateway -> Lambda truy vấn DynamoDB để lấy kết quả AI.

**2. Luồng Xử lý AI (Asynchronous Event-Driven):**
- S3 Bucket nhận ảnh -> Phát sự kiện (Event Trigger) vào SQS Queue (Đóng vai trò giảm xóc cho hệ thống).
- Lambda Processing Core (chạy Docker Container chứa AI Model từ ECR) kéo message từ SQS.
- Xử lý nhận diện ảnh và ghi kết quả vào DynamoDB.

## 📁 Cấu trúc Module Terraform (Infrastructure as Code)
Dự án áp dụng triết lý Modular Design, cô lập rủi ro giữa các tài nguyên:
- `database`: DynamoDB (On-Demand Capacity).
- `container_registry`: AWS ECR (Kích hoạt Scan on push).
- `upload_trigger`: S3 Bucket, SQS Queue và S3 Event Notification.
- `processing_core`: Lambda (Docker Image) xử lý AI + IAM Role.
- `client_api`: HTTP API Gateway v2 + 2 Lambdas (dùng `archive_file` nén code tự động).

## 🔄 CI/CD Pipeline (GitOps Workflow)
Pipeline giải quyết lỗi Circular Dependency giữa ECR và Lambda thông qua 3 Jobs nối tiếp:
1. **Job 1 (ECR Bootstrap):** Terraform sử dụng cờ `-target` để chỉ khởi tạo kho chứa ECR (Kho rỗng).
2. **Job 2 (Build & Push):** Đóng gói ứng dụng AI thành Docker Image, đánh tag bằng Short Git SHA và push lên ECR.
3. **Job 3 (Full Infrastructure Deploy):** Terraform triển khai toàn bộ hạ tầng còn lại (S3, SQS, DynamoDB, API Gateway) và liên kết Lambda với Image Tag mới nhất từ Job 2.

## 🔒 Quản lý chi phí & Bảo mật (FinOps & DevSecOps)
- **Concurrency Limit:** Giới hạn số lượng Lambda AI chạy song song để chống nghẽn DynamoDB và kiểm soát hóa đơn AWS.
- **IAM Least Privilege:** Các policy được thiết lập chặt chẽ cho GitHub Actions Bot (chặn quyền đọc data) và các Lambda Roles.
- **Short-lived Credentials:** S3 Presigned URL chỉ sống trong 5 phút để bảo vệ bucket khỏi các cuộc tấn công.

## 📖 Hướng dẫn sử dụng API (API Documentation)

Hệ thống cung cấp 2 endpoints thông qua HTTP API Gateway để Client tương tác an toàn với Cloud.

### 1. Xin cấp quyền Upload (Presigned URL)
- **Endpoint:** `GET /upload-url`
- **Mô tả:** Trả về một URL tạm thời (sống trong 5 phút) để Client đẩy file trực tiếp lên S3.
- **Response (200 OK):**
  ```json
  {
    "upload_url": "https://ai-upload-images-dev...s3.amazonaws.com/uuid.jpg?X-Amz-Signature=...",
    "request_id": "uuid.zip",
    "message": "Use upload_url to PUT file as binary body. Expires in 5 minutes."
  }
  ```

### 2. Upload dữ liệu phân loại (Thực hiện bởi Client)
- **Method:** `PUT`
- **URL:** Là `upload_url` nhận được từ bước 1.
- **Headers:** `Content-Type: application/zip` *(Bắt buộc, nếu thiếu AWS sẽ báo lỗi Signature).*
- **Body:** File zip dạng Binary (chứa 2 ảnh chụp ở các góc độ khác nhau của thuốc).

### 3. Lấy kết quả AI (Long Polling)
- **Endpoint:** `GET /result?request_id={request_id}`
- **Mô tả:** Client gọi liên tục (mỗi 2-3s) bằng `request_id` nhận được ở Bước 1 để lấy kết quả.
- **Response - Đang xử lý (202 Accepted):**
  ```json
  {
    "status": "PENDING", 
    "message": "Đang xử lý..."
  }
  ```
- **Response - Hoàn thành (200 OK):**
  ```json
  {
    "status": "SUCCESS", 
    "result": "Panadol (Confidence: 99%)",
    "drug_code": "VN-12345-19"
  }
  ```

