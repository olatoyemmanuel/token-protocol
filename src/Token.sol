// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title PortfolioToken
/// @author Your Name
/// @notice ERC20 token with minting, burning, pausing, and role-based permissions
/// @dev Built with OpenZeppelin v5. Gas-optimized storage layout.
contract PortfolioToken is ERC20, ERC20Burnable, ERC20Permit, AccessControl, Pausable {
    // ─── Roles ──────────────────────────────────────────────────────────────────
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // ─── State ───────────────────────────────────────────────────────────────────
    /// @notice Maximum total supply cap (100 million tokens)
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 ** 18;

    // ─── Events ──────────────────────────────────────────────────────────────────
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event SupplyCapReached(uint256 totalSupply);

    // ─── Errors ──────────────────────────────────────────────────────────────────
    error ExceedsMaxSupply(uint256 requested, uint256 available);
    error ZeroAmount();
    error ZeroAddress();

    // ─── Constructor ─────────────────────────────────────────────────────────────
    /// @param defaultAdmin Address granted DEFAULT_ADMIN_ROLE
    /// @param minter       Address granted MINTER_ROLE
    /// @param pauser       Address granted PAUSER_ROLE
    constructor(
        address defaultAdmin,
        address minter,
        address pauser
    )
        ERC20("PortfolioToken", "PTK")
        ERC20Permit("PortfolioToken")
    {
        if (defaultAdmin == address(0) || minter == address(0) || pauser == address(0))
            revert ZeroAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(PAUSER_ROLE, pauser);
    }

    // ─── Minting ─────────────────────────────────────────────────────────────────

    /// @notice Mint new tokens. Only callable by MINTER_ROLE.
    /// @param to     Recipient address
    /// @param amount Amount in wei (18 decimals)
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        uint256 available;
        unchecked {
            // MAX_SUPPLY >= totalSupply() always due to check below
            available = MAX_SUPPLY - totalSupply();
        }

        if (amount > available) revert ExceedsMaxSupply(amount, available);

        _mint(to, amount);
        emit TokensMinted(to, amount);

        if (totalSupply() == MAX_SUPPLY) {
            emit SupplyCapReached(totalSupply());
        }
    }

    // ─── Burning ─────────────────────────────────────────────────────────────────

    /// @notice Burn tokens from a target address (requires BURNER_ROLE).
    /// @dev Users can always burn their own tokens via ERC20Burnable.burn()
    function burnFrom(address account, uint256 amount)
        public
        override
        onlyRole(BURNER_ROLE)
    {
        if (amount == 0) revert ZeroAmount();
        super.burnFrom(account, amount);
        emit TokensBurned(account, amount);
    }

    // ─── Pausing ─────────────────────────────────────────────────────────────────

    /// @notice Pause all token transfers. Only callable by PAUSER_ROLE.
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause token transfers. Only callable by PAUSER_ROLE.
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ─── Overrides ───────────────────────────────────────────────────────────────

    /// @dev Hook that enforces pause state on all transfers.
    function _update(address from, address to, uint256 value)
        internal
        override
        whenNotPaused
    {
        super._update(from, to, value);
    }

    /// @notice Returns remaining mintable supply.
    function remainingSupply() external view returns (uint256) {
        unchecked {
            return MAX_SUPPLY - totalSupply();
        }
    }
}
