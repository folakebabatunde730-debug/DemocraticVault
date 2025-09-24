# Democratic Vault Ì∑≥Ô∏è

A decentralized governance system built with Clarity smart contracts that enables token-based voting on proposals through a proxy architecture. Perfect for DAOs and decentralized organizations seeking transparent, secure governance mechanisms.

## Overview

Democratic Vault implements a proxy-based governance system where token holders can create and vote on proposals that execute through different implementation contracts. This architecture allows for upgradeable functionality while maintaining democratic oversight and transparent decision-making.

## Features

- **Ì¥Ñ Proxy Architecture**: Modular design with upgradeable implementation contracts
- **Ì∫ô Token-Based Voting**: Governance tokens determine voting power
- **Ì≥ù Proposal System**: Create, vote on, and execute community proposals
- **‚è∞ Time-Bound Voting**: Configurable voting periods for fair participation
- **Ìª°Ô∏è Security Controls**: Anti-double voting, access controls, and validation
- **Ì≥ä Transparent Tracking**: Full audit trail of proposals and votes

## Smart Contract Structure

### Core Components

1. **Governance Token System**: Simplified token balances for voting power
2. **Proposal Management**: Create and track governance proposals
3. **Voting Mechanism**: Secure voting with balance verification
4. **Proxy Execution**: Route approved proposals to implementation contracts
5. **Administrative Controls**: Owner functions for system management

### Key Data Structures

- `proposals`: Stores proposal details, votes, and execution status
- `votes`: Tracks individual voter choices and voting power
- `token-balances`: Governance token holdings
- `implementation-registry`: Maps functions to implementation contracts

## Getting Started

### Prerequisites

- Clarinet for local development and testing
- Understanding of Clarity smart contract language
- Basic knowledge of blockchain governance concepts

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-org/democratic-vault
cd democratic-vault
```

2. Initialize Clarinet project:
```bash
clarinet new democratic-vault
cd democratic-vault
```

3. Add the contract to your `Clarinet.toml`:
```toml
[contracts.governance-proxy]
path = "contracts/governance-proxy.clar"
```

### Deployment

1. Test the contract:
```bash
clarinet test
```

2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

## Usage Guide

### Creating a Proposal

```clarity
(contract-call? .governance-proxy create-proposal 
  "Upgrade Treasury Contract"
  "Proposal to upgrade the treasury management system with new features"
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
  "upgrade-implementation")
```

### Voting on Proposals

```clarity
;; Vote in favor (true) or against (false)
(contract-call? .governance-proxy vote u1 true)
```

### Executing Approved Proposals

```clarity
;; Execute proposal after voting period ends and it passes
(contract-call? .governance-proxy execute-proposal u1)
```

### Checking Proposal Status

```clarity
;; Get full proposal details
(contract-call? .governance-proxy get-proposal u1)

;; Check if proposal can be executed
(contract-call? .governance-proxy can-execute u1)
```

## Configuration

### System Parameters

- **Minimum Vote Threshold**: `1000` tokens required to create proposals
- **Voting Period**: `1440` blocks (~10 days)
- **Total Token Supply**: `1,000,000` tokens

### Modifying Parameters (Owner Only)

```clarity
;; Change voting period
(contract-call? .governance-proxy set-voting-period u2880) ;; ~20 days

;; Update minimum threshold
(contract-call? .governance-proxy set-min-threshold u2000)
```

## Architecture Benefits

### Proxy Pattern Advantages

1. **Upgradeability**: Change implementation logic without losing state
2. **Modularity**: Separate governance from execution logic
3. **Flexibility**: Different proposals can target different implementations
4. **Security**: Governance approval required for all changes

### Governance Features

1. **Democratic Process**: Token-weighted voting ensures fair representation
2. **Transparency**: All proposals and votes are publicly visible
3. **Time-Bounded**: Prevents rushed decisions with mandatory voting periods
4. **Anti-Manipulation**: Prevents double voting and requires minimum thresholds

## Security Considerations

- **Access Control**: Owner-only functions for critical operations
- **Vote Validation**: Prevents double voting and requires token ownership
- **Proposal Lifecycle**: Clear states prevent premature or duplicate execution
- **Balance Verification**: Ensures voters have sufficient tokens

## Error Handling

The contract includes comprehensive error codes:

- `u100`: Unauthorized access
- `u101`: Proposal not found
- `u102`: Already voted on proposal
- `u103`: Proposal voting period expired
- `u104`: Proposal not active
- `u105`: Insufficient token balance
- `u106`: Invalid implementation contract

## Testing

### Unit Tests

Create test files in the `tests/` directory:

```clarity
;; Test proposal creation
(define-test test-create-proposal
  (let ((result (contract-call? .governance-proxy create-proposal 
                  "Test Proposal" 
                  "Test Description"
                  tx-sender
                  "test-function")))
    (unwrap! result false)))
```

### Integration Tests

Test the complete governance flow from proposal creation to execution.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

- [ ] Multi-signature proposal creation
- [ ] Weighted voting based on lock-up periods
- [ ] Quadratic voting implementation
- [ ] Integration with external oracle systems
- [ ] Mobile-friendly governance interface

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Clarity language documentation
- Community feedback and testing
- Open source governance research

## Support

For questions and support:

- Create an issue in this repository
- Join our community Discord
- Check the documentation wiki

---

**Built with ‚ù§Ô∏è for the decentralized future**
