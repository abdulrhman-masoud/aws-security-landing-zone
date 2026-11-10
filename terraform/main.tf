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

# تقييد الـ Default Security Group بالكامل
resource "aws_default_security_group" "landing_zone_default_sg" {
  vpc_id = aws_vpc.landing_zone_vpc.id

  tags = {
    Name = "LandingZone-Default-SG-Restricted"
  }
}

# تفعيل VPC Flow Logs إلى CloudWatch
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/landing-zone-flow-logs"
  retention_in_days = 365
  kms_key_id        = data.aws_kms_alias.cloudwatch_logs.target_key_arn
}

data "aws_kms_alias" "cloudwatch_logs" {
  name = "alias/aws/logs"
}

resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "LandingZone-VPCFlowLogs-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "LandingZone-VPCFlowLogs-Policy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc_flow_logs" {
  vpc_id               = aws_vpc.landing_zone_vpc.id
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn
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