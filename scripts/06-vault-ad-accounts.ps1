<#
.SYNOPSIS
    AD-side preparation for Vault LDAP credential rotation (Phase 4).
.DESCRIPTION
    Creates Vault's bind account and the managed target accounts, moves managed
    accounts into a dedicated ServiceAccounts OU, and (via the GUI Delegation of
    Control wizard / dsacls) grants least-privilege Reset Password rights.
    Passwords are prompted, never hardcoded.
.NOTES
    Run on the domain controller as a Domain Admin. LDAPS must be enabled on the
    DC (AD CS Enterprise Root CA) for Vault to rotate passwords — see build log.
#>

# --- Vault bind account (Tier 0) ---
$vaultPass = Read-Host "Enter a STRONG password for svc-vault" -AsSecureString
New-ADUser -Name "svc-vault" -SamAccountName "svc-vault" `
  -UserPrincipalName "svc-vault@lab.local" `
  -Path "OU=Accounts,OU=Tier0,OU=Admin,DC=lab,DC=local" `
  -AccountPassword $vaultPass -Enabled $true -PasswordNeverExpires $true `
  -Description "Vault bind account - authenticates Vault to AD for credential rotation"
# NOTE: a weak password causes the account to be created DISABLED. If so:
#   Set-ADAccountPassword -Identity svc-vault -NewPassword (Read-Host -AsSecureString) -Reset
#   Enable-ADAccount -Identity svc-vault

# --- Dedicated OU for Vault-managed accounts (separate from admin accounts) ---
New-ADOrganizationalUnit -Name "ServiceAccounts" -Path "OU=Tier1,OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true

# --- Static-role target account ---
$appPass = Read-Host "Enter initial password for svc-app01" -AsSecureString
New-ADUser -Name "svc-app01" -SamAccountName "svc-app01" `
  -UserPrincipalName "svc-app01@lab.local" `
  -Path "OU=ServiceAccounts,OU=Tier1,OU=Admin,DC=lab,DC=local" `
  -AccountPassword $appPass -Enabled $true -PasswordNeverExpires $true `
  -Description "Managed service account - password rotated by Vault (static role)"

# --- Shared accounts for the check-out/check-in library ---
foreach ($n in @("svc-shared01","svc-shared02")) {
    $p = Read-Host "Enter password for $n" -AsSecureString
    New-ADUser -Name $n -SamAccountName $n `
      -UserPrincipalName "$n@lab.local" `
      -Path "OU=ServiceAccounts,OU=Tier1,OU=Admin,DC=lab,DC=local" `
      -AccountPassword $p -Enabled $true -PasswordNeverExpires $true `
      -Description "Shared privileged account - managed by Vault check-out library"
}

# --- Delegation ---
# Reset Password over the ServiceAccounts OU is granted via the GUI
# "Delegate Control" wizard (User objects -> Reset Password) to LAB\svc-vault.
# For rotate-root, svc-vault also needs Reset Password over ITS OWN object,
# scoped to the single object with dsacls:
#
#   dsacls "CN=svc-vault,OU=Accounts,OU=Tier0,OU=Admin,DC=lab,DC=local" `
#     /G "LAB\svc-vault:CA;Reset Password"

# --- Verify ---
Get-ADUser -Filter "Name -like 'svc-*'" -Properties Description |
    Select-Object Name, SamAccountName, Enabled, DistinguishedName | Format-Table -AutoSize
