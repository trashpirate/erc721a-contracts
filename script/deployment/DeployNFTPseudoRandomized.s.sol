// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTPseudoRandomized} from "src/NFTPseudoRandomized.sol";
import {HelperConfig} from "script/helpers/HelperConfig.s.sol";

contract DeployNFTPseudoRandomized is Script {
    HelperConfig public helperConfig;

    function run() external returns (NFTPseudoRandomized, HelperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.ConstructorArguments memory args = helperConfig.activeNetworkConfig();

        console.log("initial owner: ", args.owner);
        console.log("base uri: ", args.baseURI);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        NFTPseudoRandomized nfts =
            new NFTPseudoRandomized(args.name, args.symbol, args.baseURI, args.contractURI, args.owner, args.maxSupply);
        console.log("Deployment gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        return (nfts, helperConfig);
    }
}
