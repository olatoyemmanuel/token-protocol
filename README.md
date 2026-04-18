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

---

## License

MIT
