// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract PortfolioTokenTest is Test {
    PortfolioToken public token;

    address public admin   = makeAddr("admin");
    address public minter  = makeAddr("minter");
    address public pauser  = makeAddr("pauser");
    address public user    = makeAddr("user");
    address public user2   = makeAddr("user2");

    uint256 constant ONE_TOKEN = 1e18;
    uint256 constant MAX       = 100_000_000 * 1e18;

    // ─── Setup ───────────────────────────────────────────────────────────────────

    function setUp() public {
        token = new PortfolioToken(admin, minter, pauser);
    }

    // ─── Constructor ─────────────────────────────────────────────────────────────

    function test_Constructor_SetsName() public view {
        assertEq(token.name(), "PortfolioToken");
    }

    function test_Constructor_SetsSymbol() public view {
        assertEq(token.symbol(), "PTK");
    }

    function test_Constructor_GrantsRoles() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
        assertTrue(token.hasRole(token.PAUSER_ROLE(), pauser));
    }

    function test_Constructor_ZeroAdmin_Reverts() public {
        vm.expectRevert(PortfolioToken.ZeroAddress.selector);
        new PortfolioToken(address(0), minter, pauser);
    }

    function test_Constructor_ZeroMinter_Reverts() public {
        vm.expectRevert(PortfolioToken.ZeroAddress.selector);
        new PortfolioToken(admin, address(0), pauser);
    }

    // ─── Minting ─────────────────────────────────────────────────────────────────

    function test_Mint_Success() public {
        vm.prank(minter);
        token.mint(user, ONE_TOKEN);
        assertEq(token.balanceOf(user), ONE_TOKEN);
        assertEq(token.totalSupply(), ONE_TOKEN);
    }

    function test_Mint_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit PortfolioToken.TokensMinted(user, ONE_TOKEN);
        vm.prank(minter);
        token.mint(user, ONE_TOKEN);
    }

    function test_Mint_Unauthorized_Reverts() public {
        vm.expectRevert();
        vm.prank(user);
        token.mint(user, ONE_TOKEN);
    }

    function test_Mint_ZeroAddress_Reverts() public {
        vm.expectRevert(PortfolioToken.ZeroAddress.selector);
        vm.prank(minter);
        token.mint(address(0), ONE_TOKEN);
    }

    function test_Mint_ZeroAmount_Reverts() public {
        vm.expectRevert(PortfolioToken.ZeroAmount.selector);
        vm.prank(minter);
        token.mint(user, 0);
    }

    function test_Mint_ExceedsMaxSupply_Reverts() public {
        vm.prank(minter);
        token.mint(user, MAX);

        vm.expectRevert(
            abi.encodeWithSelector(PortfolioToken.ExceedsMaxSupply.selector, ONE_TOKEN, 0)
        );
        vm.prank(minter);
        token.mint(user, ONE_TOKEN);
    }

    function test_Mint_ExactMaxSupply_EmitsCapReached() public {
        vm.expectEmit(false, false, false, true);
        emit PortfolioToken.SupplyCapReached(MAX);
        vm.prank(minter);
        token.mint(user, MAX);
    }

    function test_RemainingSupply_DecreasesOnMint() public {
        assertEq(token.remainingSupply(), MAX);
        vm.prank(minter);
        token.mint(user, ONE_TOKEN);
        assertEq(token.remainingSupply(), MAX - ONE_TOKEN);
    }

    // ─── Burning ─────────────────────────────────────────────────────────────────

    function test_Burn_OwnTokens() public {
        vm.prank(minter);
        token.mint(user, ONE_TOKEN);

        vm.prank(user);
        token.burn(ONE_TOKEN);
        assertEq(token.balanceOf(user), 0);
    }

    // ─── Pausing ─────────────────────────────────────────────────────────────────

    function test_Pause_BlocksTransfers() public {
        vm.prank(minter);
        token.mint(user, ONE_TOKEN);

        vm.prank(pauser);
        token.pause();

        vm.expectRevert();
        vm.prank(user);
        token.transfer(user2, ONE_TOKEN);
    }

    function test_Pause_BlocksMinting() public {
        vm.prank(pauser);
        token.pause();

        vm.expectRevert();
        vm.prank(minter);
        token.mint(user, ONE_TOKEN);
    }

    function test_Unpause_RestoresTransfers() public {
        vm.prank(minter);
        token.mint(user, ONE_TOKEN);

        vm.prank(pauser);
        token.pause();

        vm.prank(pauser);
        token.unpause();

        vm.prank(user);
        token.transfer(user2, ONE_TOKEN);
        assertEq(token.balanceOf(user2), ONE_TOKEN);
    }

    function test_Pause_Unauthorized_Reverts() public {
        vm.expectRevert();
        vm.prank(user);
        token.pause();
    }

    // ─── Fuzz Tests ──────────────────────────────────────────────────────────────

    function testFuzz_Mint_ValidAmounts(uint256 amount) public {
        amount = bound(amount, 1, MAX);
        vm.prank(minter);
        token.mint(user, amount);
        assertEq(token.balanceOf(user), amount);
        assertEq(token.totalSupply(), amount);
    }

    function testFuzz_Transfer_ValidAmounts(uint256 amount) public {
        amount = bound(amount, 1, MAX);
        vm.prank(minter);
        token.mint(user, amount);

        vm.prank(user);
        token.transfer(user2, amount);
        assertEq(token.balanceOf(user2), amount);
        assertEq(token.balanceOf(user), 0);
    }

    function testFuzz_Burn_ValidAmounts(uint256 amount) public {
        amount = bound(amount, 1, MAX);
        vm.prank(minter);
        token.mint(user, amount);

        vm.prank(user);
        token.burn(amount);
        assertEq(token.balanceOf(user), 0);
        assertEq(token.totalSupply(), 0);
    }
}
