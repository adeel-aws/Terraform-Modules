# VPC Module

This module creates a production-ready AWS VPC architecture with:

* Multi-AZ public & private subnets
* Optional NAT Gateway
* Optional App, ELB, and DB Security Groups
* Secure SG-to-SG communication model (industry standard)
* Fully reusable across multiple projects

---

## 🧠 Security Design (IMPORTANT)

This module follows a production-grade architecture:

* **ELB SG** → exposes HTTP/HTTPS (80/443) to internet
* **APP SG** → only accessible from ELB SG
* **DB SG** → only accessible from APP SG

👉 No CIDR-based internal access
👉 Only security group references are used

---

## 🛠️ Required Inputs

| Name            | Description                  | Type         | Required |
| --------------- | ---------------------------- | ------------ | -------- |
| vpc_name        | Name of the VPC              | string       | yes      |
| vpc_cidr        | CIDR block of the VPC        | string       | yes      |
| public_subnets  | List of public subnet CIDRs  | list(string) | yes      |
| private_subnets | List of private subnet CIDRs | list(string) | yes      |
| azs             | Availability zones           | list(string) | yes      |

---

## ⚙️ Optional Inputs

| Name               | Description        |
| ------------------ | ------------------ |
| enable_nat_gateway | Enable NAT Gateway |
| create_eip         | Create Elastic IP  |
| create_app_sg      | Create App SG      |
| create_elb_sg      | Create ELB SG      |
| create_db_sg       | Create DB SG       |            |
| elb_ingress_rules  | Custom ELB ports   |
| app_ingress_rules  | Custom App ports   |

---

## 📤 Outputs

| Name               | Description        |
| ------------------ | ------------------ |
| vpc_id             | VPC ID             |
| public_subnet_ids  | Public subnet IDs  |
| private_subnet_ids | Private subnet IDs |
| app_sg_id          | App SG ID          |
| elb_sg_id          | ELB SG ID          |
| db_sg_id           | DB SG ID           |
| nat_gateway_id     | NAT Gateway ID     |
| eip_id             | Elastic IP ID      |

---

## 🔧 Example Usage

```hcl
## 🔧 Example Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name = "nexus"
  environment  = "dev"

  vpc_name = "nexus-vpc"
  vpc_cidr = "10.0.0.0/16"

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  azs             = ["us-east-1a", "us-east-1b"]

  enable_nat_gateway = true
  create_eip         = true

  # -------------------
  # Security Groups
  # -------------------
  create_elb_sg = true
  create_app_sg = true
  create_db_sg  = true

  # -------------------
  # ELB SG (Public Access)
  # -------------------
  elb_ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  # -------------------
  # APP SG (ONLY from ELB)
  # -------------------
  app_ingress_rules = [
    {
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      security_groups = [module.vpc.elb_sg_id]
    }
  ]

  # -------------------
  # DB SG (ONLY from APP)
  # -------------------
  db_ingress_rules = [
    {
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [module.vpc.app_sg_id]
    }
  ]
}
```

---

## 🧱 Architecture Flow

```
Internet → ELB SG → APP SG → DB SG
```

---

## 🚀 Key Features

* Fully independent resource toggles
* Secure SG-to-SG communication
* No CIDR internal exposure
* Production-ready architecture
* Optional NAT Gateway

---

## 👨‍💻 Author

**Muhammad Adeel**  : 
DevOps Engineer
