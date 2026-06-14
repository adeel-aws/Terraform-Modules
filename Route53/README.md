# 🚀 Route53 Module (Fully Reusable + Production Ready)

## 📌 Overview

This module provides a fully reusable AWS Route53 DNS solution with support for:

- A Records
- CNAME Records
- Alias Records (ALB / NLB / CloudFront)
- Weighted Routing
- Failover Routing
- Latency Routing
- Multi-record support
- Zero dependency design

---

## 📁 Structure
Route53/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md

---

---

## ⚙️ Features

| Feature | Status |
|---|---|
| A Record | ✅ |
| CNAME | ✅ |
| TXT | ✅ |
| Alias (ALB/NLB/CloudFront) | ✅ |
| Weighted Routing | ✅ |
| Failover Routing | ✅ |
| Latency Routing | ✅ |
| Multi Record Support | ✅ |
| No Dependency on ELB/ACM/VPC | ✅ |

---

## 🚀 Example Usage (ALB Alias - MOST COMMON)

```hcl
module "route53" {
  source = "./modules/route53"

  project_name = "signoz"
  environment  = "prod"
  zone_id      = "ZXXXXXXXXXXXX"

  records = {
    alb = {
      name = "monitoring.aerodyne.group"
      type = "A"

      alias = {
        name    = module.elb.lb_dns_name
        zone_id = module.elb.lb_zone_id
      }
    }
  }
}
```

---

## 🌍 Example Usage (Static IP)

```hcl
records = {
  api = {
    name    = "api.aerodyne.group"
    type    = "A"
    ttl     = 300
    records = ["1.2.3.4"]
  }
}
```

---

## 📝 ACM Validation Record Example

When using ACM module with `auto_validate_via_route53 = false`, copy the `validation_records` output and add them here manually:

```hcl
module "route53" {
  source = "./modules/route53"

  project_name = "signoz"
  environment  = "prod"
  zone_id      = "ZXXXXXXXXXXXX"

  records = {
    acm_validation = {
      name    = "_abc123.monitoring.aerodyne.group"
      type    = "CNAME"
      ttl     = 60
      records = ["_xyz456.acm-validations.aws."]
    }
  }
}
```

Or if using ACM module with `auto_validate_via_route53 = true` — validation is handled automatically inside the ACM module, no Route53 module needed for validation.

---

## ⚖️ Example Usage (Weighted Routing - Blue/Green)

```hcl
records = {
  blue = {
    name           = "api.aerodyne.group"
    type           = "A"
    set_identifier = "blue"

    weighted_routing_policy = {
      weight = 70
    }

    alias = {
      name    = module.elb.blue_dns
      zone_id = module.elb.zone_id
    }
  }

  green = {
    name           = "api.aerodyne.group"
    type           = "A"
    set_identifier = "green"

    weighted_routing_policy = {
      weight = 30
    }

    alias = {
      name    = module.elb.green_dns
      zone_id = module.elb.zone_id
    }
  }
}
```

---

## 🔁 Example Usage (Failover Routing)

```hcl
records = {
  primary = {
    name           = "api.aerodyne.group"
    type           = "A"
    set_identifier = "primary"

    failover_routing_policy = {
      type = "PRIMARY"
    }

    alias = {
      name    = module.elb.primary_dns
      zone_id = module.elb.zone_id
    }
  }

  secondary = {
    name           = "api.aerodyne.group"
    type           = "A"
    set_identifier = "secondary"

    failover_routing_policy = {
      type = "SECONDARY"
    }

    alias = {
      name    = module.elb.secondary_dns
      zone_id = module.elb.zone_id
    }
  }
}
```

---

## ⏱ Example Usage (Latency Routing)

```hcl
records = {
  ap_south = {
    name           = "api.aerodyne.group"
    type           = "A"
    set_identifier = "ap-south"

    latency_routing_policy = {
      region = "ap-south-1"
    }

    alias = {
      name    = module.elb.ap_dns
      zone_id = module.elb.zone_id
    }
  }
}
```

---

## 📥 Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| zone_id | string | Yes | Hosted Zone ID |
| records | map(any) | Yes | DNS record definitions |
| project_name | string | Yes | Project name |
| environment | string | Yes | Environment |

---

## 📤 Outputs

| Output | Description |
|---|---|
| record_fqdns | All created DNS record FQDNs |

---

## ⚠️ Important Notes

- When using `alias` — do NOT pass `ttl` or `records`. AWS does not allow both together.
- When using `ttl` and `records` — do NOT pass `alias`.
- For ACM DNS validation via this module — use `type = "CNAME"` with the values from `module.acm.validation_records` output.

---

## 🧠 Key Design Philosophy

- Fully reusable across all projects
- No dependency on ELB / VPC / ACM
- Works with any AWS architecture
- Simple for basic use cases
- Powerful for advanced routing

---

## 🏷 Naming Convention

- monitoring.example.group
- api.example.group
- app.example.group