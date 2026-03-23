```markdown
# SGP.22 Consumer RSP — Full Protocol Step Reference
# For ProVerif model construction
# Options: (a) classical baseline | (b) PQ-TLS transport only |
#          (c) ML-DSA auth + classical ECDH | (d) full PQC (ML-DSA + ML-KEM)

---

## Notation

- SM-DP+  : Subscription Manager Data Preparation Plus
- LPA     : Local Profile Assistant (host device mediator)
- eUICC   : Embedded Universal Integrated Circuit Card
- CI      : GSMA Certificate Issuer (trust anchor)

### Keys and Certificates

| Symbol                  | Description                                      |
|-------------------------|--------------------------------------------------|
| SK.DPauth.ECDSA         | SM-DP+ authentication signing key (ECDSA)        |
| SK.DPauth.MLDSA         | SM-DP+ authentication signing key (ML-DSA-44)   |
| SK.DPpb.ECDSA           | SM-DP+ profile binding signing key (ECDSA)       |
| SK.DPpb.MLDSA           | SM-DP+ profile binding signing key (ML-DSA-44)  |
| SK.EUICC.ECDSA          | eUICC long-term signing key (ECDSA)              |
| SK.EUICC.MLDSA          | eUICC long-term signing key (ML-DSA-44)          |
| otSK.EUICC.ECKA         | eUICC ephemeral ECDH private key                 |
| otPK.EUICC.ECKA         | eUICC ephemeral ECDH public key                  |
| otSK.EUICC.MLKEM        | eUICC ephemeral ML-KEM secret key (option d)     |
| otPK.EUICC.MLKEM        | eUICC ephemeral ML-KEM public key (option d)     |
| otSK.DP.ECKA            | SM-DP+ ephemeral ECDH private key                |
| otPK.DP.ECKA            | SM-DP+ ephemeral ECDH public key                 |
| PK.CI.ECDSA             | CI root public key (ECDSA)                       |
| PK.CI.MLDSA             | CI root public key (ML-DSA-44)                   |
| CERT.DPauth.ECDSA/MLDSA | SM-DP+ authentication certificate               |
| CERT.DPpb.ECDSA/MLDSA   | SM-DP+ profile binding certificate              |
| CERT.EUICC.ECDSA/MLDSA  | eUICC certificate                               |
| CERT.EUM.ECDSA/MLDSA    | eUICC Manufacturer certificate                  |

### Cryptographic Primitives per Option

| Operation          | Options (a,b)    | Option (c)        | Option (d)        |
|--------------------|------------------|-------------------|-------------------|
| Authentication sig | ECDSA            | ML-DSA-44         | ML-DSA-44         |
| Profile binding sig| ECDSA            | ML-DSA-44         | ML-DSA-44         |
| eUICC ephemeral KA | ECDH (ECKA)      | ECDH (ECKA)       | ML-KEM-768        |
| SM-DP+ KA          | DH               | DH                | ML-KEM Encaps     |
| eUICC KA           | DH               | DH                | ML-KEM Decaps     |
| ES9+ transport     | TLS 1.3 (a only) | PQ-TLS            | PQ-TLS            |
| BPP encryption     | AES-128 (BSP)    | AES-128 (BSP)     | AES-128 (BSP)     |

---

## Phase 1 — Mutual Authentication (Steps 1–16)

### Step 1 — eUICC Info Retrieval

**Actor: LPA → eUICC**

```
1a. LPA sends:  getEUICCInfo
1b. eUICC returns: { eUIICCInfo1 }
```

- `eUIICCInfo1` includes supported CI public key identifiers
  (`euiccCiPKIdListForVerification`, `euiccCiPKIdListForSigning`)
- No cryptographic operations; all options identical

---

### Step 2 — Challenge Request

**Actor: LPA → eUICC**

```
2.  LPA sends: GetEUICCChallenge
```

- No cryptographic operations; all options identical

---

### Step 3 — eUICC Challenge Generation

**Actor: eUICC (internal)**

```
3.  eUICC generates: eUIICCChallenge  (16-byte random nonce)
```

- All options identical

---

### Step 4 — Challenge Delivery

**Actor: eUICC → LPA**

```
4.  eUICC returns: { eUIICCChallenge }
```

- All options identical

---

### Step 5 — Secure Channel Establishment

**Actor: LPA ↔ SM-DP+ (ES9+ interface)**

```
Option (a)  : TLS 1.3 Connection
Options (b, c, d): PQ-TLS or KEM-TLS Secure Channel
```

- The eUICC never directly terminates this TLS session;
  the LPA acts as the TLS endpoint
- This is the ONLY step where option (b) differs from option (a)
- Options (b), (c), (d) are identical at this step

---

### Step 6 — LPA Pre-checks

**Actor: LPA (internal)**

```
6a. Check SM-DP+ address
6b. Verify euiccCiPKIdListForVerification
6c. Verify euiccCiPKIdListForSigning
```

- All options identical

---

### Step 7 — Challenge Forwarding to SM-DP+

**Actor: LPA → SM-DP+**

```
7.  LPA sends: { eUIICCChallenge, eUIICCInfo1, SM-DP+ address }
```

- All options identical

---

### Step 8 — Server Authentication Data Construction

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
    Options (a, b): ECDSA.Sign( SK.DPauth.ECDSA, serverSigned1 )
    Options (c, d): MLDSA.Sign( SK.DPauth.MLDSA, serverSigned1 )
```

