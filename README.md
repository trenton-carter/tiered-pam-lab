# Tiered Privileged Access Lab

A self-hosted lab that implements the core controls of an enterprise Privileged
Access Management (PAM) program — credential vaulting, automated rotation,
brokered and recorded privileged sessions, tiered least-privilege administration,
and machine identity — using open-source tooling on a Windows Active Directory
domain.

> **Why this exists.** Commercial PAM platforms like CyberArk solve a specific
> set of problems: who can use a privileged credential, when, how it's rotated,
> and what happened during the session. This lab reproduces those *problems and
> controls* with open-source equivalents, so the concepts are demonstrable
> without an enterprise license. Each control below is mapped to its CyberArk
> analog.

Every control in this lab is **built and verified** — each phase ends with a
proof (a denied logon, a rejected rotated password, a replayed session
recording, a renewed short-lived certificate), captured in the linked build
logs.

---

## Build logs

Each phase is documented end to end with commands, screenshots, gotchas, and
verification steps.

| Phase | Focus | Log |
|-------|-------|-----|
| 1 | Domain foundation (forest, DNS, static addressing, validation) | [docs/01-domain-foundation.md](docs/01-domain-foundation.md) |
| 2 | Tiered admin model (Tier 0/1/2 OUs, accounts, deny-logon GPOs) | [docs/02-tiered-admin-model.md](docs/02-tiered-admin-model.md) |
| 3 | Member server & tiering proof (join, GPO, runas denial) | [docs/03-member-server-tiering-proof.md](docs/03-member-server-tiering-proof.md) |
| 4 | Vault credential vaulting & rotation over LDAPS | [docs/04-vault-credential-rotation.md](docs/04-vault-credential-rotation.md) |
| 5 | Teleport brokered access & session recording | [docs/05-teleport-session-recording.md](docs/05-teleport-session-recording.md) |
| 6 | step-ca machine identity & short-lived certificates | [docs/06-stepca-machine-identity.md](docs/06-stepca-machine-identity.md) |

Reusable scripts live in [`scripts/`](scripts/).

---

## Architecture

| Host  | Role                                              | OS                     |
|-------|---------------------------------------------------|------------------------|
| DC01  | Domain controller, DNS, AD CS enterprise CA, tiering GPOs | Windows Server 2025 |
| SRV01 | Tier 1 member server (tiering-proof target)       | Windows Server 2025    |
| SVC01 | Vault + Teleport + step-ca                         | Ubuntu Server 24.04    |

Domain: `lab.local` (NetBIOS `LAB`). Isolated lab network: `10.10.10.0/24`
(VirtualBox NAT Network, DHCP disabled, static addressing). SVC01 is multi-homed
with a second host-only interface (`192.168.56.0/24`) for host access to the
Vault and Teleport web UIs.

**Boot order:** DC01 first (the other hosts depend on it for DNS and
authentication), then SRV01/SVC01.

---

## What this maps to in CyberArk

| CyberArk component                        | This lab's open-source analog                     | Status |
|-------------------------------------------|---------------------------------------------------|--------|
| Password Vault / Safes                    | HashiCorp Vault + scoped policies                 | Built |
| Central Policy Manager (credential rotation) | Vault LDAP secrets engine — static-role rotation over LDAPS | Built |
| Privileged Session Manager (PSM)          | Teleport session recording + replay               | Built |
| Secure Infrastructure Access (SIA)        | Teleport brokered access (MFA, short-lived certs) | Built |
| Certificate Manager / machine identity    | step-ca short-lived certs + ACME auto-renewal     | Built |
| PVWA (web portal)                         | Vault UI + Teleport web UI                         | Built |
| Shared privileged account management      | Vault check-out/check-in library (auto-rotate on return) | Built |

> **Note on parity.** Some capabilities are gated behind Vault/Teleport
> Enterprise licensing (e.g. unattended timer-based rotation schedules). Where
> that applies, the underlying *mechanism* is demonstrated on the community
> edition via manual and event-triggered rotation — the build logs call out the
> boundary honestly.

---

## Requirements this lab demonstrates

Phrases in the left column are drawn from real entry-level IAM/PAM job
descriptions. The right column links to where each is implemented and verified.

