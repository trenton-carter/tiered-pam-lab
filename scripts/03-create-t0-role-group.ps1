<#
.SYNOPSIS
    Creates the Tier 0 role group and grants it domain admin privilege via nesting.
.DESCRIPTION
    Implements an RBAC role-group pattern rather than adding users directly to
    Domain Admins: t0-admin -> T0-Admins (role) -> Domain Admins (built-in
    privilege). This keeps entitlements auditable and access reviews simple.
.NOTES
    Run on the domain controller as a Domain Admin, after 02-create-tiered-admins.ps1.
#>

# Create the Tier 0 role group (security group so it can carry permissions)
New-ADGroup -Name "T0-Admins" -SamAccountName "T0-Admins" `
  -GroupCategory Security -GroupScope Global `
  -Path "OU=Groups,OU=Tier0,OU=Admin,DC=lab,DC=local" `
  -Description "Tier 0 role group - carries domain admin privilege"

# Assign the user to the role, then nest the role into built-in Domain Admins
Add-ADGroupMember -Identity "T0-Admins" -Members "t0-admin"
Add-ADGroupMember -Identity "Domain Admins" -Members "T0-Admins"

# Verify the nesting chain: T0-Admins inside Domain Admins, t0-admin inside T0-Admins
Get-ADGroupMember "Domain Admins" | Select-Object Name, objectClass
Get-ADGroupMember "T0-Admins"    | Select-Object Name, objectClass
