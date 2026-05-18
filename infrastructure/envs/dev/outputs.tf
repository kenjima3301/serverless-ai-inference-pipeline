output "client_api_url" {
  description = "Link API Gateway for Client to upload/get result"
  value       = module.client_api.api_endpoint
}
