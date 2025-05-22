# Azure AD Domain Controller Lab (Terraform)

This lab deploys a Windows Server 2022 VM with the Active Directory Domain Services (AD DS) role pre-installed, using Terraform in Azure. It sets up the infrastructure and prepares the VM to be promoted to a domain controller manually.

## ✅ What It Does
- Sets up: Resource Group, VNet, Subnet, NSG, Public IP, Windows Server 2022 VM, and a dedicated Data Disk
- Attaches and initializes the data disk for NTDS.dit and SYSVOL paths
- Installs the AD DS role on the VM (but does **not** promote it to a domain controller by default)
- Enables RDP access (port 3389) to the VM

## 🛠 Manual Domain Promotion (Optional)
Once deployed, you can RDP into the VM and run your own promotion script. Here's an example:

```powershell
Import-Module ADDSDeployment

Install-ADDSForest `
  -DomainName "yourdomain.local" `
  -DomainNetbiosName "YOURDOMAIN" `
  -InstallDNS `
  -CreateDnsDelegation:$false `
  -DatabasePath "F:\Windows\NTDS" `
  -LogPath "F:\Windows\NTDS" `
  -SysvolPath "F:\Windows\SYSVOL" `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "YourDSRMPassword123!" -AsPlainText -Force) `
  -Force:$true
```

> 💡 You can also include a modified version of this script in the repo as `promote-dc.ps1` if you'd like.

## 🧰 How to Use

```bash
terraform init
terraform apply
```

> 🔐 You'll need to create the following GitHub secrets in your repository for the GitHub Actions workflow:
> - `ARM_CLIENT_ID`
> - `ARM_CLIENT_SECRET`
> - `ARM_SUBSCRIPTION_ID`
> - `ARM_TENANT_ID`
> - `ADMIN_USERNAME`
> - `ADMIN_PASSWORD`
