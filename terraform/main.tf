provider "aws" {
  region = "us-east-1"
}

# لجلب رقم الحساب الحالي أوتوماتيك لربطه بأمان في السياسة
data "aws_caller_identity" "current" {}

# 1. إنشاء الـ VPC مع إعدادات الأمان
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

# 2. تقييد الـ Default Security Group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.landing_zone_vpc.id

  ingress = []
  egress  = []

  tags = {
    Name = "Default-SG-Restricted"
  }
}

# 3. مفتاح تشفير KMS مع Policy آمنة وخالية من Wildcard Principal لتجاوز الفحص
resource "aws_kms_key" "logs_key" {
  description             = "KMS key for CloudWatch logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs Encryption"
        Effect = "Allow"
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# 4. CloudWatch Log Group مع الاحتفاظ باللوجات لمدة 365 يوم وتشفرها بـ KMS
resource "aws_cloudwatch_log_group" "flow_log_group" {
  name              = "/aws/vpc/landing-zone-flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.logs_key.arn
}

# 5. صلاحيات الـ IAM للـ Flow Logs
resource "aws_iam_role" "flow_log_role" {
  name = "VPCFlowLogExecutionRole"

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

# 6. IAM Policy مقيدة بدقة على الـ Log Group
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "VPCFlowLogPolicy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.flow_log_group.arn}:*"
      }
    ]
  })
}

# 7. ربط الـ Flow Log بالـ VPC
resource "aws_flow_log" "main_vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.landing_zone_vpc.id
}

# 8. دور التدقيق الأمني (Least Privilege IAM Role)
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