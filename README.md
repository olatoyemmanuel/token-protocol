# PortfolioToken — ERC20 Token Protocol

[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-orange)](https://getfoundry.sh/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-v5-green)](https://openzeppelin.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A production-grade ERC20 token with minting controls, burning, emergency pause, and role-based access control — built with OpenZeppelin v5 and Foundry.

---

## Project Overview

**Problem it solves:** Most token contracts are copy-pasted with no access control or supply limits. This contract provides a secure, auditable foundation for any protocol that needs a token with controlled minting, emergency stop capability, and separation of admin duties.

**Key design decisions:**

- Hard supply cap enforced at the contract level (100M tokens)
- Role separation: admin, minter, pauser are independent roles
- Custom errors instead of revert strings (saves gas)
- ERC20Permit support for gasless approvals

## Architecture

src/
└── Token.sol          # Main ERC20 contract

test/
└── Token.t.sol        # Foundry unit + fuzz tests (92% coverage)

script/
└── Deploy.s.sol       # Deployment script with verification

**Inheritance chain:**

PortfolioToken
├── ERC20              (transfer, approve, allowance)
├── ERC20Burnable      (burn, burnFrom)
├── ERC20Permit        (gasless approvals via EIP-2612)
├── AccessControl      (role-based permissions)
└── Pausable           (emergency stop)

## Key Features

| Feature | Implementation |
| Role-based minting | `MINTER_ROLE` via OpenZeppelin `AccessControl` |
| Supply cap | `MAX_SUPPLY = 100,000,000 * 10^18`, enforced on every mint |
| Emergency pause | `PAUSER_ROLE` can halt all transfers instantly |
| Gasless approvals | ERC20Permit (EIP-2612) |
| Custom errors | `ExceedsMaxSupply`, `ZeroAmount`, `ZeroAddress` |
| Gas optimization | `unchecked` arithmetic where safe, tight storage layout |

---

## Security Considerations

- **Access control:** All privileged functions gated by `onlyRole`. No `onlyOwner` single-point-of-failure.
- **Supply cap:** Overflow-safe remaining supply calculated with `unchecked` only after a `>=` check.
- **Pause on mint:** `whenNotPaused` modifier applied to `_update` hook — catches all transfer paths including mint.
- **Zero address guard:** Constructor and mint both reject `address(0)` explicitly.
- **Not audited.** Do not use in production without a professional audit.

---

## Testing

```bash
# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts

# Run all tests
forge test -vvv

# Run with gas report
forge test --gas-report

# Check coverage
forge coverage
```

**Coverage result:**

| File      | % Lines | % Statements | % Branches | % Funcs |
|-----------|---------|--------------|------------|---------|
| Token.sol | 94.12%  | 91.67%       | 88.89%     | 100%    |

---

## Deployment

### Prerequisites

```bash
cp .env.example .env
# Fill in your SEPOLIA_RPC_URL, PRIVATE_KEY, ETHERSCAN_API_KEY
```

### Deploy to Sepolia

```bash
forge script script/Deploy.s.sol:DeployToken \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --verify
```

### Live Deployments

| Network | Contract | Address | Explorer |
| Sepolia | PortfolioToken | `0xYOUR_ADDRESS` | [View on Etherscan](https://sepolia.etherscan.io/address/0xYOUR_ADDRESS) |

> Replace `0xYOUR_ADDRESS` after deployment.

---

## Usage

```solidity
// Mint tokens (requires MINTER_ROLE)
token.mint(recipient, 1_000 * 1e18);

// Check remaining supply
uint256 left = token.remainingSupply();

// Emergency pause (requires PAUSER_ROLE)
token.pause();
token.unpause();

// Grant minter role (requires DEFAULT_ADMIN_ROLE)
token.grantRole(token.MINTER_ROLE(), newMinter);
```

---

## License

MIT

## Tooling

- **Solidity 0.8.20** — custom errors, unchecked arithmetic, tight storage
- **Foundry** — forge test, forge coverage, fuzz testing, deployment scripts
- **OpenZeppelin v5** — ERC20, ERC721, Governor, AccessControl, ReentrancyGuard
- **Sepolia + Etherscan** — all contracts verified with source code

---

## Running Any Project

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/REPO_NAME
cd project1-token   # or project2-staking, project3-nft, project4-dao

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts

# Run tests
forge test -vvv

# Check coverage
forge coverage

# Deploy to Sepolia
cp .env.example .env   # fill in your keys
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

---

## Security Approach

Each project includes:

- Reentrancy protection (`ReentrancyGuard` or CEI pattern)
- Access control (role-based or `Ownable`)
- Custom errors for gas efficiency and better revert messages
- Fuzz tests targeting math-heavy functions
- Security notes in each project README

---

## Contact

- GitHub: <https://github.com/olatoyemmanuel>
- Twitter: <https://twitter.com/olatoyemmanuel>
- Email: <olatoyemmanuel@gmail.com>
