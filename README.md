## Logos Governance (Experimental Demo dApp)

> **Experimental / Test Project:** This repository is a test and demonstration mini-app showcasing dApp integration with **Wallez** (`WallezKit` + `e_wallet_core`) and **Identity Accountability (Domain 6)** on Logos Basecamp.

[![Logos Basecamp](https://img.shields.io/badge/Platform-Logos%20Basecamp-orange.svg)](https://github.com/logos-co/logos-basecamp)
[![LEZ Testnet 0.4](https://img.shields.io/badge/Network-LEZ%20Testnet%200.4-emerald.svg)](https://testnet.lez.logos.co)
[![Identity Accountability](https://img.shields.io/badge/Cryptography-BIP--340%20Schnorr%20%7C%20Scoped%20Nullifiers-blue.svg)](https://github.com/evice-labs/lez-wallet-sdk)
[![License: MIT OR Apache-2.0](https://img.shields.io/badge/License-MIT%2FApache--2.0-blue.svg)](LICENSE)

## 1. Overview & Reference Architecture

The **Logos DAO Governance Mini-App** is the canonical reference dApp demonstrating decentralized anonymous governance on the Logos Execution Zone (LEZ). It demonstrates how third-party applications integrate with the **Evice LEZ Wallet Provider SDK** (`lez-wallet-sdk` and `e-wallet-core`) to implement **Sybil-resistant, anonymous citizen voting** using native **Identity Accountability (Domain 6)** primitives.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   LOGOS DAO GOVERNANCE ARCHITECTURE                    │
│                                                                        │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │               Logos DAO Mini-App (dao-miniapp)                 │   │
│   │   • Proposal Chamber UI (Quorum, Ballots, Live Tallies)        │   │
│   │   • Voter Status: Proves Citizen Identity via ZK Root         │   │
│   │   • Scoped Nullifier Derivation (Unlinkable across proposals)  │   │
│   └───────────────────────────────┬────────────────────────────────┘   │
│                                   │ logos.callModule("e_wallet_core")  │
│                                   ▼                                    │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │               e-wallet-core (C++20 Coordinator)                │   │
│   │   • DApp Session Lifecycle & Permission Grants                 │   │
│   │   • Identity Facade: Master Commitment, Nullifier, Attestation │   │
│   │   • proposeContractCall Smart Contract Dispatch                │   │
│   └───────────────────────────────┬────────────────────────────────┘   │
│                                   │ C-ABI FFI                          │
│                                   ▼                                    │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │               lez-wallet-sdk (Rust Engine)                     │   │
│   │   • Master Identity Commitment: C = SHA-256(secret ‖ salt)     │   │
│   │   • Scoped Nullifier: N_s = SHA-256(secret ‖ scope_id)         │   │
│   │   • BIP-340 Schnorr Ballot Attestation: sig = Schnorr(sk_s, m) │   │
│   └───────────────────────────────┬────────────────────────────────┘   │
│                                   │ JSON-RPC & State Tree              │
│                                   ▼                                    │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │                 Logos Execution Zone Sequencer                 │   │
│   │   • Canonical Testnet 0.4: https://testnet.lez.logos.co        │   │
│   │   • On-Chain Nullifier Registry (Strict Double-Voting Guard)   │   │
│   └────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
```

## 2. Key Cryptographic Primitives (Domain 6)

1. **Master Identity Commitment ($C$):**
   A persistent 32-byte hash representing verified citizenship in the Logos ecosystem. Evaluators and dApps can verify citizen status without ever learning the voter's private keys or wallet addresses.

2. **Deterministic Scoped Nullifiers ($N_s$):**
   Derived specifically for each proposal:
   $$\text{scope} = \text{"dao.governance.lez/proposal/"} \mathbin{\Vert} \text{proposal\_id}$$
   $$N_s = \text{SHA-256}(s \mathbin{\Vert} \text{scope})$$
   - **Determinism:** The same voter submitting multiple times for Proposal #1 always generates the exact same nullifier $N_1$, allowing the sequencer and contract to instantly reject duplicate votes.
   - **Domain Separation & Unlinkability:** The same voter submitting for Proposal #2 generates $N_2 \neq N_1$. Nobody can link a ballot on Proposal #1 to a ballot on Proposal #2.

3. **BIP-340 Schnorr Ballot Attestation:**
   The vote choice (`YES`, `NO`, or `ABSTAIN`) is cryptographically signed using a scoped scalar derived from the master secret. The resulting 64-byte Schnorr signature authenticates the ballot payload without exposing the voter's primary keypair.

## 3. Wallet Provider SDK Integration Flow (`WallezKit` + `e_wallet_core`)

In QML (`Main.qml` & `DaoBridge.qml`), the dApp integrates with Wallez via **WallezKit** (`Provider`, `ConnectButton`, `ConnectModal`), which handles session creation, account selection (displaying integer-formatted `LGO` balances), and scoped grants (`IdentityRead`, `IdentityPropose`, and account-level `Read`/`Propose`) over `logos.callModule("e_wallet_core", ...)`:

```javascript
// 1. Connect via WallezKit (connects DApp session, selects account, grants Read/Propose + IdentityRead/IdentityPropose)
wallet.connect(selectedAccountId, function (res) { ... });

// 2. Verify Citizen Master Commitment
var commitRes = logos.callModule("e_wallet_core", "getIdentityCommitment", [sessionId]);

// 3. Derive Proposal-Scoped Nullifier
var nullRes = logos.callModule("e_wallet_core", "deriveScopedNullifier", [sessionId, "dao.governance.lez/proposal/1"]);

// 4. Sign BIP-340 Schnorr Ballot
var sigRes = logos.callModule("e_wallet_core", "signIdentityAttestation", [sessionId, "dao.governance.lez/proposal/1", ballotPayloadHex]);

// 5. Broadcast Ballot to LEZ Sequencer (triggers informed-consent ApprovalModal in Wallez)
logos.callModule("e_wallet_core", "proposeContractCall", [sessionId, daoProgramId, payerId, mentionsJson, ballotPayloadHex, "Vote YES on Proposal #1"]);
```

## 4. Verification & Testing

An automated end-to-end Python test suite exercises the complete protocol against `libe_wallet_sdk.so`:

```bash
# Run test suite
python3 tests/test_dao_governance.py
```

## 5. Building & Deploying to Logos Basecamp

```bash
# 1. Nix check (syntax and formatting)
nix flake check

# 2. Deploy module to local Logos Basecamp
mkdir -p ~/.local/share/Logos/LogosBasecamp/plugins/
cp -r . ~/.local/share/Logos/LogosBasecamp/plugins/dao_miniapp
```
