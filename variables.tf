###############################################################
# variables.tf
###############################################################

variable "project_name" {
  description = "Project name — used as prefix for all resources"
  type        = string
  default     = "nodeapp"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Your domain name (managed in GoDaddy)"
  type        = string
  # e.g. "example.com"
}

variable "container_image" {
  description = "Full container image URI from DockerHub or GHCR"
  type        = string
  # e.g. "yourdockerhubuser/nodeapp:latest"
  # or   "ghcr.io/yourgithubuser/nodeapp:latest"
}


variable "redis_password" {
  description = "Auth token (password) for ElastiCache Redis — min 16 characters"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.redis_password) >= 16
    error_message = "Redis auth token must be at least 16 characters (AWS requirement)."
  }
}
