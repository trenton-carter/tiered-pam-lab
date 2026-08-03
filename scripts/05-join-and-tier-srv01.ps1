<#
.SYNOPSIS
    Joins a member server to lab.local, names it correctly, moves it into the
    Tier 1 OU, and applies policy. Reference script for Phase 3.
.DESCRIPTION
    Steps 1-2 run on the member server; step 3 runs on the domain controller;
    step 4 runs on the member server. Credentials are always prompted, never
    embedded.
.NOTES
    Adjust names/OU paths as needed. Run each block in the indicated location.
#>

# ---- On the MEMBER SERVER (as local admin) ----

# Join the domain (prompts for a domain admin, e.g. lab\t0-admin). Reboots.
Add-Computer -DomainName "lab.local" -Credential (Get-Credential) -Restart

# If the Windows computer name wasn't set before joining, rename while joined.
# Renames both the machine and its AD computer account in one step. Reboots.
Rename-Computer -NewName "SRV01" -DomainCredential (Get-Credential) -Restart


# ---- On the DOMAIN CONTROLLER (as domain admin) ----

# Confirm the computer account and where it landed (default is CN=Computers)
Get-ADComputer -Identity "SRV01" | Select-Object Name, DistinguishedName

# Move it into the Tier 1 Servers OU so it inherits the Tier1 deny-logon GPO
Get-ADComputer -Identity "SRV01" |
    Move-ADObject -TargetPath "OU=Servers,OU=Tier1,OU=Admin,DC=lab,DC=local"

# Verify the move
Get-ADComputer -Identity "SRV01" | Select-Object Name, DistinguishedName


# ---- Back on the MEMBER SERVER ----

# Force a policy refresh, then confirm the Tier1 deny GPO applied
gpupdate /force
gpresult /r    # look for "Tier1 - Deny Higher-Tier Logon" under Computer Settings

<#
Proof test (run on the member server):

  runas /user:lab\t0-admin cmd   -> denied: 1385 logon type not granted (Tier 0 blocked)
  runas /user:lab\t1-admin cmd   -> permitted: opens a session (Tier 1 allowed)
#>
