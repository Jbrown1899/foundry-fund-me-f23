// 1. Deploy mocks when we are on a local network
// 2. Keep track of contracts accross different chains
// Sepolia ETH/USD
// Mainnet ETH/USD
// Sepolia ETH/USD: 0x694AA1769357215DE4FAC081bf1f309aDC325306
// Mainnet ETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // if on  a local anvil chain, deploy mock contract
    // else if on a testnet, use the deployed contract address

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8; // 2000 USD with 8 decimals

    NetworkConfig public activeNetworkConfig;
    // We can use a struct to store the network configuration

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == 11155111) {
            // Sepolia
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 31337) {
            // Anvil
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
        else if (block.chainid == 1) {
            // Mainnet
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            revert("Unsupported network");
        }
    }


    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            // If the price feed is already set, return the existing config
            return activeNetworkConfig;
        }
        
        vm.startBroadcast();
        //deploy mock contract
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE); // 2000 USD with 8 decimals
        vm.stopBroadcast();
        // return the mock contract address
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)// Replace with mock address if needed
        });
        return anvilConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }
}