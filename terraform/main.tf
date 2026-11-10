provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "landing_zone_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "Secure-LandingZone-VPC"
    Environment = "Production"
    Compliance  = "CIS-Benchmark"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.landing_zone_vpc.id

  tags = {
    Name = "Default-SG-Restricted"
  }
}

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