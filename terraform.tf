terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.57.1"
      #      version = "~> 6.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
provider "time" {}
