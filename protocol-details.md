# SGP.22 Consumer RSP: Full Protocol Step Reference

> **Options:**
> - **(a)** Classical baseline — ECDSA auth + ECDH key exchange, TLS 1.3 transport
> - **(b)** PQ-TLS transport only — ECDSA auth + ECDH key exchange, PQ-TLS transport
> - **(c)** Hybrid — classical ECDSA auth/certs + ML-KEM key exchange, PQ-TLS transport
> - **(d)** Full PQC — ML-DSA auth + ML-KEM key exchange, PQ-TLS transport

---

## Notation

| Symbol | Description |
|---|---|
| SM-DP+ | Subscription Manager Data Preparation Plus |
| LPA | Local Profile Assistant (host device mediator) |
| eUICC | Embedded Universal Integrated Circuit Card |
| CI | GSMA Certificate Issuer (trust anchor) |

### Keys and Certificates

| Symbol | Description |
|---|---|
| SK.DPauth.ECDSA | SM-DP+ authentication signing key (ECDSA) — options (a, b, c) |
| SK.DPauth.MLDSA | SM-DP+ authentication signing key (ML-DSA-44) — option (d) |
| SK.DPpb.ECDSA | SM-DP+ profile binding signing key (ECDSA) — options (a, b, c) |
| SK.DPpb.MLDSA | SM-DP+ profile binding signing key (ML-DSA-44) — option (d) |
| SK.EUICC.ECDSA | eUICC long-term signing key (ECDSA) — options (a, b, c) |
| SK.EUICC.MLDSA | eUICC long-term signing key (ML-DSA-44) — option (d) |
| otSK.EUICC.ECKA | eUICC ephemeral ECDH private key — options (a, b) |
| otPK.EUICC.ECKA | eUICC ephemeral ECDH public key — options (a, b) |
| otSK.EUICC.MLKEM | eUICC ephemeral ML-KEM secret key — options (c, d) |
| otPK.EUICC.MLKEM | eUICC ephemeral ML-KEM public key — options (c, d) |
| otSK.DP.ECKA | SM-DP+ ephemeral ECDH private key — options (a, b) |
| otPK.DP.ECKA | SM-DP+ ephemeral ECDH public key — options (a, b) |
| PK.CI.ECDSA | CI root public key (ECDSA) |
| PK.CI.MLDSA | CI root public key (ML-DSA-44) |
| CERT.DPauth.ECDSA | SM-DP+ authentication certificate (ECDSA) — options (a, b, c) |
| CERT.DPauth.MLDSA | SM-DP+ authentication certificate (ML-DSA) — option (d) |
| CERT.DPpb.ECDSA | SM-DP+ profile binding certificate (ECDSA) — options (a, b, c) |
| CERT.DPpb.MLDSA | SM-DP+ profile binding certificate (ML-DSA) — option (d) |
| CERT.EUICC.ECDSA | eUICC certificate (ECDSA) — options (a, b, c) |
| CERT.EUICC.MLDSA | eUICC certificate (ML-DSA) — option (d) |
| CERT.EUM.ECDSA | eUICC Manufacturer certificate (ECDSA) — options (a, b, c) |
| CERT.EUM.MLDSA | eUICC Manufacturer certificate (ML-DSA) — option (d) |

### Cryptographic Primitives per Option

| Operation | Option (a) | Option (b) | Option (c) | Option (d) |
|---|---|---|---|---|
| Authentication sig | ECDSA | ECDSA | ECDSA | ML-DSA-44 |
| Profile binding sig | ECDSA | ECDSA | ECDSA | ML-DSA-44 |
| eUICC ephemeral KA | ECDH (ECKA) | ECDH (ECKA) | ML-KEM-768 | ML-KEM-768 |
| SM-DP+ key agreement | DH | DH | ML-KEM Encaps | ML-KEM Encaps |
| eUICC key recovery | DH | DH | ML-KEM Decaps | ML-KEM Decaps |
| ES9+ transport | TLS 1.3 | PQ-TLS | PQ-TLS | PQ-TLS |
| BPP encryption | AES-128 (BSP) | AES-128 (BSP) | AES-128 (BSP) | AES-128 (BSP) |

### Initial Credential State

**SM-DP+ holds at session start:**

