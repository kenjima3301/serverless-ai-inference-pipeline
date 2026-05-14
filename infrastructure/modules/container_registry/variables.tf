variable "env" {
  description = "Name of environment"
  type        = string
}

variable "repo_name" {
  description = "Name of repository that stores AI models"
  type        = string
  default     = "ai-model-repo"
}

variable "tags" {
  description = "Attaching tags to resources makes it easier to manage costs"
  type        = map(string)
  default     = {}
}