- `serverSigned1` structure is identical across all options;
  only the signing key and algorithm differ at 8e
- **ProVerif note**: model 8e as two separate branches on option flag

---

### Step 9 — Server Authentication Message

**Actor: SM-DP+ → LPA**

```
9.  SM-DP+ sends: {
      TransactionID,
      serverSigned1,
      serverSignature1,
      euiccCiPKIdToBeUsed,
      CERT.DPauth.( ECDSA | MLDSA )   ← option-dependent
    }
```

- Certificate type matches the signing algorithm used in 8e

---

### Step 10 — LPA Processing

**Actor: LPA (internal)**

```
10a. Verify SM-DP+ address
10b. Generate: ctxParams1 = activation code token
```

- All options identical

---

### Step 11 — AuthenticateServer Command

**Actor: LPA → eUICC**

```
11. LPA sends AuthenticateServer() = {
      serverSigned1,
      serverSignature1,
      euiccCiPKIdToBeUsed,
      CERT.DPauth.( ECDSA | MLDSA ),
      ctxParams1
    }
```

- All options identical in message structure;
  the certificate type changes with the option

---

### Step 12 — eUICC Server Verification

**Actor: eUICC (internal)**

```
Options (a, b):
  12a. Verify CERT.DPauth.ECDSA using PK.CI.ECDSA
  12b. Extract: PK.DPauth.ECDSA ← CERT.DPauth.ECDSA
  12c. Verify: ECDSA.Verify( PK.DPauth.ECDSA,
                             serverSigned1,
                             serverSignature1 )

Options (c, d):
  12a. Verify CERT.DPauth.MLDSA using PK.CI.MLDSA
  12b. Extract: PK.DPauth.MLDSA ← CERT.DPauth.MLDSA
  12c. Verify: MLDSA.Verify( PK.DPauth.MLDSA,
                             serverSigned1,
                             serverSignature1 )

All options (shared):
  12d. Verify: eUIICCChallenge in serverSigned1
               matches previously generated challenge (step 3)
  12e. Verify: euiccCiPKIdToBeUsed is in supported list
```

- **ProVerif note**: step 12c is the primary authentication
  goal — injective agreement on serverSigned1 from eUICC's
  perspective; 12d prevents replay

---

### Step 13 — eUICC Signed Response Construction