| Options (a, b, c) | Option (d) |
|---|---|
| CERT.DPauth.ECDSA, PK.DPauth.ECDSA, SK.DPauth.ECDSA | CERT.DPauth.MLDSA, PK.DPauth.MLDSA, SK.DPauth.MLDSA |
| CERT.DPpb.ECDSA, PK.DPpb.ECDSA, SK.DPpb.ECDSA | CERT.DPpb.MLDSA, PK.DPpb.MLDSA, SK.DPpb.MLDSA |

**eUICC holds at session start:**

| Options (a, b, c) | Option (d) |
|---|---|
| CERT.EUICC.ECDSA, PK.EUICC.ECDSA, SK.EUICC.ECDSA | CERT.EUICC.MLDSA, PK.EUICC.MLDSA, SK.EUICC.MLDSA |

---

## Phase 1: Mutual Authentication (Steps 1–16)

---

### Step 1: eUICC Info Retrieval

**Flow: LPA → eUICC → LPA**

```
LPA sends:    GetEUICCInfo
eUICC returns: { eUIICCInfo1 }
```

`eUIICCInfo1` contains `euiccCiPKIdListForVerification` and `euiccCiPKIdListForSigning`. No cryptographic operations. All options identical.

---

### Step 2: Challenge Request

**Flow: LPA → eUICC**

```
LPA sends: GetEUICCChallenge
```

No cryptographic operations. All options identical.

---

### Step 3: eUICC Challenge Generation

**Actor: eUICC (internal)**

```
eUICC generates: eUIICCChallenge  (16-byte random nonce)
```

All options identical.

---

### Step 4: Challenge Delivery

**Flow: eUICC → LPA**

```
eUICC returns: { eUIICCChallenge }
```

All options identical.

---

### Step 5: Secure Channel Establishment

**Flow: LPA ↔ SM-DP+ (ES9+ interface)**

```
Option (a)     : TLS 1.3 Connection
Options (b, c, d): PQ-TLS or KEM-TLS Secure Channel
```

The eUICC never directly terminates this TLS session; the LPA acts as the TLS endpoint. This is the **only step** where option (b) differs from option (a). Options (b), (c), and (d) are identical at this step.

---

### Step 6: LPA Pre-checks

**Actor: LPA (internal)**

```
6a. Check SM-DP+ address
6b. Verify euiccCiPKIdListForVerification
6c. Verify euiccCiPKIdListForSigning
```

All options identical.

---

### Step 7: Challenge Forwarding to SM-DP+

**Flow: LPA → SM-DP+**

```
LPA sends: { eUIICCChallenge, eUIICCInfo1, SM-DP+ address }
```

All options identical.

---

### Step 8: Server Authentication Data Construction

**Actor: SM-DP+ (internal)**

```
8a. Generate: TransactionID
8b. Generate: serverChallenge  (random nonce)
8c. Select:   one CI PK from euiccCiPKIdListForSigning
              → euiccCiPKIdToBeUsed

8d. Construct: serverSigned1 = {
                 TransactionID,
                 eUIICCChallenge,
                 euiccCiPKIdToBeUsed,
                 serverChallenge,
                 SM-DP+ address
               }

8e. Compute serverSignature1:
    Options (a, b, c): ECDSA.Sign( SK.DPauth.ECDSA, serverSigned1 )
    Option  (d):       MLDSA.Sign( SK.DPauth.MLDSA,  serverSigned1 )
```

`serverSigned1` structure is identical across all options; only the signing key and algorithm differ at 8e.

> **ProVerif note:** model 8e as two separate branches on option flag.

---

### Step 9: Server Authentication Message

**Flow: SM-DP+ → LPA**

```
SM-DP+ sends: {
  TransactionID,
  serverSigned1,
  serverSignature1,
  euiccCiPKIdToBeUsed,
  CERT.DPauth.ECDSA    ← options (a, b, c)
  CERT.DPauth.MLDSA    ← option  (d)
}
```

Certificate type matches the signing algorithm used in step 8e.

---

### Step 10: LPA Processing

**Actor: LPA (internal)**

```
10a. Verify SM-DP+ address
10b. Generate: ctxParams1 = activation code token
```

All options identical.

---

### Step 11: AuthenticateServer Command

**Flow: LPA → eUICC**

```
LPA sends AuthenticateServer() = {
  serverSigned1,
  serverSignature1,
  euiccCiPKIdToBeUsed,
  CERT.DPauth.ECDSA    ← options (a, b, c)
  CERT.DPauth.MLDSA    ← option  (d)
  ctxParams1
}
```

Message structure is identical across all options; only the certificate type varies.

---

### Step 12: eUICC Server Verification

