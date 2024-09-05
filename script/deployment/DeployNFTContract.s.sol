// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTContract} from "../../src/NFTContract.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";

contract DeployNFTContract is Script {
    HelperConfig public helperConfig;

    function run() external returns (NFTContract, HelperConfig) {
        helperConfig = new HelperConfig();
        (address feeToken, address feeAddress, address initialOwner) = helperConfig.activeNetworkConfig();

        console.log("fee token: ", feeToken);
        console.log("fee address: ", feeAddress);
        console.log("initial owner: ", initialOwner);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        NFTContract nfts = new NFTContract(feeToken, feeAddress, initialOwner);
        console.log("Deployment gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        return (nfts, helperConfig);
    }
}