| Requirement                                      | Implemented by                                        | Evidence |
|--------------------------------------------------|-------------------------------------------------------|----------|
| Privileged Access Management (PAM)               | Vault credential vaulting + Teleport brokered access  | [P4](docs/04-vault-credential-rotation.md), [P5](docs/05-teleport-session-recording.md) |
| Password / credential rotation                   | Vault LDAP secrets engine — static-role & check-in rotation over LDAPS | [P4](docs/04-vault-credential-rotation.md) |
| Session monitoring / management                  | Teleport session recording + playback                 | [P5](docs/05-teleport-session-recording.md) |
| Least-privilege principles                       | Tier 0/1/2 admin model + GPO deny-logon boundaries    | [P2](docs/02-tiered-admin-model.md), [P3](docs/03-member-server-tiering-proof.md) |
| Privileged account lifecycle management          | Service-account onboarding into Vault management + rotation | [P4](docs/04-vault-credential-rotation.md) |
| Active Directory administration                  | Windows Server 2025 AD DS forest, DNS, OUs, GPOs      | [P1](docs/01-domain-foundation.md), [P2](docs/02-tiered-admin-model.md) |
| Multi-factor authentication (MFA)                | Teleport TOTP enforced on privileged access           | [P5](docs/05-teleport-session-recording.md) |
| Machine identity management                      | step-ca short-lived host/service certificates         | [P6](docs/06-stepca-machine-identity.md) |
| Certificate management / PKI                     | AD CS enterprise CA (LDAPS) + step-ca ACME issuance   | [P4](docs/04-vault-credential-rotation.md), [P6](docs/06-stepca-machine-identity.md) |
| Access control workflows (RBAC)                  | Vault policies + AD delegation + Teleport roles       | [P4](docs/04-vault-credential-rotation.md), [P5](docs/05-teleport-session-recording.md) |
| Technical documentation / operational procedures | This repo's build logs and scripts                    | [docs/](docs/), [scripts/](scripts/) |
| Access reviews / segregation of duties           | Companion **IAM Governance Toolkit** repo (in progress) | [AD Identity Governance Toolkit](https://github.com/trenton-carter/ad-governance-toolkit) |

---

## Threat model — what each control mitigates

| Control                     | Attack it mitigates                                   | How verified |
|-----------------------------|-------------------------------------------------------|--------------|
| Tiered admin + deny-logon GPOs | Credential-theft pivot (pass-the-hash) from a lower tier to the domain controller | `runas` as a Tier 0 account on a Tier 1 server denied with error 1385 ([P3](docs/03-member-server-tiering-proof.md)) |
| Vault credential rotation   | Long-lived, hardcoded static service-account passwords | Old password rejected by AD after rotation; current value retrievable only from Vault ([P4](docs/04-vault-credential-rotation.md)) |
| Vault rotate-root           | Human knowledge of the privileged bind credential      | Bind password rotated to a value only Vault holds; setup-time password invalidated ([P4](docs/04-vault-credential-rotation.md)) |
| Teleport session recording  | Undetected / unaudited privileged activity             | Full session replayed from the audit log with user, resource, and every command ([P5](docs/05-teleport-session-recording.md)) |
| Teleport MFA + short-lived certs | Standing SSH keys / reusable stolen credentials   | Access requires TOTP and issues expiring certificates rather than static keys ([P5](docs/05-teleport-session-recording.md)) |
| step-ca short-lived certs   | Stolen long-lived machine credentials                  | 24h certificate lifetime with credential-less auto-renewal; passive revocation ([P6](docs/06-stepca-machine-identity.md)) |

---

## At enterprise scale

This is a single-node teaching lab; a production deployment differs in
significant ways, honestly noted here:

- **High availability & storage.** Vault runs single-node with file storage; a
  production cluster uses integrated Raft/Consul with multiple nodes and
  auto-unseal via a cloud KMS or HSM, rather than manual Shamir unseal.
- **HSM-backed CA keys.** The AD CS and step-ca private keys live on disk here;
  production CAs keep keys in an HSM.
- **Real TLS trust.** Teleport's web cert is self-signed in the lab; internally
  it would be issued by the enterprise CA, and public deployments use ACME/Let's
  Encrypt. LDAPS already uses a cert from the lab's own enterprise CA.
- **Identity federation.** A production environment federates to a real IdP
  (Entra ID / Okta) for SSO and conditional access, rather than local accounts.
- **Break-glass & recovery.** Production adds documented emergency-access
  procedures and key-recovery runbooks (e.g. recovering a Vault-owned bind
  credential by resetting it in AD).
- **Scheduled rotation & monitoring.** Unattended timer-based rotation and
  certificate-expiry alerting are Enterprise/tooling additions on top of the
  mechanisms demonstrated here.

Naming these boundaries is deliberate: the lab proves the *controls*, and this
section shows where the lab ends and production begins.

---

## Skills demonstrated

Active Directory administration · tiered least-privilege design · Group Policy ·
credential vaulting · automated secret rotation · privileged session brokering
and recording · MFA enforcement · PKI (enterprise CA + LDAPS, short-lived certs,
ACME) · machine identity · PowerShell · Linux service administration · secure
networking · security documentation and threat modeling.

---

## Companion projects

- **[AD Identity Governance Toolkit](https://github.com/trenton-carter/ad-governance-toolkit)** — PowerShell toolkit for privileged access inventory, stale-account detection, Segregation of Duties analysis, and access-review certification against Active Directory, with a Pester test suite and a documented Microsoft Graph / Entra extension path.