**Actor: eUICC (internal)**

```
Options (a, b, c):
  12a. Verify CERT.DPauth.ECDSA using relevant PK.CI.ECDSA
  12b. Extract: PK.DPauth.ECDSA ← CERT.DPauth.ECDSA
  12c. Verify: ECDSA.Verify( PK.DPauth.ECDSA,
                             serverSigned1,
                             serverSignature1 )

Option (d):
  12a. Verify CERT.DPauth.MLDSA using relevant PK.CI.MLDSA
  12b. Extract: PK.DPauth.MLDSA ← CERT.DPauth.MLDSA
  12c. Verify: MLDSA.Verify( PK.DPauth.MLDSA,
                             serverSigned1,
                             serverSignature1 )

All options (shared):
  12d. Verify: eUIICCChallenge in serverSigned1
               matches previously generated challenge (step 3)
  12e. Verify: euiccCiPKIdToBeUsed is in supported list
```

> **ProVerif note:** step 12c is the primary authentication goal — injective agreement on `serverSigned1` from eUICC's perspective. Step 12d prevents cross-session replay.

---

### Step 13: eUICC Signed Response Construction

**Actor: eUICC (internal)**

```
13a. Construct: euiccSigned1 = {
                  TransactionID,
                  serverChallenge,
                  euiccInfo2,
                  ctxParams1
                }

13b. Compute euiccSignature1:
     Options (a, b, c): ECDSA.Sign( SK.EUICC.ECDSA, euiccSigned1 )
     Option  (d):       MLDSA.Sign( SK.EUICC.MLDSA,  euiccSigned1 )
```

> **ProVerif note:** `euiccSigned1` binds `serverChallenge` (from step 8b), preventing server impersonation replay.

---

### Step 14: eUICC Authentication Response

**Flow: eUICC → LPA**

```
eUICC returns: {
  euiccSigned1,
  euiccSignature1,
  CERT.EUICC.ECDSA  ← options (a, b, c)
  CERT.EUICC.MLDSA  ← option  (d)
  CERT.EUM.ECDSA    ← options (a, b, c)
  CERT.EUM.MLDSA    ← option  (d)
}
```

---

### Step 15: AuthenticateClient Command

**Flow: LPA → SM-DP+**

```
LPA sends AuthenticateClient() = {
  euiccSigned1,
  euiccSignature1,
  CERT.EUICC.ECDSA  ← options (a, b, c)
  CERT.EUICC.MLDSA  ← option  (d)
  CERT.EUM.ECDSA    ← options (a, b, c)
  CERT.EUM.MLDSA    ← option  (d)
}
```

LPA passes through without modification.

---

### Step 16: SM-DP+ Client Verification

**Actor: SM-DP+ (internal)**

```
16a. Verify: TransactionID matches step 8a

Options (a, b, c):
  16b. Verify CERT.EUICC.ECDSA and CERT.EUM.ECDSA
       using PK.CI.ECDSA
  16c. Extract: PK.EUICC.ECDSA ← CERT.EUICC.ECDSA
  16d. Verify: ECDSA.Verify( PK.EUICC.ECDSA,
                             euiccSigned1,
                             euiccSignature1 )

Option (d):
  16b. Verify CERT.EUICC.MLDSA and CERT.EUM.MLDSA
       using PK.CI.MLDSA
  16c. Extract: PK.EUICC.MLDSA ← CERT.EUICC.MLDSA
  16d. Verify: MLDSA.Verify( PK.EUICC.MLDSA,
                             euiccSigned1,
                             euiccSignature1 )

All options (shared):
  16e. Verify: serverChallenge in euiccSigned1
               matches previously generated challenge (step 8b)
```

> **ProVerif note:** 16d is the primary eUICC authentication goal from SM-DP+'s perspective. Step 16e prevents reflection attacks.

---

## Phase 2: Profile Download (Steps 17–29)

---

### Step 17: Profile Binding Data Construction

**Actor: SM-DP+ (internal)**

```
17a. Generate: Profile Metadata

17b. Construct: smdpSigned2 = { TransactionID }

17c. Compute smdpSignature2:
     Options (a, b, c): ECDSA.Sign( SK.DPpb.ECDSA, smdpSigned2 )
     Option  (d):       MLDSA.Sign( SK.DPpb.MLDSA,  smdpSigned2 )
```

`SK.DPpb` is a separate profile-binding keypair from `SK.DPauth` used in Phase 1.

---

### Step 18: PrepareDownload to LPA

