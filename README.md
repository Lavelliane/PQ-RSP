# ProVerif Models — SGP.22 Post-Quantum Migration

Formal verification of four SGP.22 Consumer RSP migration configurations using ProVerif 2.05 under a Dolev-Yao attacker extended with a quantum oracle (`break_dh`) modelling Shor's algorithm.

See [results.md](results.md) for the full technical write-up, attack traces, and cryptographic primitive modelling.

---

## File Naming Convention

```
option_{a,b,c,d}[_suffix].pv
```

| Suffix | Attacker model | Session count |
|--------|---------------|---------------|
| *(none)* | Dolev-Yao + `break_dh` oracle | Unbounded (`!`) |
| `_classical` | Dolev-Yao only (no oracle) | Unbounded |
| `_pfs` | Dolev-Yao, phase-separated key reveal | Single session |

---

## Protocol Options

| Option | Auth | Key exchange | Transport |
|--------|------|-------------|-----------|
| **(a)** | ECDSA | ECDH P-256 | TLS 1.3 |
| **(b)** | ECDSA | ECDH P-256 | PQ-TLS |
| **(c)** | ECDSA | ECDH + ML-KEM-768 | PQ-TLS |
| **(d)** | ML-DSA-44 | ML-KEM-768 | PQ-TLS |

---

## Running

```bash
# Requires ProVerif 2.05

# Step 1 — classical baseline (confirm no pre-existing weakness)
proverif option_a_classical.pv
proverif option_b_classical.pv
proverif option_c_classical.pv
proverif option_d_classical.pv

# Step 2 — quantum oracle (break_dh active)
proverif option_a.pv   # Q5/Q6 FALSE — HNDL-vulnerable
proverif option_b.pv   # Q5/Q6 FALSE — HNDL-vulnerable
proverif option_c.pv   # Q5/Q6 TRUE, QD FALSE — HNDL-resistant
proverif option_d.pv   # Q5/Q6 TRUE — HNDL-resistant

# Step 3 — forward secrecy (phase-separated, no oracle)
proverif option_a_pfs.pv
proverif option_b_pfs.pv
proverif option_c_pfs.pv
proverif option_d_pfs.pv
```

Raw output is in [`results/`](results/).

---

## Queries

| ID | Property | Files |
|----|----------|-------|
| Q1–Q2 | Server authentication (agreement + injective) | all |
| Q3–Q4 | Client authentication (agreement + injective) | all |
| Q5 | Session key secrecy | all |
| Q6 | BPP confidentiality | all |
| Q7 | Binding integrity | all |
| QD | Oracle diagnostic — confirms `break_dh` fired on ECDH component | `option_c` only |
| Q8 | Forward secrecy (post-compromise) | `_pfs` variants |

---

## Key Results

| Property | (a) | (b) | (c) | (d) |
|----------|:---:|:---:|:---:|:---:|
| Mutual authentication | TRUE | TRUE | TRUE | TRUE |
| Session key secrecy | **FALSE** | **FALSE** | **TRUE** | **TRUE** |
| BPP confidentiality | **FALSE** | **FALSE** | **TRUE** | **TRUE** |
| Binding integrity | TRUE | TRUE | TRUE | TRUE |
| Forward secrecy | TRUE | TRUE | TRUE | TRUE |
| Oracle diagnostic | N/A | N/A | FALSE (fired) | N/A |

Options (a) and (b) are HNDL-vulnerable. Option (c) is HNDL-resistant via `combine_kdf` — the oracle fires on the ECDH component but the hybrid KDF blocks session key recovery. Option (d) is HNDL-resistant; the oracle is inapplicable.
