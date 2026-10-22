# Zenith Gig Escrow

A decentralized escrow and freelance payment hub deployed on the Base L2 network. Zenith empowers independent contractors and clients to collaborate safely by mathematically guaranteeing payment upon successful delivery of off-chain milestones or digital assets.

## Core Mechanics
* **Trustless Fund Locking:** Clients lock the exact gig payment within the contract state during the registration phase. Funds cannot be siphoned or withdrawn arbitrarily once the gig is active.
* **Automated Settlement:** Upon the client's approval of the submitted work, the smart contract instantly calculates the platform fee, routes it to the treasury, and settles the remaining balance directly into the freelancer's wallet.
* **Refund Security:** If a project is canceled before completion, the contract guarantees a full refund of the `lockedWei` back to the original client, bypassing the fee deduction mechanics.

## Architecture
Developed using Solidity `0.8.37`. The protocol integrates the Checks-Effects-Interactions pattern rigidly within the `cancelGigRequest` and `approveGigPayment` functions, completely neutralizing reentrancy exploits during ETH settlement routing.