**Flow: SM-DP+ → LPA**

```
SM-DP+ sends PrepareDownload = {
  TransactionID,
  Profile Metadata,
  smdpSigned2,
  smdpSignature2,
  CERT.DPpb.ECDSA    ← options (a, b, c)
  CERT.DPpb.MLDSA    ← option  (d)
}
```

---

### Step 19: PrepareDownload to eUICC

**Flow: LPA → eUICC**

```
LPA forwards PrepareDownload = {
  TransactionID,
  Profile Metadata,
  smdpSigned2,
  smdpSignature2,
  CERT.DPpb.ECDSA    ← options (a, b, c)
  CERT.DPpb.MLDSA    ← option  (d)
}
```

LPA passes through without modification. All options identical in relay behaviour.

---

### Step 20: eUICC Profile Binding Verification

**Actor: eUICC (internal)**

```
Options (a, b, c):
  20a. Verify CERT.DPpb.ECDSA using PK.CI.ECDSA
  20b. Verify: ECDSA.Verify( PK.DPpb.ECDSA,
                             smdpSigned2,
                             smdpSignature2 )

Option (d):
  20a. Verify CERT.DPpb.MLDSA using PK.CI.MLDSA
  20b. Verify: MLDSA.Verify( PK.DPpb.MLDSA,
                             smdpSigned2,
                             smdpSignature2 )

All options (shared):
  20c. Verify: smdpSigned2 content (TransactionID binding)
```

---

### Step 21: eUICC Ephemeral Key Generation

**Actor: eUICC (internal)**

> This is the primary architectural divergence between options (a, b) and options (c, d).

```
Options (a, b): ECDH path:
  21a. Generate ephemeral ECDH key pair:
         ( otPK.EUICC.ECKA, otSK.EUICC.ECKA )

  21b. Construct: euiccSigned2 = {
                    TransactionID,
                    otPK.EUICC.ECKA
                  }

Options (c, d): ML-KEM path:
  21a. Generate ephemeral ML-KEM-768 key pair:
         ( otPK.EUICC.MLKEM, otSK.EUICC.MLKEM ) ← ML-KEM.KeyGen()

  21b. Construct: euiccSigned2 = {
                    TransactionID,
                    otPK.EUICC.MLKEM
                  }

Signing euiccSigned2 (all options):
  21c. Options (a, b, c): ECDSA.Sign( SK.EUICC.ECDSA,
                                      euiccSigned2 || smdpSignature2 )
  21c. Option  (d):       MLDSA.Sign( SK.EUICC.MLDSA,
                                      euiccSigned2 || smdpSignature2 )
```

> **ProVerif note:** the concatenation `euiccSigned2 || smdpSignature2` in 21c binds the ephemeral key to this specific download session, preventing key reuse across transactions. Under options (c, d) the KEM is single-sided: only the eUICC generates a KEM keypair; the SM-DP+ encapsulates to it.

---

### Step 22: eUICC Key Material Delivery

**Flow: eUICC → LPA**

```
eUICC sends: { euiccSigned2, euiccSignature2 }
```

All options identical in message structure (content differs by option per step 21).

---

### Step 23: GetBoundProfilePackage Request

**Flow: LPA → SM-DP+ (ES9+ interface)**

```
LPA sends ES9+.GetBoundProfilePackage = {
  euiccSigned2,
  euiccSignature2
}
```

All options identical.

---

### Step 24: SM-DP+ BPP Construction and Key Agreement

**Actor: SM-DP+ (internal)**

> This step differs fundamentally between the ECDH path (a, b) and the ML-KEM path (c, d). Signature verification also splits between (a, b, c) and (d).

