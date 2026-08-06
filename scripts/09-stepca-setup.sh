#!/usr/bin/env bash
#
# step-ca machine identity CA: install, initialize, issue short-lived certs,
# renew, and enable ACME (Phase 6). Run on SVC01.
#
# Demonstrates modern short-lived machine identity, contrasting with the
# traditional AD CS enterprise PKI from Phase 4.

set -euo pipefail

# --- Install step CLI and step-ca from current tarballs ---
# (The dl.smallstep.com "latest" URLs always resolve to the current release.)
wget -qO /tmp/step.tar.gz "https://dl.smallstep.com/cli/docs-ca-install/latest/step_linux_amd64.tar.gz"
tar -xzf /tmp/step.tar.gz -C /tmp
sudo install /tmp/step_*/bin/step /usr/local/bin/step

wget -qO /tmp/step-ca.tar.gz "https://dl.smallstep.com/certificates/docs-ca-install/latest/step-ca_linux_amd64.tar.gz"
tar -xzf /tmp/step-ca.tar.gz -C /tmp
# NOTE: this tarball extracts the binary directly (no bin/ subdir):
sudo install /tmp/step-ca_linux_amd64/step-ca /usr/local/bin/step-ca

step version
step-ca version

# --- Initialize the two-tier PKI (interactive) ---
# Deployment type: Standalone
# PKI name:        Lab Machine Identity CA
# DNS/IPs:         svc01.lab.local,10.10.10.30,127.0.0.1
# Bind:            :9000
# Provisioner:     admin@lab.local
# Password:        set a strong one (or let it generate) -- needed to start CA
step ca init

# --- Start the CA (foreground; prompts for the CA key password) ---
# Leave this running in its own terminal:
#   step-ca $(step path)/config/ca.json

# --- (Second session) Bootstrap client trust, then issue a short-lived cert ---
# step ca bootstrap --ca-url https://svc01.lab.local:9000 --fingerprint <ROOT_FP>
step ca certificate "test-machine.lab.local" test.crt test.key
step certificate inspect test.crt --short          # ~24h validity

# --- Renew (uses the existing cert to authenticate; no password) ---
step ca renew test.crt test.key
step certificate inspect test.crt --short          # new serial, window moved

# --- ACME provisioner: industry-standard automated issuance ---
step ca provisioner add acme --type ACME
# Reload the CA: in the CA terminal, Ctrl+C then restart step-ca (or kill -1 <pid>)

# The CA validates by connecting back to the claimed name, so it must resolve:
echo "127.0.0.1 acme-test.lab.local" | sudo tee -a /etc/hosts

# Issue via ACME in standalone mode (http-01 challenge; needs sudo for :80):
sudo step ca certificate "acme-test.lab.local" acme.crt acme.key \
  --provisioner acme --standalone \
  --ca-url https://svc01.lab.local:9000 \
  --root ~/.step/certs/root_ca.crt

step certificate inspect acme.crt --short
