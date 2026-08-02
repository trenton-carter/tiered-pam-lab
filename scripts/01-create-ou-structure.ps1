<#
.SYNOPSIS
    Creates the tiered administration OU structure for the lab.local domain.
.DESCRIPTION
    Builds an Admin branch with Tier0/Tier1/Tier2 OUs, each containing Accounts
    and Groups sub-OUs (plus Servers for Tier1 and Workstations for Tier2).
    Follows Microsoft's AD administrative tier model. All OUs are protected from
    accidental deletion.
.NOTES
    Run on the domain controller as a Domain Admin. Idempotent-ish: re-running
    will error on OUs that already exist.
#>

# Root admin container for the tier model
New-ADOrganizationalUnit -Name "Admin" -Path "DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true

# Tier 0
New-ADOrganizationalUnit -Name "Tier0" -Path "OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Accounts" -Path "OU=Tier0,OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Groups"   -Path "OU=Tier0,OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true

# Tier 1
New-ADOrganizationalUnit -Name "Tier1" -Path "OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Accounts" -Path "OU=Tier1,OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Groups"   -Path "OU=Tier1,OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Servers"  -Path "OU=Tier1,OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true

# Tier 2
New-ADOrganizationalUnit -Name "Tier2" -Path "OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Accounts"     -Path "OU=Tier2,OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Groups"       -Path "OU=Tier2,OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Tier2,OU=Admin,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $true

# Verify
Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Admin,DC=lab,DC=local" |
    Select-Object Name, DistinguishedName | Sort-Object DistinguishedName
