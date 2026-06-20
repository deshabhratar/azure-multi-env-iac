# azure-multi-env-iac

Production-grade, multi-environment Azure infrastructure built with modularized Terraform and deployed via GitHub Actions CI/CD. This project simulates a real enterprise cloud setup — private networking, autoscaling compute, private database connectivity, monitoring, and governance — deployed consistently across dev and prod using a single codebase.

---

## What this project does

A 3-tier web application infrastructure (web → app → database) deployed across two isolated environments (dev and prod) on Microsoft Azure. Every layer is private, automated, and follows cloud security best practices — no public database access, no hardcoded secrets, no manual deployments.

---

## Architecture

```
Internet
    │
    ▼
App Gateway v2 (WAF · Public IP · SSL termination)
    │   snet-gateway · NSG
    ▼
Web VMSS (nginx · Uniform mode · autoscale)
    │   snet-web · NSG: allow 443/80 from snet-gateway only
    ▼
Internal Load Balancer (private IP · health probe)
    │
    ▼
App VMSS (Flask · Uniform mode · autoscale)
    │   snet-app · NSG: allow from snet-web only
    │   Managed Identity → Key Vault + Storage RBAC
    ▼
Azure SQL (private endpoint · public access disabled)
    │   snet-data · NSG: allow 1433 from snet-app only
    │   Private DNS Zone: privatelink.database.windows.net
    ▼
Log Analytics Workspace
    │   Diagnostic settings on all resources
    │   KQL alert rules · Action Groups
    ▼
Azure Policy (subscription scope)
    Allowed locations · Tag enforcement
```

---

## Tech stack

| Layer | Technology |
|---|---|
| Cloud | Microsoft Azure (Central India) |
| IaC | Terraform — modularized, remote state |
| CI/CD | GitHub Actions — branch promotion strategy |
| Auth | OIDC (Workload Identity Federation) — no stored secrets |
| Networking | Azure VNet · 4 isolated subnets · custom NSGs |
| Ingress | Azure Application Gateway v2 |
| Internal routing | Private Azure Load Balancer |
| Compute | Dual Linux VMSS — Uniform mode · CPU autoscale |
| Database | Azure SQL — Private Endpoint only |
| DNS | Azure Private DNS Zone |
| Identity | Managed Identity · RBAC · least privilege |
| Monitoring | Azure Monitor · Log Analytics · KQL · Alert rules |
| Governance | Azure Policy — location + tag enforcement |
| TF version | 1.7.0 pinned · AzureRM `~> 4.0` |

---

## Repository structure

```
azure-multi-env-iac/
├── modules/
│   ├── networking/
│   │   ├── main.tf          # VNet, subnets, NSGs, Private DNS, VNet link
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf          # VMSS, Load Balancer, autoscale, extensions
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── scripts/
│   │       ├── web_init.sh  # nginx + proxy config
│   │       └── app_init.sh  # Python + Flask app
│   └── database/
│       ├── main.tf          # Azure SQL, Private Endpoint, DNS A record
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── backend.tf
│   │   └── providers.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── backend.tf
│       └── providers.tf
└── .github/
    └── workflows/
        ├── deploy-dev.yml   # triggers on push to dev branch
        └── deploy-prod.yml  # triggers on push to main · manual approval
```

---

## Environments

| | Dev | Prod |
|---|---|---|
| VM SKU | Standard_D1ds_v3 | Standard_D1ds_v3 |
| VMSS min instances | 1 | 2 |
| State file | `dev/terraform.tfstate` | `prod/terraform.tfstate` |
| Trigger | Push to `dev` branch | Push to `main` · approval gate |

Both environments share the same module codebase. Different values are passed via separate `terraform.tfvars` files per environment.

---

## CI/CD pipeline

```
Developer pushes to dev branch
        │
        ▼
GitHub Actions: deploy-dev.yml
    terraform init
    terraform plan
    terraform apply -auto-approve -input=false
        │
        ▼
Code promoted to main branch
        │
        ▼
GitHub Actions: deploy-prod.yml
    Manual approval gate
        │
        ▼
    terraform init
    terraform plan
    terraform apply -auto-approve -input=false
```

Authentication uses OIDC (Workload Identity Federation) — GitHub Actions authenticates directly with Azure Entra ID using short-lived tokens. No client secrets stored anywhere.

---

## Security design

**Network isolation:** Each tier lives in a dedicated subnet with its own NSG. Rules follow least-privilege — each tier only accepts traffic from the tier directly above it. The database subnet accepts no public traffic at all.

**Private database connectivity:** Azure SQL has public access disabled. The only way to reach it is through a Private Endpoint inside `snet-data`. A Private DNS Zone (`privatelink.database.windows.net`) linked to the VNet ensures internal hostname resolution returns the private IP — not the public Azure endpoint.

**Identity:** The app tier VMSS uses a Managed Identity. No passwords or connection strings stored in code. Key Vault and Storage access granted via RBAC role assignments.

**Governance:** An Azure Policy at subscription scope enforces allowed deployment regions and mandatory resource tags. Resources created outside Central India or without required tags are denied at the API layer.

---

## Key engineering decisions

**Why Uniform mode VMSS over Flexible?**
The web and app tiers are stateless workloads with identical instances. Uniform mode creates identical VM clones and supports native autoscale — the right choice for a homogeneous stateless tier.

**Why Private Endpoint over VNet Service Endpoint for SQL?**
Private Endpoint assigns a real private IP inside the VNet and disables public access entirely. Service Endpoints still route over the Azure backbone but keep the public endpoint active. Private Endpoint is the stricter, more secure option.

**Why separate state files per environment?**
Isolates blast radius. A failed `terraform destroy` in dev cannot affect prod state. Each environment is an independent Terraform workspace with its own backend key.

**Why OIDC over Service Principal client secrets?**
Short-lived tokens negotiated at runtime. No secret rotation, no secret leakage, no secrets stored in GitHub. The federated credential trusts GitHub's identity provider directly.

---

## How to deploy

**Prerequisites**
- Azure subscription with contributor access
- Terraform 1.7.0
- Azure CLI
- GitHub repository with Actions enabled

**Remote state storage**
Create the backend storage manually before first deployment:

```bash
az group create --name rg-tfstate --location centralindia
az storage account create --name satfstate<yourname> --resource-group rg-tfstate --sku Standard_LRS
az storage container create --name tfstate --account-name satfstate<yourname>
```

**OIDC setup**
Configure Workload Identity Federation between your Azure subscription and GitHub repository. Assign Contributor role to the federated identity at subscription scope.

**Deploy dev**

```bash
cd environments/dev
az login
terraform init
terraform plan
terraform apply
```

**Deploy prod**

```bash
cd environments/prod
az login
terraform init
terraform plan
terraform apply
```

---

## What I learned building this

- Terraform module design — writing reusable modules with clean variable and output contracts
- How Azure Private DNS Zone + VNet link + Private Endpoint work together for split-horizon DNS resolution
- VMSS Uniform mode autoscale — CPU-based scale out and scale in rules with cooldown periods
- NSG design for strict tier isolation — overriding the default `AllowVNetInBound` rule
- OIDC authentication — eliminating stored secrets from CI/CD pipelines entirely
- Multi-environment IaC patterns — same module, different inputs, separate state files

---

## Author

Built by Pratik — Associate Systems Engineer transitioning into Cloud/DevOps Engineering.
Hands-on Azure infrastructure, Terraform, GitHub Actions, and enterprise identity (Entra ID, AD Connect, Intune).
