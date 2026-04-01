# EC2 Module

This module creates an **AWS EC2 instance** with optional user data and SSM support. It is designed to be reusable in any Terraform project.

---

## 🛠️ Required Inputs

| Name       | Description                       | Type   | Default | Required |
|------------|-----------------------------------|--------|---------|----------|
| `ami_id`   | AMI ID to use for EC2 instance    | string | n/a     | yes      |
| `subnet_id`| Subnet ID to launch EC2 in        | string | n/a     | yes      |
| `vpc_sg_ids` | List of security group IDs for EC2 | list(string) | n/a | yes |

---

## ⚙️ Optional Inputs

| Name           | Description                                   | Type   | Default       |
|----------------|-----------------------------------------------|--------|---------------|
| `instance_name`| Name of the EC2 instance                      | string | "web-server"  |
| `instance_type`| EC2 instance type                             | string | "t2.micro"    |
| `key_name`     | Key pair name for SSH access                  | string | "" (none)     |
| `user_data`    | Optional user_data script                     | string | "" (none)     |
| `enable_ssm`   | Attach SSM IAM role for EC2 management       | bool   | false         |

---

## 📤 Outputs

> Include any outputs you have defined in your module. For example:

| Name           | Description                       |
|----------------|-----------------------------------|
| `instance_id`  | ID of the created EC2 instance    |
| `public_ip`    | Public IP of the instance         |
| `private_ip`   | Private IP of the instance        |

---

## 🔧 Example Usage

```hcl
module "ec2" {
  source       = "./modules/ec2"
  ami_id       = "ami-0123456789abcdef0"
  subnet_id    = "subnet-0abc12345def67890"
  vpc_sg_ids   = ["sg-0a1b2c3d4e5f67890"]
  instance_name = "my-app-server"
  key_name      = "my-keypair"
  enable_ssm    = true
  user_data     = file("setup.sh")
}