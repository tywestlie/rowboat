variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name, used for resource naming/tagging"
  type        = string
  default     = "rowboat"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "rowboat_production"
}

variable "db_username" {
  description = "Master DB username"
  type        = string
  default     = "rowboat"
}

variable "rails_master_key" {
  description = "Rails master key for decrypting credentials"
  type        = string
  sensitive   = true
}

variable "anthropic_api_key" {
  description = "Anthropic API key for the AI query feature"
  type        = string
  sensitive   = true
}

variable "ai_access_code" {
  description = "Shared access code gating the AI query feature"
  type        = string
  sensitive   = true
}

variable "github_repo" {
  description = "GitHub repo in owner/name format, for OIDC trust scoping"
  type        = string
}