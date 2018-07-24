. "$PSSCriptRoot\Get-SecurePassword.ps1"

# Run the Build-HtmlPages script, generating the website
. "$PSScriptRoot\Build-HtmlPages.ps1"

# Create a PSCredential object with the password for the domain backup VLAN admin account
$securePassFile = "C:\Scripts\Cyrus-Backup-Server\130294490"
$userName = "ad\Cyrus"
$creds = Get-SecurePassword -PwdFile $securePassFile -userName $userName
    
# What is being backed up
$backupSource = "\\192.168.90.92\d$\NASShare\dr"
    
# Create a temporary mapped drive, connecting to the backup source folder with the credentials from above
Remove-PSDrive -Name "tempSource1" -ErrorAction SilentlyContinue
New-PSDrive -Name "tempSource1" -PSProvider FileSystem -Root $backupSource -Credential $creds
$source = "tempSource1:\"


Copy-Item "C:\Scripts\Cyrus-Backup-Server\CyrusDashboard" -Recurse -Destination "$source\CyrusDashboard" -Force