# AWS Security Landing Zone & DevSecOps Compliance

A secure-by-design AWS cloud infrastructure project implemented using **Terraform (IaC)** and integrated with automated security compliance testing via **GitHub Actions** and **Checkov** (CIS Benchmarks).

---

## 🏗️ Architecture & Component Overview

This repository provisions a foundational, enterprise-grade AWS Landing Zone designed to prevent security misconfigurations and comply with rigorous security standards.

### 1. Network Security (Secure VPC)
* **Isolated Virtual Private Cloud (VPC):** Provisioned with a dedicated CIDR block (`10.0.0.0/16`) with DNS hostnames and resolution enabled for secure internal communication.
* **Restricted Default Security Group (`CKV2_AWS_12`):** Strictly restricted by stripping all default inbound (`ingress`) and outbound (`egress`) rules to block unauthorized traffic.

### 2. Encryption & Key Management (KMS)
* **KMS Key Rotation & Protection (`CKV2_AWS_158`):** Provisioned a customer-managed AWS KMS key with automated key rotation enabled for CloudWatch log encryption.
* **Strict Key Policy (`CKV2_AWS_64`):** Engineered a least-privilege key policy referencing the exact account root identity (`data.aws_caller_identity`) and specific AWS log service endpoints, avoiding risky wildcard principals (`AWS = "*"`).

### 3. Network Monitoring & Audit Logging
* **VPC Flow Logs (`CKV2_AWS_11`):** Capture and record all IPv4 network traffic (`traffic_type = "ALL"`) traversing the VPC interfaces.
* **Log Retention Compliance (`CKV2_AWS_338`):** Configured CloudWatch Log Group retention to **365 days** (1 year) to meet audit and compliance mandates.

### 4. Least-Privilege Identity & Access Management (IAM)
* **Scoped Execution Roles:** Created dedicated IAM roles allowing the VPC Flow Logs service to deliver log streams securely to CloudWatch.
* **Resource-Bounded IAM Policies (`CKV2_AWS_290`, `CKV2_AWS_355`):** Strictly scoped IAM write permissions directly to the target CloudWatch log group ARN (`Resource = "${aws_cloudwatch_log_group.flow_log_group.arn}:*"`), eliminating dangerous wildcard resource permissions.

---

## 🛠️ Tech Stack & Tools

* **Cloud Infrastructure:** Amazon Web Services (VPC, KMS, CloudWatch Logs, IAM)
* **Infrastructure as Code (IaC):** Terraform
* **DevSecOps / CI/CD:** GitHub Actions
* **Security & Static Code Analysis:** Checkov (CIS Benchmarks)

---

## 🔄 Automated DevSecOps Pipeline

The repository features an automated GitHub Actions pipeline (`.github/workflows/checkov.yml`) that triggers on every `push` and `pull_request` to the `main` branch. 

### Scanning Process:
1. **Source Code Checkout:** Pulls the latest Terraform configuration files (`main.tf`).
2. **Static Security Analysis:** Executes Checkov to scan IaC files against AWS CIS Benchmarks.
3. **Compliance Verification:** Ensures 0 critical or high-risk misconfigurations exist before code can be merged or deployed.

---

## 📂 Project Structure

```text
aws-security-landing-zone/
├── .github/
│   └── workflows/
│       └── checkov.yml      # CI/CD Security Pipeline definition
├── terraform/
│   └── main.tf              # Main IaC Security Infrastructure definition
├── .gitignore               # Excludes .terraform cache and state files
└── README.md                # Project documentation

![Checkov Security Scan](https://github.com/abdulrahman-masoud/aws-security-landing-zone/actions/workflows/checkov.yml/badge.svg)