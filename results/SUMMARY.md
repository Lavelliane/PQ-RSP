# ProVerif verdict summary

All results below were produced with **ProVerif 2.05**. The per-model `RESULT`
lines are in `results/<model>.result.txt`; run `./run_all.sh` to regenerate the
full logs. `QD` is a diagnostic query (see the repository README).

## 1. Classical baseline (Dolev–Yao attacker, no quantum oracle)

Establishes that any later failure is caused by the quantum oracle, not by a
pre-existing protocol weakness.

| Property | (a) | (b) | (c) | (d) |
|---|:--:|:--:|:--:|:--:|
| Q1–Q4 mutual authentication | TRUE | TRUE | TRUE | TRUE |
| Q5 session-key secrecy | TRUE | TRUE | TRUE | TRUE |
| Q6 BPP confidentiality | TRUE | TRUE | TRUE | TRUE |
| Q7 binding integrity | TRUE | TRUE | TRUE | TRUE |
| QD ECDH-branch diagnostic | n/a | n/a | TRUE | n/a |

## 2. Quantum oracle `break_dh` active (HNDL scenario)

| Property | (a) | (b) | (c) | (d) |
|---|:--:|:--:|:--:|:--:|
| Q1–Q4 mutual authentication | TRUE | TRUE | TRUE | TRUE |
| Q5 session-key secrecy | **FALSE** | **FALSE** | **TRUE** | **TRUE** |
| Q6 BPP confidentiality | **FALSE** | **FALSE** | **TRUE** | **TRUE** |
| Q7 binding integrity | TRUE | TRUE | TRUE | TRUE |
| QD ECDH-branch diagnostic | n/a | n/a | **FALSE (oracle fired, blocked)** | n/a |

- **(a), (b) are HNDL-vulnerable.** The oracle recovers the ECDH shared secret
  from the two ephemeral public keys observed on the public APDU channel and
  derives the session key. PQ-TLS on the transport (b) does not help: the keys
  are already in cleartext on the local bus.
- **(c) is HNDL-resistant.** `QD = FALSE` confirms the oracle *fired* and
  recovered the ECDH-branch secret `shS_ecdh`, yet Q5/Q6 stay TRUE because
  `combine_kdf` also requires the ML-KEM branch `shS_mlkem`, which is not
  recoverable under the MLWE assumption.
- **(d) is HNDL-resistant.** No ECDH operation exists, so the oracle is
  vacuously inapplicable.

## 3. X-Wing combiner companion for configuration (c)

`option_c_xwing.pv` replaces the two-input `combine_kdf` with a five-input
X-Wing-style combiner. Every verdict is identical to `option_c.pv`, so the
HNDL-resistance of (c) is robust to the combiner choice in the symbolic model.

| Property | combine_kdf (option_c) | xwing_combine (option_c_xwing) |
|---|:--:|:--:|
| Q1–Q4 | TRUE | TRUE |
| Q5, Q6 | TRUE | TRUE |
| Q7 | TRUE | TRUE |
| QD | FALSE (fired, blocked) | FALSE (fired, blocked) |

## 4. Forward secrecy (`_pfs`, phase-1 long-term key reveal, no oracle)

Q8 (classical post-compromise secrecy): all TRUE for (a)–(d).

## 5. Signature-forgery oracle `break_ecdsa`

Shows why ECDSA-retaining configurations lose authentication once a quantum
computer can forge signatures, motivating configuration (d).

| Model | Q1 | Q2 | Q3 | Q4 | Q7 |
|---|:--:|:--:|:--:|:--:|:--:|
| `option_a_break_ecdsa` (2-event demo) | FALSE | FALSE | — | — | — |
| `option_a_break_ecdsa_full` (full ladder) | FALSE | FALSE | FALSE | FALSE | FALSE |
