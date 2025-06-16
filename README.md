# BatchCallAndSponsor

An educational project demonstrating account abstraction and sponsored transaction execution using EIP-7702. This project uses Foundry for deployment, scripting, and testing.

## Overview

The `BatchCallAndSponsor` contract enables batch execution of calls by verifying signatures over a nonce and batched call data. It supports:

- **Direct execution**: by the smart account itself.
- **Sponsored execution**: via an off-chain signature (by a sponsor).

Replay protection is provided by an internal nonce that increments after each batch execution.

## Features

- Batch transaction execution
- Off-chain signature verification using ECDSA
- Replay protection through nonce incrementation
- Support for both ETH and ERC-20 token transfers

## Prerequisites

- [Foundry](https://github.com/foundry-rs/foundry)
- Solidity ^0.8.20

## Installation & Execution

```bash
git clone https://github.com/JustUzair/bb-eip-7702.git
cd bb-eip-7702
forge build
make deploy
```
