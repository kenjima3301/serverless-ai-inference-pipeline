variable "env" {
  description = "Name of environment"
  type        = string
}

variable "bucket_name" {
  type    = string
  default = "ai-upload-images"
}

variable "queue_name" {
  type    = string
  default = "ai-image-queue"
}
