// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Token.sol";

/// @notice Deployment script for PortfolioToken
/// @dev Run with:
///   forge script script/Deploy.s.sol:DeployToken \
///     --rpc-url $SEPOLIA_RPC_URL \
///     --private-key $PRIVATE_KEY \
///     --broadcast \
///     --etherscan-api-key $ETHERSCAN_API_KEY \
///     --verify
contract DeployToken is Script {
    function run() external returns (PortfolioToken token) {
        // Read deployer from environment
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        // In production you may want separate addresses for each role.
        // For portfolio/testnet, deployer holds all roles.
        address admin  = deployer;
        address minter = deployer;
        address pauser = deployer;

        vm.startBroadcast();

        token = new PortfolioToken(admin, minter, pauser);

        vm.stopBroadcast();

        // Log deployment info
        console2.log("=== PortfolioToken Deployed ===");
        console2.log("Address   :", address(token));
        console2.log("Name      :", token.name());
        console2.log("Symbol    :", token.symbol());
        console2.log("Max Supply:", token.MAX_SUPPLY());
        console2.log("Admin     :", admin);
        console2.log("Network   : Sepolia");
    }
}
