# Serverless AI Inference Pipeline 🚀

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![PyTorch](https://img.shields.io/badge/PyTorch-%23EE4C2C.svg?style=for-the-badge&logo=PyTorch&logoColor=white)

## 📌 Tổng quan dự án (Project Overview)
Dự án xây dựng hạ tầng Cloud hoàn toàn tự động (IaC) để triển khai mô hình AI Phân loại thuốc (CNN + Transformer). 
Hệ thống sử dụng kiến trúc **Event-Driven Serverless** giúp xử lý hàng ngàn ảnh cùng lúc mà không bị quá tải, đồng thời tối ưu chi phí (FinOps) thông qua mô hình Pay-as-you-go của AWS.

## 🏗️ Kiến trúc hệ thống (Architecture)
*(Sẽ chèn hình ảnh Architecture Diagram vào đây sau)*

**Luồng dữ liệu (Data Flow):**
1. Người dùng tải ảnh lên **Amazon S3** (thông qua Presigned URL).
2. S3 kích hoạt sự kiện, gửi thông điệp vào **Amazon SQS** Queue (đóng vai trò giảm xóc/buffer).
3. **AWS Lambda** (chạy Docker Container chứa AI Model) pull message từ SQS để suy luận.
4. Kết quả nhận diện được lưu trữ bền vững tại **Amazon DynamoDB**.

## 📁 Cấu trúc Module (Infrastructure as Code)
Dự án áp dụng triết lý thiết kế Module độc lập, tránh Circular Dependency:
- `container_registry`: Khởi tạo AWS ECR (Tích hợp Trivy Image Scanning).
- `database`: Cấu hình DynamoDB (On-Demand Capacity).
- `upload_trigger`: Cấu hình S3 và SQS Queue nối tiếp.
- `processing_core`: Cấu hình AWS Lambda (Container Image) và IAM Roles (Least Privilege).

## 🚀 Hướng dẫn triển khai (Deployment)

### Yêu cầu cài đặt (Prerequisites)
- Terraform >= 1.5.0
- AWS CLI đã cấu hình credentials.
- Docker & Python 3.10 (Dành cho việc test local).

### Các bước chạy thực tế
1. **Khởi tạo hạ tầng lưu trữ (Stateful):**
   ```bash
   cd infra/envs/dev
   terraform init
   terraform apply -target=module.container_registry -target=module.database
   ```
2. **Build & Push AI Model lên ECR:** (Được quản lý tự động qua GitHub Actions).
3. **Triển khai hạ tầng xử lý (Stateless):**
   ```bash
   terraform apply
   ```

## 🔒 Quản lý chi phí & Bảo mật (FinOps & DevSecOps)
- Giới hạn Concurrency của Lambda để chống sập Database và kiểm soát hóa đơn AWS.
- Quét lỗ hổng tự động (Scan on push) trên ECR.
- Quản lý State Terraform an toàn trên S3 Backend + DynamoDB State Locking.