**Actor: eUICC (internal)**

```
13a. Construct: euiccSigned1 = {
                  TransactionID,
                  serverChallenge,
                  euiccInfo2,
                  ctxParams1
                }

13b. Compute euiccSignature1:
     Options (a, b): Sign( SK.EUICC.ECDSA, euiccSigned1 )
     Options (c, d): Sign( SK.EUICC.MLDSA, euiccSigned1 )
```

- **ProVerif note**: `euiccSigned1` binds `serverChallenge`
  (from step 8b) preventing server impersonation replay

---

### Step 14 — eUICC Authentication Response

**Actor: eUICC → LPA**

```
14. eUICC returns: {
      euiccSigned1,
      euiccSignature1,
      CERT.EUICC.( ECDSA | MLDSA ),
      CERT.EUM.( ECDSA | MLDSA )
    }
```

---

### Step 15 — AuthenticateClient Command

**Actor: LPA → SM-DP+**

```
15. LPA sends AuthenticateClient() = {
      euiccSigned1,
      euiccSignature1,
      CERT.EUICC.( ECDSA | MLDSA ),
      CERT.EUM.( ECDSA | MLDSA )
    }
```

---

### Step 16 — SM-DP+ Client Verification

**Actor: SM-DP+ (internal)**

```
16a. Verify: TransactionID matches step 8a

Options (a, b):
  16b. Verify CERT.EUICC.ECDSA and CERT.EUM.ECDSA
       using PK.CI.ECDSA
  16c. Extract: PK.EUICC.ECDSA ← CERT.EUICC.ECDSA
  16d. Verify: ECDSA.Verify( PK.EUICC.ECDSA,
                             euiccSigned1,
                             euiccSignature1 )

Options (c, d):
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

- **ProVerif note**: 16d is the primary eUICC authentication
  goal from SM-DP+'s perspective; 16e prevents reflection attacks

---

## Phase 2 — Profile Download (Steps 17–29)

---

### Step 17 — Profile Binding Data Construction

**Actor: SM-DP+ (internal)**

```
17a. Generate: Profile Metadata

17b. Construct: smdpSigned2 = { TransactionID }

17c. Compute smdpSignature2:
     Options (a, b): Sign( SK.DPpb.ECDSA, smdpSigned2 )
     Options (c, d): Sign( SK.DPpb.MLDSA,  smdpSigned2 )
```

- Note: `SK.DPpb` is a separate profile-binding keypair from
  `SK.DPauth` used in Phase 1; SM-DP+ must hold both under
  options (c) and (d)

---

### Step 18 — PrepareDownload to LPA

**Actor: SM-DP+ → LPA**

```
18. SM-DP+ sends PrepareDownload = {
      TransactionID,
      Profile Metadata,
      smdpSigned2,
      smdpSignature2,
      CERT.DPpb.( ECDSA | MLDSA )
    }
```

---

### Step 19 — PrepareDownload to eUICC

**Actor: LPA → eUICC**

```
19. LPA forwards PrepareDownload = {
      TransactionID,
      Profile Metadata,
      smdpSigned2,
      smdpSignature2,
      CERT.DPpb.( ECDSA | MLDSA )
    }
```

- LPA passes through without modification; all options identical

---

### Step 20 — eUICC Profile Binding Verification

**Actor: eUICC (internal)**

```
Options (a, b):
  20a. Verify CERT.DPpb.ECDSA using PK.CI.ECDSA
  20b. Verify: ECDSA.Verify( PK.DPpb.ECDSA,
                             smdpSigned2,
                             smdpSignature2 )

Options (c, d):
  20a. Verify CERT.DPpb.MLDSA using PK.CI.MLDSA
  20b. Verify: MLDSA.Verify( PK.DPpb.MLDSA,
                             smdpSigned2,
                             smdpSignature2 )

All options (shared):
  20c. Verify: smdpSigned2 content (TransactionID binding)
