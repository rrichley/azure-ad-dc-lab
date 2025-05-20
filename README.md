# Azure AD Domain Controller Lab (Terraform)

Deploys a Windows Server 2022 VM as a Domain Controller using Terraform in Azure.

## ✅ What It Does
- Sets up: Resource Group, VNet, Subnet, NSG, Public IP, VM, Data Disk
- Adds AD DS role using a PowerShell script
- RDP access enabled (port 3389)

## 🧰 How to Use
```bash
terraform init
terraform apply