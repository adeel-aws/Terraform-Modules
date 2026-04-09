# 🚀 Terraform Modules Repository

A collection of **reusable, production-ready Terraform modules** for provisioning AWS infrastructure.

This repository serves as a **central module registry** where each module is self-contained and documented.

---

## 📦 Available Modules

### 🌐 VPC Module

Provision a fully customizable Virtual Private Cloud.

**Features:**

* VPC creation
* Public & private subnets
* Internet Gateway
* Route tables
* Flexible networking configuration

---

### 🪣 S3 Module

Create secure and flexible S3 buckets with independent optional features.

**Features:**

* Default bucket (like AWS Console)
* Optional:

  * Public access control
  * Static website hosting
  * Bucket policies (custom/public)
  * Versioning
  * Lifecycle rules (expiration + storage class transition)
  * Server access logging
* Fully configurable **Block Public Access settings**

---

### 🖥️ EC2 Module

Launch and manage EC2 instances.

**Features:**

* EC2 provisioning
* Custom AMI support
* Instance type configuration
* Key pair support
* Security groups integration
* User data support

---

## 🏗️ Repository Structure

```id="repo-struct-01"
.
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── s3/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── ec2/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
└── README.md   # (this file)
```

---

## ⚙️ How to Use

Clone the repository:

```bash id="clone-01"
git clone https://github.com/adeel-aws/Terraform-Modules.git
```

Then call any module:

```hcl id="usage-01"
module "s3_bucket" {
  source = "./s3"

  bucket_name = "myapp"
}
```

---

## 📘 Module Documentation

Each module contains its own **README.md** with:

* Features
* Required inputs
* Optional inputs
* Notes
* Example usage

👉 Simply open the respective module folder to get full usage details.

---

## 🎯 Goal of This Repository

* Promote **modular Terraform architecture**
* Avoid code duplication
* Enable **quick infrastructure deployment**
* Follow **DevOps best practices**

---

## 💡 Design Principles

* 🔹 Reusable modules
* 🔹 Independent features (no tight coupling)
* 🔹 Minimal hardcoding
* 🔹 Environment-ready (dev / staging / prod)
* 🔹 Beginner-friendly but scalable

---

## 🚀 Future Enhancements

* CloudFront module
* RDS module
* Load Balancer (ALB/NLB) module
* EKS / ECS modules
* CI/CD integration using GitHub Actions

---

## 🤝 Contributing

Contributions, improvements, and suggestions are welcome.

---

## 📜 License

This project is open-source and available under the MIT License.

---

## 👨‍💻 Author

**Muhammad Adeel**: 
Aspiring DevOps Engineer 🚀
