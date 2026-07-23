# ProVerif models: post-quantum migration of GSMA SGP.22 eSIM provisioning

Symbolic verification artifacts for the paper

> **Closing the HNDL Window in Consumer eSIM Provisioning: Hybrid Post-Quantum
> Migration, Formal Verification, and Deployment Constraints on eUICC Silicon**
> Jhury Kevin Lastre, Yongho Ko, Hoseok Kwon, and Ilsun You (Kookmin University).

This repository releases the complete [ProVerif](https://bblanche.gitlabpages.inria.fr/proverif/)
models used to verify Harvest-Now-Decrypt-Later (HNDL) resistance of four
post-quantum migration configurations of the GSMA SGP.22 Consumer Remote SIM
Provisioning protocol. It exists so that the paper's formal-verification results,
in particular the HNDL resistance of the hybrid configuration (c) under the
`break_dh` quantum oracle, can be reproduced and independently checked.

## What is modelled

Each session runs between three parties: the eUICC (the secure chip), the
SM-DP+ (the operator-side provisioning server), and the LPA (host software that
relays messages). The attacker is a Dolev–Yao adversary who fully controls the
network and passively reads the local APDU channel, extended with a quantum
oracle:

- **`break_dh`** — a Shor-style oracle that inverts ECDH from the two ephemeral
  public keys the attacker observes on the APDU channel. This models the HNDL
  threat.
- **`break_ecdsa`** — a separate oracle that recovers an ECDSA signing key from
  its verification key, modelling signature forgery once a quantum computer is
  available.

## The four configurations

| Option | Authentication | Key exchange | Transport |
|--------|----------------|--------------|-----------|
| **(a)** | ECDSA P-256 | ECDH P-256 | TLS 1.3 |
| **(b)** | ECDSA P-256 | ECDH P-256 | PQ-TLS |
| **(c)** | ECDSA P-256 | ECDH P-256 ∥ ML-KEM-768 (hybrid `combine_kdf`) | PQ-TLS |
| **(d)** | ML-DSA-44 | ML-KEM-768 | PQ-TLS |

## Requirements

[ProVerif 2.05](https://bblanche.gitlabpages.inria.fr/proverif/) on your `PATH`.
No other dependencies. Each `.pv` file is self-contained.

## Running

```bash
./run_all.sh              # run every model, print a verdict tally, save logs to results/
proverif option_c.pv      # or run a single model directly
```

`run_all.sh` takes roughly 15 minutes end to end (`option_c` and
`option_c_xwing` dominate). Expected verdicts are documented in
[`results/SUMMARY.md`](results/SUMMARY.md); pre-extracted `RESULT` lines from a
reference run are in `results/<model>.result.txt`.

## File map

| File | Scenario | Reproduces |
|------|----------|------------|
| `option_{a,b,c,d}_classical.pv` | Dolev–Yao only, no quantum oracle | Classical baseline: all queries TRUE |
| `option_{a,b,c,d}.pv` | `break_dh` oracle active (HNDL) | Main result: (a)/(b) FAIL, (c)/(d) resist |
| `option_c_xwing.pv` | (c) with a five-input X-Wing-style combiner | Combiner-robustness of (c) |
| `option_{a,b,c,d}_pfs.pv` | Phase-1 long-term key reveal, no oracle | Forward secrecy (Q8) |
| `option_a_break_ecdsa.pv` | `break_ecdsa` oracle, minimal two-event model | Authentication fails under forgery |
| `option_a_break_ecdsa_full.pv` | `break_ecdsa` oracle, full message ladder | Authentication fails on the full protocol |

## Queries

| ID | Property |
|----|----------|
| Q1–Q4 | Mutual authentication (agreement + injective correspondences) |
| Q5 | Session-key secrecy |
| Q6 | Bound Profile Package (BPP) confidentiality |
| Q7 | Binding integrity |
| Q8 | Forward secrecy / classical post-compromise secrecy (`_pfs` variants) |
| QD | Oracle diagnostic (config c): confirms `break_dh` fired on the ECDH branch |

`QD = FALSE` in `option_c.pv` is the intended result: it certifies that the
oracle **did** recover the ECDH-branch shared secret, while Q5/Q6 remaining TRUE
shows that `combine_kdf` still hides the session key because the ML-KEM branch is
unrecoverable.

## Assumptions

The models are symbolic. A TRUE verdict certifies the absence of structural
protocol attacks under the following assumptions, not concrete bit-security:
ECDH is classically hard and inverted only by `break_dh`; ML-KEM is IND-CCA2
secure (MLWE hard, no `break_kem`); ML-DSA is unforgeable (MSIS hard, no
`break_sign`); hashes/KDFs behave as random oracles; AES is semantically secure;
and `combine_kdf` is a pseudorandom function. See the paper for the full
assumption table and the computational-security discussion.

## Citation
```
@Article{s26154683,
AUTHOR = {Lastre, Jhury Kevin and Ko, Yongho and Kwon, Hoseok and You, Ilsun},
TITLE = {Closing the HNDL Window in Consumer eSIM Provisioning: Hybrid Post-Quantum Migration, Formal Verification, and Deployment Constraints on eUICC Silicon},
JOURNAL = {Sensors},
VOLUME = {26},
YEAR = {2026},
NUMBER = {15},
ARTICLE-NUMBER = {4683},
URL = {https://www.mdpi.com/1424-8220/26/15/4683},
ISSN = {1424-8220},
ABSTRACT = {Embedded Subscriber Identity Modules (eSIMs) enable consumer devices to install mobile subscriptions remotely under the GSMA SGP.22 standard for Remote SIM Provisioning (RSP). Because RSP sessions rely on classical elliptic-curve cryptography and eSIM profiles can remain active for 5 to 20 years, recorded provisioning traffic faces a concrete Harvest-Now–Decrypt-Later (HNDL) threat. Upgrading the network transport to post-quantum Transport Layer Security (TLS) is often assumed to be sufficient. However, SGP.22 exchanges the keys that protect the profile across the local host-to-chip interface, beneath the transport layer. This paper presents a systematic post-quantum cryptography (PQC) migration framework for consumer RSP. We model four configurations of the SGP.22 on-card key-agreement step and determine, under a quantum key-recovery adversary, which configurations resist HNDL and what resources they require. We combine symbolic verification in ProVerif with a device-grounded evaluation that pairs provisioning and memory observations from a sysmocom C2T research embedded Universal Integrated Circuit Card (eUICC) with strict-instruction-set PQC measurements on an STM32 Nucleo-F446RE development board with an ARM Cortex-M4F core. Among the configurations studied, hybrid classical and post-quantum key exchange is the minimum configuration that resists HNDL, whereas a fully post-quantum configuration also protects authentication against signature forgery. Under the tested platform and resource assumptions, volatile Random Access Memory (RAM), rather than computation, is the binding deployment constraint. We therefore propose a capability-negotiation mechanism that would match a migration configuration to the memory advertised by each card.},
DOI = {10.3390/s26154683}
}
```
If you use these models, please cite the paper above. 

## License

Released under the [MIT License](LICENSE).