```

---

### Step 21 — eUICC Ephemeral Key Generation

**Actor: eUICC (internal)**

> This is the primary architectural divergence between
> options (a,b,c) and option (d)

```
Options (a, b, c) — ECDH path:
  21a. Generate ephemeral ECDH key pair:
         ( otPK.EUICC.ECKA, otSK.EUICC.ECKA )

  21b. Construct: euiccSigned2 = {
                    TransactionID,
                    otPK.EUICC.ECKA
                  }

  21c. Compute euiccSignature2:
       Options (a, b): Sign( SK.EUICC.ECDSA,
                             euiccSigned2 || smdpSignature2 )
       Option  (c):    MLDSA.Sign( SK.EUICC.MLDSA,
                                   euiccSigned2 || smdpSignature2 )

Option (d) — ML-KEM path:
  21a. Generate ephemeral ML-KEM-768 key pair:
         ( otPK.EUICC.MLKEM, otSK.EUICC.MLKEM )
         ← ML-KEM.KeyGen()

  21b. Construct: euiccSigned2 = {
                    TransactionID,
                    otPK.EUICC.MLKEM
                  }

  21c. Compute euiccSignature2:
         MLDSA.Sign( SK.EUICC.MLDSA,
                     euiccSigned2 || smdpSignature2 )
```

- **ProVerif note**: the concatenation `euiccSigned2 || smdpSignature2`
  in 21c binds the ephemeral key to this specific download session,
  preventing key reuse across transactions
- Under option (d) the KEM is single-sided: only the eUICC
  generates a KEM keypair; the SM-DP+ encapsulates to it

---

### Step 22 — eUICC Key Material Delivery

**Actor: eUICC → LPA**

```
22. eUICC sends: { euiccSigned2, euiccSignature2 }
```

---

### Step 23 — GetBoundProfilePackage Request

**Actor: LPA → SM-DP+ (ES9+ interface)**

```
23. LPA sends ES9+.GetBoundProfilePackage = {
      euiccSigned2,
      euiccSignature2
    }
```

---

### Step 24 — SM-DP+ BPP Construction and Key Agreement

**Actor: SM-DP+ (internal)**

> This step is the most complex; structure differs
> fundamentally between (a,b,c) and (d)

```
Options (a, b) — ECDSA verify + ECDH key agreement:
  24a. Verify: ECDSA.Verify( PK.EUICC.ECDSA,
                             euiccSigned2,
                             euiccSignature2 )
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
  24h. Compute: serverSignature3 =
                  Sign( SK.DPpb.ECDSA, bind_body )

Option (c) — ML-DSA verify + ECDH key agreement:
  24a. Verify: MLDSA.Verify( PK.EUICC.MLDSA,
                             euiccSigned2,
                             euiccSignature2 )
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
  24h. Compute: serverSignature3 =
                  MLDSA.Sign( SK.DPpb.MLDSA, bind_body )

Option (d) — ML-DSA verify + ML-KEM encapsulation:
  24a. Verify: MLDSA.Verify( PK.EUICC.MLDSA,
                             euiccSigned2,
                             euiccSignature2 )
  24b. Run:    ( ct, ShS ) =
                 ML-KEM.Encaps( otPK.EUICC.MLKEM )
  24c. Derive: KE, KM = KDF( ShS )
  24d. Compute: BPP = enc( KE, profile )
  24e. Set:    bind_body = {
                 TransactionID,
                 ct,              ← KEM ciphertext replaces
                 BPP                ephemeral EC public keys
               }
  24f. Compute: MAC = MAC( KM, bind_body )
  24g. Compute: serverSignature3 =
                  MLDSA.Sign( SK.DPpb.MLDSA, bind_body )
