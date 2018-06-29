function Get-SecurePassword {
    <#
    .SYNOPSIS
    Retrieves a password from a secure password file and creates a PSCredential object.

    .DESCRIPTION
    This is a Powershell function to retrieve a password from a secure password file and
    create a PSCredential object. It is used in conjunction with files created using 
    ConvertFrom-SecureString (I recommend using New-SecurePassFile).
    
    You can optionally supply a username to include in the PSCredential object.

    This function must be run on the same computer and by the same user account that were
    used to create the secure password file. 

    A plain text password can be gotten from a secure password file by running:
        (Get-SecurePassword $encryptionKeyFile).GetNetworkCredential().Password

    See New-SecurePassFile to create a new secure password file.

    .INPUTS
    This script does not accept any inputs.

    .OUTPUTS
    [PSCredential]

    .EXAMPLE
    Get-SecurePassword "C:\Scripts\837839423"
    Returns a PSCredential object made from the password in "C:\Scripts\837839423".

    .EXAMPLE
    $creds = Get-SecurePassword -PwdFile "\\svr\pwds\password.txt" -userName "Eric Claus"
    Sets $creds to a PSCredential object made from the password in "\\svr\pwds\password.txt"
    and the username "Eric Claus".

    .EXAMPLE
    (Get-SecurePassword "C:\path\to\file").GetNetworkCredential().Password
    Converts a secure password in "C:\path\to\file" to plain text.

    .NOTES
    Author: Eric Claus
    Last Modified: 11/07/2017
    Based on code from Shawn Melton (@wsmelton), http://blog.wsmelton.com

    .LINK
    https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
    #>

    Param(
    [Parameter(Mandatory=$true)] [string]$PwdFile,
    [string]$userName="tempPlaceHolder"
    )

    $ErrorActionPreference = "Stop"

    Try {
        $pwd = Get-Content $PwdFile | ConvertTo-SecureString
    }
    Catch [System.Security.Cryptography.CryptographicException] {
        Throw "Error: The secure password file needs to be created by the same user and on the same computer as this script is being run."
        Exit 5
    }
    $mycred = New-Object System.Management.Automation.PSCredential($userName,$pwd)

    $mycred

    Remove-Variable userName,PwdFile,pwd,mycred
}