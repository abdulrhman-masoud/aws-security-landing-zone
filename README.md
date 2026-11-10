# AWS Security Landing Zone & IaC Compliance

A secure-by-design cloud infrastructure project implementing Infrastructure as Code (IaC) with automated DevSecOps security scanning.

## 🚀 Architecture & Overview
This project sets up a foundational AWS Landing Zone focusing on secure networking (VPC) and Least-Privilege access controls using Terraform, adhering strictly to security best practices and compliance frameworks.

## 🛠️ Tech Stack
- **Cloud Provider:** AWS (Simulated & Managed via Terraform)
- **Infrastructure as Code (IaC):** Terraform
- **Security & Compliance Testing:** Checkov (CIS Benchmarks)
- **CI/CD Automation:** GitHub Actions

## 🛡️ Security Pipelines (DevSecOps)
The repository includes an automated GitHub Actions workflow (`.github/workflows/checkov.yml`) that triggers on every push to scan the Terraform code for security misconfigurations before deployment.