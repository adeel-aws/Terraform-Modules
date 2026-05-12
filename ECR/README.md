# 🚀 Terraform ECR Module (Reusable & Production Ready)

## 📌 Overview
This Terraform module creates a **fully reusable AWS ECR (Elastic Container Registry)** setup for Docker images with:

- Versioned repository support
- Encryption enabled
- Image scanning on push
- Lifecycle policy (optional but recommended)
- Consistent naming using `project + environment`
- Industry-standard tagging via `name_prefix`

---

## 📁 Module Structure

```
modules/
 └── ECR/
      ├── main.tf
      ├── variables.tf
      ├── outputs.tf
      └── README.md
```

---

## 🔗 Example Usage

```hcl
module "ecr_backend" {
  source = "../modules/ECR"

  project_name    = "admin"
  environment     = "dev"
  repository_name = "backend"

  scan_on_push = true

  tags = {
    Project = "admin"
    Env     = "dev"
  }
}
```

---

## 🏷️ Naming Convention (IMPORTANT)

All resources follow:

```
<project-name>-<environment>-<resource>
```

Example:
```
admin-dev-backend
admin-prod-backend
```

---

## 🧠 Why This Design?

✔ Fully reusable for any service (backend/frontend/worker)  
✔ Clean separation of environments  
✔ Standard AWS ECR best practices  
✔ Works with ECS, CI/CD pipelines, GitHub Actions  
✔ No hardcoded names  

---

## 👨‍💻 Author

Muhammad Adeel  :  
(DevOps Engineer)
