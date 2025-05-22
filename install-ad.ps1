Start-Transcript -Path "C:\ad-setup.log" -Force

# Initialise the new data disk (LUN 0) as F:
$disk = Get-Disk | Where-Object PartitionStyle -Eq 'RAW' | Sort-Object Number | Select-Object -First 1
Initialize-Disk -Number $disk.Number -PartitionStyle MBR
New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel "ADData" -Confirm:$false

# Install AD DS and Management Tools
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Stop-Transcript
