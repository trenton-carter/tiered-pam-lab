#!/usr/bin/env bash
#
# Teleport Community Edition setup for brokered access + session recording
# (Phase 5). Run on the Teleport host (SVC01).
#
# Produces a single-node cluster (Auth + Proxy + SSH services) with a self-signed
# web TLS cert. In production the proxy cert would be issued by the internal CA
# (Phase 4 AD CS) instead of self-signed.

set -euo pipefail

# --- Install Teleport (Community Edition), pinned version ---
curl https://cdn.teleport.dev/install.sh | bash -s 18.10.0
teleport version    # confirm output says "Teleport" (Community), not "Enterprise"

# --- Web TLS cert for the proxy (self-signed; SANs cover all reach paths) ---
sudo mkdir -p /var/lib/teleport/tls
sudo openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout /var/lib/teleport/tls/teleport.key \
  -out    /var/lib/teleport/tls/teleport.crt \
  -days 825 -subj "/CN=svc01.lab.local" \
  -addext "subjectAltName=DNS:svc01.lab.local,DNS:svc01,IP:10.10.10.30,IP:192.168.56.101,IP:127.0.0.1"

# --- Generate cluster config for a private-network deployment ---
sudo teleport configure -o file \
  --cluster-name=svc01.lab.local \
  --public-addr=svc01.lab.local:443 \
  --cert-file=/var/lib/teleport/tls/teleport.crt \
  --key-file=/var/lib/teleport/tls/teleport.key

# --- Resolve the cluster name locally ---
echo "127.0.0.1 svc01.lab.local svc01" | sudo tee -a /etc/hosts

# --- Start the service ---
sudo systemctl enable teleport
sudo systemctl start teleport
sudo systemctl status teleport      # expect active (running)

# --- Create the admin user (auditor role required to view recordings) ---
# Prints an invite URL; open it (swap hostname for host-only IP if needed),
# set a password, and enroll a TOTP MFA app.
sudo tctl users add teleport-admin --roles=editor,access,auditor --logins=svcadmin,root

# --- Demo ---
# In the web UI: Resources -> SVC01 -> Connect -> login as svcadmin -> run
# commands -> exit. Then Session Recordings -> play back the session.
