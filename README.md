# PQ-RSP

ProVerif models of the **GSMA SGP.22** consumer Remote SIM Provisioning (RSP) protocol: mutual authentication (Phase 1) and profile download (Phase 2) between **SM-DP+** and **eUICC**, with the **LPA** as relay where modeled. 

Post-quantum primitives (where used) follow NIST selections: **ML-DSA-44** for signatures and **ML-KEM-768** for key encapsulation (see `protocol-details.md` for step-to-primitive mapping).

## Options (four models)

| Option | File | Description |
|--------|------|-------------|
| **(a)** | [option_a.pv](pv-models/option_a.pv) | **Classical baseline.** Long-term and binding signatures use **ECDSA**; Phase 2 session keys use **ECDH** (ephemeral DH on both sides). ES9+ is a single **public** channel (TLS 1.3 not modeled; security is application-layer). |
| **(b)** | [option_b.pv](pv-models/option_b.pv) | **PQ-TLS transport only.** Same crypto as **(a)** (ECDSA + ECDH). ES9+ LPA↔SM-DP+ is modeled as a **private** channel (`c_pqtls`) with an explicit **LPA relay**; eUICC↔LPA stays public. Isolates transport protection from app-layer proofs. |
| **(c)** | [option_c.pv](pv-models/option_c.pv) | **PQ authentication, classical KA.** All certificate-backed signatures use **ML-DSA-44**; Phase 2 key agreement remains **ECDH**; `bind_body` includes both ephemeral **EC** public keys (same shape as (a)/(b)). |
| **(d)** | [option_d.pv](pv-models/option_d.pv) | **Full PQC.** Signatures use **ML-DSA-44**; Phase 2 uses **ML-KEM-768** (eUICC KEM keygen, SM-DP+ encapsulates). **No ECDH** in the model; `bind_body` is **ML-KEM-shaped** (transaction ID + KEM ciphertext + BPP), not two EC keys. |

## Contents

| File | Role |
|------|------|
| [protocol-details.md](protocol-details.md) | Protocol step reference and ProVerif modeling notes (notation, options, security goals) |
| [pv-models/option_a.pv](pv-models/option_a.pv) | Option **(a)**: ECDSA + ECDH, public channel |
| [pv-models/option_b.pv](pv-models/option_b.pv) | Option **(b)**: same as (a); PQ-TLS-style ES9+ (`c_pqtls` + relay) |
| [pv-models/option_c.pv](pv-models/option_c.pv) | Option **(c)**: **ML-DSA-44** + ECDH |
| [pv-models/option_d.pv](pv-models/option_d.pv) | Option **(d)**: **ML-DSA-44** + **ML-KEM-768** |

Each `.pv` file is self-contained (no includes).

## Diagrams

Sequence diagrams for consumer RSP (SGP.22-style flows):

| File | Phase |
|------|--------|
| [CONSUMER-RSP-auth.png](diagrams/CONSUMER-RSP-auth.png) | Phase 1: mutual authentication (challenge, `AuthenticateServer` / `AuthenticateClient`) |
| [CONSUMER-RSP-download.png](diagrams/CONSUMER-RSP-download.png) | Phase 2: profile download (`PrepareDownload`, `GetBoundProfilePackage`, `LoadBoundProfilePackage`) |

![Phase 1: mutual authentication](diagrams/CONSUMER-RSP-auth.png)

![Phase 2: profile download](diagrams/CONSUMER-RSP-download.png)

## Verification

Requires [ProVerif](https://proverif.inria.fr/) (tested with 2.05).

```bash
proverif pv-models/option_a.pv
proverif pv-models/option_b.pv
proverif pv-models/option_c.pv
proverif pv-models/option_d.pv
```

Each model declares correspondence, secrecy, and binding queries aligned with `protocol-details.md` (mutual auth, session/profile secrecy, install binding, forward-secrecy-style phase checks).
