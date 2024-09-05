// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {NFTContract} from "src/NFTContract.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address feeToken;
        address feeAddress;
        address initialOwner;
    }

    /**
     * Tron IDE: TNEe78wmo2waTYF9Viu8AifzD3D99VXd7q, TYR2TRfKCMQsqekiZUhVJFSmwSEK2wUTAA, TYR2TRfKCMQsqekiZUhVJFSmwSEK2wUTAA
     */
    // chain configurations
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 1 || block.chainid == 8453 || block.chainid == 123) {
            activeNetworkConfig = getMainnetConfig();
        } else if (block.chainid == 84532 || block.chainid == 11155111) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getActiveNetworkConfigStruct() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function getMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            feeToken: vm.envAddress("TOKEN_ADDRESS"),
            feeAddress: vm.envAddress("FEE_ADDRESS"),
            initialOwner: vm.envAddress("OWNER_ADDRESS")
        });
    }

    function getTestnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            feeToken: vm.envAddress("TOKEN_ADDRESS"),
            feeAddress: vm.envAddress("FEE_ADDRESS"),
            initialOwner: vm.envAddress("OWNER_ADDRESS")
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // Deploy mock contracts
        vm.startBroadcast();
        ERC20Mock token = new ERC20Mock();
        vm.stopBroadcast();

        return NetworkConfig({
            feeToken: address(token),
            feeAddress: vm.envAddress("ANVIL_DEFAULT_ACCOUNT"),
            initialOwner: vm.envAddress("ANVIL_DEFAULT_ACCOUNT")
        });
    }
}
