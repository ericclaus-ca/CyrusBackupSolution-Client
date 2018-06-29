<#
.SYNOPSIS
Creates a secure password file which can be used to retrieve the password at a later time.
 
.DESCRIPTION
This is a Powershell function to create a secure password file. It can be run one time to
create a secure password that will be used in scripts that require automation.
 
It prompts for the password to be entered and then converts it to a secure string and saves
it to a file. It returns the path to the secure password file as a string. The file name is
randomly generated and the directory it is located in can be either left to the default path
defined in the script, or a directory specified with the -PwdFileDir parameter.
 
This function must be run on the same computer and by the same user account that will run any 
scripts that reference the secure password file.
 
This function can be used in conjuction with Get-SecurePassword to store a secure password
and then reference it as plain text in a script. It is useful for scripts that require both 
automation and plain text passwords.  
 
See Get-SecurePassword to convert the secure password file to a plain text password in scripts.
 
.INPUTS
This script does not accept any inputs.
 
.OUTPUTS
[string] path to the secure password file.
 
.EXAMPLE
New-SecurePassFile.ps1
Prompts for a password, then converts it to a secure string and saves the file to the default directory.
 
.EXAMPLE
New-SecurePassFile "C:\myPwds\"
Prompts for a password, then converts it to a secure string and saves the file to the "C:\myPwds\" directory.
 
.NOTES
Author: Eric Claus
Last Modified: 11/07/2017
Based on code from Shawn Melton (@wsmelton), http://blog.wsmelton.com
 
.LINK
https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
#>
 
Param(
    [string]$PwdFileDir = "C:\Scripts"
)
 
$PwdFile = "$PwdFileDir\$(Get-Random)"
 
#If (Test-Path $PwdFile) {
    #New-SecurePassFile $PwdFileDir
#}
 
$Password = (Read-Host -Prompt "Enter the password to add to the file" -AsSecureString)
 
ConvertFrom-SecureString -SecureString $Password | Out-File $PwdFile
 
echo $PwdFile