```
Signature verification:
  Options (a, b, c): 24a. ECDSA.Verify( PK.EUICC.ECDSA,
                                         euiccSigned2,
                                         euiccSignature2 )
  Option  (d):       24a. MLDSA.Verify( PK.EUICC.MLDSA,
                                         euiccSigned2,
                                         euiccSignature2 )

Options (a, b): ECDH key agreement:
  24b. Generate ephemeral ECDH key pair:
         ( otPK.DP.ECKA, otSK.DP.ECKA )
  24c. Compute: ShS = DH( otSK.DP.ECKA, otPK.EUICC.ECKA )
  24d. Derive:  KE, KM = KDF( ShS )
  24e. Compute: BPP = enc( KE, profile )
  24f. Set:     bind_body = {
                  TransactionID,
                  otPK.DP.ECKA,
                  otPK.EUICC.ECKA,
                  BPP
                }
  24g. Compute: MAC = MAC( KM, bind_body )

Options (c, d): ML-KEM encapsulation:
  24b. Run:    ( ct, ShS ) = ML-KEM.Encaps( otPK.EUICC.MLKEM )
  24c. Derive: KE, KM = KDF( ShS )
  24d. Compute: BPP = enc( KE, profile )
  24e. Set:    bind_body = {
                 TransactionID,
                 ct,              ← KEM ciphertext (replaces EC public keys)
                 BPP
               }
  24f. Compute: MAC = MAC( KM, bind_body )

Signing bind_body:
  Options (a, b, c): 24g. ECDSA.Sign( SK.DPpb.ECDSA, bind_body )
                          → serverSignature3
  Option  (d):       24g. MLDSA.Sign( SK.DPpb.MLDSA,  bind_body )
                          → serverSignature3
```

> **ProVerif note:** `bind_body` structure is not interchangeable between (a, b) and (c, d) — model as distinct message formats. Under (a, b): `bind_body` contains two EC public keys (contributory DH). Under (c, d): `bind_body` contains a KEM ciphertext `ct` (non-contributory; only eUICC contributes randomness via KeyGen). IND-CCA2 of ML-KEM-768 should be modeled as `Decaps(sk, Encaps(pk)) = ShS` where `ct` is indistinguishable from random under the adversary.

---

### Step 25: BoundProfilePackage Delivery to LPA

**Flow: SM-DP+ → LPA**

```
SM-DP+ sends BoundProfilePackage = {
  TransactionID,
  bind_body,
  MAC,
  serverSignature3
}
```

---

### Step 26: LoadBoundProfilePackage Command

**Flow: LPA → eUICC**

```
LPA sends LoadBoundProfilePackage = {
  TransactionID,
  BPP,
  bind_body,
  MAC,
  serverSignature3
}
```

LPA passes through without modification.

---

### Step 27: eUICC Profile Installation

**Actor: eUICC (internal)**

> Peak memory pressure for option (d): SK.EUICC.MLDSA (2,560 B) and otSK.EUICC.MLKEM (2,400 B) may coexist in working memory between 27b and 27f.

```
serverSignature3 verification:
  Options (a, b, c): 27a. ECDSA.Verify( PK.DPpb.ECDSA,
                                         bind_body,
                                         serverSignature3 )
  Option  (d):       27a. MLDSA.Verify( PK.DPpb.MLDSA,
                                         bind_body,
                                         serverSignature3 )

Session key recovery:
  Options (a, b):    27b. Compute: ShS = DH( otSK.EUICC.ECKA, otPK.DP.ECKA )
  Options (c, d):    27b. Compute: ShS = ML-KEM.Decaps( otSK.EUICC.MLKEM, ct )

All options (shared):
  27c. Derive:  KE, KM = KDF( ShS )
  27d. Verify:  MAC( KM, bind_body ) matches received MAC
  27e. Compute: profile = dec( KE, BPP )

Installation result signature:
  Options (a, b, c): 27f. ECDSA.Sign( SK.EUICC.ECDSA,
                                       TransactionID || "Success" || ICCID )
                          → euiccSignature3
  Option  (d):       27f. MLDSA.Sign( SK.EUICC.MLDSA,
                                       TransactionID || "Success" || ICCID )
                          → euiccSignature3
```

> **ProVerif note:** step 27d MAC verification is the BPP integrity goal — models that the KE-encrypted profile was prepared by the authenticated SM-DP+. Step 27b under options (c, d) closes the IND-CCA2 loop; ShS must equal the ShS derived at step 24b/c.

---

### Step 28: ProfileInstallationResult

**Flow: eUICC → LPA**

```
eUICC sends ProfileInstallationResult = {
  TransactionID,
  "Success",
  ICCID,
  euiccSignature3
}
```

---

### Step 29: HandleNotification

**Flow: LPA → SM-DP+**

```
LPA sends HandleNotification = {
  TransactionID,
  "Success",
  ICCID,
  euiccSignature3
}
```

SM-DP+ may verify `euiccSignature3` to confirm installation. This closes the session loop and ties ICCID to the TransactionID.

---

## Summary: Step-to-Primitive Mapping

### Phase 1: Mutual Authentication

