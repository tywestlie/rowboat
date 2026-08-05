terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
        source  = "hashicorp/random"
        version = "~> 3.6"
    }
  }

  # Remote state (we'll set this up once the basics are working)
  # backend "s3" {
  #   bucket         = "rowboat-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}