# VPC Module

This module creates a **VPC with public and private subnets**, optional NAT Gateway, and security group rules. It is reusable and configurable for different environments.

---
## Features

* Create a VPC with your desired CIDR block
* Public and private subnets across multiple availability zones
* Optional NAT Gateway with private route tables
* Optional Elastic IP for NAT Gateway
* Optional EC2 Security Group for instances
* Optional DB Security Group for databases

## 🛠️ Required Inputs

* vpc_name – Name of the VPC
* vpc_cidr – CIDR block for the VPC
* public_subnets – List of public subnet CIDRs
* private_subnets – List of private subnet CIDRs
* azs – Availability zones for subnets (multi-AZ)
* enable_nat_gateway – Enable NAT Gateway and private route table (true/false)
* create_eip – Create Elastic IP for NAT (true/false)
* create_ec2_sg – Create EC2 security group (true/false)
* allowed_ssh_cidr – List of CIDRs allowed to SSH into EC2
* allowed_http_cidr – List of CIDRs allowed to access HTTP on EC2
* db_port – Port for database security group (default: 3306)

---

## 📤 Outputs

> Include outputs from your module. Example:

| Name                 | Description                           |
|----------------------|---------------------------------------|
| `vpc_id`             | ID of the created VPC                  |
| `public_subnet_ids`  | List of public subnet IDs              |
| `private_subnet_ids` | List of private subnet IDs             |
| `nat_gateway_ids`    | List of NAT Gateway IDs (if enabled)  |
| `security_group_ids` | List of security group IDs             |

---

## 🔧 Example Usage

module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "my-vpc"
  vpc_cidr           = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.3.0/24", "10.0.4.0/24"]
  azs                = ["us-east-1a", "us-east-1b"]
  enable_nat_gateway = true
  create_eip         = true
  create_ec2_sg      = true

  allowed_ssh_cidr   = ["YOUR_IP/32"]
  allowed_http_cidr  = ["0.0.0.0/0"]
  db_port            = 3306
}