| Step | Actor | Operation | Options (a, b, c) | Option (d) |
|---|---|---|---|---|
| 8e | SM-DP+ | Sign `serverSigned1` | ECDSA (SK.DPauth.ECDSA) | ML-DSA-44 (SK.DPauth.MLDSA) |
| 12a | eUICC | Verify CERT.DPauth | ECDSA chain (PK.CI.ECDSA) | ML-DSA chain (PK.CI.MLDSA) |
| 12c | eUICC | Verify `serverSignature1` | ECDSA.Verify | MLDSA.Verify |
| 13b | eUICC | Sign `euiccSigned1` | ECDSA (SK.EUICC.ECDSA) | ML-DSA-44 (SK.EUICC.MLDSA) |
| 16b | SM-DP+ | Verify CERT.EUICC + EUM | ECDSA chain (PK.CI.ECDSA) | ML-DSA chain (PK.CI.MLDSA) |
| 16d | SM-DP+ | Verify `euiccSignature1` | ECDSA.Verify | MLDSA.Verify |

### Phase 2: Profile Download

| Step | Actor | Operation | Options (a, b) | Option (c) | Option (d) |
|---|---|---|---|---|---|
| 17c | SM-DP+ | Sign `smdpSigned2` | ECDSA | ECDSA | ML-DSA-44 |
| 20b | eUICC | Verify `smdpSignature2` | ECDSA.Verify | ECDSA.Verify | MLDSA.Verify |
| 21a | eUICC | Ephemeral key gen | ECKA KeyGen | ML-KEM KeyGen | ML-KEM KeyGen |
| 21c | eUICC | Sign `euiccSigned2` | ECDSA | ECDSA | ML-DSA-44 |
| 24a | SM-DP+ | Verify `euiccSignature2` | ECDSA.Verify | ECDSA.Verify | MLDSA.Verify |
| 24b | SM-DP+ | Session key agreement | DH (ECDH) | ML-KEM.Encaps | ML-KEM.Encaps |
| 24g | SM-DP+ | Sign `bind_body` | ECDSA | ECDSA | ML-DSA-44 |
| 27a | eUICC | Verify `serverSignature3` | ECDSA.Verify | ECDSA.Verify | MLDSA.Verify |
| 27b | eUICC | Session key recovery | DH (ECDH) | ML-KEM.Decaps | ML-KEM.Decaps |
| 27f | eUICC | Sign installation result | ECDSA | ECDSA | ML-DSA-44 |

---

## ProVerif Modeling Notes

### Security Properties to Verify

1. **Mutual authentication (Phase 1):** Injective agreement — eUICC agrees with SM-DP+ on `serverSigned1`; SM-DP+ agrees with eUICC on `euiccSigned1`.

2. **Session key secrecy (Phase 2):** `ShS` derived at step 24b/c / 27b is secret to the adversary.

3. **BPP confidentiality:** `profile` at step 27e is secret to the adversary.

4. **Binding integrity:** `bind_body` MAC at step 27d ensures BPP was prepared by the SM-DP+ that completed Phase 1.

5. **Replay resistance:** `eUIICCChallenge` (step 12d) and `serverChallenge` (step 16e) prevent cross-session replay.

6. **Forward secrecy (options c, d):** Compromise of long-term keys after session completion does not reveal `ShS` — derived from ephemeral ML-KEM keying material.

### Abstraction Guidance

- Model `ML-KEM.Encaps` / `ML-KEM.Decaps` as: `Encaps(pk) = (ct, k)` where `Decaps(sk, ct) = k` and `k` is indistinguishable from random under IND-CCA2.

- Model `ML-DSA.Sign` / `ML-DSA.Verify` identically to ECDSA in ProVerif syntax. Both are EUF-CMA; distinguish only by key type in the type system.

- Model the LPA as a **passive relay** in steps 7, 9, 11, 14, 15, 18, 19, 22, 23, 25, 26, 28, 29. The LPA performs no cryptographic operations on payloads (only address/token operations at steps 6 and 10).

- `TransactionID` must appear in every signed structure; model it as a **fresh nonce per session** to capture its anti-replay role.

- `bind_body` under options (c, d) must be typed **distinctly** from `bind_body` under options (a, b) due to structural difference: `ct` vs `{ otPK.DP.ECKA, otPK.EUICC.ECKA }`.

- **Key grouping summary for ProVerif branching:**
  - Authentication / signing: branch on `{a,b,c}` vs `{d}`
  - Ephemeral key type / KEM path: branch on `{a,b}` vs `{c,d}`
  - Transport: branch on `{a}` vs `{b,c,d}`