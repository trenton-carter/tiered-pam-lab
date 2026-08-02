<#
.SYNOPSIS
    Creates the three tiered admin accounts (t0/t1/t2-admin) in their tier OUs.
.DESCRIPTION
    Prompts for each password as a SecureString at runtime so no credentials are
    ever stored in the script, shell history, or repository. Each account lands
    in its tier's Accounts OU, which makes the deny-logon GPO targeting work.
.NOTES
    Run on the domain controller as a Domain Admin, after 01-create-ou-structure.ps1.
#>

# Prompt for each password securely (never hardcode credentials in a script)
$t0Pass = Read-Host "Enter password for t0-admin" -AsSecureString
$t1Pass = Read-Host "Enter password for t1-admin" -AsSecureString
$t2Pass = Read-Host "Enter password for t2-admin" -AsSecureString

# Tier 0 admin
New-ADUser -Name "t0-admin" -SamAccountName "t0-admin" `
  -UserPrincipalName "t0-admin@lab.local" `
  -Path "OU=Accounts,OU=Tier0,OU=Admin,DC=lab,DC=local" `
  -AccountPassword $t0Pass -Enabled $true `
  -PasswordNeverExpires $false -Description "Tier 0 privileged admin - domain/DC control"

# Tier 1 admin
New-ADUser -Name "t1-admin" -SamAccountName "t1-admin" `
  -UserPrincipalName "t1-admin@lab.local" `
  -Path "OU=Accounts,OU=Tier1,OU=Admin,DC=lab,DC=local" `
  -AccountPassword $t1Pass -Enabled $true `
  -PasswordNeverExpires $false -Description "Tier 1 privileged admin - servers"

# Tier 2 admin
New-ADUser -Name "t2-admin" -SamAccountName "t2-admin" `
  -UserPrincipalName "t2-admin@lab.local" `
  -Path "OU=Accounts,OU=Tier2,OU=Admin,DC=lab,DC=local" `
  -AccountPassword $t2Pass -Enabled $true `
  -PasswordNeverExpires $false -Description "Tier 2 privileged admin - workstations"

# Verify
Get-ADUser -Filter * -SearchBase "OU=Admin,DC=lab,DC=local" -Properties Description |
    Select-Object Name, SamAccountName, Enabled, DistinguishedName, Description | Format-Table -AutoSize