```

- **ProVerif note**: `bind_body` structure is not interchangeable
  between (a,b,c) and (d) — model as distinct message formats
- Under (a,b,c): `bind_body` contains two EC public keys
  (contributory DH); under (d): `bind_body` contains a KEM
  ciphertext `ct` (non-contributory; only eUICC contributes
  randomness via KeyGen)
- **ProVerif note**: IND-CCA2 of ML-KEM-768 should be modeled
  as a function where Decaps(sk, Encaps(pk)) = ShS;
  ct is indistinguishable from random under the adversary

---

### Step 25 — BoundProfilePackage Delivery to LPA

**Actor: SM-DP+ → LPA**

```
25. SM-DP+ sends BoundProfilePackage = {
      TransactionID,
      bind_body,
      MAC,
      serverSignature3
    }
```

---

### Step 26 — LoadBoundProfilePackage Command

**Actor: LPA → eUICC**

```
26. LPA sends LoadBoundProfilePackage = {
      TransactionID,
      BPP,
      bind_body,
      MAC,
      serverSignature3
    }
```

---

### Step 27 — eUICC Profile Installation

**Actor: eUICC (internal)**

> Peak memory pressure point for option (d):
> SK.EUICC.MLDSA (2,560 B) and otSK.EUICC.MLKEM (2,400 B)
> may coexist in working memory between 27b and 27f

```
All options — serverSignature3 verification:
  Options (a, b): 27a. Verify: ECDSA.Verify( PK.DPpb.ECDSA,
                                             bind_body,
                                             serverSignature3 )
  Options (c, d): 27a. Verify: MLDSA.Verify( PK.DPpb.MLDSA,
                                             bind_body,
                                             serverSignature3 )

Key agreement and BPP decryption:
  Options (a, b, c):
    27b. Compute: ShS = DH( otSK.EUICC.ECKA, otPK.DP.ECKA )

  Option (d):
    27b. Compute: ShS = ML-KEM.Decaps( otSK.EUICC.MLKEM, ct )

  All options (shared):
    27c. Derive:  KE, KM = KDF( ShS )
    27d. Verify:  MAC( KM, bind_body ) matches received MAC
    27e. Compute: profile = dec( KE, BPP )

Installation result signature:
  Options (a, b):
    27f. Compute: euiccSignature3 =
                    Sign( SK.EUICC.ECDSA,
                          TransactionID || "Success" || ICCID )
  Options (c, d):
    27f. Compute: euiccSignature3 =
                    MLDSA.Sign( SK.EUICC.MLDSA,
                                TransactionID || "Success" || ICCID )
```

- **ProVerif note**: 27d MAC verification is the BPP
  integrity goal — models that KE-encrypted profile was
  prepared by the authenticated SM-DP+
- **ProVerif note**: 27b under option (d) closes the
  IND-CCA2 loop; ShS must equal the ShS derived at 24c

---

### Step 28 — ProfileInstallationResult

**Actor: eUICC → LPA**

```
28. eUICC sends ProfileInstallationResult = {
      TransactionID,
      "Success",
      ICCID,
      euiccSignature3
    }
```

---

### Step 29 — HandleNotification

**Actor: LPA → SM-DP+**

```
29. LPA sends HandleNotification = {
      TransactionID,
      "Success",
      ICCID,
      euiccSignature3
    }
