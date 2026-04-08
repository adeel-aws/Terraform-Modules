# EC2 Module

This module creates an **AWS EC2 instance** with optional SSM, user_data, key_name, and environment-aware naming.  
It supports multiple security groups passed dynamically (e.g., from a VPC module).

---

## 🛠️ Required Inputs

| Name     | Description               | Type   | Default | Required |
|----------|---------------------------|--------|---------|----------|
| `ami_id` | AMI ID to use for EC2     | string | n/a     | yes      |

---

## ⚙️ Optional Inputs

| Name                     | Description                                         | Type           | Default       |
|--------------------------|-----------------------------------------------------|----------------|---------------|
| `instance_name`          | EC2 instance name                                   | string         | "web-server"  |
| `instance_type`          | EC2 instance type                                   | string         | "t2.micro"    |
| `subnet_id`              | Subnet ID to launch EC2 in                          | string         | null          |
| `security_group_ids`     | List of security group IDs to attach to EC2        | list(string)   | []            |
| `key_name`               | Key pair for SSH access                             | string         | ""            |
| `user_data`              | Optional user_data script                           | string         | ""            |
| `enable_ssm`             | Attach SSM IAM role                                 | bool           | false         |
| `environment`            | Environment name for naming convention (dev/prod)  | string         | "dev"         |

---

## 📤 Outputs

| Name          | Description                       |
|---------------|-----------------------------------|
| `instance_id` | ID of the created EC2 instance    |
| `public_ip`   | Public IP of the instance         |
| `private_ip`  | Private IP of the instance        |

---

## 🔧 Example Usage

```hcl
module "ec2" {
  source             = "./modules/ec2"
  ami_id             = "ami-0123456789abcdef0"
  instance_name      = "my-app-server"
  key_name           = "my-keypair"
  enable_ssm         = true
  environment        = "dev"
  user_data          = file("setup.sh")
  security_group_ids  = [
    module.vpc.ec2_sg_id,
    module.vpc.db_sg_id
  ]
}