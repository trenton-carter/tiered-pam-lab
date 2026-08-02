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

---

## Architecture

_[ ] Insert architecture diagram here (draw.io / Excalidraw export)._

| Host  | Role                                              | OS                     |
|-------|---------------------------------------------------|------------------------|
| DC01  | Domain controller, DNS, tiering GPOs              | Windows Server 2025    |
| SRV01 | Tier 1 member server (rotation + session target)  | Windows Server 2025    |
| SVC01 | Vault + Teleport + step-ca                         | Ubuntu Server 24.04    |

Domain: `lab.local` (adjust to taste). Private lab network: `10.10.10.0/24`.

---

## What this maps to in CyberArk

| CyberArk component                        | This lab's open-source analog                     | Status |
|-------------------------------------------|---------------------------------------------------|--------|
| Password Vault / Safes                    | HashiCorp Vault + scoped policies                 | [ ]    |
| Central Policy Manager (credential rotation) | Vault AD secrets engine auto-rotation          | [ ]    |
| Privileged Session Manager (PSM)          | Teleport session recording (RDP/SSH)              | [ ]    |
| Secure Infrastructure Access (SIA)        | Teleport brokered access + just-in-time requests  | [ ]    |
| Certificate Manager / machine identity    | step-ca short-lived certs + auto-renewal          | [ ]    |
| PVWA (web portal)                         | Vault UI + Teleport web UI                         | [ ]    |

---

## Requirements this lab demonstrates

Phrases in the left column are drawn from real entry-level IAM/PAM job
descriptions. Right column links to where each is implemented.

| Requirement                                      | Implemented by                                        | Evidence / location   |
|--------------------------------------------------|-------------------------------------------------------|-----------------------|
| Privileged Access Management (PAM)               | Teleport brokered access + Vault credential vaulting  | `/teleport`, `/vault` |
| Password rotation                                | Vault AD secrets engine, scheduled rotation           | `/vault/rotation`     |
| Session monitoring / management                  | Teleport session recording + playback                 | `/teleport/sessions`  |
| Least-privilege principles                       | Tier 0/1/2 admin model + GPO deny-logon boundaries    | `/ad/tiering`         |
| Privileged account lifecycle management          | Onboarding / offboarding runbooks                     | `/docs/runbooks`      |
| Active Directory administration                  | Windows Server 2025 AD DS domain                      | `/ad`                 |
| Machine identity management                      | step-ca certificate issuance to hosts                 | `/step-ca`            |
| Certificate management                           | step-ca ACME issuance + expiry monitoring             | `/step-ca`            |
| Session, password, and access workflows          | Vault policies + Teleport RBAC + JIT approval         | `/vault`, `/teleport` |
| Technical documentation / operational procedures | This repo `/docs`                                     | `/docs`               |
| Access reviews / segregation of duties           | See companion **IAM Governance Toolkit** repo         | _link_                |

---

## Reproduce this lab

_[ ] Step-by-step build instructions go here as you complete each phase, so a
reviewer (or future you) can rebuild it. Keep it terse and command-first._

1. Network + VMs
2. Promote domain, create tiering OUs and accounts
3. GPO deny-logon boundaries
4. Vault install + AD secrets engine + rotation
5. Teleport install + agent enrollment + session recording
6. step-ca + certificate issuance

---

## Threat model — what each control mitigates

_[ ] Fill in after the build. One row per control: attack it stops, and how
you verified. Example rows to complete:_

| Control                     | Attack it mitigates                          | How verified          |
|-----------------------------|----------------------------------------------|-----------------------|
| Tiered admin + deny-logon   | Credential theft pivot from workstation to DC | [ ]                  |
| Vault rotation              | Long-lived static service-account passwords   | [ ]                  |
| Teleport session recording  | Undetected/unaudited privileged activity      | [ ]                  |
| step-ca short-lived certs   | Stolen long-lived machine credentials         | [ ]                  |

---

## At enterprise scale

_[ ] A short, honest section on what this lab simplifies and what a production
deployment adds (HA, separate Vault cluster, HSM-backed CA, real IdP federation,
break-glass procedures). Shows you know the lab isn't production — a maturity
signal reviewers notice._

---

## Skills demonstrated

Active Directory · tiered least-privilege design · Group Policy · credential
vaulting · automated secret rotation · privileged session brokering and
recording · machine identity / PKI · PowerShell · Linux service administration ·
security documentation and threat modeling.