```

- SM-DP+ may verify `euiccSignature3` to confirm installation;
  this closes the session loop and ties ICCID to the TransactionID

---

## Summary: Step-to-Primitive Mapping

### Phase 1 — Authentication

| Step | Actor         | Operation         | (a,b)       | (c,d)       |
|------|---------------|-------------------|-------------|-------------|
| 8e   | SM-DP+        | Sign serverSigned1| ECDSA       | ML-DSA-44   |
| 12a  | eUICC         | Verify CERT.DPauth| ECDSA chain | MLDSA chain |
| 12c  | eUICC         | Verify serverSig1 | ECDSA.Vrfy  | MLDSA.Vrfy  |
| 13b  | eUICC         | Sign euiccSigned1 | ECDSA       | ML-DSA-44   |
| 16b  | SM-DP+        | Verify CERT.EUICC | ECDSA chain | MLDSA chain |
| 16d  | SM-DP+        | Verify euiccSig1  | ECDSA.Vrfy  | MLDSA.Vrfy  |

### Phase 2 — Download

| Step | Actor  | Operation              | (a,b)         | (c)           | (d)           |
|------|--------|------------------------|---------------|---------------|---------------|
| 17c  | SM-DP+ | Sign smdpSigned2       | ECDSA         | ML-DSA-44     | ML-DSA-44     |
| 20b  | eUICC  | Verify smdpSig2        | ECDSA.Vrfy    | MLDSA.Vrfy    | MLDSA.Vrfy    |
| 21a  | eUICC  | Ephemeral key gen      | ECKA KeyGen   | ECKA KeyGen   | ML-KEM KeyGen |
| 21c  | eUICC  | Sign euiccSigned2      | ECDSA         | ML-DSA-44     | ML-DSA-44     |
| 24a  | SM-DP+ | Verify euiccSig2       | ECDSA.Vrfy    | MLDSA.Vrfy    | MLDSA.Vrfy    |
| 24b  | SM-DP+ | Session key agreement  | DH (ECDH)     | DH (ECDH)     | ML-KEM.Encaps |
| 24h/g| SM-DP+ | Sign bind_body         | ECDSA         | ML-DSA-44     | ML-DSA-44     |
| 27a  | eUICC  | Verify serverSig3      | ECDSA.Vrfy    | MLDSA.Vrfy    | MLDSA.Vrfy    |
| 27b  | eUICC  | Session key recovery   | DH (ECDH)     | DH (ECDH)     | ML-KEM.Decaps |
| 27f  | eUICC  | Sign installation result| ECDSA        | ML-DSA-44     | ML-DSA-44     |

---

## ProVerif Modeling Notes

### Security Properties to Verify

1. **Mutual authentication (Phase 1)**
   Injective agreement: eUICC agrees with SM-DP+ on
   `serverSigned1`; SM-DP+ agrees with eUICC on `euiccSigned1`

2. **Session key secrecy (Phase 2)**
   `ShS` derived at step 24c / 27b is secret to the adversary

3. **BPP confidentiality**
   `profile` at step 27e is secret to the adversary

4. **Binding integrity**
   `bind_body` MAC at step 27d ensures BPP was prepared
   by the SM-DP+ that completed Phase 1

5. **Replay resistance**
   `eUIICCChallenge` (step 12d) and `serverChallenge` (step 16e)
   prevent cross-session replay

6. **HNDL forward secrecy (options c, d)**
   Compromise of `SK.DPauth` or `SK.EUICC` after session
   completion does not reveal `ShS` (from ephemeral keys)

### Abstraction Guidance

- Model `ML-KEM.Encaps` / `ML-KEM.Decaps` as:
  `Encaps(pk) = (ct, k)` where `Decaps(sk, ct) = k`
  and `k` is indistinguishable from random under IND-CCA2

- Model `ML-DSA.Sign` / `ML-DSA.Verify` identically to
  ECDSA in ProVerif syntax — both are EUF-CMA signatures;
  distinguish only by key type in the type system

- Model the LPA as a passive relay in Phase 1 steps 7, 9,
  11, 14, 15 and Phase 2 steps 18, 19, 22, 23, 25, 26, 28, 29
  — it does not perform cryptographic operations on the
  message payloads (only address/token operations at 6 and 10)

- `TransactionID` must appear in every signed structure;
  model it as a fresh nonce per session to capture its
  anti-replay role

- `bind_body` under option (d) must be typed distinctly
  from `bind_body` under (a,b,c) due to structural difference
  (ct vs otPK.DP.ECKA + otPK.EUICC.ECKA)
```