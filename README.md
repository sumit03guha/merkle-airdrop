# Merkle Airdrop System

The Merkle Airdrop system enables the distribution of tokens via airdrops in a secure and gas-efficient manner using Merkle proofs to verify claims. This repository contains the smart contracts, testing suite, and deployment scripts necessary for setting up and managing a Merkle Airdrop.

## Features

- **Secure Token Distribution**: Uses Merkle proofs to ensure that airdrops are claimed only by eligible addresses.
- **Gas Efficiency**: Reduces the gas cost by allowing users to prove their token claim without the need for on-chain storage of all possible claimants.
- **EIP712 Signing**: Implements EIP712 for secure and verifiable signatures.
- **Comprehensive Tests**: Includes a full suite of tests to ensure functionality and robustness.
- **Script Automation**: Scripts to generate airdrop input data and Merkle proofs for deployment.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html) for Solidity testing and deployment

## Installation

Clone the repository and install dependencies:

```bash
git clone https://your-repository-url.git
cd merkle-airdrop-system
forge install
```

## Usage

### Generating Merkle Proofs

Generate input data and Merkle proofs by running:

```bash
forge script script/GenerateInput.s.sol
forge script script/MakeMerkle.s.sol
```

### Running Tests

Execute the tests with Foundry:

```bash
forge test
```

## Smart Contracts

- **MerkleAirdrop.sol**: Main contract for handling the airdrop.
- **MockToken.sol**: Mock ERC20 token for testing purposes.

## Scripts

- **GenerateInput.s.sol**: Generates the input data for the Merkle tree.
- **MakeMerkle.s.sol**: Generates the Merkle tree root and proofs from the input data.

## License

Distributed under the MIT License. See `LICENSE` for more information.
