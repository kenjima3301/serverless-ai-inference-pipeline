variable "env" {
  description = "Name of environment"
  type        = string
}

variable "table_name" {
  description = "Base name of DynamoDB table"
  type        = string
  default     = "ai-inference-results"
}

variable "tags" {
  description = "Attaching tags to resources makes it easier to manage costs"
  type        = map(string)
  default     = {}
}
