Start-Transcript -Path "C:\ad-setup.log" -Force

# Initialise the new data disk (LUN 0) as F:
$disk = Get-Disk | Where-Object PartitionStyle -Eq 'RAW' | Sort-Object Number | Select-Object -First 1
Initialize-Disk -Number $disk.Number -PartitionStyle MBR
New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel "ADData" -Confirm:$false
$driveLetter = (Get-Partition -DiskNumber $disk.Number | Get-Volume).DriveLetter
$ntdsPath = "$driveLetter`:\Windows\NTDS"
$sysvolPath = "$driveLetter`:\Windows\SYSVOL"

# Install AD DS and Management Tools
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to Domain Controller
Import-Module ADDSDeployment

Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath $ntdsPath `
    -DomainMode "WinThreshold" `
    -DomainName "rr.com" `
    -DomainNetbiosName "RR" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath $ntdsPath `
    -SysvolPath $sysvolPath `
    -NoRebootOnCompletion:$true `
    -Force:$true

Stop-Transcript

# Commented out to allow Custom Script Extension to return success to Terraform
# Restart-Computer -Force
