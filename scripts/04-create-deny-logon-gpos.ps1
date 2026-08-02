<#
.SYNOPSIS
    Creates and links the tier deny-logon GPOs.
.DESCRIPTION
    Creates two GPOs and links each to its tier's machine OU. The deny-logon
    USER RIGHTS themselves (Deny log on locally / through Remote Desktop Services)
    are populated via the Group Policy Management Editor GUI - see the Phase 2
    build log - because populating User Rights Assignment in raw PowerShell means
    editing security template files, which is more error-prone than the GUI.

    Target settings once populated:
      Tier2 GPO (Workstations OU): deny T0-Admins AND t1-admin  (both logon types)
      Tier1 GPO (Servers OU):      deny T0-Admins only          (both logon types)
.NOTES
    Run on the domain controller as a Domain Admin, after the OU structure exists.
#>

Import-Module GroupPolicy

# Create the GPOs
New-GPO -Name "Tier1 - Deny Higher-Tier Logon" -Comment "Denies Tier 0 admins from logging into Tier 1 servers"
New-GPO -Name "Tier2 - Deny Higher-Tier Logon" -Comment "Denies Tier 0 and Tier 1 admins from logging into Tier 2 workstations"

# Link each GPO to its tier's machine OU
New-GPLink -Name "Tier1 - Deny Higher-Tier Logon" -Target "OU=Servers,OU=Tier1,OU=Admin,DC=lab,DC=local"
New-GPLink -Name "Tier2 - Deny Higher-Tier Logon" -Target "OU=Workstations,OU=Tier2,OU=Admin,DC=lab,DC=local"

# Verify existence and links
Get-GPO -All | Where-Object { $_.DisplayName -like "Tier*Deny*" } | Select-Object DisplayName, Id
Get-GPInheritance -Target "OU=Workstations,OU=Tier2,OU=Admin,DC=lab,DC=local" | Select-Object -ExpandProperty GpoLinks
Get-GPInheritance -Target "OU=Servers,OU=Tier1,OU=Admin,DC=lab,DC=local"      | Select-Object -ExpandProperty GpoLinks

<#
After populating the User Rights Assignment settings in the GUI, export
human-readable reports as evidence:

Get-GPOReport -Name "Tier1 - Deny Higher-Tier Logon" -ReportType Html -Path "C:\temp\tier1-gpo-report.html"
Get-GPOReport -Name "Tier2 - Deny Higher-Tier Logon" -ReportType Html -Path "C:\temp\tier2-gpo-report.html"
#>
