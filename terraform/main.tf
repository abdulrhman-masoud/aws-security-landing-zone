provider "aws" {
  region = "us-east-1"
}

# محاكاة لإنشاء VPC آمنة للـ Landing Zone
resource "aws_vpc" "landing_zone_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "Secure-LandingZone-VPC"
    Environment = "Sandbox"
    Compliance  = "CIS-Benchmark"
  }
}

# مثال على Least-Privilege IAM Role للأمان
resource "aws_iam_role" "secure_audit_role" {
  name = "LandingZone-Audit-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    SecurityControl = "LeastPrivilege"
  }
}