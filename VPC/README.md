# VPC Module

This module creates a **VPC** with multi-AZ subnets, optional NAT Gateway, optional Elastic IP, and optional EC2/DB security groups. It is reusable in any Terraform project.

---

## 🛠️ Required Inputs

| Name            | Description                          | Type        | Default | Required |
|-----------------|--------------------------------------|------------|---------|----------|
| `vpc_name`       | Name of the VPC                       | string     | n/a     | yes      |
| `vpc_cidr`       | CIDR block of the VPC                 | string     | n/a     | yes      |
| `public_subnets` | List of public subnet CIDRs           | list(string)| n/a    | yes      |
| `private_subnets`| List of private subnet CIDRs          | list(string)| n/a    | yes      |
| `azs`            | List of availability zones (multi-AZ)| list(string)| n/a    | yes      |

---

## ⚙️ Optional Inputs

| Name                | Description                                    | Type       | Default |  
|--------------------|------------------------------------------------|-----------|---------|  
| `enable_nat_gateway` | Enable NAT Gateway and private route table    | bool      | false   |  
| `create_eip`         | Create Elastic IP for NAT Gateway             | bool      | true    |  
| `create_ec2_sg`      | Create EC2 Security Group                     | bool      | true    |  
| `allowed_ssh_cidr`   | CIDR blocks allowed to SSH into EC2          | list(string)| ["0.0.0.0/0"] |  
| `allowed_http_cidr`  | CIDR blocks allowed for HTTP access          | list(string)| ["0.0.0.0/0"] |  
| `db_port`            | Port for DB Security Group                     | number    | 3306    |  

---

## 📤 Outputs

| Name                 | Description                                   |  
|---------------------|-----------------------------------------------|  
| `vpc_id`            | ID of the created VPC                          |  
| `public_subnet_ids` | List of public subnet IDs                       |  
| `private_subnet_ids`| List of private subnet IDs                      |  
| `ec2_sg_id`         | EC2 Security Group ID (optional)               |  
| `db_sg_id`          | DB Security Group ID (optional)                |  
| `nat_gateway_id`    | NAT Gateway ID (optional)                      |  
| `eip_id`            | Elastic IP ID (optional)                       |  

---

## 🔧 Example Usage

```hcl
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
