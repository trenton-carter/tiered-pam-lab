#!/usr/bin/env bash
#
# Vault LDAP secrets engine configuration and rotation demos (Phase 4).
# Run on the Vault host (SVC01) after Vault is initialized, unsealed, and
# logged in, and after LDAPS is enabled on the DC and the CA cert is placed
# at /etc/vault.d/lab-ca.pem.
#
# Environment (persisted in ~/.bashrc):
#   export VAULT_ADDR='https://127.0.0.1:8200'
#   export VAULT_SKIP_VERIFY='true'
#
# NOTE: no credentials are hardcoded here. bindpass is entered interactively
# once, then rotate-root removes human knowledge of it entirely.

set -euo pipefail

# --- Enable the LDAP secrets engine ---
vault secrets enable ldap

# --- Configure the connection to AD over LDAPS ---
# Supply the real svc-vault password when prompted by NOT scripting it here.
# Example (bindpass entered manually at the terminal):
#
# vault write ldap/config \
#   binddn="CN=svc-vault,OU=Accounts,OU=Tier0,OU=Admin,DC=lab,DC=local" \
#   bindpass="<REAL-SVC-VAULT-PASSWORD>" \
#   url="ldaps://dc01.lab.local" \
#   certificate=@/etc/vault.d/lab-ca.pem \
#   schema=ad \
#   insecure_tls=false \
#   userdn="OU=Admin,DC=lab,DC=local"
#
# insecure_tls=false strictly verifies the DC cert against the CA cert.
# userdn is the search base required by the check-out library.

# --- Rotate the bind (root) credential: Vault takes over its own password ---
# Requires svc-vault to have Reset Password over its own object (dsacls).
vault write -f ldap/rotate-root

# After rotate-root you no longer know bindpass. Re-writes of ldap/config must
# OMIT bindpass; Vault uses its internally-held rotated credential.

# --- Static role: manage a persistent service account ---
vault write ldap/static-role/app01-role \
  dn="CN=svc-app01,OU=ServiceAccounts,OU=Tier1,OU=Admin,DC=lab,DC=local" \
  username="svc-app01" \
  rotation_period="24h"

vault read ldap/static-role/app01-role      # shows last_vault_rotation
vault read ldap/static-cred/app01-role       # returns current password Vault holds

# --- Check-out / check-in library: shared privileged accounts ---
vault write ldap/library/ops-team \
  service_account_names="svc-shared01@lab.local,svc-shared02@lab.local" \
  ttl="1h" max_ttl="4h" disable_check_in_enforcement=false

vault read  ldap/library/ops-team/status     # both available
vault write -f ldap/library/ops-team/check-out   # borrow one (returns password)
vault read  ldap/library/ops-team/status     # one now checked out
vault write -f ldap/library/ops-team/check-in    # return -> auto-rotates password
vault read  ldap/library/ops-team/status     # available again

# Proof (run on DC01): the checked-out password is rejected by AD after check-in.
