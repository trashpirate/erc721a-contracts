// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTWhitelist} from "src/NFTWhitelist.sol";
import {HelperConfig} from "script/helpers/HelperConfig.s.sol";

contract DeployNFTWhitelist is Script {
    HelperConfig public helperConfig;

    function run() external returns (NFTWhitelist, HelperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.ConstructorArguments memory args = helperConfig.activeNetworkConfig();

        console.log("initial owner: ", args.owner);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        NFTWhitelist nfts = new NFTWhitelist(
            args.name, args.symbol, args.baseURI, args.contractURI, args.owner, args.maxSupply, args.merkleRoot
        );
        console.log("Deployment gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        return (nfts, helperConfig);
    }
}
